package FWS::V2::Database;

use 5.006;
use strict;

=head1 NAME

FWS::V2::Database - Framework Sites version 2 data management

=head1 VERSION

Version 0.005

=cut

our $VERSION = '0.005';


=head1 SYNOPSIS

	use FWS::V2;

        #
        # Create FWS with MySQL connectivity
        #
        my $fws = FWS::V2->new(       DBName          => "theDBName",
                                      DBUser          => "myUser",
                                      DBPassword      => "myPass");

        #
        # create FWS with SQLite connectivity
        #
        my $fws2 = FWS::V2->new(      DBType          => "SQLite",
                                      DBName          => "/home/user/your.db");



=head1 DESCRIPTION

Framework Sites version 2 common methods that connect, read, write, reorder or alter the database itself.


=head1 METHODS

=head2 addExtraHash

In FWS database tables there is a field named extra_value.  This field holds a hash that is to be appended to the return hash of the record it belongs to.
        
	#
        # If we have an extra_value field and a real hash lets combine them together
        #
        %dataHash = $fws->addExtraHash($extra_value,%dataHash);

Note: If anything but stored extra_value strings are passed, the method will throw an error

=cut


sub addExtraHash {
        my ($self,$extraValue,%addHash) = @_;

        #
        # lets use storable in comptabile nfreeze mode
        #
        use Storable qw(nfreeze thaw);

        #
        # pull the hash out
        #
        my %extraHash;

        #
        # only if its populated unthaw it
        #
        if ($extraValue ne '') { %extraHash = %{thaw($extraValue)} }

        #
        # return the two hashes combined together
        #
        my %mergedHash = (%addHash,%extraHash);
        return %mergedHash;
}

=head2 adminUserArray

Return an array of the admin users.   The hash array will contain name, userId, and guid.

        #
        # get a reference to the hash array
        #
        my $dataArrayRef = $fws->adminUserArray(ref=>1);

=cut

sub adminUserArray {
        my ($self,%paramHash) = @_;
        my @userHashArray;

        #
        # get the data from the database and push it into the hash array
        #
        my $adminUserArray = $self->runSQL(SQL=>"select name,user_id,guid from admin_user");
        while (@$adminUserArray) {
                #
                # assign the data to variables: Perl likes it done this way
                #
                my %userHash;
                $userHash{'name'}              = shift(@$adminUserArray);
                $userHash{'userId'}            = shift(@$adminUserArray);
                $userHash{'guid'}              = shift(@$adminUserArray);

                #
                # push it into the array
                #
                push (@userHashArray,{%userHash});
        }
        if ($paramHash{'ref'} eq '1') { return \@userHashArray } else {return @userHashArray }
}


=head2 adminUserHash

Return an array of the admin users.   The hash array will contain name, userId, and guid.

        #
        # get a reference to the hash
        #
        my $dataHashRef = $fws->adminUserHash(guid=>'someGUIDOfAnAdminUser',ref=>1);

=cut

sub adminUserHash {
        my ($self,%paramHash) = @_;
        my $extArray            = $self->runSQL(SQL=>"select extra_value,'email',email,'userId',user_id,'name',name from admin_user where guid='".$self->safeSQL($paramHash{'guid'})."'");
        my $extraValue          = shift(@$extArray);
        my %adminUserHash       = @$extArray;
        %adminUserHash          = $self->addExtraHash($extraValue,%adminUserHash);
        if ($paramHash{'ref'} eq '1') { return \%adminUserHash } else {return %adminUserHash }
}

=head2 alterTable

It is not recommended you would use the alterTable method outside of its intended core database creation and maintenance routines but is here for completeness.  Some of the internal table definitions alter data based on its context and will be unpredictable.  For work with table structures not directly tied to the FWS 2 core schema, use FWS::Lite in a non web rendered script.

        #
        # retrieve a reference to an array of data we asked for
        #
        # Note: It is not recommended to change the data structure of
        # FWS default tables
        #
        print $fws->alterTable( table   =>"table_name",         # case sensitive table name
                                field   =>"field_name",         # case sensitive field name
                                type    =>"char(255)",          # Any standard cross platform type
                                key     =>"",                   # MUL, PRIMARY KEY, FULL TEXT
                                default =>"");                  # '0000-00-00', 1, 'this default value'...

=cut

sub alterTable {
        my ($self, %paramHash) =@_;

	#
	# because this is only called interanally and all data is static and known, we can be a little laxed on safety
	# there is no need to wrapper everything in safeSQL - even so in the context of some parts here we actually
	# might even been adding tics out of place on purpose.
	#

        #
        # set some vars we will flip depending on db type alot is defaulted to mysql, because that
        # is the norm, we will groom things that need to be groomed
        #
        my $sqlReturn;
        my $autoIncrement       = "AUTO_INCREMENT ";
        my $indexStatement      = "alter table ".$paramHash{'table'}." add INDEX ".$paramHash{'table'}."_".$paramHash{'field'}." (".$paramHash{'field'}.")";

        #
        # if default is timestamp lets not put tic's around it
        #
        if ($paramHash{'default'} ne 'CURRENT_TIMESTAMP') { 
		$paramHash{'default'} =
                                                "'".
                                                $paramHash{'default'}.
                                                "'" }

        my $addStatement        = "alter table ".$paramHash{'table'}." add ".$paramHash{'field'}." ".$paramHash{'type'}." NOT NULL default ".$paramHash{'default'};
        my $changeStatement     = "alter table ".$paramHash{'table'}." change ".$paramHash{'field'}." ".$paramHash{'field'}." ".$paramHash{'type'}." NOT NULL default ".$paramHash{'default'};


        #
        # add primary key if the table is not an ext field
        #
        my $primaryKey = "PRIMARY KEY";

        #
        # show tables statement
        #
        my $showTablesStatement = "show tables";

        #
        # do SQLLite changes
        #
        if ($self->{'DBType'} =~ /^sqlite$/i) {
                $autoIncrement = "";
                $indexStatement = "create index ".$paramHash{'table'}."_".$paramHash{'field'}." on ".$paramHash{'table'}." (".$paramHash{'field'}.")";
                $showTablesStatement = "select name from sqlite_master where type='table'";
        }


        #
        # do mySQL changes
        #
        if ($self->{'DBType'} =~ /^mysql$/i) {
                if ($paramHash{'key'} eq 'FULLTEXT') {
                        $indexStatement = "create FULLTEXT index ".$paramHash{'table'}."_".$paramHash{'field'}." on ".$paramHash{'table'}." (".$paramHash{'field'}.")";
                }
        }

  	#
        # FULTEXT is MUL if not mysql, and mysql returns them as MUL even if they are full text so we don't need to updated them if they are set to that
        # so lets change it to MUL to keep mysql and other DB's without FULLTEXT syntax happy
        #
        if ($paramHash{'key'} eq 'FULLTEXT') { $paramHash{'key'} = 'MUL' }

        #
        # blank by default because we use guid - enxt if we are trans we need order ids for easy to read transactions
        #
        my $idField = '';
        if ($paramHash{'table'} eq 'trans') { $idField = ", id INTEGER ".$autoIncrement.$primaryKey }

        #
        # if its the sessions table make it like this
        #
        if ($paramHash{'table'} eq 'fws_sessions') { $idField = ", id char(50) ".$primaryKey }

        #
        # compile the statement
        #
        my $createStatement = "create table ".$paramHash{'table'}." (site_guid char(36) NOT NULL default ''".$idField.")";

	#
	# For full text searching, we will need to use MyISAM  
	#
        if ($self->{'DBType'} =~ /^mysql$/i) { $createStatement .= " ENGINE=MyISAM" }

        #
        # get the table hash
        #
        my %tableHash;
        my @tableList = @{$self->runSQL(SQL=>$showTablesStatement,noUpdate=>1)};
        while (@tableList) {
                my $fieldInc                       = shift(@tableList);
                $tableHash{$fieldInc} = '1';
        }

        #
        # create tht table if it does not exist
        #
        if ($tableHash{$paramHash{'table'}} ne '1') {
                $self->runSQL(SQL=>$createStatement,noUpdate=>1);
                $sqlReturn .= $createStatement."; ";
        }

        #
        # get the table deffinition hash
        #
        my %tableFieldHash = $self->tableFieldHash($paramHash{'table'});

        #
        # make the field if its not there
        #
        if ($tableFieldHash{$paramHash{'field'}}{"type"} eq "") {
                $self->runSQL(SQL=>$addStatement,noUpdate=>1);
                $sqlReturn .= $addStatement."; ";
        }



        #
        # change the datatype if we are talking about MySQL for now if your SQLite
        # we still have to add support for that
        #
        if ($paramHash{'type'} ne $tableFieldHash{$paramHash{'field'}}{"type"} && $self->{'DBType'} =~ /^mysql$/i) {
                $self->runSQL(SQL=>$changeStatement,noUpdate=>1);
                $sqlReturn .= $changeStatement."; ";
        }

        #
        # set any keys if not the same;
        #
        if ($tableFieldHash{$paramHash{'table'}."_".$paramHash{'field'}}{"key"} ne "MUL" && $paramHash{'key'} ne "") {
                $self->runSQL(SQL=>$indexStatement,noUpdate=>1);
                $sqlReturn .=  $indexStatement."; ";
        }

        return $sqlReturn;
}


=head2 connectDBH

Do the initial database connection via MySQL or SQLite.  This method will return back the DBH it creates, but it is only here for completeness and would normally never be used.  For FWS database routines this is not required as it will be implied when executing those methods.
        
	$fws->connectDBH();

If you want to pass DBType, DBName, DBHost, DBUser, and DBPassword as a hash, the global FWS DBH will not be passed, and the DBH it creates will be returned from the method.

The first time this is ran, it will cache the DBH and not ask for another.   If you are running multipule data sources you will need to add noCache=>1.  This will not cache the DBH, nor use the the cached DBH used as the default return.

=cut

sub connectDBH {
        my ($self,%paramHash) = @_;

	#
	# Use defaults if they are not passed
	#
	if ($paramHash{'DBType'} eq '') {	$paramHash{'DBType'} 		= $self->{'DBType'} }
	if ($paramHash{'DBName'} eq '') {	$paramHash{'DBName'} 		= $self->{'DBName'} }
	if ($paramHash{'DBHost'} eq '') {	$paramHash{'DBHost'} 		= $self->{'DBHost'} }
	if ($paramHash{'DBUser'} eq '') {	$paramHash{'DBUser'} 		= $self->{'DBUser'} }
	if ($paramHash{'DBPort'} eq '') {	$paramHash{'DBPort'} 		= $self->{'DBPort'} }
	if ($paramHash{'DBPassword'} eq '') {	$paramHash{'DBPassword'} 	= $self->{'DBPassword'} }

	#
	# fill this up!
	#	
	my $DBH;

        #
        # grab the DBI if we don't have it yet, or if noCache is passed do it again
        #
        if (!defined $self->{'_DBH_'.$paramHash{'DBName'}.$paramHash{'DBHost'}} || $paramHash{'noCache'} eq '1') {

                #
                # hook up with some DBI
                #
                use DBI;

		#
		# DBType for mysql is always lower case
		#
                if ($paramHash{'DBType'} =~ /mysql/i) { $paramHash{'DBType'} = lc($paramHash{'DBType'}) }

                #
                # default set to mysql
                #
                my $dsn = $paramHash{'DBType'}.":".$paramHash{'DBName'}.":".$paramHash{'DBHost'}.":".$paramHash{'DBPort'};

                #
                # SQLite
                #
                if ($paramHash{'DBType'} =~ /SQLite/i) { $dsn = "SQLite:".$paramHash{'DBName'} }

                #
                # set the DBH for use throughout the script
                #
                $DBH = DBI->connect("DBI:".$dsn,$paramHash{'DBUser'},$paramHash{'DBPassword'});

		#
		# send an error if we got one
		#
		if (DBI->errstr ne '') { $self->FWSLog('DB Connection error: '.DBI->errstr) }
        }

	#
	# if DBH cache isn't defined then lets define it
	#
       	if (!defined $self->{'_DBH_'.$paramHash{'DBName'}.$paramHash{'DBHost'}} && $paramHash{'noCache'} ne '1')  { $self->{'_DBH_'.$paramHash{'DBName'}.$paramHash{'DBHost'}} = $DBH }

	#
	# in either case return the DBH in case someone wants it for convience
	#
	return $DBH;
}


=head2 dataArray

Retrieve a hash array based on any combination of keywords, type, guid, or tags

	my @dataArray = $fws->dataArray(guid=>$someParentGUID);
	for my $i (0 .. $#dataArray) {
     		$valueHash{'html'} .= $dataArray[$i]{'name'}."<br/>";
	}

Any combination of the following parameters will restrict the results.  At least one is required.

=over 4

=item * guid: Retrieve any element whose parent element is the guid

=item * keywords: A space delimited list of keywords to search for

=item * tags: A comma delimited list of element tags to search for

=item * type: Match any element which this exact type

=item * containerId: Pull the data from the data container

=item * childGUID: Retrieve any element whose child element is the guid (This option can not be used with keywords attribute)

=item * showAll: Show active and inactive records. By default only active records will show

=back

Note: guid and containerId cannot be used at the same time, as they both specify the parent your pulling the array from

=cut

sub dataArray {
        my ($self,%paramHash) = @_;

        #
        # set site GUID if it wasn't passed to us
        #
        if ($paramHash{'siteGUID'} eq '') {$paramHash{'siteGUID'} = $self->{'siteGUID'} }

        #
        # transform the containerId to the parent id
        #
        if ($paramHash{'containerId'} ne '') {

                #
                # if we don't get one, we will fail on the next check because we won't have a guid
                #
                ($paramHash{'guid'}) = @{$self->runSQL(SQL=>"select guid from data where name='".$self->safeSQL($paramHash{'containerId'})."' and element_type='data' and site_guid='".$self->safeSQL($paramHash{'siteGUID'})."' LIMIT 1")};

        }

        #
        # if we don't have any data to search for get out so we don't get "EVERYTHING"
        #
        if ($paramHash{'childGUID'} eq '' && $paramHash{'guid'} eq '' && !$paramHash{'type'} && $paramHash{'keywords'} eq '' && $paramHash{'tags'} eq '') {
                  return ();
        }

        #
        # get the where and join builders ready for content
        #
        my $addToExtWhere       = "";
        my $addToDataWhere      = "";
        my $addToExtJoin        = "";
        my $addToDataXRefJoin   = "";

	#
        # bind by element Type could be a comma delemented List
        #
        if ($paramHash{'type'} ne '') {
                my @typeArray   = split(/,/,$paramHash{'type'});
                $addToDataWhere .= 'and (';
                $addToExtWhere  .= 'and (';
                while (@typeArray) {
                        my $type = shift(@typeArray);
                        $addToDataWhere .= "data.element_type like '".$type."' or ";
                }
                $addToExtWhere  =~ s/ or $//g;
                $addToExtWhere  .= ')';
                $addToDataWhere =~ s/ or $//g;
                $addToDataWhere .= ')';
        }

        #
        # data left join connector
        #
        my $dataConnector =  'guid_xref.child=data.guid';

        #
        # bind critera by child guid, so we are only seeing stuff who's child = #
        #
        if($paramHash{'childGUID'} ne '') {
                $addToExtWhere  .= "and guid_xref.child = '".$self->safeSQL($paramHash{'childGUID'})."' ";
                $addToDataWhere .= "and guid_xref.child = '".$self->safeSQL($paramHash{'childGUID'})."' ";
                $dataConnector  = 'guid_xref.parent=data.guid'
        }

        #
        # bind critera by array guid, so we are only seeing stuff who's parent = #
        #
        if ($paramHash{'guid'} ne '') {
                $addToExtWhere  .= "and guid_xref.parent = '".$self->safeSQL($paramHash{'guid'})."' ";
                $addToDataWhere .= "and guid_xref.parent = '".$self->safeSQL($paramHash{'guid'})."' ";
        }


	#
	# find data by tags
	#
        if ($paramHash{'tags'} ne '') {
                my @tagsArray = split(/,/,$paramHash{'tags'});
                my $tagGUIDs = '';
                while (@tagsArray) {
                        my $checkTag = shift(@tagsArray);

                        #
                        # bind by tags Type could be a comma delemented List
                        #
                        my %elementHash = $self->_fullElementHash();


			for my $elementType ( keys %elementHash ) {
                        my $incTags = $elementHash{$elementType}{"tags"};
                        if (            ($incTags =~/^$checkTag$/
                                                || $incTags =~/^$checkTag,/
                                                || $incTags =~/,$checkTag$/
                                                || $incTags =~/,$checkTag,$/
                                                )
                                                && $incTags ne '' && $checkTag ne '') {
                                        $tagGUIDs .= ',\''.$elementType.'\'';
                                        }
                                }
                        }

                $addToDataWhere .= 'and (data.element_type in (\'\''.$tagGUIDs.'))';
                $addToExtWhere  .= 'and (data.element_type in (\'\''.$tagGUIDs.'))';
                }


        #
        # add the keywordScore field response
        #
        my $keywordScoreSQL = '1';
        my $dataCacheSQL = '1';
        my $dataCacheJoin = '';

        #
        # if any keywords are added,  and create an array of ID's and join them into comma delmited use
        #
        if ($paramHash{'keywords'} ne '') {

                #
                # build the field list we will search against
                #
                my @fieldList = ("data_cache.title","data_cache.name");
                for my $key ( keys %{$self->{"dataCacheFields"}} ) { push(@fieldList,"data_cache.".$key) }

                #
                # set the cache and join statement starters
                #
                $dataCacheSQL   = 'data_cache.pageIdOfElement';
                $dataCacheJoin  = 'left join data_cache on (data_cache.guid=child)';

                #
                # do some last minute checking for keywords stablity
                #
                $paramHash{'keywords'} =~ s/[^a-zA-Z0-9 \.\-]//sg;

                #
                # build the actual keyword chains
                #
                $addToDataWhere .= " and data.active='1' and (";
                $addToDataWhere .= $self->_getKeywordSQL($paramHash{'keywords'},@fieldList);
                $addToDataWhere .= ")";

                #
                # if we are on mysql lets do some fuzzy matching
                #
                if ($self->{'DBType'} =~ /^mysql$/i) {
                        $keywordScoreSQL = "(";
                        while (@fieldList) {
                                $keywordScoreSQL .= "(MATCH (".$self->safeSQL(shift(@fieldList)).") AGAINST ('".$self->safeSQL($paramHash{'keywords'})."'))+"
                                }
                        $keywordScoreSQL =~ s/\+$//sg;
                        $keywordScoreSQL =  $keywordScoreSQL.")+1 as keywordScore";
                        }
                }

        my @hashArray;
        #my $arrayRef = $self->runSQL(SQL=>"select distinct ".$keywordScoreSQL.",".$dataCacheSQL.",data.extra_value,data.guid,data.created_date,data.show_mobile,data.lang,guid_xref.site_guid,data.site_guid,data.site_guid,data.active,data.friendly_url,data.page_friendly_url,data.title,data.disable_title,data.default_element,element.tags,data.disable_edit_mode,data.element_type,data.nav_name,data.name,guid_xref.parent,guid_xref.layout from guid_xref ".$dataCacheJoin."  left join data on (guid_xref.site_guid='".$self->safeSQL($paramHash{'siteGUID'})."') and ".$dataConnector." ".$addToDataXRefJoin." ".$addToExtJoin." left join element on (element.guid = data.element_type or data.element_type = element.type) where guid_xref.parent != '' and guid_xref.site_guid is not null ".$addToDataWhere." order by guid_xref.ord");
        my $arrayRef = $self->runSQL(SQL=>"select distinct ".$keywordScoreSQL.",".$dataCacheSQL.",data.extra_value,data.guid,data.created_date,data.show_mobile,data.lang,guid_xref.site_guid,data.site_guid,data.site_guid,data.active,data.friendly_url,data.page_friendly_url,data.title,data.disable_title,data.default_element,data.disable_edit_mode,data.element_type,data.nav_name,data.name,guid_xref.parent,guid_xref.layout from guid_xref ".$dataCacheJoin."  left join data on (guid_xref.site_guid='".$self->safeSQL($paramHash{'siteGUID'})."') and ".$dataConnector." ".$addToDataXRefJoin." ".$addToExtJoin." where guid_xref.parent != '' and guid_xref.site_guid is not null ".$addToDataWhere." order by guid_xref.ord");


        #
        # for speed we will add this to here so we don't have to ask it EVERY single time we loop though the while statemnent
        #
        my $showMePlease = 0;
        if (($paramHash{'showAll'} eq '1' || $self->formValue('editMode') eq '1' || $self->formValue('p') =~ /^fws_/) ) { $showMePlease =1 }

	#
	# move though the data records creating the individual hashes
	#
        while (@{$arrayRef}) {
                my %dataHash;

                my $keywordScore                = shift(@{$arrayRef});
                my $pageIdOfElement             = shift(@{$arrayRef});

                my $extraValue                  = shift(@{$arrayRef});

                $dataHash{'guid'}               = shift(@{$arrayRef});
                $dataHash{'createdDate'}        = shift(@{$arrayRef});
                $dataHash{'showMobile'}         = shift(@{$arrayRef});
                $dataHash{'lang'}               = shift(@{$arrayRef});
                $dataHash{'guid_xref_site_guid'}= shift(@{$arrayRef});
                $dataHash{'siteGUID'}           = shift(@{$arrayRef});
                $dataHash{'site_guid'}          = shift(@{$arrayRef});
                $dataHash{'active'}             = shift(@{$arrayRef});
                $dataHash{'friendlyURL'}    	= shift(@{$arrayRef});
                $dataHash{'pageFriendlyURL'}    = shift(@{$arrayRef});
                $dataHash{'title'}              = shift(@{$arrayRef});
                $dataHash{'disableTitle'}       = shift(@{$arrayRef});
                $dataHash{'defaultElement'}     = shift(@{$arrayRef});
                #$dataHash{'tags'}     		= shift(@{$arrayRef});
                $dataHash{'disableEditMode'}    = shift(@{$arrayRef});
                $dataHash{'type'}               = shift(@{$arrayRef});
                $dataHash{'navigationName'}     = shift(@{$arrayRef});
                $dataHash{'name'}               = shift(@{$arrayRef});
                $dataHash{'parent'}             = shift(@{$arrayRef});
                $dataHash{'layout'}             = shift(@{$arrayRef});

		

                if ($dataHash{'active'} || ($showMePlease && $dataHash{'siteGUID'} eq $paramHash{'siteGUID'}) || ($paramHash{'siteGUID'} ne $dataHash{'siteGUID'} && $dataHash{'active'})) {

                        #
                        # twist our legacy statements around.  titleOrig isn't legacy - but I don't
                        # know why its here either.  We will attempt to deprecate it on the next version
                        #
                        $dataHash{'element_type'}               = $dataHash{'type'};
                        $dataHash{'titleOrig'}                  = $dataHash{'title'};

                        #
                        # if the title is blank lets dump the name into it
                        #
                        if ($dataHash{'title'} eq '') { $dataHash{'title'} =  $dataHash{'name'} }

                        #
                        # add the extended fields and create the hash
                        #
                        %dataHash = $self->addExtraHash($extraValue,%dataHash);

                        #
                        # overwriting these, just in case someone tried to save them in the extended hash
                        #
                        $dataHash{'keywordScore'}       = $keywordScore;
                        $dataHash{'pageIdOfElement'}    = $pageIdOfElement;

                        #
                        # push the hash into the array
                        #
                        push(@hashArray,{%dataHash});
                }
        }

	#
	# return the reference or the array
	#
        if ($paramHash{'ref'} eq '1') { return \@hashArray } else {return @hashArray }
}

=head2 dataHash

Retrieve a hash or hash reference for a data matching the passed guid.  This can only be used after setSiteValues() because it required $fws->{'siteGUID'} to be defined.

	#
	# get the hash itself
	#
        my %dataHash 	= $fws->dataHash(guid=>'someguidsomeguidsomeguid');
       
	#
	# get a reference to the hash
	# 
	my $dataHashRef = $fws->dataHash(guid=>'someguidsomeguidsomeguid',ref=>1);

=cut

sub dataHash {
        my ($self,%paramHash) = @_;
        
	#
        # set site GUID if it wasn't passed to us
        #
        if ($paramHash{'siteGUID'} eq '') {$paramHash{'siteGUID'} = $self->{'siteGUID'} }


        my $arrayRef =  $self->runSQL(SQL=>"select data.extra_value,data.element_type,'lang',lang,'guid',data.guid,'pageFriendlyURL',page_friendly_url,'friendlyURL',friendly_url,'defaultElement',data.default_element,'guid_xref_site_guid',data.site_guid,'showLogin',data.show_login,'showMobile',data.show_mobile,'showResubscribe',data.show_resubscribe,'groupId',data.groups_guid,'disableEditMode',data.disable_edit_mode,'siteGUID',data.site_guid,'site_guid',data.site_guid,'title',data.title,'disableTitle',data.disable_title,'active',data.active,'navigationName',nav_name,'name',data.name from data left join site on site.guid=data.site_guid where data.guid='".$self->safeSQL($paramHash{'guid'})."' and (data.site_guid='".$self->safeSQL($paramHash{'siteGUID'})."' or site.sid='fws')");

        #
        # pull off the first two fields because we need to manipulate them
        #
        my $extraValue  = shift(@$arrayRef);
        my $dataType    = shift(@$arrayRef);

        #
        # convert it to a hash
        #
        my %dataHash                    = @$arrayRef;

        #
        # do some legacy data type switching around.  some call it type (wich it should be, and some call it element_type
        #
        $dataHash{"type"}               = $dataType;
        $dataHash{"element_type"}       = $dataType;

        #
        # combine the hash
        #
        %dataHash                       = $self->addExtraHash($extraValue,%dataHash);

        #
        # Overwrite the title with the name if it is blank
        #
        if ($dataHash{'title'} eq '') { $dataHash{'title'} =  $dataHash{'name'} }

        #
        # return the hash or hash reference
        #
        if ($paramHash{'ref'} eq '1') { return \%dataHash } else {return %dataHash }
}

=head2 deleteData

Delete something from the data table.   %dataHash must contain guid and either containerId or parent. By passing noOrphanDelete with a value of 1, any data ophaned from the act of this delete will also be deleted.

	my %dataHash;
	$dataHash{'noOrphanDelete'}	= '0';
	$dataHash{'guid'}		= 'someguid123123123';
	$dataHash{'parent'}		= 'someparentguid';
        my %dataHash $fws->deleteData(%dataHash);

=cut

sub deleteData {
        my ($self, %paramHash) = @_;
        %paramHash = $self->runScript('preDeleteData',%paramHash);

        #
        # get the sid if one wasn't passed
        #
        if ($paramHash{'siteGUID'} eq '') { $paramHash{'siteGUID'} = $self->{'siteGUID'} }

        #
        # transform the containerId to the parent id
        #
        if ($paramHash{'containerId'} ne '') {
                ($paramHash{'parent'}) = @{$self->runSQL(SQL=>"select guid from data where name='".$self->safeSQL($paramHash{'containerId'})."' and element_type='data' and site_guid='".$self->safeSQL($paramHash{'siteGUID'})."' LIMIT 1")};
        }

        #
        # Kill the xref
        #
        $self->_deleteXRef($paramHash{'guid'},$paramHash{'parent'},$paramHash{'siteGUID'});

        #
        # Kill any data recrods now orphaned from this process
        #
	$self->_deleteOrphanedData("guid_xref","child","data","guid");
	
	#
	# if we are cleaning orphans continue
	#	
	if ($paramHash{'noOrphanDelete'} ne '1') {
	        #
	        # loop though till we don't see anything dissapear
	        #
	        my $keepGoing = 1;
	
	        while ($keepGoing) {
			#
			# set up the tests
			#
	                my ($firstTest)         = @{$self->runSQL(SQL=>"select count(1) from guid_xref")};
	                my ($firstTestData)     = @{$self->runSQL(SQL=>"select count(1) from data")};

	                #
	                # get rid of any parent that no longer has a perent
	                #
	                $self->_deleteOrphanedData('guid_xref','parent','data','guid',' and guid_xref.parent <> \'\'');
	
	                #
	                # get rid of any data records that are now orphaned from the above process's
	                #
	                $self->_deleteOrphanedData("data","guid","guid_xref","child");
	
			#
			# if we are not deleting orphans do the checks
			#
			if ($paramHash{'noOrphanDelete'} ne '1') {
	
	                        #
	                        # grab a second test to match against
	                        #
	                        my ($secondTest)        = @{$self->runSQL(SQL=>"select count(1) from guid_xref")};
	                        my ($secondTestData)    = @{$self->runSQL(SQL=>"select count(1) from data")};
	
	                        #
	                        # now that we have a first and second pass.  if they have changed keep going, but if nothing happened
	                        # lets ditch out of here
	                        #
	                        if ($secondTest eq $firstTest && $secondTestData eq $firstTestData) { $keepGoing = 0 } else { $keepGoing = 1 }
	                }
	        }
        	#
	        # Kill any data recrods now orphaned from the cleansing
	        #
		$self->_deleteOrphanedData("guid_xref","child","data","guid");
	}

	#
	# run any post scripts and return what we were passed
	#
        %paramHash = $self->runScript('postDeleteData',%paramHash);
        return %paramHash;
}

=head2 deleteHash

doc needed

=cut

sub deleteHash {
        my ($self,%paramHash) = @_;

        #
        # get the current array
        #
        my @hashArray = $self->hashArray(%paramHash);
        my @newArray;

        #
        # go though each one of the shippingLocation items, figure out what one is being updated and update it!
        #
        for my $i (0 .. $#hashArray) {

                #
                # update the loc with the same guid with the new hash
                #
                if ($paramHash{'guid'} ne $hashArray[$i]{'guid'}) { push(@newArray,{%{$hashArray[$i]}}) }
        }
        return (nfreeze(\@newArray));
}

=head2 deleteQueue

Delete from the message and process queue

        my %queueHash;
        $queueHash{'guid'}               = 'someQueueGUID';
        my %queueHash $fws->deleteData(%queueHash);

=cut

sub deleteQueue {
        my ($self,%paramHash) = @_;
        %paramHash = $self->runScript('preDeleteQueue',%paramHash);
        $self->runSQL(SQL=>"delete from queue where guid = '".$self->safeSQL($paramHash{'guid'})."'");
        %paramHash = $self->runScript('postDeleteQueue',%paramHash);
        return %paramHash;
}

=head2 elementHash

Return the hash for an element from cache, plugin for element database

=cut

sub elementHash {
        my ($self,%paramHash) = @_;

        if ($self->{'elementHash'}->{$paramHash{'guid'}}{'guid'} eq '') {

                #
                # add to element guid or type
                #
                my $addToWhere = "guid='".$self->safeSQL($paramHash{'guid'})."'";
                if ($paramHash{'guid'} ne '') {$addToWhere .= " or type='".$self->safeSQL($paramHash{'guid'})."'" }

                #
                # get tha hash from the DB
                #
                my (@scriptArray) = @{$self->runSQL(SQL=>"select 'jsDevel',js_devel,'cssDevel',css_devel,'adminGroup',admin_group,'classPrefix',class_prefix,'siteGUID',site_guid,'guid',guid,'ord',ord,'tags',tags,'public',public,'rootElement',root_element,'type',type,'parent',parent,'title',title,'schemaDevel',schema_devel,'scriptDevel',script_devel,'checkedout',checkedout from element where ".$addToWhere." order by ord limit 1")};

                #
                # create the hash and return it
                #
                %{$self->{'elementHash'}->{$paramHash{'guid'}}} = @scriptArray;
        }

        return %{$self->{'elementHash'}->{$paramHash{'guid'}}};
}

=head2 exportCSV

Return a hash array in a csv format.

        my $csv = $fws->exportCSV(dataArray=>[@someArray]);

=cut

sub exportCSV {
        my ($self,%paramHash) = @_;

        #
        # pull the array out of the hash and find out the keys
        #
        my @dataArray = @{$paramHash{'dataArray'}};
        my %theKeys;
        for my $i (0 .. $#dataArray) {
                for my $key ( keys %{$dataArray[$i]}) {
                        if ($key !~ /^(guid|killSession)$/) {
                                $theKeys{$key} =1;
                        }
                }
        }

        #
        # create the header
        #
        my $returnString = 'guid,';
        for my $key ( sort keys %theKeys) { $returnString .= $key.',' }
        $returnString .= "\n";

        #
        # create the list for everything else
        #
        for my $i (0 .. $#dataArray) {
                $returnString .= $dataArray[$i]{'guid'}.',';

                #
                # kill anything that is a blank date and aggressivly clean up anything
                # could break a csv
                #
                for my $key ( sort keys %theKeys) {
                        $dataArray[$i]{$key} =~ s/(,|;)/ /sg;
                        $dataArray[$i]{$key} =~ s/(\n|\r)//sg;
                        $dataArray[$i]{$key} =~ s/^(0000.00.00.*|'|")//sg;
                        $returnString .= $dataArray[$i]{$key}.',';
                }
                $returnString .= "\n";
        }

        #
        # kill the trailing comma and return the string
        #
        $returnString =~ s/,$//sg;
        return $returnString. "\n";;
}



=head2 flushSearchCache

Delete all cached data and rebuild it from scratch.  Will return the number of records it optimized.  If no siteGUID was passed then the one from the current site being rendered is used

        print $fws->flushSearchCache($fws->{'siteGUID'});

=cut

sub flushSearchCache {
        my ($self,$siteGUID) = @_;

	#
	# set the site guid if it wasn't passed
	#
        if ($siteGUID eq '') { $siteGUID = $self->{'siteGUID'} }

        #
        # before we do anything lets get the cache fields reset
        #
        $self->setCacheIndex();

        #
        # drop the current data
        #
        $self->runSQL(SQL=>"delete from data_cache where site_guid='".$self->safeSQL($siteGUID)."'");

	#
	# lets make the stuff we might need
	#
        my %dataCacheFields = %{$self->{"dataCacheFields"}};
        foreach my $key ( keys %dataCacheFields ) {
        	$self->alterTable(table=>"data_cache",field=>$key,type=>"text",key=>"FULLTEXT",default=>"") 
        }

        #
        # have a counter so we can see how much work we did
        #
        my $dataUnits = 0;

        #
        # get a list of the current data, and update the cache for each one
        #
        my $dataArray = $self->runSQL(SQL=>"select guid from data where site_guid='".$self->safeSQL($siteGUID)."'");
        while (@$dataArray) {
                my $guid = shift(@$dataArray);
                $self->updateDataCache($self->dataHash(guid=>$guid));
                $dataUnits++;
        }
        return $dataUnits;
}

=head2 fwsGUID

Retrieve the GUID for the fws site. If it does not yet exist, make a new one.

        print $fws->fwsGUID();

=cut

sub fwsGUID {
        my ($self) = @_;

        #
        # if is not set, set it and create the site id
        #
        if ($self->siteValue('fwsGUID') eq '') {

                #
                # get the sid for the fws site
                #
                my ($fwsGUID) = $self->getSiteGUID('fws');

                #
                # if its blank make a new one
                #
                if ($fwsGUID eq '') {
                        $fwsGUID = $self->createGUID('f');
                        my ($adminGUID) = $self->getSiteGUID('admin');
                        $self->runSQL(SQL=>"insert into site set sid='fws',guid='".$fwsGUID."',site_guid='".$self->safeSQL($adminGUID)."'");
                }

                #
                # add it as a siteValue and return the result
                #
                $self->siteValue('fwsGUID',$fwsGUID) ;
                return $fwsGUID;
        }

        #
        # I already know it, just return the result
        #
        else { return $self->siteValue('fwsGUID') }
}




=head2 gatewayPassword

Retrieve the payment gateway password

        my $gatewayPass =  $fws->gatewayPassword();

=cut

sub gatewayPassword {
        my ( $self ) = @_;
        my ($gateway_password) = @{$self->runSQL(SQL=>"select gateway_password from site where guid='".$self->safeSQL($self->{'siteGUID'})."'")};
        return $self->FWSDecrypt($gateway_password);
}


=head2 getSiteGUID

Get the site GUID for a site by passing the SID of that site.  If the SID does not exist it will return an empty string.

        print $fws->getSiteGUID('somesite');

=cut

sub getSiteGUID {
        my ($self,$sid) = @_;
        #
        # get the ID to the sid for site ids these always match the corrisponding sid
        #
        my ($guid) = @{$self->runSQL(SQL=>"select guid from site where sid='".$self->safeSQL($sid)."'")};
        return $guid;
}

=head2 getPageGUID

Get the GUID for a site by passing a guid of an item on a page.  If the guid is referenced in more than one place, the page it will be passed could be random.

        my $pageGUID =  $fws->getPageGUID($valueHash{'elementId'},10);

Note: This procedure is very database extensive and should be used lightly.  The default depth to look before giving up is 5, the example above shows searching for 10 depth before giving up. 

=cut

sub getPageGUID {
        my ($self,$guid,$depth) = @_;

	#
	# set the depth to how far you will look before giving up
	#
	if ($depth eq '') { $depth = 10 }

	#
	# set the cap counter
	#
        my $recurCap = 0;

        #
        # get the inital type
        #
        my $recId = -1;
        my ($type) = @{$self->runSQL(SQL=>"select element_type from data where guid='".$self->safeSQL($guid)."'")};

        #
        # recursivly head down till you get "page" or "" as refrence.
        #
        while ($type ne 'page' && $type ne 'home' && $guid ne '') {
                my @idsAndTypes = @{$self->runSQL(SQL=>"select parent,element_type from guid_xref left join data on data.guid=parent where child='".$self->safeSQL($guid)."'")};
                while (@idsAndTypes) {
                        $guid           = shift(@idsAndTypes);
                        my $listType    = shift(@idsAndTypes);
                        if ($listType eq 'page') {
                                $recId = $guid;
                                $type = 'page';
                        }
                }

                #
                # give up after 5 
                #
                if ($recurCap > 5) { $type = 'page'; $recId =  -1 }
                $recurCap++;
        }
        return $recId;
}

=head2 hashArray

doc needed

=cut

sub hashArray {
        my ($self,%paramHash) = @_;
        if ($paramHash{'hashArray'} ne '') {
                #
                # get the current array, and clear the loc string
                #
                use Storable qw(nfreeze thaw);
                return @{thaw($paramHash{'hashArray'})};
        }
        return ();
}


=head2 newDBCheck

Do a new database check and then create the base records for a new install of FWS if the database doesn't have an admin record.  The return is the HTML that would render for a browser to let them know what just happened.

=cut

sub newDBCheck {
        my ($self) = @_;
        my ($isADMIN) = @{$self->runSQL(SQL=>"select 1 from site where sid='admin'")};

        if ($isADMIN ne '1') {
                my $fwsGUID     = $self->createGUID('f');
                my $adminGUID   = $self->createGUID('s');
                my $siteGUID    = $self->createGUID('s');
                $self->runSQL(SQL=>"insert into site (guid,sid,site_guid) values ('".$fwsGUID."','fws','".$adminGUID."')");
                $self->runSQL(SQL=>"insert into site (guid,sid,site_guid) values ('".$adminGUID."','admin','".$adminGUID."')");
                $self->runSQL(SQL=>"insert into site (guid,sid,default_site,site_guid) values ('".$siteGUID."','site','1','".$adminGUID."')");

                #
                # create new home page GUID
                #
                $self->homeGUID($siteGUID);

                $self->{'stopProcessing'} = 1;

                return "Content-Type: text/html; charset=UTF-8\n\n<html><head><title>New Database Detected</title></head><body><h2>Setting up New Database Users</h2><br/>".
                        "<b>Admin User Account</b><hr/>".
                        "User Id: admin<br/>".
                        "Password: This was set in the ".$self->{'scriptName'}." file<br/>".
                        "<br/>".
                        "Note: Once an admin level user is created on this installation, the admin account will be disabled for security reasons. ".
                        "Please do this before working on your new site for security!".
                        "<br/><br/>Finished: <a href=\"".$self->{'scriptName'}."\">Click here to continue to</a> -> ".$self->domain().$self->{'scriptName'}.
                        "</body></html>";
        }
}

=head2 queueArray

Return a hash array of the current items in the processing queue.

=cut

sub queueArray {
        my ($self,%paramHash) = @_;

        #
        # set PH's for sql statement
        #
        my $whereStatement = "1 = 1 ";
        my $keywordSQL;

        #
        # Add keywords if they exist to select statement
        #
        if ($paramHash{'keywords'} ne '') {
                $keywordSQL = $self->_getKeywordSQL($paramHash{'keywords'},"guid","queue_from","queue_to","from_name","subject");
                if ($keywordSQL) { $keywordSQL = " and ( ".$keywordSQL." ) " }
        }

        #
        # queuery by directory or user if needed
        # add other criteria if applicable
        #
        if ($paramHash{'directoryGUID'} ne '')  { $whereStatement .= " and directory_guid = '".$self->safeSQL($paramHash{'directoryGUID'})."'" }
        if ($paramHash{'userGUID'} ne '')       { $whereStatement .= " and profile_guid = '".$self->safeSQL($paramHash{'userGUID'})."'" }
        if ($paramHash{'from'} ne '')           { $whereStatement .= " and queue_from = '".$self->safeSQL($paramHash{'from'})."'" }
        if ($paramHash{'to'} ne '')             { $whereStatement .= " and queue_to = '".$self->safeSQL($paramHash{'to'})."'" }
        if ($paramHash{'fromName'} ne '')       { $whereStatement .= " and from_name = '".$self->safeSQL($paramHash{'fromName'})."'" }
        if ($paramHash{'subject'} ne '')        { $whereStatement .= " and subject = '".$self->safeSQL($paramHash{'subject'})."'" }

        #
        # add date critiria if appicable
        #
        if ($paramHash{'dateFrom'} eq '')    { $paramHash{'dateFrom'}   = "0000-00-00 00:00:00" }
        if ($paramHash{'dateTo'} eq '')      { $paramHash{'dateTo'}     = $self->formatDate(format=>'SQL') }
        $whereStatement .= " and scheduled_date <= '".$self->safeSQL($paramHash{'dateTo'})."'";
        $whereStatement .= " and scheduled_date >= '".$self->safeSQL($paramHash{'dateFrom'})."'";

        my $arrayRef = $self->runSQL(SQL=>"select profile_guid,directory_guid,guid,type,hash,draft,from_name,queue_from,queue_to,body,subject,digital_assets,transfer_encoding,mime_type,scheduled_date from queue where ".$whereStatement.$keywordSQL." ORDER BY scheduled_date DESC");
        my @queueArray;
        while (@$arrayRef) {
                my %sendHash;
                $sendHash{'userGUID'}           = shift(@$arrayRef);
                $sendHash{'directoryGUID'}      = shift(@$arrayRef);
                $sendHash{'guid'}               = shift(@$arrayRef);
                $sendHash{'type'}               = shift(@$arrayRef);
                $sendHash{'hash'}               = shift(@$arrayRef);
                $sendHash{'draft'}              = shift(@$arrayRef);
                $sendHash{'fromName'}           = shift(@$arrayRef);
                $sendHash{'from'}               = shift(@$arrayRef);
                $sendHash{'to'}                 = shift(@$arrayRef);
                $sendHash{'body'}               = shift(@$arrayRef);
                $sendHash{'subject'}            = shift(@$arrayRef);
                $sendHash{'digitalAssets'}      = shift(@$arrayRef);
                $sendHash{'transferEncoding'}   = shift(@$arrayRef);
                $sendHash{'mimeType'}           = shift(@$arrayRef);
                $sendHash{'scheduledDate'}      = shift(@$arrayRef);
                push(@queueArray, {%sendHash});
        }
        if ($paramHash{'ref'} eq '1') { return \@queueArray } else {return @queueArray }
}

=head2 queueHash

Return a hash or reference to the a queue hash.

=cut

sub queueHash {
        my ($self,%paramHash) = @_;

        #
        # get an array of the all stuff we need,  in a name\value pair format
        #
        my $arrayRef = $self->runSQL(SQL=>"select 'directoryGUID',directory_guid,'userGUID',profile_guid,'hash',hash,'guid',guid,'draft',draft,'fromName',from_name,'from',queue_from,'to',queue_to,'body',body,'subject',subject,'digitalAssets',digital_assets,'transferEncoding',transfer_encoding,'mimeType',mime_type,'scheduledDate',scheduled_date from queue where guid='".$self->safeSQL($paramHash{'guid'})."'");

        #
        # convert the array to a hash
        #
        my %itemHash = @$arrayRef;

        if ($paramHash{'ref'} eq '1') { return \%itemHash } else {return %itemHash }
}


=head2 queueHistoryArray

Return a hash array of the history items from the processing queue.

Parmeters to constrain data:

=over 4

=item * limit

Maximum number of records to return.

=item * email

Only items that were sent to or from an email account specified.

=item * synced

Only items that match the sync flaged that is passed.  [0|1]

=item * userGUID

Only items created from this user.

=item * directoryGUID

Only items referencing this directory record.

=back

=cut

sub queueHistoryArray {
        my ($self,%paramHash) = @_;

        #
        # set SQL PH's
        #
        my $whereStatement = '1=1';
        my $limitSQL = '';

        #
        # create sql where and limits
        #
        if ($paramHash{'limit'} ne '')          { $limitSQL = ' LIMIT '.$self->safeSQL($paramHash{'limit'}) }
        if ($paramHash{'email'} ne '')       	{ $whereStatement .= " and (queue_from like '".$self->safeSQL($paramHash{"email"})."' or queue_to like '".$self->safeSQL($paramHash{"email"})."')" }
        if ($paramHash{'userGUID'} ne '')       { $whereStatement .= " and profile_guid='".$self->safeSQL($paramHash{"userGUID"})."'" }
        if ($paramHash{'directoryGUID'} ne '')  { $whereStatement .= " and directory_guid='".$self->safeSQL($paramHash{"directoryGUID"})."'" }
        if ($paramHash{'synced'} ne '')  	{ $whereStatement .= " and synced='".$self->safeSQL($paramHash{"synced"})."'" }

        my @historyArray;
        my $arrayRef = $self->runSQL(SQL=>"select queue_guid,profile_guid,queue_guid,directory_guid,guid,hash,queue_from,queue_to,type,subject,success,synced,failure_code,response,sent_date,scheduled_date from queue_history where ".$whereStatement." order by sent_date desc".$limitSQL);

        while (@$arrayRef) {
                my %sendHash;
                $sendHash{'guidGUID'}           = shift(@$arrayRef);
                $sendHash{'userGUID'}           = shift(@$arrayRef);
                $sendHash{'queueGUID'}        	= shift(@$arrayRef);
                $sendHash{'directoryGUID'}      = shift(@$arrayRef);
                $sendHash{'guid'}               = shift(@$arrayRef);
                $sendHash{'hash'}               = shift(@$arrayRef);
                $sendHash{'from'}               = shift(@$arrayRef);
                $sendHash{'to'}                 = shift(@$arrayRef);
                $sendHash{'type'}               = shift(@$arrayRef);
                $sendHash{'subject'}            = shift(@$arrayRef);
                $sendHash{'success'}            = shift(@$arrayRef);
                $sendHash{'synced'}             = shift(@$arrayRef);
                $sendHash{'failureCode'}        = shift(@$arrayRef);
                $sendHash{'response'}           = shift(@$arrayRef);
                $sendHash{'sentDate'}           = shift(@$arrayRef);
                $sendHash{'scheduledDate'}      = shift(@$arrayRef);
                push(@historyArray, {%sendHash});
        }
        if ($paramHash{'ref'} eq '1') { return \@historyArray } else {return @historyArray }
}

=head2 queueHistoryHash

Return a hash or reference to the a queue history hash.   History hashes will be referenced by passing a guid key or if present a queueGUID key from the derived queue record it was created from.

=cut;

sub queueHistoryHash {
        my ($self,%paramHash) = @_;

	#
	# get the historyHash based on the queueGUID it was dirived from if that what is being used for
	# if not just treat it like any ole hash lookup
	#
	my $whereStatement = "guid='".$self->safeSQL($paramHash{'guid'})."'";
	if ($paramHash{'queueGUID'} ne '') { $whereStatement = "queue_guid='".$self->safeSQL($paramHash{'queueGUID'})."'" }

        #
        # get an array of the all stuff we need,  in a name\value pair format
        #
        my $arrayRef = $self->runSQL(SQL=>"select 'hash',hash,'guid',guid,'scheduledDate',scheduled_date,'queueGUID',queue_guid,'from',queue_from,'to',queue_to,'failureCode',failure_code,'body',body,'synced',synced,'success',success,'response',response,'subject',subject,'sentDate',sent_date from queue_history where ".$whereStatement);

        #
        # convert the array
        #
        my %itemHash = @$arrayRef;

        if ($paramHash{'ref'} eq '1') { return \%itemHash } else {return %itemHash }
}

=head2 runSQL

Return an reference to an array that contains the results of the SQL ran.  In addition if you pass noUpdate=>1 the method will not run updateDatabase on errors.  This is important if you doing something that could create a recursion problem.


        #
        # retrieve a reference to an array of data we asked for
        #
        my $dataArray = $fws->runSQL(SQL=>"select id,type from id_and_type_table");     # Any SQL statement or query

        #
        # loop though the array
        #
        while (@$dataArray) {

                #
                # collect the data each row at a time
                #
                my $id          = shift(@$dataArray);
                my $type        = shift(@$dataArray);

                #
                # display or do something with the data
                #
                print "ID: ".$id." - ".$type."\n";
        }


=cut

sub runSQL {
        my ($self,%paramHash) = @_;

	#
	# Make sure we are connected to the default DBH
	#
        $self->connectDBH();

	#
	# if we pass a DBH lets use it
	#
	if ($paramHash{'DBH'} eq '') { $paramHash{'DBH'} = $self->{'_DBH_'.$self->{'DBName'}.$self->{'DBHost'}} }

        #
        # Get this data array ready to slurp
        # and set the failFlag for future use to autocreate a dB schema
        # based on a default setting
        #
        my @data = ();
        my $errorResponse;

        #
        # send this off to the log
        #
        $self->SQLLog($paramHash{'SQL'});

        #
        # prepare the SQL and loop though the arrays
        #

        my $sth = $paramHash{'DBH'}->prepare($paramHash{'SQL'});
        if ($sth ne '') {
                $sth->{PrintError} = 0;
                $sth->execute();

                #
                # clean way to get error response
                #
                if (defined $DBI::errstr) { $errorResponse .= $DBI::errstr }

                #
                # set the row variable ready to be populated
                #
                my $clean;

                #
                # SQL lite gathing and normilization
                #
                if ($self->{'DBType'} =~ /^SQLite$/i) {
                        while (my @row = $sth->fetchrow) {
                		my @cleanRow;
                                while (@row) {
                                        $clean = shift(@row);
                                        $clean = '' if !defined $clean;
                                        $clean =~ s/\\\\/\\/sg;
                                        push (@cleanRow,$clean);
                                }
                                push (@data,@cleanRow);
                        }
                }

                #
                # Fault to MySQL if we didn't find another type
                #
                else {
                        while (my @row = $sth->fetchrow) {
                		my @cleanRow;
                                while (@row) {
                                        $clean = shift(@row);
                                        $clean = '' if !defined $clean;
                                        push (@cleanRow,$clean);
                                }
                                push (@data,@cleanRow);
                        }
                }
        }

        #
        # check if myDBH has been blanked - if so we have an error
        # or I didn't have one to begin with
        #
        if ($errorResponse) { 
		$self->FWSLog('SQL ERROR: '.$paramHash{'SQL'});

		#
		# run update DB on an error to fix anything that was broke :(
		# if noUpdate is passed lets not do this, so we do recurse!
		#
		if($paramHash{'noUpdate'} ne '1') { $self->FWSLog('UPDATED DB: '.$self->updateDatabase()) }
	}

        #
        # return this back as a normal array
        #
        return \@data;
}

=head2 saveData

Update or create a new data record.  If guid is not provided then a new record will be created.   If you pass "newGUID" as a parameter for a new record, the new guid will not be auto generated, newGUID will be used.

        %dataHash = $fws->saveData(%dataHash);

Required hash keys if the data is new:

=over 4

=item * parent: This is the reference to where the data belongs

=item * name: This is the reference id for the record

=item * type: A valid element type

=back

Not required hash keys:

=over 4

=item * $active: 0 or 1. Default is 0 if not specified

=item * newGUID: If this is a new record, use this guid (Note: There is no internal checking to make sure this is unique)

=item * lang: Two letter language definition. (Not needed for most multi-lingual sites, only if the code has a requirement that it is splitting language based on other criteria in the control)

=item * ... Any other extended data fields you want to save with the data element

=back


Example of adding a data record

	my %paramHash;
	$paramHash{'parent'} 		= $fws->formValue('guid');
	$paramHash{'active'} 		= 1;
	$paramHash{'name'}   		= $fws->formValue('name');
	$paramHash{'title'}  		= $fws->formValue('title');
	$paramHash{'type'}   		= 'site_myElement';
	$paramHash{'color'}  		= 'red';

	%paramHash = $fws->saveData(%paramHash);

Example of adding the same data record to a "data container"

	my %paramHash;
	$paramHash{'containerId'} 	= 'thisReference';
	$paramHash{'active'}		= 1;
	$paramHash{'name'}   		= $fws->formValue('name');
	$paramHash{'type'}   		= 'site_thisType';
	$paramHash{'title'}  		= $fws->formValue('title');
	$paramHash{'color'}  		= 'red';

	%paramHash = $fws->saveData(%paramHash);

Note: If the containerId does not match or exist, then one will be created in the root of your site, and the data will be added to the new one.

Example of updating a data record:

	$guid = 'someGUIDaaaaabbbbccccc';
 
	#
	# get the original hash
	#
	my %dataHash = $fws->dataHash(guid=>$guid);
 
	#
	# make some changes
	#
	$dataHash{'name'} 	= "New Reference Name";
	$dataHash{'color'} 	= "blue";
 
	#
	# Give the altered hash to the update procedure
	# 
	$fws->saveData(%dataHash);

=cut

sub saveData {
        my ($self, %paramHash) = @_;

        #
        # if siteGUID is blank, lets set it to the site we are looking at
        #
        if ($paramHash{'siteGUID'} eq '') { $paramHash{'siteGUID'} = $self->{'siteGUID'} }

        #
        # transform the containerId to the parent id
        #
        if ($paramHash{'containerId'} ne '') {
                #
                # if we don't have a container for it already, lets make one!
                #
                ($paramHash{'parent'}) = @{$self->runSQL(SQL=>"select guid from data where name='".$self->safeSQL($paramHash{'containerId'})."' and element_type='data' LIMIT 1")};
                if ($paramHash{'parent'} eq '') {

                        #
                        # recursive!!!! but because containerId isn't passed we are good :)
                        #
                        my %parentHash = $self->saveData(name=>$paramHash{'containerId'},type=>'data',parent=>$self->siteValue('homeGUID'),layout=>'0');

                        #
                        # set the =parent to the new guid
                        #
                        $paramHash{'parent'} = $parentHash{'guid'};
                }

                #
                # get rid of the containerId, and lets continue with a normal update
                #
                delete($paramHash{'containerId'});
        }

        #
        # check to see if its already used;
        #
        my %usedHash = $self->dataHash(guid=>$paramHash{'guid'});

        #
        # Lets check the "new guid" if there is one, if it matches, this is an update also
        #
        if ($usedHash{'guid'} eq '' && $paramHash{'newGUID'} ne '') {
                %usedHash = $self->dataHash(guid=>$paramHash{'newGUID'});
                if ($usedHash{'guid'} ne '') {$paramHash{'guid'} = $paramHash{'newGUID'} }
        }

        #
        # if there is no ID this is an add, else, its really just an updateData
        #
        if ($usedHash{'guid'} eq '') {
                #
                # set the active to false if its not specified
                #
                if ($paramHash{'active'} eq '') { $paramHash{'active'} = '0' }

                #
                # get the intial ID and insert the record
                #
                if ($paramHash{'newGUID'} ne '') {$paramHash{'guid'} = $paramHash{'newGUID'} }
                elsif ($paramHash{'guid'} eq '') {$paramHash{'guid'} = $self->createGUID('d')}

                #
                # if title is blank make it the name;
                #
                if ($paramHash{'title'} eq '') {$paramHash{'title'} = $paramHash{'name'} }


                #
                # insert the record
                #
                $self->runSQL(SQL=>"insert into data (guid,site_guid,created_date) values ('".$self->safeSQL($paramHash{'guid'})."','".$self->safeSQL($paramHash{'siteGUID'})."','".$self->formatDate(format=>"SQL")."')");
        }

        #
        # get the next in the org, so it will be at the end of the list
        #
        if ($paramHash{'ord'} eq '') { ($paramHash{'ord'}) = @{$self->runSQL(SQL=>"select max(ord)+1 from guid_xref where site_guid='".$self->safeSQL($paramHash{'siteGUID'})."' and parent='".$self->safeSQL($paramHash{'parent'})."'")}}

        #
        # if we are talking a type of page or home, set layout to 0 because it should not be used
        #
        if ($paramHash{'type'} eq 'page' || $paramHash{'type'} eq 'home') { $paramHash{'layout'} = '0' }

        #
        # if layout is ever blank, set it to main as a default
        #
        if ($paramHash{'layout'} eq '') { $paramHash{'layout'} = 'main' }

        #
        # add the xref record if it needs to... BUT!  only pages are aloud to have blank parents, everything else needs a parent
        #
	if ($paramHash{'type'} eq 'home' || $paramHash{'parent'} ne '') {
	        $self->_saveXRef($paramHash{'guid'},$paramHash{'layout'},$paramHash{'ord'},$paramHash{'parent'},$paramHash{'siteGUID'});
	}

	#
	# if we are talking about a home page, then we actually need to set this as "page"
	#
	if ($paramHash{'type'} eq 'home') { $paramHash{'type'} ='page' }
	
        #
        # now before we added something new we might need a new index, lets reset it for good measure
        #
        $self->setCacheIndex();

        #
        # Save the data minus the extra fields
        #
        $self->runSQL(SQL=>"update data set extra_value='',show_mobile='".$self->safeSQL($paramHash{'showMobile'})."',show_login='".$self->safeSQL($paramHash{'showLogin'})."',default_element='".$self->safeSQL($paramHash{'default_element'})."',disable_title='".$self->safeSQL($paramHash{'disableTitle'})."',disable_edit_mode='".$self->safeSQL($paramHash{'disableEditMode'})."',disable_title='".$self->safeSQL($paramHash{'disableTitle'})."',lang='".$self->safeSQL($paramHash{'lang'})."',friendly_url='".$self->safeSQL($paramHash{'friendlyURL'})."', page_friendly_url='".$self->safeSQL($paramHash{'pageFriendlyURL'})."', active='".$self->safeSQL($paramHash{'active'})."',nav_name='".$self->safeSQL($paramHash{'navigationName'})."',name='".$self->safeSQL($paramHash{'name'})."',title='".$self->safeSQL($paramHash{'title'})."',element_type='".$self->safeSQL($paramHash{'type'})."' where guid='".$self->safeSQL($paramHash{'guid'})."' and site_guid='".$self->safeSQL($paramHash{'siteGUID'})."'");

        #
        # loop though and update every one that is diffrent
        #
        for my $key ( keys %paramHash ) {
                if ($key !~ /^(ord|pageIdOfElement|keywordScore|navigationName|showResubscribe|guid_xref_site_guid|groupId|lang|friendlyURL|pageFriendlyURL|type|guid|siteGUID|newGUID|showMobile|name|element_type|active|title|disableTitle|disableEditMode|defaultElement|showLogin|parent|layout|site_guid)$/) {
                        $self->saveExtra(table=>'data',siteGUID=>$paramHash{'siteGUID'},guid=>$paramHash{'guid'},field=>$key,value=>$paramHash{$key});
                }
        }

        #
        # update the modified stamp
        #
        $self->updateModifiedDate(%paramHash);

        #
        # update the cache data directly
        #
        $self->updateDataCache(%paramHash);

        #
        # return anything created in the paramHash that was changed and already present
        #
        return %paramHash;
}



=head2 saveExtra

Save data that is part of the extra hash for a FWS table.

        $self->saveExtra(	table		=>'table_name',
				siteGUID	=>'site_guid_not_required',
				guid		=>'some_guid',
				field		=>'table_field','the value we are setting it to');

=cut

sub saveExtra {
        my ($self,%paramHash) = @_;

        #
        # make sure we are on a compatable table
        #
        #if ($self->{'dataSchema'}{$paramHash{'table'}}{'extra_value'}{'type'} ne '') {
	
		#
	        # set site GUID if it wasn't passed to us
	        #
	        if ($paramHash{'siteGUID'} eq '') {$paramHash{'siteGUID'} = $self->{'siteGUID'} }



                #
                # set up the site_sid restriction... but a lot of table types don't use
                #
                my $addToWhere = " and site_guid='".$self->safeSQL($paramHash{'siteGUID'})."'";
		if ($self->{'dataSchema'}{$paramHash{'table'}}{'site_guid'}{'noSite'} eq '1')	{  $addToWhere = '' }

                #
                # get the hash from the id we are pulling from
                #
                my ($extraValue) = @{$self->runSQL(SQL=>"select extra_value from ".$self->safeSQL($paramHash{'table'})." where guid='".$self->safeSQL($paramHash{'guid'})."'".$addToWhere)};


                #
                # if crypt password is set, then crypt it up!
                #
                if ($self->{'dataSchema'}{$paramHash{'table'}}{'extra_value'}{'encrypt'} eq '1')          { $extraValue = $self->FWSDecrypt($extraValue) }

                #
                # pull the hash out
                #
                use Storable qw(nfreeze thaw);
                my %extraHash;
                if ($extraValue ne '') { %extraHash = %{thaw($extraValue)} }

                #
                # add the new one
                #
                $extraHash{$paramHash{'field'}} = $paramHash{'value'};

                #
                # convert back to a hash string
                #
                my $hash = nfreeze(\%extraHash);

                #
                # encrypt if we are the trans table
                #
                if ($self->{'dataSchema'}{$paramHash{'table'}}{'extra_value'}{'encrypt'} eq '1')          { $hash = $self->FWSEncrypt($hash) }

                #
                # update the hash in the db
                #
                $self->runSQL(SQL=>"update ".$self->safeSQL($paramHash{'table'})." set extra_value='".$self->safeSQL($hash)."' where guid='".$self->safeSQL($paramHash{'guid'})."'".$addToWhere);

                #
                # update the cache table if we are on the data table
                #
                if ($paramHash{'table'} eq 'data') {

                        #
                        # pull the data has, update it, then send it to the cache
                        #
                        $self->updateDataCache($self->dataHash(guid=>$paramHash{'guid'}));
                }
        #}
}





=head2 saveHash

Save a generic hash to a hash object in the same fasion as other FWS save objects.  If the object exists already it will udpate it, or add a new one if it did not exist

	#
	# add a new object
	#
	$someHash{'someArray'} = $fws->saveHash( hashArray       => $someHash{'someArray'},
                                                 date            => $fws->dateTime(format=>'SQL'),

	#
	# update a object that contains its perspective guid
	#
	$someHash{'someArray'} = $fws->saveHash( hashArray       => $someHash{'someArray'},%existingDataThatIsUpdated );

=cut


sub saveHash {
        my ($self,%paramHash) = @_;

        #
        # get the current array, and clear the loc string
        #
        my @hashArray = $self->hashArray(%paramHash);
        my @newArray;
        my $hashUpdated = 0;

        #
        # lets not keep the refrence to the hashArray itself, that would be nasty if we saved it!
        #
        delete $paramHash{'hashArray'};

        #
        # go though each one of the shippingLocation items, figure out what one is being updated and update it!
        #
        for my $i (0 .. $#hashArray) {

                #
                # update the loc with the same guid with the new hash
                #
                if ($paramHash{'guid'} eq $hashArray[$i]{'guid'}) {

                        #
                        # update the flag, to know we are NOT talking about adding a new one and append to the line
                        #
                        push(@newArray,{%paramHash});
                        $hashUpdated = 1;
                        }
                #
                # update the loc with the same thing but repackaged (no change was made)
                #
                else { push(@newArray,{%{$hashArray[$i]}}) }
        }

        #
        # if we dindn't update then this is an add
        #
        if (!$hashUpdated) {
                $paramHash{'guid'} = $self->createGUID('h');
                push(@newArray,{%paramHash})
        }
        return (nfreeze(\@newArray));
}


=head2 saveQueue

Save a hash to the process and message queue.

        %queueHash = $fws->saveQueue(%queueHash);

=cut

sub saveQueue {
        my ($self,%paramHash) = @_;
        %paramHash = $self->runScript('preSaveQueue',%paramHash);

        %paramHash = $self->_recordInit('_guidLeader'   =>'q',
                                        '_table'        =>'queue',
                                        %paramHash);

        %paramHash = $self->_recordSave('_fields'        =>'directory_guid|profile_guid|queue_from|hash|queue_to|from_name|draft|type|subject|digital_assets|transfer_encoding|mime_type|body|scheduled_date',
                                        '_keys'          =>'directoryGUID|userGUID|from|hash|to|fromName|draft|type|subject|digitalAssets|transferEncoding|mimeType|body|scheduledDate',
                                        '_table'        =>'queue',
                                        '_noExtra'      =>'1',
                                        %paramHash);


        %paramHash = $self->runScript('postSaveQueue',%paramHash);

        return %paramHash;
}

=head2 saveQueueHistory

Save a hash to the process and message queue history.

        %queueHash = $fws->saveQueueHistory(%queueHash);

=cut

sub saveQueueHistory {
        my ($self,%paramHash) = @_;
        
	%paramHash = $self->runScript('preSaveQueueHistory',%paramHash);
      
	#
        # if sent date isn't set,  lets set it to NOW
        #
        if ($paramHash{'sentDate'} eq '' || $paramHash{'sentDate'}  =~ /^0000.00.00/) { $paramHash{'sentDate'} = $self->safeSQL($self->formatDate(format=>"SQL")) }

        %paramHash = $self->_recordInit('_guidLeader'   =>'q',
                                        '_table'        =>'queue_history',
                                        %paramHash);

        %paramHash = $self->_recordSave('_fields'       =>'synced|queue_guid|directory_guid|profile_guid|hash|scheduled_date|queue_from|from_name|queue_to|body|type|subject|success|failure_code|response|sent_date',
                                        '_keys'         =>'synced|queueGUID|directoryGUID|profileGUID|hash|scheduledDate|from|fromName|to|body|type|subject|success|failureCode|response|sentDate',
                                        '_table'        =>'queue_history',
                                        '_noExtra'      =>'1',
                                        %paramHash);

        %paramHash = $self->runScript('postSaveQueueHistory',%paramHash);

        return %paramHash;
}

=head2 schemaHash

Return the schema hash for an element.  You can pass either the guid or the element type.

        my %schemaHash = $fws->schemaHash('someGUIDorType');

=cut

sub schemaHash {
        my ($fws,$guid) = @_;

	#
	# Get it from the element hash, (with caching enabled)
	#
	my %elementHash = $fws->elementHash(guid=>$guid);

        #
        # copy the self object to fws
        #
        #my $fws = $self;
        
	#
        # make sure schemaHash is defined before we run the code
        #
        my %dataSchema;

        #
        # run the eval and populate the hash (Including the title)
        #
        eval $elementHash{'schemaDevel'};
        my $errorCode = $@;
        if ($errorCode) { $fws->FWSLog('SCHEMA ERROR: '.$guid.' - '.$errorCode) }

        #
        # now put it back
        #
        #$self = $fws;

        return %dataSchema;
}


=head2 setCacheIndex

Set a sites cache index for its site.  you can bas a siteGUID as a hash parameter if you wish to update the index for a site not currently being rendered.

        $fws->setCacheIndex();

=cut

sub setCacheIndex {
        my ($self,%paramHash) = @_;
        
	#
        # set site GUID if it wasn't passed to us
        #
        if ($paramHash{'siteGUID'} eq '') {$paramHash{'siteGUID'} = $self->{'siteGUID'} }
        
	my @indexArray;
	my %elementHash = $self->_fullElementHash();
  	for my $elementGUID ( keys %elementHash ) {
		my %schemaHash = $self->schemaHash($elementGUID);

                #
                #  loop though each one and if the index is set to one, add it to the index list
                #
                for my $key ( keys %schemaHash) {
                        if ($schemaHash{$key}{index} eq '1') { push (@indexArray,$key) }
                }
        }

        #
        # create a comma delemited list that is the inexed fields
        #
        my $cacheValue = join(',',@indexArray);

        #
        # update the extra table of what the cacheIndex is
        #
	if ($self->siteValue('dataCacheIndex') ne $cacheValue) {
		$self->FWSLog("Setting new site cache index: ".$cacheValue);
        	$self->saveExtra(table=>'site',guid=>$paramHash{'siteGUID'},field=>'dataCacheIndex',value=>$cacheValue);
	}
}


=head2 sortArray

Return a sorted array reference by passing the array reference, what key to sort by, and numrical or alpha sort.

	#
	# type: alpha|number
	# key: the key you are sorting by
	# array: an array reference
	#
	my $arrayRef = $fws->sortArray(key=>'id',type=>'alpha',array=>\@someArray); 

=cut

sub sortArray {
        my ($self,%paramHash) = @_;
	my @returnArray = @{$paramHash{'array'}};
	
	if ($paramHash{'type'} eq 'number') {
        	@returnArray = (map{$_->[1]} sort {$a->[0] <=> $b->[0]} map{[$_->{$paramHash{'key'}},$_]} @returnArray)
        }
	else {
        	@returnArray = (map{$_->[1]} sort {$a->[0] cmp $b->[0]} map{[$_->{$paramHash{'key'}},$_]} @returnArray)
	}
	return \@returnArray;
}

=head2 tableFieldHash

Return a multi-dimensional hash of all the fields in a table with its properties.  This usually isn't used by anything but internal table alteration methods, but it could be useful if you are making conditionals to determine the data structure before adding or changing data.  The method is CPU intensive so it should only be used when performance is not a requirement.

        $tableFieldHashRef = $fws->tableFieldHash('the_table');

The return dump will have the following structure:

        $tableFieldHashRef->{field}{type}
        $tableFieldHashRef->{field}{ord}
        $tableFieldHashRef->{field}{null}
        $tableFieldHashRef->{field}{default}
        $tableFieldHashRef->{field}{extra}
        
If the field is indexed it will return a unique table field combination key equal to MUL or FULLTEXT:
	
	$tableFieldHashRef->{thetable_field}{key} 

=cut

sub tableFieldHash {
        my ($self,$table) = @_;

        #
        # set an order counter so we can sort by this if needed
        #
        my $fieldOrd = 0;

        #
        # if we have a cached version lets make one
        #
        if (!keys %{$self->{'_'.$table.'FieldCache'}}) {

                #
                # grab the table def hash for mysql
                #
                if ($self->{'DBType'} =~ /^mysql$/i) {
                        my $tableData = $self->runSQL(SQL=>"desc ".$self->safeSQL($table));
                        while (@$tableData) {
                                $fieldOrd++;
                                my $fieldInc  			                                  = shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'type'}              = shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'ord'}               = $fieldOrd;
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'null'}              = shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$table."_".$fieldInc}{'key'}    = shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'default'}           = shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'extra'}             = shift(@$tableData);
                        }
                }

                #
                # grab the table def hash for sqlite
                #
                if ($self->{'DBType'} =~ /^sqlite$/i) {
                        my $tableData = $self->runSQL(SQL=>"PRAGMA table_info(".$self->safeSQL($table).")");
                        while (@$tableData) {
                                $fieldOrd++;
        		                                                                shift(@$tableData);
                                my $fieldInc =  		                        shift(@$tableData);
                       		                                	                shift(@$tableData);
                               		                                	        shift(@$tableData);
                                       		                                	shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'type'} =  shift(@$tableData);
                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{'ord'}  = $fieldOrd;
                        }

                        $tableData = $self->runSQL(SQL=>"PRAGMA index_list(".$self->safeSQL($table).")");
                        while (@$tableData) {
                                                        				shift(@$tableData);
                                my $fieldInc =          				shift(@$tableData);
                                                        				shift(@$tableData);

                                $self->{'_'.$table.'FieldCache'}->{$fieldInc}{"key"} = 	"MUL";
                        }
                }
        }
	return %{$self->{'_'.$table.'FieldCache'}};

}



=head2 updateDataCache

Update the cache version of the data record.  This is called automatically when saveData is called.

        $fws->updateDataCache(%theDataHash);

=cut

sub updateDataCache {
        my ($self,%dataHash) = @_;

        #
        # get the field hash so we don't have to try to add fields that might not be there EVERY time
        #
        my %tableFieldHash = $self->tableFieldHash("data_cache");

        #
        # set the page id of the guid for easy access on search pages
        #
        $dataHash{'pageIdOfElement'} = $self->getPageGUID($dataHash{'guid'});

        #
        # get the page hash of the page, and update the page description to the data for easy access on search pages
        #
        my %pageHash = $self->dataHash(guid=>$dataHash{'pageIdOfElement'});
        $dataHash{'pageDescription'} = $pageHash{'pageDescription'};

        #
        # get what fields we are aloud to use
        #
        my %dataCacheFields = %{$self->{"dataCacheFields"}};

        #
        # we will be building these up while we loop
        #
        my $fields = '';
        my $values = '';

        #
        # make any fields that "might" be needed
        #
        foreach my $key ( keys %dataHash ) {
                if ($dataCacheFields{$key} eq '1' || $key eq 'site_guid' || $key eq 'guid' || $key eq 'name' || $key eq 'title' || $key eq 'pageIdOfElement' || $key eq 'pageDescription') {

                        #
                        # if the type is blank, then this is new
                        #
                        if ($tableFieldHash{$key}{'type'} eq '') {
                                #
                                # alter tha table
                                #
                                $self->alterTable(table=>"data_cache",field=>$key,type=>"text",key=>"FULLTEXT",default=>"");
                        }



                        #
                        # append the new data to the strings we are using to create the insert statement
                        #
                        $fields .= $self->safeSQL($key).',';
                        $values .= "'".$self->safeSQL($dataHash{$key})."',";
		}
        }

        #
        # clean up the commas at the end of values and fields
        #
        $fields =~ s/,$//sg;
        $values =~ s/,$//sg;

        #
        # remove the one that "might" be there
        #
        $self->runSQL(SQL=>"delete from data_cache where guid='".$self->safeSQL($dataHash{'guid'})."'");

        #
        # add the the new one
        #
        $self->runSQL(SQL=>"insert into data_cache (".$fields.") values (".$values.")");
}

=head2 userArray

Return an array or reference to an array of the users on an installation.    You can pass they keywords paramater and it will look though name and email address.

=cut

sub userArray {
        my ($self,%paramHash) = @_;
        my @userHashArray;

        #
        # add keyword Search
        #
        my $whereStatement;
        my $keywordsSQL = $self->_getKeywordSQL($paramHash{"keywords"},"name","email","extra_value");
        if ($keywordsSQL ne '') { $whereStatement = 'where '.$keywordsSQL };

        #
        # get the data from the database and push it into the hash array
        #
        my $userArray = $self->runSQL(SQL=>"select fb_id,fb_access_token,name,email,guid,active,extra_value from profile ".$whereStatement);
        while (@$userArray) {
                #
                # fill in the hash
                #
                my %userHash;
                $userHash{'FBId'}               = shift(@$userArray);
                $userHash{'FBAccessToken'}      = shift(@$userArray);
                $userHash{'name'}               = shift(@$userArray);
                $userHash{'email'}              = shift(@$userArray);
                $userHash{'guid'}               = shift(@$userArray);
                $userHash{'active'}             = shift(@$userArray);

                #
                # add the extra stuff to the hash
                #
                my $extra_value = shift(@$userArray);
                %userHash       = $self->addExtraHash($extra_value,%userHash);

                #
                # push it into the array
                #
                push (@userHashArray,{%userHash});
        }
        if ($paramHash{'ref'} eq '1') { return \@userHashArray } else {return @userHashArray }
}

=head2 updateDatabase

Alter the database to match the schema for FWS 2.   The return will print the SQL statements used to adjust the tables.

	print $fws->updateDatabase()."\n";

This method is automatically called when on the web optimized version of FWS when rendering the 'System' screen.

=cut

sub updateDatabase {
        my ($self) = @_;
        my $db = "";

        #
        # loop though the records and make or update the tables
        #
        my $dbResponse;

	for my $table ( keys %{$self->{'dataSchema'}} ) {
        	for my $field ( keys %{$self->{'dataSchema'}{$table}} ) {
               	 	my $type 	= $self->{'dataSchema'}{$table}{$field}{'type'};
               	 	my $key 	= $self->{'dataSchema'}{$table}{$field}{'key'};
               	 	my $default 	= $self->{'dataSchema'}{$table}{$field}{'default'};

			#
			# make sure this isn't a bad record.   It at least needs a table name
			#
			if ($table ne '') { $dbResponse .= $self->alterTable(table=>$table,field=>$field,type=>$type,key=>$key,default=>$default) }
        	}
	}

        return $dbResponse;
}

=head2 updateModifiedDate

Update the modified date of the page a dataHash element resides on.

        $fws->updateModifiedDate(%dataHash);

Note: By updating anything that is persistant against multiple pages all pages will have thier date updated as it is considered a site wide change.

=cut

sub updateModifiedDate {
        my ($self,%paramHash) = @_;

        #
        # it is default or not
        #
        if ($paramHash{'siteGUID'} eq '') { $paramHash{'siteGUID'} = $self->{'siteGUID'} }

        #
        # set the type to page if the id itself is a page
        #
        my ($type) = @{$self->runSQL(SQL=>"select element_type from data where guid='".$self->safeSQL($paramHash{'guid'})."' and site_guid='".$self->safeSQL($paramHash{'siteGUID'})."'")};

        #
        # if its not page loop though till it finds what page its on
        #
        my $isDefault = 0;
        my $recurCap = 0;
        while ($paramHash{'guid'} ne '' && ($type ne 'page' || $type ne 'home') && $recurCap < 100) {
                my ($defaultElement) = @{$self->runSQL(SQL=>"select default_element from data where guid='".$self->safeSQL($paramHash{'guid'})."' and site_guid='".$self->safeSQL($paramHash{'siteGUID'})."'")};
                ($paramHash{'guid'},$type) = @{$self->runSQL(SQL=>"select parent,data.element_type from guid_xref left join data on data.guid=parent where child='".$self->safeSQL($paramHash{'guid'})."' and guid_xref.site_guid='".$self->safeSQL($paramHash{'siteGUID'})."'")};
                if (!$isDefault && $defaultElement) { $isDefault = 1 }
                $recurCap++;
        }

        #
        # if id is blank that means we are updating a home page element
        #
        if ($type eq '' || $isDefault > 0 || $isDefault < 0) {
                $self->saveExtra(table=>'data',siteGUID=>$paramHash{'siteGUID'},field=>'dateUpdated',value=>time);
        }

        #
        # if is default then update ALL pages
        #
        if ($isDefault) {
                $self->saveExtra(table=>'data',siteGUID=>$paramHash{'siteGUID'},field=>'dateUpdated',value=>time);
                my @pageList = @{$self->runSQL(SQL=>"select guid from data where data.site_guid='".$self->safeSQL($paramHash{'siteGUID'})."' and (data.element_type='page' or data.element_type='home')")};
                while (@pageList) {
                        my $pageId = shift(@pageList);
                        $self->saveExtra(table=>'data',siteGUID=>$paramHash{'siteGUID'},guid=>$pageId,field=>'dateUpdated',value=>time);
                }
        }

        #
        # if the type is page, then just update that page
        #
        if ($type eq 'page' || $type eq 'home') {
                $self->saveExtra(table=>'data',siteGUID=>$paramHash{'siteGUID'},guid=>$paramHash{'guid'},field=>'dateUpdated',value=>time);
        }
}


############################################################################################
# DATA: Delete a orphened data
############################################################################################

sub _deleteOrphanedData {
        my ($self,$table,$field,$refTable,$refField,$extraWhere,$DBH) = @_;

        #
        # get the vars set for pre-processing
        #
        my $keepDeleting = 1;

        #
        # keep looping till either we are endless or
        #
        while ($keepDeleting) {

		#
		# create the SQL that will be used for the delete and the reflective query
		#
                my $fromSQL = "from ".$table." where ".$table.".".$field." in (select ".$field." from (select distinct ".$table.".".$field." from ".$table." left join ".$refTable." on ".$refTable.".".$refField." = ".$table.".".$field." where ".$refTable.".".$refField." is null ".$extraWhere.") as delete_list)";

		#
		# do the actual delete
		#
                $self->runSQL(DBH=>$DBH,SQL=>"delete ".$fromSQL);

		#
		# if we are talking about the data field, lets do the same thing to the data cache table
		#
                if ($table eq 'data') {
                        $self->runSQL(DBH=>$DBH,SQL=>"delete from ".$table."_cache where ".$table."_cache.".$field." in (select ".$field." from (select distinct ".$table."_cache.".$field." from ".$table."_cache left join ".$refTable." on ".$refTable.".".$refField." = ".$table."_cache.".$field." where ".$refTable.".".$refField." is null ".$extraWhere.") as delete_list)");
                }

		#
		# run the same fromSQL and see if anything is left
		#
                ($keepDeleting) = @{$self->runSQL(DBH=>$DBH,SQL=>"select 1 ".$fromSQL)};
        }
}

############################################################################################
# DATA: Delete a guid XRef
############################################################################################

sub _deleteXRef {
        my ($self,$child,$parent,$siteGUID) = @_;
        $self->runSQL(SQL=>"delete from guid_xref where child='".$self->safeSQL($child)."' and parent='".$self->safeSQL($parent)."' and site_guid='".$self->safeSQL($siteGUID)."'");
}

############################################################################################
# DATA: Lookup all the elements and return the hash
#
# NOTE: This does NOT pull back schema and scripts.  This is for lean element lookups
############################################################################################

sub _fullElementHash {
        my ($self,%paramHash) = @_;

        if (!keys %{$self->{'_fullElementHashCache'}}) {

                #
                # if your in an admin page, you will need this so you can see the stuff in scope for the tree views
                # it doesn't matter if it caches it, because these are ajax calls limited only to themselves
                #

                #
                # get the elementArray
                #
                my $elementArray = $self->runSQL(SQL=>"select guid,type,class_prefix,css_devel,js_devel,title,tags,parent,ord,site_guid,root_element,public,checkedout from element");


		#
		# Push the elementHash into the Cache	
		#	
		%{$self->{'_fullElementHashCache'}} = %{$self->{'elementHash'}};  


                while (@$elementArray) {
                        my $guid                                                        = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'guid'}               = $guid;
                        $self->{'_fullElementHashCache'}->{$guid}{'type'}               = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'classPrefix'}        = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'cssDevel'}           = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'jsDevel'}            = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'title'}              = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'tags'}               = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'parent'}             = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'ord'}                = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'siteGUID'}           = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'rootElement'}        = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'public'}             = shift(@$elementArray);
                        $self->{'_fullElementHashCache'}->{$guid}{'checkedout'}         = shift(@$elementArray);

               	}

		#
		# Do alpha sorting and add parent refernces if needed
		#
                my $alphaOrd = 0;
	 	for my $guid ( sort { $self->{'_fullElementHashCache'}->{$a}{'title'} cmp $self->{'_fullElementHashCache'}->{$b}{'title'} } keys %{$self->{'_fullElementHashCache'}}) {
                        $alphaOrd++;
                        $self->{'_fullElementHashCache'}->{$guid}{'alphaOrd'}           = $alphaOrd;
			my $type = $self->{'_fullElementHashCache'}->{$guid}{'type'};

                        if ($type ne '') {
                                $self->{'_fullElementHashCache'}->{$type}{'guid'}       = $guid;
                                $self->{'_fullElementHashCache'}->{$type}{'parent'}     = $self->{'_fullElementHashCache'}->{$guid}{'parent'};
                        }
		}
        }
        return %{$self->{'_fullElementHashCache'}};
}

############################################################################################
# _recordInit: do creation of a record if needed, and also set pins and guids
############################################################################################

sub _recordInit {
        my ($self, %paramHash) = @_;

        #
        # lets make sure we are not updateing the same record or adding a new one we shouldn't
        #
        if ($paramHash{'guid'} eq '') {
                #
                # set the dirived stuff so nobody gets sneeky and tries to pass it to the procedure
                #
                if ($paramHash{'siteGUID'} eq '') 	{ $paramHash{'siteGUID'} = $self->{'siteGUID'} }
                if ($paramHash{'_guidLeader'} eq '') 	{ $paramHash{'_guidLeader'} = 'r' }
                $paramHash{'siteGUID'} = $self->safeSQL($paramHash{'siteGUID'});
                $paramHash{'guid'}      = $self->createGUID($paramHash{'_guidLeader'});
                $self->runSQL(DBH=>$paramHash{'DBH'},SQL=>"insert into ".$self->safeSQL($paramHash{'_table'})." (guid,site_guid,created_date) values ('".$paramHash{'guid'}."','".$paramHash{'siteGUID'}."','".$self->formatDate(format=>"SQL")."')");
        }

        if (($paramHash{'_table'} eq 'directory' || $paramHash{'_table'} eq 'profile') && $paramHash{'pin'} eq '') {
                #
                # set the dirived stuff so nobody gets sneeky and tries to pass it to the procedure
                #
                $paramHash{'pin'} = $self->createPin();
                $self->runSQL(DBH=>$paramHash{'DBH'},SQL=>"update ".$self->safeSQL($paramHash{'_table'})." set pin='".$self->safeSQL($paramHash{'pin'})."' where guid='".$self->safeSQL($paramHash{'guid'})."'");
        }

        return %paramHash;
}

############################################################################################
# _recordHash: return a generic record hash
# 		Pass: table, where
############################################################################################

sub _recordHash {
        my ($self, %paramHash) = @_;

  	#
	# eat 's in table for safety
	#
	$paramHash{'table'} =~ s/'//sg;

        #
        # define the SQL starter statement
        #
        my $SQL = "select ";

        #
        # if fields was not passed, we assume we have matching field and keys based on the schema
        #
        for my $field ( keys %{$self->{'dataSchema'}{$paramHash{'table'}}} ) {
                if ($self->{'dataSchema'}{$paramHash{'table'}}{$field}{'name'} ne '') {
			# for safety lets eat any tic in the field name
			$field =~ s/'//sg;
                        $SQL .= "'".$self->safeSQL($self->{'dataSchema'}{$paramHash{'table'}}{$field}{'name'})."',".$field.",";
                }
        }
	$SQL =~ s/,$//sg;

	#
	# do extra value if this table has one
	#
	if ($self->{'dataSchema'}{$paramHash{'_table'}}{'extra_value'}{'type'} ne '') { $SQL .= ',extra_value' }
	
	#
	# get the hash
	#
	my @returnArray = @{$self->runSQL(DBH=>$paramHash{'DBH'},SQL=>$SQL." from ".$paramHash{'table'}." where ".$paramHash{'where'})};

	#
	# pop off the ext values
	#
	if ($self->{'dataSchema'}{$paramHash{'_table'}}{'extra_value'}{'type'} ne '') {
		my $extraValue = pop(@returnArray);
        	return $self->addExtraHash($extraValue,@returnArray);
	}

	#
	# if no ext value, then return the whole thing
	#
	return @returnArray;
}


############################################################################################
# _recordSave: save a record with generic record structure
############################################################################################

sub _recordSave {
        my ($self, %paramHash) = @_;

        #
        # for completeness lets hold on to this so we can return it
        #
        my %paramHolder = %paramHash;

        #
        # define the SQL starter statement
        #
        my $SQL = "update ".$self->safeSQL($paramHash{'_table'})." set ";

	#
	# if fields was not passed, we assume we have matching field and keys based on the schema
	#
	if ($paramHash{'_keys'} eq '' || $paramHash{'_fields'} eq '') {
	        for my $field ( keys %{$self->{'dataSchema'}{$paramHash{'_table'}}} ) {
			if ($self->{'dataSchema'}{$paramHash{'_table'}}{$field}{'save'} eq '1') {
				$paramHash{'_keys'} 	.= $self->{'dataSchema'}{$paramHash{'_table'}}{$field}{'name'}.'|';
				$paramHash{'_fields'} 	.= $field.'|';
	        	}
	        }
		$paramHash{'_keys'} =~ s/\|$//sg;
		$paramHash{'_fields'} =~ s/\|$//sg;
	}

        #
        # make arrays usable
        #
        my @fields 	= split(/\|/,$paramHash{'_fields'});
        my @fieldKeys 	= split(/\|/,$paramHash{'_keys'});

        #
        # add each field thats a core field
        #
        for my $i (0 .. $#fields) {
                $SQL .= $fields[$i]."='".$self->safeSQL($paramHash{$fieldKeys[$i]})."'," ;
                #
                # for the next step delete the keys that should not be updated
                #
                delete $paramHash{$fieldKeys[$i]};
        }

        #
        # trim off last ,
        #
        $SQL =~ s/,$//sg;

	#
	# default key is guid
	#
	if ($paramHash{'keyField'} eq '') {		$paramHash{'keyField'} = 'guid' }
	if ($paramHash{'keyValueKey'} eq '') {		$paramHash{'keyValueKey'} = 'guid' }

        #
        # add scope to the statement
        #
        $SQL .= " where ".$self->safeSQL($paramHash{'keyField'})."='".$self->safeSQL($paramHash{$paramHash{'keyValueKey'}})."'";

        $self->runSQL(DBH=>$paramHash{'DBH'},SQL=>$SQL);

        #
        # save the keys in the ext field;
        #
        my $keyReg = $paramHash{'_keys'};
        for my $key ( keys %paramHash ) {
                if (    $key !~ /^_/ &&
                        $key !~ /^guid$/ &&
                        $key !~ /^site_guid$/ &&
                        $key !~ /^created_date$/ &&
                        $key !~ /^createdDate$/ &&
                        $key !~ /^siteGUID$/ &&
                        $key !~ /^pin$/) {
			if ($self->{'dataSchema'}{$paramHash{'_table'}}{'extra_value'}{'type'} ne '') {
                        	$self->saveExtra(DBH=>$paramHash{'DBH'},table=>$paramHash{'_table'},guid=>$paramHash{'guid'},field=>$key,value=>$paramHash{$key});
				}
                }
        }
        return %paramHolder;
}

############################################################################################
# FORMAT: Pass keywords and field list, and create a wellformed where statement for keyword
#         searches
############################################################################################

sub _getKeywordSQL {
        my ($self,$keywords,@likeFields) = @_;
        #
        # Grab everything that is in quotes
        #
        my @exactMatches = ();
        while ($keywords =~ /"/) {
                $keywords =~ /(".*?")/g;
                my $currentMatch = $1;
                $keywords =~ s/$currentMatch//g;
                $currentMatch =~ s/"//g;
                push (@exactMatches,$currentMatch);
        }

        #
        # split them up and add the exact matches
        #
        my @keywordsSplit = split(' ',$keywords);
        push (@keywordsSplit,@exactMatches);


        #
        # build the SQL
        #
        my $keywordSQL ='';
        foreach my $keyword (@keywordsSplit) {
                if ($keyword ne '') {
                        my $fieldSQL = '';
                        foreach my $likeField (@likeFields) {
                                $fieldSQL .= $self->safeSQL($likeField)." LIKE '%".
                                $self->safeSQL($keyword)."%' or ";
                                }
                        $fieldSQL =~ s/ or $//sg;
                        if ($fieldSQL ne '') {
                                $keywordSQL .= "( ".$fieldSQL." )";
                                $keywordSQL .= " and ";
                        }
                }
        }

        #
        # kILL THE last and and then wrap it in parans so it will fit will in sql statements
        #
        $keywordSQL =~ s/ and $//sg;
        return $keywordSQL;
}

############################################################################################
# DATA: Save a guid XRef
############################################################################################

sub _saveXRef {
        my ($self,$child,$layout,$ord,$parent,$siteGUID) = @_;

	#
	# delete the old one if its there
	#
        $self->_deleteXRef($child,$parent,$siteGUID);

	#
	# add the new one
	#
        $self->runSQL(SQL=>"insert into guid_xref (child,layout,ord,parent,site_guid) values ('".$self->safeSQL($child)."','".$self->safeSQL($layout)."','".$self->safeSQL($ord)."','".$self->safeSQL($parent)."','".$self->safeSQL($siteGUID)."')");

}

=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Database


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


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::Database
