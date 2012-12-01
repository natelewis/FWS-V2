package FWS::V2::Format;

use 5.006;
use strict;

=head1 NAME

FWS::V2::Format - Framework Sites version 2 text and html formatting

=head1 VERSION

Version 0.004

=cut

our $VERSION = '0.004';

=head1 SYNOPSIS

	use FWS::V2;
	
	my $fws = FWS::V2->new();

        my $tempPassword = $fws->createPassword( lowLength => 6, highLength => 8);

	my $newGUID = $fws->createGUID();



=head1 DESCRIPTION

Framework Sites version 2 methods that use or manipulate text either for rendering or default population.

=head1 METHODS

=head2 createGUID

Return a non repeatable Globally Unique Identifier to be used to populate the guid field that is default on all FWS tables.

        #
        # retrieve a guid to use with a new record
        #
        my $guid = $fws->createGUID();

In version 2 all GUID's have a prefix, if not specified it will be set to 'd'.  There should be no reason to use another prefix, but if you wish you can add it as the only parameter it will be used.  In newer versions of FWS the prefix will eventually be deprecated and is only still present for compatibility.

=cut

sub createGUID {
        my ($self,$guid) =@_;

	#
	# Version 2 guids are always prefixed with a character, if you don't pass one
	# lets make it 'd'
	#
        if ($guid eq '') { $guid = 'd' }

        use Digest::SHA1 qw(sha1);
        return $guid . join('', unpack('H8 H4 H4 H4 H12', sha1( shift().shift().time().rand().$<.$$)));
}

=head2 activeToggleIcon

Create a on off admin lightbulb for an item that will work if you are logged in as an edit mode editor role.  Pass a data hash, and append ajaxUpdateTable if it is not updating the standard data table.

=cut

sub activeToggleIcon {
        my ($self,%paramHash) = @_;

	my $table = 'data';
	if ($paramHash{'ajaxUpdateTable'} ne '') { $table = $paramHash{'ajaxUpdateTable'} }

        if ($paramHash{'active'} ne '1') {
                return $self->FWSIcon(    icon    => "lightbulb_off_16.png",
                                          onClick =>      "var currentState = 1; if (this.src.substr(this.src.length-9,2) == 'on')".
                                                          "{this.src='".$self->{'fileFWSPath'}.
                                                          "/icons/lightbulb_off_16.png'; currentState = 0; } else { this.src='".$self->{'fileFWSPath'}.
                                                          "/icons/lightbulb_on_16.png';};\$('<div></div>').FWSAjax({queryString:'".
                                                          "&value='+currentState+'&guid=".$paramHash{'guid'}.
                                                          "&table=".$table."&field=active&pageAction=AJAXUpdate&returnStatusNote=1',showLoading:false});",
                                          title   => "Active Toggle",
                                          alt     => "Active Toggle",
                                          style   => $paramHash{'style'},
                                          width   => "16");
        }
        else {
                return $self->FWSIcon(    icon    => "lightbulb_on_16.png",
                                          onClick =>      "var currentState = 1; if (this.src.substr(this.src.length-9,2) == 'on')".
                                                          "{this.src='".$self->{'fileFWSPath'}.
                                                          "/icons/lightbulb_off_16.png'; currentState = 0; } else { this.src='".$self->{'fileFWSPath'}.
                                                          "/icons/lightbulb_on_16.png';};\$('<div></div>').FWSAjax({queryString:'".
                                                          "&value='+currentState+'&guid=".$paramHash{'guid'}.
                                                          "&table=".$table."&field=active&pageAction=AJAXUpdate&returnStatusNote=1',showLoading:false});",
                                          style   => $paramHash{'style'},
                                          title   => "Active Toggle",
                                          alt     => "Active Toggle",
                                          width   => "16");
        }
}

=head2 applyLanguage

Apply the langague to a hash, so it will return as if the current sessions language is returned as the default keys.

        #
        # retrieve a guid to use with a new record
        #
        %dataHash = $fws->applyLanguage(%dataHash);

=cut


sub applyLanguage {
        my ($self,%langHash) =@_;

	#
	# init the return hash
	#
	my %returnHash;

	#
	# go though each one
	#	
	foreach my $key (keys %langHash) {

		#
		# if it doesn't eend with a language notation, then run the field
		#
		if ($key !~ /_\w\w$/ && $key !~ /_id/i) { $returnHash{$key} = $self->field($key,%langHash) }
		else  { $returnHash{$key} = $langHash{$key} }
	}
	#
	# return our hash we created
	#
	return %returnHash;
}

=head2 createPin

Return a short pin for common data structures.

        #
        # retrieve a guid to use with a new record
        #
        my $pin = $fws->createPin();

This pin will be checked against the directory, and profile tables to make sure it is not repeated and by default be 6 characters long with only easy to read character composition (23456789QWERTYUPASDFGHJKLZXCVBNM).

=cut

sub createPin {
        my ($self,$class) = @_;
        my $newPin;

        #
        # run a while statement until we get a guid that isn't arelady used
        #
        while ($newPin eq '') {
                $newPin = $self->createPassword(composition=>'23456789QWERTYUPASDFGHJKLZXCVBNM',lowLength=>6,highLength=>6);
                my ($foundItUser)               = $self->openRS("select 1 from profile where pin='".$newPin."'");
                my ($foundItDirectory)          = $self->openRS("select 1 from directory where pin='".$newPin."'");
                if ($foundItDirectory || $foundItUser ) { $newPin = '' }
                }
        return $newPin;
        }

=head2 createPassword

Return a random password or text key that can be used for temp password or unique configurable small strings.

        #
        # retrieve a password that is 6-8 characters long and does not contain commonly mistaken letters
        #
        my $tempPassword = $fws->createPassword(
                                        composition     => "abcedef1234567890",
                                        lowLength       => 6,
                                        highLength      => 8);

If no composition is given, a vocal friendly list will be used: qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM23456789

=cut

sub createPassword {
        my ($self, %paramHash) = @_;

	#
	# PH for return
	#
	my $returnString;

	#
	# set the composition to the easy say set if its blank
	#
	if ($paramHash{'composition'} eq '') { $paramHash{'composition'} = "qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM23456789" }

        my @pass = split //,$paramHash{'composition'};
        my $length = int(rand($paramHash{'highLength'} - $paramHash{'lowLength'} + 1)) + $paramHash{'lowLength'};
        for(1..$length) { $returnString .= $pass[int(rand($#pass))] }
        return $returnString;
}



=head2 dateDiff

Return the amount of time between two dates in days or seconds.

Possible Parameters:

=over 4

=item * date

The base date to compare against

=item * compDate

A date in the future or past compare it to.  If not passed, the current date will be used.

=item * format

The date format used.  Default is SQLTime,  you can choose epoch as an alternative

=item * type

The compare type to return as.  Default is in 'seconds', you set this to 'days' if you would like the amount in days with its remainder as a decimal.

=back

=cut

sub dateDiff {
        my ($self,%paramHash) = @_;

	my $format = 'SQLTime';
	
	my $epoch1 = $self->formatDate(format=>'epoch',$format=>$paramHash{date});
	my $epoch2 = $self->formatDate(format=>'epoch',$format=>$paramHash{compDate});
	
	my $secDiff = ($epoch2 - $epoch1);

	#
	# if its 0 lets get out of here so we don't have devide by 0 errors
	#
	if ($secDiff == 0) { return 0 }

	if ($paramHash{'type'} =~ /day/i) {
		return $secDiff / 86400;
	}
	else {
		return $secDiff;
	}	
}


=head2 formatDate

Return the date time in a given format.  By passing epochTime, SQLTime you can do a time conversion from that date/time to what ever format is set to.  If you do not pass epoch or SQL time the server time will be used.

        #
        # get the current Date in SQL format
        #
        my $currentDate = $fws->formatDate(format=>'date');
        
	#
        # convert SQL formated date time to a human form
        #
        my $humanDate = $fws->formatDate(SQLTime=>'2012-10-12 10:09:33',format=>'date');

By passing monthMod or dayMod you can adjust the month forward or backwards by the given number of months or days

	#
	# 3 months from today (negative numbers are ok)
	#
	my $threeMonths = $fws->formatDate(format=>'date',monthMod=>3);

Multilingual support: French date formats will be used  for 'fancyDate' and 'date' if the language() is set to FR.

Possible Parameters:

=over 4

=item * format

Format type to return.  This is the only required field

=item * epochTime

epoch time which could be created with time()

=item * monthMod

modify the current month ahead or behind.  (Note: If your current day is 31st, and you mod to a month that has less than 31 days it will move to the highest day of that month)

=item * dayMod

modify the current day ahead or behind.

=item * dateSeparator

This will default to '-', but can be changed to anything.   (Note: Do not use this if you are returing SQLTime format)

=item * GMTOffset

Time zone modifier.  Example: CST would be -5

=item * numberTime

Use an number translated time format (It looks like SQL without sperators)  YYYYMMDDHHMMSS.  HHMMSS will default to 000000 if not passed.

=item * SQLTime

Use an SQL time format as the incomming date and time.

=item * ISO8601

Use GMT based ISO8601 formated time as the incomming date and time.

=back

The following types of formats are valid:

=over 4

=item * date

mm-dd-yyyy

=item * time

hh:mmAM XXX

=item * shortDate

MMM DD YYYY  (MMM is the three letter acrynomn for the month in caps)

=item * fancyDate

weekdayName, monthName dd[st|nd|rd] of yyyy

=item * cookie

cookie compatible date/time

=item * apache

apache web server compatible date/time

=item * number

yyyymmddhhmmss

=item * dateTime

mm-dd-yyyy hh:mmAM XXX

=item * dateTimeFull

mm-dd-yyyy hh:mm:ss XXX

=item * SQL

yyyy-mm-dd hh:mm:ss

=item * epoch

Standard epoch number

=item * yearFirstDate

yyyy-mm-dd

=item * year

yyyy

=item * month

mm

=item * day

dd

=item * ISO8601

YYYY-MM-DDTHH:MM:SSZ (The Z and the T are literal.  This format will always return GMT, but when epoch, and SQLTime are passed, they should passed as server time because they will be converted to GMT on the based on $fws->{GMTOffset} site setting)

=back

=cut

sub formatDate {
        my ($self,%paramHash) = @_;
        my $format     		= $paramHash{'format'};
        my $monthMod    	= $paramHash{'monthMod'};
        my $dayMod    		= $paramHash{'dayMod'};
        my $POSIXTime   	= $paramHash{'POSIXTime'};
        my $epochTime   	= $paramHash{'epochTime'};
        my $dateSeparator 	= $paramHash{'dateSeparator'};

	#
	# default the separator to a dash
	#
	if ($dateSeparator eq '') { $dateSeparator = '-' };
        

	#
	# set up the ISO8601 date time and make it SQL with the GMTOffset and then process form there
	#
	if ($paramHash{'ISO8601'} ne '') {
		$paramHash{'GMTOffset'} 	= $self->{GMTOffset};
		$paramHash{'SQLTime'} 		= $paramHash{'ISO8601'};
		$paramHash{'SQLTime'} 		=~ s/T/ /sg;
		$paramHash{'SQLTime'} 		=~ s/Z//sg;
	}

	#
	# pase numbers or sql times
	#
        if ($paramHash{'numberTime'} ne '' || $paramHash{'SQLTime'} ne '') {
               
		# 	
		# do sql by default, but overwrite with numberTime if thats what it is
		#
		my @timeSplit = split(/[ \-:]/,$paramHash{'SQLTime'});
        	if ($paramHash{'numberTime'} ne '') {
	                $timeSplit[0] = substr($paramHash{'numberTime'},0,4);
	                $timeSplit[1] = substr($paramHash{'numberTime'},4,2);
	                $timeSplit[2] = substr($paramHash{'numberTime'},6,2);
	                $timeSplit[3] = substr($paramHash{'numberTime'},8,2);
	                $timeSplit[4] = substr($paramHash{'numberTime'},10,2);
	                $timeSplit[5] = substr($paramHash{'numberTime'},12,2);
		}
                
		#
		# fix anything that could rock the boat
		#
		if ( $timeSplit[0] < 1970) {$timeSplit[0] = '1970';}
                if ( $timeSplit[1] eq '' || $timeSplit[1] == 0) {$timeSplit[1] = '1'}
                if ( $timeSplit[2] eq '' || $timeSplit[2] == 0) {$timeSplit[2] = '1'}
                if ( $timeSplit[3] eq '') {$timeSplit[3] = '0'}
                if ( $timeSplit[4] eq '') {$timeSplit[4] = '0'}
                if ( $timeSplit[5] eq '') {$timeSplit[5] = '0'}

		#
		# fix the month and make it epoch to use for the rest of the script
		#
                $timeSplit[1]--;
                require Time::Local;
                Time::Local->import();
                $epochTime = timelocal(reverse(@timeSplit));
        }
	
        #
        # $format = odbc, date, time, dateAndTime, SQL, number
        #
        if ($epochTime eq '') { $epochTime = time() }
        
	#
	# offset the time if reqested to
	# 
	$epochTime += ($paramHash{'GMTOffset'} * 3600);

	#
	# move the day around if passed
	#
	if ($dayMod ne '') { $epochTime += ($dayMod * 86400) }

        #
        # get the localtime
        #
        my ($sec,$min,$hr,$mday,$mon,$annum,$wday,$yday,$isdst) = localtime($epochTime);

        #
        # we want months to go from 1-12 with the mod adjustment
        #
        $mon += $monthMod + 1;

        #
        # and we want to use four-digit years
        #
        my $year = 1900 + $annum;

        #
        # min and second is always leading zero
        #
        $min = ("0" x (2 - length($min))).$min;
        $sec = ("0" x (2 - length($sec))).$sec;

        #
        # lets grab minute before we PM/AM it
        #
        my $minute = $min;

	#
        #grab the hour before we am/pm it
        #
        my $hour = $hr;

        #
        # turn military time time to AM/PM time
        # hr is the AM PM version hour is military
        #
        if ($hr > 12) {
                $hr = $hr-12;
                $min .= "PM";
        }
        else {
                if ($hr == 12)          { $min .= "PM" }
                else                    { $min .= "AM" }
        }


        #
        # if the $month is less than 1 then shift them off to the year slots
        # if the monthmod is more than 12 shift them off to the year slots positivly
        #
        while ($mon < 1) {
                $mon += 12;
                $year--;
        }
        while ($mon > 12 ) {
                $mon -= 12;
                $year++;
        }

        #
        # adjust the number of months by the mod
        #
        my $month = ("0" x (2 - length($mon))) . $mon;

        #
        # leading zero our minute
        #
        $hour = ("0" x (2 - length($hour))).$hour;
        my $monthDay = ("0" x (2 - length($mday))) . $mday;

        #
        # this is what we will return
        #
        my $showDateTime = '';

        if ($format =~ /^number$/i) {
                $showDateTime = $year.$month.$monthDay.$hour.$minute.$sec;
        }

        if ($format =~ /^shortDate$/i) {
                my @monthName = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
                $showDateTime = $monthName[$mon-1].' '.$monthDay.' '.$year;
        }

	if ($format =~ /^cookie$/i) {
                my @dayName = qw(Sun Mon Tue Wed Thu Fri Sat);
                my @monthName = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
                $showDateTime = $dayName[$wday].','.' '.$monthDay.$dateSeparator.$monthName[$mon-1].$dateSeparator.$year.' '.$hour.':'.$minute.':'.$sec.' GMT';
        }


	if ($format =~ /^ISO8601$/i) {
		$showDateTime = sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", sub { ($_[5]+1900, $_[4]+1, $_[3], $_[2], $_[1], $_[0]) }->(gmtime($epochTime)));
	}


        if ($format =~ /^fancyDate$/i) {
                my @dayName 	= qw(Sunday Monday Tueday Wednesday Thursday Friday Saturday);
                my @monthName 	= qw(January Febuary March April May June July August September October November December);

		#
		# date names in french
		#
                if ($self->language() =~ /fr/i) { @dayName 	= qw(Dimanche Lundi Mardi Vendredi Jeudi Vendredi Samedi)}
                if ($self->language() =~ /fr/i) { @monthName 	= qw(janvier fevrier mars avril mai juin juillet a^out septembre octobre novembre decembre)}

              	# 
              	# English th/nd/st rules 
              	# 
		my $numberCap = 'th';
                $monthDay =~ s/^0//sg;
                if ($monthDay =~ /2$/ && $monthDay ne '12') { $numberCap = "nd" }
                if ($monthDay =~ /3$/ && $monthDay ne '13') { $numberCap = "rd" }
                if ($monthDay =~ /1$/i && $monthDay ne '11') { $numberCap = "st" }

		#
		# English date format
		# 
                $showDateTime = $dayName[$wday].','.' '.$monthName[$mon-1].' '.$monthDay.$numberCap.','.' '.$year;

		#
		# French date format
		#
		if ($self->language() =~ /fr/i) { $showDateTime = $dayName[$wday].' le '.$monthDay.' '.$monthName[$mon-1].' '.$year }
        }

        if ($format =~ /^apache$/i) {
                my @monthName = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
                my @dayName = qw(Sun Mon Tue Wed Thu Fri Sat);
                my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($epochTime);
                $year=$year+1900;
                $showDateTime = $dayName[$wday].','.' '.$mday.' '.$monthName[$mon].' '.$year.' '.$hour.':'.$minute.':'.$sec.' GMT';
        }

        if ($format =~ /^odbc$/i|| $format =~ /SQL/i) {
                $showDateTime = $year.$dateSeparator.$month.$dateSeparator.$monthDay." ".$hour.":".$minute.":".$sec;
        }

        if ($format =~ /^date$/i) {
		#
		# english date
		#
                $showDateTime = $month.$dateSeparator.$monthDay.$dateSeparator.$year;

		#
		# french date
		#
              	if ($self->language() =~ /fr/i) { $showDateTime = $monthDay.$dateSeparator.$month.$dateSeparator.$year }
        }
        
	if ($format =~ /^month$/i) 	{ $showDateTime = $month }
	if ($format =~ /^year$/i) 	{ $showDateTime = $year }
	if ($format =~ /^day$/i) 	{ $showDateTime = $monthDay }

        if ($format =~ /^time$/i) {
                $showDateTime = $hr.":".$min." EST";
        }

        if ($format =~ /^dateTime$/i) {
                $showDateTime = $month.$dateSeparator.$monthDay.$dateSeparator.$year." ".$hr.":".$min." EST";
        }

        if ($format =~ /^dateTimeFull$/i) {
                $showDateTime = $month.$dateSeparator.$monthDay.$dateSeparator.$year." ".$hour.":".$minute.":".$sec." EST";
        }

        if ($format =~ /^yearFirstDate$/i) {
                $showDateTime = $year.$dateSeparator.$month.$dateSeparator.$monthDay;
        }

        if ($format =~ /^firstOfMonth$/i) {
                $showDateTime = $month.$dateSeparator."01".$dateSeparator.$year;
        }

        if ($format =~ /^epoch$/i) {
                $showDateTime = $epochTime;
        }

        return $showDateTime;
}

=head2 field

Return a field based on dynamic language and falling back to the default if the language specific value isn't available.

        print $fws->field('title',%dataHash);

=cut

sub field {
        my ($self, $fieldName,%dataHash) = @_;

	#
	# default field name
	#
	my $returnField = $dataHash{$fieldName};

	#
	# the datafields have a couple of issues with core field names that do not match its language field
	# here are the conversions
	#
	$fieldName =~ s/navigationName/nav_name/sg;

	#
	# check to see if a language specific one exists
	#
	if ($dataHash{$fieldName.'_'.$self->language()} ne '') { $returnField = $dataHash{$fieldName.'_'.$self->language()} }

	#
	# return either the default, or the language specific one
	#
	return $returnField;	
}

=head2 formatCurrency

Return a number in USD Format.

        print $fws->formatCurrency(33.55);

=cut

sub formatCurrency {
        my ($self, $amount) = @_;
        my $negative = '';
        if ($amount =~ /^-/) { $negative = '-' }
        $amount =~ s/[^\d.]+//g;
        $amount = $amount + 0;
        if ($amount == 0) { $amount = "0.00" }
        else { $amount = sprintf ("%.2f", $amount) }
        $amount =~ s/\G(\d{1,3})(?=(?:\d\d\d)+(?:\.|$))/$1,/g;
        return "\$".$negative.$amount;
        }


=head2 formatPhone

Return a phone number in a specific format.

        print $fws->formatPhone(format=>'full',phone=>'555-367-5309');


Valid formats: 

number: 1234567890

full: (123) 456-7890

dots: 123.456.7890

=cut

sub formatPhone {
        my ($self,%paramHash) = @_;
        my $returnPhone = $paramHash{'phone'};
        $paramHash{'phone'}     =~ s/[\D]//sg;
        $paramHash{'phone'}     = substr($paramHash{'phone'},-10);
        if (length($paramHash{'phone'}) != 10) { $returnPhone = '' } else {
                if ($paramHash{'format'} eq 'number') {
                        $returnPhone            = $paramHash{'phone'};
                }
                if ($paramHash{'format'} eq 'full') {
                        $returnPhone = '('.substr($paramHash{'phone'},0,3).') '.substr($paramHash{'phone'},3,3).'-'.substr($paramHash{'phone'},6,4);
                }
                if ($paramHash{'format'} eq 'dots') {
                        $returnPhone = substr($paramHash{'phone'},0,3).'.'.substr($paramHash{'phone'},3,3).'.'.substr($paramHash{'phone'},6,4);
                }
        }
        return $returnPhone;
}

=head2 FWSIcon

Return just the file name when given a full file path

       $valueHash{'html'} .= $fws->FWSIcon(icon=>'blank_16.png');

You can pass the following keys:

	icon
	class
	id
	width
	alt
	onClick

=cut

sub FWSIcon {
        my ($self,%paramHash) = @_;
        if ($paramHash{'icon'} eq '') {         $paramHash{'icon'} = 'blank.png' }
        if ($paramHash{'class'} ne '') {        $paramHash{'class'} = ' class="'.$paramHash{"class"}.'"' }
        if ($paramHash{'id'} ne '') {           $paramHash{'id'} = ' id="'.$paramHash{'id'}.'"' }
        if ($paramHash{'width'} eq '') {        $paramHash{'style'} .= "width:".$paramHash{'width'}."px" }
        if ($paramHash{'alt'} eq '') {          $paramHash{'alt'} = '\'\'' }
        if ($paramHash{'onClick'} ne '') {
                $paramHash{'onClick'}   = " onclick=\"".$paramHash{'onClick'}."\"";
                $paramHash{'style'}     = 'cursor:pointer;'.$paramHash{'style'};
        }
        return "<img src=\"".$self->{'fileFWSPath'}."/icons/".$paramHash{'icon'}."\" alt=\"".$paramHash{'alt'}."\"".$paramHash{'id'}.$paramHash{'class'}.$paramHash{'onClick'}." style=\"border:none;".$paramHash{'style'}."\"/>";
}

=head2 justFileName

Return just the file name when given a full file path

        my $fileName = $fws->justFileName('/this/is/not/going/to/be/here/justTheFileName.jpg');

=cut

sub justFileName {
        my ($self, $justFileName) = @_;

        #
        # change the \ to /'s
        #
        $justFileName =~ s/\\/\//g;

	#
	# split it up and pop off the last one
	#
        my @fileNameArray = split(/\//,$justFileName);
        $justFileName = pop(@fileNameArray);

        return $justFileName
        }

=head2 jqueryEnable

Add FWS core distribution jQuery modules and corresponding CSS files to the CSS and JS cached files.  These are located in the /fws/jquery directory.  The naming convention for jQuery files are normalized and only the module name and version is required.

	#
	# if the module you were loadings file name is:
	# jquery-WHATEVERTHEMODULEIS-1.1.1.min.js
	# it would be loaded via jqueryEnable as follows:
        #
        $fws->jqueryEnable('WHATEVERTHEMODULEIS-1.1.1');

This method ensures jQuery files are only loaded once, and the act of any jQuery module being enabled will auto-activate the core jQuery library.  They will be loaded in the order they were called  from any element in the rendering process.

=cut

sub jqueryEnable {
        my ( $self, $jqueryEnable ) = @_;

        #
        # get the current hash
        #
        my %jqueryHash = %{$self->{'_jqueryHash'}};

        #
        # if its already there lets just leave it alone
        #
        if ($jqueryHash{$jqueryEnable} eq '') { $jqueryHash{$jqueryEnable} = keys %jqueryHash }

        #
        # pass the new hash back into the jqueryHash
        #
        %{$self->{'_jqueryHash'}} = %jqueryHash;
}

=head2 popupWindow

Create a link to a popup window or just the onclick.  Passing queryString is requried and pass linkHTML if you would like it to be a link.  

	$valueHash{'html'} .= $fws->popupWindow(queryString=>'p=somePage',$linkHTML=>'Click Here to go to some page');

NOTE: This should only be used in the context of the FWS Administration, and is only here as a reference for modifiers of the admin. 

=cut

sub popupWindow {
        my ($self,%paramHash) =@_;
        my $returnHTML = "window.open('".$self->{'scriptName'}.$self->{'queryHead'}.$paramHash{'queryString'}."','_blank');";
        if ($paramHash{'linkHTML'} ne "") { return "<span class=\"FWSAjaxLink\" onclick=\"".$returnHTML."\">".$paramHash{'linkHTML'}."</span>" }
        else { return $returnHTML }
}

=head2 removeHTML

Return a string minus anything that is in < >.

        $safeForText = $fws->removeHTML('<a href="somelink.html">This is the text that will return without the anchor</a>');

=cut

sub removeHTML {
        my ($self,$theString) = @_;
        $theString =~ s/<!.*?-->//gs;
        $theString =~ s/<.*?>//gs;
        return $theString;
}

=head2 startElement

Return a the complement to endElement having the default title control and class labeling.

	$valueHash{'html'} .= $fws->startElement(%dataHash);
	$valueHash{'html'} .= $fws->endElement(%dataHash);

If there is no dataHash to pass, you can set its the keys elementClass, title, and disableTitle to control its appearence.

=cut

sub startElement {
        my ($self,%dataHash) = @_;

        my $elementClass = $self->formValue('FWS_elementClassPrefix');
        if ($dataHash{'elementClass'} ne '') { $elementClass = $dataHash{'elementClass'} }

        #
        # start two divs for positioning and backgrounds
        #
        my $html = "<div class=\"globalElementWrapper ".$elementClass."Wrapper\"><div class=\"globalElement ".$elementClass."\">";

        #
        # Title Field/Table
        #
        if ($dataHash{"disableTitle"} ne "1") {
                $html .= "<div class=\"globalTitleWrapper ".$elementClass."TitleWrapper\"><h2 class=\"globalTitle ".$elementClass."Title\">";
                $html .= $self->field('title',%dataHash);
                $html .= "</h2></div>";
                }

        $html .= "<div class=\"globalContentWrapper ".$elementClass."ContentWrapper\">";

        #
        # wrap the element
        #
        return $html;
        }

=head2 stateDropDown

Return a dropdown for all US States, passining it (current, class, id, style, topOption)  TopOption if passed will be the text that is displayed for the option, but the value will be blank.

=cut

sub stateDropDown {
        my ($self, %paramHash) = @_;

	#
	# create a array we will process of states
	#
	my @stateArray = ('AL','Alabama','AK','Alaska','AZ','Arizona','AR','Arkansas','CA','California','CO','Colorado','CT','Connecticut','DE','Delaware','DC','District of Columbia','FL','Florida','GA','Georgia','HI','Hawaii','ID','Idaho','IL','Illinois','IN','Indiana','IA','Iowa','KS','Kansas','KY','Kentucky','LA','Louisiana','ME','Maine','MD','Maryland','MA','Massachusetts','MI','Michigan','MN','Minnesota','MS','Mississippi','MO','Missouri','MT','Montana','NE','Nebraska','NV','Nevada','NH','New Hampshire','NJ','New Jersey','NM','New Mexico','NY','New York','NC','North Carolina','ND','North Dakota','OH','Ohio','OK','Oklahoma','OR','Oregon','PA','Pennsylvania','RI','Rhode Island','SC','South Carolina','SD','South Dakota','TN','Tennessee','TX','Texas','UT','Utah','VT','Vermont','VA','Virginia','WA','Washington','WV','West Virginia','WI','Wisconsin','WY','Wyoming');

	#
	# preformat anything that will be in the html that is passed
	#
	if ($paramHash{'class'} ne '') 		{ $paramHash{'class'} 		= 'class="'.$paramHash{'class'}.'" ' }
	if ($paramHash{'style'} ne '') 		{ $paramHash{'style'} 		= 'style="'.$paramHash{'style'}.'" ' }
	if ($paramHash{'id'} ne '') 		{ $paramHash{'id'} 		= 'id="'.$paramHash{'id'}.'" ' }
	if ($paramHash{'topOption'} ne '') 	{ $paramHash{'topOption'} 	= '<option value="">'.$paramHash{'topOption'}.'</option>' }

	#
	# start off the select with the top opction if present
	#
	my $returnHTML = '<select '.$paramHash{'id'}.$paramHash{'class'}.$paramHash{'style'}.'>';
	$returnHTML .= $paramHash{'topOption'};

	#
	# loop though the array creating each one, with the selected if the current matches
	#
	while (@stateArray) {
		my $stateAbbr = shift(@stateArray);
		my $stateName = shift(@stateArray);
		$returnHTML .= '<option ';
		if ($paramHash{'current'} =~ /$stateAbbr/i) { $returnHTML .= 'selected="selected" ' }
		$returnHTML .= 'value="'.$stateAbbr.'">'.$stateName.'</option>';
	}

	#
	#  Close the select, and return our HTML for the select
	#
	$returnHTML .= '</select>';
	return $returnHTML;
}


=head2 SQLDate

Return a date string in SQL format if it was passed ass SQL format already, or convert it if it was sent as mm-dd-yyyy.

        my $SQLDate = $fws->SQLDate('2012-02-03');

=cut

sub SQLDate {
        my ($self,$date) = @_;
        my @dateSplit = split(/\D/,$date);
        if (length($dateSplit[2]) == 4) { $date = $dateSplit[2].'-'.$dateSplit[0].'-'.$dateSplit[1]}
        else {$date =$dateSplit[0].'-'.$dateSplit[1].'-'.$dateSplit[2]}
        return $self->safeSQL($date);
}

=head2 truncateContent

Return content based on nearest ended word to the length parameter.

        print $fws->truncateContent(content=>'this is some long content I want just a preview of.', length=>10, postText=>'...');

=cut



sub truncateContent {
        my ($self,%paramHash) = @_;

	my $theString = $paramHash{'content'};
	my $maxLength = $paramHash{'length'};

        #
        # add a space to make the logic easier, we will eat this after the fact if its still sitting around
        #
        $theString .= ' ';
        my @charArray = split(//,$theString);
        my $count = 0;
        my $newString = '';
        my $currentWord = '';

        #
        # loop though the array, adding to the newstring if there is a friendly space
        #
        while (@charArray) {
                $count++;
                my $currentChar = shift(@charArray);
                if ($count < $maxLength) {
                        $currentWord .= $currentChar;
                        if ($currentChar eq ' ') {
                                $newString .= $currentWord;
                                $currentWord = '';
                        }
                }
        }

        #
        # if there is no friendly spaces, just chop at the maxLength
        #
        if ($newString eq '') { $newString = substr($theString, 0, $maxLength) }

        #
        # eat the post space if there is any.
        #
        $newString =~ s/\s+$//sg;

	#
	# add posttext if there is a chop
	#
	if ($paramHash{'content'} ne $newString) { $newString .= $paramHash{'postText'} }

	#
	# return our newly created pontentialy shorter string
	#
        return $newString;
}

=head1 FWS ADMIN METHODS

These methods are used only by FWS Admin maintainers.   They should not be used out of the context of the FWS Admin as they could change without warning.

=head2 adminField

Return an edit field or field block for the FWS Admin.   The adminField method is a very configurable tool used by the FWS administration maintainers.  

        #
        # Create a admin edit field
        #
        $valueHash{'html'} .= $fws->adminField( %paramHash );

NOTE: This should only be used in the context of the FWS Administration, and is only here as a reference for modifiers of the admin.

Passable Keys:

fieldType

fieldName

fieldValue

fieldOptions

unilingual: [1|0]

ajaxUpdateGUID

ajaxUpdateParentId

id

class

style

onSaveComplete

updateType

guid

onKeyDown

note

afterFieldHTML

=cut

sub adminField {
        my ($self,%paramHash) = @_;

	#
	# for language replication fields, hold the array here so we can use it clean
	#
	my %origHash = %paramHash;

        #
        # set the id if not already set or if we going to use ajax, lets make a 
	# new id so we don't get dups from bad programming
        #
        if ($paramHash{"id"} eq '' || $paramHash{"updateType"} ne "") { $paramHash{"id"} = $paramHash{"fieldName"} }
        
	#
        # make the guid for ajax unique if needed
        #
        if ($paramHash{"guid"} eq '') { $paramHash{"guid"} = $paramHash{"fieldName"} }

	#
	# Set the uniqueId to something other than guyid if its passed, for save icon references
	#
	if ($paramHash{'uniqueId'} eq '') { $paramHash{'uniqueId'} = $paramHash{'fieldName'} }

	#
	# if these are blank, add them to the unique to make it more unique
	#
        if ($paramHash{"ajaxUpdateGUID"} ne '') 	{ $paramHash{"uniqueId"} .= "_".$paramHash{"ajaxUpdateGUID"}}
        if ($paramHash{"ajaxUpdateParentId"} ne '') 	{ $paramHash{"uniqueId"} .= "_".$paramHash{"ajaxUpdateParentId"}}

        #
        # if we are talking about a date, we are recieving it in SQL format, lets flip it real quicik
        # before we display it
        #
        if ($paramHash{"fieldType"} eq 'dateTime' && $paramHash{"fieldValue"} ne '') {

                #
                # convert from SQL format and spin it around for normal US date formats
                #
                if ($paramHash{"dateFormat"} =~ /(sql|)/i) {
                        my ($year,$month,$day,$hour,$minute,$second) = split(/\D/,$paramHash{"fieldValue"});
                        $paramHash{"fieldValue"} = $month."-".$day."-".$year." ".$hour.":".$minute.":".$second;
                }
        }

        #
        # if we are talking about a date, we are recieving it in SQL format, lets flip it real quicik
        # before we display it
        #
        if ($paramHash{"fieldType"} eq 'date' && $paramHash{"fieldValue"} ne '') {

                #
                # convert from SQL format and spin it around for normal US date formats
                #
                if ($paramHash{"dateFormat"} =~ /sql/i || $paramHash{"dateFormat"} eq '') {
                        my ($year,$month,$day)   = split(/\D/,$paramHash{"fieldValue"});
                        $paramHash{"fieldValue"} = $month."-".$day."-".$year;
                }

                #
                # convert from number format to normal dates so the picker will love it
                #
                if ($paramHash{"dateFormat"} =~ /number/i) {
                        my $year       = substr($paramHash{"fieldValue"},0,4);
                        my $month      = substr($paramHash{"fieldValue"},4,2);
                        my $day        = substr($paramHash{"fieldValue"},6,2);
                        $paramHash{"fieldValue"} = $month."-".$day."-".$year;
                }

        }

        #
        # this is the js needed to copy the date field to the SQL compatable hidden field
        #

        my $copyToHidden .= "\$('#".$paramHash{'uniqueId'}."_ajax').val(\$('#".$paramHash{'uniqueId'}."').val());";

        if ($paramHash{"fieldType"} eq 'date') {
                $copyToHidden = "if (document.getElementById('".$paramHash{'uniqueId'}."\').value != '') {var dateSplit=document.getElementById('".$paramHash{'uniqueId'}."\').value.split(/\\D/);while(dateSplit[1].length &lt; 2) { dateSplit[1] = '0'+dateSplit[1];}while(dateSplit[0].length &lt; 2) { dateSplit[0] = '0'+dateSplit[0];}document.getElementById('".$paramHash{'uniqueId'}."_ajax').value=dateSplit[2]+'-'+dateSplit[0]+'-'+dateSplit[1];}else {document.getElementById('".$paramHash{'uniqueId'}."_ajax').value='';}";
        }

        if ($paramHash{"fieldType"} eq 'dateTime') {
                $copyToHidden = "if (document.getElementById('".$paramHash{'uniqueId'}."\').value != '') {var dateSplit=document.getElementById('".$paramHash{'uniqueId'}."\').value.split(/\\D/);while(dateSplit[1].length &lt; 2) { dateSplit[1] = '0'+dateSplit[1];}while(dateSplit[0].length &lt; 2) { dateSplit[0] = '0'+dateSplit[0];}document.getElementById('".$paramHash{'uniqueId'}."_ajax').value=dateSplit[2]+'-'+dateSplit[0]+'-'+dateSplit[1]+' '+dateSplit[3]+':'+dateSplit[4]+':'+dateSplit[5];}else {document.getElementById('".$paramHash{'uniqueId'}."_ajax').value='';}";
        }

        #
        # set the style if we have to something to give
        #
        my $styleHTML;
        if ($paramHash{"style"} ne '') { $styleHTML = " style=\"".$paramHash{"style"}."\"" }

	#
	# Seed the save JS, we will build on this depending on what we have to work with
	#
        my $AJAXSave;

        #
        # radio boxes have there own transfer method
        #
        if ($paramHash{"fieldType"} ne "radio" && $paramHash{"fieldType"} ne 'date') {
                $AJAXSave .= $copyToHidden;
        }

	#
	# seed the onSaveJS, we will seed this also and depdningon what we are doing, we might
	# need to do different onSaveJS functions
	#
        my $onSaveJS;

        #
        # if your a text area, update the text
        #
        if ($paramHash{"updateType"} ne "" && $paramHash{"fieldType"} eq "textArea") {
                $onSaveJS .= "\$('#".$paramHash{'uniqueId'}."_status').css('visibility', 'hidden');"
        }

        #
        # if your a password, update the text
        #
        if ($paramHash{"updateType"} ne "" && $paramHash{"fieldType"} eq "password") {
                $onSaveJS .= "\$('#".$paramHash{'uniqueId'}."_passwordStrong').hide();"
        }

        #
        # everyone gets the spinny
        #
        my $imageID;
        if ($paramHash{"updateType"} ne "") {
                $imageID = "'#".$paramHash{'uniqueId'}."_img'";
                $onSaveJS .= "\$(".$imageID.").attr('src','".$self->{'fileFWSPath'}."/saved.gif');";
                $AJAXSave .= "\$(".$imageID.").attr('src','".$self->loadingImage()."');";
        }

        #
        # after the save is complete run this javascript
        #
        if ($paramHash{"onSaveComplete"} ne "") {
                $onSaveJS .= $paramHash{"onSaveComplete"};
        }

	#
	#  tack in the onSave it was populated
	#
        if ($onSaveJS ne '') { $onSaveJS = ",onSuccess: function() {".$onSaveJS."}" }

        #
        # the save everyone uses
        #
        if ($paramHash{"updateType"} ne "") {
                if ($paramHash{"updateType"} eq "AJAXUpdate" || $paramHash{"updateType"} eq "AJAXExt") {
                        $AJAXSave .= "\$('<div></div>').FWSAjax({queryString:'s=".$self->{'siteId'}."&guid=".$paramHash{'ajaxUpdateGUID'}."&parent=".$paramHash{'ajaxUpdateParentId'}."&table=".$paramHash{'ajaxUpdateTable'}."&field=".$paramHash{'fieldName'}."&value='+encodeURIComponent(\$('#".$paramHash{'uniqueId'}."_ajax').val())+'&pageAction=".$paramHash{'updateType'}."&returnStatusNote=1'".$onSaveJS.",showLoading:false});";
                }
                else {
                    $AJAXSave .= "\$('<div></div>').FWSAjax({queryString:'s=".$self->{'siteId'}."&guid=".$paramHash{'ajaxUpdateGUID'}."&parent=".$paramHash{'ajaxUpdateParentId'}."&field=".$paramHash{'fieldName'}."&value='+encodeURIComponent(\$('#".$paramHash{'uniqueId'}."_ajax').val())+'&pageAction=".$paramHash{'updateType'}."&p=".$paramHash{'updateType'}."'".$onSaveJS.",showLoading:false});";
                }
        }



        #
        # if this is a date fields, lets wrap this in the conditional not to save unless its groovy
        #
        if ($paramHash{'fieldType'} eq 'date' || $paramHash{'fieldType'} eq 'dateTime' ) {
                my $reformatJS;
                $reformatJS .= "if (\$('".$paramHash{'uniqueId'}."_ajax').val()"." != '') {";
                if ($paramHash{'dateFormat'} =~ /number/i) {
                        $reformatJS .= "var cleanDate;cleanDate = document.getElementById('".$paramHash{'uniqueId'}."_ajax').value.replace(/\\D/g,'');";
                        $reformatJS .= "\$('#".$paramHash{'uniqueId'}."_ajax').val(cleanDate);";
                }
                $reformatJS .= '}';

                $AJAXSave = $copyToHidden.
                        "var dateSplit=document.getElementById('".$paramHash{'uniqueId'}.'_ajax\').value.split(/\\D/);if (document.getElementById(\''.$paramHash{'uniqueId'}.'_ajax\').value == \'\' || (dateSplit[0].length==4 &amp;&amp; dateSplit[1] &gt; 0 &amp;&amp; dateSplit[1] &lt; 13 &amp;&amp;  dateSplit[2] &gt; 0 &amp;&amp; dateSplit[2] &lt; 32 )) { '.
                        $reformatJS.$AJAXSave .'}';
        }

        #
        # change all carrage returns to safe ones that are compatable with ajax calls
        # only beat up the value field if we are talking about a value that will be injected into an element.  otherwise leave it alone
        # because we might be passing some sweet stuff to it that will have raw html
        #
        if ($paramHash{'fieldType'} ne '') {
                $paramHash{'fieldValue'} =~ s/\n/&#10;/sg;
                $paramHash{'fieldValue'} =~ s/\r//sg;
                $paramHash{'fieldValue'} =~ s/"/&quot;/sg;
        }

	#
	# lets starting building the actual fieldHTML we will return
	# EVERYONE gets the hidden ajax guid
	#
        my $fieldHTML = "<input type=\"hidden\" name=\"".$paramHash{'uniqueId'}."_ajax\" id=\"".$paramHash{'uniqueId'}."_ajax\"/>";

	#
	# textArea starter with hidden save message only if we are going to update it
	#
        if ($paramHash{"updateType"} ne "" && $paramHash{"fieldType"} eq "textArea") {
                $fieldHTML .= "<div id=\"".$paramHash{"uniqueId"}."_status\" style=\"color:#FF0000;visibility:hidden;\">";
                $fieldHTML .= "<img alt=\"save\" src=\"".$self->{'fileFWSPath'}."/saved.gif\" style=\"border:0pt none;\" id=\"".$paramHash{"uniqueId"}."_img\" onclick=\"".$AJAXSave."\"/>";
                $fieldHTML .= "&nbsp;Your content has not been saved";
                $fieldHTML .= "</div>";
        }

        #
        # text/password
        #
        if ($paramHash{'fieldType'} =~ /^(text|password)$/) {
                $fieldHTML .= "<input type=\"".$paramHash{"fieldType"}."\" name=\"".$paramHash{"fieldName"}."\"  size=\"60\"".$styleHTML."  class=\"FWSFieldText ".$paramHash{"class"}."\" value=\"".$paramHash{"fieldValue"}."\"";
        }

        #
        # currency,date and number
        #
        if ( $paramHash{'fieldType'} eq 'date') {
                $self->jqueryEnable('ui-1.8.9');
                $self->jqueryEnable('ui.datepicker-1.8.9');
                $paramHash{"class"} .= ' FWSDatePicker';
        }

        #
        # color picker
        #
        if ( $paramHash{'fieldType'} eq 'color') {
                $paramHash{"class"} .= " FWSColorPicker";
        }

        #
        # datetime
        #
        if ( $paramHash{'fieldType'} eq 'dateTime') {
                $self->jqueryEnable('ui-1.8.9');
                $self->jqueryEnable('ui.widget-1.8.9');
                $self->jqueryEnable('ui.mouse-1.8.9');
                $self->jqueryEnable('ui.datepicker-1.8.9');
                $self->jqueryEnable('ui.slider-1.8.9');
                $self->jqueryEnable('timepickr-0.9.6') ;
                $paramHash{"class"} .= " FWSDateTime";
        }


        if ($paramHash{'fieldType'} =~ /^(currency|number|date|color|dateTime)$/) {

                if ($paramHash{'fieldType'} eq 'color') { $styleHTML = " style=\"background-color: #".$paramHash{"fieldValue"}."\""; }

                if ($paramHash{"fieldType"} eq 'dateTime') {
                   $fieldHTML .= "<input type=\"text\" name=\"".$paramHash{"fieldName"}."\"  size=\"20\"".$styleHTML." class=\"".$paramHash{"class"}."\" value=\"".$paramHash{"fieldValue"}."\"";
                }
                else {
                   $fieldHTML .= "<input type=\"text\" name=\"".$paramHash{"fieldName"}."\"  size=\"10\"".$styleHTML."  class=\"".$paramHash{"class"}."\" value=\"".$paramHash{"fieldValue"}."\"";
                }

                #
                # only allow numbers and such
                #
                $paramHash{"onKeyDown"} .= "var keynum; if(window.event) { keynum = event.keyCode } else if(event.which) {";
                $paramHash{"onKeyDown"} .= "keynum = event.which };";
                $paramHash{"onKeyDown"} .= "if ((";
                $paramHash{"onKeyDown"} .= "keynum&lt;48 || keynum&gt;105 || (keynum&gt;57 &amp;&amp; keynum&lt;95)";
                $paramHash{"onKeyDown"} .= ")";
                
		#
                # if I'm a color let people pick a-f
                #
                if ( $paramHash{"fieldType"} eq 'color' ) {
                        $paramHash{"onKeyDown"} .= " &amp;&amp; keynum != 65 &amp;&amp; keynum != 66 &amp;&amp; keynum != 67 &amp;&amp; keynum != 68 &amp;&amp; keynum != 69 &amp;&amp; keynum != 70 ";
                }
                else {
                        #
                        # keypad and number: -
                        #
                        $paramHash{"onKeyDown"} .= " &amp;&amp; keynum != 45 &amp;&amp; keynum != 109 ";

                        #
                        # keypad: .
                        #
                        $paramHash{"onKeyDown"} .= " &amp;&amp; keynum != 45 &amp;&amp; keynum != 110 ";
                }

                $paramHash{"onKeyDown"} .= " &amp;&amp; keynum!=46  &amp;&amp; keynum!=189 &amp;&amp; keynum!=37 &amp;&amp; keynum!= 39 &amp;&amp; keynum!= 35 &amp;&amp; keynum!= 36 &amp;&amp; keynum!=8 &amp;&amp; keynum!=9 &amp;&amp; keynum!=190) { return false }";

        }

        #
        # dropDown
        #
        if ($paramHash{"fieldType"} eq "dropDown") {
                $fieldHTML .= "<select name=\"".$paramHash{"fieldName"}."\"".$styleHTML." class=\"".$paramHash{"class"}."\"";
        }

        if ($paramHash{"fieldType"} eq "birthday") {

		#	
		# onchange bday js
		#
		my $bdayOnchange .= "if (!isNaN(\$('#".$paramHash{'uniqueId'}."_year').val()) && !isNaN(\$('#".$paramHash{'uniqueId'}."_day').val()) && !isNaN(\$('#".$paramHash{'uniqueId'}."_month').val())) {  \$('#".$paramHash{'uniqueId'}."_ajax').val(\$('#".$paramHash{'uniqueId'}."_year').val()+'-'+\$('#".$paramHash{'uniqueId'}."_month').val()+'-'+\$('#".$paramHash{'uniqueId'}."_day').val());}";
		#
		# month
		#
		$fieldHTML .= '<select class="FWSInputField" id="'.$paramHash{'uniqueId'}.'_month" name="'.$paramHash{'uniqueId'}.'_month" onchange="'.$bdayOnchange.'">';
		$fieldHTML .= '<option>- Month -</option>';
		$fieldHTML .= '<option value="01">January</option>';
		$fieldHTML .= '<option value="02">February</option>';
		$fieldHTML .= '<option value="03">March</option>';
		$fieldHTML .= '<option value="04">April</option>';
		$fieldHTML .= '<option value="05">May</option>';
		$fieldHTML .= '<option value="06">June</option>';
		$fieldHTML .= '<option value="07">July</option>';
		$fieldHTML .= '<option value="08">August</option>';
		$fieldHTML .= '<option value="09">September</option>';
		$fieldHTML .= '<option value="10">October</option>';
		$fieldHTML .= '<option value="11">November</option>';
		$fieldHTML .= '<option value="12">December</option>';
		$fieldHTML .= '</select>';
		
		#
		# Day
		#
		$fieldHTML .= '<select class="FWSInputField" id="'.$paramHash{'uniqueId'}.'_day" name="'.$paramHash{'uniqueId'}.'_day" onchange="'.$bdayOnchange.'">';
		$fieldHTML .= '<option>- Day -</option>';
		for (my $count = 1; $count <= 31; $count++) { my $lead = '0'; if ($count > 9) {$lead = ''}$fieldHTML .= '<option value="'.$lead.$count.'">'.$count.'</option>' }
		$fieldHTML .= '</select>';
		
		#
		# year
		#
		$fieldHTML .= '<select class="FWSInputField" id="'.$paramHash{'uniqueId'}.'_year" name="'.$paramHash{'uniqueId'}.'_year" onchange="'.$bdayOnchange.'">';
		$fieldHTML .= '<option>- Year -</option>';
		my $year = $self->formatDate(format=>'year');
		for (my $count = $year-4; $count > $year-110; $count--) { $fieldHTML .= '<option value="'.$count.'">'.$count.'</option>' }
		$fieldHTML .= '</select>';
	}    

        #
        # textArea
        #
        if ($paramHash{"fieldType"} eq "textArea") {
                $fieldHTML .= "<textarea rows=\"8\" cols=\"70\" name=\"".$paramHash{"fieldName"}."\"".$styleHTML." class=\"".$paramHash{"class"}."\"";
        }


        #
        # all but checkboxes and radio buttons
        #
        if ($paramHash{"fieldType"} =~ /^(dateTime|color|currency|number|text|password|textArea|dropDown|date)$/) {
                #
                # set the Id
                #
                $fieldHTML .= " id=\"".$paramHash{"uniqueId"}."\"";
                if ($paramHash{"readOnly"} eq "1") { $fieldHTML .= " disabled=\"disabled\"" }
        }



        #
        # if its a date, flip it around also update the ajax because it wont't do it on the save
        #
        if ($paramHash{"fieldType"} =~ /^(date|color|dateTime)$/) {
                $fieldHTML .= " onkeyup=\"".$copyToHidden."\"";
        }

        if ($paramHash{'updateType'} ne '' && $paramHash{'fieldType'} eq 'password')  {
                $fieldHTML .= ' onkeyup="';
		if ($paramHash{'strongPassword'} ne '0') {
                	$fieldHTML .= 'if (document.getElementById(\''.$paramHash{'uniqueId'}.'\').value.search(/(?=^.{7,}$)(?=.*\\d)(?=.*[A-Z])(?=.*[a-z]).*$/) != -1) {';
	                $fieldHTML .= "\$('#".$paramHash{'uniqueId'}."_passwordWeak').hide();";
		}
		$fieldHTML .= "\$('#".$paramHash{'uniqueId'}."_passwordStrong').show();";
		if ($paramHash{'strongPassword'} ne '0') {
                	$fieldHTML .= " } else {\$('#".$paramHash{'uniqueId'}."_passwordWeak').show();\$('#".$paramHash{'uniqueId'}."_passwordStrong').hide();}";
		}
                $fieldHTML .= '"';
        }

        #
        # run all these if on fields, even if ajax is not on
        #
        if (($paramHash{"fieldType"} =~ /^(dateTime|color|currency|number|text|password|textArea|date)$/))  {
                $fieldHTML .= " onfocus=\"".$copyToHidden;
                $fieldHTML .=  $paramHash{'onFocus'} ."\"";
        }

        if ($paramHash{'updateType'} ne '' && ($paramHash{'fieldType'} =~ /^(color|dateTime|currency|number|text|password|date|textArea)$/))  {

                #
                # key down & context right clicking ajax image update
                #

		#
		# choose a different icon
		#
		my $saveIcon = $self->{'fileFWSPath'}."/save.gif";
		if ($paramHash{'saveIcon'} ne '') { $saveIcon = $self->{'fileFWSPath'}.'/icons/'.$paramHash{'saveIcon'} }

                $fieldHTML .= " onkeydown=\"document.getElementById('".$paramHash{'uniqueId'}."_img').src='".$saveIcon."';";

                if ($paramHash{'updateType'} ne '' && $paramHash{'fieldType'} eq 'textArea')  {
                        $fieldHTML .= "\$('#".$paramHash{'uniqueId'}."_status').css('visibility', 'visible');";
                }
                $fieldHTML .= $paramHash{'onKeyDown'};
                $fieldHTML .= "\" ";
        }

        
	#
        # set the onchange/onblur for the diffrent types
        #

        #
        # text/password
        #
        if ($paramHash{"fieldType"} =~ /^(color|currency|dateTime|number|text|date)$/) {
                $fieldHTML .= " onblur=\"".$paramHash{'onChange'}.$AJAXSave."\"";
        }

        #
        # dropDown
        #
        if ($paramHash{'fieldType'} =~ /^(dropDown|date|color|dateTime)$/)  {
                $fieldHTML .= " onchange=\"".$paramHash{'onChange'}.$AJAXSave."\"";
        }

        #
        # if we are a radio button list, all other stuff is out the window, and this is the only thing that happens
        #
        if ($paramHash{'fieldType'} eq 'radio') {
                #
                # clean these up in case peole did some formatting in the box
                #
                $paramHash{"fieldOptions"} =~ s/\n//sg;
                my @optionSplit = split(/\|/,$paramHash{'fieldOptions'});
                my $matchFound = 0;
                while (@optionSplit) {
                        my $optionValue = shift(@optionSplit);
                        my $optionName = shift(@optionSplit);
                        $fieldHTML .= "<input type=\"radio\" name=\"".$paramHash{"fieldName"}."\"".$styleHTML." class=\"".$paramHash{"class"}."\"";
                        $fieldHTML .= " onclick=\"".$paramHash{"onChange"};
                        $fieldHTML .= "\$('#".$paramHash{'uniqueId'}."_ajax').val('".$optionValue."');";
                        $fieldHTML .= $AJAXSave;
                        $fieldHTML .= '"';
                        if ($paramHash{"readOnly"} eq "1") { $fieldHTML .= " disabled=\"disabled\"" }
                        if ($optionValue eq $paramHash{"fieldValue"} || ($#optionSplit < 1 && !$matchFound)) {
                                $matchFound = 1;
                                $fieldHTML .= " checked=\"checked\"";
                        }
                        $fieldHTML .= "/> ";
                        $fieldHTML .= "<span class=\"FWSRadioButtonTitle\">".$optionName." &nbsp; </span>";
                }
        }
        #
        #
        # if we are a dropDown, put the options in and close the select
        #
        if ($paramHash{"fieldType"} eq "dropDown") {
                $fieldHTML .= ">";
                #
                # clean these up in case peole did some formatting in the box
                #
                $paramHash{"fieldOptions"} =~ s/\n//sg;
                my @optionSplit = split(/\|/,$paramHash{"fieldOptions"});
                while (@optionSplit) {
                        my $optionValue = shift (@optionSplit);
                        my $optionName = shift (@optionSplit);
                        $fieldHTML .= "<option value=\"".$optionValue."\"";
                        if ($optionValue eq $paramHash{"fieldValue"}) { $fieldHTML .= " selected=\"selected\"" }
                        $fieldHTML .= ">".$optionName."</option>";
                }
                $fieldHTML .= "</select>";
        }


        if ($paramHash{"fieldType"} eq "") {
                $fieldHTML .= "<div class=\"FWSNoFieldType\"".$styleHTML.">";
                $fieldHTML .= $paramHash{"fieldValue"};
                $fieldHTML .= "</div>";
        }


        #
        #
        # html
        #
        if ($paramHash{"fieldType"} eq "html") {
       		$self->{'tinyMCEEnable'} =1
	}

	#
	# textArea
        #
        if ($paramHash{"fieldType"} eq "textArea") {
                $fieldHTML .= ">";
                $fieldHTML .= $paramHash{"fieldValue"};
                $fieldHTML .= "</textarea>";
        }

        #
        # if we are not an dropDown or textarea, just close the input box
        #
        if ($paramHash{"fieldType"} =~ /^(color|currency|number|dateTime|text|password|date)$/)  {
                $fieldHTML .= "/>";
        }


	#
	# add autocomplete code
	#
	if ($paramHash{'autocompleteSource'} ne '') {
	        $fieldHTML .= '<script>$("#'.$paramHash{'uniqueId'}.'" ).autocomplete({';
	        $fieldHTML .= 'source: '.$paramHash{'autocompleteSource'}.',';
	        $fieldHTML .= 'search: function(event, ui) {$("#'.$paramHash{'uniqueId'}.'_img").attr("src","'.$self->loadingImage().'");'.$paramHash{'autocompleteSearch'} .'},';
	        $fieldHTML .= 'open: function(event, ui) {$("#'.$paramHash{'uniqueId'}.'_img").attr("src","'.$self->{'fileWebPath'}.'/fws/icons/blank_16.png");'.$paramHash{'autocompleteOpen'} .'},';
	        $fieldHTML .= 'select: function(event, ui) {'.$paramHash{'autocompleteSelect'} .'}';
		$fieldHTML .= '})';
	
		if ($paramHash{'autocompletePostHTML'} ne '') {
			$fieldHTML .= '.data("autocomplete")._renderItem = function(ul, item) { return $("<li></li>")';
	        	$fieldHTML .= '.data("item.autocomplete", item).append("<a>" + item.value + \' '.$paramHash{'autocompletePostHTML'}.'</a>\').appendTo(ul); }'; 
		}
		$fieldHTML .= ';</script>';
	}


        if ($paramHash{"updateType"} ne "" && $paramHash{"fieldType"} eq "password" ) {
		if ($paramHash{'strongPassword'} ne '0') {
	                $fieldHTML .= "<div id=\"".$paramHash{"uniqueId"}."_passwordWeak\" style=\"color:#FF0000;display:none;\">";
	                $fieldHTML .= "Passwords must be at least 6 characters and contain a number, an upper case character, a lower case character.";
	                $fieldHTML .= "</div>";
		}
                $fieldHTML .= "<div id=\"".$paramHash{"uniqueId"}."_passwordStrong\" style=\"color:#FF0000;display:none;\">";
                $fieldHTML .= "<img alt=\"save\" src=\"".$self->{'fileFWSPath'}."/saved.gif\" style=\"border:0pt none;\" id=\"".$paramHash{"uniqueId"}."_img\" onclick=\"".$AJAXSave."\"/>";
                $fieldHTML .= " Click the disk icon to commit your change";
                $fieldHTML .= "</div>";
        }

        #
        # stick the image in for saving if we are an updating field
        #
        if (($paramHash{"updateType"} ne "" && ($paramHash{"fieldType"} =~ /^(color|currency|dateTime|number|text|password|dropDown|date|radio)$/)) || $paramHash{'autocompleteSource'} ne '') {
                $fieldHTML .= "<img alt=\"save\" src=\"".$self->{'fileFWSPath'}."/saved.gif\" style=\"border:0pt none;\" id=\"".$paramHash{"uniqueId"}."_img\"";
                if ($paramHash{"noAutoSave"} eq "1") { $fieldHTML .= " onclick=\"".$AJAXSave."\"" }
                $fieldHTML .= "/>";
        }

	#
	# if we are a text area, lets place lang id if needed
	#
	if ($paramHash{"fieldType"} =~ /^text$/ || $paramHash{"fieldType"} =~ /^textArea$/ ) {
		my $langId = $paramHash{"fieldName"};
		if ($langId =~ /_(\w\w)$/ && $langId !~ /_id/i) { $fieldHTML .= "[".$1."]" }
	}

        #
        # if there is a title, wrap it with the GNF Field table!
        #
        if ($paramHash{"title"} ne "") {

                my $FWSFieldTitle;
                my $FWSFieldValueWrapper;
                my $FWSFieldContainer;
                my $FWSFieldValue;
                if ($paramHash{'inlineCSS'} eq '1') {
                        $FWSFieldTitle 		= " style=\"float:left;text-align:right;;color:#000000;width:25%;\"";
                        $FWSFieldValueWrapper 	= " style=\"float:left;width:70%;\"";
                        $FWSFieldContainer 	= " style=\"width:95%\"";
                }

                my $html .= "<div class=\"FWSFieldContainer\">";
                $html .= "<div ".$FWSFieldTitle."class=\"FWSFieldTitle\">";
                if ($paramHash{"updateType"} ne "" && $paramHash{"fieldType"} eq "textArea") { $html .= "<br/>" }
                $html .= $paramHash{"title"}."</div>";

                #
                # add precursor
                #
                $html .= "<div class=\"FWSFieldPreCursor\" style=\"width:10px;text-align:right;float:left;\">";
                if ($paramHash{'fieldType'} eq 'currency') { $html .= "\$" }
                else { $html .= "&nbsp;"}
                $html .= "</div>";

		

                $html .= "<div ".$FWSFieldValueWrapper."class=\"FWSFieldValueWrapper\">";
                $html .= "<div ".$FWSFieldValue."class=\"FWSFieldValue\">".$fieldHTML.$paramHash{"afterFieldHTML"}."</div>";
	        
		if (($paramHash{"fieldType"} =~ /^text$/ || $paramHash{"fieldType"} =~ /^textArea$/) && $paramHash{"unilingual"} ne '1' && $paramHash{'fieldName'} ne 'name') {
			my @langArray = $self->languageArray();
			#
			# eat the default
			#
			shift(@langArray); 
			while (@langArray) {
				my $langId = shift(@langArray);
				my %langHash = %origHash;
				$langHash{'updateType'} = 'AJAXExt';
				$langHash{'uniqueId'}  	= $langHash{'fieldName'}.'_'.$langHash{'guid'}.'_'.$langId;
				delete $langHash{'title'};
				$langHash{'fieldName'} 	= $langHash{'fieldName'}."_".$langId;
				$langHash{'fieldValue'} = $langHash{$langHash{'fieldName'}};
				$html .= $self->adminField(%langHash);	
			} 
        	}

                if ($paramHash{"note"} ne "") { $html .= "<div class=\"FWSFieldValueNote\">".$paramHash{"note"}."</div>" }
                $html .= "</div>";

                $html .= "<div style=\"clear:both;\"></div>";
                $html .= "</div>";
                return $html;
        }

        return $fieldHTML;
}

=head2 endElement

Return the complement to startElement() having the default by placing the appropriate close divs created in startElement().

        $valueHash{'html'} .= $fws->startElement(%dataHash);
        $valueHash{'html'} .= $fws->endElement(%dataHash);

=cut

sub endElement {
        my ($self) = @_;
        return "</div></div></div>";
        }

=head2 adminPageHeader

Return a standard HTML admin header for admin elements that open in new pages.

        #
        # Header for an admin page that opens in a new window
        #
        $valueHash{'html'} .= $fws->adminPageHeader(	name		=>'Page Name in the upper right',
							rightContent	=>'This will show up on the right,
									usually its a saving widget',
							title		=>'This is title on the left, it will
									look just like a panel title',
							icon		=>'somethingInTheFWSIconDirectory.png');

NOTE: This should only be used in the context of the FWS Administration, and is only here as a reference for modifiers of the admin. 

=cut

sub adminPageHeader {
        my ($self,%paramHash) = @_;
        my $bgIcon;
        if ($paramHash{'icon'} ne '') {
                $bgIcon .= "background: url(".$self->{'fileFWSPath'}."/icons/".$paramHash{'icon'}.") no-repeat scroll 0% 0% transparent;";
        }
        my $headerHTML = "<div class=\"FWSAdminPageHeader\">";
        $headerHTML .= "<div class=\"FWSAdminPageHeaderTitle\">".$paramHash{'name'}."</div>";
        $headerHTML .= "<div class=\"FWSAdminPageHeaderRight\">".$paramHash{'rightContent'}."</div>";
        $headerHTML .= "</div>";
        $headerHTML .= "<div class=\"FWSPanelTitle FWSAdminPageHeaderPanelTitle\" style=\"".$bgIcon." \">".$paramHash{'title'}."</div>";
        return $headerHTML;
}

=head2 tabs

Return jQueryUI tab html.  The tab names, tab content, tinyMCE editing field name, and any javascript for the tab onclick is passed as arrays to the method.   

	#
        # add the data to the tabs and panels to the HTML
        #
        $valueHash{'html'} .= $self->tabs(	id		=>'theIdOfTheTabContainer',
	                                  	tabs		=>[@tabs],
	                                  	tabContent	=>[@tabContent],
	                                  	tabJava		=>[@tabJava],
	                                 	
						# html and file tab support
	                                  	tabType		=>[@tabType],		# file, html or leave empty for standard panel
											# setting type will overwrite content and java provided

						tabFields	=>[@tabFields],		# field your updating

						guid		=>'someGUID',		# guid your updating
						
						# optional if your talking to a non-data table
						tabUpdateType	=>[@tabUpdateType],  	# defaults to AJAXExt
						table		=>'data',		# defaults to data

						# for file type only (required)
						currentFile     =>[@currentFile],	# 
	                                  	);

NOTE: This should only be used in the context of the FWS Administration, and is only here as a reference for modifiers of the admin.   In future versions this will be replaced with a hash array style paramater to make this less cumbersome, but this will be avaiable for legacy controls. 

=cut

sub tabs {
        my ($self,%paramHash) = @_;

        #
        # this will be the counter we will use for inique IDs for each tab for referencing
        #
        my $tabCount = 0;

        #
        # seed our tab html and the div html that will hold the content
        #
        my $tabDivHTML;
        my $tabHTML = "<div id=\"".$paramHash{"id"}."\" class=\"FWSTabs tabContainer ui-tabs ui-widget ui-widget-content ui-corner-all\"><ul class=\"tabList ui-tabs ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all\">";

        while (@{$paramHash{tabs}}) {
                my $tabJava 		= shift(@{$paramHash{tabJava}});
                my $tabContent 		= shift(@{$paramHash{tabContent}});
                my $tabName 		= shift(@{$paramHash{tabs}});
                my $fieldName 		= shift(@{$paramHash{tabFields}});
                my $tabType 		= shift(@{$paramHash{tabType}});
                my $tabUpdateType 	= shift(@{$paramHash{tabUpdateType}});
                my $currentFile 	= $self->urlEncode(shift(@{$paramHash{currentFile}}));

		#
		# set the default
		#               
		if ($tabUpdateType eq '') { $tabUpdateType = 'AJAXExt' }

		#
		# pass all the info in as the id so we can save it later
		#
		my $editorName  = $paramHash{'guid'}."_v_".$fieldName."_v_".$paramHash{'table'}."_v_".$tabUpdateType;

		#
		# tab type overwrites tabJava and tabContent!
		#
		if ($tabType eq 'file') {
            		$tabContent 	= "<div id=\"dataEdit".$fieldName."\">Loading...</div>";
			$tabJava	= "if(\$('#dataEdit".$fieldName."').html().length < 50) {\$('#dataEdit".$fieldName."').FWSAjax({queryString: '".$self->{'queryHead'}."p=fws_fileManager&current_file=".$currentFile."&field_update_type=".$tabUpdateType."&field_table=".$paramHash{'table'}."&field_name=".$fieldName."&guid=".$paramHash{'guid'}."',showLoading: false});}";
		}

		if ($tabType eq 'html') {
            		$tabContent 	= "<div name=\"".$fieldName."\" id=\"".$editorName."\" class=\"HTMLEditor\" style=\"width:100%;height:445px;\">".$tabContent."</div><div style=\"display:none;\" id=\"".$paramHash{'guid'}."_v_".$fieldName."_v_StatusNote\"></div>";
		}

                #
                # this is the connector between the tab and its HTML
                #
                my $tabHRef     = $paramHash{"id"}."_".$tabCount."_".$self->createPassword(composition=>'qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM',lowLength=>6,highLength=>6);

                #
                # if tiny mce is being used on a tab, lets light it up per the clicky
                # also tack on any tabJava we had passed to us
                #
                my $javaScript          = "if(typeof(tinyMCE) != 'undefined') {";
		$javaScript		.= "for (id in tinyMCE.editors) { tinyMCE.execCommand('mceRemoveControl', false, id); }";
                $javaScript             .= "tinyMCE.execCommand('mceAddControl', false, '".$editorName."');}";
                $javaScript             .= "if(typeof(\$.modal) != 'undefined') {\$.modal.update();}";
                $javaScript             .= $tabJava;
                $javaScript             .= "return false;";

                #
                # flag we are on the first one!... we want to hide the content areas if we are not
                #
                my $hideMe;
                if ($tabCount > 0) {$hideMe = " ui-tabs-hide" }

                #
                # add to the tab LI and the HTML we will put below for each tab
                #
                $tabHTML 	.= "<li class=\"tabItem tabItem ui-state-default ui-corner-top ui-state-hover\"><a onclick=\"".$javaScript."\" href=\"#".$tabHRef."\">".$tabName."</a></li>";
                $tabDivHTML 	.= "<div id=\"".$tabHRef."\" class=\"ui-tabs-panel ui-widget-content ui-corner-bottom".$hideMe."\">".$tabContent."</div>";

		#
		# add another tabCount to make our next tab unique ( plus a unique 6 char key )
		#
                $tabCount++;
        }

        #
        # the tabs need this jquery ui stuff to work.  lets make sure they are here if they aren't laoded already
        #
        $self->jqueryEnable('ui-1.8.9');
        $self->jqueryEnable('ui.widget-1.8.9');
        $self->jqueryEnable('ui.tabs-1.8.9');
        $self->jqueryEnable('ui.fws-1.8.9');

        #
        # return the tab content closing the ul and div we started in tabHTML
        #
        return $tabHTML.'</ul>'.$tabDivHTML.'</div>';
}


############################################################################################
# HELPER: organize JS scripts to be used
############################################################################################

sub _jsEnable {
        my ( $self, $jsEnable,$modifier ) = @_;

        #
        # get the current hash
        #
        my %jsHash = %{$self->{'_jsHash'}};

        #
        # if its already there lets just leave it alone
        #
        if ($jsHash{$jsEnable} eq '') { $jsHash{$jsEnable} = (keys %jsHash)+$modifier }

        #
        # pass the new hash back into the jsHash
        #
        %{$self->{'_jsHash'}} = %jsHash;
}


############################################################################################
# HELPER: organize CSS files to be used
############################################################################################

sub _cssEnable {
        my ( $self, $cssEnable,$modifier ) = @_;
	
        #
        # get the current hash
        #
        my %cssHash = %{$self->{'_cssHash'}};

        #
        # if its already there lets just leave it alone
        #
        if ($cssHash{$cssEnable} eq '') { $cssHash{$cssEnable} = (keys %cssHash)+$modifier }

        #
        # pass the new hash back into the cssHash
        #
        %{$self->{'_cssHash'}} = %cssHash;
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Format


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

Copyright 2012 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::Format
