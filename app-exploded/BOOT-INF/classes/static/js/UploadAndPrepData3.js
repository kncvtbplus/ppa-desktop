application.controller
(
		"UploadAndPrepData3",
		function($rootScope, $scope, $sce)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// variables
			
			$scope.selectedDataSourceRow;
			
			// page open
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				$scope.editable = $rootScope.user.administrator;
				
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					$scope.initializeDataSources();
					$scope.initializeSubsetColumn1Values();
					$scope.initializeSubsetColumn2Values();
					
				}
				else
				{
					$scope.clearSubsetColumn1Values();
					$scope.clearSubsetColumn2Values();
					$scope.refreshDataSources();
					
				}
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.title = $scope.trustAsHtml(getMessage("UploadAndPrepData3.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("UploadAndPrepData3.subtitle"));
				
			}
			
			// subsets
			
			$scope.initializeDataSources = function()
			{
				$("#UploadAndPrepData3-dataSources").datagrid
				(
						{
							fit: true,
							fitColumns: true,
							singleSelect: true,
							idField: "id",
							url: "data/getDataSourceSubsets",
							queryParams: {},
							columns:
								[
									[
										{
											field: "fileName",
											title: getMessage("UploadAndPrepData3.dataSources.column.fileName"),
											width: 400,
											rowspan: 2,
										},
										{
											title: getMessage("UploadAndPrepData3.dataSources.column.subsetColumn1Group"),
											colspan: 2,
										},
										{
											title: getMessage("UploadAndPrepData3.dataSources.column.subsetColumn2Group"),
											colspan: 2,
										},
										{
											field: "nRows",
											title: getMessage("UploadAndPrepData3.dataSources.column.nRows"),
											width: 80,
											fixed: true,
											rowspan: 2,
											"align": "right",
											"halign": "left",
										},
									],
									[
										{
											field: "subsetColumn1Name",
											title: getMessage("UploadAndPrepData3.dataSources.column.subsetColumn1Name"),
											width: 400,
											formatter:
												function(value,row,index)
												{
													var output =
														"<input class='easyui-element UploadAndPrepData3-subsetColumn1Name' style='width: 100%; '" +
														" value='" + value + "'" +
														" dataSourceId='" + row["id"] + "'" +
														"/>"
													;
													
													return output;
													
												},
										},
										{
											field: "subsetColumn1ValueCount",
											title: getMessage("UploadAndPrepData3.dataSources.column.subsetColumn1ValueCount"),
											align: "right",
											width: 110,
											fixed: true,
										},
										{
											field: "subsetColumn2Name",
											title: getMessage("UploadAndPrepData3.dataSources.column.subsetColumn2Name"),
											width: 400,
											formatter:
												function(value,row,index)
												{
													var output =
														"<input class='easyui-element UploadAndPrepData3-subsetColumn2Name' style='width: 100%; '" +
														" value='" + value + "'" +
														" dataSourceId='" + row["id"] + "'" +
														"/>"
													;
													
													return output;
													
												},
										},
										{
											field: "subsetColumn2ValueCount",
											title: getMessage("UploadAndPrepData3.dataSources.column.subsetColumn2ValueCount"),
											align: "right",
											width: 110,
											fixed: true,
										},
									],
								],
							onLoadSuccess:
								function()
								{
									// keep selection
									
									$(this).datagrid("unselectAll");
									
									if ($scope.selectedDataSourceRow)
									{
										$(this).datagrid("selectRecord", $scope.selectedDataSourceRow["id"]);
										
										$scope.selectedDataSourceRow = $(this).datagrid("getSelected");
										
									}
									else
									{
										// clear column value lists
										
										$("#UploadAndPrepData3-subsetColumn1Values").datagrid("reload", {"queryParams": {}, });
										$("#UploadAndPrepData3-subsetColumn2Values").datagrid("reload", {"queryParams": {}, });

									}
									
									// render subsetColumn1Name
									
									$(".UploadAndPrepData3-subsetColumn1Name").each
									(
											function(index, element)
											{
												var dataSourceId = element.getAttribute("dataSourceId");
												
												var dataSourceColumnNames = getData("getDataSourceColumnNames", {"dataSourceId": dataSourceId, });
												
												$(element).combobox
												(
														{
															disabled: !$scope.editable,
															valueField: "value",
															textField: "value",
															data: dataSourceColumnNames,
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
																	$scope.setDataSourceSubsetColumn1Name(dataSourceId, newValue);
																	
																},
														}
												)
												;
												
											}
									)
									;
									
									// render subsetColumn2Name
									
									$(".UploadAndPrepData3-subsetColumn2Name").each
									(
											function(index, element)
											{
												var dataSourceId = element.getAttribute("dataSourceId");
												
												var dataSourceColumnNames = getData("getDataSourceColumnNames", {"dataSourceId": dataSourceId, });
												
												$(element).combobox
												(
														{
															disabled: !$scope.editable,
															valueField: "value",
															textField: "value",
															data: dataSourceColumnNames,
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
																	$scope.setDataSourceSubsetColumn2Name(dataSourceId, newValue);
																	
																},
														}
												)
												;
												
											}
									)
									;
									
								},
							onSelect:
								function(index,row)
								{
									$scope.selectedDataSourceRow = row;
									
									$scope.refreshSubsetColumn1Values();
									$scope.refreshSubsetColumn2Values();
									
								}
						}
				)
				;
				
			}
			
			$scope.refreshDataSources = function()
			{
				$("#UploadAndPrepData3-dataSources").datagrid("reload");
				
			}
			
			$scope.setDataSourceSubsetColumn1Name = function(dataSourceId, subsetColumn1Name)
			{
				postData
				(
						"setDataSourceSubsetColumn1Name",
						{"dataSourceId": dataSourceId, "subsetColumn1Name": subsetColumn1Name, },
						true,
						function(response)
						{
							// update counts
							
							$scope.updateCounts(response);
							
							// refresh values
							
							$scope.refreshSubsetColumn1Values();
							
						}
				);
				
			}
			
			$scope.setDataSourceSubsetColumn2Name = function(dataSourceId, subsetColumn2Name)
			{
				postData
				(
						"setDataSourceSubsetColumn2Name",
						{"dataSourceId": dataSourceId, "subsetColumn2Name": subsetColumn2Name, },
						true,
						function(response)
						{
							// update counts
							
							$scope.updateCounts(response);
							
							// refresh values
							
							$scope.refreshSubsetColumn2Values();
							
						}
				);
				
			}
			
			// subsetColumn1Values
			
			$scope.initializeSubsetColumn1Values = function()
			{
				$("#UploadAndPrepData3-subsetColumn1Values").datagrid
				(
						{
							fit: true,
							/*fitColumns: true,*/
							onBeforeSelect: function(){return false;},
							url: "data/getDataSourceSubsetColumn1Values",
							columns:
								[[
									{field: "ck", checkbox: true, },
									{
										field: "value",
										title: getMessage("UploadAndPrepData3.subsetColumn1Values.column.value"),
										width: 130,
										fixed: true,
									},
									{
										field: "frequency",
										title: getMessage("UploadAndPrepData3.subsetColumn1Values.column.frequency"),
										align: "right",
										halign: "left",
										width: 70,
										fixed: true,
									},
								]],
							onLoadSuccess:
								function()
								{
									// enable or disable checkboxes depending on the role
									
									$(this).datagrid("getPanel").find("input[type=checkbox]").prop("disabled", !$scope.editable);
	
								},
							onCheckAll:
								function()
								{
									$scope.setDataSourceSubsetColumn1SelectedValues(null, true);
									
								},
							onUncheckAll:
								function()
								{
									$scope.setDataSourceSubsetColumn1SelectedValues(null, false);
									
								},
							onCheck:
								function(index, row)
								{
									$scope.setDataSourceSubsetColumn1SelectedValues(row["value"], true);
									
								},
							onUncheck:
								function(index, row)
								{
									$scope.setDataSourceSubsetColumn1SelectedValues(row["value"], false);
									
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", (200 + $rootScope.tableScrollbarWidth + $rootScope.tableCheckColumnWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshSubsetColumn1Values = function()
			{
				var selectedRow = $("#UploadAndPrepData3-dataSources").datagrid("getSelected");
				
				if (selectedRow)
				{
					var dataSourceId = selectedRow["id"];
					
					$("#UploadAndPrepData3-subsetColumn1Values").datagrid({"queryParams": {"dataSourceId": dataSourceId, }, });
					
				}

			}
			
			$scope.clearSubsetColumn1Values = function()
			{
				$("#UploadAndPrepData3-subsetColumn1Values").datagrid({"queryParams": {"dataSourceId": null, }, });

			}
			
			$scope.setDataSourceSubsetColumn1SelectedValues = function(value, selected)
			{
				var selectedRow = $("#UploadAndPrepData3-dataSources").datagrid("getSelected");
				
				if (selectedRow)
				{
					var dataSourceId = selectedRow["id"];
					
					// send update
					
					postData
					(
							"setDataSourceSubsetColumn1SelectedValues",
							queryParameters = {"dataSourceId": dataSourceId, "value": value, "selected": selected, },
							true,
							function(response)
							{
								// update counts
								
								$scope.updateCounts(response);
								
							}
					)
					;
					
				}
				
			}
			
			// subsetColumn2Values
			
			$scope.initializeSubsetColumn2Values = function()
			{
				$("#UploadAndPrepData3-subsetColumn2Values").datagrid
				(
						{
							fit: true,
							/*fitColumns: true,*/
							onBeforeSelect: function(){return false;},
							url: "data/getDataSourceSubsetColumn2Values",
							columns:
								[[
									{field: "ck", checkbox: true, },
									{
										field: "value",
										title: getMessage("UploadAndPrepData3.subsetColumn2Values.column.value"),
										width: 130,
										fixed: true,
									},
									{
										field: "frequency",
										title: getMessage("UploadAndPrepData3.subsetColumn2Values.column.frequency"),
										align: "right",
										halign: "left",
										width: 70,
										fixed: true,
									},
								]],
							onLoadSuccess:
								function()
								{
									// enable or disable checkboxes depending on the role
									
									$(this).datagrid("getPanel").find("input[type=checkbox]").prop("disabled", !$scope.editable);
	
								},
							onCheckAll:
								function()
								{
									$scope.setDataSourceSubsetColumn2SelectedValues(null, true);
									
								},
							onUncheckAll:
								function()
								{
									$scope.setDataSourceSubsetColumn2SelectedValues(null, false);
									
								},
							onCheck:
								function(index, row)
								{
									$scope.setDataSourceSubsetColumn2SelectedValues(row["value"], true);
									
								},
							onUncheck:
								function(index, row)
								{
									$scope.setDataSourceSubsetColumn2SelectedValues(row["value"], false);
									
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", (200 + $rootScope.tableScrollbarWidth + $rootScope.tableCheckColumnWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshSubsetColumn2Values = function()
			{
				var selectedRow = $("#UploadAndPrepData3-dataSources").datagrid("getSelected");
				
				if (selectedRow)
				{
					var dataSourceId = selectedRow["id"];
					
					$("#UploadAndPrepData3-subsetColumn2Values").datagrid({"queryParams": {"dataSourceId": dataSourceId, }, });
					
				}

			}
			
			$scope.clearSubsetColumn2Values = function()
			{
				$("#UploadAndPrepData3-subsetColumn2Values").datagrid({"queryParams": {"dataSourceId": null, }, });

			}
			
			$scope.setDataSourceSubsetColumn2SelectedValues = function(value, selected)
			{
				var selectedRow = $("#UploadAndPrepData3-dataSources").datagrid("getSelected");
				
				if (selectedRow)
				{
					var dataSourceId = selectedRow["id"];
					
					// send update
					
					postData
					(
							"setDataSourceSubsetColumn2SelectedValues",
							queryParameters = {"dataSourceId": dataSourceId, "value": value, "selected": selected, },
							true,
							function(response)
							{
								// update counts
								
								$scope.updateCounts(response);
								
							}
					)
					;
					
				}
				
			}
			
			// counts
			
			$scope.updateCounts = function(response)
			{
				// update subsetColumn1ValueCount

				var panel = $("#UploadAndPrepData3-dataSources").datagrid("getPanel");
				$(panel).find("tr.datagrid-row.datagrid-row-selected td[field='subsetColumn1ValueCount']>div")
				.text(response.subsetColumn1ValueCount);

				// update subsetColumn2ValueCount

				var panel = $("#UploadAndPrepData3-dataSources").datagrid("getPanel");
				$(panel).find("tr.datagrid-row.datagrid-row-selected td[field='subsetColumn2ValueCount']>div")
				.text(response.subsetColumn2ValueCount);

				// update nRows

				var panel = $("#UploadAndPrepData3-dataSources").datagrid("getPanel");
				$(panel).find("tr.datagrid-row.datagrid-row-selected td[field='nRows']>div")
				.text(response.nRows);
				
			}
			
		}
)
;

