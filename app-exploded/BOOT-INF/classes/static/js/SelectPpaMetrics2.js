application.controller
(
		"SelectPpaMetrics2",
		function($rootScope, $scope, $sce)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// page open
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				$scope.editable = $rootScope.user.administrator;
				
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					$scope.initializePpaMetrics();
					
				}
				else
				{
					$scope.refreshPpaMetrics();
					
				}
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.title = $scope.trustAsHtml(getMessage("SelectPpaMetrics2.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("SelectPpaMetrics2.subtitle"));
				
			}
			
			// ppaMetrics
			
			$scope.initializePpaMetrics = function()
			{
				$("#SelectPpaMetrics2-ppaMetrics").datagrid
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
										field: "metricName",
										title: getMessage("SelectPpaMetrics2.column.metricName"),
										width: 190,
										fixed: true,
									},
									{
										field: "dataPointName",
										title: getMessage("SelectPpaMetrics2.column.dataPointName"),
										width: 500,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<input class='easyui-element SelectPpaMetrics2-dataPointNameTextbox'" +
													" data-options='value: \"" + value + "\", metricId: " + row["metricId"] + ", '" +
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
									
									$(".SelectPpaMetrics2-dataPointNameTextbox").each
									(
											function(index, element)
											{
												// expand element to cell width
												
												$(element).width($(element).parent().width());
												
												// render component
												
												$(element).textbox
												(
														{
															disabled: !$scope.editable,
															
															onChange:
																function(newValue)
																{
																	var options = $(this).textbox("options");
																	
																	call("SelectPpaMetrics2", "setMetricDataPointName", [options["metricId"], newValue, ]);
																	
																}
														}
												)
												;
												
												// set maxlength property
												
												$(element).textbox("textbox").prop("maxlength", 50);
												
											}
									)
									;
									
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", (690 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshPpaMetrics = function()
			{
				$("#SelectPpaMetrics2-ppaMetrics").datagrid("reload");

			}
			
			$scope.setMetricDataPointName = function(metricId, dataPointName)
			{
				postData("setMetricDataPointName", {"metricId": metricId, "dataPointName": dataPointName, });
				
			}
			
		}
)
;

