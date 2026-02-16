application.controller
(
		"UploadAndPrepData1",
		function($rootScope, $scope, $sce)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// page open
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				// Local installer: all users can edit upload & prep steps.
				// For cloud/hosted use, switch this back to:
				//   $rootScope.user.administrator;
				$scope.editable = true;
				
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					$scope.initializeMetrics();
					
				}
				else
				{
					$scope.refreshMetrics();
					
				}
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.title = $scope.trustAsHtml(getMessage("UploadAndPrepData1.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("UploadAndPrepData1.subtitle"));
				
			}
			
			// ppaMetrics
			
			$scope.initializeMetrics = function()
			{
				$("#UploadAndPrepData1-metrics").datagrid
				(
						{
							fit: true,
							/*fitColumns: false,*/
				            onBeforeSelect: function(){return false;},
							url: "data/getMetrics",
							queryParams: {"selected": true, },
							columns:
								[[
									{
										field: "dataPointName",
										title: getMessage("UploadAndPrepData1.ppaMetrics.column.dataPointName"),
										width: 350,
										fixed: true,
									},
									{
										field: "userFileId",
										title: getMessage("UploadAndPrepData1.ppaMetrics.column.userFile"),
										width: 500,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<input class='easyui-element UploadAndPrepData1-userFileCombobox' style='width: 100%; '" +
													" value='" + value + "'" +
													" metricId='" + row["id"] + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									// upload userFile
									{
										field: "fileUpload",
										width: 500,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<form id='UploadAndPrepData1-metrics-userFile-fileForm-" + row["id"] + "' method='post' enctype='multipart/form-data'>" +
														"<input type='hidden' name='metricId' value='" + row["id"] + "' />" +
														"<input class='easyui-element easyui-filebox UploadAndPrepData1-metrics-userFile-fileForm-filebox' name='file' style='width: 100%; '/>" +
													"</form>"
												;
												
												return output;
												
											},
									},
									// upload userFile button
									{
										field: "fileUploadButton",
										width: 100,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<a class='easyui-linkbutton UploadAndPrepData1-metrics-userFile-fileForm-linkbutton' style='width: 100%; '" +
													" metricId='" + row["id"] + "'" +
													"></a>"
												;
												
												return output;
												
											},
									},
								]],
							onLoadSuccess:
								function()
								{
									// render userFileCombobox
									
									var userFiles = getData("getUserFiles", {});
									
									$(".UploadAndPrepData1-userFileCombobox").each
									(
											function(index, element)
											{
												// get additional variables
												
												var metricId = element.getAttribute("metricId");
												
												// render component
												
												$(element).combobox
												(
														{
															disabled: !$scope.editable,
															prompt: (userFiles.length == 0 ? getMessage("UploadAndPrepData1.ppaMetrics.column.userFile.combobox.noFilesPrompt") : ""),
															valueField: "id",
															textField: "fileName",
															data: userFiles,
															onChange:
																function(newValue)
																{
																	if (newValue != "")
																	{
																		$scope.setMetricUserFile(metricId, newValue);
																		
																	}
																	
																}
														}
												)
												;
												
											}
									)
									;
									
									// render userFile upload form
									
									$(".UploadAndPrepData1-metrics-userFile-fileForm-filebox").each
									(
											function(index, element)
											{
												// render component
												
												$(element).filebox
												(
														{
															disabled: !$scope.editable,
														}
												)
												;
												
											}
									)
									;
									
									$(".UploadAndPrepData1-metrics-userFile-fileForm-linkbutton").each
									(
											function(index, element)
											{
												// get additional variables
												
												var metricId = element.getAttribute("metricId");
												
												// render component
												
												$(element).linkbutton
												(
														{
															disabled: !$scope.editable,
															iconCls: "icon-upload",
															text: getMessage("common.label.upload"),
															onClick:
																function()
																{
																	// upload file and refresh page
																	
																	uploadFile
																	(
																			"#UploadAndPrepData1-metrics-userFile-fileForm-" + metricId + "",
																			"file",
																			"loadUserFileAndAssignItToMetric",
																			function()
																			{
																				// refresh page
																				
																				$scope.refreshMetrics();
																				
																			}
																	)
																	;
																	
																},
														}
												)
												;
												
											}
									)
									;
									
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", (1450 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshMetrics = function()
			{
				$("#UploadAndPrepData1-metrics").datagrid("reload");

			}
			
			$scope.setMetricUserFile = function(metricId, userFileId)
			{
				postData("setMetricUserFile", {"metricId": metricId, "userFileId": userFileId, });
				
			}
			
		}
)
;

