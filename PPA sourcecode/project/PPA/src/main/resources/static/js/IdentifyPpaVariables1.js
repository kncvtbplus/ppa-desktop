application.controller
(
		"IdentifyPpaVariables1",
		function($rootScope, $scope, $sce)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// variables
			
			$scope.globalVariableDataSourcesSelectedRowIndex = -1;
			
			// page open
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				// Local installer: all users can map PPA variables.
				$scope.editable = true;
				
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					$scope.initializeGlobalVariableDataSources();
					$scope.initializeGlobalVariableDataSourceColumnValues();
					
				}
				else
				{
					$scope.clearGlobalVariableDataSourceColumnValues();
					$scope.refreshGlobalVariableDataSources();
					
				}
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.title = $scope.trustAsHtml(getMessage("IdentifyPpaVariables1.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("IdentifyPpaVariables1.subtitle"));
				
			}
			
			// globalVariableDataSource
			
			$scope.initializeGlobalVariableDataSources = function()
			{
				$("#IdentifyPpaVariables1-globalVariableDataSources").datagrid
				(
						{
							fit: true,
							/*fitColumns: false,*/
							singleSelect: true,
							url: "data/getGlobalVariableDataSources",
							view: groupview,
							groupField: "globalVariableName",
						    groupFormatter:
						    	function(value, rows)
						    	{
						    		return value;
						    		
						    	},
							columns:
								[[
									{
										field: "dataSourceFileName",
										title: getMessage("IdentifyPpaVariables1.globalVariableDataSources.column.dataSourceFileName"),
										width: 500,
									},
									{
										field: "globalVariableColumnName",
										title: getMessage("IdentifyPpaVariables1.globalVariableDataSources.column.globalVariableColumnName"),
										width: 300,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<input class='easyui-element IdentifyPpaVariables1-globalVariableColumnNameCombobox'" +
													" value='" + value + "'" +
													" dataSourceId='" + row["dataSourceId"] + "'" +
													" globalVariable='" + row["globalVariable"] + "'" +
													" style='width: 100%; ' />"
												;
												
												return output;
												
											},
									},
								]],
							onLoadSuccess:
								function()
								{
									// render globalVariableColumnNameCombobox
									
									$(".IdentifyPpaVariables1-globalVariableColumnNameCombobox").each
									(
											function(index, element)
											{
												var dataSourceId = element.getAttribute("dataSourceId")
												var globalVariable = element.getAttribute("globalVariable")
												
												getDataAsync
												(
														"getDataSourceColumnNames",
														{"dataSourceId": dataSourceId, },
														function(data)
														{
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
																							
																							$scope.setDataSourceGlobalVariableColumnName(dataSourceId, globalVariable, "");
																							
																						},
																				},
																			],
																		onChange:
																			function(newValue, oldValue)
																			{
																				if (newValue != "")
																				{
																					// check data source column valid
																					
																					var dataSourceGlobalVariableColumnNameValidResponse = getData("getDataSourceGlobalVariableColumnNameValid", {"dataSourceId": dataSourceId, "globalVariable": globalVariable, "columnName": newValue, });
																					
																					if (dataSourceGlobalVariableColumnNameValidResponse.valid)
																					{
																						$scope.setDataSourceGlobalVariableColumnName(dataSourceId, globalVariable, newValue);
																						
																					}
																					else
																					{
																						$.messager.alert
																						(
																								getMessage("IdentifyPpaVariables1.sameColumnError.title"),
																								dataSourceGlobalVariableColumnNameValidResponse.message,
																								"error"
																						);
																						
																						// revert combobox value
																						
																						$(element).combobox("initValue", oldValue);
																						
																					}
																					
																				}
																				
																			}
																	}
															)
															;
															
														}
												)
												;
												
											}
									)
									;
									
								},
							// do not unselect
							singleSelect: true,
							onSelect:
								function(index, row)
								{
									$scope.refreshGlobalVariableDataSourceColumnValues();
									
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", (1000 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshGlobalVariableDataSources = function()
			{
				$("#IdentifyPpaVariables1-globalVariableDataSources").datagrid("reload");
				
			}
			
			$scope.setDataSourceGlobalVariableColumnName = function(dataSourceId, globalVariable, columnName)
			{
				postData
				(
						"setDataSourceGlobalVariableColumnName",
						{"dataSourceId": dataSourceId, "globalVariable": globalVariable, "columnName": columnName, },
						true,
						function()
						{
							$scope.refreshGlobalVariableDataSourceColumnValues();
							
						}
				)
				;
				
			}
			
			// globalVariableDataSourceSelectedColumnValues
			
			$scope.initializeGlobalVariableDataSourceColumnValues = function()
			{
				$("#IdentifyPpaVariables1-globalVariableDataSourceColumnValues").datagrid
				(
						{
							fit: true,
							/*fitColumns: true,*/
				            onBeforeSelect: function(){return false;},
							url: "data/getGlobalVariableDataSourceColumnValues",
							columns:
								[[
									{
										field: "value",
										title: getMessage("common.label.value"),
										width: 300,
										fixed: true,
									},
									{
										field: "count",
										title: getMessage("common.label.count"),
										width: 70,
										fixed: true,
										align: "right",
										halign: "left",
									},
								]],
						}
				)
				.datagrid("getPanel")
				.css("max-width", (370 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.clearGlobalVariableDataSourceColumnValues = function()
			{
				$("#IdentifyPpaVariables1-globalVariableDataSourceColumnValues").datagrid("loadData", []);

			}
			
			$scope.refreshGlobalVariableDataSourceColumnValues = function()
			{
				var globalVariableDataSourcesSelectedRow = $("#IdentifyPpaVariables1-globalVariableDataSources").datagrid("getSelected");
				
				if (globalVariableDataSourcesSelectedRow)
				{
					var dataSourceId = globalVariableDataSourcesSelectedRow["dataSourceId"];
					var globalVariable = globalVariableDataSourcesSelectedRow["globalVariable"];
					
					$("#IdentifyPpaVariables1-globalVariableDataSourceColumnValues").datagrid("reload", {"dataSourceId": dataSourceId, "globalVariable": globalVariable, });
					
				}
				else
				{
					$scope.clearGlobalVariableDataSourceColumnValues();
					
				}

			}
			
		}
)
;

