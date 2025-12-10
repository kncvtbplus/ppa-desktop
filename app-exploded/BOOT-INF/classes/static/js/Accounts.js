application.controller
(
		"Accounts",
		function($rootScope, $scope, $sce, $timeout)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// variables
			
			$scope.manageAccountUsersDialogTitle;
			$scope.managedAccount;
			
			// page open
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					$scope.initializeAccounts();
					$scope.initializeCreateAccountDialog();
					$scope.initializeManageAccountUsersDialog();
					
				}
				else
				{
					// don't refresh account onOpen
//					$scope.refreshAccounts();
					
				}
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.title = $scope.trustAsHtml(getMessage("Accounts.title"));
				$scope.subtitle = $scope.trustAsHtml(getMessage("Accounts.subtitle"));
				
			}
			
			// Accounts
			
			$scope.initializeAccounts = function()
			{
				$("#Accounts-accounts").datagrid
				(
						{
							fit: true,
							fitColumns: true,
				            onBeforeSelect: function(){return false;},
							singleSelect: true,
							url: "data/getAccountsTable",
							idField: "id",
							remoteSort: false,
							sortName: "name",
							columns:
								[[
									{
										field: "id",
										title: getMessage("Accounts.accounts.columns.select"),
										width: 80,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var output =
													"<input id='Accounts-accounts-select-" + row["id"] + "' class='Accounts-accounts-select'" +
													" name='Accounts-accounts-select'" +
													" value='" + value + "'" +
													(row["selected"] ? " checked" : "") +
													" accountId='" + row["id"] + "'" +
													"/>"
												;
												
												return output;
												
											},
									},
									{
										field: "name",
										title: getMessage("Accounts.accounts.columns.name"),
										sortable: true,
										width: 500,
										fixed: true,
										// temporary disable name modification
//										formatter:
//											function(value,row,index)
//											{
//												var output =
//													"<input class='Accounts-accounts-name' style='width: 100%; '" +
//													" value='" + value + "'" +
//													" accountId='" + row["id"] + "'" +
//													"/>"
//												;
//												
//												return output;
//												
//											},
									},
									{
										field: "owner",
										title: getMessage("Accounts.accounts.columns.owner"),
										sortable: true,
										width: 80,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												return (value ? "<div class='datagid-checkmark'>" : "");
												
											},
									},
									{
										field: "administrator",
										title: getMessage("Accounts.accounts.columns.administrator"),
										sortable: true,
										width: 130,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												return (value ? "<div class='datagid-checkmark'>" : "");
												
											},
									},
									{
										field: "leave",
										title: getMessage("Accounts.accounts.columns.leave"),
										width: 120,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var output;
												
												if (value)
												{
													output =
														"<a class='Accounts-accounts-leave'" +
														" accountId='" + row["id"] + "'" +
														" accountName='" + row["name"] + "'" +
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
									{
										field: "manage",
										title: getMessage("Accounts.accounts.columns.manage"),
										width: 130,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var output;
												
												if (value)
												{
													output =
														"<a class='Accounts-accounts-manage'" +
														" accountId='" + row["id"] + "'" +
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
									{
										field: "delete",
										title: getMessage("Accounts.accounts.columns.delete"),
										width: 120,
										fixed: true,
										align: "center",
										formatter:
											function(value,row,index)
											{
												var output;
												
												if (value)
												{
													output =
														"<a class='Accounts-accounts-delete'" +
														" accountId='" + row["id"] + "'" +
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
							toolbar:
								[
									{
										id: "Accounts-accounts-addButton",
										iconCls: "icon-add",
										text: getMessage("common.label.createNew"),
										handler:
											function()
											{
												$scope.openCreateAccountDialog();
												
											},
									},
								],
							onLoadSuccess:
								function()
								{
									// render select
									
									$(".Accounts-accounts-select").each
									(
											function(index, element)
											{
												var accountId = element.getAttribute("accountId");
												
												$(this).radiobutton
												(
														{
															onChange:
																function(checked)
																{
																	if (checked)
																	{
																		$scope.selectAccount(accountId);
																		
																	}
																	
																},
														}
												)
												;
												
											}
									)
									;
									
									// render leave
									
									$(".Accounts-accounts-leave").each
									(
											function(index, element)
											{
												var accountId = element.getAttribute("accountId");
												var accountName = element.getAttribute("accountName");
												
												$(this).linkbutton
												(
														{
															iconCls: "icon-exit",
															onClick:
																function()
																{
																	$scope.leaveAccount(accountId, accountName);
																	
																},
														}
												)
												;
												
											}
									)
									;
									
									// render manage
									
									$(".Accounts-accounts-manage").each
									(
											function(index, element)
											{
												var accountId = element.getAttribute("accountId");
												
												$(this).linkbutton
												(
														{
															iconCls: "icon-users",
															onClick:
																function()
																{
																	$scope.manageAccount(accountId);
																	
																},
														}
												)
												;
												
											}
									)
									;
									
									// render delete
									
									$(".Accounts-accounts-delete").each
									(
											function(index, element)
											{
												var accountId = element.getAttribute("accountId");
												
												$(this).linkbutton
												(
														{
															iconCls: "icon-delete",
															onClick:
																function()
																{
																	$scope.deleteAccount(accountId);
																	
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
				.css("max-width", (1160 + $rootScope.tableScrollbarWidth).toString() + "px")
				;
				
			}
			
			$scope.refreshAccounts = function()
			{
				// refresh datagrid
				
				$("#Accounts-accounts").datagrid("reload");

				// refresh account selection
				
				call(null, "refreshSelectedAccount");
				
			}
			
			$scope.createAccount = function()
			{
				// add row
				
				postData
				(
						"createAccount",
						{},
						true,
						function()
						{
							// refresh user
							
							call(null, "refreshUser");
							
							// refresh accounts
							
							$scope.refreshAccounts();
							
						}
				)
				;
				
			}

			// temporary disable account name modification
//			$scope.setAccountName = function(accountId, accountName)
//			{
//				postData("setAccountName", {"accountId": accountId, "accountName": accountName, });
//				
//				// refresh selected account
//				
//				call(null, "refreshSelectedAccount");
//				
//			}
//			
			$scope.selectAccount = function(accountId)
			{
				$("#Home-selectedAccount").combobox("setValue", accountId);
				
			}
			
			$scope.clearAccount = function(accountId)
			{
				$("#Home-selectedAccount").combobox("clear");
				
			}
			
			$scope.leaveAccount = function(accountId, accountName)
			{
				$.messager.confirm
				(
						getMessage("ConfirmationDialog.title"),
						getMessage("Accounts.accounts.leave.message", [accountName, ]),
						function(confirmed)
						{
							if (confirmed)
							{
								// leave account
								
								postData
								(
										"leaveAccount",
										{"accountId": accountId, },
										true,
										function()
										{
											// refresh accounts
											
											$scope.refreshAccounts();
											
										}
								)
								;
								
							}
							
						}
				)
				;
				
			}
			
			$scope.manageAccount = function(accountId)
			{
				// save managedAccount
				
				getDataAsync
				(
						"getAccount",
						{"accountId": accountId, },
						function(data)
						{
							$scope.managedAccount = data;

							// open manageAccountUsersDialog
							
							$scope.openManageAccountUsersDialog();
							
							// refresh users
							
							$("#Accounts-manageAccountUsersDialog-users").datagrid({"queryParams": {"accountId": accountId, }, });
							
							// refresh AngularJS
							
							$scope.$evalAsync();
							
						}
				)
				;
				
			}
			
			$scope.deleteAccount = function(accountId)
			{
				$.messager.confirm
				(
						getMessage("ConfirmationDialog.title"),
						getMessage("Accounts.accounts.delete.message"),
						function(confirmed)
						{
							if (confirmed)
							{
								// delete account
								
								postData
								(
										"deleteAccount",
										{"accountId": accountId, },
										true,
										function()
										{
											// refresh user if deleted account was selected
											
											if ($rootScope.user.selectedAccountId == accountId)
											{
												call(null, "refreshUser");
												
											}
											
											// refresh accounts
											
											$scope.refreshAccounts();
											
										}
								)
								;
								
							}
							
						}
				)
				;
				
			}
			
			// createAccountDialog
			
			$scope.initializeCreateAccountDialog = function()
			{
				$("#Accounts-createAccount-form-name").textbox
				(
						{
							cls: "background-icon-user",
							prompt: getMessage("Accounts.createAccount.form.name"),
							required: true,
						}
				)
				;
				
				// set maxlength property
				
				$("#Accounts-createAccount-form-name").textbox("textbox").prop("maxlength", 100);
				
				// bind enter press
				
				$("#Accounts-createAccount-form-name").textbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.createAccount();
							}
						}
				)
				;
				
//				$("#Accounts-createAccount-form-demo").checkbox
//				(
//						{
//							label: getMessage("Accounts.createAccount.form.demo"),
//							labelPosition: "after",
//						}
//				)
//				;
//				
				$("#Accounts-createAccount-form-submitButton").linkbutton
				(
						{
							text: getMessage("Accounts.createAccount.form.submitButton.text"),
							onClick: $scope.createAccount,
						}
				)
				;
				
			}
			
			$scope.openCreateAccountDialog = function()
			{
				$("#Accounts-createAccountDialog").css("visibility", "visible");
				
			}
			
			$scope.closeCreateAccountDialog = function()
			{
				$("#Accounts-createAccountDialog").css("visibility", "hidden");
				
			}
			
			$scope.createAccount = function()
			{
				// validate form
				
				if (!$("#Accounts-createAccount-form").form("validate"))
				{
					showErrorMessage(getMessage("common.alert.invalidFormErrorMessage"));
					
					return;
					
				}
				
				// collect form data
				
				var name = $("#Accounts-createAccount-form-name").textbox("getValue");
				
				// check name unique
				
				var checkAccountNameExistsResponse = getData("checkAccountNameExists", {"name": name, });
				
				if (checkAccountNameExistsResponse.accountNameExists)
				{
					showErrorMessage(getMessage("Accounts.createAccount.uniqueAccountNameValidationError.text"));
					
					return;
					
				}
				
				// createAccount
				
				postData
				(
						"createAccount",
						{"name": name, "demo": /*$("#Accounts-createAccount-form-demo").checkbox("options")["checked"]*/false, },
						true,
						function()
						{
							// close dialog
							
							$scope.closeCreateAccountDialog();
							
							// clear form
							
							$("#Accounts-createAccount-form").form("clear");
							
							// refreshAccounts
							
							$scope.refreshAccounts();
							
						}
				)
				;
				
			}
			
			// manageAccountUsers
			
			$scope.initializeManageAccountUsersDialog = function()
			{
				$("#Accounts-manageAccountUsersDialog").dialog
				(
						{
							title: getMessage("Accounts.manageAccountUsersDialog.title"),
							modal: true,
							closed: true,
						}
				)
				;
				
				$("#Accounts-manageAccountUsersDialog-users").datagrid
				(
						{
							fit: true,
							/*fitColumns: false,*/
				            onBeforeSelect: function(){return false;},
							singleSelect: true,
							view: scrollview,
							pageSize: 50,
							url: "data/getAccountUsers",
							idField: "id",
							toolbar:
								[
									{
										id: "Accounts-manageAccountUsersDialog-users-inviteUser",
										iconCls: "icon-add",
										text: getMessage("Accounts.manageAccountUsersDialog.users.inviteUserButton.text"),
										handler:
											function()
											{
												$scope.openInviteUserDialog();
												
											},
									},
								],
							columns:
							[[
								{
									field: "username",
									title: getMessage("Accounts.manageAccountUsersDialog.users.columns.username"),
									width: 400,
								},
								{
									field: "administrator",
									title: getMessage("Accounts.manageAccountUsersDialog.users.columns.administrator"),
									width: 120,
									align: "center",
									formatter:
										function(value,row,index)
										{
											return (value ? "<div class='datagid-checkmark'>" : "");
											
										},
									formatter:
										function(value,row,index)
										{
											var output =
												"<div style='height: 22px;'>" +
												"<input type='checkbox' class='Accounts-manageAccountUsersDialog-users-administrator' " +
												(value ? " checked" : "") +
												" userId='" + row["id"] + "'" +
												" owner='" + row["owner"] + "'" +
												"/>" +
												"</div>"
											;
											
											return output;
											
										},
								},
								{
									field: "expel",
									title: getMessage("Accounts.manageAccountUsersDialog.users.columns.expel"),
									width: 60,
									align: "center",
									formatter:
										function(value,row,index)
										{
											var output;
											
											if (value)
											{
												output =
													"<a class='Accounts-manageAccountUsersDialog-users-expel'" +
													" userId='" + row["id"] + "'" +
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
									// render administrator
									
									$(".Accounts-manageAccountUsersDialog-users-administrator").on
									(
											"change",
											function(event)
											{
												var accountId = $scope.managedAccount.id;
												var userId = this.getAttribute("userId");
												var owner = this.getAttribute("owner");
												
												$scope.setAccountUserAdministrator(accountId, userId, this.checked);
												
											}
									)
									;
									
									// render expel
									
									$(".Accounts-manageAccountUsersDialog-users-expel").each
									(
											function(index, element)
											{
												var accountId = $scope.managedAccount.id;
												var userId = element.getAttribute("userId");
												
												$(this).linkbutton
												(
														{
															iconCls: "icon-exit",
															onClick:
																function()
																{
																	$scope.expelAccountUser(accountId, userId);
																	
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
			
			$scope.openManageAccountUsersDialog = function()
			{
				// set account name
				
				$("#Accounts-manageAccountUsersDialog-header").text($scope.managedAccount.name);
				
				// open dialog
				
				openDialog("#Accounts-manageAccountUsersDialog");

				// initialize easyui
				
				if (!$scope.manageAccountUsersDialogInitilized)
				{
					$scope.manageAccountUsersDialogInitilized = true;
					
					$scope.initializeInviteUserDialog();
					
				}
				
			}
			
			$scope.refreshAccountUsers = function()
			{
				$("#Accounts-manageAccountUsersDialog-users").datagrid("reload");
				
			}
			
			$scope.setAccountUserAdministrator = function(accountId, userId, administrator)
			{
				postData("setAccountUserAdministrator", {"accountId": accountId, "userId": userId, "administrator": administrator, }, true);
				
			}
			
			$scope.expelAccountUser = function(accountId, userId)
			{
				$.messager.confirm
				(
						getMessage("ConfirmationDialog.title"),
						getMessage("Accounts.manageAccountUsersDialog.users.expel.message"),
						function(confirmed)
						{
							if (confirmed)
							{
								// expel account user
								
								postData
								(
										"expelAccountUser",
										{"accountId": accountId, "userId": userId, },
										true,
										function()
										{
											// refresh account users
											
											$scope.refreshAccountUsers();
											
										}
								)
								;
								
							}
							
						}
				)
				;
				
			}
			
			// inviteUserDialog
			
			$scope.initializeInviteUserDialog = function()
			{
				$("#Accounts-inviteUser-form-email").textbox
				(
						{
							cls: "background-icon-user",
							prompt: getMessage("Accounts.inviteUser.form.email"),
							required: true,
							validType: "email",
						}
				)
				.textbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.inviteUser();
							}
						}
				)
				;
				
				$("#Accounts-inviteUser-form-submitButton").linkbutton
				(
						{
							text: getMessage("Accounts.inviteUser.form.submitButton.text"),
							onClick: $scope.inviteUser,
						}
				)
				;
				
			}
			
			$scope.openInviteUserDialog = function()
			{
				$("#Accounts-inviteUserDialog").css("visibility", "visible");
				
			}
			
			$scope.closeInviteUserDialog = function()
			{
				$("#Accounts-inviteUserDialog").css("visibility", "hidden");
				
			}
			
			$scope.inviteUser = function()
			{
				// validate form
				
				if (!$("#Accounts-inviteUser-form").form("validate"))
				{
					showErrorMessage(getMessage("common.alert.invalidFormErrorMessage"));
					
					return;
					
				}
				
				// collect form data
				
				var email = $("#Accounts-inviteUser-form-email").textbox("getValue");
				
				// inviteUser
				
				postData
				(
						"inviteUser",
						{"accountId": $scope.managedAccount.id, "email": email, },
						true,
						function()
						{
							// clear form
							
							$("#Accounts-inviteUser-form").form("clear");
							
							// close dialog
							
							$scope.closeInviteUserDialog();
							
							// refreshAccountUsers
							
							$scope.refreshAccountUsers();
							
							// show confirmation message
							
							showConfirmationMessage(getMessage("email.invitation.confirmation.message"));
							
						}
				)
				;
				
			}
			
		}
)
;

