package FWS::V2::Check;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';

=head1 NAME

FWS::V2::Check - Framework Sites version 2 validation and checking methods

=head1 VERSION

Version 0.003

=cut

our $VERSION = '0.003';


=head1 SYNOPSIS

	use FWS::V2;

	#
	# Create $fws
	#	
	my $fws = FWS::V2->new();

	#
	# all simple boolean response in conditionals
	#
	if ( $fws->isValidEmail( 'this@email.com') ) { print "Its not real, but it could be!\n" } 
	else { print "Yuck, bad email.\n" } 


=head1 DESCRIPTION

Simple methods that will return boolean results based on the validation of the passed parameter.

=cut


=head1 METHODS

=head2 isAdminLoggedIn

Return a 0 or 1 depending if a admin user is currently logged in.


        #
        # do something if logged in as an admin user
        #
        if ( $fws->isAdminLoggedIn() ) { $valueHash{html} .= 'I am logged in as a admin<br/>' }

=cut

sub isAdminLoggedIn {
    my ( $self, $loginType ) = @_;
    if ( $self->{adminLoginId} ) { return 1 }
    return 0;
}

=head2 isUserLoggedIn

Return a 0 or 1 depending if a site user is currently logged in.

        #
        # do something if logged in as an site user
        #
        if ( $fws->isUserLoggedIn() ) { $valueHash{html} .= 'I am logged in as a user<br/>' }

=cut

sub isUserLoggedIn {
    my ( $self, $loginType ) = @_;
    if ( $self->{userLoginId} ) { return 1 }
    return 0;
}

=head2 isValidEmail

Return a boolean response to validate if an email address is well formed.

=cut

sub isValidEmail {
    my ( $self, $fieldValue ) = @_;
    if ( $fieldValue !~ /^\w+[\w|\.|-]*\w+@(\w+[\w|\.|-]*\w+\.[a-z]{2,4}|(\d{1,3}\.){3}\d{1,3})$/i ) { return 0 }
    return 1;
}

=head2 isCaptchaValid

Built in captcha support will return 1 or 0 based on the last captcha post.

=cut

sub isCaptchaValid {
    my ( $self ) = @_;
    my $publicKey   = $self->siteValue( 'captchaPublicKey' );
    my $privateKey  = $self->siteValue( 'captchaPrivateKey' );
    my $returnHTML;
    if ( $publicKey ) {
        require Captcha::reCAPTCHA;
        Captcha::reCAPTCHA->import();
        my $captcha = Captcha::reCAPTCHA->new();
        my $result = $captcha->check_answer( $privateKey, $ENV{REMOTE_ADDR}, $self->formValue( 'recaptcha_challenge_field' ), $self->formValue( 'recaptcha_response_field' ) );
        if ( !$result->{is_valid} ) { return 0 }
    }
    return 1;
}


=head2 isStrongPassword

FWS standard strong password checker.   Upper, lower, symbol, at least 6 chars.

=cut

sub isStrongPassword {
    my ( $self, $fieldValue ) = @_;
    if ( $fieldValue !~ /^.*(?=.{6,})(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).*$/) { return 0 }
    return 1;
}

=head2 isElementPresent

See if an element is present on the current page.  This is here for some legacy code but should not be used because it is not good practice and could be slow if the page is complex.  Just find another way to achieve the same result of knowing if something is present on a page.

=cut

sub isElementPresent {
    my ( $self, $guid, $elementName ) = @_;

    #
    # Lets check if the formavalue FWS_elementblahblah is set if, so we have already looked this up and don't need to re-run it
    #
    my $isPresent = $self->formValue( 'FWS_ELEMENT_PRESENT_' . $elementName );

    #
    # if it is blank, then we do need to run it for the first time :(
    #
    if ( !$isPresent ) {

            #
            # pull from the database to see if its there
            #
            my $pageId = $self->getPageGUID( $guid );
            ( $isPresent ) = @{$self->runSQL( SQL => "select 1 from data left join guid_xref on data.guid=child where guid_xref.parent='". $self->safeSQL( $pageId ) . "' and data.site_guid='" . $self->safeSQL( $self->{siteGUID} ) . "' and (element_type like '" . $self->safeSQL( $elementName ) . "')" )};

            #
            # if it comes back as "NO NO NO!"  then it will be blank.  so we will need to set it to 0
            #
            $isPresent ||= 0;

            #
            # Set the form value to what the value is so then we don't have to worry about it the next time we are here
            #
            $self->formValue( 'FWS_ELEMENT_PRESENT_' . $elementName, $isPresent );
    }

    #
    # pass back the value if we have gotten it from the cache or we had to look it up
    #
    return $isPresent;
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-lite at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-Check>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Check


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FWS-Check>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FWS-Check>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FWS-Check>

=item * Search CPAN

L<http://search.cpan.org/dist/FWS-Check/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::Check
