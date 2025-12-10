var application = angular.module("application", []);

application.controller
(
		"index",
		function($rootScope, $scope, $sce, $window, $timeout)
		{
			loadMessages();
			
			// messages
			
			$scope.getMessage = getMessage;
			$scope.trustAsHtml = $sce.trustAsHtml;
			
			// rootScope variables
			
			$rootScope.tableCheckColumnWidth = 28;
			$rootScope.tableScrollbarWidth = 17;
			
			// variables
			
			$scope.waitForOtherAdminsLogoutHandler;
			$scope.ppaAggregationLevel;
			
			$scope.tabs =
				{
					"Accounts":
					{
						role: "ROLE_USER",
					},
					"SelectPPA":
					{
						role: "ROLE_USER",
					},
					"Account":
					{
						role: "ROLE_USER",
					},
					"MyDataSources":
						{
							role: "ROLE_USER",
						},
					"SelectPpaMetrics1":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-SelectPpaMetrics",
							submenuItemId: "Home-menu-SelectPpaMetrics1",
						},
					"SelectPpaMetrics2":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-SelectPpaMetrics",
							submenuItemId: "Home-menu-SelectPpaMetrics2",
						},
					"UploadAndPrepData1":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-UploadAndPrepData",
							submenuItemId: "Home-menu-UploadAndPrepData1",
						},
					"UploadAndPrepData2":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-UploadAndPrepData",
							submenuItemId: "Home-menu-UploadAndPrepData2",
						},
					"UploadAndPrepData3":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-UploadAndPrepData",
							submenuItemId: "Home-menu-UploadAndPrepData3",
						},
					"IdentifyPpaVariables1":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-IdentifyPpaVariables",
							submenuItemId: "Home-menu-IdentifyPpaVariables1",
						},
					"IdentifyPpaVariables2":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-IdentifyPpaVariables",
							submenuItemId: "Home-menu-IdentifyPpaVariables2",
						},
					"MapHealthSectorsAndLevels1":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-MapHealthSectorsAndLevels",
							submenuItemId: "Home-menu-MapHealthSectorsAndLevels1",
						},
					"MapHealthSectorsAndLevels2":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-MapHealthSectorsAndLevels",
							submenuItemId: "Home-menu-MapHealthSectorsAndLevels2",
						},
					"MapAggregationLevels1":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-MapAggregationLevels",
							submenuItemId: "Home-menu-MapAggregationLevels1",
						},
					"MapAggregationLevels2":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-MapAggregationLevels",
							submenuItemId: "Home-menu-MapAggregationLevels2",
						},
					"SelectOutputTypeAndGo1":
						{
							role: "ROLE_USER",
							ppaRequired: true,
							menuItemId: "Home-menu-SelectOutputTypeAndGo",
							submenuItemId: "Home-menu-SelectOutputTypeAndGo1",
						},
				}
			;
			$scope.wizardTabsNational = ["SelectPPA", "SelectPpaMetrics1", "SelectPpaMetrics2", "UploadAndPrepData1", "UploadAndPrepData2", "UploadAndPrepData3", "IdentifyPpaVariables1", "IdentifyPpaVariables2", "MapHealthSectorsAndLevels1", "MapHealthSectorsAndLevels2", "SelectOutputTypeAndGo1", ];
			$scope.wizardTabsSubnational = ["SelectPPA", "SelectPpaMetrics1", "SelectPpaMetrics2", "UploadAndPrepData1", "UploadAndPrepData2", "UploadAndPrepData3", "IdentifyPpaVariables1", "IdentifyPpaVariables2", "MapHealthSectorsAndLevels1", "MapHealthSectorsAndLevels2", "MapAggregationLevels1", "MapAggregationLevels2", "SelectOutputTypeAndGo1", ];
			
			$scope.initialized = false;
			$scope.onOpen = function()
			{
				if (!$scope.initialized)
				{
					$scope.initialized = true;
					
					$scope.refreshUser();
					
					$scope.setVariables();
					
					$scope.createLoginButton();
					$scope.createUserMenu();
					$scope.createSelectedAccount();
					$scope.createSelectedPpa();
					$scope.createMenu();
					
					// refresh menu button states
					
					$scope.refreshMenuButtonStates();
					
					// navigate to last user page
					
					var userNavigationPage = $rootScope.user.navigationPage || "Accounts";
					
					if (userNavigationPage)
					{
						$scope.selectContentTab(userNavigationPage);
						
					}
					
				}
				
				// refresh user menu
				
				$scope.refreshUserMenu();
				
			}
			
			// wizard ribbon
			
			$scope.showWizardRibbon = function()
			{
				$("#Home-page-header-bottom").panel("expand");
				
			}
			
			$scope.hideWizardRibbon = function()
			{
				$("#Home-page-header-bottom").panel("collapse");
				
			}
			
			// user
			
			$scope.refreshUser = function()
			{
				// (get synchronously)
				
				$rootScope.user = getData("getCurrentUser");
				
			}
			
			// variables
			
			$scope.setVariables = function()
			{
				$scope.menuUploadAndPrepDataText = $scope.trustAsHtml(getMessage("home.menu.UploadAndPrepData.text"));
				$scope.menuIdentifyPpaVariablesText = $scope.trustAsHtml(getMessage("home.menu.IdentifyPpaVariables.text"));
				$scope.menuMapHealthSectorsAndLevelsText = $scope.trustAsHtml(getMessage("home.menu.MapHealthSectorsAndLevels.text"));
				$scope.menuMapAggregationLevelsText = $scope.trustAsHtml(getMessage("home.menu.MapAggregationLevels.text"));
				$scope.menuSelectOutputTypeAndGoText = $scope.trustAsHtml(getMessage("home.menu.SelectOutputTypeAndGo.text"));
				
			}
			
			// logo
			
			$scope.createLogo = function()
			{
				$("#Home-logo").linkbutton
				(
						{
							plain: true,
							text: getMessage("common.label.LOGO"),
							onClick:
								function()
								{
									// select home tab
									
									$scope.selectContentTab("Home");
									
									// unselect all menu buttons
									
									$(".menu-button").linkbutton("unselect");
									
								},
						}
				)
				;
				
			}
			
			// loginButton
			
			$scope.createLoginButton = function()
			{
				$("#Home-loginButton").linkbutton
				(
						{
							text: getMessage("home.userMenu.login.text"),
							onClick:
								function()
								{
									call(null, "selectContentTab", ["Login", ]);
									
								},
						}
				)
				;
				
			}
			
			// userMenu
			
			$scope.createUserMenu = function()
			{
				// menu button
				
				$("#Home-userMenuButton").menubutton
				(
						{
							size: "large",
							plain: true,
							hasDownArrow: false,
							iconCls: "icon-menu",
//							text: getMessage("home.userMenuButton.notAuthenticated.text"),
							showEvent: "mouseenter",
							onClick:
								function()
								{
									$($(this).menubutton("options")["menu"]).menu("show");
									
								},
						}
				)
				;
				
				// menu for not authenticated user
				
				$("#Home-userMenu-notAuthenticated").menu({});
				
				$("#Home-userMenu-notAuthenticated").menu
				(
						"appendItem",
						{
							id: "Home-userMenu-login",
							text: getMessage("home.userMenu.login.text"),
							onclick:
								function()
								{
									call(null, "selectContentTab", ["Login", ]);
									
								},
						}
				)
				;
				
				// menu for authenticated user
				
				$("#Home-userMenu-authenticated").menu({});
				
				$("#Home-userMenu-authenticated").menu
				(
						"appendItem",
						{
							id: "Home-userMenu-Accounts",
							text: getMessage("home.userMenu.Accounts.text"),
							onclick:
								function()
								{
									call(null, "selectContentTab", ["Accounts", ]);
									
								},
						}
				)
				;
				
				$("#Home-userMenu-authenticated").menu
				(
						"appendItem",
						{
							id: "Home-userMenu-myPPAs",
							text: getMessage("home.userMenu.myPPAs.text"),
							onclick:
								function()
								{
									call(null, "selectContentTab", ["SelectPPA", ]);
									
								},
						}
				)
				;
				
				$("#Home-userMenu-authenticated").menu
				(
						"appendItem",
						{
							id: "Home-userMenu-myUserFiles",
							text: getMessage("home.userMenu.myDataSources.text"),
							onclick:
								function()
								{
									call(null, "selectContentTab", ["MyDataSources", ]);
									
								},
						}
				)
				;
				
				$("#Home-userMenu-authenticated").menu
				(
						"appendItem",
						{
							id: "Home-userMenu-accountSettings",
							text: getMessage("home.userMenu.accountSettings.text"),
							onclick:
								function()
								{
									call(null, "selectContentTab", ["Account", ]);
									
								},
						}
				)
				;
				
				$("#Home-userMenu-authenticated").menu
				(
						"appendItem",
						{
							id: "Home-userMenu-switchUserAccount",
							text: getMessage("home.userMenu.switchUserAccount.text"),
							onclick:
								function()
								{
									logout(true);
									
								},
						}
				)
				;
				
				// Add 'contact'
				$("#Home-userMenu-authenticated").menu
				(
						"appendItem",
						{
							id: "Home-userMenu-contact",
							text: getMessage("home.userMenu.contact.text"),
							onclick:
								function()
								{
									  console.log("Running contact link menu item");
									  
									  var recipient = getMessage("home.userMenu.contact.recipient");
									  var subject = getMessage("home.userMenu.contact.subject");
									  var body = getMessage("home.userMenu.contact.body");
									 
									  var mailtoLink = "mailto:" + recipient +
									                   "?subject=" + encodeURIComponent(subject) +
									                   "&body=" + encodeURIComponent(body);
									 
									  var href_mailtoLink='<a href="' + mailtoLink + '">Contact</a>';
									  console.log("href_mailtoLink="+href_mailtoLink);
									  //alert("Click the following link to open your email client: \n\n" + href_mailtoLink);
									  // window.location.href = mailtoLink;
									  
									// Create a custom alert with a clickable link
									console.log("Opening alertBox...");
									  var alertBox = document.createElement("div");
									  alertBox.style.position = "fixed";
									  alertBox.style.left = "50%";
									  alertBox.style.top = "50%";
									  alertBox.style.transform = "translate(-50%, -50%)";
									  alertBox.style.padding = "20px";
									  alertBox.style.backgroundColor = "white";
									  alertBox.style.border = "1px solid black";
									  alertBox.style.zIndex = "1000";
									 
									  var message = document.createElement("p");
									  message.innerHTML = "Click the link to open your email client: <a href='" + mailtoLink + "'>Open Email Client</a>";
									  alertBox.appendChild(message);
									 
									  var closeButton = document.createElement("button");
									  closeButton.innerText = "Close";
									  closeButton.onclick = function() {
									    document.body.removeChild(alertBox);
									  };
									  alertBox.appendChild(closeButton);
									 
									  document.body.appendChild(alertBox);
  

								},
						}
				)
				;
				
				$("#Home-userMenu-authenticated").menu
				(
						"appendItem",
						{
							id: "Home-userMenu-logout",
							text: getMessage("home.userMenu.logout.text"),
							onclick:
								function()
								{
									logout(false);
									
								},
						}
				)
				;
				
			}
			
			$scope.refreshUserMenu = function()
			{
				// attach menu for authenticated user
				
				$("#Home-userMenuButton").menubutton({menu: "#Home-userMenu-authenticated"})
				
				// toggle account dependent items
				
				if ($("#Home-selectedAccount").combobox("getValue") == "")
				{
					$("#Home-userMenu-authenticated").menu("disableItem", $("#Home-userMenu-myPPAs")[0]);
					$("#Home-userMenu-authenticated").menu("disableItem", $("#Home-userMenu-myUserFiles")[0]);
					
				}
				else
				{
					$("#Home-userMenu-authenticated").menu("enableItem", $("#Home-userMenu-myPPAs")[0]);
					$("#Home-userMenu-authenticated").menu("enableItem", $("#Home-userMenu-myUserFiles")[0]);
					
				}
				
				// check duplicate login
				
				if ($rootScope.user.recentLogin != null)
				{
					// show alert
					
					$.messager.alert
					(
							getMessage("Login.duplicateLoginAlert.title"),
							getMessage("Login.duplicateLoginAlert.text", user.recentLogin),
							"warning"
					);
					
					// clear recentLogin
					
					postData("clearCurrentUserRecentLogin");
					
				}
				
			}
			
			// selectedAccount
			
			$scope.createSelectedAccount = function()
			{
				$("#Home-selectedAccount").combobox
				(
						{
							panelAlign: "left",
							panelWidth: 394,
							valueField: "id",
							textField: "name",
							editable: false,
							url: "data/getAccounts",
							onChange:
								function(newValue)
								{
									$scope.selectAccount(newValue);
	
								},
						}
				)
				;
				
			}
			
			$scope.refreshSelectedAccount = function()
			{
				$("#Home-selectedAccount").combobox("reload");
				
			}
			
			$scope.selectAccount = function(accountId)
			{
				// move cursor to left
				
				$("#Home-selectedAccount").combobox("textbox")[0].setSelectionRange(0, 0);
				
				// selectAccount
				
				postData("selectAccount", {"accountId": accountId, });
				
				// refresh user
				
				$rootScope.user = getData("getCurrentUser");
				
				// selectAccount on Accounts page
				
				$("#Accounts-accounts-select-" + accountId + "").radiobutton("check");
				
				// refresh selectedPpa
				
				$scope.refreshSelectedPpa();
				
				// refresh userMenu
				
				$scope.refreshUserMenu();
				
				// check logged admins
				
				$scope.checkLoggedAdmins();
				
			}
			
			// selectedPpa
			
			$scope.createSelectedPpa = function()
			{
				$("#Home-selectedPpa").combobox
				(
						{
							panelAlign: "right",
							panelWidth: 394,
							valueField: "id",
							textField: "name",
							editable: false,
							url: "data/getPpas",
							onChange:
								function(newValue)
								{
									if (newValue)
									{
										$scope.selectPpa(newValue);
										
									}
									
								},
						}
				)
				;
				
			}
			
			$scope.refreshSelectedPpa = function()
			{
				// refresh select PPA datagrid
				
				$("#SelectPPA-ppas").datagrid("reload");

				// refresh selected PPA combobox
				
				$("#Home-selectedPpa").combobox("clear").combobox("reload");
				
			}
			
			$scope.selectPpa = function(ppaId)
			{
				// move cursor to left
				
				$("#Home-selectedPpa").combobox("textbox")[0].setSelectionRange(0, 0);
				
				// selectPpa
				
				postData("selectPpa", {"ppaId": ppaId, });
				
				// refresh user
				
				$scope.refreshUser();
				
				// refresh menu button states
				
				$scope.refreshMenuButtonStates();
				
				// refresh open page
				
				var contentTabTitle = $($("#conentTabs").tabs("getSelected")).panel("options")["title"];
				
				switch (contentTabTitle)
				{
				case "Accounts":
					
					// do nothing
					
				case "SelectPPA":
					
					// selectPpa on SelectPPA page
					
					$("#SelectPPA-ppas-select-" + ppaId + "").radiobutton("check");
					
					break;
					
				default:
					
					// refresh page
					
					call(contentTabTitle, "onOpen");
				
				}
				
				// NWL
				// check logged admins since this now is PPA specific
				
				$scope.checkLoggedAdmins();
				
			}
			
			// menu
			
			$scope.createMenu = function()
			{
				// SelectPpaMetrics
				
				$("#Home-menu-SelectPpaMetrics").menubutton
				(
						{
							plain: true,
							hasDownArrow: false,
							text: "<span class='page-header-wizard-menu-text'><span class='page-header-wizard-menu-text-number'>" + getMessage("home.menu.SelectPpaMetrics.number") + "</span> <span class='page-header-wizard-menu-text-name'>" + getMessage("home.menu.SelectPpaMetrics.name") + "</span></span>",
							menu: "#Home-menu-SelectPpaMetrics-menu",
						}
				)
				;
				$("#Home-menu-SelectPpaMetrics").addClass("Home-menu-item");
				
				$("#Home-menu-SelectPpaMetrics-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-SelectPpaMetrics1",
							text: getMessage("home.menu.SelectPpaMetrics1.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("SelectPpaMetrics1");
									
								},
						}
				)
				;
				$("#Home-menu-SelectPpaMetrics1").addClass("Home-submenu-item");
				
				$("#Home-menu-SelectPpaMetrics-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-SelectPpaMetrics2",
							text: getMessage("home.menu.SelectPpaMetrics2.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("SelectPpaMetrics2");
									
								},
						}
				)
				;
				$("#Home-menu-SelectPpaMetrics2").addClass("Home-submenu-item");
				
				// UploadAndPrepData
				
				$("#Home-menu-UploadAndPrepData").menubutton
				(
						{
							plain: true,
							hasDownArrow: false,
							text: "<span class='page-header-wizard-menu-text'><span class='page-header-wizard-menu-text-number'>" + getMessage("home.menu.UploadAndPrepData.number") + "</span> <span class='page-header-wizard-menu-text-name'>" + getMessage("home.menu.UploadAndPrepData.name") + "</span></span>",
							menu: "#Home-menu-UploadAndPrepData-menu",
						}
				)
				;
				$("#Home-menu-UploadAndPrepData").addClass("Home-menu-item");
				
				$("#Home-menu-UploadAndPrepData-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-UploadAndPrepData1",
							text: getMessage("home.menu.UploadAndPrepData1.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("UploadAndPrepData1");
									
								},
						}
				)
				;
				$("#Home-menu-UploadAndPrepData1").addClass("Home-submenu-item");
				
				$("#Home-menu-UploadAndPrepData-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-UploadAndPrepData2",
							text: getMessage("home.menu.UploadAndPrepData2.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("UploadAndPrepData2");
									
								},
						}
				)
				;
				$("#Home-menu-UploadAndPrepData2").addClass("Home-submenu-item");
				
				$("#Home-menu-UploadAndPrepData-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-UploadAndPrepData3",
							text: getMessage("home.menu.UploadAndPrepData3.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("UploadAndPrepData3");
									
								},
						}
				)
				;
				$("#Home-menu-UploadAndPrepData3").addClass("Home-submenu-item");
				
				// IdentifyPpaVariables
				
				$("#Home-menu-IdentifyPpaVariables").menubutton
				(
						{
							plain: true,
							hasDownArrow: false,
							text: "<span class='page-header-wizard-menu-text'><span class='page-header-wizard-menu-text-number'>" + getMessage("home.menu.IdentifyPpaVariables.number") + "</span> <span class='page-header-wizard-menu-text-name'>" + getMessage("home.menu.IdentifyPpaVariables.name") + "</span></span>",
							menu: "#Home-menu-IdentifyPpaVariables-menu",
						}
				)
				;
				$("#Home-menu-IdentifyPpaVariables").addClass("Home-menu-item");
				
				$("#Home-menu-IdentifyPpaVariables-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-IdentifyPpaVariables1",
							text: getMessage("home.menu.IdentifyPpaVariables1.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("IdentifyPpaVariables1");
									
								},
						}
				)
				;
				$("#Home-menu-IdentifyPpaVariables1").addClass("Home-submenu-item");
				
				$("#Home-menu-IdentifyPpaVariables-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-IdentifyPpaVariables2",
							text: getMessage("home.menu.IdentifyPpaVariables2.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("IdentifyPpaVariables2");
									
								},
						}
				)
				;
				$("#Home-menu-IdentifyPpaVariables2").addClass("Home-submenu-item");
				
				// MapHealthSectorsAndLevels
				
				$("#Home-menu-MapHealthSectorsAndLevels").menubutton
				(
						{
							plain: true,
							hasDownArrow: false,
							text: "<span class='page-header-wizard-menu-text'><span class='page-header-wizard-menu-text-number'>" + getMessage("home.menu.MapHealthSectorsAndLevels.number") + "</span> <span class='page-header-wizard-menu-text-name'>" + getMessage("home.menu.MapHealthSectorsAndLevels.name") + "</span></span>",
							menu: "#Home-menu-MapHealthSectorsAndLevels-menu",
						}
				)
				;
				$("#Home-menu-MapHealthSectorsAndLevels").addClass("Home-menu-item");
				
				$("#Home-menu-MapHealthSectorsAndLevels-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-MapHealthSectorsAndLevels1",
							text: getMessage("home.menu.MapHealthSectorsAndLevels1.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("MapHealthSectorsAndLevels1");
									
								},
						}
				)
				;
				$("#Home-menu-MapHealthSectorsAndLevels1").addClass("Home-submenu-item");
				
				$("#Home-menu-MapHealthSectorsAndLevels-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-MapHealthSectorsAndLevels2",
							text: getMessage("home.menu.MapHealthSectorsAndLevels2.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("MapHealthSectorsAndLevels2");
									
								},
						}
				)
				;
				$("#Home-menu-MapHealthSectorsAndLevels2").addClass("Home-submenu-item");
				
				// MapAggregationLevels
				
				$("#Home-menu-MapAggregationLevels").menubutton
				(
						{
							plain: true,
							hasDownArrow: false,
							text: "<span class='page-header-wizard-menu-text'><span class='page-header-wizard-menu-text-number'>" + getMessage("home.menu.MapAggregationLevels.number") + "</span> <span class='page-header-wizard-menu-text-name'>" + getMessage("home.menu.MapAggregationLevels.name") + "</span></span>",
							menu: "#Home-menu-MapAggregationLevels-menu",
						}
				)
				;
				$("#Home-menu-MapAggregationLevels").addClass("Home-menu-item");
				
				$("#Home-menu-MapAggregationLevels-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-MapAggregationLevels1",
							text: getMessage("home.menu.MapAggregationLevels1.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("MapAggregationLevels1");
									
								},
						}
				)
				;
				$("#Home-menu-MapAggregationLevels1").addClass("Home-submenu-item");
				
				$("#Home-menu-MapAggregationLevels-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-MapAggregationLevels2",
							text: getMessage("home.menu.MapAggregationLevels2.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("MapAggregationLevels2");
									
								},
						}
				)
				;
				$("#Home-menu-MapAggregationLevels2").addClass("Home-submenu-item");
				
				// SelectOutputTypeAndGo
				
				$("#Home-menu-SelectOutputTypeAndGo").menubutton
				(
						{
							plain: true,
							hasDownArrow: false,
							text: "<span class='page-header-wizard-menu-text'><span class='page-header-wizard-menu-text-number'>" + getMessage("home.menu.SelectOutputTypeAndGo.number") + "</span> <span class='page-header-wizard-menu-text-name'>" + getMessage("home.menu.SelectOutputTypeAndGo.name") + "</span></span>",
							menu: "#Home-menu-SelectOutputTypeAndGo-menu",
						}
				)
				;
				$("#Home-menu-SelectOutputTypeAndGo").addClass("Home-menu-item");
				
				$("#Home-menu-SelectOutputTypeAndGo-menu").menu
				(
						"appendItem",
						{
							id: "Home-menu-SelectOutputTypeAndGo1",
							text: getMessage("home.menu.SelectOutputTypeAndGo1.text"),
							onclick:
								function()
								{
									$scope.selectContentTab("SelectOutputTypeAndGo1");
									
								},
						}
				)
				;
				$("#Home-menu-SelectOutputTypeAndGo1").addClass("Home-submenu-item");
				
			}
			
			$scope.refreshMenuButtonStates = function()
			{
				var selectedPpa = $("#Home-selectedPpa").combobox("getValue");
				
				if (selectedPpa != "")
				{
					getDataAsync
					(
							"getPpaAggregationLevel",
							{},
							function(ppaAggregationLevel)
							{
								$scope.ppaAggregationLevel = ppaAggregationLevel;
								
								var action = (ppaAggregationLevel.national ? "disable" : "enable");
								
								$("#Home-menu-MapAggregationLevels").menubutton(action);
								
							}
					)
					;
					
				}

			}
			
			/**
			 * Selects content tab with given tab title.
			 */
			$scope.selectContentTab = function(tabTitle)
			{
				// assert tabTitle is not null
				
				if (!tabTitle)
				{
					alert("selectContentTab: empty tabTitle.");
					
					return;
					
				}
				
				// assert tabTitle is listed
				
				if (!$scope.tabs.hasOwnProperty(tabTitle))
				{
					alert("selectContentTab: tabTitle is not listed.");
					
					return;
					
				}
				
				// assert tab with this title exists
				
				if ($("#conentTabs").tabs("getTab", tabTitle) == null)
				{
					alert("selectContentTab: tab with tabTitle does not exist.");
					
					return;

				}
				
				// check special conditions
				
				switch (tabTitle)
				{
				case "MapAggregationLevels1":
				case "MapAggregationLevels2":
					
					// get dataSources with region column set
					
					var getDataSourcesWithRegionColumnSet = getData("getDataSources", {"subnationalUnitColumnNameSet": true, });
					
					if (getDataSourcesWithRegionColumnSet.length == 0)
					{
						$.messager.alert
						(
								getMessage("MapAggregationLevels1.emptyDataSources.message.title"),
								getMessage("MapAggregationLevels1.emptyDataSources.message.text"),
								"warning"
						);
						
						call(null, "selectContentTab", ["IdentifyPpaVariables1", ]);
						
						return;
						
					}
					
					break;

				}
				
				// wizard and non-wizard pages
				
				switch (tabTitle)
				{
				// non wizard pages
				case "Account":
				case "Accounts":
				case "SelectPPA":
				case "MyDataSources":
					
					// hide wizard ribbon
					
					$scope.hideWizardRibbon();
					
					break;
					
				// wizard pages
				default:
					
					// show wizard ribbon
					
					$scope.showWizardRibbon();
					
					break;
					
				}
				
				// unselect all wizard menu buttons
				
				$.each
				(
						$(".page-header-wizard-menu-button"),
						function(index, menuButton)
						{
							$(menuButton).linkbutton({selected: false, });
							
						}
				)
				;
				
				// get tab parameters
				
				var tabProperties = $scope.tabs[tabTitle];
				
				// check permissions
				
				if (tabProperties.role)
				{
					if ($rootScope.user.roles.indexOf(tabProperties.role) == -1)
					{
						$.messager.alert
						(
								getMessage("system.notAuthorized.title"),
								getMessage("system.notAuthorized.message"),
								"error"
						);
						
						return;
						
					}
					
					if (tabProperties.ppaRequired && !$rootScope.user.selectedPpaId)
					{
						$.messager.alert
						(
								getMessage("system.ppaRequired.title"),
								getMessage("system.ppaRequired.message"),
								"error",
								function()
								{
									call(null, "selectContentTab", ["SelectPPA", ]);
									
								}
						);
						
						return;
						
					}
					
				}
				
				// select tab
				
				$("#conentTabs").tabs("select", tabTitle);
				
				// store userNavigationPage
				
				window.setTimeout(function(){postData("setNavigationPage", {"navigationPage": tabTitle, });});
				
				// unselect menu button
				
				$(".Home-menu-item").linkbutton("unselect");
				$(".Home-submenu-item").removeClass("wizard-submenu-item-selected");
				
				if (tabProperties.menuItemId && tabProperties.submenuItemId)
				{
					// select menu button
					
					$("#" + tabProperties.menuItemId).linkbutton("select");
					$("#" + tabProperties.submenuItemId).addClass("wizard-submenu-item-selected");
					
				}
				else
				{
				}
				
			}
			
			$scope.selectNextWizardTab = function()
			{
				var ppaAggregationLevelNational = $scope.ppaAggregationLevel.national;
				var wizardTabs = (ppaAggregationLevelNational ? $scope.wizardTabsNational : $scope.wizardTabsSubnational);
				
				var title = $($("#conentTabs").tabs("getSelected")).panel("options")["title"];
				var index = wizardTabs.indexOf(title);
				
				if (index < wizardTabs.length - 1)
				{
					$scope.selectContentTab(wizardTabs[index + 1]);
					
				}
				
			}
			
			$scope.selectPreviousWizardTab = function()
			{
				var ppaAggregationLevelNational = $scope.ppaAggregationLevel.national;
				var wizardTabs = (ppaAggregationLevelNational ? $scope.wizardTabsNational : $scope.wizardTabsSubnational);
				
				var title = $($("#conentTabs").tabs("getSelected")).panel("options")["title"];
				var index = wizardTabs.indexOf(title);
				
				if (index > 0)
				{
					$scope.selectContentTab(wizardTabs[index - 1]);
					
				}
				
			}
			
			// logged admins
			
			$scope.checkLoggedAdmins = function()
			{
				// user is not selected account administrator
				
				if (!$rootScope.user.selectedAccountAdministrator)
				{
					if ($rootScope.user.activeAdministratorUsername)
					{
						showInformationMessage(getMessage("common.readonlyWarning.user", [$rootScope.user.activeAdministratorUsername, ]));
						
					}
					
				}
				
				// user is selected account administrator
				
				else
				{
					if ($rootScope.user.activeAdministratorUsername)
					{
						showInformationMessage(getMessage("common.readonlyWarning.admin", [$rootScope.user.activeAdministratorUsername, ]));
						
						// start waitForOtherAdminsLogout listener
						
						$scope.waitForOtherAdminsLogout();
						
					}
					
				}
				
			}
			
			/**
			 * Listen to other admin logout.
			 */
			$scope.waitForOtherAdminsLogout = function()
			{
				// NWL
				if($scope.waitForOtherAdminsLogoutHandler!=undefined)
					return;
				$scope.waitForOtherAdminsLogoutHandler =
						window.setInterval
						(
								function()
								{
									getDataAsync
									(
											"getCurrentUser",
											{},
											function(data)
											{
												$rootScope.user = data;
												
												if ($rootScope.user.selectedAccountAdministrator && !$rootScope.user.activeAdministratorUsername)
												{
													// stop listener
													
													$scope.stopWaitingForOtherAdminsLogout();
													
													// refresh open page
													
													var contentTabTitle = $($("#conentTabs").tabs("getSelected")).panel("options")["title"];
													
													call(contentTabTitle, "onOpen");
													
													// show message
													
													showInformationMessage(getMessage("common.readonlyWarning.admin.logout"));
													
												}
												
											}
									)
									;
									
								},
								10000
						)
				;
				
			}
			
			/**
			 * Stop waiting to other admin logout.
			 */
			$scope.stopWaitingForOtherAdminsLogout = function()
			{
				// stop listener
				
				window.clearInterval($scope.waitForOtherAdminsLogoutHandler);
				
				// NWL
				$scope.waitForOtherAdminsLogoutHandler=undefined;
			}
			
			// initialization code
			
			$.parser.onComplete =
				function(context)
				{
					if (context == undefined)
					{
						$scope.onOpen();
						
						document.getElementById("loader").remove();
						
					}
					
				}
			;
			
			// parse EasyUI
			
			window.onload =
				function()
				{
					$.parser.parse();
					
				}
			;
			
			// session timeout
			
			initializeSessionTimeoutHandling();
			
		}
)
;

