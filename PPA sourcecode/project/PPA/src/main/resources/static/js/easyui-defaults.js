// datagrid no border

$.fn.datagrid.defaults.border = false;

// datagrid decouple select and check

$.fn.datagrid.defaults.checkOnSelect = false;
$.fn.datagrid.defaults.selectOnCheck = false;

// datagrid do not select already selected row

$.fn.datagrid.defaults.onBeforeSelect =
	function(index, row)
	{
		var selectedRow = $(this).datagrid("getSelected");
		
		if (selectedRow && row == selectedRow)
		{
			return false;
			
		}
		else
		{
			return true;
			
		}
		
	}
;

// datagrid checkbox editor

$.extend
(
		$.fn.datagrid.defaults.editors,
		{
			workingcheckbox:
			{
				init:
					function(container, options)
					{
						var input = $("<input type='checkbox' style='vertical-align: middle; margin: 0; border: none; '>").appendTo(container);
						
						if (options.onClick)
						{
							input.bind("click", options.onClick);
							
						}
						
						return input;
						
					},
				getValue:
					function(target)
					{
						return $(target).prop('checked');
					},
				setValue:
					function(target, value)
					{
						$(target).prop('checked', value);
					},
			},
		}
)
;

// datagrid default pageSize

$.fn.datagrid.defaults.pageSize = 100;

//extend the 'equals' rule for validatebox

$.extend
(
		$.fn.validatebox.defaults.rules,
		{
			equals:
			{
				validator:
					function(value, parameters)
					{
						console.log("equals");
						return value == $(parameters[0]).val();
						
					},
				message: "Value does not match.",
			}
		}
)
;

// datebox date conversion

$.fn.datebox.defaults.formatter =
	function(date)
	{
		var y = date.getUTCFullYear();
		var m = date.getUTCMonth()+1;
		var d = date.getUTCDate();
		
		return y.toString() + '-' + (m < 10 ? "0" : "") + m.toString() + '-' + (d < 10 ? "0" : "") + d.toString();
		
	}
;

$.fn.datebox.defaults.parser =
	function(s)
	{
		var date;
		
		if (s)
		{
			var st = s.split(/\D/);
			
			date = new Date(Number(st[0]), Number(st[1])-1, Number(st[2]));
			
		}
		else
		{
			date = new Date();
			
		}
		
		return date;
		
	}
;

// combobox enable edit but limit to existing values

$.fn.combobox.defaults.editable = true;
$.fn.combobox.defaults.reversed = true;

// dropdown panel auto size

$.map
(
		['combo','combobox','combogrid','combotree','datebox','datetimebox'],
		function(plugin)
		{
//			$.fn[plugin].defaults.width = "100%";
//			$.fn[plugin].defaults.panelWidth = "auto";
			$.fn[plugin].defaults.panelHeight = "auto";
			$.fn[plugin].defaults.panelMinHeight = 30;
			$.fn[plugin].defaults.panelMaxHeight = 400;
			
		}
)
;

/**
Reloads combobox data and clears it if selection doesn't exist anymore.
*/
$.fn.combobox.defaults.onLoadSuccess =
	function()
	{
		// only for reversed comboboxes
	
		if (!this.reversed)
			return;
		
		var value = $(this).combobox("getValue");
		
		// skip emtpy value
		
		if (value == "")
			return;
		
		var valueField = $(this).combobox("options")["valueField"];
		var data = $(this).combobox("getData");
		
		var exists = false;
		$.each
		(
				data,
				function(dataRowIndex, dataRow)
				{
					if (dataRow[valueField] == value)
					{
						exists = true;
						return false;
						
					}
					
				}
		)
		;
		
		if (!exists)
		{
			// clear combobox
			
			$(this).combobox("clear");
			
		}
		
	}
;

// switch button default texts

$.fn.switchbutton.defaults.onText = "Yes";
$.fn.switchbutton.defaults.offText = "No";

// passwordbox

$.fn.passwordbox.defaults.checkInterval = 0;
$.fn.passwordbox.defaults.lastDelay = 0;

// menubutton show menu on click

$.fn.menubutton.defaults.onClick =
	function()
	{
		$($(this).menubutton("options")["menu"]).menu("show");
		
	}
;

// input style

$.fn.textbox.defaults.height = 35;
$.fn.passwordbox.defaults.height = 35;
$.fn.numberbox.defaults.height = 35;
$.fn.filebox.defaults.height = 35;
$.fn.combobox.defaults.height = 35;

// checkbox

$.fn.checkbox.defaults.width = 16;
$.fn.checkbox.defaults.height = 16;

// radiobutton

$.fn.radiobutton.defaults.width = 26;
$.fn.radiobutton.defaults.height = 26;

// datagrid rowStyler

$.fn.datagrid.defaults.rowStyler =
	function(index,row)
	{
		return "background-color: " + (index % 2 == 0 ? "white" : "#EDEDED") + ";";
		
	}
;

// Open combo dropdown when clicking the text input area

$(document).on('click', '.combo .textbox-text', function(e) {
	$(this).siblings('.textbox-addon').find('.combo-arrow').trigger('click');
});

// datagrid fitContent

$.fn.datagrid.defaults.fitColumns = true;

// datagrid processing message

$.fn.datagrid.defaults.loadMsg = "";

//textbox setText reset selectionStart after setting value

//var originalSetText = $.fn.textbox.methods.setText;
//$.fn.textbox.methods.setText =
//	function(textbox, text)
//	{
//		originalSetText.apply(this,arguments);
//		
//		$(textbox).textbox("textbox")[0].setSelectionRange(0, 0);
//		
//	}
//;
//
