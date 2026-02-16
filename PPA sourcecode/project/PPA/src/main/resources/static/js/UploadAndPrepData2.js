application.controller
(
		"UploadAndPrepData2",
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
				$scope.editable = true;
				
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					$scope.initializeDataSources();
					
				}
				else
				{
					$scope.refreshDataSources();
					
					
				}
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.title = $scope.trustAsHtml(getMessage("UploadAndPrepData2.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("UploadAndPrepData2.subtitle"));
				
			}
			
			// dataSources
			
			$scope.initializeDataSources = function()
			{
				$("#UploadAndPrepData2-dataSources").datagrid
				(
						{
							fit: true,
							/*fitColumns: false,*/
				            onBeforeSelect: function(){return false;},
							url: "data/getDataSources",
							columns:
								[[
									{
										field: "fileName",
										title: getMessage("UploadAndPrepData2.dataSources.column.fileName"),
										width: 500,
										fixed: true,
									},
									{
										field: "weightColumnName",
										title: getMessage("UploadAndPrepData2.dataSources.column.weightColumnName"),
										width: 250,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<input class='easyui-element UploadAndPrepData2-dataSources-weightColumnName' style='width: 100%; '" +
													" value='" + value + "'" +
													" dataSourceId='" + row["id"] + "'"
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "weightMultiplier",
										fixed: true,
										width: 150,
										fixed: true,
										title: getMessage("UploadAndPrepData2.dataSources.column.weightMultiplier"),
										formatter:
											function(value,row,index)
											{
												var output =
													"<input class='easyui-element UploadAndPrepData2-dataSources-weightMultiplier' style='width: 100%; '" +
													" value='" + value + "'" +
													" dataSourceId='" + row["id"] + "'"
													"/>"
												;
												
												return output;
												
											},
									},
								]],
							onLoadSuccess:
								function()
								{
									// render weightColumnName
									
									$(".UploadAndPrepData2-dataSources-weightColumnName").each
									(
											function(index, element)
											{
												var dataSourceId = element.getAttribute("dataSourceId");
												
												var data = getData("getDataSourceColumnNames", {"dataSourceId": dataSourceId, });
												
												$(element).combobox
												(
														{
															disabled: !$scope.editable,
															valueField: "value",
															textField: "value",
															data: data,
															icons:
																[
																	{
																		iconCls: "icon-clear",
																		handler:
																			function(e)
																			{
																				$(e.data.target).combobox("clear");
																				
																			},
																	},
																],
															onChange:
																function(newValue)
																{
																	$scope.setDataSourceWeightColumnName(dataSourceId, newValue);
																	
																}
														}
												)
												;
												
											}
									)
									;
									
									// render weightMultiplier
									
									$(".UploadAndPrepData2-dataSources-weightMultiplier").each
									(
											function(index, element)
											{
												var dataSourceId = element.getAttribute("dataSourceId");
												
												$(element).numberbox
												(
														{
															disabled: !$scope.editable,
															required: true,
															precision: 12,
															formatter:
																function(value)
																{
																	return value.replace(/0+$/, "").replace(/\.$/, "");
																	
																},
															onChange:
																function(newValue)
																{
																	if (newValue == "")
																	{
																		showErrorMessage(getMessage("UploadAndPrepData2.dataSources.column.weightMultiplier.errorMessage"));
																		return;
																		
																	}
																	
																	$scope.setDataSourceWeightMultiplier(dataSourceId, newValue);
																	
																}
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
				.css("max-width", (900 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshDataSources = function()
			{
				$("#UploadAndPrepData2-dataSources").datagrid("reload");

			}
			
			$scope.setDataSourceWeightColumnName = function(dataSourceId, weightColumnName)
			{
				postData("setDataSourceWeightColumnName", {"dataSourceId": dataSourceId, "weightColumnName": weightColumnName, });
				
			}
			
			$scope.setDataSourceWeightMultiplier = function(dataSourceId, weightMultiplier)
			{
				postData("setDataSourceWeightMultiplier", {"dataSourceId": dataSourceId, "weightMultiplier": weightMultiplier, });
				
			}
			
		}
)
;

