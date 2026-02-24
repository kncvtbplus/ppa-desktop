var application = angular.module("application", [])
.config
(
		function($locationProvider)
		{
			// use the HTML5 History API
			$locationProvider.html5Mode(true);
		}
)
;

application.controller
(
		"home",
		function($rootScope, $scope, $sce, $window, $timeout, $location)
		{
			loadMessages();
			
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// variables
			
			$scope.textboxTitle = $scope.trustAsHtml(getMessage("home.textboxTitle"));
			$scope.textboxSubtitle = $scope.trustAsHtml(getMessage("home.textboxSubtitle"));
			$scope.textboxDescription = $scope.trustAsHtml(getMessage("home.textboxDescription"));

			// Keep UI texts for login and sign-up.
			$scope.forgotUsernamePasswordHrefText = ""; // no email-based recovery in local/offline product
			$scope.signUpText = getMessage("loginUser.form.signUpText");
			$scope.signUpHrefText = getMessage("loginUser.form.signUpHrefText");
			$scope.loginText = getMessage("registerUser.form.loginText");
			$scope.loginHrefText = getMessage("registerUser.form.loginHrefText");
			
			$scope.token;
			$scope.tokenVerified = false;
			$scope.username;
			$scope.invitationAccountName;
			$scope.invitationExistingUser;
			
			// initialization
			
			$scope.$evalAsync
			(
					function()
					{
						window.setTimeout
						(
								$scope.onOpen,
								100
						)
						;
						
					}
			)
			;
			
		$scope.onOpen = function()
		{
			// Auto-login as guest and redirect to main app
			$scope.guestLogin();
			return;

			// --- Legacy login UI (kept for cloud mode reference) ---

			// home
			
			$scope.initializeHome();
			
			// registerUser
			
			$scope.initializeRegisterUserForm();
			
			// loginUser
			
			$scope.initializeLoginUserForm();
			
			// acceptInvitation
			
			$scope.initializeAcceptInvitationForm();
			
			// recoverPassword
			
			$scope.initializeRecoverPasswordForm();
			
			// resetPassword
			
			$scope.initializeResetPasswordForm();
			
			// post initialization
			
			if ($location.search().hasOwnProperty("confirmEmail"))
				{
					// check token
					
					$scope.token = $location.search().token;
					
					var confirmEmailTokenVerificationResponse =
						postData
						(
								"confirmEmail",
								{"token": $scope.token, },
								true,
								function(response)
								{
									showInformationMessage(getMessage("confirmEmail.information.message"));
									
								}
						)
					;
					
				}
				else if ($location.search().hasOwnProperty("acceptInvitation"))
				{
					// check token
					
					$scope.token = $location.search().token;
					
					var acceptInvitationTokenVerificationResponse =
						getDataAsync
						(
								"getAcceptInvitationTokenVerification",
								{"token": $scope.token, },
								function(response)
								{
									$scope.tokenVerified = true;
									$scope.invitationAccountName = response.invitationAccountName;
									$scope.invitationExistingUser = response.invitationExistingUser;
									
									if ($scope.invitationExistingUser)
									{
										// hide registration fields
										
										$("#acceptInvitation-form-password-cell").css("visibility", "hidden");
										$("#acceptInvitation-form-passwordConfirmation-cell").css("visibility", "hidden");
										
									}
									
									// update UI
									
									$scope.$apply();
									
									// show dialog
									
									$scope.showAcceptInvitationDialog();
									
								}
						)
					;
					
				}
				else if ($location.search().hasOwnProperty("resetPassword"))
				{
					// check token
					
					$scope.token = $location.search().token;
					
					if ($scope.token)
					{
						getDataAsync
						(
								"getResetPasswordTokenVerification",
								{"token": $scope.token, },
								function(response)
								{
									if (response.success)
									{
										$scope.tokenVerified = true;
										$scope.username = response.username;
										
										$scope.showResetPasswordDialog();
										
									}
									else
									{
										switch (response.error)
										{
										case "invalid":
											$.messager.alert
											(
													getMessage("resetPassword.invalidResetPasswordUrl.title"),
													getMessage("resetPassword.invalidResetPasswordUrl.message"),
													"error"
											)
											;
											break;
											
										case "expired":
											$.messager.alert
											(
													getMessage("resetPassword.expiredResetPasswordUrl.title"),
													getMessage("resetPassword.expiredResetPasswordUrl.message"),
													"error"
											)
											;
											break;
											
										default:
											$.messager.alert
											(
													"Unexpected error",
													"Please contact application administrator.",
													"error"
											)
											;
										
										}
										
									}
									
								}
						)
						;
						
						
					}
					else
					{
						$.messager.alert
						(
								getMessage("resetPassword.invalidResetPasswordUrl.title"),
								getMessage("resetPassword.invalidResetPasswordUrl.message"),
								"error"
						)
						;
						
					}
					
				}
				else if ($location.search().hasOwnProperty("login"))
				{
					$scope.showLoginUserDialog();
					
				}
				
			}
			
			// home
			
			$scope.initializeHome = function()
			{
				$("#home-loginButton").linkbutton
				(
						{
							text: getMessage("home.button.login.text"),
							onClick: $scope.showLoginUserDialog,
						}
				)
				;

				$("#home-registerButton").linkbutton
				(
						{
							text: getMessage("home.button.register.text"),
							onClick: $scope.showRegisterUserDialog,
						}
				)
				;

				$("#home-guestButton").linkbutton
				(
						{
							text: "Continue without login",
							onClick: $scope.guestLogin,
						}
				)
				;

			}
			
			// registerUser
			
			$scope.initializeRegisterUserForm = function()
			{
				$("#registerUser-form-username").textbox
				(
						{
							cls: "background-icon-user",
							prompt: getMessage("registerUser.form.username"),
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
								$scope.registerUser();
							}
						}
				)
				;
				
				$("#registerUser-form-password").passwordbox
				(
						{
							cls: "background-icon-lock",
							prompt: getMessage("registerUser.form.password"),
							required: true,
						}
				)
				.textbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.registerUser();
							}
						}
				)
				;
				
				$("#registerUser-form-passwordConfirmation").passwordbox
				(
						{
							cls: "background-icon-lock",
							prompt: getMessage("registerUser.form.passwordConfirmation"),
							required: true,
							validType: "equals['#registerUser-form-password']",
							invalidMessage: "Pasword and password confirmation do not match.",
						}
				)
				.textbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.registerUser();
							}
						}
				)
				;
				
				$("#registerUser-form-submitButton").linkbutton
				(
						{
							text: getMessage("registerUser.form.submitButton.text"),
							onClick: $scope.registerUser,
						}
				)
				;
				
			}
			
			$scope.showRegisterUserDialog = function()
			{
				$(".dialog").css("visibility", "hidden");
				$("#registerUserDialog").css("visibility", "visible");
				
			}
			
			$scope.hideRegisterUserDialog = function()
			{
				$("#registerUserDialog").css("visibility", "hidden");
				
			}
			
			$scope.registerUser = function()
			{
				// validate form
				
				if (!$("#registerUser-form").form("validate"))
				{
					showErrorMessage(getMessage("common.alert.invalidFormErrorMessage"));
					
					return;
					
				}
				
				// collect form data
				
				var username = $("#registerUser-form-username").textbox("getValue");
				var password = $("#registerUser-form-password").textbox("getValue");
				
				// registerUser
				
				postData
				(
						"registerUser",
						{"username": username, "password": password, },
						true,
						function()
						{
							// clear form
							
							$("#registerUser-form").form("clear");
							
							// close form
							
							$scope.hideRegisterUserDialog();
							
							// show information
							
							showInformationMessage(getMessage("registerUser.informationMessage.text"))
							
						}
				)
				;
				
			}
			
			// loginUser
			
			$scope.initializeLoginUserForm = function()
			{
				$("#loginUser-form-username").textbox
				(
						{
							cls: "background-icon-user",
							prompt: getMessage("loginUser.form.username"),
							required: true,
							// TODO temporary allow non email logins
//							validType: "email",
						}
				)
				.textbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.loginUser();
							}
						}
				)
				;
				
				$("#loginUser-form-password").passwordbox
				(
						{
							cls: "background-icon-lock",
							prompt: getMessage("loginUser.form.password"),
							required: true,
						}
				)
				.textbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.loginUser();
							}
						}
				)
				;
				
				$("#loginUser-form-registerButton").linkbutton
				(
						{
							cls: "background-icon-lock",
							text: getMessage("loginUser.form.submitButton.text"),
							onClick: $scope.loginUser,
						}
				)
				;
				
			}
			
			$scope.showLoginUserDialog = function()
			{
				$(".dialog").css("visibility", "hidden");
				$("#loginUserDialog").css("visibility", "visible");
				
			}
			
			$scope.hideLoginUserDialog = function()
			{
				$("#loginUserDialog").css("visibility", "hidden");
				
			}
			
			$scope.loginUser = function()
			{
				// validate form
				
				if (!$("#loginUser-form").form("validate"))
				{
					showErrorMessage(getMessage("common.alert.invalidFormErrorMessage"));
					
					return;
					
				}
				
				// login
				
				var rememberMe = $("#loginUser-form-rememberme").is(":checked");
				
				login
				(
						{
							"username": $("#loginUser-form-username").textbox("getValue"),
							"password": $("#loginUser-form-password").passwordbox("getValue"),
							"remember-me": rememberMe ? "on" : "off",
						},
						// success handler
						function()
						{
							// redirect user to application site
							
							window.location.href = "/";
							
						}
				)
				;
				
			}
			
			// guestLogin
			
			$scope.guestLogin = function()
			{
				postData
				(
						"guestLogin",
						{},
						true,
						function()
						{
							window.location.href = "/";
							
						}
				)
				;
				
			}
			
			// acceptInvitation
			
			$scope.initializeAcceptInvitationForm = function()
			{
				$("#acceptInvitation-form-password").passwordbox
				(
						{
							cls: "background-icon-lock",
							prompt: getMessage("acceptInvitation.form.password"),
							required: true,
						}
				)
				.textbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.acceptInvitation();
							}
						}
				)
				;
				
				$("#acceptInvitation-form-passwordConfirmation").passwordbox
				(
						{
							cls: "background-icon-lock",
							prompt: getMessage("acceptInvitation.form.passwordConfirmation"),
							required: true,
							validType: "equals['#acceptInvitation-form-password']",
							invalidMessage: "Pasword and password confirmation do not match.",
						}
				)
				.textbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.acceptInvitation();
							}
						}
				)
				;
				
				$("#acceptInvitation-form-acceptInvitationButton").linkbutton
				(
						{
							text: getMessage("acceptInvitation.form.submitButton.text"),
							onClick: $scope.acceptInvitation,
						}
				)
				;
				
			}
			
			$scope.showAcceptInvitationDialog = function()
			{
				$(".dialog").css("visibility", "hidden");
				$("#acceptInvitationDialog").css("visibility", "visible");
				
			}
			
			$scope.hideAcceptInvitationDialog = function()
			{
				$("#acceptInvitationDialog").css("visibility", "hidden");
				
			}
			
			$scope.acceptInvitation = function()
			{
				if ($scope.invitationExistingUser)
				{
					// do not validate form
					
				}
				else
				{
					// validate form
					
					if (!$("#acceptInvitation-form").form("validate"))
					{
						showErrorMessage(getMessage("common.alert.invalidFormErrorMessage"));
						
						return;
						
					}
					
					// collect form data
					
					var password = $("#acceptInvitation-form-password").textbox("getValue");
					
				}
				
				// acceptInvitation
				
				postData
				(
						"acceptInvitation",
						{"token": $scope.token, "password": password, },
						true,
						function(response)
						{
							// hide dialog
							
							$scope.hideAcceptInvitationDialog();
							
							// clear form
							
							$("#acceptInvitation-form").form("clear");
							
							if ($scope.invitationExistingUser)
							{
								// show login form
								
								$scope.showLoginUserDialog();
								
								// show confirmation
								
								showConfirmationMessage(getMessage("acceptInvitation.confirmation.message"))
								
							}
							else
							{
								// automatically login user
								
								$("#loginUser-form-username").textbox("setValue", response.username);
								$("#loginUser-form-password").passwordbox("setValue", password);
								$scope.loginUser();
								
							}
								
						}
				)
				;
				
			}
			
			// recoverPassword
			
			$scope.initializeRecoverPasswordForm = function()
			{
				$("#recoverPassword-form-email").textbox
				(
						{
							cls: "background-icon-email",
							prompt: getMessage("recoverPassword.form.email"),
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
								$scope.recoverPassword();
							}
						}
				)
				;
				
				$("#recoverPassword-form-sendButton").linkbutton
				(
						{
							text: getMessage("recoverPassword.form.submitButton.text"),
							onClick: $scope.recoverPassword,
						}
				)
				;
				
			}
			
			$scope.showRecoverPasswordDialog = function()
			{
				$(".dialog").css("visibility", "hidden");
				$("#recoverPasswordDialog").css("visibility", "visible");
				
			}
			
			$scope.hideRecoverPasswordDialog = function()
			{
				$("#recoverPasswordDialog").css("visibility", "hidden");
				
			}
			
			$scope.recoverPassword = function()
			{
				// validate form
				
				if (!$("#recoverPassword-form").form("validate"))
				{
					showErrorMessage(getMessage("common.alert.invalidFormErrorMessage"));
					
					return;
					
				}
				
				// collect form data
				
				var email = $("#recoverPassword-form-email").textbox("getValue");
				
				// recoverPassword
				
				postData
				(
						"sendRecoverUsernameAndPasswordLink",
						{"email": email, },
						true,
						function()
						{
							// clear form
							
							$("#recoverPassword-form").form("clear");
							
							// hide recoverPassword dialog
							
							$scope.hideRecoverPasswordDialog();
							
							// show confirmation
							
							showConfirmationMessage(getMessage("recoverPassword.confirmationMessage.text"))
							
						}
				)
				;
				
			}
			
			// resetPassword
			
			$scope.initializeResetPasswordForm = function()
			{
				$("#resetPassword-form-password").passwordbox
				(
						{
							cls: "background-icon-lock",
							prompt: getMessage("resetPassword.form.password"),
							required: true,
						}
				)
				.textbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.resetPassword();
							}
						}
				)
				;
				
				$("#resetPassword-form-passwordConfirmation").passwordbox
				(
						{
							cls: "background-icon-lock",
							prompt: getMessage("resetPassword.form.passwordConfirmation"),
							required: true,
							validType: "equals['#resetPassword-form-password']",
							invalidMessage: "Pasword and password confirmation do not match.",
						}
				)
				.textbox("textbox").bind
				(
						"keydown",
						function(e)
						{
							if (e.keyCode == 13)
							{
								$scope.resetPassword();
							}
						}
				)
				;
				
				$("#resetPassword-form-resetPasswordButton").linkbutton
				(
						{
							text: getMessage("resetPassword.form.submitButton.text"),
							onClick: $scope.resetPassword,
						}
				)
				;
				
			}
			
			$scope.showResetPasswordDialog = function()
			{
				$(".dialog").css("visibility", "hidden");
				$("#resetPasswordDialog").css("visibility", "visible");
				
			}
			
			$scope.hideResetPasswordDialog = function()
			{
				$("#resetPasswordDialog").css("visibility", "hidden");
				
			}
			
			$scope.resetPassword = function()
			{
				// validate form
				
				if (!$("#resetPassword-form").form("validate"))
				{
					showErrorMessage(getMessage("common.alert.invalidFormErrorMessage"));
					
					return;
					
				}
				
				// collect form data
				
				var password = $("#resetPassword-form-password").textbox("getValue");
				
				// resetPassword
				
				postData
				(
						"resetPassword",
						{"token": $scope.token, "password": password, },
						true,
						function()
						{
							// clear form
							
							$("#resetPassword-form").form("clear");
							
							// show loginUser dialog
							
							$scope.showLoginUserDialog();
							
							// show confirmation
							
							showConfirmationMessage(getMessage("resetPassword.confirmation.title"), getMessage("resetPassword.confirmation.message"))
							
						}
				)
				;
				
			}
			
		}
)
;

