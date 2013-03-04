 // FWS Layout Generator
// Copyright 2009 FrameWork Sites


var templateWidth = 579;
var bgcolorlist=new Array("#DFDFFF", "#FFFFBF", "#80FF80",  "#C9FFA8", "#F7F7F7","#DDDD00");

function updateBackgrounds(templateId) {
   var colorCount = 0;
   var node_list = document.getElementsByTagName('input');
   for (var i = 0; i < node_list.length; i++) {
      var node = node_list[i];
      if (node.getAttribute('class') == 'data_'+templateId && node.getAttribute('name') == 'width' && typeof node.parentNode != "undefined") {
         node.parentNode.style.backgroundColor = bgcolorlist[colorCount];
         colorCount++;
         if (colorCount > bgcolorlist.length-1) { colorCount = 0 }
      } 
   }
}


function updateAuto(templateId) {
   var colorCount = 0;
   var node_list = document.getElementsByTagName('input');
   var widthNode;
   var autoCount = 0;
   var rowCount = 0;
   var staticWidth = 0;
   
   for (var i = 0; i < node_list.length; i++) {
      var node = node_list[i];
      if (node.getAttribute('class') == 'data_'+templateId && node.getAttribute('name') == 'width' ) {
         widthNode = node;
      } 
      if (node.getAttribute('class') == 'data_'+templateId && node.getAttribute('name') == 'auto' ) {
         if (node.checked) { widthNode.disabled = true; autoCount++; }
         else { widthNode.disabled = false; staticWidth += parseFloat('0'+widthNode.value); }
      }
      if (node.getAttribute('class') == 'endDiv_'+templateId) {
         var rowCountx = 0;
         var autoWidth = (document.getElementById('templateWidth_'+templateId).value - staticWidth) / autoCount;
         autoWidth = Math.round(autoWidth*10)/10 
         if (autoWidth < 0) { autoWidth = 0 }
         for (var x = 0; x < node_list.length; x++) {
            var nodex = node_list[x]; 
            if (rowCountx == rowCount) {
               if (nodex.getAttribute('class') == 'data_'+templateId && nodex.getAttribute('name') == 'width' ) {
                  if (nodex.disabled) {
                     nodex.value=autoWidth;
                  }
               }
            }
            if (nodex.getAttribute('class') == 'endDiv_'+templateId) {
               rowCountx++;
            }
         }
         rowCount++;
         staticWidth = 0;
         autoCount = 0;
      }
   }
}


function showTemplate(templateId,imagePath) {

   var contentHTML = '';
   var contentCSS = '';
   var contentHTMLWithStyle = '';


   var radio_list = document.getElementsByTagName('input');

   var widthType = 'px';

   for (var i = 0; i < radio_list.length; i++) {
      var node = radio_list[i];
  
      if (node.getAttribute('name') == 'type' && node.checked == true) {
         widthType = node.value;
      }
   }


   var rowCount = 1;
   var columnCount = 1;
   var width = 0;
   var widthTotal = 0;
   var name = '';
   var rowHTML = '';
   var rowWidth = 0;
   var rowHTMLWithStyle = '';
   var widthMax = 0;
   var colorCount = 0;

   var previewShrink = (document.getElementById('templateWidth_'+templateId).value / (templateWidth/2));


   var classPrefix = document.getElementById('classPrefix_'+templateId).value;

   var node_list = document.getElementsByTagName('input');
   for (var i = 0; i < node_list.length; i++) {
      var node = node_list[i];
  
      if (node.getAttribute('class') == 'endData_'+templateId) {





         var className = classPrefix+'_'+rowCount+'_'+columnCount;
         rowHTML += '\t\t\t\t<div id="'+className+'_wrapper">\n\t\t\t\t\t<div id="'+className+'">\n';
         if (name == '') { name = 'row_'+rowCount+'_col_'+columnCount; }
         rowHTML += '\t\t\t\t\t\t#FWSShow-'+name+'#\n';

         rowHTML += '\t\t\t\t\t</div>\n\t\t\t\t</div>\n';
         var style = '\tfloat:left;\n\twidth:'+width+widthType+';\n';
         contentCSS += '#'+className+'_wrapper {\n'+style+'\t}\n';  
         var previewRowWidth = (width/previewShrink);
         rowHTMLWithStyle += '<div style="font-size:8px;float:left;width:'+previewRowWidth+'px;height:20px;background-color:'+bgcolorlist[colorCount]+';text-align:center;">';
         rowHTMLWithStyle += name;
         rowHTMLWithStyle += '</div>';
         widthTotal = parseFloat(widthTotal)+parseFloat(width);
         if (widthTotal > widthMax) { widthMax = widthTotal }
         widthTotal = Math.round(widthTotal); 
         name = '';
         className = '';
         width = '';
         columnCount++;
         colorCount++;
         if (colorCount > bgcolorlist.length-1) { colorCount = 0 }
         }
      if (node.getAttribute('class') == 'data_'+templateId && node.getAttribute('name') == 'width' ) {
         width = node.value;
      } 
      if (node.getAttribute('class') == 'data_'+templateId && node.getAttribute('name') == 'name' ) {
         name = node.value;
      }



      if (node.getAttribute('class') == 'endDiv_'+templateId) {
         contentHTML += '\t\t<div id="'+classPrefix+'_'+rowCount+'_wrapper">\n\t\t\t<div id="'+classPrefix+'_'+rowCount+'">\n'+rowHTML+'\t\t\t</div>\n\t\t</div>\n';
         var style = '\toverflow:hidden;\n';

         contentCSS += '#'+classPrefix+'_'+rowCount+'_wrapper {\n'+style+'\t}\n';
         var previewColWidth = (widthTotal/previewShrink)+10;
      
      
         contentHTMLWithStyle += '<div style="width:'+(previewColWidth)+'px;" id="'+classPrefix+'_row_'+rowCount+'">'+rowHTMLWithStyle+'\t</div>';
         rowHTML = '';
         rowHTMLWithStyle = '';
         rowCount++;
         widthTotal = 0;
         columnCount = 1;
      }
   }
   widthMax = Math.round(widthMax*10)/10; 
   var style = 'width: '+widthMax+widthType+';\n';

   contentCSS = '#'+classPrefix+'_wrapper {\n\t'+style+'\t}\n'+contentCSS+'.clear { clear:both; }\n';
   contentHTML = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">\n<head>\n#FWSHead#</head>\n<body>\n#FWSMenu#\n<div id="'+classPrefix+'_wrapper">\n\t<div id="'+classPrefix+'">\n'+contentHTML+'\t</div>\n</div>\n<div class="clear"></div>\n#FWSJavaLoad#\n</body>\n</html>\n';

	eval('css_'+templateId+'.getSession().setValue(contentCSS)');
	eval('template_'+templateId+'.getSession().setValue(contentHTML)');

   contentHTMLWithStyle = '<div style="clear:both;width:310px;margin:auto;">'+contentHTMLWithStyle+'</div>';
   document.getElementById('checkPlace_'+templateId).innerHTML=contentHTMLWithStyle;
   }



function formatRow(cellName,imagePath) {

      for (var i = 0; i < cellName.childNodes.length-2; i++) {
         var node = cellName.childNodes[i];
         if (i > 0) { 
           node.setAttribute('style','height:80px;background-image:url(\''+imagePath+'/layoutBox.gif\');background-repeat:no-repeat;background-position:top center;position:relative;text-align: center; float: left; width: '+((templateWidth / (cellName.childNodes.length-3)))+'px;');
        }
      }
    }

function deleteCell(cellName,imagePath,templateId) {

   if (cellName.parentNode.childNodes.length > 4) {
      var rowNode = cellName.parentNode;
      cellName.parentNode.removeChild(cellName);
      formatRow(rowNode,imagePath);
      }
   else {
      cellName.parentNode.parentNode.removeChild(cellName.parentNode);
      }
   updateAll(templateId,imagePath);
   }

function addRow(cellName,location,columnName,imagePath,templateId) {



   var newNode = document.createElement('div');
   newNode.setAttribute('style','clear:both;');

   var beforeNode = document.createElement('div');
   beforeNode.setAttribute('style','float:left;');
   var beforeButton = document.createElement('img');
   beforeButton.setAttribute('src',imagePath+'/layoutLeft.gif');
   beforeButton.setAttribute('style','height:80px;width:13px;');
   beforeButton.setAttribute('onclick','addCell(this.parentNode,\'before\',\'\',true,\''+imagePath+'\',\''+templateId+'\')');
   beforeNode.appendChild(beforeButton);
 
   var afterNode = document.createElement('div');
   afterNode.setAttribute('style','float:left;clear:right;');

   var afterButton = document.createElement('img');
   afterButton.setAttribute('src',imagePath+'/layoutRight.gif');
   afterButton.setAttribute('style','height:80px;width:13px;');
   afterButton.setAttribute('onclick','addCell(this.parentNode,\'after\',\'\',true,\''+imagePath+'\',\''+templateId+'\')');
   afterNode.appendChild(afterButton);
   var afterEndDiv = document.createElement('input');
   afterEndDiv.setAttribute('class','endDiv_'+templateId);
   afterEndDiv.setAttribute('type','hidden');


   newNode.appendChild(beforeNode);
   newNode.appendChild(addCell(cellName,'none',columnName,false,imagePath,templateId));
   newNode.appendChild(afterNode);
   newNode.appendChild(afterEndDiv);

   if (location == 'after') {
      cellName.parentNode.insertBefore(newNode,cellName); 
      }
   if (location == 'before') {
      cellName.parentNode.insertBefore(newNode,cellName.nextSibling); 
      }
   if (location == 'none') {
      return(newNode); 
      }
   updateAll(templateId,imagePath);
   }

function updateAll(templateId,imagePath) {
   updateAuto(templateId);
   updateBackgrounds(templateId);
   showTemplate(templateId,imagePath);

   }

function addCell(cellName,location,columnName,checkSize,imagePath,templateId) {
   

   if (cellName.parentNode.childNodes.length > 7 && checkSize) { alert('This interface only allows for 5 columns in a single row. If needed, more can be added manually after you implement your template.'); return false;  }
 
   var newNode = document.createElement('div');
   newNode.setAttribute('style','height:80px;background-image:url(\''+imagePath+'/layoutBox.gif\');background-repeat:no-repeat;background-position:top center;position:relative;text-align:center;margin:0px;width:'+(templateWidth)+'px;float:left;');

   var widthBox = document.createElement('input');
   widthBox.setAttribute('type','text');
   widthBox.setAttribute('style','text-align:center;width:36px;margin:auto;margin-top:15px;padding:0;height:18px;');
   widthBox.setAttribute('value','');
   widthBox.setAttribute('disabled',true);
   widthBox.setAttribute('name','width');
   widthBox.setAttribute('onkeyup','updateAuto(\''+templateId+'\');showTemplate(\''+templateId+'\',\''+imagePath+'\');');
   widthBox.setAttribute('class','data_'+templateId);


   var nameBox = document.createElement('input');
   nameBox.setAttribute('name','name');
   nameBox.setAttribute('type','text');
   nameBox.setAttribute('value',columnName);
   nameBox.setAttribute('onkeyup','showTemplate(\''+templateId+'\',\''+imagePath+'\');');
   nameBox.setAttribute('class','data_'+templateId);
   nameBox.setAttribute('style','text-align:center;width:90px;display:block;margin:auto;margin-top:18px;;padding:0;height:18px;');

   var autoBox = document.createElement('input');
   autoBox.setAttribute('type','checkbox');
   autoBox.setAttribute('name','auto');
   autoBox.setAttribute('checked',true);
   autoBox.setAttribute('onclick','updateAuto(\''+templateId+'\');showTemplate(\''+templateId+'\',\''+imagePath+'\');');
   autoBox.setAttribute('class','data_'+templateId);
   autoBox.setAttribute('style','width:16px;height:16px;');


   var delBox = document.createElement('img');
   delBox.setAttribute('style','padding-left:8px;padding-right:2px;');
   delBox.setAttribute('src',imagePath+'/icons/delete_16.png');
   delBox.setAttribute('onclick','deleteCell(this.parentNode,\''+imagePath+'\',\''+templateId+'\')');

   var endBox = document.createElement('input');
   endBox.setAttribute('type','hidden');
   endBox.setAttribute('class','endData_'+templateId);

   newNode.appendChild(nameBox);
   newNode.appendChild(widthBox);
   newNode.appendChild(autoBox);

   newNode.appendChild(delBox);
   newNode.appendChild(endBox);

   if (location == 'after') {
      cellName.parentNode.insertBefore(newNode,cellName); 
   }
   if (location == 'before') {
      cellName.parentNode.insertBefore(newNode,cellName.nextSibling); 
   }
   if (location == 'none') {
      return newNode; 
   }
   formatRow(cellName.parentNode,imagePath);
   updateAll(templateId,imagePath);
}

