application.controller
(
		"SelectPpaMetrics1",
		function($rootScope, $scope, $sce)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// page open
			
			$scope.initialized = false;
			$scope.showSelectedOnly = false;
			$scope.onOpen = function()
			{
				// Local installer: all users can edit PPA settings.
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
				$scope.title = $scope.trustAsHtml(getMessage("SelectPpaMetrics1.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("SelectPpaMetrics1.subtitle"));
				
			}
			
			// ppaMetrics
			
			$scope.initializeMetrics = function()
			{
				$("#SelectPpaMetrics1-ppaMetrics").datagrid
				(
						{
							fit: true,
							/*fitColumns: false,*/
				            onBeforeSelect: function(){return false;},
							url: "data/getMetrics",
							toolbar:
								[
									{
										id: "SelectPpaMetrics1-filterButton",
										iconCls: "icon-filter",
										text: getMessage("SelectPpaMetrics1.filter.showSelected"),
										handler:
											function()
											{
												$scope.toggleFilter();
												
											},
									},
								],
							columns:
								[[
									{field: "ck", checkbox: true, },
									{field: "metricName", title: getMessage("SelectPpaMetrics1.column.metricName"), width: 190, fixed: true, },
									{
										field: "dataPointName",
										title: getMessage("SelectPpaMetrics1.column.dataPointName"),
										width: 500,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var safeValue = (value != null ? value : "");
												var output =
													"<input class='easyui-element SelectPpaMetrics1-dataPointNameTextbox'" +
													" id='SelectPpaMetrics1-dpn-" + row["metricId"] + "'" +
													" data-options='value: \"" + safeValue + "\", metricId: " + row["metricId"] + ", '" +
													"/>"
												;
												
												return output;
												
											},
									},
								]],
							onLoadSuccess:
								function(data)
								{
									var options = $(this).datagrid("options");
									
									// enable or disable checkboxes depending on the role
									
									$(this).datagrid("getPanel").find("input[type=checkbox]").prop("disabled", !$scope.editable);
	
									// disable check function
									
									var onCheckSaved = options.onCheck;
									options.onCheck = function(){};
									
									// set checkboxes
									
									for (i = 0; i < data.rows.length; ++i)
									{
										// disable checkbox for required metrics
										
										if (data.rows[i]["required"])
										{
											var tr = options.finder.getTr(this, i);
											tr.find('input[type=checkbox]').attr('disabled', true);
											
										}
										
					            		// check selected metrics
					            		
										if (data.rows[i]["selected"])
										{
											$(this).datagrid("checkRow", i);
											
										}
										
									}
									
									// enable check function
									
									options.onCheck = onCheckSaved;
									
									// render dataPointName textboxes
									
									$(".SelectPpaMetrics1-dataPointNameTextbox").each
									(
											function(index, element)
											{
												$(element).width($(element).parent().width());
												
												$(element).textbox
												(
														{
															disabled: !$scope.editable,
															
															onChange:
																function(newValue)
																{
																	var options = $(this).textbox("options");
																	
																	call("SelectPpaMetrics1", "setMetricDataPointName", [options["metricId"], newValue, ]);
																	
																}
														}
												)
												;
												
												$(element).textbox("textbox").prop("maxlength", 50);
												
											}
									)
									;
									
									// disable textboxes for unselected metrics
									
									for (i = 0; i < data.rows.length; ++i)
									{
										if (!data.rows[i]["selected"])
										{
											$("#SelectPpaMetrics1-dpn-" + data.rows[i]["metricId"]).textbox("disable");
											
										}
										
									}
									
									// apply filter visibility if active
									
									if ($scope.showSelectedOnly)
									{
										$scope.applyFilter();
									}
									
								},
							onCheckAll:
								function()
								{
									$scope.setMetricSelected(null, true);
									$(".SelectPpaMetrics1-dataPointNameTextbox").each(function()
									{
										$(this).textbox("enable");
									});
									if ($scope.showSelectedOnly)
									{
										$scope.applyFilter();
									}
									
								},
							onUncheckAll:
								function()
								{
									$scope.setMetricSelected(null, false);
									$(".SelectPpaMetrics1-dataPointNameTextbox").each(function()
									{
										$(this).textbox("disable");
									});
									var data = $("#SelectPpaMetrics1-ppaMetrics").datagrid("getData");
									for (var i = 0; i < data.rows.length; i++)
									{
										if (data.rows[i]["required"])
										{
											$("#SelectPpaMetrics1-dpn-" + data.rows[i]["metricId"]).textbox("enable");
										}
									}
									if ($scope.showSelectedOnly)
									{
										$scope.applyFilter();
									}
									
								},
							onCheck:
								function(index,row)
								{
									$scope.setMetricSelected(row["id"], true);
									$("#SelectPpaMetrics1-dpn-" + row["metricId"]).textbox("enable");
									
								},
							onUncheck:
								function(index,row)
								{
									$scope.setMetricSelected(row["id"], false);
									$("#SelectPpaMetrics1-dpn-" + row["metricId"]).textbox("disable");
									if ($scope.showSelectedOnly)
									{
										$scope.applyFilter();
									}
									
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", ($rootScope.tableCheckColumnWidth + 190 + 500 + $rootScope.tableScrollbarWidth).toString() + "px")
				.addClass("datagrid-nocheckbox")
				;
				
			}
			
			$scope.refreshMetrics = function()
			{
				$("#SelectPpaMetrics1-ppaMetrics").datagrid("reload");

			}
			
			$scope.toggleFilter = function()
			{
				$scope.showSelectedOnly = !$scope.showSelectedOnly;
				var $btn = $("#SelectPpaMetrics1-filterButton");
				
				if ($scope.showSelectedOnly)
				{
					$btn.addClass("filter-active");
					$btn.find(".l-btn-text").text(getMessage("SelectPpaMetrics1.filter.showAll"));
					$scope.applyFilter();
				}
				else
				{
					$btn.removeClass("filter-active");
					$btn.find(".l-btn-text").text(getMessage("SelectPpaMetrics1.filter.showSelected"));
					$scope.showAllRows();
				}
				
			}
			
			$scope.applyFilter = function()
			{
				var dg = $("#SelectPpaMetrics1-ppaMetrics");
				var options = dg.datagrid("options");
				var panel = dg.datagrid("getPanel");
				var rows = dg.datagrid("getRows");
				
				for (var i = 0; i < rows.length; i++)
				{
					var tr = options.finder.getTr(panel, i);
					var trAlt = options.finder.getTr(panel, i, "body", 2);
					
					if (!rows[i]["selected"])
					{
						$(tr).hide();
						if (trAlt.length) $(trAlt).hide();
					}
					else
					{
						$(tr).show();
						if (trAlt.length) $(trAlt).show();
					}
				}
				
			}
			
			$scope.showAllRows = function()
			{
				var dg = $("#SelectPpaMetrics1-ppaMetrics");
				var options = dg.datagrid("options");
				var panel = dg.datagrid("getPanel");
				var rows = dg.datagrid("getRows");
				
				for (var i = 0; i < rows.length; i++)
				{
					var tr = options.finder.getTr(panel, i);
					var trAlt = options.finder.getTr(panel, i, "body", 2);
					
					$(tr).show();
					if (trAlt.length) $(trAlt).show();
				}
				
			}
			
			$scope.setMetricSelected = function(metricId, selected)
			{
				postData("setMetricSelected", {"metricId": metricId, "selected": selected, });
				
			}
			
			$scope.setMetricDataPointName = function(metricId, dataPointName)
			{
				postData("setMetricDataPointName", {"metricId": metricId, "dataPointName": dataPointName, });
				
			}
			
		}
)
;
