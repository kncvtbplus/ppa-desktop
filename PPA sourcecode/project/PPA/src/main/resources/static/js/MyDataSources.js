application.controller
(
		"MyDataSources",
		function($rootScope, $scope, $sce)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// page open
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				// Local installer: all users can manage data sources.
				$scope.editable = true;
				
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					$scope.initializeDropzone();
					$scope.initializeUserFiles();
					
				}
				else
				{
					$scope.refreshUserFiles();
					
				}
				
				$scope.refreshEditability();
				
				// refresh title
				
				$scope.refreshTitle();
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.subtitle = $scope.trustAsHtml(getMessage("MyDataSources.subtitle"));

			}
			
			$scope.refreshEditability = function()
			{
				$("#MyDataSources-userFile-file").filebox($scope.editable ? "enable" : "disable");
				$("#MyDataSources-userFile-fileUploadButton").linkbutton($scope.editable ? "enable" : "disable");
				
			}
			
			// title
			
			$scope.refreshTitle = function()
			{
				$scope.title = getMessage("MyDataSources.title", [$rootScope.user.selectedAccountName, ]);
				
			}
			
			// dropzone
			
			$scope.initializeDropzone = function()
			{
				makeDroppable(document.querySelector("#MyDataSources-dropzone"), "loadUserFile", $scope.refreshUserFiles);
				$("#MyDataSources-dropzone").text(getMessage("MyDataSources.dropzone.text"));
				
			}
			
			// userFiles
			
			$scope.initializeUserFiles = function()
			{
				// create userFiles
				
				$("#MyDataSources-userFiles").datagrid
				(
						{
							fit: true,
							/*fitColumns: true,*/
				            onBeforeSelect: function(){return false;},
							url: "data/getUserFiles",
							columns:
								[[
									{
										field: "fileName",
										title: getMessage("common.label.fileName"),
										width: 500,
										fixed: true,
									},
									{
										field: "delete",
										title: getMessage("MyDataSources.userFiles.column.delete"),
										width: 80,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var output;
												
												if ($scope.editable)
												{
													output =
														"<a class='MyDataSources-userFiles-delete'" +
														" userFileId='" + row["id"] + "'" +
														" userFileName='" + row["fileName"] + "'" +
														"></a>"
													;
													
												}
												else
												{
													output = "";
													
												}
												
												return output;
												
											},
									},
								]],
							onLoadSuccess:
								function()
								{
									// render delete
									
									$(".MyDataSources-userFiles-delete").each
									(
											function(index, element)
											{
												var userFileId = element.getAttribute("userFileId");
												var userFileName = element.getAttribute("userFileName");
												
												$(this).linkbutton
												(
														{
															iconCls: "icon-delete",
															onClick:
																function()
																{
																	$scope.deleteUserFile(userFileId, userFileName);
																	
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
				.css("max-width", (580 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshUserFiles = function()
			{
				$("#MyDataSources-userFiles").datagrid("reload");
				
			}
			
			$scope.deleteUserFile = function(userFileId, userFileName)
			{
				// get dependentPpaNames
				
				var dependentPpaNames = getData("getUserFileDependentPpaNames", {"userFileId": userFileId, });
				
				var message;
				
				if (dependentPpaNames.length == 0)
				{
					message = getMessage("MyDataSources.userFiles.delete.noDependentPpas.message", [userFileName, ]);
					
				}
				else
				{
					var dependentPpaNamesFormatted = dependentPpaNames.join("<br>");
					
					message = getMessage("MyDataSources.userFiles.delete.dependentPpas.message", [userFileName, dependentPpaNamesFormatted, ]);
					
				}
				
				$.messager.confirm
				(
						getMessage("ConfirmationDialog.title"),
						message,
						function(confirmed)
						{
							if (confirmed)
							{
								// delete user file
								
								postData
								(
										"deleteUserFiles",
										{"userFileIds": [userFileId, ], },
										true,
										function()
										{
											// refresh user files
											
											$scope.refreshUserFiles();
											
										}
								)
								;
								
							}
							
						}
				)
				;
				
			}
			
		}
)
;

