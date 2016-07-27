<%@ page contentType="text/html; charset=iso-8859-1" language="java"
         import="org.ecocean.servlet.ServletUtilities,
org.ecocean.identity.IdentityServiceLog,
java.util.ArrayList,org.ecocean.Annotation, org.ecocean.Encounter,
org.ecocean.media.MediaAsset,
org.ecocean.media.MediaAssetFactory,
org.dom4j.Document, org.dom4j.Element,org.dom4j.io.SAXReader, org.ecocean.*, org.ecocean.grid.MatchComparator, org.ecocean.grid.MatchObject, java.io.File, java.util.Arrays, java.util.Iterator, java.util.List, java.util.Vector, java.nio.file.Files, java.nio.file.Paths, java.nio.file.Path" %>

<%

String context="context0";
context=ServletUtilities.getContext(request);


//let's set up references to our file system components
String rootWebappPath = getServletContext().getRealPath("/");
File webappsDir = new File(rootWebappPath).getParentFile();
File shepherdDataDir = new File(webappsDir, CommonConfiguration.getDataDirectoryName(context));
File encountersDir=new File(shepherdDataDir.getAbsolutePath()+"/encounters");

//quick hack to set id & approve
if ((request.getParameter("number") != null) && (request.getParameter("individualID") != null)) {
	Shepherd myShepherd = new Shepherd(context);
	myShepherd.beginDBTransaction();
	Encounter enc = myShepherd.getEncounter(request.getParameter("number"));
	if (enc == null) {
		out.println("{\"success\": false, \"error\": \"no such encounter\"}");
		myShepherd.rollbackDBTransaction();
	} else {
		String taskId = request.getParameter("taskId");
		enc.setIndividualID(request.getParameter("individualID"));
		enc.setState("approved");
		enc.setMatchedBy("Fin Matching Algorithm" + ((taskId == null) ? "" : " (task " + taskId + ")"));
		myShepherd.commitDBTransaction();
		out.println("{\"success\": true}");
	}
	myShepherd.closeDBTransaction();
	return;
}


  session.setMaxInactiveInterval(6000);
  String taskId = request.getParameter("taskId");

	String jobId = null;
	int qmaId = -1;
	Shepherd myShepherd2 = new Shepherd(context);
	myShepherd2.beginDBTransaction();
	ArrayList<IdentityServiceLog> logs = IdentityServiceLog.loadByTaskID(taskId, "BenWhiteshark", myShepherd2);
        for (IdentityServiceLog l : logs) {
            if (l.getServiceJobID() != null) jobId = l.getServiceJobID();
	    try {
            	if ((l.getObjectIDs() != null) && (l.getObjectIDs().length > 0)) qmaId = Integer.parseInt(l.getObjectIDs()[0]);
		} catch (Exception ex) {}
        }

	String qMediaAssetJson = null;
	String qannId = null;
       	//Annotation qann = null;
	MediaAsset ma = MediaAssetFactory.load(qmaId, myShepherd2);
	String num = null;
	Encounter enc = null;
	if (ma != null) {
		qMediaAssetJson = ma.sanitizeJson(request, new org.datanucleus.api.rest.orgjson.JSONObject()).toString();
        	enc = Encounter.findByMediaAsset(ma, myShepherd2);
		num = enc.getCatalogNumber();
	}
	


	myShepherd2.rollbackDBTransaction();
	myShepherd2.closeDBTransaction();
%>

 <link href="../css/pageableTable.css" rel="stylesheet" type="text/css"/>
<link rel="stylesheet" href="../javascript/tablesorter/themes/blue/style.css" type="text/css" media="print, projection, screen" />


<style type="text/css">

#approval-buttons {
	height: 5em;
}

#approval-button {
	margin-left: 30px;
}

#all-wrapper {
}

#results {
	height: 300px;
	overflow-y: scroll;
	display: inline-block;
	width: 20%;
}

#results ul {
	width: 90%;
}

#results li {
	list-style-type: none;
	padding: 2px 5px;
	border-radius: 3px;
}

#results li:hover {
	background-color: #DDD;
}

#result-images {
	display: inline;
	margin-bottom: 100px;
}

td.ptcol-overall_score,
td.ptcol-score_holmbergIntersection,
td.ptcol-score_fastDTW,
td.ptcol-score_I3S,
td.ptcol-score_proportion {
	text-align: right;
}

.ptcol-adaboost_match {
        display: none !important;
}

/*
td.ptcol-encounterID:hover, td.ptcol-individualID:hover {
	background-color: #FF0 !important;
	outline: solid black 2px;
}
*/

td.ptcol-encounterID, td.ptcol-individualID {
	position: relative !important;
}
tr.clickable:hover .link-button {
	display: inline-block;
}

.indiv-button {
	display: none;
}
.enc-button {
	display: inline-block;
}
.link-button, .link-button:hover {
	position: absolute;
	right: 2px;
	bottom: 2px;
	background-color: #FFA;
	padding: 1px 4px;
	border: solid #444 1px;
	border-radius: 4px;
	margin: 0 3px;
	color: #444;
	text-decoration: none;
}
.link-button:hover {
	color: #000;
	background-color: #FF0;
}

#result-images {
	height: 300px;
	position: relative;
}

#image-main {
	background-color: #02F;
}
#image-compare {
	background-color: #FAFA00;
}
.result-image-wrapper {
	padding: 9px;
	border-radius: 6px;
	width: 30%;
	margin: 4px;
	float: left;
	top: 0;
}

.result-image-wrapper img {
	top: 0;
	left: 0;
	width: 100%;
}

.result-image-wrapper .note, #chart .note {
	background-color: rgba(0,0,0,0.5);
	border-radius: 10px;
	padding: 5px;
	margin: 50px 10px 0 10px;
	text-align: center;
	color: #FFF;
	font-size: 0.9em;
}


.image-info {
	padding: 5px;
	margin: 8px;
	margin-bottom: -75px;
	width: 43%;
	background-color: rgba(255,255,255,0.7);
	font-size: 0.8em;
	position: absolute;
	bottom: 0;
}


#image-meta {
	width: 100%;
	text-align:center;
}
#image-meta #score {
	display: inline-block;
	padding: 3px 15px;
	border-radius: 12px;
	background-color: rgba(0,0,0,0.7);
	color: #FFF;
	z-index: 9999 !important;
	position: relative;
	margin-bottom: -25px;
}


/* makes up for nudging of chart */
#chart .note {
	width: 80%;
}

#chart {
	margin: 75px 0 -30px 70px;
	height: 400px;
}


</style>

<script>
var taskId = '<%=taskId%>';
var jobId = <%=((jobId == null) ? "undefined" : "'" + jobId + "'")%>;
var qannId = <%=((qannId == null) ? "undefined" : "'" + qannId + "'")%>;
var qMediaAsset = <%=((qMediaAssetJson == null) ? "undefined" : qMediaAssetJson)%>;
var qencId = false;
</script>



<jsp:include page="../header.jsp" flush="true" />

<div class="container maincontent">




<h1>Matching Results <a href="<%=CommonConfiguration.getWikiLocation(context)%>scan_results"
  target="_blank"><img src="../images/information_icon_svg.gif"
                       alt="Help" border="0" align="absmiddle">
   </a>
</h1>




<p>



<div id="all-wrapper">
	<div id="results">Waiting for results....</div>
	<div id="result-images"></div>
</div>



<div id="link" style="clear: both;"><%
	if (num != null) out.println("<a href=\"encounter.jsp?number=" + num + "\">Return to encounter</a>");
%></div>



</div>
<jsp:include page="../footer.jsp" flush="true"/>



<script src="../javascript/underscore-min.js"></script>
<script src="../javascript/backbone-min.js"></script>
<script src="../javascript/core.js"></script>
<script src="../javascript/classes/Base.js"></script>

<script src="../javascript/tablesorter/jquery.tablesorter.js"></script>
<script src="//code.jquery.com/ui/1.11.2/jquery-ui.js"></script>
<link rel="stylesheet" href="//code.jquery.com/ui/1.11.2/themes/smoothness/jquery-ui.css">
<link rel="stylesheet" href="../javascript/tablesorter/themes/blue/style.css" type="text/css" media="print, projection, screen" />
<link rel="stylesheet" href="../css/pageableTable.css" />
<script src="../javascript/tsrt.js"></script>
<script src="../javascript/flukeScanEnd.js"></script>

<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<script type="text/javascript">
/*
	google.load('visualization', '1.1', {packages: ['line', 'corechart']});
    	google.setOnLoadCallback(initChart);
*/
</script>


<script>
function init2() {   //called from wildbook.init() when finished
    	$('#result-images').append('<div class="result-image-wrapper" id="image-main" />');
    	$('#result-images').append('<div class="result-image-wrapper" id="image-compare" />');
	//if (qMediaAsset) addImage(fakeEncounter({}, qMediaAsset),jQuery('#image-main'));
	if (qMediaAsset) jQuery('#image-main').append('<img src="' + wildbook.cleanUrl(qMediaAsset.url) + '" />');
	jQuery('#image-compare').append('<img style="height: 11px; width: 50%; margin: 40px 25%;" src="../images/image-processing.gif" />');
	checkForResults();
}

function checkForResults() {
	jQuery.ajax({
		url: '../ia',
		type: 'POST',
		contentType: 'application/javascript',
		data: JSON.stringify({BenWhiteshark: { taskResults: taskId }}),
		success: function(d) {
			console.info(d);
			processResults(d);
		},
		error: function() {
			alert('error fetching results');
		},
		dataType: 'json'
	});
}

var countdown = 100;
function processResults(res) {
/*
	if (res && res.queryObjects && (res.queryObjects.length > 0)) {  //queryObjects is actually an array cuz it could be many!  we use first. :/
		var enc = {};
		if (res.queryObjects[0].encounterId) {
			enc.catalogNumber = res.queryObjects[0].encounterId;
		}
		jQuery('#image-main').html('');
		addImage(fakeEncounter(enc, res.queryObjects[0].asset), jQuery('#image-main'));
	}
*/

	if (!res || !res.matches) {
console.info('waiting to try again...');
		$('#results').html('Waiting for results. You may leave this page.  [countdown=' + countdown + ']');
		countdown--;
		if (countdown < 0) {
			$('#results').html('Gave up waiting for results, sorry.  Reload to wait longer.');
			return;
		}
		setTimeout(function() { checkForResults(); }, 3000);
		return;
	}

	if (!res.matches || (res.matches.length < 1)) {
		jQuery('#image-compare').html('<img style="width: 225px; margin: 20px 30%;" src="../images/image-not-found.jpg" />');
		$('#results').html('No matches found.');
		return;
	}

////// TODO this makes the erroneous assumption we only have one query object -- but we need an overhaul of the ui to handle more than one!

	if (res.queryObjects && (res.queryObjects.length > 0)) qencId = res.queryObjects[0].encounterId;

	var marr = res.matches[Object.keys(res.matches)[0]];
	updateMatch(marr[0], res.matchImages);
	var h = '<p><b>' + marr.length + ' matches</b></p><ul>';
	for (var i = 0 ; i < marr.length ; i++) {
//console.info(marr[i]);
		var indivId = marr[i][0];
//console.info(indivId);
		h += '<li data-individ="' + marr[i][0] + '" data-imgsrc="' + ((marr[i].length > 3) ? marr[i][3] : '') + '" data-i="' + i + '"><a target="_new" href="../individuals.jsp?number=' + indivId + '">indiv ' +
			indivId + '</a>' +
			', score = ' +
			marr[i][1] + '</li>';
	}
	//h += '</ul><div>' + approvalButtons(res.queryAnnotation, res.matchAnnotations) + '</div>';
	h += '</ul>';

	$('#results').html(h);

	$('#link').append('<div id="approval-buttons"><input id="approval-button" type="button" data-id="' + marr[0][0] + '" value="Approve as indiv ' + marr[0][0] + '" onClick="newApproval(this);" /></div>');

	if (marr[0].length > 3) {
		jQuery('#image-compare').html('<img src="' + marr[0][3] + '" />');
	} else {
		jQuery('#image-compare').html('<p>no image</p>');
	}

	$('#results li').on('mouseover', function(ev) {
		//var i = ev.currentTarget.getAttribute('data-i');
		var iid = ev.currentTarget.getAttribute('data-individ');

		$('#approval-button').val('Approve as indiv ' + iid).attr('data-id', iid);

		var imgsrc = ev.currentTarget.getAttribute('data-imgsrc');
		if (!imgsrc) {
			jQuery('#image-compare').html('<p>no image</p>');
		} else {
			jQuery('#image-compare').html('<img src="' + imgsrc + '" />');
		}
	});
}

function updateMatch(m, imgMap) {
	var indivId = Object.keys(m)[0];
	if (!imgMap || !imgMap[indivId]) return;
//console.warn('updateMatch(%o)', m);
	jQuery('#image-compare').html('<img src="' + imgMap[indivId] + '" />');
	//addImage(fakeEncounter(m.encounter, m.mediaAsset),jQuery('#image-compare'));
}

function fakeEncounter(e, ma) {
	var enc = new wildbook.Model.Encounter(e);
	enc.set('annotations', [{mediaAsset: ma}]);
	return enc;
}


function approvalButtons(qann, manns) {
	if (!manns || (manns.length < 1) || !qann || !qann.encounter) return '';
console.info(qann);
	var inds = [];
	for (var i = 0 ; i < manns.length ; i++) {
		if (!manns[i].encounter || !manns[i].encounter.individualID) continue;
		if (inds.indexOf(manns[i].encounter.individualID) > -1) continue;
		if (manns[i].encounter.individualID == qann.encounter.individualID) continue;
		inds.push(manns[i].encounter.individualID);
	}
console.warn(inds);
	if (inds.length < 1) return '';
	var h = ' <div id="approval-buttons">';
	for (var i = 0 ; i < inds.length ; i++) {
		h += '<input type="button" onClick="approvalButtonClick(\'' + qann.encounter.catalogNumber + '\', \'' +
		     inds[i] + '\');" value="Approve as assigned to ' + inds[i] + '" />';
	}
	return h + '</div>';
}


function newApproval(el) {
	var iid = el.getAttribute('data-id');
	approvalButtonClick(qencId, iid);
}

function approvalButtonClick(encID, indivID) {
	console.info('approvalButtonClick(%s, %s)', encID, indivID);
	jQuery('#approval-buttons').html('<i>sending request...</i>');
	jQuery.ajax({
		url: 'matchResults.jsp?number=' + encID + '&individualID=' + indivID + '&taskId=' + taskId,
		type: 'GET',
		dataType: 'json',
		success: function(d) {
			if (d.success) {
				window.location.href = 'encounter.jsp?number=' + encID;
			} else {
				console.warn(d);
				jQuery('#approval-buttons').html('error');
				alert('Error updating encounter: ' + d.error);
			}
		},
		error: function(x,y,z) {
			console.warn('%o %o %o', x, y, z);
			jQuery('#approval-buttons').html('error');
			alert('Error updating encounter');
		}
	});
	return true;
}


</script>
