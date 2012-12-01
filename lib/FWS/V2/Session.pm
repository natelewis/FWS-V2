package FWS::V2::Session;

use 5.006;
use strict;

=head1 NAME

FWS::V2::Session - Framework Sites version 2 session related methods

=head1 VERSION

Version 0.006

=cut

our $VERSION = '0.006';


=head1 SYNOPSIS

	use FWS::V2;
	
	my $fws = FWS::V2->new();

	$fws->saveFormValue('thisThing');


=head1 DESCRIPTION

FWS version 2 session methods are used to manipulate how a session is maintained, authenticated, and initiated.

=head1 METHODS


=head2 formArray

Return a list of all the available form values passed.

        #
        # get the array
        #
        my @formArray = $fws->formArray();

=cut

sub formArray {
        my ($self) =  @_;
        my @returnArray;
        for my $key ( keys %{$self->{'form'}}) { push (@returnArray,$key) }
        return @returnArray;
}

=head2 formValue

Get or set a form value.  If the value was not set, it will always return an empty string, never undefined.

        #
        # set the form value
        #
       	$fws->formValue('myVar','This is what its set to');

        #
        # get the form value and pass it to the html rendering
        #
       	$valueHash{'html'} .= $fws->formValue('myVar');

=cut

sub formValue {
        my ($self,$field,$fieldVal) =  @_;
        if (defined $fieldVal) { $self->{"form"}{$field} = $fieldVal }
        if (!defined $self->{"form"}{$field}) { $self->{"form"}{$field} = '' }
        return $self->{"form"}{$field};
}

=head2 getFormValues

Gather the passed form values, and from it set the language formValue and the session formValue.

        #
        # get the array
        #
        $fws->getFormValues();

=cut

sub getFormValues {
        my ($self) =  @_;
        use CGI qw(:cgi);
        my $cgi = new CGI();
        $CGI::POST_MAX=-1;
        foreach my $paramIn ($cgi->param) { $self->{"form"}{$paramIn} = $cgi->param($paramIn) }

        #
        # grab the one from the cookie if we have it
        #
        my $cookieSession = $cgi->cookie($self->{'sessionCookieName'});
        if ($cookieSession ne '' && $self->{"form"}{"session"} eq '') { $self->{"form"}{"session"} = $cookieSession }

        #
        # if fws_lang is not set, lets set it
        #
        if ($self->{"form"}{"fws_lang"} ne '') { $self->language(uc($self->{"form"}{"fws_lang"})) }
}

=head2 language

Get or set the current language.  If no language is currently set, the first entry in language will be used.  If languageArray has not be set, then 'EN' will be used.  The language can be set by being passed as a form value with the name 'fws_lang'.

        #
	# set the language
	#
        $fws->language('FR');

	#
	# get the language
	#
	$valueHash{'html'} .= 'The current language is: '.$fws->language().'<br />';	

=cut

sub language {
        my ( $self, $lang ) = @_;
        if (defined $lang) { $self->{"_language"} = $lang }
        if ($self->{"_language"} eq '') {
                my @langArray = $self->languageArray();
                $self->{"_language"} = $langArray[0];
        }
        if ($self->{"_language"} eq '') {  $self->{"_language"} = 'EN' }
        return uc($self->{"_language"});
}

=head2 languageArray

Set the languages the site will use.  The first one in the list will be considered default.  If languageArray is not set it will just contain 'EN'.

        #
        # set the languages available
        #
        $fws->languageArray('EN','FR','SP');

=cut

sub languageArray {
        my ( $self, @languageArray ) = @_;
        if (defined $languageArray[0]) { $self->{"_languageArray"} = uc(join('|',@languageArray)) }
        if ($self->{"_languageArray"} eq '') { return ('') }
        return (split(/\|/,$self->{"_languageArray"}));
}

=head2 saveFormValue

Mark a formValue to remain persistant with the session.
        
	#
        # This should go in a 'init' element or located int he go.pl file
        # at any point it can be referenced via formValue
        #
        $fws->saveFormValue('myCity');

=cut

sub saveFormValue {
	my ($self,$fieldName) = @_;
	#
	# add to session
	#
	my %saveWithSession = $self->_saveWithSessionHash();
	$saveWithSession{$fieldName} = 1;
	$self->_saveWithSessionHash(%saveWithSession);
}


=head2 setSiteValues

Set default values derived from the site settings for a site.  This will also set the formValue 'p' to the homeGUID if no 'p' value is currently set.

        #
        # currently rendered site
        #
        $fws->setSiteValues();

        #
        # set site values for some other site
        #
        $fws->setSiteValues('othersite');

=cut


sub setSiteValues {
        my ($self, $siteId) = @_;

        #
        # pre-set the valuse if they are not already
        #
        if ($siteId ne '') { $self->{'siteId'} = $siteId }

	#
	# if for any crazy reason this thing is still blank, lets use our default "site"
	#
	if ($self->{'siteId'} eq '') { $self->{'siteId'} = 'site' }

        #
        # get and set site assigned values
        #
        my ($siteExtraValue,$default_site);
        ($self->{'languageArray'},$self->{'siteName'},$self->{"site"}{'cssDevel'},$self->{"site"}{'jsDevel'},$self->{'siteGUID'},$siteExtraValue,$default_site,$self->{'gatewayUserID'},$self->{'gatewayType'},$self->{'email'},$self->{"site"}{'homeGUID'}) = @{$self->runSQL(SQL=>"select language_array,name,css_devel,js_devel,guid,extra_value,default_site,gateway_user_id,gateway_type,email,home_guid from site where sid='".$self->safeSQL($self->{'siteId'})."'")};

	#
	# move the lang into the useable array
	#
	$self->languageArray(split(',',$self->{'languageArray'}));

	#
	# if for any reason homeGUID is blank, lets make a new one and its page
	# but only do it, if we have a real site.  Just skip it because we could
	# be doing something else that isn't site rendering
	#
	if ($self->{"site"}{'homeGUID'} eq '' && $self->{'siteGUID'} ne '') {
        	my $homeGUID = $self->{'siteGUID'};
        	$homeGUID =~ s/^./h/sg;
        	$self->siteValue('homeGUID',$homeGUID);
        	$self->runSQL(SQL=>"update site set home_guid='".$self->safeSQL($homeGUID)."' where guid='".$self->safeSQL($self->{'siteGUID'})."'");

        	#
        	# make the actual page
        	#
		# there isn't actually a type home, this is the flag that allows you to make a xref that does not have  a parent it will be flipped to 'page 
		#
       		$self->saveData(type=>'home',parent=>'',newGUID=>$homeGUID);
		}

        #
        # check to see if there is no level... if so then we need create a new admin account
        #
        if ($self->{'siteGUID'} eq '') { print $self->newDBCheck() }

        #
        # convert the values and fields to global valuse
        #
        my %siteHash = $self->addExtraHash($siteExtraValue);

	#
        # get the keys and and set them
        #
        for my $key ( keys %siteHash ) { $self->siteValue( $key, $siteHash{$key} ) }

        #
        # set the data cache hash
        #
        my @indexArray = split(/,/,$self->siteValue("dataCacheIndex"));
        while (@indexArray) { $self->{"dataCacheFields"}->{shift(@indexArray)} = 1 }

        #
        # if we are not the default site turn off friendlies
        #
        if ($default_site ne '1') { $self->siteValue('noFriendlies','1') }
        else { $self->siteValue('noFriendlies','0') }

        #
        # Now that we have the session we can set the queryHead
        #
        $self->{'queryHead'} = "?fws_noCache=".$self->createPassword(composition=>'qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM',lowLength=>6,highLength=>6)."&session=".$self->formValue('session')."&s=".$self->formValue('s')."&";

        #
        # if p is still blank, lets set it
        #
        if ($self->formValue('p') eq '') { $self->formValue('p',$self->siteValue('homeGUID')) }

        #
        # set where we will get FWS files from
        #
        $self->{'fileFWSPath'} = $self->fileWebPath().'/fws';




}

=head2 siteValue

Get or save a siteValue for the session.

	#
	# save something
	#
        $fws->siteValue('something','this is something');

	#
	# get something
	#
        my $something = $fws->siteValue('something');

=cut

sub siteValue {
        my ($self,$field,$fieldVal) =  @_;
        if (defined $fieldVal) { $self->{"site"}{$field} = $fieldVal }
        if (!defined $self->{"site"}{$field}) { $self->{"site"}{$field} = '' }
        return $self->{"site"}{$field};
}

=head2 userValue

Get or set a admin user value.  This is used mostly for security flags and should only be used to get values FWS has set, never to change or set them.

	#
        # is the admin user a developer?
        #
        my $isDeveloper = $fws->siteValue('isDeveloper');

=cut

sub userValue {
        my ($self,$field,$fieldVal) =  @_;
        if (defined $fieldVal) { $self->{"user"}{$field} = $fieldVal }
        if (!defined $self->{"user"}{$field}) { $self->{"user"}{$field} = '' }
        return $self->{"user"}{$field};
}

############################################################################################
# HELPER: organize and combine what formValues that will be saved with the session
############################################################################################

sub _saveWithSessionHash {
        my ( $self, %saveWithSessionHash ) = @_;
        if (keys %saveWithSessionHash) { %{$self->{"_saveWithSessionHash"}} = %saveWithSessionHash }

	#
	# add the save with session site value directive also
	#
        my @addSession = split(/,/,$self->siteValue('saveWithSession'));
        while (@addSession) { ${$self->{"_saveWithSessionHash"}}{shift @addSession} = 1 }

        return %{$self->{"_saveWithSessionHash"}};
}




=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Session


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

1; # End of FWS::V2::Session
