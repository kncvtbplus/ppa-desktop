//========================================================================================================================
// context path
//========================================================================================================================

var contextPath = $("meta[name='contextPath']").attr("content");
// root context path is undefined
if (!contextPath)
{
	contextPath = "";
	
}

function buildUrl(contextRelativeUrl)
{
	if (contextRelativeUrl.substring(0, 1) != "/")
	{
		contextRelativeUrl = "/" + contextRelativeUrl;
		
	}
	
	return contextPath + contextRelativeUrl;
	
}

// prepend context path to all jQuery AJAX requests

$.ajaxPrefilter
(
		function(options, originalOptions, jqXHR)
		{
			if (!options.crossDomain)
			{
				options.url = buildUrl(options.url);
				
			}
			
		}
)
;

// session timeout

var maxInactiveIntervalMilliseconds;
var lastRequestDateTime;
var sessionTimeout;

// processing message

var processingMessageTimer;
var processingMessageDialog;

//========================================================================================================================
// AJAX template
//========================================================================================================================

var dataUrlPrefix = "/data/";

function login(data, success)
{
	$.ajax
	(
		{
			"async": false,
			"cache": false,
			"type": "POST",
			"url": buildUrl("/login"),
			"data": data,
			"success": success,
		}
	);
	
}

function logout(showLoginForm)
{
	$.ajax
	(
		{
			"async": false,
			"cache": false,
			"type": "GET",
			"url": buildUrl("/logout"),
			"success":
				function()
				{
					window.location.href = "/home" + (showLoginForm ? "?login=true" : "");
					
				}
		}
	);
	
}

function getData(method, requestParameters)
{
	var data = null;
	
	var url = buildUrl(dataUrlPrefix + method);
	
	$.ajax
	(
		{
			"async": false,
			"cache": false,
			"type": "GET",
			"url": url,
			"data": requestParameters,
			"success":
				function(response)
				{
					data = response;
					
				},
		}
	);
	
	return data;
	
}

function getDataAsync(method, requestParameters, success)
{
	var url = buildUrl(dataUrlPrefix + method);
	
	$.ajax
	(
		{
			"async": true,
			"cache": false,
			"type": "GET",
			"url": url,
			"data": requestParameters,
			"success": success,
		}
	);
	
}

function requestJson(method, object)
{
	var data = null;
	
	var url = dataUrlPrefix + method;
	
	$.ajax
	(
		{
			"async": false,
			"cache": false,
			"type": "POST",
			"processData": false,
			"contentType": "application/json",
			"url": url,
			"data": JSON.stringify(object),
			//"accepts": "applications/json",
			"success":
				function(response)
				{
					data = response;
					
				},
		}
	);
	
	return data;
}

function postData(method, requestParameters, async, success)
{
	if (async === undefined)
	{
		async = false;
		
	}
	
	if (!async)
	{
		success = function(data){return data;};
		
	}
	
	var url = dataUrlPrefix + method;
	
	$.ajax
	(
		{
			"async": async,
			"cache": false,
			"type": "POST",
			"url": url,
			"data": requestParameters,
			"success": success,
		}
	);
	
}

//========================================================================================================================
// ajax response functions
//========================================================================================================================

//========================================================================================================================
//ajax handlers
//========================================================================================================================

$(document).ajaxStart
(
		function()
		{
			// set session timeout
			
			checkSessionTimeout();
			
			// start processing message timer
			
			processingMessageTimer =
				setTimeout
				(
						showProcessingMessage,
						1000
				)
			;
			
		}
		
);

$(document).ajaxSend
(
		function(event, jqXHR, ajaxOptions)
		{
			if (sessionTimeout)
			{
				jqXHR.abort();
				throw "Session timeout";
				
			}
			
		}
)
;

$(document).ajaxStop
(
		function()
		{
			clearTimeout(processingMessageTimer);
			
			hideProcessingMessage();
			
		}
);

$(document).ajaxError
(
		function(event, jqXHR, ajaxSettings, thrownError)
		{
			// unblock UI
			
			if ($.unblockUI)
			{
				$.unblockUI();
				
			}
			
			// abort
			
			if (jqXHR.status == 0)
			{
				return;
				
			}
			
			// format error dialog
			
			var errorTitle;
			var errorMessage;
			
			switch (jqXHR.status)
			{
			// AuthenticationFailure
			case 401:
				errorTitle = getMessage("system.notAuthenticated.title");
				errorMessage = getMessage("system.notAuthenticated.message");
				break;
				
			case 402:
				errorTitle = getMessage("system.loginFailure.title");
				errorMessage = getMessage("system.loginFailure.message");
				break;
				
			case 409:
				errorTitle = getMessage("system.loginFailureNotConfirmed.title");
				errorMessage = getMessage("system.loginFailureNotConfirmed.message");
				break;
				
			case 403:
				errorTitle = getMessage("system.notAuthorized.title");
				errorMessage = getMessage("system.notAuthorized.message", [jqXHR.responseJSON.path, ]);
				break;
				
			// default:
			// 	errorTitle = getMessage("system.default.title");
			// 	errorMessage = (jqXHR.responseJSON ? jqXHR.responseJSON.message : jqXHR.thrownError);

			// NWL: pick up the .message field, then .error (with .path), then the entire JSON to never output 'undefined'
			default:
				errorTitle = getMessage("system.default.title");
				if(jqXHR.responseJSON)
				{
					if(jqXHR.responseJSON.message)
						errorMessage=jqXHR.responseJSON.message;
					else
						if(jqXHR.responseJSON.error)
							if(jqXHR.responseJSON.path)
								errorMessage=jqXHR.responseJSON.path+":"+jqXHR.responseJSON.error;
							else
								errorMessage=jqXHR.responseJSON.error;
						else
							errorMessage=JSON.stringify(jqXHR.responseJSON, null, 2);
				}
				else
					if(jqXHR.responseText)
						errorMessage=jqXHR.responseText;
					else
						if(jqXHR.thrownError)
							errorMessage = jqXHR.thrownError;
						else
							errorMessage = "Sorry, failed to retrieve error message";
			}
			
			if ($.messager)
			{
				setTimeout
				(
						function()
						{
							$.messager.alert
							(
									errorTitle,
									errorMessage,
									"error"
							);
						},
						0
				)
				;
				
			}
			else
			{
				alert(errorMessage);
				
			}
			
		}
);

function showProcessingMessage()
{
//	processingMessageDialog =
//		$.messager.show
//		(
//				{
//					title: "Processing",
//					msg: "Working ...",
//					showType: null,
//					timeout: 0,
//				}
//		)
//	;
	
	$.blockUI();
	
}

function hideProcessingMessage()
{
//	if (processingMessageDialog)
//	{
//		processingMessageDialog.dialog("close");
//		
//		processingMessageDialog = null;
//		
//	}
//
	
	$.unblockUI();

}

//========================================================================================================================
// utility methods
//========================================================================================================================

/**
 * Executes method on element scope
 * 
 * @param elementId
 * @param method
 * @param parameters
 * @returns
 */
function call(elementId, method, parameters)
{
	var elementSelector = (elementId == null ? "html" : "#" + elementId);
	
	if ($(elementSelector).scope())
	{
		$(elementSelector).scope().$evalAsync
		(
				function($scope, locals)
				{
					if ($scope[locals.method])
					{
						$scope[locals.method].apply(null, locals.parameters);
						
					}
					
				},
				{"method": method, "parameters": parameters, }
		)
		;
		
	}
	
}

/**
 * Uploads file.
 */
function uploadFile(fileFormSelector, fileElementName, methodName, callback)
{
	if (fileFormSelector && fileElementName && methodName)
	{
		var form = $(fileFormSelector)[0];
		var fileElement = form.elements[fileElementName];
		
		if (fileElement.files.length >= 1)
		{
			var file = fileElement.files[0];
			
			if (file.size > 10000000000)
			{
				alert("File is bigger than 10GB.");
				return;
				
			}
			
			var formData = new FormData(form);
			
			$.ajax
			(
					{
						"processData": false,
						"contentType": false,
						"type": "POST",
						"url": dataUrlPrefix + methodName,
						"data": formData,
						"success":
							function(response)
							{
								// display errors
								
								if (response.length >= 1)
								{
									$.messager.alert("Warning", response.replace("\n", "<br />"));

								}
								else
								{
									// show confirmation
									
									showConfirmationMessage(getMessage("common.dialog.fileLoadConfirmation.text"));
									
									// call callback method
									
									if (callback)
									{
										callback();
										
									}
									
								}

							},
					}
			);
			
		}
		
	}
	
}

/**
 * Converts list of maps to map of maps with given key.
 * @returns
 */
function map(array, keyName, valueName)
{
	var map =
		array.reduce
		(
				function(map, row)
				{
					map[row[keyName]] = row[valueName];
					
					return map;
					
				},
				{}
		)
	;
	
	return map;
	
}

/**
 * Extracts list of field values from object list.
 * @returns
 */
function fieldValueList(objectList, key)
{
	var fieldValueList =
			$.map
			(
					objectList,
					function(object)
					{
						return object[key];
						
					}
			)
	;
	
	return fieldValueList;
	
}

/**
 * Enables button if there are checked rows in datagrid. Disables otherwise.
 * 
 * @param datagridSelector
 * @param deleteCheckedButtonSelector
 * @returns
 */
function updateCheckDependentButtonState(datagridSelector, buttonSelector)
{
	$(buttonSelector).linkbutton($(datagridSelector).datagrid("getChecked").length == 0 ? "disable" : "enable");
	
}

/**
 * Loads messages from back-end and retrieve them in front-end.
 * 
 */
var messages = {};
function loadMessages()
{
	messages = getData("getMessages");
	
}
function getMessage(code, parameters)
{
	// cash all messages
	
	var message;
	
	// simple message
	if (parameters === undefined)
	{
		// extract message from cache
		if (code in messages)
		{
			message = messages[code];
			
		}
		// get message and save it in cache
		else
		{
			var messageResponse = getData("getMessage", {"code": code, });
			message = messageResponse.message;
			
			messages[code] = message;
			
		}
		
	}
	// parameterized message
	else
	{
		var messageResponse = getData("getMessage", {"code": code, "parameters": parameters, });
		message = messageResponse.message;
		
	}
	
	return message;
	
}

/* confirmations */

function showConfirmationMessage(title, message)
{
	if (!message)
	{
		message = title;
		title = getMessage("common.dialog.confirmation.title");
		
	}
	
	window.setTimeout
	(
			function()
			{
				$.messager.show
				(
						{
							title: title,
							msg: message,
						}
				)
				;
				
			},
			100
	);
	
}

function showDataSavedConfirmationMessage()
{
	showConfirmationMessage(getMessage("common.dialog.message.dataSaved"));
	
}

function showErrorMessage(message)
{
	$.messager.alert
	(
			getMessage("common.alert.error.title"),
			message,
			"error"
	)
	;
	
}

function showWarningMessage(message)
{
	$.messager.alert
	(
			getMessage("common.alert.warning.title"),
			message,
			"warning"
	)
	;
	
}

function showInformationMessage(message)
{
	$.messager.alert
	(
			getMessage("common.alert.information.title"),
			message,
			"info"
	)
	;
	
}

function showValidationErrorMessage()
{
	showErrorMessage(getMessage("common.validationError.text"));
	
}

/**
Returns object type options for relation type.
*/
function getRelatedObjectTypes(relatingObjectTypeId, relationTypeId)
{
	var objectTypes = [];
	
	$.ajax
	(
		{
			async: false,
			dataType: "json",
			type: "GET",
			url: "/get_related_object_types",
			data: {object_type_id: relatingObjectTypeId, relation_type_id: relationTypeId},
			success:
				function(data)
				{
					objectTypes = data;
				}
		}
	);
	
	return objectTypes;
}

/**
Returns object types related to given object type via relation type.
*/
function getRelatedObjectTypes(relatingObjectTypeId, relationTypeId)
{
	var objectTypes = [];
	
	$.ajax
	(
		{
			async: false,
			dataType: "json",
			type: "GET",
			url: "/get_related_object_types",
			data: {object_type_id: relatingObjectTypeId, relation_type_id: relationTypeId},
			success:
				function(data)
				{
					objectTypes = data;
				}
		}
	);
	
	return objectTypes;
}

/* ========================================================================================================================
Helper functions
======================================================================================================================== */

/**
Builds options HTML from data array.
*/
function buildOptionsHtml(data, emptyOption, selectedId, emptyOptionValue)
{
	var optionsHtml = "";
	
	if (emptyOption)
	{
		optionsHtml += "<option value='" + (emptyOptionValue ? emptyOptionValue : "") + "'>" + (emptyOption === true ? "" : emptyOption) + "</option>";
	}
	
	data.forEach
	(
		function(item)
		{
			optionsHtml += "<option value='" + item.id + "'" + (selectedId && item.id == selectedId ? " selected" : "") + ">" + item.name + "</option>";
		}
	);
	
	return optionsHtml;
}

/**
Builds group options HTML from data array.
*/
function buildGroupOptionsHtml(data, merge, emptyOption, emptyOptionValue)
{
	var optionsHtml = "";
	
	if (emptyOption)
	{
		optionsHtml += "<option" + (emptyOptionValue ? " value='" + emptyOptionValue + "'" : "") + "></option>";
	}
	
	data.forEach
	(
		function(group)
		{
			optionsHtml += "<optgroup label='" + group.name + "'>";
			
			if (group.items)
			{
				group.items.forEach
				(
					function(item)
					{
						var optionValue = (merge ? group.id + "_" + item.id : item.id);
						var optionLabel = (merge ? group.name + ": " + item.name : item.name);
						optionsHtml += "<option value='" + optionValue + "'>" + optionLabel + "</option>";
					}
				);
			}
			
			optionsHtml += "</optgroup>";
		}
	);
	
	return optionsHtml;
}

/**
Builds group options.
*/
function buildGroupOptions(groups, merge, emptyOption)
{
	var optionsHtml = "";
	
	if (emptyOption)
	{
		optionsHtml += "<option></option>";
	}
	
	data.forEach
	(
		function(group)
		{
			optionsHtml += "<optgroup label='" + group.name + "'>";
			
			if (group.items)
			{
				group.items.forEach
				(
					function(item)
					{
						var optionValue = (merge ? group.id + "_" + item.id : item.id);
						var optionLabel = (merge ? group.name + ": " + item.name : item.name);
						optionsHtml += "<option value='" + optionValue + "'>" + optionLabel + "</option>";
					}
				);
			}
			
			optionsHtml += "</optgroup>";
		}
	);
	
	return optionsHtml;
}

/**
Builds checkbox rows.
*/
function buildCheckboxRows(data, name, checkedItems, className)
{
	var checkboxRows = "";
	
	var checkedItemIds = new Array();
	
	if (checkedItems)
	{
		checkedItems.forEach
		(
			function(checkedItem)
			{
				checkedItemIds.push(checkedItem.id);
			}
		);
	}
	
	data.forEach
	(
		function(item)
		{
			checkboxRows +=
				"<tr>" +
				"<td class='centered'>" +
				"<input type='checkbox'" + (className ? " class='" + className + "'" : "") + " name='" + name + "' value='" + item.id + "' " + (checkedItemIds.indexOf(item.id) != -1 ? "checked" : "") + " />" +
				"</td>" +
				"<td>" + item.name + "</td>" +
				"</tr>";
		}
	);
	
	return checkboxRows;
}

/**
Builds radiobox rows.
*/
function buildRadioboxRows(data, name, checkedItemIds, emptyOptionValue)
{
	var radioboxRows = "";
	
	if (emptyOptionValue)
	{
		data.unshift({"id": "", "name": emptyOptionValue});
	}
	
	data.forEach
	(
		function(item)
		{
			radioboxRows +=
				"<tr>" +
				"<td><input type='radio' name='" + name + "' value='" + item.id + "' " + (checkedItemIds.indexOf(item.id) != -1 ? "checked" : "") + " /></td>" +
				"<td style='width: 100%;'>" + item.name + "</td>" +
				"</tr>";
		}
	);
	
	return radioboxRows;
}

/**
Builds hierarchical name for container controls.
*/
function buildHierarchicalControlName(container, name, multiSelect)
{
	var hierarchicalControlName = "query";
	$(container).parents("TR.relationRow").reverse().forEach
	(
		function(value, index, array)
		{
			hierarchicalControlName += "[relations][" + $(value).find("INPUT[type='hidden'][name='relationRowId']")[0].value + "]";
		}
	);
	hierarchicalControlName += "[" + name + "]";

	if (multiSelect)
	{
		hierarchicalControlName += "[]";
	}

	return hierarchicalControlName;
}

function getImageData(chartContainer)
{
	var chartArea = chartContainer.getElementsByTagName('svg')[0].parentNode;
	var svg = chartArea.innerHTML;
	var doc = chartContainer.ownerDocument;
	var canvas = doc.createElement('canvas');
	canvas.setAttribute('width', chartArea.offsetWidth);
	canvas.setAttribute('height', chartArea.offsetHeight);

	canvas.setAttribute(
		'style',
		'position: absolute; ' +
		'top: ' + (-chartArea.offsetHeight * 2) + 'px;' +
		'left: ' + (-chartArea.offsetWidth * 2) + 'px;');
	doc.body.appendChild(canvas);
	canvg(canvas, svg);
	var imageData = canvas.toDataURL("image/png");
	canvas.parentNode.removeChild(canvas);
	
	return imageData;
}

function buildImageOptions(data, emptyOption, selectedId, value)
{
	var options = "";
	
	if (emptyOption)
	{
		options += "<option value='" + (value ? value : "") + "'></option>";
	}
	
	data.forEach
	(
		function(item)
		{
			options += "<option value='" + (value ? value : item.url) + "' data-imagesrc='" + item.url + "'" + (selectedId && item.id == selectedId ? " selected" : "") + "></option>";
		}
	);
	
	return options;
}

function buildObjectRelationHierarchyList(objects)
{
	var objectRelationHierarchyList = "";
	
	// begin list
	
	objectRelationHierarchyList += "<ul>";
	
	// add items
	
	objects.forEach
	(
		function(object)
		{
			// begin item
				
			objectRelationHierarchyList += "<li>";
			
			// begin label
			
			objectRelationHierarchyList += "<a>";
			
			// relation type name
			
			if (object.relation_type_name != null)
			{
				objectRelationHierarchyList += "<span style='font-style: italic;'>" + object.relation_type_name + "</span>: ";
			}
			
			// name
			
			objectRelationHierarchyList += "<span style='font-weight: bold;" + (object.loop ? " color: darkgray;" : "") + "'>" + object.name + "</span>";

			// end label
			
			objectRelationHierarchyList += "</a>";
			
			// children
			
			if (object.children != null && object.children.length >= 1)
			{
				objectRelationHierarchyList += buildObjectRelationHierarchyList(object.children);
			}
			
			// end node

			objectRelationHierarchyList += "</li>";
		}
	);

	// end list
	
	objectRelationHierarchyList += "</ul>";
	
	return objectRelationHierarchyList;
}
		
function initializePopup(selector, title, sizeOptions)
{
	if (!$(selector).hasClass('ui-dialog-content'))
	{
		$(selector).dialog
		(
				{
					"dialogClass": "popup",
					"autoOpen": false,
					"resizable": false,
					"modal": true,
					"width": (sizeOptions && sizeOptions.width ? sizeOptions.width : $(window).width() - 2),
					"height": (sizeOptions && sizeOptions.height ? sizeOptions.height : $(window).height() - 2),
					"closeOnEscape": true,
					"title": title
				}
		)
		;
		
	}
	
}

function popup(selector, title, sizeOptions)
{
	if (!$(selector).hasClass('ui-dialog-content'))
	{
		$(selector).dialog
		(
				{
					"dialogClass": "popup",
					"autoOpen": false,
					"resizable": false,
					"modal": true,
					"width": (sizeOptions && sizeOptions.width ? sizeOptions.width : $(window).width() - 2),
					"height": (sizeOptions && sizeOptions.height ? sizeOptions.height : $(window).height() - 2),
					"closeOnEscape": true,
					"title": title
				}
		)
		;
		
	}
	
	$(selector).dialog("open");
	
}

function toObject(selector, skipEmpty)
{
	return $(selector).toObject({"skipEmpty": (skipEmpty ? true : false)});
}

function records(object)
{
	return jQuery.extend({"records": {}}, object);
}

function inputValue(value)
{
	return (value == null ? "" : value);
}

function initializeTree(selector, plugins, options, open)
{
	var treePlugins = $.merge([], plugins);

	var treeOptions =
		$.extend
		(
				true,
				{
					"core" :
					{
						"animation": 0,
						"check_callback": true
					}
				},
				options,
				{
					"plugins": treePlugins
				}
		);

	$(selector).jstree(treeOptions);

	if (open)
	{
		$(selector).on
		(
				"refresh.jstree",
				function (event, data)
				{
		        	$(this).jstree("open_all");
		        	
				}
		);
	}
	
}

function refreshTree(selector, data)
{
	$(selector).jstree().settings.core.data = data;
	$(selector).jstree().refresh();

}

function tree(selector, data, open, pluginOptions)
{
	var treeOptions =
		{
			"core" :
			{
				"animation": 0,
				"check_callback": true,
				"data": (data ? data : "<ul></ul>")
			},
			"plugins": []
		};
	
	if (pluginOptions)
	{
		$.extend(treeOptions, pluginOptions);
		
		$.each
		(
				pluginOptions,
				function(pluginName, pluginObject)
				{
					treeOptions.plugins.push(pluginName);
				}
		);
		
	}
	
	var tree = $(selector).jstree(treeOptions);
	
	if (open)
	{
		tree.bind
		(
				"ready.jstree",
				function (event, data)
				{
		        	$(this).jstree("open_all");
				}
		);
	}
	
}

// shows and hides selector specified element 
function show(selector)
{
	$(selector).show();

	adjustHeight(selector);
	
}
function hide(selector)
{
	$(selector).hide();

}

// block ui synchronously

function executeWithBlockedUI(code)
{
	$.blockUI();
	
	setTimeout
	(
			function()
			{
				code();
				$.unblockUI();
				
			},
			200
	);
	
}

/**
 * Returns easyui tree leaf checked nodes.
 */
function getCheckedEasyuiTreeValues(selector, leavesOnly, key)
{
	var checkedValues =
		$.map
		(
				$(selector).tree("getChecked"),
				function(node)
				{
					// skip not leaves if specified
					if (leavesOnly && ("children" in node))
					{
						return [];
						
					}
					else
					{
						// return key value if exists
						if (key in node)
						{
							return node[key];
							
						}
						else
						{
							return [];
							
						}
						
					}
					
				}
		);
	
	return checkedValues;
	
}

/**
 * EasyUI tree uncheck all.
 */
function easyuiTreeUncheckAll(selector)
{
	$.each
	(
			$(selector).tree("getChecked"),
			function(index, node)
			{
				$(selector).tree("uncheck", node.target);
				
			}
	)
	;
	
}

/**
 * Returns datagrid checked row ids.
 */
function getCheckedDatagridValues(selector, key)
{
	var checkedValues =
		$.map
		(
				$(selector).datagrid("getChecked"),
				function(row)
				{
					// return value if key exists
					
					if (key in row)
					{
						return row[key];
						
					}
					else
					{
						return [];
						
					}
					
				}
		);
	
	return checkedValues;
	
}

function extractErrorMessage(responseText)
{
	var pattern = /<h1>(.*?)<\/h1>.*?<b>message<\/b>.*?<u>(.*?)<\/u>.*?<b>description<\/b>.*?<u>(.*?)<\/u>/;
	
	var matches = pattern.exec(responseText);

	var errorMessage = (matches ? matches[1] + "<br />" + matches[2] + "<br />" + matches[3] + "<br />" : responseText);
	
	return errorMessage;

}

function isMobile()
{
    var mobile =
    	navigator.userAgent.match(/Android/i)
    	||
    	navigator.userAgent.match(/BlackBerry/i)
    	||
    	navigator.userAgent.match(/iPhone|iPad|iPod/i)
    	||
    	navigator.userAgent.match(/Opera Mini/i)
    	||
    	navigator.userAgent.match(/IEMobile/i)
    	;
    
    return mobile;
    
}

// resize, center and open dialog

function openDialog(dialogSelector)
{
	$(dialogSelector).dialog("open");
	$(dialogSelector).dialog("resize", {"width": window.innerWidth * 0.9, "height": window.innerHeight * 0.9, });
	$(dialogSelector).dialog("center");
	
	// set escape key to close dialog
	
	$("body").on
	(
			"keydown",
			function(event)
			{
				if (event.keyCode == 27)
				{
					$(dialogSelector).dialog("close");
					
				}
				
			}
	)
	;

}

// classification path column formatter

function classificationItemPathColumnFormatter(value, row, index)
{
	var output;
	
	output = "<div style='text-align: left; '>";
	
	$.each
	(
			value,
			function(index, pathElement)
			{
				// process everything except group level
				if (index >= 1)
				{
					output += "<div style='padding-bottom: 4px; padding-left: " + ((index - 1) * 8) + "px; ' >" + pathElement + "</div>";
					
				}
				
			}
	);
	
	output += "</div>";
		
	return output;
		
}

// classification path column styler

function classificationPathColumnStyler(value, row, index)
{
	return "font-weight: bold; ";

}

// under construction message

function underConstructionMessage()
{
	$.messager.alert
	(
			getMessage("UnderConstruction.title"),
			getMessage("UnderConstruction.text"),
			"info"
	);

}

// datagrid helper functions

function datagridDeleteCheckedRows(datagridSelector)
{
	// delete checked rows one by one
	
	while ($(datagridSelector).datagrid("getChecked").length >= 1)
	{
		var firstCheckedRow = $(datagridSelector).datagrid("getChecked")[0];
		var firstCheckedRowIndex = $(datagridSelector).datagrid("getRowIndex", firstCheckedRow);
		
		// end edit - otherwise it gives an error
		
		$(datagridSelector).datagrid("endEdit", firstCheckedRowIndex);
		$(datagridSelector).datagrid("deleteRow", firstCheckedRowIndex);
	
	}

}

function setButtonStates(state, buttonSelectors)
{
	$.each
	(
			buttonSelectors,
			function(index, buttonSelector)
			{
				$(buttonSelector).linkbutton(state);
				
			}
	)
	;
	
}

/**
 * EasyUI uses empty string for combo... value when no option is selected.
 * This function replaces empty string with undefined.
 * 
 */
function convertEasyUIComboValue(easyuiComboValue)
{
	return (easyuiComboValue == "" ? undefined : easyuiComboValue);
	
}

/**
 * Help dialog.
 * Populate dialog title and text and open it.
 * @returns
 */
function openHelpDialog(title, text)
{
	$("#helpDialog").dialog("setTitle", title);
	$("#helpDialog-text").html(text);
	
	openDialog("#helpDialog");
	
}

function formatClassificationItemPath(classificationItemPath, startIndex)
{
	var output = "";
	
	for (i = startIndex; i < classificationItemPath.length; i++)
	{
		output +=
			"<div style='padding-bottom: 4px; padding-left: " + ((i - startIndex) * 8) + "px; ' >"
			+ classificationItemPath[i]
			+ "</div>"
		;
		
	}
	
	return output;
		
}

function formatCheckboxImage(value)
{
	// convert "false" string to false
	
	var output;
	
	output =
		(
				value
				?
						"<img src='lib/jquery-easyui/themes/icons/checkbox-checked.png' style='vertical-align: middle; min-height:16px; min-width: 16px; ' />"
						:
							"<img src='lib/jquery-easyui/themes/icons/checkbox-unchecked.png' style='vertical-align: middle; min-height:16px; min-width: 16px; ' />"
		)
	;
	
	return output;
	
}

/**
 * Stores onChange handler if any and disables it before reload. Then enables it back.
 * 
 * @returns
 */
function reloadComboboxWithoutTriggeringChange(selector)
{
}

// session timeout

function initializeSessionTimeoutHandling()
{
	getDataAsync
	(
			"getMaxInactiveInterval",
			{},
			function(response)
			{
				maxInactiveIntervalMilliseconds = (response.maxInactiveInterval - 60) * 1000;
				lastRequestDateTime = new Date();
				
			}
	)
	;
	
}

function checkSessionTimeout()
{
	if (maxInactiveIntervalMilliseconds)
	{
		if (new Date().getTime() < lastRequestDateTime.getTime() + maxInactiveIntervalMilliseconds)
		{
			lastRequestDateTime = new Date();
			
		}
		else
		{
			sessionTimeout = true;
			
			$.messager.alert
			(
					getMessage("system.sessionTimeoutMessage.title"),
					getMessage("system.sessionTimeoutMessage.message"),
					"info",
					function()
					{
						window.location.href = "/home?login=true";
						
					}
			)
			;
			
		}
		
	}
	
}

function textboxContainsText(textboxSelectors)
{
	var containsText = false;
	
	textboxSelectors.forEach
	(
			function(textboxSelector)
			{
				var value;
				
				var focused = $(textboxSelector).textbox("textbox").parent().hasClass("textbox-focused");
				
				if (focused)
				{
					value = $(textboxSelector).textbox("textbox").val();
					
				}
				else
				{
					value = $(textboxSelector).textbox("getValue");
					
				}
				
				if (value)
				{
					containsText = true;
					
					return false;
					
				}
				
			}
	)
	;
	
	return containsText;
	
}

function makeDroppable(element, methodName, callback) {

	var input = document.createElement('input');
	input.setAttribute('type', 'file');
	input.style.display = 'none';

	input.addEventListener('change', triggerCallback);
	element.appendChild(input);

	element.addEventListener('dragover', function(e) {
		e.preventDefault();
		e.stopPropagation();
		element.classList.add('dragover');
	});

	element.addEventListener('dragleave', function(e) {
		e.preventDefault();
		e.stopPropagation();
		element.classList.remove('dragover');
	});

	element.addEventListener('drop', function(e) {
		e.preventDefault();
		e.stopPropagation();
		element.classList.remove('dragover');
		triggerCallback(e);
	});

	element.addEventListener('click', function() {
		input.value = null;
		input.click();
	});

	function triggerCallback(e) {
		var files;
		if(e.dataTransfer) {
			files = e.dataTransfer.files;
		} else if(e.target) {
			files = e.target.files;
		}
		
		if (files.length >= 1)
		{
			var file = files[0]
			
			// upload file with ajax
			
			var formData = new FormData();
			formData.append("file", file);

			$.ajax({
				url: dataUrlPrefix + methodName,
				method: 'post',
				data: formData,
				processData: false,
				contentType: false,
				success:
					function(response)
					{
						// display errors
						
						if (response.length >= 1)
						{
							$.messager.alert("Warning", response.replace("\n", "<br />"));
			
						}
						else
						{
							// show confirmation
							
							showConfirmationMessage(getMessage("common.dialog.fileLoadConfirmation.text"));
							
							// call callback method
							
							if (callback)
							{
								callback();
								
							}
							
						}
			
					},
			});
			
		}
		else
		{
			console.error("No files provided");
			
		}
		
	}
	
}

