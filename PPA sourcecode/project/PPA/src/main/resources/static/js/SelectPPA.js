application.controller
(
		"SelectPPA",
		function($rootScope, $scope, $sce)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// variables
			
			$scope.nationalGeographicAggregationLevel = "National";
			$scope.geographicAggregationLevels =
				[
					{"value": $scope.nationalGeographicAggregationLevel, },
					{"value": "Region", },
					{"value": "State", },
					{"value": "Province", },
					{"value": "County", },
					{"value": "District", },
					{"value": "Urban/Rural", },
				]
			;
			
			// page open
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				// In the local Windows installer we allow all users to create,
				// rename, duplicate and delete PPAs. If you want to restrict
				// this to administrators only, change this back to:
				//   $rootScope.user.administrator;
				$scope.editable = true;
				
				if (!$scope.initialized)
				{
					$scope.initializeVariables();
					$scope.initializePpas();
					
					$scope.initialized = true;
					
				}
				else
				{
					$scope.refreshPpas();
					
				}
				
				// refresh title
				
				$scope.refreshTitle();
					
			}
			
			$scope.initializeVariables = function()
			{
				$scope.subtitle = $scope.trustAsHtml(getMessage("SelectPPA.subtitle"));
				
			}
			
			// title
			
			$scope.refreshTitle = function()
			{
				$scope.title = getMessage("SelectPPA.title", [$rootScope.user.selectedAccountName, ]);
				
			}
			
			// ppas
			
			$scope.initializePpas = function()
			{
				$("#SelectPPA-ppas").datagrid
				(
						{
							fit: true,
							fitColumns: true,
							checkbox: true,
				            onBeforeSelect: function(){return false;},
							singleSelect: true,
							url: "data/getPpas",
							idField: "id",
							columns:
								[[
									{
										field: "id",
										title: getMessage("SelectPPA.ppas.columns.select"),
										width: 80,
										fixed: true,
										align: "center",
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<input id='SelectPPA-ppas-select-" + row["id"] +"' class='SelectPPA-ppas-select'" +
													" name='SelectPPA-ppas-select'" +
													" value='" + value + "'" +
													(row["selected"] ? " checked" : "") +
													" ppaId='" + row["id"] + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "name",
										title: getMessage("common.label.name"),
										width: 500,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<input class='SelectPPA-ppas-name' style='width: 100%; '" +
													" value='" + value + "'" +
													" ppaId='" + row["id"] + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "region",
										title: getMessage("SelectPPA.ppas.columns.region"),
										width: 260,
										fixed: true,
										formatter:
											function(value,row,index)
											{
												var output =
													"<div class='SelectPPA-ppas-region-tooltip' style='width: 100%; '>" +
													"<input class='SelectPPA-ppas-region' style='width: 100%; '" +
													" value='" + value + "'" +
													" ppaId='" + row["id"] + "'" +
													" selected='" + row["selected"] + "'" +
													"/>" +
													"</div>"
												;
												
												return output;
												
											},
									},
									{
										field: "export",
										title: getMessage("SelectPPA.ppas.columns.export"),
										width: 90,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var output = "";
												
												if ($scope.editable)
												{
													output +=
														"<a class='SelectPPA-ppas-export'" +
														" ppaId='" + row["id"] + "'" +
														"></a>"
													;
													
												}
												
												return output;
												
											},
									},
									{
										field: "duplicate",
										title: getMessage("SelectPPA.ppas.columns.duplicate"),
										width: 90,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var output = "";
												
												if ($scope.editable)
												{
													if (value)
													{
														output +=
															"<a class='SelectPPA-ppas-duplicate'" +
															" ppaId='" + row["id"] + "'" +
															"></a>"
														;
														
													}
													
												}
												
												return output;
												
											},
									},
									{
										field: "delete",
										title: getMessage("SelectPPA.ppas.columns.delete"),
										width: 70,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var output = "";
												
												if ($scope.editable)
												{
													if (value)
													{
														output =
															"<a class='SelectPPA-ppas-delete'" +
															" ppaId='" + row["id"] + "'" +
															" ppaName='" + row["name"] + "'" +
															"></a>"
														;
														
													}
													
												}
												
												return output;
												
											},
									},
								]],
							toolbar:
								[
									{
										disabled: !$scope.editable,
										id: "SelectPPA-ppas-addButton",
										iconCls: "icon-add",
										text: getMessage("common.label.createNew") + " PPA",
										handler:
											function()
											{
												$scope.createPpa();
												
											},
									},
									{
										disabled: !$scope.editable,
										id: "SelectPPA-ppas-importButton",
										iconCls: "icon-download",
										text: getMessage("SelectPPA.ppas.import"),
										handler:
											function()
											{
												$scope.openImportDialog();
												
											},
									},
								],
							onLoadSuccess:
								function()
								{
									// render select
									
									$(".SelectPPA-ppas-select").each
									(
											function(index, element)
											{
												var ppaId = element.getAttribute("ppaId");
												
												$(this).radiobutton
												(
														{
															onChange:
																function(checked)
																{
																	if (checked)
																	{
																		$scope.selectPpa(ppaId);
																		
																	}
																	
																},
														}
												)
												;
												
											}
									)
									;
									
									// render name
									
									$(".SelectPPA-ppas-name").each
									(
											function(index, element)
											{
												var ppaId = element.getAttribute("ppaId");
												
												$(this).textbox
												(
														{
															disabled: !$scope.editable,
															onChange:
																function(newValue)
																{
																	$scope.setPpaName(ppaId, newValue);
																	
																},
														}
												)
												;
												
												// set maxlength property
												
												$(element).textbox("textbox").prop("maxlength", 100);
												
											}
									)
									;
								
									// render region
									
									$(".SelectPPA-ppas-region-tooltip").tooltip
									(
											{
												position: "top",
												content: getMessage("SelectPPA.ppas.columns.region.prompt"),
											}
									)
									;
									
									$(".SelectPPA-ppas-region").each
									(
											function(index, element)
											{
												var ppaId = element.getAttribute("ppaId");
												var selected = element.getAttribute("selected");
												
												$(element).combobox
												(
														{
															prompt: getMessage("SelectPPA.ppas.columns.region.prompt"),
															disabled: !$scope.editable,
															reversed: false,
															selectOnNavigation: false,
															panelHeight: "auto",
															valueField: "value",
															textField: "value",
															data: $scope.geographicAggregationLevels,
															keyHandler:
																$.extend
																(
																		true,
																		{},
																		$.fn.combobox.defaults.keyHandler,
																		{
																			enter:
																				function(e)
																				{
																					var s = $(this).combobox('getText');
																					$.fn.combobox.defaults.keyHandler.enter.call(this,e);
																					if ($(this).combobox('getText') == "")
																					{
																						$(this).combobox('setValue', s);
																					}
																				},
																		}
																),
															onChange:
																function(newValue)
																{
																	if (newValue != "")
																	{
																		// replace "/" with "." in value
																		
																		if (newValue.indexOf("/") != -1)
																		{
																			// replace value
																			
																			$(this).combobox("setValue", newValue.replace("/", "."));
																			
																		}
																		else
																		{
																			// update request
																			
																			$scope.setPpaAggregationLevel(ppaId, newValue, selected);
																			
																		}
																		
																	}
																	
																},
													}
												)
												;
												
											}
									)
									;
									
									// render duplicate
									
									$(".SelectPPA-ppas-duplicate").each
									(
											function(index, element)
											{
												var ppaId = element.getAttribute("ppaId");
												
												$(this).linkbutton
												(
														{
															iconCls: "icon-duplicate",
															onClick:
																function()
																{
																	$scope.duplicatePpa(ppaId);
																	
																},
														}
												)
												;
												
											}
									)
									;
									
									// render export
									
									$(".SelectPPA-ppas-export").each
									(
											function(index, element)
											{
												var ppaId = element.getAttribute("ppaId");
												
												$(this).linkbutton
												(
														{
															iconCls: "icon-upload",
															onClick:
																function()
																{
																	$scope.exportPpa(ppaId);
																	
																},
														}
												)
												;
												
											}
									)
									;
									
									// render delete
									
									$(".SelectPPA-ppas-delete").each
									(
											function(index, element)
											{
												var ppaId = element.getAttribute("ppaId");
												var ppaName = element.getAttribute("ppaName");
												
												$(this).linkbutton
												(
														{
															iconCls: "icon-delete",
															onClick:
																function()
																{
																	$scope.deletePpa(ppaId, ppaName);
																	
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
				.datagrid("getPanel");
				
			}
			
			$scope.refreshPpas = function()
			{
				// refresh tool button
				
				if ($scope.editable)
				{
					$("#SelectPPA-ppas-addButton").linkbutton("enable");
					$("#SelectPPA-ppas-importButton").linkbutton("enable");
					
				}
				else
				{
					$("#SelectPPA-ppas-addButton").linkbutton("disable");
					$("#SelectPPA-ppas-importButton").linkbutton("disable");
					
				}
				
				// delegate to index function
				
				call(null, "refreshSelectedPpa");
				
			}
			
			$scope.openImportDialog = function()
			{
				var $fileInput = $("#SelectPPA-importFile");
				
				// reset previous selection and handler
				
				$fileInput.val("");
				$fileInput.off("change.SelectPPAImport");
				
				$fileInput.on
				(
						"change.SelectPPAImport",
						function(event)
						{
							var files = this.files;
							
							if (!files || files.length == 0)
							{
								return;
								
							}
							
							var formData = new FormData();
							
							formData.append("file", files[0]);
							
							$.ajax
							(
									{
										url: "data/importPpa",
										type: "POST",
										data: formData,
										processData: false,
										contentType: false,
										success:
											function(response)
											{
												$fileInput.val("");
												
												// refresh PPAs
												
												$scope.refreshPpas();
												
												// auto-select imported PPA when possible
												
												try
												{
													if (response && response.ppaId)
													{
														call(null, "selectPpa", [response.ppaId, ]);
														
													}
												}
												catch (e)
												{
												}
												
												showInformationMessage(getMessage("SelectPPA.import.success"));
												
											},
										error:
											function()
											{
												$fileInput.val("");
												
												$.messager.alert
												(
														getMessage("common.alert.error.title"),
														getMessage("SelectPPA.import.error"),
														"error"
												);
												
											},
									}
							)
							;
							
						}
				)
				;
				
				$fileInput.click();
				
			}
			
			$scope.exportPpa = function(ppaId)
			{
				if (ppaId)
				{
					window.location = "data/exportPpa?ppaId=" + ppaId;
					
				}
				
			}
			
			$scope.createPpa = function()
			{
				// add row
				
				postData("createPpa");
				
				// refresh user
				
				call(null, "refreshUser");
				
				// refresh PPAs
				
				$scope.refreshPpas();
				
			}
			
			$scope.setPpaName = function(ppaId, ppaName)
			{
				postData("setPpaName", {"ppaId": ppaId, "ppaName": ppaName, });
				
				// refresh PPAs
				
				$scope.refreshPpas();
				
			}
			
			$scope.setPpaAggregationLevel = function(ppaId, ppaAggregationLevel, selected)
			{
				postData
				(
						"setPpaAggregationLevel",
						{"ppaId": ppaId, "ppaAggregationLevel": ppaAggregationLevel, },
						true,
						function()
						{
							// refresh menu button states for selected PPA
							
							if (selected)
							{
								call(null, "refreshMenuButtonStates");
								
							}
							
						}
				)
				;
				
			}
			
			$scope.selectPpa = function(ppaId)
			{
				$("#Home-selectedPpa").combobox("setValue", ppaId);
				
			}
			
			$scope.duplicatePpa = function(ppaId)
			{
				if (ppaId)
				{
					// duplicate rows
					
					postData
					(
							"duplicatePpas",
							{"ppaIds": [ppaId, ], },
							true,
							function()
							{
								// refresh PPAs
								
								$scope.refreshPpas();
								
							}
					)
					;
					
				}
				
			}
			
			$scope.deletePpa = function(ppaId, ppaName)
			{
				if (ppaId)
				{
					$.messager.confirm
					(
							getMessage("ConfirmationDialog.title"),
							getMessage("SelectPPA.ppas.delete.message", [ppaName, ]),
							function(confirmed)
							{
								if (confirmed)
								{
									// delete rows
									
									postData
									(
											"deletePpas",
											{"ppaIds": [ppaId, ], },
											true,
											function()
											{
												// refresh PPAs
												
												$scope.refreshPpas();
												
											}
									)
									;
									
								}
								
							}
					)
					;
					
				}
				
			}
			
		}
)
;

