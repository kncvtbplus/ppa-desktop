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
							columns:
								[[
									{field: "ck", checkbox: true, },
									{field: "metricName", title: getMessage("SelectPpaMetrics1.column.metricName"), width: 190, fixed: true, },
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
									
								},
							onCheckAll:
								function()
								{
									$scope.setMetricSelected(null, true);
									
								},
							onUncheckAll:
								function()
								{
									$scope.setMetricSelected(null, false);
									
								},
							onCheck:
								function(index,row)
								{
									$scope.setMetricSelected(row["id"], true);
									
								},
							onUncheck:
								function(index,row)
								{
									$scope.setMetricSelected(row["id"], false);
									
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", ($rootScope.tableCheckColumnWidth + 190 + $rootScope.tableScrollbarWidth).toString() + "px")
				.addClass("datagrid-nocheckbox")
				;
				
			}
			
			$scope.refreshMetrics = function()
			{
				$("#SelectPpaMetrics1-ppaMetrics").datagrid("reload");

			}
			
			$scope.setMetricSelected = function(metricId, selected)
			{
				postData("setMetricSelected", {"metricId": metricId, "selected": selected, });
				
			}
			
		}
)
;

