application.controller
(
		"IdentifyPpaVariables2",
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
				// Local installer: all users can map PPA variables.
				$scope.editable = true;
				
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					$scope.initializeMetrics();
					$scope.initializeMetricColumnValues();
					
				}
				else
				{
					// refresh elements
					
					$scope.clearMetricColumnValues();
					$scope.refreshMetrics();
					
				}
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.title = $scope.trustAsHtml(getMessage("IdentifyPpaVariables2.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("IdentifyPpaVariables2.subtitle"));
				
			}
			
			// Metrics
			
			$scope.initializeMetrics = function()
			{
				$("#IdentifyPpaVariables2-metrics").datagrid
				(
						{
							fit: true,
							/*fitColumns: false,*/
							singleSelect: true,
							idField: "metricId",
							url: "data/getMetrics",
							queryParams: {"columnValueFilter": true, "selected" : true, "dataSourceAssigned": true, },
							columns:
								[[
									{
										field: "dataPointName",
										title: getMessage("IdentifyPpaVariables2.metrics.column.metricName"),
										width: 350,
										fixed: true,
									},
									{
										field: "userFileName",
										title: getMessage("IdentifyPpaVariables2.metrics.column.dataSource"),
										width: 350,
										fixed: true,
									},
									{
										field: "dataSourceColumnName",
										title: getMessage("IdentifyPpaVariables2.metrics.column.dataSourceColumnName"),
										width: 250,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<input class='easyui-element IdentifyPpaVariables2-dataSourceColumnNameCombobox'" +
													" metricId='" + row["metricId"] + "'" +
													" dataSourceId='" + row["dataSourceId"] + "'" +
													" value='" + value + "'" +
													" />"
												;
												
												return output;
												
											},
									},
									{
										field: "valueCount",
										title: getMessage("IdentifyPpaVariables2.metrics.column.valueCount"),
										width: 110,
										fixed: true,
										align: "right",
										halign: "left",
									},
								]],
							onLoadSuccess:
								function(data)
								{
									// keep selection
									
									$(this).datagrid("unselectAll");
									
									if ($scope.selectedDataSourceRow)
									{
										$(this).datagrid("selectRecord", $scope.selectedDataSourceRow["metricId"]);
										
									}
									else
									{
										$scope.clearMetricColumnValues();
										
									}
								
									// render dataSourceColumnNameCombobox
									
									$(".IdentifyPpaVariables2-dataSourceColumnNameCombobox").each
									(
											function(index, element)
											{
												var metricId = element.getAttribute("metricId")
												var dataSourceId = element.getAttribute("dataSourceId")
												
												var data = getData("getDataSourceColumnNames", {"dataSourceId": dataSourceId, });
												
												$(element).combobox
												(
														{
															disabled: !$scope.editable,
															valueField: "value",
															textField: "value",
															data: data,
															onChange:
																function(newValue)
																{
																	$scope.setMetricDataSourceColumnName(metricId, newValue);
																	
																}
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
									$scope.updateMetricColumnValues();
									
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", (1060 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshMetrics = function()
			{
				$scope.selectedDataSourceRow = $("#IdentifyPpaVariables2-metrics").datagrid("getSelected");
				
				$("#IdentifyPpaVariables2-metrics").datagrid("reload");
				
			}
			
			$scope.setMetricDataSourceColumnName = function(metricId, dataSourceColumnName)
			{
				postData
				(
						"setMetricDataSourceColumnName",
						{"metricId": metricId, "dataSourceColumnName": dataSourceColumnName, },
						true,
						function()
						{
							$scope.updateMetricColumnValues();
							
						}
				)
				;
				
			}
			
			// MetricColumnValues
			
			$scope.initializeMetricColumnValues = function()
			{
				$("#IdentifyPpaVariables2-metricColumnValues").datagrid
				(
						{
							fit: true,
							/*fitColumns: true,*/
				            onBeforeSelect: function(){return false;},
							onClickRow:
								function(index, row)
								{
									var t = window.event ? window.event.target : null;
									if (t && $(t).closest('input,textarea,select,.textbox,.combo,.datagrid-cell-check').length) return;
									var dg = $(this);
									var checked = dg.datagrid("getChecked");
									var isChecked = false;
									for (var i = 0; i < checked.length; i++) { if (checked[i] === row) { isChecked = true; break; } }
									dg.datagrid(isChecked ? "uncheckRow" : "checkRow", index);
								},
							url: "data/getMetricColumnValues",
							columns:
								[[
									{field: "ck", checkbox: true, },
									{field: "value", title: getMessage("common.label.value"), width: 250, fixed: true, },
									{field: "count", title: getMessage("common.label.count"), width: 70, fixed: true, align: "right", halign: "left", },
								]],
							onLoadSuccess:
								function(data)
								{
									// save onCheck handler
									
									var onCheckHandler = $(this).datagrid("options").onCheck;
									
									// disable onCheck handler
									
									$(this).datagrid("options").onCheck = function(){};
									
									// check checked rows
									
									var rows = $(this).datagrid("getRows");
									for(var i = 0; i < rows.length; i++)
									{
										if (rows[i]["checked"] == 1)
										{
											$(this).datagrid("checkRow", i);
											
										}
										
									}
									
									// enable onCheck handler
									
									$(this).datagrid("options").onCheck = onCheckHandler;
									
									// enable or disable checkboxes depending on the role
									
									$(this).datagrid("getPanel").find("input[type=checkbox]").prop("disabled", !$scope.editable);
	
								},
							onCheck:
								function()
								{
									$scope.setMetricSelectedColumnValues();
									
								},
							onUncheck:
								function()
								{
									$scope.setMetricSelectedColumnValues();
									
								},
							onCheckAll:
								function()
								{
									$scope.setMetricSelectedColumnValues();
									
								},
							onUncheckAll:
								function()
								{
									$scope.setMetricSelectedColumnValues();
									
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", ($rootScope.tableCheckColumnWidth + 320 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.clearMetricColumnValues = function()
			{
				$("#IdentifyPpaVariables2-metricColumnValues").datagrid("reload", {"metricDataSourceId": null, });

			}
			
			$scope.updateMetricColumnValues = function()
			{
				var metricsSelectedRow = $("#IdentifyPpaVariables2-metrics").datagrid("getSelected");
				
				if (metricsSelectedRow)
				{
					var metricId = metricsSelectedRow["metricId"];
					
					$("#IdentifyPpaVariables2-metricColumnValues").datagrid("reload", {"metricId": metricId, });
					
				}

			}
			
			$scope.setMetricSelectedColumnValues = function()
			{
				var selectedMetricsRow = $("#IdentifyPpaVariables2-metrics").datagrid("getSelected");
				
				if (selectedMetricsRow)
				{
					var metricId = selectedMetricsRow["metricId"];
					
					var checkedMetricValues = $("#IdentifyPpaVariables2-metricColumnValues").datagrid("getChecked");
					
					var selectedColumnValues = fieldValueList(checkedMetricValues, "value");
					
					postData
					(
							"setMetricSelectedColumnValues",
							{"metricId": metricId, "selectedColumnValues": selectedColumnValues, },
							true,
							function()
							{
								// update value count
								
								var valueCount = 0;
								
								checkedMetricValues.forEach
								(
										function(checkedMetricValue)
										{
											valueCount += checkedMetricValue["count"];
											
										}
								)
								;
								

								var panel = $("#IdentifyPpaVariables2-metrics").datagrid("getPanel");
								$(panel).find("tr.datagrid-row.datagrid-row-selected td[field='valueCount']>div").text(valueCount.toString());
								
							}
					)
					;
					
				}
				
			}
			
		}
)
;

