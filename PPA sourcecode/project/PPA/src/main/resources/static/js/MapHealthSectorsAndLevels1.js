application.controller
(
		"MapHealthSectorsAndLevels1",
		function($rootScope, $scope, $sce)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// variables and constants
			
			var levels = ["0", "1", "2", "3", "4", "5", "6", "other", ];
			var maxSectorLevelCombinations = 10;
			
			// page open
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				// Local installer: all users can map health sectors and levels.
				$scope.editable = true;
				
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					$scope.initialize();
					
				}
				
				// refresh
				
				$scope.refreshPpaSectors();
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.title = $scope.trustAsHtml(getMessage("MapHealthSectorsAndLevels1.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("MapHealthSectorsAndLevels1.subtitle"));
				
			}
			
			// initialization
			
			$scope.initialize = function()
			{
				// create dataSources
				
				$scope.createPpaSectors();
				
			}
			
			// ppaSectors
			
			$scope.createPpaSectors = function()
			{
				$("#MapHealthSectorsAndLevels1-ppaSectors").datagrid
				(
						{
							fit: true,
							/*fitColumns: false,*/
				            onBeforeSelect: function(){return false;},
							onClickRow:
								function(index, row)
								{
									var t = window.event ? window.event.target : null;
									if (t && $(t).closest('input,textarea,select,.textbox,.combo,.switchbutton,.datagrid-cell-check').length) return;
									var dg = $(this);
									var checked = dg.datagrid("getChecked");
									var isChecked = false;
									for (var i = 0; i < checked.length; i++) { if (checked[i] === row) { isChecked = true; break; } }
									dg.datagrid(isChecked ? "uncheckRow" : "checkRow", index);
								},
							url: "data/getPpaSectors",
							columns:
								[[
									{
										field: "name",
										title: getMessage("MapHealthSectorsAndLevels1.ppaSectors.column.ppaSector"),
										width: 300,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output = "";
												
												// PPA sector name
												if (row["editable"])
												{
													output +=
														"<input class='easyui-element MapHealthSectorsAndLevels1-ppaSectors-name' style='width: 100%; '" +
														" value='" + value + "'" +
														" id='" + row["id"] + "'" +
														"/>"
													;
													
												}
												else
												{
													output +=
														"<span>" + value + "<span/>"
													;
													
												}
												
												return output;
												
											},
									},
									{
										field: "level0",
										title: getMessage("MapHealthSectorsAndLevels1.ppaSectors.column.level0"),
										width: 80,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var level = "0";
												
												var output =
													"<input type='checkbox' class='MapHealthSectorsAndLevels1-ppaSectors-levelCheckbox'" +
													" ppaSectorId='" + row["id"] + "'" +
													" level='" + level + "'" +
													" checked='" + (row["levels"].indexOf(level) != -1) + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "level1",
										title: getMessage("MapHealthSectorsAndLevels1.ppaSectors.column.level1"),
										width: 80,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var level = "1";
												
												var output =
													"<input type='checkbox' class='MapHealthSectorsAndLevels1-ppaSectors-levelCheckbox'" +
													" ppaSectorId='" + row["id"] + "'" +
													" level='" + level + "'" +
													" checked='" + (row["levels"].indexOf(level) != -1) + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "level2",
										title: getMessage("MapHealthSectorsAndLevels1.ppaSectors.column.level2"),
										width: 80,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var level = "2";
												
												var output =
													"<input type='checkbox' class='MapHealthSectorsAndLevels1-ppaSectors-levelCheckbox'" +
													" ppaSectorId='" + row["id"] + "'" +
													" level='" + level + "'" +
													" checked='" + (row["levels"].indexOf(level) != -1) + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "level3",
										title: getMessage("MapHealthSectorsAndLevels1.ppaSectors.column.level3"),
										width: 80,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var level = "3";
												
												var output =
													"<input type='checkbox' class='MapHealthSectorsAndLevels1-ppaSectors-levelCheckbox'" +
													" ppaSectorId='" + row["id"] + "'" +
													" level='" + level + "'" +
													" checked='" + (row["levels"].indexOf(level) != -1) + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "level4",
										title: getMessage("MapHealthSectorsAndLevels1.ppaSectors.column.level4"),
										width: 80,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var level = "4";
												
												var output =
													"<input type='checkbox' class='MapHealthSectorsAndLevels1-ppaSectors-levelCheckbox'" +
													" ppaSectorId='" + row["id"] + "'" +
													" level='" + level + "'" +
													" checked='" + (row["levels"].indexOf(level) != -1) + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "level5",
										title: getMessage("MapHealthSectorsAndLevels1.ppaSectors.column.level5"),
										width: 80,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var level = "5";
												
												var output =
													"<input type='checkbox' class='MapHealthSectorsAndLevels1-ppaSectors-levelCheckbox'" +
													" ppaSectorId='" + row["id"] + "'" +
													" level='" + level + "'" +
													" checked='" + (row["levels"].indexOf(level) != -1) + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "level6",
										title: getMessage("MapHealthSectorsAndLevels1.ppaSectors.column.level6"),
										width: 80,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var level = "6";
												
												var output =
													"<input type='checkbox' class='MapHealthSectorsAndLevels1-ppaSectors-levelCheckbox'" +
													" ppaSectorId='" + row["id"] + "'" +
													" level='" + level + "'" +
													" checked='" + (row["levels"].indexOf(level) != -1) + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "levelOther",
										title: getMessage("MapHealthSectorsAndLevels1.ppaSectors.column.levelOther"),
										width: 80,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var level = "other";
												
												var output =
													"<input type='checkbox' class='MapHealthSectorsAndLevels1-ppaSectors-levelCheckbox'" +
													" ppaSectorId='" + row["id"] + "'" +
													" level='" + level + "'" +
													" checked='" + (row["levels"].indexOf(level) != -1) + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
								]],
							onLoadSuccess:
								function(data)
								{
									// render name box
									
									$(".MapHealthSectorsAndLevels1-ppaSectors-name").each
									(
											function(index, element)
											{
												var id = element.getAttribute("id");
												
												$(this).textbox
												(
														{
															disabled: !$scope.editable,
															onChange:
																function(newValue)
																{
																	$scope.setPpaSectorName(id, newValue);
																	
																},
														}
												)
												;
												
											}
									)
									;
									
									// render level checkbox
									
									$(".MapHealthSectorsAndLevels1-ppaSectors-levelCheckbox").each
									(
											function(index, element)
											{
												var ppaSectorId = element.getAttribute("ppaSectorId");
												var level = element.getAttribute("level");
												var checked = (element.getAttribute("checked") == "true");
												
												$(this).prop("disabled", !$scope.editable);
												$(this).prop("checked", checked);
												$(this).change
												(
														function()
														{
															$scope.setPpaSectorLevel(ppaSectorId, level, this.checked);
															
														}
												)
												;
												
											}
									)
									;
									
									// update check dependent button state
									
									updateCheckDependentButtonState("#MapHealthSectorsAndLevels1-ppaSectors", "#MapHealthSectorsAndLevels1-ppaSectors-deleteCheckedButton");
									
									// enable or disable checkboxes depending on the role
									
									$(this).datagrid("getPanel").find("input[type=checkbox]").prop("disabled", !$scope.editable);
	
								},
							onCheck:
								function()
								{
									updateCheckDependentButtonState("#MapHealthSectorsAndLevels1-ppaSectors", "#MapHealthSectorsAndLevels1-ppaSectors-deleteCheckedButton");
									
								},
							onUncheck:
								function()
								{
									updateCheckDependentButtonState("#MapHealthSectorsAndLevels1-ppaSectors", "#MapHealthSectorsAndLevels1-ppaSectors-deleteCheckedButton");
									
								},
							onCheckAll:
								function()
								{
									updateCheckDependentButtonState("#MapHealthSectorsAndLevels1-ppaSectors", "#MapHealthSectorsAndLevels1-ppaSectors-deleteCheckedButton");
									
								},
							onUncheckAll:
								function()
								{
									updateCheckDependentButtonState("#MapHealthSectorsAndLevels1-ppaSectors", "#MapHealthSectorsAndLevels1-ppaSectors-deleteCheckedButton");
									
								},
						}
				)
				.datagrid("getPanel")
				.css("max-width", (940 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshPpaSectors = function()
			{
				$("#MapHealthSectorsAndLevels1-ppaSectors").datagrid("reload");

			}
			
			$scope.setPpaSectorSelected = function(id, selected)
			{
				postData("setPpaSectorSelected", {"id": id, "selected": selected, });
				
			}
			
			$scope.setPpaSectorName = function(id, name)
			{
				postData("setPpaSectorName", {"id": id, "name": name, });
				
			}
			
			$scope.setPpaSectorLevel = function(ppaSectorId, level, selected)
			{
				// check max number of combinations
				
				if (selected)
				{
					var selectedPpaSectorLevelCount = $(".MapHealthSectorsAndLevels1-ppaSectors-levelCheckbox:checked").length;
					
					if (selectedPpaSectorLevelCount > maxSectorLevelCombinations)
					{
						// revert checked state
						
						$(".MapHealthSectorsAndLevels1-ppaSectors-levelCheckbox[ppaSectorId=" + ppaSectorId + "][level=" + level + "]").prop("checked", false);
						
						// display error message
						
						$.messager.alert
						(
								getMessage("MapHealthSectorsAndLevels1.maxSectorLevelCombinationsError.title"),
								getMessage("MapHealthSectorsAndLevels1.maxSectorLevelCombinationsError.message", [maxSectorLevelCombinations, ]),
								"error"
						);
						
						return;
						
					}
					 
				}
				
				// update database
				
				postData("setPpaSectorLevel", {"ppaSectorId": ppaSectorId, "level": level, "selected": selected, }, true);
				
			}
			
		}
)
;

