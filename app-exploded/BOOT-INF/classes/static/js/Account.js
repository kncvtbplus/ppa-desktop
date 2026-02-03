application.controller
(
		"Account",
		function($rootScope, $scope, $sce)
		{
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// variables
			
			$scope.emailLabel = getMessage("Account.profile.email.label");
			$scope.confirmationTitle = getMessage("Account.profile.confirmation.title");
			$scope.confirmationMessage = getMessage("Account.profile.confirmation.message");
			$scope.logoutTitle = getMessage("Account.profile.logout.title");
			$scope.logoutMessage = getMessage("Account.profile.logout.message");
			$scope.changeEmailDialogTitle = getMessage("Account.changeEmail.form.title");

			// page open
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.initializeVariables();
					$scope.initializeProfile();
//					$scope.initializeChangeEmailDialog();
//					$scope.initializeChangePasswordDialog();
					
				}
				
				// clear form
				
				$scope.refreshProfile();
				
			}
			
			$scope.initializeVariables = function()
			{
				$scope.title = getMessage("Account.profile.title");
				$scope.subtitle = $scope.trustAsHtml(getMessage("Account.profile.subtitle"));
				$scope.currentValueColumnHeader = getMessage("Account.profile.currentValueColumnHeader");
				$scope.updatedValueColumnHeader = getMessage("Account.profile.updatedValueColumnHeader");
				$scope.accountName = getMessage("Account.profile.accountName");
				$scope.username = getMessage("Account.profile.username");
				$scope.logoutWarning = getMessage("Account.profile.username.logoutWarning");
				$scope.password = getMessage("Account.profile.password");
				$scope.passwordConfirmation = getMessage("Account.profile.passwordConfirmation");
				$scope.email = getMessage("Account.profile.email");
				$scope.name = getMessage("Account.profile.name");
				
			}
			
			// profile
			
			$scope.initializeProfile = function()
			{
				$("#Account-profileForm").bind
				(
						"input",
						function(event)
						{
							console.log("c");
							$scope.profileFormValueChanged();
							
						}
				)
				;
				
				$("#Account-profileForm-email").textbox
				(
						{
							width: 340,
							height: 50,
							cls: "account-textbox",
							prompt: getMessage("Account.profileForm.email"),
							validType: "email",
						}
				)
				;
				$("#Account-profileForm-email").bind
				(
						"input",
						function(event)
						{
							$scope.profileFormValueChanged();
							
						}
				)
				;
				
				$("#Account-profileForm-emailConfirmation").textbox
				(
						{
							width: 340,
							height: 50,
							cls: "account-textbox",
							prompt: getMessage("Account.profileForm.emailConfirmation"),
						}
				)
				;
				
				$("#Account-profileForm-password").passwordbox
				(
						{
							width: 340,
							height: 50,
							cls: "account-textbox",
							prompt: getMessage("Account.profileForm.password"),
						}
				)
				;
				
				$("#Account-profileForm-passwordConfirmation").passwordbox
				(
						{
							width: 340,
							height: 50,
							cls: "account-textbox",
							prompt: getMessage("Account.profileForm.passwordConfirmation"),
						}
				)
				;
				
				$("#Account-profileForm-submitButton").linkbutton
				(
						{
							text: getMessage("Account.profileForm.submitButtonText"),
							disabled: true,
							onClick:
								function()
								{
									$scope.updateProfile();
									
								},
						}
				)
				;
				
			}
			
			$scope.profileFormValueChanged = function()
			{
				if
				(
						textboxContainsText
						(
								[
									"#Account-profileForm-email",
									"#Account-profileForm-emailConfirmation",
									"#Account-profileForm-password",
									"#Account-profileForm-passwordConfirmation",
								]
						)
				)
				{
					$("#Account-profileForm-submitButton").linkbutton("enable");
					
				}
				else
				{
					$("#Account-profileForm-submitButton").linkbutton("disable");
					
				}
				
			}
			
			$scope.refreshProfile = function()
			{
				// clear form
				
				$("#Account-profileForm").form("clear");
				
				$scope.profileFormValueChanged();
				
			}
			
			$scope.updateProfile = function()
			{
				// validate form
				
				if ($("#Account-profileForm-emailConfirmation").textbox("getValue") != $("#Account-profileForm-email").textbox("getValue"))
				{
					showErrorMessage(getMessage("common.emailConfirmationDoesNotMatch"));
					
					return;
					
				}
				
				if ($("#Account-profileForm-passwordConfirmation").textbox("getValue") != $("#Account-profileForm-password").textbox("getValue"))
				{
					showErrorMessage(getMessage("common.passwordConfirmationDoesNotMatch"));
					
					return;
					
				}
				
				// collect form data
				
				var username = $("#Account-profileForm-email").textbox("getValue");
				var password = $("#Account-profileForm-password").textbox("getValue");
				
				// check username unique
				
				if (username)
				{
					var checkUsernameExistsResponse = getData("checkUsernameExists", {"username": username, });
					
					if (checkUsernameExistsResponse.usernameExists)
					{
						showErrorMessage(getMessage("common.uniqueUsernameValidationError.text"));
						
						return;
						
					}

				}
				
				// updateUser
				
				postData
				(
						"updateUser",
						{"username": username, "password": password, },
						true,
						function()
						{
							// credential changed
							
							if (username || password)
							{
								var alertTitle;
								var alertMessage;
								
								// email confirmation info
								
								if (username)
								{
									alertTitle = $scope.confirmationTitle;
									alertMessage = $scope.confirmationMessage;
									
								}
								else
								{
									alertTitle = $scope.logoutTitle;
									alertMessage = $scope.logoutMessage;
									
								}
								
								$.messager.alert
								(
										alertTitle,
										alertMessage,
										"info",
										function()
										{
											logout(true);
											
										}
								)
								;
								
							}
							else
							{
								// show confirmation
								
								showConfirmationMessage(getMessage("Account.profile.dataUpdatedConfirmation.text"));
								
								// clear form
								
								$scope.refreshProfile();
								
								// trigger AngularJS refresh
								
								$scope.$apply();
								
							}
							
						}
				)
				;
				
			}
			
			$scope.resetPassword = function()
			{
				postData
				(
						"sendResetPasswordLink",
						{},
						true,
						function()
						{
							// show confirmation
							
							showConfirmationMessage(getMessage("Account.profile.passwordResetConfirmation.text"));
							
						}
				)
				;
				
			}
			
			// changeEmailDialog
			
			$scope.initializeChangeEmailDialog = function()
			{
				$("#Account-changeEmail-form-email")
				.textbox
				(
						{
							cls: "background-icon-user",
							prompt: getMessage("Account.changeEmail.form.email"),
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
								$scope.changeEmail();
							}
						}
				)
				;
				
				$("#Account-changeEmail-form-submitButton").linkbutton
				(
						{
							text: getMessage("Account.changeEmail.form.submitButton.text"),
							onClick: $scope.changeEmail,
						}
				)
				;
				
			}
			
			$scope.openChangeEmailDialog = function()
			{
				$("#Account-changeEmailDialog").css("visibility", "visible");
				
			}
			
			$scope.closeChangeEmailDialog = function()
			{
				$("#Account-changeEmailDialog").css("visibility", "hidden");
				
			}
			
			$scope.changeEmail = function()
			{
				// validate form
				
				if (!$("#Account-changeEmail-form").form("validate"))
				{
					showErrorMessage(getMessage("common.alert.invalidFormErrorMessage"));
					
					return;
					
				}
				
				// collect form data
				
				var email = $("#Account-changeEmail-form-email").textbox("getValue");
				
				// check email unique
				
				var checkUsernameExistsResponse = getData("checkUsernameExists", {"username": email, });
				
				if (checkUsernameExistsResponse.usernameExists)
				{
					showErrorMessage(getMessage("Account.changeEmail.uniqueUserEmailValidationError.text"));
					
					return;
					
				}
				
				// change username
				
				postData
				(
						"setUsername",
						{"username": email, },
						true,
						function()
						{
							var alertTitle = $scope.logoutTitle;
							var alertMessage = $scope.logoutMessage;
							
							$.messager.alert
							(
									alertTitle,
									alertMessage,
									"info",
									function()
									{
										logout(true);
										
									}
							)
							;
							
						}
				)
				;
				
			}
			
			// changePasswordDialog
			
			$scope.initializeChangePasswordDialog = function()
			{
				$("#Account-changePassword-form-password")
				.passwordbox
				(
						{
							cls: "background-icon-lock",
							prompt: getMessage("Account.changePassword.form.password"),
							required: true,
						}
				)
				.passwordbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.changePassword();
							}
						}
				)
				;
				
				$("#Account-changePassword-form-passwordConfirmation")
				.passwordbox
				(
						{
							cls: "background-icon-lock",
							prompt: getMessage("Account.changePassword.form.passwordConfirmation"),
							required: true,
							validType: "equals['#Account-changePassword-form-password']",
							invalidMessage: getMessage("common.passwordConfirmationDoesNotMatch"),
						}
				)
				.passwordbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.changePassword();
							}
						}
				)
				;
				
				$("#Account-changePassword-form-submitButton").linkbutton
				(
						{
							text: getMessage("Account.changePassword.form.submitButton.text"),
							onClick: $scope.changePassword,
						}
				)
				;
				
			}
			
			$scope.openChangePasswordDialog = function()
			{
				$("#Account-changePasswordDialog").css("visibility", "visible");
				
			}
			
			$scope.closeChangePasswordDialog = function()
			{
				$("#Account-changePasswordDialog").css("visibility", "hidden");
				
			}
			
			$scope.changePassword = function()
			{
				// validate form
				
				if (!$("#Account-changePassword-form").form("validate"))
				{
					showErrorMessage(getMessage("common.alert.invalidFormErrorMessage"));
					
					return;
					
				}
				
				// collect form data
				
				var password = $("#Account-changePassword-form-password").textbox("getValue");
				
				// change password
				
				postData
				(
						"setPassword",
						{"password": password, },
						true,
						function()
						{
							var alertTitle = $scope.logoutTitle;
							var alertMessage = $scope.logoutMessage;
							
							$.messager.alert
							(
									alertTitle,
									alertMessage,
									"info",
									function()
									{
										logout(true);
										
									}
							)
							;
							
						}
				)
				;
				
			}
			
		}
)
;

