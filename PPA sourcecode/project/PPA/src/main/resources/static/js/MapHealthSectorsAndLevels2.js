application
		.controller(
				"MapHealthSectorsAndLevels2",
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
						// Local installer: all users can map health sectors and levels.
						$scope.editable = true;

						if (!$scope.initialized)
						{
							$scope.initializeVariables();
							$scope.initialize();

							$scope.initialized = true;

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
						if (!getData("getAllPpaSectorLevelMapped").value)
						{
							$.messager
									.alert(
											getMessage("common.dialog.warning.title"),
											getMessage("MapHealthSectorsAndLevels2.ppaSectorMapping.missingMappingWarning.message"),
											"warning");

						}

					}

					$scope.initializeVariables = function()
					{
						$scope.dataSourceLabel = getMessage("common.label.dataSource");
						$scope.title = $scope.trustAsHtml(getMessage("MapHealthSectorsAndLevels2.title"));
						$scope.subtitle = $scope.trustAsHtml(getMessage("MapHealthSectorsAndLevels2.subtitle"));

					}

					// initialization

					$scope.initialize = function()
					{
						$scope.initializeDataSources();

						$scope.initializePpaSectorMapping();

					}

					// refresh

					$scope.refresh = function()
					{
						$scope.clearPpaSectorMapping();
						$scope.refreshDataSources();

					}

					// dataSources

					$scope.initializeDataSources = function()
					{
						$("#MapHealthSectorsAndLevels2-dataSources").datagrid
						(
								{
									fit: true,
									/*fitColumns: false,*/
									singleSelect: true,
									idField: "id",
									url: "data/getPpaSectorLevelMappingDataSources",
									columns :
									[
										[
											{
												field : "fileName",
												title : getMessage("MapHealthSectorsAndLevels2.dataSources.column.fileName"),
												width : 350,
												fixed: true,
											},
											{
												field : "mapped",
												title : getMessage("MapHealthSectorsAndLevels2.dataSources.column.mapped"),
												width : 100,
												fixed: true,
												align : "center",
												formatter :
													function(value, row,index)
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
										]
									],
									onLoadSuccess : function(data)
									{
										// keep selection

										$(this).datagrid("unselectAll");

										if ($scope.selectedDataSourceRow)
										{
											$(this).datagrid("selectRecord", $scope.selectedDataSourceRow["id"]);

										}

									},
									onSelect : function(index, row)
									{
										$scope.updatePpaSectorMapping(row["id"]);

										// check undefined mapped

										if (row["mapped"] == "columnNotSet")
										{
											showWarningMessage(getMessage("MapHealthSectorsAndLevels2.dataSources.mappedUndefinedWarning.message", [ row["fileName"], ]));

										}

									},
								}
						)
						.datagrid("getPanel")
						.css("max-width", (450 + $rootScope.tableScrollbarWidth).toString() + "px")
						;

					}

					$scope.refreshDataSources = function()
					{
						$scope.selectedDataSourceRow = $("#MapHealthSectorsAndLevels2-dataSources").datagrid("getSelected");

						$("#MapHealthSectorsAndLevels2-dataSources").datagrid("reload");

					}

					// ppaSectorMapping

					$scope.initializePpaSectorMapping = function()
					{
						$("#MapHealthSectorsAndLevels2-ppaSectorMapping").datagrid
						(
								{
									fit : true,
									/*fitColumns: false,*/
									onBeforeSelect : function()
									{
										return false;
									},
									view : scrollview,
									pageSize : 50,
									url : "data/getDataSourcePpaSectorMappings",
									columns :
									[
										[
											{
												field : "ppaSectorLevelId",
												title : getMessage("MapHealthSectorsAndLevels2.ppaSectorMapping.column.ppaSectorLevel"),
												width : 250,
												fixed : true,
												formatter :
													function(value, row, index)
													{
														var output = "<input class='easyui-element MapHealthSectorsAndLevels2-ppaSectorMapping-ppaSectorLevel'"
																+ " dataSourceId='"
																+ row["dataSourceId"]
																+ "'"
																+ " value='"
																+ value
																+ "'"
																+ " valueCombination='"
																+ row["valueCombination"]
																+ "'"
																+ "/>";
	
														return output;
	
													},
											},
											{
												field : "healthSector",
												title : getMessage("MapHealthSectorsAndLevels2.ppaSectorMapping.column.healthSector"),
												width : 250,
												fixed : true,
											},
											{
												field : "facilityType",
												title : getMessage("MapHealthSectorsAndLevels2.ppaSectorMapping.column.facilityType"),
												width : 250,
												fixed : true,
											},
											{
												field : "valueCombinationFrequency",
												title : getMessage("MapHealthSectorsAndLevels2.ppaSectorMapping.column.valueCombinationFrequency"),
												width : 100,
												fixed : true,
												align : "right",
												halign : "left",
											},
										]
									],
									onLoadSuccess : function(data)
									{
										// render ppaSectorLevel
										// combobox

										var ppaSectorLevels = getData("getPpaSectorLevels");

										$(
												".MapHealthSectorsAndLevels2-ppaSectorMapping-ppaSectorLevel")
												.each(
														function(index,
																element)
														{
															// expand
															// element
															// to cell
															// width

															$(element)
																	.width(
																			$(
																					element)
																					.parent()
																					.width());

															// get
															// additional
															// variables

															var dataSourceId = element
																	.getAttribute("dataSourceId");
															var valueCombination = element
																	.getAttribute("valueCombination");

															// render
															// component

															$(element)
																	.combobox(
																			{
																				disabled : !$scope.editable,
																				valueField : "ppaSectorLevelId",
																				textField : "text",
																				data : ppaSectorLevels,
																				onChange : function(
																						newValue)
																				{
																					$scope
																							.setDataSourcePpaSectorMapping(
																									dataSourceId,
																									valueCombination,
																									newValue);

																				},
																			});

														});

									},
								}
						)
						.datagrid("getPanel")
						.css("max-width", (850 + $rootScope.tableScrollbarWidth).toString() + "px")
						;

					}

					$scope.clearPpaSectorMapping = function()
					{
						$("#MapHealthSectorsAndLevels2-ppaSectorMapping")
								.datagrid(
								{
									"queryParams" : {},
								});

					}

					$scope.updatePpaSectorMapping = function(dataSourceId)
					{
						if (dataSourceId)
						{
							$("#MapHealthSectorsAndLevels2-ppaSectorMapping")
									.datagrid("reload",
									{
										"dataSourceId" : dataSourceId,
									});

						}

					}

					$scope.setDataSourcePpaSectorMapping = function(
							dataSourceId, valueCombination, ppaSectorLevelId)
					{
						if (dataSourceId)
						{
							postData(
									"setDataSourcePpaSectorMapping",
									{
										"dataSourceId" : dataSourceId,
										"valueCombination" : valueCombination,
										"ppaSectorLevelId" : ppaSectorLevelId,
									},
									true,
									function(response)
									{
										if (response.mapped)
										{
											var selectedDataSourceRow = $(
													"#MapHealthSectorsAndLevels2-dataSources")
													.datagrid("getSelected");

											if (selectedDataSourceRow)
											{
												var selectedDataSourceRowIndex = $(
														"#MapHealthSectorsAndLevels2-dataSources")
														.datagrid(
																"getRowIndex",
																selectedDataSourceRow);

												$(
														"#MapHealthSectorsAndLevels2-dataSources")
														.datagrid(
																"updateRow",
																{
																	index : selectedDataSourceRowIndex,
																	row :
																	{
																		"mapped" : "yes",
																	},
																});

											}

										}

									});

						}

					}

				});
