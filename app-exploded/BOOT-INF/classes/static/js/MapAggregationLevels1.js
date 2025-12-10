application.controller
(
		"MapAggregationLevels1",
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
					
					$scope.initializeVaribles();
					$scope.initialize();
					
				}
				else
				{
					$scope.refresh();
					
				}
				
			}
			
			$scope.initializeVaribles = function()
			{
				$scope.dataSourceLabel = getMessage("common.label.dataSource");
				$scope.title = $scope.trustAsHtml(getMessage("MapAggregationLevels1.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("MapAggregationLevels1.subtitle"));
				
			}
			
			// initialization
			
			$scope.initialize = function()
			{
				$scope.initializeDataSource();
				
				$scope.initializeSubnationalUnits();
				
			}
			
			// refresh
			
			$scope.refresh = function()
			{
				$scope.refreshDataSource();
				
				$scope.refreshSubnationalUnits();
				
			}
			
			// dataSource
			
			$scope.initializeDataSource = function()
			{
				$("#MapAggregationLevels1-dataSource").combobox
				(
						{
							disabled: !$scope.editable,
							valueField: "id",
							textField: "fileName",
							url: "data/getDataSources",
							queryParams: {"subnationalUnitColumnNameSet": true, },
							onChange:
								function(newValue)
								{
									// enable populate button
									
									if (newValue)
									{
										$("#MapAggregationLevels1-populateSubnationalUnits").linkbutton("enable");
										
									}
									
								},
						}
				)
				;
				
			}
			
			$scope.refreshDataSource = function()
			{
				$("#MapAggregationLevels1-dataSource").combobox("reload");
				
			}
			
			// subnationalUnits
			
			$scope.initializeSubnationalUnits = function()
			{
				$("#MapAggregationLevels1-subnationalUnits").datagrid
				(
						{
							fit: true,
							/*fitColumns: false,*/
				            onBeforeSelect: function(){return false;},
							url: "data/getSubnationalUnits",
							columns:
								[[
									{field: "ck", checkbox: true, },
									{
										field: "name",
										title: /*getMessage("MapAggregationLevels1.subnationalUnits.column.name")*/$rootScope.user.selectedPpaAggregationLevelName,
										width: 500,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<input class='easyui-element MapAggregationLevels1-subnationalUnits-name' style='width: 100%; '" +
													" value='" + value + "'" +
													" subnationalUnitId='" + row["id"] + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
								]],
							toolbar:
								[
									{
										id: "MapAggregationLevels1-subnationalUnits-addButton",
										iconCls: "icon-add",
										text: getMessage("common.label.createNew"),
										handler:
											function()
											{
												$scope.addSubnationalUnit();
												
											},
									},
									{
										id: "MapAggregationLevels1-subnationalUnits-deleteCheckedButton",
										iconCls: "icon-delete",
										text: getMessage("common.label.deleteChecked"),
										disabled: true,
										handler:
											function()
											{
												$scope.deleteCheckedSubnationalUnits();
												
											},
									},
								],
							onLoadSuccess:
								function(data)
								{
									// render name box
									
									$(".MapAggregationLevels1-subnationalUnits-name").each
									(
											function(index, element)
											{
												var subnationalUnitId = element.getAttribute("subnationalUnitId");
												
												$(this).textbox
												(
														{
															disabled: !$scope.editable,
															onChange:
																function(newValue)
																{
																	$scope.setSubnationalUnitName(subnationalUnitId, newValue);
																	
																},
														}
												)
												;
												
											}
									)
									;
									
									// update check dependent button state
									
									updateCheckDependentButtonState("#MapAggregationLevels1-subnationalUnits", "#MapAggregationLevels1-subnationalUnits-deleteCheckedButton");
									
									// enable or disable checkboxes depending on the role
									
									$(this).datagrid("getPanel").find("input[type=checkbox]").prop("disabled", !$scope.editable);
	
								},
							onCheck:
								function()
								{
									updateCheckDependentButtonState("#MapAggregationLevels1-subnationalUnits", "#MapAggregationLevels1-subnationalUnits-deleteCheckedButton");
									
								},
							onUncheck:
								function()
								{
									updateCheckDependentButtonState("#MapAggregationLevels1-subnationalUnits", "#MapAggregationLevels1-subnationalUnits-deleteCheckedButton");
									
								},
							onCheckAll:
								function()
								{
									updateCheckDependentButtonState("#MapAggregationLevels1-subnationalUnits", "#MapAggregationLevels1-subnationalUnits-deleteCheckedButton");
									
								},
							onUncheckAll:
								function()
								{
									updateCheckDependentButtonState("#MapAggregationLevels1-subnationalUnits", "#MapAggregationLevels1-subnationalUnits-deleteCheckedButton");
									
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", ($rootScope.tableCheckColumnWidth + 500 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshSubnationalUnits = function()
			{
				$("#MapAggregationLevels1-subnationalUnits").datagrid("reload");

			}
			
			$scope.populateSubnationalUnits = function()
			{
				var dataSourceId = $("#MapAggregationLevels1-dataSource").combobox("getValue");
				
				if (dataSourceId)
				{
					// populate
					
					postData("populateSubnationalUnits", {"dataSourceId": dataSourceId, });
					
					// refresh
					
					$scope.refreshSubnationalUnits();
					
				}
				
			}
			
			$scope.addSubnationalUnit = function()
			{
				// add
				
				postData("createSubnationalUnit");
				
				// refresh
				
				$scope.refreshSubnationalUnits();
				
			}
			
			$scope.deleteCheckedSubnationalUnits = function()
			{
				var checkedRows = $("#MapAggregationLevels1-subnationalUnits").datagrid("getChecked");
				
				if (checkedRows)
				{
					// delete
					
					postData("deleteSubnationalUnits", {"subnationalUnitIds": fieldValueList(checkedRows, "id"), });
					
					// refresh
					
					$scope.refreshSubnationalUnits();
					
				}
				
			}
			
			$scope.setSubnationalUnitName = function(subnationalUnitId, subnationalUnitName)
			{
				postData("setSubnationalUnitName", {"subnationalUnitId": subnationalUnitId, "subnationalUnitName": subnationalUnitName, });
				
			}
			
		}
)
;

