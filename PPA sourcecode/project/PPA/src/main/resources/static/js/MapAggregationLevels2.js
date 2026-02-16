application.controller
(
		"MapAggregationLevels2",
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
				// Local installer: all users can map aggregation levels.
				$scope.editable = true;
				
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					$scope.initialize();
					
				}
				else
				{
					// refresh
					
					$scope.refresh();
					
				}
				
			}
			
			// page close
			
			$scope.onClose = function()
			{
				if (!getData("getAllAggregationLevelMapped").value)
				{
					$.messager.alert
					(
							getMessage("common.dialog.warning.title"),
							getMessage("MapAggregationLevels2.ppaSectorMapping.missingMappingWarning.message"),
							"warning"
					);
					
				}
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.dataSourceLabel = getMessage("common.label.dataSource");
				$scope.title = $scope.trustAsHtml(getMessage("MapAggregationLevels2.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("MapAggregationLevels2.subtitle"));
				
			}
			
			// initialization
			
			$scope.initialize = function()
			{
				$scope.initializeDataSources();
				
				$scope.initializeSubnationalUnitMapping();
				
			}
			
			// refresh
			
			$scope.refresh = function()
			{
				$scope.clearSubnationalUnitMapping();
				$scope.refreshDataSources();
				
			}
			
			// dataSources
			
			$scope.initializeDataSources = function()
			{
				$("#MapAggregationLevels2-dataSources").datagrid
				(
						{
							fit: true,
							/*fitColumns: false,*/
							singleSelect: true,
							idField: "id",
							url: "data/getAggregationLevelMappingDataSources",
							columns:
								[[
									{
										field: "fileName",
										title: getMessage("MapAggregationLevels2.dataSources.column.fileName"),
										width: 400,
										fixed: true,
									},
									{
										field: "mapped",
										title: getMessage("MapAggregationLevels2.dataSources.column.mapped"),
										width: 100,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var output;
												
												switch (value)
												{
												case "columnNotSet":
													output = "<img src=\"/images/warning.png\">";
													break;
													
												case "yes":
													output = "<div class='datagid-checkmark'>";
													break;
													
												case "no":
													output = "";
													break;
													
												}
												
												return output;
												
											},
									},
								]],
							onLoadSuccess:
								function(data)
								{
									// keep selection
									
									$(this).datagrid("unselectAll");
									
									if ($scope.selectedDataSourceRow)
									{
										$(this).datagrid("selectRecord", $scope.selectedDataSourceRow["id"]);
										
									}
									else
									{
										$scope.clearSubnationalUnitMapping();
										
									}
								
								},
							onSelect:
								function(index,row)
								{
									$scope.updateSubnationalUnitMapping(row["id"]);
									
									// check undefined mapped
									
									if (row["mapped"] == "columnNotSet")
									{
										showWarningMessage(getMessage("MapAggregationLevels2.dataSources.mappedUndefinedWarning.message", [row["aggregationLevel"], row["fileName"], ]));
	
									}
	
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", (500 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshDataSources = function()
			{
				$scope.selectedDataSourceRow = $("#MapAggregationLevels2-dataSources").datagrid("getSelected");
				
				$("#MapAggregationLevels2-dataSources").datagrid("reload");
				
			}
			
			// subnationalUnitMapping
			
			$scope.initializeSubnationalUnitMapping = function()
			{
				$("#MapAggregationLevels2-subnationalUnitMapping").datagrid
				(
						{
							fit: true,
							/*fitColumns: false,*/
				            onBeforeSelect: function(){return false;},
							view: scrollview,
							pageSize: 50,
							url: "data/getDataSourceSubnationalUnitMappings",
							columns:
								[[
									{
										field: "subnationalUnitId",
										title: getMessage("MapAggregationLevels2.subnationalUnitMapping.column.subnationalUnit"),
										width: 400,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<input class='easyui-element MapAggregationLevels2-subnationalUnitMapping-subnationalUnit' style='width: 100%; '" +
													" dataSourceId='" + row["dataSourceId"] + "'" +
													" value='" + value + "'" +
													" regionColumnValue='" + row["regionColumnValue"] + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "regionColumnValue",
										title: getMessage("MapAggregationLevels2.subnationalUnitMapping.column.regionColumnValue"),
										width: 400,
										fixed: true,
									},
									{
										field: "regionColumnValueFrequency",
										title: getMessage("MapAggregationLevels2.subnationalUnitMapping.column.regionColumnValueFrequency"),
										width: 100,
										fixed: true,
										align: "right",
										halign: "left",
									},
								]],
							onLoadSuccess:
								function(data)
								{
									// render subnationalUnit combobox
									
									var subnationalUnits = getData("getSubnationalUnits");
									
									$(".MapAggregationLevels2-subnationalUnitMapping-subnationalUnit").each
									(
											function(index, element)
											{
												// expand element to cell width
												
												$(element).width($(element).parent().width());
												
												// get additional variables
												
												var dataSourceId = element.getAttribute("dataSourceId");
												var regionColumnValue = element.getAttribute("regionColumnValue");
												
												// render component
												
												$(element).combobox
												(
														{
															disabled: !$scope.editable,
															valueField: "id",
															textField: "name",
															data: subnationalUnits,
										                    onChange:
																function(newValue)
																{
																	$scope.setDataSourceSubnationalUnitMapping(dataSourceId, regionColumnValue, newValue);
																	
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
				.css("max-width", (900 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.clearSubnationalUnitMapping = function()
			{
				$("#MapAggregationLevels2-subnationalUnitMapping").datagrid({"queryParams": {}, });

			}
			
			$scope.updateSubnationalUnitMapping = function(dataSourceId)
			{
				if (dataSourceId)
				{
					$("#MapAggregationLevels2-subnationalUnitMapping").datagrid("reload", {"dataSourceId": dataSourceId, });

				}
				
			}
			
			$scope.setDataSourceSubnationalUnitMapping = function(dataSourceId, regionColumnValue, subnationalUnitId)
			{
				if (dataSourceId)
				{
					postData
					(
							"setDataSourceSubnationalUnitMapping",
							{"dataSourceId": dataSourceId, "regionColumnValue": regionColumnValue, "subnationalUnitId": subnationalUnitId, },
							true,
							function(response)
							{
								if (response.mapped)
								{
									var selectedDataSourceRow = $("#MapAggregationLevels2-dataSources").datagrid("getSelected");
									
									if (selectedDataSourceRow)
									{
										var selectedDataSourceRowIndex = $("#MapAggregationLevels2-dataSources").datagrid("getRowIndex", selectedDataSourceRow);
										
										$("#MapAggregationLevels2-dataSources").datagrid
										(
												"updateRow",
												{
													index: selectedDataSourceRowIndex,
													row:
													{
														"mapped": true,
													},
												}
										)
										;
										
									}
									
								}
								
							}
					)
					;
					
				}
					
			}
			
		}
)
;

