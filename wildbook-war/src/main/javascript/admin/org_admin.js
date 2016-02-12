/* global angular, alertplus */
'use strict';

//
// &callback = returns orgid. Can get list of orgs to check against in parent from wbConfig
// =?readonly = hides all edit functions and effectively makes this a dropdown select w/ return/callback/scope link
// @editOnSelect = true/false string enables ng-change to open up the edit for current orgs
// =orgid = passin org id
// =?org = pass in full org  obj
// =displayinline = doesnt work yet
// attr action-icons = replaces save/cancel with icons to save space
//
angular.module('wildbook.admin').directive(
    'wbOrgAdmin',
    ["$http", "wbConfig", function($http, wbConfig) {
        return {
            restrict: 'E',
            scope: {
                callback: '&',
                readonly: '=?',
                editOnSelect: '@',
                orgid: '=',
                org: '=?',
                displayinline: '='
            },
            templateUrl: 'admin/org_admin.html',
            replace: true,
            link: function($scope, element, attr) {
                $scope.$watch('orgid', function(newVal, oldVal) {
                    if(newVal !== oldVal && newVal !== undefined) {
                        setOrgs();
                    }
                });

                wbConfig.config()
                .then(function(config) {
                    $scope.orgs = config.orgs;
                    setOrgs();
                });

                if (attr.actionIcons) {
                    $scope.showAsIcons = true;
                }

                function setOrgs() {
                    $scope.orgs.forEach(function(org) {
                        if(org.orgId === $scope.orgid) {
                            $scope.orgInput = org;
                            $scope.org = org;
                            if ($scope.editOnSelect === "true") {
                                $scope.showEdit = true;
                            }
                        }
                    });
                }

                $scope.edit = function(org) {
                    if (!org) {
                        return;
                    }

                    $scope.orgInput = angular.copy(org);
                    $scope.existingOrg = true;

                    if ($scope.callback) {
                        $scope.callback({orgId: $scope.orgInput.orgId});
                    }

                    if ($scope.editOnSelect === "true") {
                        $scope.showEdit = true;
                    }
                };

                $scope.showEditOrg = function() {
                    $scope.showEdit = true;
                };

                $scope.newOrg = function() {
                    $scope.cancel();
                    $scope.orgInput = {};
                    $scope.showEdit = true;
                };

                $scope.cancel = function() {
                    $scope.org = null;
                    $scope.orgInput = null;
                    $scope.orgSearch = null;
                    $scope.showEdit = false;
                    delete $scope.existingOrg;

                };

                $scope.save = function() {
                    if (!$scope.orgInput.name) {
                        alertplus.alert("Please enter an organization name.");
                        return ;
                    }

                    var exists = false;
                    $scope.orgs.forEach(function(obj) {
                        if (obj.name === $scope.orgInput.name) {
                            exists = true;
                        }
                    });

                    if (exists) {
                        alertplus.alert("Organization " + $scope.orgInput.name + " already exist!");
                        return;
                    }

                    if (!exists) {
                        $http.post("siteadmin/saveorg", $scope.orgInput)
                        .then(function (response) {
                            if ($scope.orgInput.orgId) {
                                $scope.orgs.forEach(function(obj, key) {
                                    if (obj.orgId === $scope.orgInput.orgId) {
                                        $scope.orgs[key] = $scope.orgInput;
                                    }
                                });
                            } else {
                                $scope.orgInput.orgId = response.data;
                                $scope.orgs.push($scope.orgInput);
                            }

                            if ($scope.callback) {
                                $scope.callback({orgId: $scope.orgInput.orgId});
                            }

                            $scope.cancel();
                        });
                    }
                };

                $scope.delete = function() {
                    return alertplus.confirm('Are you sure you want to remove '+ $scope.orgInput.name +'?', "Delete Organization", true)
                    .then(function(){
                        $http.post('siteadmin/deleteorg/' + $scope.orgInput.orgId)
                        .success(function() {
                            $scope.orgs.forEach(function(org, key) {
                                if (org.orgId === $scope.orgInput.orgId) {
                                    $scope.orgs.splice(key, 1);
                                }
                            });
                            $scope.cancel();
                        })
                        .error(function(res){
                            alertplus.error(res.message);
                        });
                    });
                };
            }
        };
    }]
);
