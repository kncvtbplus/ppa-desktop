application.controller
(
		"SetPPASpecifications",
		function($rootScope, $scope, $sce)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// page open
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				if (!$scope.initialized)
				{
					$scope.initialize();
					$scope.initialized = true;
					
				}
				else
				{
					// refresh ppaSpecifications
					
					$scope.refreshPpaSpecifications();
					
				}
				
			}
			
			// initialization
			
			$scope.initialize = function()
			{
				// create ppaSpecifications
				
				$("#SetPPASpecifications-ppaSpecifications").datagrid
				(
						{
							fit: true,
				            onBeforeSelect: function(){return false;},
							url: "data/getMetrics",
							columns:
								[[
									{field: "metricName", title: getMessage("SetPPASpecifications.column.metricName"), },
									{
										field: "dataPointName",
										title: getMessage("SetPPASpecifications.column.dataPointName"),
										formatter:
											function(value,row,index)
											{
												var output =
													"<input class='SetPPASpecifications-dataPointNameTextbox'" +
													" data-options='value: \"" + value + "\", metricId: " + row["metricId"] + ", '" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "dataSourceIds",
										title: getMessage("SetPPASpecifications.column.dataSource"),
										formatter:
											function(value,row,index)
											{
												var output =
													"<input class='SetPPASpecifications-dataSourceCombobox'" +
													" value='" + value + "'" +
													" metricId='" + row["metricId"] + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
								]],
							onLoadSuccess:
								function()
								{
									// render dataPointNameTextbox
									
									$(".SetPPASpecifications-dataPointNameTextbox").each
									(
											function(index, element)
											{
												// expand element to cell width
												
												$(element).width($(element).parent().width());
												
												// render component
												
												$(element).textbox
												(
														{
															onChange:
																function(newValue)
																{
																	var options = $(this).textbox("options");
																	
																	call("SetPPASpecifications", "setDataPointName", [options["metricId"], newValue, ]);
																	
																}
														}
												)
												;
												
											}
									)
									;
									
									// render dataSourceCombobox
									
									var dataSources = getData("getDataSources", {});
									
									$(".SetPPASpecifications-dataSourceCombobox").each
									(
											function(index, element)
											{
												// expand element to cell width
												
												$(element).width($(element).parent().width());
												
												// get additional variables
												
												var metricId = element.getAttribute("metricId");
												
												// render component
												
												$(element).combobox
												(
														{
															valueField: "id",
															textField: "fileName",
															data: dataSources,
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
																	var options = $(this).textbox("options");
																	
																	call("SetPPASpecifications", "setPpaMetricDataSources", [metricId, newValue, ]);
																	
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
				;
				
			}
			
			// refresh ppaSpecifications
			
			$scope.refreshPpaSpecifications = function()
			{
				$("#SetPPASpecifications-ppaSpecifications").datagrid("reload");

			}
			
			// dataPointName
			
			$scope.setDataPointName = function(metricId, dataPointName)
			{
				postData("setMetricDataPointName", {"metricId": metricId, "dataPointName": dataPointName, });
				
			}
			
			// dataSources
			
			$scope.setPpaMetricDataSources = function(metricId, dataSourceIds)
			{
				postData("setPpaMetricDataSources", {"metricId": metricId, "dataSourceIds": [dataSourceIds, ], });
				
			}
			
		}
)
;

