application.controller
(
		"SelectOutputTypeAndGo1",
		function($rootScope, $scope, $sce)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// variables
			
			$scope.outputId;
			$scope.selectedRow;
			
			// page open
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				$scope.editable = $rootScope.user.administrator;
				
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					
					$scope.initializeOutputs();
					$scope.initializeChartRegion();
					
				}
				else
				{
					// refresh
					
					$scope.closeChartRegion();
					$scope.refresh();
					$scope.displayChart();
					
				}
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.dataSourceLabel = getMessage("common.label.dataSource");
				$scope.title = $scope.trustAsHtml(getMessage("SelectOutputTypeAndGo1.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("SelectOutputTypeAndGo1.subtitle"));
				
			}
			
			// refresh
			
			$scope.refresh = function()
			{
				$scope.refreshOutputs();
				
			}
			
			// outputs
			
			$scope.initializeOutputs = function()
			{
				$("#SelectOutputTypeAndGo1-outputs").datagrid
				(
						{
							fit: true,
							/*fitColumns: true,*/
							singleSelect: true,
							idField: "id",
							url: "data/getOutputs",
							columns:
								[[
									{
										field: "created",
										title: getMessage("SelectOutputTypeAndGo1.outputs.column.created"),
										width: 150,
										fixed: true,
									},
									{
										field: "fileName",
										title: getMessage("SelectOutputTypeAndGo1.outputs.column.file"),
										width: 100,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var output =
													"<a class='SelectOutputTypeAndGo1-outputs-download'" +
													" outputId='" + row["id"] + "'" +
													"></a>"
												;
												
												return output;
												
											},
									},
									{
										field: "delete",
										title: getMessage("SelectOutputTypeAndGo1.outputs.column.delete"),
										width: 100,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var output;
												
												if (value)
												{
													output =
														"<a class='SelectOutputTypeAndGo1-outputs-delete'" +
														" outputId='" + row["id"] + "'" +
														"></a>"
													;
													
												}
												else
												{
													output = "";
													
												}
												
												return output;
												
											},
									},
								]],
							toolbar:
								[
									{
										disabled: !$scope.editable,
										iconCls: "icon-add",
										text: getMessage("SelectOutputTypeAndGo1.generateOutput"),
										handler:
											function()
											{
												$scope.generateOutput();
												
											}
									},
								],
							onLoadSuccess:
								function(data)
								{
									// keep selection
									
									$(this).datagrid("unselectAll");
									
									if ($scope.selectedRow)
									{
										$("#SelectOutputTypeAndGo1-outputs").datagrid("selectRecord", $scope.selectedRow["id"]);
										
									}

									// render download
									
									$(".SelectOutputTypeAndGo1-outputs-download").each
									(
											function(index, element)
											{
												var outputId = element.getAttribute("outputId");
												
												$(this).linkbutton
												(
														{
															iconCls: "icon-download",
										                    onClick:
																function()
																{
																	$scope.getOutput(outputId);
																	
																},
														}
												)
												.click
												(
														function (e)
														{
															e.stopPropagation();
														}
												)
												;
												
											}
									)
									;
									
									// render delete
									
									$(".SelectOutputTypeAndGo1-outputs-delete").each
									(
											function(index, element)
											{
												var outputId = element.getAttribute("outputId");
												
												$(this).linkbutton
												(
														{
															disabled: !$scope.editable,
															iconCls: "icon-delete",
															onClick:
																function()
																{
																	$scope.deleteOutput(outputId);
																	
																},
														}
												)
												.click
												(
														function (e)
														{
															e.stopPropagation();
														}
												)
												;
												
											}
									)
									;
									
								},
				            onSelect:
				            	function(index, row)
				            	{
				            		$scope.refreshChartRegion(row["id"]);
				            		
				            	},
						}
				)
				.datagrid("getPanel")
				.css("max-width", (350 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshOutputs = function()
			{
				$scope.selectedRow = $("#SelectOutputTypeAndGo1-outputs").datagrid("getSelected");
				
				$("#SelectOutputTypeAndGo1-outputs").datagrid("reload");
				
			}
			
			$scope.generateOutput = function()
			{
				// check all PpaSectorLevels mapped
				
				if (!getData("getAllPpaSectorLevelMapped").value)
				{
					$.messager.alert
					(
							getMessage("common.dialog.error.title"),
							getMessage("MapHealthSectorsAndLevels2.ppaSectorMapping.missingMappingWarning.message"),
							"error"
					);
					
					return;
					
				}
				
				// check all AggregationLevels mapped
				
				if (!getData("getAllAggregationLevelMapped").value)
				{
					$.messager.alert
					(
							getMessage("common.dialog.error.title"),
							getMessage("MapAggregationLevels2.ppaSectorMapping.missingMappingWarning.message"),
							"warning"
					);
					
					return;
					
				}
				
				// generate output and refresh outputs
				
				postData("generateOutput", null, true, $scope.refreshOutputs);
				
			}
			
			$scope.deleteOutput = function(outputId)
			{
				// delete
				
				postData
				(
						"deleteOutputs",
						{"outputIds": [outputId, ], },
						true,
						function()
						{
							// delete output grid row
							
							var deletedRowIndex = $("#SelectOutputTypeAndGo1-outputs").datagrid("getRowIndex", outputId);
							$("#SelectOutputTypeAndGo1-outputs").datagrid("deleteRow", deletedRowIndex);
							
							// hide char area if there is no selected output row
							
							var selectedOutputRow = $("#SelectOutputTypeAndGo1-outputs").datagrid("getSelected");
							
							if (selectedOutputRow == null)
							{
								$scope.closeChartRegion();
								
							}
							
						}
				)
				;
				
			}
			
			// chart region
			
			$scope.initializeChartRegion = function()
			{
				// chart selector
				
				$("#SelectOutputTypeAndGo1-chartSelector").combobox
				(
						{
							valueField: "chartFileName",
							textField: "subnationalUnit",
							onLoadSuccess:
								function(data)
								{
									if (data.length >= 1)
									{
										$(this).combobox("setValue", data[0]["chartFileName"]);
										
									}
									
								},
		                    onChange:
								function(chartFileName)
								{
									$scope.displayChart(chartFileName);
									
								},
							
						}
				)
				;
				
			}
			
			$scope.openChartRegion = function()
			{
				$("#SelectOutputTypeAndGo1-chartRegion").panel("open");
				
			}
			
			$scope.closeChartRegion = function()
			{
				$("#SelectOutputTypeAndGo1-chartRegion").panel("close");
				
			}
			
			$scope.refreshChartRegion = function(outputId)
			{
				$scope.outputId = outputId;
				
				$("#SelectOutputTypeAndGo1-chartSelector").combobox({url: "data/getOutputCharts", queryParams: {"outputId": outputId, }, });
				$scope.openChartRegion();
				
			}
			
			$scope.getOutput = function(outputId)
			{
				if (outputId)
				{
					$("#SelectOutputTypeAndGo1-getOutput-outputId").val(outputId);
					$("#SelectOutputTypeAndGo1-getOutput").submit();
					
				}
				
			}
			
			// chart
			
			$scope.displayChart = function(chartFileName)
			{
				if (chartFileName)
				{
					getDataAsync
					(
							"getChartImageBase64String",
							{"chartFileName": chartFileName, },
							function(response)
							{
								if (response.hasOwnProperty("chartImageBase64String"))
								{
									var chartImageBase64String = response["chartImageBase64String"];
									
									$("#SelectOutputTypeAndGo1-content-chart").css("background", "url(data:image/png;base64," + chartImageBase64String + ") center/contain no-repeat");
									
								}
								
							}
					)
					;
					
				}
				else
				{
					$("#SelectOutputTypeAndGo1-content-chart").css("background", "");
					
				}
				
			}
			
		}
)
;

