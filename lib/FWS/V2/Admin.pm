package FWS::V2::Admin;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';

=head1 NAME

FWS::V2::Admin - Framework Sites version 2 internal administration

=head1 VERSION

Version 1.14012919

=cut

our $VERSION = '1.14012919';


=head1 SYNOPSIS

    use FWS::V2;

    #
    # Create $fws
    #
    my $fws = FWS::V2->new();


=head1 DESCRIPTION

These methods are used by the FWS to perform web based admin features.  Most methods here are not for general use and can change at any time, reference these in plugins and element for experimental reasons only.

=cut


=head1 METHODS

These modules are used for FWS admin display and logic.   They should not be used outside of the context of FWS admin modules specific to the current build.

=cut


=head2 runAdminAction

Run admin actions.  This will be depricated once they are all moved into the FWS display elements.

=cut

sub runAdminAction {
    my ( $self ) = @_;
    if ( $self->isAdminLoggedIn() && !$self->{stopProcessing} ) { $self->_processAdminAction() }
    return;
}


=head2 displayAdminLogin

Return the HTML used for a default FWS admin login.

=cut

sub displayAdminLogin {
    my ( $self, @tabList ) = @_;
    my $pageId = $self->formValue('p');

    my $loginForm = "<div class=\"FWSAdminLoginContainer\"><div id=\"FWSAdminLogin\">";
    $loginForm .= "<form method=\"post\" enctype=\"multipart/form-data\" action=\"" . $self->{scriptName} . "\">";

    $loginForm .= "<h2>FWS Administrator Login</h2>";

    $loginForm .= "<div class=\"FWSAdminLoginLeft\"><label for=\"FWSAdminLoginUser\">Username:</label><br/><input type=\"text\" name=\"bs\" id=\"FWSAdminLoginUser\" value=\"" . $self->formValue("bs_hold") . "\" /></div>";
    $loginForm .= "<div class=\"FWSAdminLoginRight\"><label for=\"FWSAdminLoginPassword\">Password:</label><br/><input id=\"FWSAdminLoginPassword\" type=\"password\" name=\"l_password\" /></div>";

    $loginForm .= "<div class=\"clear\"></div>";

    $loginForm .= "<input class=\"FWSAdminLoginButton\" type=\"submit\" title=\"Login\" value=\"Login\" />";

    $loginForm .= "<input type=\"hidden\" name=\"p\" value=\"" . $self->{adminURL} . "\"/>";
    $loginForm .= "<input type=\"hidden\" name=\"session\" value=\"" . $self->formValue("session") . "\"/>";
    $loginForm .= "<input type=\"hidden\" name=\"id\" value=\"" . $self->safeQuery( $self->formValue( "id" ) ) . "\"/>";
    $loginForm .= "<input type=\"hidden\" id=\"s\" name=\"s\" value=\"" . $self->formValue("s") . "\"/>";

    $loginForm .= "</form>";
    $loginForm .= "</div>";

    $loginForm .= "<div class=\"FWSAdminLoginLegal\">Powered by Framework Sites v" . $self->{FWSVersion} . "</div>";

    $loginForm .= "</div></div>";

    return $self->printPage( content => $loginForm, head => $self->_minCSS() );
}


=head2 tabs

Return jQueryUI tab html.  The tab names, tab content, tinyMCE editing field name, and any javascript for the tab onclick is passed as arrays to the method.

    #
    # add the data to the tabs and panels to the HTML
    #
    $valueHash{html} .= $self->tabs(
        id              => 'theIdOfTheTabContainer',
        tabs            => [@tabs],
        tabContent      => [@tabContent],
        tabJava         => [@tabJava],

        # html and file tab support
        tabType         => [@tabType],       # file, html or leave empty for standard panel
                                             # setting type will overwrite content and java provided

        tabFields       => [@tabFields],     # field your updating

        guid            => 'someGUID',       # guid your updating

        # optional if your talking to a non-data table
        tabUpdateType   => [@tabUpdateType], # defaults to AJAXExt
        table           => 'data',           # defaults to data

        # for file type only (required)
        currentFile     => [@currentFile],   #
    );

NOTE: This should only be used in the context of the FWS Administration, and is only here as a reference for modifiers of the admin.   In future versions this will be replaced with a hash array style paramater to make this less cumbersome, but this will be avaiable for legacy controls.

=cut

sub tabs {
    my ( $self, %paramHash ) = @_;

    #
    # this will be the counter we will use for inique IDs for each tab for referencing
    #
    my $tabCount = 0;

    #
    # seed our tab html and the div html that will hold the content
    #
    my $tabDivHTML;
    my $tabHTML = "<div id=\"" . $paramHash{id} . "\" class=\"FWSTabs tabContainer ui-tabs ui-widget ui-widget-content ui-corner-all\"><ul class=\"tabList ui-tabs ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all\">";

    while (@{$paramHash{tabs}}) {
        my $tabJava         = shift( @{$paramHash{tabJava}} );
        my $tabContent      = shift( @{$paramHash{tabContent}} );
        my $tabName         = shift( @{$paramHash{tabs}} );
        my $fieldName       = shift( @{$paramHash{tabFields}} );
        my $tabType         = shift( @{$paramHash{tabType}} );
        my $tabUpdateType   = shift( @{$paramHash{tabUpdateType}} );
        my $currentFile     = $self->urlEncode( shift( @{$paramHash{currentFile}} ) );

        #
        # set the default
        #
        $tabUpdateType ||= 'AJAXExt';

        #
        # pass all the info in as the id so we can save it later
        #
        my $editorName  = $paramHash{guid} . "_v_" . $fieldName . "_v_" . $paramHash{table} . "_v_" . $tabUpdateType;

        #
        # tab type overwrites tabJava and tabContent!
        #
        if ( $tabType eq 'file' ) {
            $tabContent = "<div id=\"dataEdit" . $fieldName . "\">Loading...</div>";
            $tabJava    = "if(\$('#dataEdit" . $fieldName . "').html().length < 50) {\$('#dataEdit" . $fieldName . "').FWSAjax({queryString: '" . $self->{queryHead} . "p=fws_fileManager&current_file=" . $currentFile . "&field_update_type=" . $tabUpdateType . "&field_table=" . $paramHash{table} . "&field_name=" . $fieldName . "&guid=" . $paramHash{guid} . "',showLoading: false});}";
        }

        if ( $tabType eq 'html' ) {
            $tabContent = "<div name=\"" . $fieldName . "\" id=\"" . $editorName . "\" class=\"HTMLEditor\" style=\"width:100%;height:445px;\">" . $tabContent . "</div><div style=\"display:none;\" id=\"" . $paramHash{guid} . "_v_" . $fieldName . "_v_StatusNote\"></div>";
        }

        #
        # this is the connector between the tab and its HTML
        #
        my $tabHRef     = $paramHash{id} . "_" . $tabCount . "_" . $self->createPassword( composition => 'qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM', lowLength => 6, highLength => 6 );

        #
        # if tiny mce is being used on a tab, lets light it up per the clicky
        # also tack on any tabJava we had passed to us
        #
        my $javaScript      = "FWSCloseMCE();";
        $javaScript        .= "if ( typeof(tinyMCE) != 'undefined' ) { tinyMCE.execCommand('mceAddControl', false, '" . $editorName . "'); }";
        $javaScript        .= "if ( typeof(\$.modal) != 'undefined' ) { \$.modal.update(); }";
        $javaScript        .= "if ( typeof(\$.modal) != 'undefined' ) { \$.modal.update(); }";
        $javaScript        .= $tabJava;
        $javaScript        .= "return false;";

        #
        # flag we are on the first one!... we want to hide the content areas if we are not
        #
        my $hideMe;
        if ( $tabCount > 0 ) { $hideMe = " ui-tabs-hide" }

        #
        # add to the tab LI and the HTML we will put below for each tab
        #
        $tabHTML        .= "<li class=\"tabItem tabItem ui-state-default ui-corner-top ui-state-hover\"><a onclick=\"" . $javaScript . "\" href=\"#" . $tabHRef . "\">" . $tabName . "</a></li>";
        $tabDivHTML     .= "<div id=\"" . $tabHRef . "\" class=\"ui-tabs-panel ui-widget-content ui-corner-bottom" . $hideMe . "\">" . $tabContent . "</div>";

        #
        # add another tabCount to make our next tab unique ( plus a unique 6 char key )
        #
        $tabCount++;
    }

    #
    # the tabs need this jquery ui stuff to work.  lets make sure they are here if they aren't laoded already
    #
    $self->jqueryEnable( 'ui-1.8.9' );
    $self->jqueryEnable( 'ui.widget-1.8.9' );
    $self->jqueryEnable( 'ui.tabs-1.8.9' );
    $self->jqueryEnable( 'ui.fws-1.8.9' );

    #
    # return the tab content closing the ul and div we started in tabHTML
    #
    return $tabHTML . '</ul>' . $tabDivHTML . '</div>';
}


=head2 importSiteImage

Unpack a agnostic DB and File administration packages via FWS administration distrubuted by framworksites.com.

=cut

sub importSiteImage {
    my ( $self, %paramHash ) = @_;

    my $image               = $paramHash{image};
    my $imageFile           = $paramHash{imageFile};
    my $imageURL            = $paramHash{imageURL};
    my $tableList           = $paramHash{tableList};
    my $deleteBeforeImport  = $paramHash{deleteBeforeImport};
    my $filesOnly           = $paramHash{filesOnly};
    my $dataOnly            = $paramHash{dataOnly};
    my $postField           = $paramHash{postField};

    my $importReturn;
    my %importTable;

    #
    # create a import file and start writing to it depending onhow we got the file in
    #
    my $importFile = $self->fileSecurePath() . "/import_" . $self->formatDate( format => 'number' ) . ".fws";

    open ( my $IFILE, ">", $importFile );

    #
    # we have an image string save it off so we can process it with the file handle
    #
    if ( $image ) { print $IFILE $image }

    #
    # if we got a URL get it!
    #
    if ( $imageURL ) {
        require LWP::UserAgent;
        my $browser         = LWP::UserAgent->new();
        my $response        = $browser->get( $imageURL );
        if (!$response->is_success ) { return "Error connecting to the FWS Module Server was found: " . $response->status_line }
        print $IFILE $response->content;
    }

    #
    # if it is ac existing site, use the admin password already there. if not leave it blank so it won't allow logins
    #
    my ( $siteActive, $siteGUID, $homeGUID ) = @{$self->runSQL( SQL => "select 1,site_guid,home_guid from site where sid = '" . $paramHash{newSID} . "'" )};

    #
    # get the tables we are going to import and set them to on.
    #
    my @tables = split( ',', $tableList );
    while ( @tables ) {
        my $theTable = shift( @tables );
        $importTable{$theTable} = 1;
    }

    #
    # read textImage if that was handed to us
    #
    if ( $postField ) {
        my $bytesread;
        my $buffer;
        while ( $bytesread = read( $self->formValue( $postField ), $buffer, 1024 ) ) {
            $buffer =~ s/[\x0A\x0D]+/\n/g;
            print $IFILE $buffer;
        }
    }

    #
    # read file if that was handed to us
    #
    if ( $imageFile ) {
        open ( my $FILE, "<", $imageFile );
        while ( my $inputLine = <$FILE> ) { print $IFILE $inputLine . "\n" };
        close $FILE;
    }


    #
    # close the import file down so we can reopen it for processing
    #
    close $IFILE;

    #
    # double check if the site is valid,  in case this is ran from a script
    # most importanly we want to make sure the site_guid isnt already there
    #

    #
    # if we are talking aout the admin import, or an elementOnly import let this ride
    #
    my $validSite = $self->_isValidSID( $paramHash{newSID} );


    #
    # set a flag for elementOnly
    #
    my $elementOnly = 0;
    if ( ( split(/\n/, $image ) )[0] eq "ELEMENT ONLY" )  {
        $importReturn = "Importing element to existing site ID:" . $paramHash{newSID};
        $elementOnly = 1;
    }

    if ( $validSite && $paramHash{newSID} ne 'zipcode' && $paramHash{newSID} ne 'admin' && !$elementOnly) { return " " .  $validSite . " No import was performed." }

    #
    # if it is an element Only import, make sure the site_guid is valid
    #
    if ( ( $elementOnly && !$siteActive ) || !$paramHash{newSID} ) { return "The FWS File is an element import file, and '" . $paramHash{newSID} . "' is not a valid Site ID.  No element import was performed." }

    if ( !-s $importFile ) { return "The FWS File is invalid.  No import was performed." }

    #
    # get the site GUID we are importing to
    #
    $siteGUID ||= $self->createGUID( 's' );

    #
    # if this is an fws import we need the fws id and import away
    #
    if ( $paramHash{newSID} eq 'fws' ) {
        $siteGUID = $self->safeSQL( $self->fwsGUID() );

        #
        # blow away all the stuff the is FWS so we can come in fresh
        #
        if ( $paramHash{removeCore} ) {
            $self->runSQL( SQL => "delete from data where guid like 'f%'" );
            $self->runSQL( SQL => "delete from element where guid like 'f%'" );
            $self->runSQL( SQL => "delete from guid_xref where site_guid = '" . $self->safeSQL( $siteGUID ) . "'" );
            $self->runSQL( SQL => "delete from data_cache where guid like 'f%'" );
        }
    }

    #
    # decompress and process
    #
    my $fileName;
    my $fileReading;
    my %tableSchema;
    my $keepAliveCount        = 0;
    $paramHash{keepAlive}   ||= 0;


    open( my $READ_FILE, "<", $importFile );

    while (my $line = <$READ_FILE>) {
            $line =~ s/\n$//g;
            $keepAliveCount++;
            if ( $line =~ /^FILE_END\|/ && !$dataOnly ) {
                #
                # get just the directory so we can make the dir in case it does not exist already
                #
                my $fileDir = $self->{filePath} . $fileName;
                my @splitDir = split( /\//, $fileDir );
                pop(@splitDir);
                my $justDirectory = join( "/", @splitDir );

                #
                # make sure nothing dangrous is in the dir
                #
                $justDirectory =~ s/\/\//\//sg;

                #
                # if we are not doing an element only, or the file starts with /admin save the file
                #
                if ( !$self->formValue( 'elementOnly' ) || $fileName =~ /^\/admin\// ) {
                    #
                    # create the directory to make sure its good
                    #
                    $self->makeDir( $justDirectory );

                    #
                    # save the file to that directory
                    #
                    $self->saveEncodedBinary( $self->{filePath} . $fileName, $fileReading );
                }

                #
                # reset so when we come around again we will no we are done.
                #
                $fileName = '';
                $fileReading = '';
            }

            #
            # if we have a file name,  we are currenlty looking for a
            # file.  eat those lines up and stick them in a diffrent var
            #
            elsif ( $fileName ) { $fileReading .= $line . "\n" }

            #
            # if this is a start of a file, lets get it set up and
            # define the file name, the next time we go around we
            # will be looking at the base 64
            #
            elsif ( $line =~ /^FILE\|/  && !$dataOnly ) {
                my @fileNameArray = split(/\|/,$line);
                $fileName = $fileNameArray[1];
                $fileName =~ s/#FWSSiteGUID#/$siteGUID/sg;
            }

            #
            # ALLLRIGHTY, this isn't a file, lets process it like it
            # it is a normal database row that needs to be processed
            #
            else {
                my @data = split( /\|/, $line );

                my $tableName = shift( @data );

                my @fieldList = split( ',', $tableSchema{$tableName} );
                my $numberOfFields = $#fieldList;

                #
                # if we havn't seen this table before that means its a schema
                #
                if ( !defined $tableSchema{$tableName} ) { $tableSchema{$tableName} =  shift(@data) }
                else {
                    my $cleanData;
                    my $dataCount  = 0;
                    my $skipComma  = 1;
                    my $skipInsert = 0;
                    my $fieldNames = $tableSchema{$tableName};

                    for( my $dataCount=0; $dataCount <= $numberOfFields; $dataCount++ ) {

                        #
                        # decode the data and flip stuf arround that needs to be groomed
                        #
                        $data[$dataCount] = $self->urlDecode( $data[$dataCount] );
                        
                        #
                        # Set the new sid
                        #
                        if ( $tableName eq 'site' && $fieldList[$dataCount] eq 'sid' ) { $data[$dataCount] = $paramHash{newSID} }

                        if ( $tableName eq 'site' && $fieldList[$dataCount] eq 'site_guid' ) {
                            #
                            # we need the admin guid for this install.
                            #
                            my ( $parentSID ) = @{$self->runSQL( SQL => "select guid from site where sid='admin'" )};
                            $data[$dataCount] = $parentSID;
                        }

                        #
                        # if we are importing stuff from the admin, we need these to be fws
                        #
                        if ( $paramHash{newSID} eq 'admin' ) {
                            if ( $tableName eq 'data'        && $fieldList[$dataCount] eq 'site_guid' ) {   $data[$dataCount] = 'fws'}
                            if ( $tableName eq 'guid_xref'   && $fieldList[$dataCount] eq 'site_guid' ) {   $data[$dataCount] = 'fws'}
                        }


                        #
                        # if we hvan't already skip the first comma, and then add the field
                        #
                        if (!$skipComma) { $cleanData .= ',' }


                        #
                        # clean and format the data from the import storage
                        #
                        $data[$dataCount] = $self->_convertImportTags( content => $data[$dataCount], siteGUID => $siteGUID, homeGUID => $homeGUID );

                        #
                        # convert safe text export back to the storable version
                        #
                        if ( $fieldList[$dataCount] eq 'extra_value' ) {
                            my @splitExtra = split(/\|/,$data[$dataCount]);
                            my %extraHash;
                            while (@splitExtra) {
                                my $field     = shift @splitExtra;
                                my $value     = shift @splitExtra;
                                $value        = $self->urlDecode( $value );
                                $value        = $self->_convertImportTags( content => $value, siteGUID => $siteGUID, homeGUID => $homeGUID );
                                $extraHash{$self->urlDecode( $field )} = $value;
                            }
                            use Storable qw(nfreeze thaw);
                            $data[$dataCount] = nfreeze(\%extraHash);
                        }

                        #
                        # add to the insert statement string
                        #
                        if ( $data[$dataCount] =~ /^null$/i ) { $cleanData .=  'null' }
                        else { $cleanData .= "'" . $self->safeSQL( $data[$dataCount] ) . "'" }

                        $skipComma = 0;

                    }

                    #
                    # process what we collected from th loop
                    #

                    #
                    # lets check to make sure we are only going to do elements if we are element only
                    #
                    if ( ( $tableName ne "element" && $self->formValue( "elementOnly" ) ) ) {
                        $skipInsert = 1;
                    }

                    #
                    # only add the data to the DB if the we are not set to fileOnly mode,
                    # and if we are not on special
                    # fields that do not have.
                    #
                    if (!$skipInsert && !$filesOnly ) {

                        my $siteCSS;
                        my $siteJavaScript;
                        my $pageJavaScript;
                        my $pageCSS;
                        $self->runSQL( SQL => "insert into " . $tableName . " (" . $fieldNames . ") values (" . $cleanData . ")" );

                    }
                }
            }
            if ( $keepAliveCount > $paramHash{keepAlive} ) {
                $keepAliveCount = 0;
                if ( $paramHash{keepAlive} ) { print " ." }
            }
        }
    close $READ_FILE;
    return $importReturn;
}
    

=head2 systemInfo

Return the system info page accessed by clicking "System" from the admin menu.

=cut

sub systemInfo { 
    my ( $self ) = @_;
    my $coreVersion     = '-';
    my $adminInstalled  = 0;    
    my $systemInfo;
    my $errorReturn;

    #
    # if we are looking at systemInfo lets make sure we have a fws guid
    # this will make a new one if its not there for an install process
    #
    $self->fwsGUID();

    #
    # run directory checks
    #
    $errorReturn = "";
    $systemInfo .= "<b>File Directory Check:</b><br/>";
    $systemInfo .= "<ul>";
    $errorReturn .= $self->_systemInfoCheckDir( $self->{filePath} );
    $errorReturn .= $self->_systemInfoCheckDir( $self->{fileSecurePath} );
    
    #
    # show this, if the rest works
    #
    if ( !$errorReturn ) { $errorReturn .= $self->_systemInfoCheckDir( $self->{filePath} . "/fws") }
    if ( !$errorReturn ) { $errorReturn .= $self->_systemInfoCheckDir( $self->{filePath} . "/fws/jquery") }
    if ( !$errorReturn ) {
        $errorReturn = "<li>All directories are present with suitable permissions.</li>"; 
        $adminInstalled = 1;
    }

    $systemInfo .= $errorReturn . "</ul>";
        
    #
    # run Module Checks
    #
    $errorReturn = '';
    $systemInfo .= '<b>Perl Module Check:</b><br/>';
    $errorReturn .= $self->_checkIfModuleInstalled( 'Captcha::reCAPTCHA' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'MIME::Base64' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'CGI::Carp' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'File::Copy' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'File::Find' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'Time::Local' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'File::Path' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'Google::SAML::Response' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'LWP::UserAgent' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'Crypt::SSLeay' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'Crypt::Blowfish' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'GD' );
    if ( !$errorReturn ) { $systemInfo .= '<ul><li>All required Perl Modules are present.</li></ul>' }    
    else { $systemInfo .= $errorReturn . '<br/>' }
    
    #
    # run go file checks
    #
    $errorReturn = '';
    $systemInfo .= '<b>Script compatibility Check:</b><br/>';
    $errorReturn .= $self->_checkScript();
    if ( !$errorReturn ) { $systemInfo .= '<ul><li>All script compatability checks passed.</li></ul>' }
    else { $systemInfo .= $errorReturn  }


    #
    # Database Checks
    #
    $systemInfo .= '<b>Database Table And Index Check:</b><br/>';
    $errorReturn = $self->updateDatabase();
    if ( !$errorReturn ) { $systemInfo .= '<ul><li>All tables and indexes are correct.</li></ul>' }    
    else {$systemInfo .= $errorReturn . '<br/>' }

    if ( $adminInstalled )  {
        $systemInfo .= "<input style=\"width:300px;\" type=\"button\" onclick=\"location.href='" . $self->{scriptName} . "?s=site';\" value=\"View Site\"/>";
    }
            
    return $systemInfo;
}


=head2 aceTextArea

Create an ace editor UI componate.

=cut

sub aceTextArea {
    my ( $self, %paramHash ) = @_;

    my $statusContainer = 'scriptChangedStatus';
    my $modeScript;

    if ( $paramHash{statusContainer} ) { $statusContainer = $paramHash{statusContainer} }
    
    #
    # load the JS for for ace... but only ONCE!
    #    
    if ( !$self->{FWSAceJSLoaded} ) {
        $self->addToFoot(    
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/ace.js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n" .
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/theme-" . $self->{aceTheme} . ".js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n" .
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/mode-javascript.js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n" .
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/mode-html.js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n" .
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/mode-perl.js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n" .
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/mode-css.js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n"
        );
        $self->addToHead( 
            "<style>" .
            ".FWSACEFullscreen .FWSACEFullscreen-editor{" . 
                "height: auto!important;" .
                "width: auto!important;" .
                "border: 0;" .
                "margin: 0;" .
                "position: fixed !important;" .
                "top: 0;" .
                "bottom: 0;" .
                "left: 0;" .
                "right: 0;" .
                "z-index: 10000;" .
            "}" .
            ".FWSACEFullscreen {" . 
                "overflow: hidden;" .
            "}" .  
            "</style>\n"
        );
        
        #
        # mark that we loaded it so we don't do this again
        #
        $self->{FWSAceJSLoaded}++;
    }
        
    $modeScript .= 'var FWSAceDOM = require("ace/lib/dom");';

    #
    # set the modes if we have them
    #
    if ( $paramHash{mode} eq 'html' ) {
        $modeScript .= "var HTMLScriptMode = require(\"ace/mode/html\").Mode;" . $paramHash{name} . ".getSession().setMode(new HTMLScriptMode());\n";
    }
    if ( $paramHash{mode} eq 'javascript' ) {
        $modeScript .= "var JSScriptMode = require(\"ace/mode/javascript\").Mode;" . $paramHash{name} .".getSession().setMode(new JSScriptMode());\n";
    }
    if ( $paramHash{mode} eq 'perl' ) {
        $modeScript .= "var HTMLScriptMode = require(\"ace/mode/perl\").Mode;" . $paramHash{name} . ".getSession().setMode(new HTMLScriptMode());\n";
    }
    if ( $paramHash{mode} eq 'css' ) {
        $modeScript .= "var CSSScriptMode = require(\"ace/mode/css\").Mode;" . $paramHash{name} . ".getSession().setMode(new CSSScriptMode());\n";
    }

    $modeScript .= $paramHash{name} . '.commands.addCommand({' .
        'name: "Fullscreen",' .
        'bindKey: {win: "ctrl-enter",  mac: "ctrl-enter"},' .
        'exec: function(editor) {' .
            'FWSAceDOM.toggleCssClass(document.body, "FWSACEFullscreen");' .
            'FWSAceDOM.toggleCssClass(editor.container, "FWSACEFullscreen-editor");' .
            'editor.resize();' .
        '},' .
        'readOnly: true,' .
        '});' . 
        "\n";

    $self->addToFoot( 
        "<script type=\"text/javascript\">" .
        "\$(document).ready(function() {" .
            "window." . $paramHash{name} . " = ace.edit(\"" . $paramHash{name} . "\");" .
            $paramHash{name} . ".setTheme(\"ace/theme/" . $self->{aceTheme} . "\");" .
            $paramHash{name} . ".getSession().setUseWrapMode(true);" .
            $paramHash{name} . ".setShowPrintMargin(false);" . 
            $modeScript . $paramHash{name} . ".getSession().on('change', function () { \$('#saveToStagingImg').addClass( 'btn-primary' );});" .
        "});" .
        "</script>\n"
    );

    #
    # clean up thing that need to be escaped for ace
    #
    $paramHash{value} =~ s/&/&amp;/sg;
    $paramHash{value} =~ s/\</&lt;/sg;

    #
    # create the line that will actually be rendered to the screen
    #
    return "<pre style=\"position: absolute; padding: 0; right: 0; bottom: 0; left: 0;display:none;\" id=\"" . $paramHash{name} . "\" class=\"FWSScriptEditContainer ui-widget ui-state-default ui-corner-bottom\">" . $paramHash{value} . "</pre>";
}


=head2 onOffLight

Return an on off lightbulb.

=cut 

sub onOffLight {
    my ( $self, $status, $guid, $style ) = @_;
    return $self->activeToggleIcon( guid => $guid, style => $style, active => $status );
}


=head2 editBox

Return a edit box for the passed element hash;

=cut

sub editBox {    
    my ( $self, %editHash ) = @_;

    my $editHTML;
    #my $ajaxID = '#editModeAJAX_' . $self->formValue( 'FWS_elementId' );
    my $ajaxID = '#editModeAJAX_' . $editHash{guid};

    #
    # default always show to off if its not passed
    #
    $editHash{alwaysShow} ||= 0;

    #
    # default color
    #
    $editHash{editBoxColor} ||= '#008000;';

    #
    # Define things to blank that might not be passed that we will
    # use
    #
    $editHash{siteGUID} ||= '';
    $editHash{name}     ||= '';
    $editHash{type}     ||= '';

    #
    # if we are in edit mode, make buttons and container
    # 
    if ( ( $self->formValue( 'editMode' ) || $editHash{alwaysShow} ) ) {

         if ( $self->{siteGUID} eq $editHash{siteGUID} || !$editHash{siteGUID} ||  $editHash{alwaysShow} ) { 
    
            #
            # Edit Bar Open Div Container
            #
            if ( !$editHash{editBoxJustButtons} ) {
                my $bgColor     = $self->_getHighlightColor( $editHash{editBoxColor} );
                my $divStyle    = "color:" . $editHash{editBoxColor} . ";background-color:".$bgColor.";border:dotted 1px " . $editHash{editBoxColor} . ";border-bottom:dotted 1px " . $editHash{editBoxColor} . ";text-align:right;";
    
                $editHTML .=  "<div style=\"" . $editHash{AJAXDivStyle} . "\" id=\"editModeAJAX_" . $editHash{guid} . "\">";
                $editHTML .=  "<div style=\"" . $divStyle . "\" class=\"FWSEditBoxControls\">";
                $editHTML .=  $editHash{name} . " ";
            }
            #
            # check to see if this could have children
            #
            my $showOrderButton = 0;
            my %elementHash = $self->_fullElementHash( typeAlso => 1 );
            for my $type ( keys %elementHash ) {
                if ( defined $elementHash{$type}{parent} ) {
                    if ( defined $editHash{type} ) {
                         if ( $elementHash{$type}{parent} eq $editHash{type} ) {  $showOrderButton = 1 }
                    }
                    if ( defined $elementHash{$editHash{type}}{guid} ) {
                        if ( $elementHash{$type}{parent} eq $elementHash{$editHash{type}}{guid} ) { $showOrderButton = 1 }
                    }
                } 
            }
    
            my $layoutFlag;
            my $pageFlag;
    
            #
            # if this is a column header edit box it will not have a type, which means we have to pass layout
            #
            if ( !$editHash{type} ) { $layoutFlag = "&layout=" . $editHash{layout} }
        
            if ( $editHash{pageOnly} ) { 
                $showOrderButton    = 1; 
                $pageFlag           = '&pageOnly=1';
                $layoutFlag         = '&layout=' . $editHash{layout};
            }
    
            if ( ( $showOrderButton || $editHash{orderTool} ) && !$editHash{disableOrderTool} ) {
                $editHTML .= $self->FWSIcon(    
                                icon        => "add_reorder_16.png",
                                onClick     => $self->dialogWindow(queryString=>"p=fws_dataOrdering&guid=" . $editHash{guid} . $pageFlag . $layoutFlag),
                                alt         => "Add And Ordering",
                                width       => "16");
            }
        
            #
            # Check to see if we should put the delete trash can icon
            #
            if ( ( $editHash{deleteTool} || ( $self->{siteGUID} eq $editHash{guid_xref_site_guid} ) || $editHash{forceDelete} ) && !$editHash{disableDeleteTool} ) {
        
                #
                # set up som vars for the post,  we want to do this differntly if we are talking about
                # a base element, or a sub element
                #
                #my $baseClear = "\$('#delete_" . $editHash{guid} . "').parent().parent().parent().parent().parent().hide();";
        
                #
                # If the parent isn't a page, that means we are talking about a sub element of an element.
                # we need to make sure the ajaxID is the parent of this element and then refresh the element in place.
                #
                # if it is a sub elemenet of an element, we also need to disable the "display none" it dosn't look goofy
                #
                #if ( $self->formValue( "FWS_pageId" ) eq $editHash{parent} && !$self->formValue( "FWS_editModeUpdate" ) ) { 
                #    $ajaxID = '<div></div>';
                #}
                #else { $baseClear = "" }
        
                $editHTML .= $self->FWSIcon(
                    icon    => "delete_16.png",
                    onClick => "\$('" . $ajaxID . "').FWSDeleteElement({pageGUID: '" . $self->formValue( 'FWS_elementId' ) . "',parentGUID: '" . $editHash{parent} . "', guid: '" . $editHash{guid} . "'});", 
                    alt     => "Delete",
                    width   => "16",
                    id      => "delete_" . $editHash{guid},
                );
            }
    
            #
            # add and order Tool Button
            #
            if ( !$editHash{disableEditTool} && $editHash{type} ne 'page') {
                $editHTML .= $self->FWSIcon(     
                    icon    => "properties_16.png",
                    onClick => $self->dialogWindow( queryString => "p=fws_dataEdit&guid=" . $editHash{guid} . "&parentId=" . $editHash{parent} ),
                    alt     => "Edit",
                    width   => "16",
                );
            }
        
            #
            # ON/OFF cotnrol
            #
            if ( !$editHash{disableActiveTool} && $editHash{guid} ne $self->homeGUID() ) { $editHTML .= $self->onOffLight( $editHash{active}, $editHash{guid} ) }
        
            #
            # close the edit bar container
            #    
            if ( !$editHash{editBoxJustButtons} ) { $editHTML .= '</div>' }
    
            $editHTML .= $editHash{editBoxContent};   
            $editHTML .= $editHash{editBox};
        
            #
            # close the delete ajax container
            #    
            if ( !$editHash{editBoxJustButtons} ) { $editHTML .= '</div>' }
        }
    }

    #
    # edit mode is not on, just show the content and call this good
    #
    else { $editHTML .= $editHash{editBoxContent} . $editHash{editBox} }
    return $editHTML;
}    
    
 
=head2 FWSMenu

Return the FWS top menu bar.

=cut

sub FWSMenu {
    my ( $self, %paramHash ) = @_;

    #
    # because we have a menu, it might need tiny mce
    #
    $self->{tinyMCEEnable} = 1;
            
    my $linkSpacer = " &nbsp;&middot;&nbsp; ";
    my $FWSMenu;
    

    #
    # create a correct label for fws/devel link to know what we have access too
    #
    if ( $self->userValue( 'isAdmin' ) || $self->userValue( 'showDeveloper' ) )  {
        $FWSMenu .= $self->popupWindow( queryString => "p=fws_systemInfo", linkHTML => "System" );
        $FWSMenu .= $linkSpacer;
    }

    #
    # get the FWSMenu taged elements and add them to the list
    #
    my @elementArray    = $self->elementArray( tags => 'FWSMenu' );
    @elementArray       = $self->sortDataByNumber( 'ord', @elementArray );
    for my $i (0 .. $#elementArray) {

        #
        # blank out the adminGroup if we have access so we can pass by the security check
        #
        map { if ( $self->userValue( $_ ) eq 1 ) { $elementArray[$i]{adminGroup} = '' } } split( /,/, $elementArray[$i]{adminGroup} );

        #
        # if we have access or we are super user show it
        #
        if ( !$elementArray[$i]{adminGroup} || $self->userValue( 'isAdmin' ) ) {
    
            #
            # convert to our friendly name format
            #
            ( my $fwsLink = $elementArray[$i]{type} ) =~ s/^FWS/fws_/sg;
    
            #
            # if this is not a friendly type version menu item then use the guid
            #
            $fwsLink ||= 'fws_' . $elementArray[$i]{guid};

            my $queryString = "FWS_pageId=" . $paramHash{pageId} . "&p=" . $fwsLink . "&FWS_showElementOnly=";
            if ( $elementArray[$i]{rootElement} ) { $FWSMenu .= $self->popupWindow( queryString => $queryString . "0", linkHTML => $elementArray[$i]{title} ) }
            else { $FWSMenu .= $self->dialogWindow( queryString => $queryString . "1", linkHTML => $elementArray[$i]{title} ) }
            $FWSMenu .= $linkSpacer;
        }
    }

    if ( $self->formValue( "p" ) =~ /^fws_/ ) {
        $FWSMenu .= $self->_selfWindow( "", "View Site" );
        $FWSMenu .= $linkSpacer;
    }
    
    #    
    # ALWAYS ON
    #
    if ( $self->userValue( 'isAdmin' ) || $self->userValue( 'showDesign' ) || $self->userValue( 'showContent' ) || $self->userValue( 'showDeveloper' ) )  {
        $FWSMenu .= $self->_editModeLink( '', $linkSpacer );
    }

    $FWSMenu .= $self->_logOutLink();
    
    if ( $self->userValue( 'isAdmin' ) || $self->userValue( 'showDesign' ) || $self->userValue( 'showContent' ) || $self->userValue( 'showDeveloper' ) )  {

        #
        # just in case we havn't installed FWS core yet, lets make sure the image is there before we 
        # try to display it.
        #
        if ( -e $self->{filePath} . '/fws/icons/add_reorder_16.png' ) {
            $FWSMenu .= $linkSpacer;
            $FWSMenu .= $self->FWSIcon( 
                icon    => 'add_reorder_16.png',
                onClick => $self->dialogWindow( queryString => 'p=fws_dataOrdering&guid=' . $paramHash{pageId} . '&pageOnly=1' ),
                alt     => 'Add And Ordering',
                width   => '16',
            );
        }
    }

    $FWSMenu .= $linkSpacer;

    return $FWSMenu;
}


=head2 panel

FWS panel HTML:  Pass title, content and panelStyle keys.

=cut

sub panel {
    my ( $self, %paramHash ) = @_;
    
    my $panel;

    if ( $paramHash{inline} ) {
        $panel .= "<div style=\"width:95%;font-size:12px;margin-top:10px;padding-bottom:10px;margin-bottom:10px;border: 1px solid #d3d3d3; padding:10px;background: #ffffff; -moz-border-radius: 4px; -webkit-border-radius: 4px; border-radius: 4px; font-weight: normal; color: #555555;" . $paramHash{panelStyle} . "\" class=\"FWSPanel ui-widget ui-widget-content ui-corner-all\">";
        $panel .= "<div style=\"padding:5px 15px 15px 15px;font-weight:800;font-size:14px;color:#2B6FB6;\" class=\"FWSPanelTitle\">" . $paramHash{title} . "</div>";
        $panel .= "<div steyl=\" padding:5px 15px 15px 15px;font-size:12px;\" class=\"FWSPanelContent\">" . $paramHash{content} . "</div>";
        $panel .= "</div>";
    }
    else {
        $panel .= "<div ";
        if ( defined $paramHash{panelStyle} ) { $panel .= "style=\"" . $paramHash{panelStyle} . "\" " }
        $panel .= "class=\"FWSPanel ui-widget ui-widget-content ui-corner-all\">";
        $panel .= "<div class=\"FWSPanelTitle\">" . $paramHash{title} . "</div>";
        $panel .= "<div class=\"FWSPanelContent\">" . $paramHash{content} . "</div>";
        $panel .= "</div>";
    }
    return $panel;
}


=head2 displayAdminPage

Run the lookup and display admin pages wrapped in security precautions.

=cut

sub displayAdminPage {
    my ( $self ) = @_;

    #
    # mimic the normal element processing controls
    #
    my $pageHTML; 
    my $showElementOnly = 0;
    my $quitPageProcessing = 0;
    my $pageId = $self->safeSQL( $self->formValue( 'p' ) );
        
    if ( $self->isAdminLoggedIn() ) {

        #
        # see if we looking at a dynamicly created admin page
        #
        if ( $pageId =~ /^fws_/ ) { 
            my %elementHash = $self->_fullElementHash();
            for my $guid ( sort { $elementHash{$a}{alphaOrd} <=> $elementHash{$b}{alphaOrd} } keys %elementHash ) {

                #
                # trim up what these actually look like to match naming
                #
                ( my $fwsElementType = $pageId ) =~ s/fws_//sg;
                $fwsElementType = 'FWS' . ucfirst( $fwsElementType );

                if ( $self->{_fullElementHashCache}->{$guid}{type} eq $fwsElementType || "fws_" . $guid eq $pageId ) {
                
                    my %elementHash = $self->elementHash( guid => $guid );
    
                    #
                    # blank out the adminGroup if we have access so we can pass by the security check
                    #
                    map { if ( $self->userValue( $_ ) eq 1 ) { $elementHash{adminGroup} = '' } } split( /,/, $elementHash{adminGroup} );
            
                    #
                    # if we have access or we are super user show it
                    #
                    if ( !$elementHash{adminGroup} || $self->userValue( 'isAdmin' ) ) {
                       
                        my %valueHash;
                        $valueHash{pageId}          = $pageId;
                        $valueHash{elementId}       = $guid;
                        $valueHash{elementWebPath}  = $self->fileWebPath() . "/" . $elementHash{siteGUID} . "/" . $valueHash{elementId};
    
                        my $fws = $self;
    
                        ## no critic
                        eval $elementHash{scriptDevel};
                        ## use critic
                        my $errorCode = $@;
                        if ( $errorCode ) {
                            $valueHash{html} .= "<div style=\"border:solid 1px;font-weight:bold;\">FrameWork Element Error:</div><div style=\"font-style:italic;\">".$errorCode."</div>";
                        }
    
                        #
                        # now put it back
                        #
                        $self = $fws;
   
                        #
                        # set head and foot from cache so we can use it for our admin page
                        #
                        $self->{tinyMCEEnable} = 1;
                        $self->{bootstrapEnable} = 1;
                        $self->setPageCache();
    
                        #
                        # just in case we havn't rendered yet, here we go!  if we have already rendered  (like we should have
                        # than this just gets passed by
                        #
                        $self->printPage( content => $valueHash{html}, head => $self->FWSHead(), foot => $self->siteValue( 'pageFoot' )  );
                    }
                }
            }
        }

            
        #
        # this one does not run in an element, because it installs the elements!
        #
        if ( $pageId eq 'fws_systemInfo' ) {
                
            my $coreElement;
            if ( !$self->{hideFWSCoreUpgrade} ) {
                $coreElement .= "<br/><input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('This could take several moments after you click ok.";
                $coreElement .= " Do you want to continue?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=installCore';}\" value=\"Install Full Core Element &amp;&nbsp;File Package\"/> ";
                $coreElement .= ' Use for new installs or if your having FWS related javascript errors.';
                $coreElement .= "<div class=\"FWSStatusNote\">".$self->formValue("coreStatusNote")."</div>";
            }



            my $log = "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you clear the FWS log file?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=clearFWSLog';}\" value=\"Clear FWS Log\"/> ";
            my $FWSLogSize = -s $self->{fileSecurePath} . '/FWS.log';
            $log .=  'FWS.Log ' . sprintf( "%0.1f", $FWSLogSize/1000 ). 'K size <a target="_blank" href="' . $self->{scriptName} . $self->{queryHead} . 'p=fws_log&lines=50">View</a>';
            $log .= "<div class=\"FWSStatusNote\">".$self->formValue("logStatusNote")."</div>";


            my %sessionInfo = $self->_sessionInfo();
            my $sess = "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you delete all sessions?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=flushSessions&months=0';}\" value=\"Delete All Sessions\"/> ";
            $sess .= $sessionInfo{total}." sessions total<br/>"; 
            $sess .= "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you delete sessions more than 1 month old?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=flushSessions&months=1';}\" value=\"Delete All Sessions More Than 1 Month Old\"/> ";
            $sess .= $sessionInfo{1}." sessions over 30 days old<br/>";
            $sess .= "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you delete sessions more than 3 months old?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=flushSessions&months=3';}\" value=\"Delete All Sessions More Than 3 Months Old\"/> ";
            $sess .= $sessionInfo{3}." sessions over 90 days old";
            $sess .= "<div class=\"FWSStatusNote\">".$self->formValue("sessionStatusNote")."</div>";

            my $backup;
            $backup = "Backup file name:<br/>";
            $backup .= "<input style=\"width:150px;\" type=\"text\" name=\"backupName\" id=\"backupName\" />";
            $backup .= "<input style=\"width:150px;\" type=\"button\" onclick=\"if(confirm('This could take several minutes depending on the size of your data.";
            $backup .= " Do you want to continue?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . " p=fws_systemInfo&excludeSiteFiles='+document.getElementById('excludeSiteFiles').checked+'&backupName='+escape(document.getElementById('backupName').value)+'&pageAction=FWSBackup';}\" value=\"Backup Now\"/> ";
            $backup .= ' This will make a backup of your FWS Site files,&nbsp;plugins,&nbsp;and database';
            $backup .= "<div class=\"FWSExcludeBackup\"><input type=\"checkbox\" name=\"excludeSiteFiles\" id=\"excludeSiteFiles\" /> Do not backup web accessible site uploaded files</div>";
            $backup .= "<div class=\"FWSStatusNote\">".$self->formValue("backupStatusNote")."</div>";

            $backup .= "Restore file name:<br/>";
            $backup .= "<input style=\"width:150px;\" type=\"text\" name=\"restoreName\" id=\"restoreName\" />";
            $backup .= "<input style=\"width:150px;\" type=\"button\" onclick=\"if(confirm('WARNING!!!  This will ovewrite your database and files.";
            $backup .= " Do you want to continue?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&restoreName='+escape(document.getElementById('restoreName').value)+'&pageAction=FWSRestore';}\" value=\"Restore Now\"/> ";
            $backup .= ' Overwrite your database,&nbsp;files,&nbsp;and plugins with a backup';
            $backup .= "<div class=\"FWSStatusNote\">".$self->formValue("restoreStatusNote")."</div>";

            my $publish = "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you flush your search cache? (Depending on the size of your site this could take several minutes)')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=flushSearchCache';}\" value=\"Rebuild Search Cache\"/>";
            $publish .= " Replace all search cache, and update parent page references. (This will be slow on large sites)<br/>";
            $publish .= "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you flush your web cache?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=flushWebCache';}\" value=\"Flush Web Cache\"/>";
            $publish .= " Remove all combined js and css files, and recreate them as needed.";
            $publish .= "<div class=\"FWSStatusNote\">" . $self->formValue("statusNote") . "</div>";

            #
            # DB Pakckages
            #
            my $dbPackages;
            $dbPackages .= "<table border=\"1\" cellspacing=\"0\" style=\"margin-left:40px;width:90%;".$self->fontCSS()."\">";
            $dbPackages .= "<tr>";
            $dbPackages .= "<th>Module or Element Name</th>";
            $dbPackages .= "<th>Your Version</th>";
            $dbPackages .= "<th>Current Version</th>";
            $dbPackages .= "<th>&nbsp;</th>";
            $dbPackages .= "</tr>";
            $dbPackages .= $self->_packageLine( "US Zip Code Package", ( $self->_versionData( 'local', 'zipcode' ) )[0],( $self->_versionData( 'live', 'zipcode' ) )[0], "fws_installZipcode" );
            $dbPackages .= $self->_packageLine( "Country Package", ( $self->_versionData( 'local', 'country' ) )[0], ( $self->_versionData( 'live', 'country' ) )[0], "fws_installCountry" );
            $dbPackages .= "</table>";


            $pageHTML .= "<div style=\"width:90%;margin:auto;padding:10px;text-align:right;color:#ff0000;\">FrameWork&nbsp;Sites&nbsp;Version&nbsp; " . $self->{FWSVersion} . "</div>";
            $pageHTML .= $self->panel( title => "FWS Installation And Health"      ,content => $self->systemInfo() . $coreElement );
            $pageHTML .= $self->panel( title => "Session Maintenance"              ,content => $sess);
            $pageHTML .= $self->panel( title => "Log Files"                        ,content => $log);
            $pageHTML .= $self->panel( title => "FWS Site Backups"                 ,content => $backup);
            $pageHTML .= $self->panel( title => "Flush Cache Engines"              ,content => $publish);
            $pageHTML .= $self->panel( title => "Core Database Packages"           ,content => $dbPackages);
            $self->siteValue("pageHead","");
            $self->siteValue("pageKeywords","");
            $self->siteValue("pageDescription","");

            $self->printPage( title => "FrameWork&nbsp;Sites&nbsp;Version&nbsp; " . $self->{FWSVersion} . " System Info", content => $pageHTML, head=> $self->_minCSS() );
        }

        #
        # do install subroutines
        #
        if ( $pageId eq 'fws_installCountry' ) { $pageHTML .= $self->_installCountry() }
        if ( $pageId eq 'fws_installZipcode' ) { $pageHTML .= $self->_installZipcode() }

    }

    #
    # Show the admin login if we didn't meet isAdminLoggedIn
    #
    else { $self->displayAdminLogin() }

    return;
}


sub _selfWindow {
    my ( $self, $queryString, $linkHTML, $extraJava ) = @_;
    return "<span style=\"cursor:pointer;\" class=\"FWSAjaxLink\" onclick=\"location.href='" . $self->{scriptName} . $self->{queryHead} . $queryString . "';" . $extraJava . "\">" . $linkHTML . "</span>";
}

sub _isSiteUsed {
    my ( $self, $fieldValue ) = @_;
    my ( $siteUsed ) = @{$self->runSQL( SQL => "select 1 from site where site.sid='" . $self->safeSQL( $fieldValue ) . "'" )};
    if ( $siteUsed ) { return 1 }
    return 0;
}

sub _isValidSID {
    my ( $self, $siteValid ) = @_;
    my $returnStatus;
    if ( $siteValid =~ /[^a-z]/ ) {
        $returnStatus .= "The Site ID must only contain lower case characters without any spaces or symbols. ";
    }
    if ( length( $siteValid ) < 4 && $siteValid ne 'fws' ) {       
        $returnStatus .= "The Site ID must be at least 4 characters long. ";
    }
    if ( length( $siteValid ) > 8 ) {      
        $returnStatus .= "The Site ID must be 8 characters or less. ";
    }
    if ( $self->_isSiteUsed( $siteValid ) && $siteValid &&  $siteValid ne 'fws' ) {
        $returnStatus .= "The Site ID has already been taken. ";
    }
    return $returnStatus;
}
    
sub _processAdminAction {
    my ( $self ) = @_;

    #
    # run FWS Admin lib
    #
    if ( $self->{adminLoginId} ) {
        $self->{FWSAdminLib} ||= 'FWSAdmin_'  . $self->{FWSVersion};
        $self->runScript( $self->{FWSAdminLib} );
    }

    if ($self->userValue( 'isAdmin') || $self->userValue('showDeveloper') || $self->userValue('showDesigner') ) {
        
        if ( $self->formValue( 'pageAction' ) eq "installCore") {
        
            #
            # We only want the end part of the package for the file name
            #
            my $distFile     = 'V2.pm';
            my $newV2File    = $self->{fileSecurePath} . "/FWS/" . $distFile;
        
            #
            # get the stuff ready for the backup copy info
            #
            require File::Copy;
            File::Copy->import();
            my $currentTime = $self->formatDate( format => 'number' );
        
            $self->FWSLog("Backing up FWS core: " . $newV2File . " - Backup File Is Now: " . $newV2File . "." . $currentTime);
            copy( $newV2File, $newV2File . "." . $currentTime );

            my ( $updateString, $majorVer, $minorVer, $build ) = $self->_versionData( 'live', 'core', 'fws_installCore' );

            #
            # set the base URL for where the dist files are pulled from
            #
            my $imageBaseURL = $self->{FWSServer} . '/fws_' . $majorVer;

            #
            # get the core Script
            #
            if ( $self->_pullDistFile( $imageBaseURL . '/current_frameworksitescom.pm', $self->{fileSecurePath} . '/FWS', $distFile, "package FWS::V2;\n" ) ) {
                
                #
                # import the new core admin
                #
                $self->_importAdmin( 'current_core' );
                $self->FWSLog( 'FWS core element packages updated' );
                $self->formValue( 'coreStatusNote', 'Current FWS Core element and file packages has been updated' );
               
                #
                # flg our sucess swo we can save versionData
                # 
                $self->_versionData( 'live', 'core', 'fws_installCore', 1 );

                #
                # add the fwsdemo files if they are not there already
                #
                my $demoFile =  $self->{fileSecurePath} . '/backups/fwsdemo';
                if ( !-e $demoFile . '.sql' ) {
                    $self->_pullDistFile( $imageBaseURL . '/fwsdemo.sql', $self->{fileSecurePath} . '/backups', 'fwsdemo.sql', '' );
                }
                if ( !-e $demoFile . '.files' ) {
                    $self->_pullDistFile( $imageBaseURL . '/fwsdemo.files', $self->{fileSecurePath} . '/backups', 'fwsdemo.files', '' );
                }
               
                #
                # delete cache directory
                #
                $self->flushWebCache();

                #
                # get rid of any orphaned data from the install process
                #
                $self->_deleteOrphanedData( "data", 'guid', "guid_xref", "child");

                #
                # if there is no elements on the site yet lets install our demo site
                #
                if ( !@{$self->runSQL( SQL => "select 1 from data where site_guid not like 'f%' and guid not like 'h%'" )} ) {
                    $self->restoreFWS( id => 'fwsdemo' );
                    print "Status: 302 Found\n";
                    print "Location: " .  $self->{scriptName} . "\n\n";

                }
            }
        }
    }        

    return;    
}

sub _pullDistFile {
    my ( $self, $imageURL, $directory, $distFile, $preContent ) = @_;

    require LWP::UserAgent;
    my $browser = LWP::UserAgent->new();
    my $response = $browser->get( $imageURL );
    if (!$response->is_success ) {
        $self->FWSLog( "FWS server connection error: " . $response->status_line );
        $self->formValue( 'coreStatusNote', "A network error in connecting to FWS Server:" . $response->status_line );
        return 0;
    }

    #
    # we got it! lets save it
    #
    $self->makeDir( $directory );
    open ( my $FILE, ">", $directory . '/' . $distFile );
    print $FILE $preContent . $response->content;
    close $FILE;
        
    $self->FWSLog( "FWS secure distributed file saved: " . $directory . '/' . $distFile );
    return 1;
}

#
# easy reuse optoin sub for the fws_data_edit
#
sub _createOptionGroup {
    my ( $self, $optLabel, $ordMin, $ordMax, %elementHash ) = @_;

    #
    # for elements in there twice because they are present via the guid, and the elementType lets hold a hash so we don't dup them
    #
    my %elementDisplayed; 
    my $optionFullHTML = "<optgroup label=\"" . $optLabel . "\">";
    for my $guid ( sort { $elementHash{$a}{alphaOrd} <=> $elementHash{$b}{alphaOrd} } keys %elementHash) {
        if ( !$elementDisplayed{$elementHash{$guid}{guid}} && ( !$elementHash{$guid}{parent} || $elementHash{$guid}{rootElement} ) && $elementHash{$guid}{ord} > $ordMin && $elementHash{$guid}{ord} <= $ordMax ) {
            $optionFullHTML .= "<option value=\"" . $guid . "\">" . $elementHash{$guid}{title} . "</option>";
            
            #
            # set the flag that we have seen this one aready,  we don't need two of them!
            #
            $elementDisplayed{$elementHash{$guid}{guid}} = 1;
        }
    }
    $optionFullHTML .= "</optgroup>";
    return $optionFullHTML;
}

sub _packageLine {
    my ( $self, $name, $currentVer, $newVer, $script ) = @_; 
    my $line    = "<tr>";
    my $upText  = "Upgrade";

    if ( !$currentVer ) {           $currentVer = "Not Installed"; $upText = "Install" }
    if ( $currentVer eq $newVer ) { $upText = "Re-Install" }
    $line .= "<td>" . $name . "</td>";

    $line .= "<td style=\"text-align:center;width:200px;\">" . $currentVer . "</td>";
    $line .= "<td style=\"text-align:center;width:200px;\">" . $newVer . "</td>";  
    $line .= "<td style=\"text-align:center;width:100px;\"><a href=\"" . $self->{scriptName} . $self->{queryHead} . "p=" . $script . "\">" . $upText . "</a>"; 
    $line .= "</tr>";
    return $line;
}


sub _checkScript {
    my ( $self, $moduleName ) = @_;
    my $errorReturn;

    if ( !$self->{FWSScriptCheck}->{registerPlugins} ) { $errorReturn .= '<li>Your script file is missing $fws->registerPlugins(); this should be added.</li>' }

    if ( $errorReturn ) { $errorReturn = '<ul>' . $errorReturn . '</ul>' }
    return $errorReturn;
}



sub _checkIfModuleInstalled {
    my ( $self, $moduleName ) = @_;
    my $errorReturn;

    ## no critic
    eval "use " . $moduleName;
    ## use critic

    if ( $@ ) { 
        my $bump;
        if ($moduleName eq "Google::SAML::Response") {  $bump = $moduleName . " is used for Single Sign On Google Apps integration.  If your not using this website for Google SSO then you will not need this." }
        if ($moduleName eq "Crypt::SSLeay") {           $bump = $moduleName . " is used for secure transactions to payment gateways.  If your not using eCommerce real time payment gateways this module may not be necessary." }
        if ($moduleName eq "Captcha::reCAPTCHA") {      $bump = $moduleName . " is used for captcha support.  If you are not using captchas for human form postings validation then this is not required." }
        if ($moduleName eq "Crypt::Blowfish") {         $bump = $moduleName . " is used to encrypt tranasactional data.  If your not using eCommerce real time payment gateways this module may not be necessary." }
        $errorReturn .= "<ul><li>" . $moduleName . " Perl module missing.  Your site may not run correctly without it. " . $bump . "<br/><br/><ul><li>To install it if you have shell access you can do the following:<br/>server prompt> cpan<br/>CPAN> install " . $moduleName . "<br/><i>Note: You must be logged in as root to use cpan, if you are unfamiliar with using cpan it might be best to have a system adminstrator do this for you.</i></li><li>To install it from CPanel do the following:<br/>Perl Modules -> Install a Perl Module: " . $moduleName . "</li><li>If these methods are unavailable you may need your server administrator to install it for you.</li></ul></li></ul><br/>" }

    return $errorReturn;
}

sub _systemInfoCheckDir {
    my ( $self, $newDir ) = @_;

    my $errorReturn;
    my $documentRoot     = $ENV{DOCUMENT_ROOT};
    my $scriptFilename   = $ENV{SCRIPT_FILENAME};

    if ( !-e $newDir ) {
        if ( $newDir =~ /\/fws/ ) {
            if ( !$self->{hideFWSCoreUpgrade} ) {
                $errorReturn .= "Your core element and file package is not installed yet.<br/>";
                $errorReturn .= '<a href="' . $self->{scriptName} . '?p=fws_systemInfo&pageAction=installCore">Click here to install your core element and file package</a><br/>';
                $errorReturn .= '<i>Depending on your connection speed and server performance, your page may take a few minutes to load after clicking the link below.</i>';
            }
        }
        else {
            $errorReturn .= "<ul><li>The directory '" . $newDir . "' does not exist";
            $self->makeDir( $newDir );
            if ( !-e $newDir ) {
                $errorReturn .= ". The webserver does not have permissions to create this directory.<br/>Create this directory by hand, and make it web server writable.  <ul><li>Sometimes large ISP might have complex directories.  Usually it will match in part with one of these, but not always:<br/>Document Root: " . $documentRoot . "<br/>Script Root Path: " . $scriptFilename . "</li><li>You can change your file permissions from your server console using: chmod 755 " . $newDir . "<br/>This can also be done though web based server administration programs or even FTP if your security settings will allow it.</li></ul>";
            }
            else {
                $errorReturn .= ',&nbsp;but was created automaticly.</br> <a href="' . $self->{scriptName} . '?p=fws_systemInfo">Click here to continue system health check</a>';
            }
        }
        $errorReturn .= "</li></ul><br/>";
    }
    else {
        if ( !$self->_testDirWritePermission( $newDir ) ) {
            $errorReturn .= "<ul><li>The directory '" . $newDir . "' is not web server writable.<br/>";
            $errorReturn .= "<ul><li>Usually this means changing your file permissions for this directly using: chmod 755 " . $newDir . "</li><li>chmod style permissions can also be done though web based server administration programs or even FTP if your security settings will allow it.</li><li>Some configurations my require an administrator to change the ownership of this directory to the webserver by using: chown nobody:nobody " . $newDir . " ('nobody:nobody' is a default web server user and group, it could be 'www:www' or something different)</li></ul>";
        $errorReturn .= "</li></ul><br/>";
        }
    }
    return $errorReturn;
}

sub _testDirWritePermission {
    my ( $self, $testFile ) = @_;
    $testFile .= "/testfile.tmp";
    open ( my $FILE, ">", $testFile );
    print $FILE "TEST FILE";
    close $FILE;
    if ( -e $testFile ) { 
        unlink $testFile;
        return 1;
    }
    return 0;
}

sub _sessionInfo {
    my ( $self, %paramHash ) = @_;
    my %returnHash;
    ( $returnHash{total} ) =  @{$self->runSQL( SQL => "select count(1) from fws_sessions" )};
    ( $returnHash{1} ) =      @{$self->runSQL( SQL => "select count(1) from fws_sessions where created < '" . $self->formatDate( format => 'SQL', monthMod=>-1 ) . "'" )};
    ( $returnHash{3} ) =      @{$self->runSQL( SQL => "select count(1) from fws_sessions where created < '" . $self->formatDate( format => 'SQL', monthMod=>-3 ) . "'" )};
    return %returnHash;
}


sub _importAdmin {
    my ($self,$adminFile) = @_;
    my $removeCore = 0;
    my $keepAlive = 500;
    if ( $adminFile eq 'current_core' ) { 
        $removeCore = 1;
        $keepAlive  = 0;
    }
    return $self->importSiteImage( 
        newSID      => "fws",
        imageURL    => "http://www.frameworksites.com/downloads/fws_" . $self->{FWSVersion} . "/" . $adminFile . ".fws",
        removeCore  => $removeCore,
        parentSID   => "admin",
        keepAlive   => $keepAlive,
    );
}


sub _installZipcode {
    my ( $self ) = @_;

    #
    # make stdout hot! and start sending to browser
    #
    local $| = 1;
    print $self->_installHeader( 'Zipcode' );

    $self->runSQL(SQL=>"delete from zipcode");  

    print "<br/>Downloading and Installing";
    
    my $importReturn = $self->_importAdmin( 'current_zipcode' );
    
    print "<br/>" . $importReturn;

    print $self->_installFooter( 'Zipcode' );
    
    if ( $importReturn !~ /error/i ) { $self->_versionData( 'live', 'zipcode', "fws_installZipcode", 1 ) }
       
    $self->{stopProcessing} = 1;

    return;
}
    
sub _installCountry {
    my ( $self ) = @_;
    
    #
    # make stdout hot! and start sending to browser
    #
    local $| = 1;
    print $self->_installHeader( 'Country' );
    
    $self->runSQL( 'delete from country' );
    
    print "<br/>Downloading and Installing";

    my $importReturn = $self->_importAdmin( 'current_country' );
    
    print $self->_installFooter( 'Country' );
    
    if ( $importReturn !~ /error/i ) { $self->_versionData( 'live', 'country', "fws_installCountry", 1 ) }
    
    $self->{stopProcessing} = 1;

    return;
}

sub _installHeader {
    my ( $self, $name ) = @_;
    return "Content-Type: text/html; charset=UTF-8\n\n<html><head><title>Installing New " . $name . " Package</title>" . 
    "</head>".
    "<body><h2>Installing New " . $name . " Package</h2><br/>".
    "<b>" . $name . " Package</b><hr/>".
    "Doing pre install cleanup";
}

sub _installFooter {
    my ( $self, $name ) = @_;
    return "<br/><br/>Finished: <a href=\"" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo\">Click here to continue</a></body></html>";
}

=head2 uploadSiteFile

Execute a file upload from a form post.

=cut

sub uploadSiteFile {
    my ( $self, %paramHash ) = @_;

    #
    # move the passed vars into regular vars because we might want to use this paramHash to do a saveData
    # and don't want any relics
    #
    my $secureFile          = $paramHash{FWSSecureFile};
    my $uploadFileField     = $paramHash{FWSUploadFileField};
    my $uploadField         = $paramHash{FWSUploadField};
    delete $paramHash{FWSUploadFileField};
    delete $paramHash{FWSUploadField};
    delete $paramHash{FWSSecureFile};

    #
    # get the file name and also name the "name" file that.  The "name" could be
    # replaced with the name extField if it is not blank.  But this will ensure
    # that the name is populated with at least something
    #
    my @fileArray = $self->formValue( $uploadFileField );

    #
    # set site guid if it wasn't passed
    #
    $paramHash{siteGUID} ||= $self->{siteGUID};

    #
    # process each one (I think this doesn't actually send more than one because of the uploader we use
    # , but hey, might as well!
    #
    foreach my $fileHandle ( @fileArray ) {

        my $runFileCleanup = 0;

        #
        # clean up the file name, and make sure the dirs are safe before we do anything with them
        #
        $paramHash{name}  = $self->justFileName( $self->formValue( $uploadFileField ) );
        $paramHash{name}  = $self->safeDir( $paramHash{name} );

        #
        # we have a parent... but we don't ahve a guid, this is a subrecord
        #
        if ( $paramHash{parent} && !$paramHash{guid} ) {
            #
            # save the record so we have a guid
            #
            %paramHash = $self->saveData( %paramHash );

            #
            # now that we know the guid, lets set the file name
            #
            $paramHash{$uploadField}    = $self->{fileWebPath} . '/' . $self->{siteGUID} . '/' . $paramHash{guid} . '/' . $paramHash{name};
            %paramHash                  = $self->saveData(%paramHash);

            #
            # because we are saving a record lets flag this so we do image cleanup at the end
            #
            $runFileCleanup = 1;
        }

        #
        # set the directory
        #
        my $directory = '/' . $paramHash{siteGUID} . '/' . $paramHash{guid} . '/';
        if ( $secureFile ) { $directory = $self->{fileSecurePath} . '/files/' . $directory }
        else { $directory = $self->{filePath} . $directory }
        $directory = $self->safeDir( $directory );

        #
        # make the directory if its not already there
        #
        $self->makeDir( $directory );
        $self->uploadFile( $directory, $fileHandle, $paramHash{name} );

        #
        # comptabality keys to match those in fileArray
        #
        $paramHash{fullFile} = $directory . '/' . $paramHash{name};
        $paramHash{file} = $paramHash{name};

        #
        # if we are adding new records redo any of the image thumbs and such and lets delete the guid so we can get a fresh one if there is another pass
        #
        if ( $runFileCleanup ) {
            $self->createSizedImages( guid => $paramHash{guid} );
            delete $paramHash{guid};
        }
    }
    return %paramHash;
}

sub _convertImportTags {
    my ( $self, %paramHash ) = @_;

    my $conversionString    = $paramHash{content};
    my $siteGUID            = $paramHash{siteGUID};
    my $scriptName          = $self->{scriptName};
    my $domain              = $self->{domain};
    my $secureDomain        = $self->{secureDomain};
    my $fileWebPath         = $self->{fileWebPath};

    #
    # clean and format the data from the import storage
    #
    $conversionString =~ s/#FWSSiteGUID#/$siteGUID/sg;
    $conversionString =~ s/#FWSDomain#/$domain/sg;
    $conversionString =~ s/#FWSScriptName#/$scriptName/sg;
    $conversionString =~ s/#FWSSecureDomain#/$secureDomain/sg;
    $conversionString =~ s/#FWSFileWebPath#/$fileWebPath/sg;
    return $conversionString;
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Admin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FWS-V2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FWS-V2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FWS-V2>

=item * Search CPAN

L<http://search.cpan.org/dist/FWS-V2/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::Admin
