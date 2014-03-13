/*_____________________________________________________________________________
|/
/  FWSJS jQuery Wrapper
|  A jQuery wrapper which modifies algorithms to support the FWS Framework.
|
|  Framework Sites requires support for a little different jQuery
|  to accomplish this we have wrapped many needed jquery functions
|  within a proxy function to support fws properly.
\
_\_____________________________________________________________________________
*/

/*
 * FWSLimitText
 * Limit text and update an onscreen counter
 *
 */
(function($) {
    $.fn.FWSLimitText = function(options) {
        var limitField = options.field;
        if (limitField.val().length > options.limit) {
  		limitField.val(limitField.val().substring(0, options.limit));
	} else { this.html(options.limit -  limitField.val().length); }
}}
)(jQuery);


/*
 * FWSCloseMCE
 * Close all tiny mce's that were opened by default FWS Controls
 *
 */
function FWSCloseMCE() {
	if(typeof(tinyMCE) != 'undefined') {
		for (id in tinyMCE.editors) { 
			if (id.match(/(0|_v_)/)) { tinyMCE.execCommand('mceRemoveControl', false, id); }
		}
	}
}


/*
 * FWSDeleteElement
 * Helper function for edit mode
 *
 */
(function($) {
    $.fn.FWSDeleteElement = function(options) {
                if(confirm('Are you sure you want to delete this item and all of its related sub items?(Non-reversable)')) {
                        $('#delete_'+options.guid).attr('src',globalFiles+'/saving.gif');
                        $('#editModeAJAX_'+options.guid).FWSAjax({queryString:'s='+siteId+'&FWS_editModeUpdate=1&parent='+options.parentGUID+'&p=fws_dataEdit&pageAction=deleteElement&guid='+options.guid,onSuccess: function(returnData){$(this).hide();},showLoading:false});
                }
        }
})(jQuery);


/*
 * FWSButton
 * jQuery Button Wrapper which utilizes
 * the FWSAjax to do its ajax calls.
 *
 */
(function($) {

    $.fn.FWSButton = function(options) {

        // Save the Element
        var element = this;

        var defaults = {
            ajax: false,
            eventListener: "click",
            ajaxOptions: {
                queryString: null,
                url: (typeof scriptName != 'undefined') ? scriptName : "/",
                method: "POST",
                timeout: 120000,
                cache: false,
                loading_html: '<div class="loading"><h4>Loading...</h4></div>',
                showLoading: true,
                onError: function() {
                    alert("Server Failure!");
                },
                onSuccess: function(r) {
                    $(element).html(r);
                }
            },
            title: false

        };
        options = $.extend(defaults, options);

        // Apply CSS
        $(element).addClass("ui-widget").addClass("ui-button").addClass("ui-state-default").addClass("ui-corner-all");

        // Override Title
        if (options.title) {
            $(element).val(options.title);
        }

        // Use Ajax
        if (options.ajax) {

            // Bind Action
            $(element).live(options.eventListener, (function() {
                // Relay Options
                $(element).FWSAjax({
                    queryString: options.ajaxOptions.queryString,
                    url: options.ajaxOptions.url,
                    method: options.ajaxOptions.method,
                    timeout: options.ajaxOptions.timeout,
                    cache: options.ajaxOptions.cache,
                    loading_html: options.ajaxOptions.loading_html,
                    showLoading: options.ajaxOptions.showLoading,
                    onError: options.ajaxOptions.onError,
                    onSuccess: options.ajaxOptions.onSuccess
                });

            }));
        }

        // Maintain Chain
        return element.each(function(){});

    };

})(jQuery);


/*
 * FWSAjax
 * jQuery Ajax Wrapper for FWS
 *
 */
(function($) {

    $.fn.FWSAjax = function(options) {

        // Save the Element
        var element = this;

        var defaults = {
            queryString: null,
            url: (typeof scriptName != 'undefined') ? scriptName : "/",
            method: "POST",
            timeout: 120000,
            cache: false,
            loading_html: '<div class="loading"><h4>Loading...</h4></div>',
            showLoading: true,
            onError: function(a, c) {
                alert("Operation Timedout Please Try Again.");
            },
            onSuccess: function(r) {
                $(element).html(r);
            }

        };
        options = $.extend(defaults, options);
		
		if ($(element).hasClass('antiClick_in_progress')) { return false; }
		
        // Ajax Wrapper
        $.ajax({
            data: options.queryString,
            type: options.method,
            url: options.url,
            timeout: options.timeout,
            cache: options.cache,
            error: function(a, c) {
                options.onError.call(this, a, c);
				$(element).removeClass('antiClick_in_progress');
            },
            beforeSend: function(r) {
				$(element).addClass('antiClick_in_progress');
                if (options.showLoading) {
                    element.each(function() {
                        $(element).html(options.loading_html);
                    });
                }
            },
            success: function(r) {
                element.each(function() {
                    options.onSuccess.call(this, r);
                });
		$(element).removeClass('antiClick_in_progress');
	     }
        });

        // Maintain Chain
        return element.each(function(){});

    };

})(jQuery);


/*
 * FWSPrint
 * print an object
 *
 */
(function($) {
    $.fn.FWSPrint = function() {
        // NOTE: We are trimming the jQuery collection down to the
        // first element in the collection.
        if (this.size() > 1){
                this.eq( 0 ).print();
                return;
        } else if (!this.size()){
                return;
        }

        // ASSERT: At this point, we know that the current jQuery
        // collection (as defined by THIS), contains only one
        // printable element.

        // Create a random name for the print frame.
        var strFrameName = ("printer-" + (new Date()).getTime());

        // Create an iFrame with the new name.
        var jFrame = $( "<iframe name='" + strFrameName + "'>" );

        // Hide the frame (sort of) and attach to the body.
        jFrame
                .css( "width", "1px" )
                .css( "height", "1px" )
                .css( "position", "absolute" )
                .css( "left", "-9999px" )
                .appendTo( $( "body:first" ) )
        ;

        // Get a FRAMES reference to the new frame.
        var objFrame = window.frames[ strFrameName ];

        // Get a reference to the DOM in the new frame.
        var objDoc = objFrame.document;

        // Grab all the style tags and copy to the new
        // document so that we capture look and feel of
        // the current document.

        // Create a temp document DIV to hold the style tags.
        // This is the only way I could find to get the style
        // tags into IE.
        var jStyleDiv = $( "<div>" ).append(
                $( "style" ).clone()
                );

        // Write the HTML for the document. In this, we will
        // write out the HTML of the current element.
        objDoc.open();
        objDoc.write( "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" );
        objDoc.write( "<html>" );
        objDoc.write( "<body>" );
        objDoc.write( "<head>" );
        objDoc.write( "<title>" );
        objDoc.write( document.title );
        objDoc.write( "</title>" );
        objDoc.write( jStyleDiv.html() );
        objDoc.write( "</head>" );
        objDoc.write( this.html() );
        objDoc.write( "</body>" );
        objDoc.write( "</html>" );
        objDoc.close();

        // Print the document.
        objFrame.focus();
        objFrame.print();

        // Have the frame remove itself in about a minute so that
        // we don't build up too many of these frames.
        setTimeout( function(){ jFrame.remove(); }, (60 * 1000));
	}
})(jQuery);




/*
 * FWSSortable
 * Make an Item Sortable
 *
 */
(function($) {

    $.fn.FWSSortable = function(options) {

        // Save the Element
        var element = this;
		
		// Set Children to have move cursor
		$(element).children().css('cursor', 'move');
		
        var defaults = {
            placeholder: "ui-state-highlight",
			axis: "y",
			cursor:	'move',
			dragImage: (typeof globalFiles != 'undefined') ? globalFiles + "/loading.gif" : "/fws/loading.gif",
			dragSpinner: false,
			originalImage: true,
       start: function(event, ui) { },
			over: function(event, ui) { },
			stop: function(event, ui) { },
			
			// Ajax Built In
			ajax: false,
            ajaxOptions: {
                queryString: null,
                url: (typeof scriptName != 'undefined') ? scriptName : "/",
                method: "POST",
            	timeout: 120000,
                cache: false,
                loading_html: '<div class="loading"><h4>Loading...</h4></div>',
                showLoading: true,
                onError: function() {
                    alert("Server Failure!");
                },
                onSuccess: function(r) {
                    $(element).html(r);
                }
            }
        };
        options = $.extend(defaults, options);


	  $( element ).sortable({
		  placeholder: options.placeholder,
		  start: function(event, ui) { 
			if (options.dragImage && options.dragSpinner) { 
				// save original image so we can revert
				options.originalImage = $(ui.item).find('img').attr('src'); 
				$(ui.item).find('img').attr('src', options.dragImage); 
			}
			options.start.call(this, event, ui); 
		},
		  over: function(event, ui) { options.over.call(this, event, ui); },
		  stop: function(event, ui) { 
		
			// Call User Defined Function
			options.stop.call(this, event, ui); 
			
			// Use Ajax
			if (options.ajax) {
				// Relay Options
				$(element).FWSAjax({
					queryString: options.ajaxOptions.queryString,
					url: options.ajaxOptions.url,
					method: options.ajaxOptions.method,
					timeout: options.ajaxOptions.timeout,
					cache: options.ajaxOptions.cache,
					loading_html: options.ajaxOptions.loading_html,
					showLoading: options.ajaxOptions.showLoading,
					onError: options.ajaxOptions.onError,
					onSuccess: options.ajaxOptions.onSuccess
				});
			}
			
			// Revert Original Image
			if (options.originalImage && options.dragSpinner) {
				$(ui.item).find('img').attr('src', options.originalImage);
			}
		}
											 
	 });
		 
		// Disable the text from being able to be selected
		if (options.disableSelection) {
			$( element ).disableSelection();
		}
		
        // Maintain Chain
        return element.each(function(){});

    };

})(jQuery);


/*
 * Will create a Query String from inputs within that div
 * ex: joe=1&jim=2&textarea=hello
 *
 */
 
(function($) {
          
    $.fn.FWSQueryString = function() {
       
        var toReturn    = [];
        var els         = $(this).find(':input').get();
       
        $.each(els, function() {
            if (this.name && !this.disabled && (this.checked || /select|textarea/i.test(this.nodeName) || /text|hidden|password/i.test(this.type))) {
                var val = $(this).val();
                toReturn.push( encodeURIComponent(this.name) + "=" + encodeURIComponent( val ) );
            }
        });   
               
        return toReturn.join("&").replace(/%20/g, "+");
       
    }
 
})(jQuery);


/*
 * FWSPipeList
 * Make an Pipe Delimited List
 *
 */
(function($) {

    $.fn.FWSPipeList = function(options) {

        // Save the Element
        var element = this;
        var returnString = "";
        
        var defaults = {
            pipe: "|",
            truncate: "orderItem_"
        };
        options = $.extend(defaults, options);
        
        $(this).each(function(index) {
           returnString += $(this).attr('id').replace(options.truncate, "");
           returnString += options.pipe;
        });
        
        return returnString;
    }
        

})(jQuery);


/*
 * truncate
 * Truncate a string and append ellipsis
 *
 */
function truncate(str, max) {
    return (str.length > ((typeof max != 'undefined') ? max : max=32)) ? str.substr(0, max-3) + "..." : str;
}











////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  old 1.3 dependicies that still have a few dependencies
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Update Tree function in Design Mode
//
function GNFTreeUpdate(catId,scriptName,queryStringHead,depth,forceRefresh) {
        var lastInList = GNFTreeUpdate.arguments[5];
        var noModalUpdate = GNFTreeUpdate.arguments[6];
        if (typeof lastInList == 'undefined') { lastInList = 0; }
        if (typeof noModalUpdate == 'undefined') { noModalUpdate = 0; }


        if (document.getElementById('cat'+catId).innerHTML == '' || forceRefresh==1) {
                if (noModalUpdate) {
			$('#cat'+catId).FWSAjax({showLoading:false,queryString: queryStringHead+'&parentId='+catId+'&depth='+depth});
                       // GNFAjax(scriptName,queryStringHead+'&amp;parentId='+catId+'&amp;depth='+depth,'cat'+catId);
                        }
                else {
			$('#cat'+catId).FWSAjax({showLoading:false,queryString: queryStringHead+'&parentId='+catId+'&depth='+depth,
						onSuccess: function(returnData) { 	
                            $(this).html(returnData); 
							if (!noModalUpdate) { $.modal.setContainerDimensions(); } 
                        }
			});

                        }
                if (catId!=0) {

                        if (document.getElementById('tree'+catId) != null  ) {
                                document.getElementById('tree'+catId).src = globalFiles+'/minus.gif';
                                }
                        }
                document.getElementById('cat'+catId).style.display = 'none';
                }
        if((document.getElementById('cat'+catId).style.display != 'none')) {
                document.getElementById('cat'+catId).style.display = 'none';
                if (lastInList) {
                        if (document.getElementById('tree'+catId) != null  ) {
                                document.getElementById('tree'+catId).src = globalFiles+'/plus.gif';
                                }
                        }
                else {
                        if (document.getElementById('tree'+catId) != null  ) {
                                document.getElementById('tree'+catId).src = globalFiles+'/plusbottom.gif';
                                }
                        }
                }
        else {
                document.getElementById('cat'+catId).style.display = 'block';
                if (lastInList) {
                        if (document.getElementById('tree'+catId) != null  ) {
                                document.getElementById('tree'+catId).src = globalFiles+'/minus.gif';
                                }
                        }
                else {
                        if (document.getElementById('tree'+catId) != null  ) {
                                document.getElementById('tree'+catId).src = globalFiles+'/minusbottom.gif';
                                }
                        }
                }

        //
        // resize any modal if now that we have expanded or collapsed the tree
        //
        if (!noModalUpdate) {$.modal.setContainerDimensions();}
        }



        //
        // Handle the enter key to move to next object, instead of submitting form
        //

        function handleEnter(field, event) {
                var keyCode = event.keyCode ? event.keyCode : event.which ? event.which : event.charCode;
                if (keyCode == 13) {
                        var i;
                        for (i = 0; i < field.form.elements.length; i++)
                                if (field == field.form.elements[i])
                                        break;
                        i = (i + 1) % field.form.elements.length;
                        field.form.elements[i].focus();
                        return false;
                }
                else
                return true;
        }

//
// renamed for the new FWS Naming convention.  Eventually we will depricate GNFAjax
//
function FWSAjax() {
   GNFAjax(FWSAjax.arguments[0],FWSAjax.arguments[1],FWSAjax.arguments[2],FWSAjax.arguments[3]);
}

//
// Ajax functions
//
function GNFAjax() {

        //GNFAjax parameters
        //(url,parameters,spanId,execWhenFinished);

        var spanId              = GNFAjax.arguments[2];
        var execWhenFinished    = GNFAjax.arguments[3];
        var randomnumber        = Math.floor(Math.random()*11111);
        var url                 = GNFAjax.arguments[0];
        var parameters          = "&"+GNFAjax.arguments[1] + "&cache="+randomnumber;
        parameters              = parameters.replace(/\?/g,"");

        // set browser request object
        var http;
        var browser = navigator.appName;
        if(browser == "Microsoft Internet Explorer"){ http = new ActiveXObject("Microsoft.XMLHTTP"); }
        else { http = new XMLHttpRequest(); }

        //document.body.style.cursor = 'wait';
        //var elems = document.getElementsByTagName("a");
        //for (var i = 0; i < elems.length; i++) { elems[i].style.cursor = 'wait'; }


        //alert(spanId+":"+url+"?"+parameters);
        http.onreadystatechange = function () {
                if (http.readyState==4 || http.readyState=="complete") {

                        if (typeof documentChanged != 'undefined') { documentChanged=false; }
                        document.body.style.cursor = '';
                        var elems = document.getElementsByTagName("a");
                        for (var i = 0; i < elems.length; i++) { elems[i].style.cursor = ''; }
                        var response = http.responseText;
                        if (typeof spanId != 'undefined') {
                                if (spanId != '') {
                                                        document.getElementById(spanId).innerHTML=response;

                                                        //var responseJS = response.match(/\<script.*\>.*\<\/script\>/gim)[0].replace("<script type=\"text/javascript\">", "").replace("<script>", "").replace("<\/script>", "");
                                                        //if (responseJS) { eval(responseJS); }

                                }
                                }
                        if (typeof execWhenFinished != 'undefined') {  eval(execWhenFinished);}
                        }

                }
        // do the post
        http.open('POST', url, true);

        http.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        http.send(parameters);
        }


/* EOF */
