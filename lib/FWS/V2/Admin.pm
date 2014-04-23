package FWS::V2::Admin;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';

=head1 NAME

FWS::V2::Admin - Framework Sites version 2 internal administration

=head1 VERSION

Version 1.14042309

=cut

our $VERSION = '1.14042309';


=head1 SYNOPSIS

    use FWS::V2;

    #
    # Create $self
    #
    my $self = FWS::V2->new();


=head1 DESCRIPTION

These methods are used by the FWS to perform web based admin features.  Most methods here are not for general use and can change at any time, reference these in plugins and element for experimental reasons only.

=cut


=head1 METHODS

These modules are used for FWS admin display and logic.   They should not be used outside of the context of FWS admin modules specific to the current build.

=cut


=head2 runAdminAction

Run admin actions to do the initial install or reinstall of core FWS package.

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
    my ( $self ) = @_;

    my $loginForm = '<div class="container"><form class="form-inline well" style="margin:auto;margin-top:40px;text-align:center;min-height:170px;max-width:550px;">';
    $loginForm .= '<h2 style="padding-bottom:20px;">' . $self->frameworkSites() . '</h2>';
    $loginForm .= '<input name="bs" type="text" class="input-large input-block-level" value="' . $self->formValue( 'bs_hold' ) . '" placeholder="User Name">';
    $loginForm .= ' <input type="password" name="l_password" class="input-large input-block-level" placeholder="Password">';
    $loginForm .= ' <button class="btn btn-primary" type="submit">Sign in</button>';
    $loginForm .= '<input type="hidden" class="name="p" value="' . $self->{adminURL} . '"/>';
    $loginForm .= '<input type="hidden" name="session" value="' . $self->formValue( 'session' ) . '"/>';
    $loginForm .= '<input type="hidden" name="id" value="' . $self->safeQuery( $self->formValue( 'id' ) ) . '"/>';
    $loginForm .= '<input type="hidden" id="s" name="s" value="' . $self->formValue( 's' ) . '"/>';
    if ( $self->formValue( 'statusNote' ) ) {
        $loginForm .= '<div style="margin:auto;width:450px;margin-top:20px;" class="alert alert-error">' . $self->formValue( 'statusNote' ) . '</div>';
    }
    $loginForm .= '</form></div>';

    return $self->printPage ( content => $loginForm, head => $self->_bootstrapCDN() );
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
        if (!$response->is_success ) { return "Error connecting to the FWS Server was found: " . $response->status_line }
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
                    if ( ( $tableName ne 'element' && $self->formValue( 'elementOnly' ) ) ) {
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
    $errorReturn;
    $systemInfo .= '<h3>File directory check:</h3>';
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
    $systemInfo .= '<h3>Perl module check:</h3>';
    $errorReturn .= $self->_checkIfModuleInstalled( 'Captcha::reCAPTCHA' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'MIME::Base64' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'CGI::Carp' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'File::Copy' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'File::Find' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'Time::Local' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'File::Path' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'LWP::UserAgent' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'Crypt::SSLeay' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'Crypt::Blowfish' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'GD' );
    if ( !$errorReturn ) { $systemInfo .= '<ul><li>All required Perl modules are present.</li></ul>' }    
    else { $systemInfo .= $errorReturn }
    
    #
    # run go file checks
    #
    $errorReturn = '';
    $systemInfo .= '<h3>Script compatibility check:</h3>';
    $errorReturn .= $self->_checkScript();
    if ( !$errorReturn ) { $systemInfo .= '<ul><li>All script compatability checks passed.</li></ul>' }
    else { $systemInfo .= $errorReturn  }


    #
    # Database Checks
    #
    $systemInfo .= '<h3>Database table and index check:</h3>';
    $errorReturn = $self->updateDatabase();
    if ( !$errorReturn ) { 
        $systemInfo .= '<ul><li>All tables and indexes are correct.</li></ul>'; 
    }
    else {
        # 
        # Pretty it up
        # 
        $errorReturn =~ s/;/;<\/li><li>/sg;
        $systemInfo .= '<ul><li>' . $errorReturn . '<div class="alert alert-error">The above statments were run to correct database schema</div></li></ul>'; 
    }

    return $systemInfo;
}


=head2 editBox

Placeholder for editBox() until the admin element brings one in.

=cut

sub editBox {    
    my ( $self, %editHash ) = @_;
    return $editHash{editBoxContent} . $editHash{editBox};
}

 
=head2 FWSMenu

Placeholder for FWSMenu() until the admin element brings one in.

=cut

sub FWSMenu {
    my ( $self, %paramHash ) = @_;

    return $self->_bootstrapCDN() . 
        '<div class="container"><div class="hero-unit">' . 
        '<h1>Welcome to FrameWork Sites!</h1>' .
        '<p>First thing your going to need is a way to access your installation.   This will install a default site, give you access to install plugins, and everything else you will need to get going.</p>' . 
        '<p><a href="' . $self->{scriptName} . $self->{queryHead} . 'p=fws_systemInfo&pageAction=installCore" class="btn btn-primary btn-large">Install Default Admin Package</a></p>' .
        '</div>';
        '</div>';

}


=head2 displayAdminPage

Run the lookup and display admin pages wrapped in security check.   This also shows fws_systemInfo and fws_health.

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
                        $valueHash{elementWebPath}  = $self->fileWebPath() . '/' . $elementHash{siteGUID} . '/' . $valueHash{elementId};
    
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
        if ( $pageId eq 'fws_systemInfo' || $pageId eq 'fws_health' ) {

            $pageHTML .= '<div class="container"><div class="hero-unit">';
            $pageHTML .= '<h1>FrameWork Sites Installation Health</h1>';

            if ( !$self->{hideFWSCoreUpgrade} ) {
                $pageHTML .= '<p>Reinstalling your admin package can be used to correct some errors.</p>';
                $pageHTML .= '<p><a href="' . $self->{scriptName} . $self->{queryHead} . 'p=fws_systemInfo&pageAction=installCore" class="btn btn-primary btn-large">Reinstall default admin package from frameworksites.com</a></p>';
                if ( $self->formValue("coreStatusNote") ) {
                    $pageHTML .= '<div class="alert alert-info">' .  $self->formValue("coreStatusNote") . '</div>';
                }
            }
                
            $pageHTML .= '<br/>' . $self->systemInfo();
            $self->siteValue( 'pageHead', '' );
            $self->siteValue( 'pageKeywords', '' );
            $self->siteValue( 'pageDescription', '' );

            $self->printPage( title => 'FrameWork&nbsp;Sites&nbsp;Version&nbsp; ' . $self->{FWSVersion} . ' System Info', content => $pageHTML, head => $self->_bootstrapCDN() );
            $pageHTML .= '</div></div>';
        }

    }

    #
    # Show the admin login if we didn't meet isAdminLoggedIn
    #
    else { $self->displayAdminLogin() }

    return;
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
    # run FWS Admin lib or the default one
    #
    if ( $self->{adminLoginId} ) {

        #
        # make sure this is here in the least
        #
        if ( !-e $self->{fileSecurePath} . '/plugins/FWSAdmin2.pm' ) {
            my ( $updateString, $majorVer, $minorVer, $build ) = $self->_versionData( 'live', 'core', 'fws_installCore' );

            #
            # set the base URL for where the dist files are pulled from
            #
            my $imageBaseURL = $self->{FWSServer} . '/fws_' . $majorVer;

            $self->_pullDistFile( $imageBaseURL . '/FWSAdmin2.pm', $self->{fileSecurePath} . '/plugins/', 'FWSAdmin2.pm', '' );
        }

        $self->runScript( $self->{FWSAdminLib}  || 'FWSAdmin2' );
    }

    if ( $self->userValue( 'isAdmin' ) ) {

        #
        # this is used to save elements that actually do the element saving
        # if you call itself when you try to save yourself it would recurse!
        #
        if ( $self->formValue( 'pageAction' ) eq 'forceUpdateScript' ) {
            my %valueHash;
            my $script = $self->safeSQL( $self->formValue( "script" ) );
            $self->runSQL( SQL => "update element set script_devel='" . $self->safeSQL( $self->formValue( "script" ) ) . "' where guid='" . $self->safeSQL( $self->formValue( 'guid' ) )  . "'" );
            $self->printPage( content => '<div style="padding:20px;">Script was force saved.  This is used to save the script that saves scripts.  No JS, or CSS was saved and no sanity check was made. </div>' );
        } 
        
        if ( $self->formValue( 'pageAction' ) eq "installCore") {
        
            #
            # set the base URL for where the dist files are pulled from
            #
            my ( $updateString, $majorVer, $minorVer, $build ) = $self->_versionData( 'live', 'core', 'fws_installCore' );
            my $imageBaseURL = $self->{FWSServer} . '/fws_' . $majorVer;

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



            #
            # get the core Script
            #
            if ( $self->_pullDistFile( $imageBaseURL . '/current_frameworksitescom.pm', $self->{fileSecurePath} . '/FWS', $distFile, "package FWS::V2;\n" ) ) {
                
                #
                # add the fwsdemo files if they are not there already
                #
                my $demoFile        = $self->{fileSecurePath} . '/backups/fwsdemo';
                my $FWSAdminPlugin  = $self->{fileSecurePath} . '/backups/FWSAdmin2.pm';
                if ( !-e $demoFile . '.sql' ) {
                    $self->_pullDistFile( $imageBaseURL . '/fwsdemo.sql', $self->{fileSecurePath} . '/backups', 'fwsdemo.sql', '' );
                }
                if ( !-e $demoFile . '.files' ) {
                    $self->_pullDistFile( $imageBaseURL . '/fwsdemo.files', $self->{fileSecurePath} . '/backups', 'fwsdemo.files', '' );
                }
                if ( !-e $FWSAdminPlugin ) {
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
                
                #
                # import the new core admin
                #
                $self->_importAdmin( 'current_core' );
                $self->FWSLog( 'FWS core element packages updated' );
                $self->formValue( 'coreStatusNote', 'Current FWS Core element and file packages has been updated' );
               
                #
                # flag our success so we can save versionData
                # 
                $self->_versionData( 'live', 'core', 'fws_installCore', 1 );
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

sub _checkScript {
    my ( $self, $moduleName ) = @_;
    my $errorReturn;

    if ( !$self->{FWSScriptCheck}->{registerPlugins} ) { $errorReturn .= '<li>Your script file is missing $self->registerPlugins(); this should be added.</li>' }

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
#        if ($moduleName eq "Google::SAML::Response") {  $bump = $moduleName . " is used for Single Sign On Google Apps integration.  If your not using this website for Google SSO then you will not need this." }
        if ($moduleName eq "Crypt::SSLeay") {           $bump = $moduleName . " is used for secure transactions to payment gateways.  If your not using eCommerce real time payment gateways this module may not be necessary." }
        if ($moduleName eq "Captcha::reCAPTCHA") {      $bump = $moduleName . " is used for captcha support.  If you are not using captchas for human form postings validation then this is not required." }
        if ($moduleName eq "Crypt::Blowfish") {         $bump = $moduleName . " is used to encrypt tranasactional data.  If your not using eCommerce real time payment gateways this module may not be necessary." }
        $errorReturn .= "<ul><li>" . $moduleName . " Perl module missing.  Your site may not run correctly without it. " . $bump . "<br/><br/><ul><li>To install it if you have shell access you can do the following:<br/>server prompt> cpan<br/>CPAN> install " . $moduleName . "<br/><i>Note: You must be logged in as root to use cpan, if you are unfamiliar with using cpan it might be best to have a system adminstrator do this for you.</i></li><li>To install it from CPanel do the following:<br/>Perl modules -> Install a Perl module: " . $moduleName . "</li><li>If these methods are unavailable you may need your server administrator to install it for you.</li></ul></li></ul>" }

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
        $errorReturn .= "</li></ul>";
    }
    else {
        if ( !$self->_testDirWritePermission( $newDir ) ) {
            $errorReturn .= "<ul><li>The directory '" . $newDir . "' is not web server writable.<br/>";
            $errorReturn .= "<ul><li>Usually this means changing your file permissions for this directly using: chmod 755 " . $newDir . "</li><li>chmod style permissions can also be done though web based server administration programs or even FTP if your security settings will allow it.</li><li>Some configurations my require an administrator to change the ownership of this directory to the webserver by using: chown nobody:nobody " . $newDir . " ('nobody:nobody' is a default web server user and group, it could be 'www:www' or something different)</li></ul>";
        $errorReturn .= "</li></ul>";
        }
    }
    return $errorReturn;
}

sub _testDirWritePermission {
    my ( $self, $testFile ) = @_;
    $testFile .= '/testfile.tmp';
    open ( my $FILE, '>', $testFile );
    print $FILE 'TEST FILE';
    close $FILE;
    if ( -e $testFile ) { 
        unlink $testFile;
        return 1;
    }
    return 0;
}

sub _importAdmin {
    my ($self,$adminFile) = @_;
    my $removeCore = 0;
    my $keepAlive = 500;
    if ( $adminFile eq 'current_core' ) { 
        $removeCore = 1;
        $keepAlive  = 0;
    }

    #
    # this is where it core comes from
    #
    my ( $updateString, $majorVer, $minorVer, $build ) = $self->_versionData( 'live', 'core', 'fws_installCore' );
    my $imageBaseURL = $self->{FWSServer} . '/fws_' . $majorVer;

    #
    # get the newest plugin for FWSAdmin2
    #
    $self->_pullDistFile( $imageBaseURL . '/FWSAdmin2.pm', $self->{fileSecurePath} . '/plugins/', 'FWSAdmin2.pm', '' );

    #
    # get the rest of the image
    #
    return $self->importSiteImage(
        newSID      => 'fws',
        imageURL    => $imageBaseURL . '/' . $adminFile . '.fws',
        removeCore  => $removeCore,
        parentSID   => 'admin',
        keepAlive   => $keepAlive,
    );

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

sub _bootstrapCDN {
    return  '<link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/css/bootstrap-combined.min.css" rel="stylesheet">';
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
