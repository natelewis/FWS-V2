package FWS::V2::Check;

use 5.006;
use strict;


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
	if ($fws->isValidEmail('this@email.com')) { print "Its not real, but it could be!\n" } 
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
        if ($fws->isAdminLoggedIn()) { $valueHash{'html'} .= 'I am logged in as a admin<br/>' }

=cut

sub isAdminLoggedIn {
        my ($self,$loginType) = @_;
        if ($self->{'adminLoginId'} ne '') { return (1) } else { return (0) }
        }

=head2 isUserLoggedIn

Return a 0 or 1 depending if a site user is currently logged in.

        #
        # do something if logged in as an site user
        #
        if ($fws->isUserLoggedIn()) { $valueHash{'html'} .= 'I am logged in as a user<br/>' }

=cut

sub isUserLoggedIn {
        my ($self,$loginType) = @_;
        if ($self->{'userLoginId'} eq '') { return (0) } else { return (1) }
        }

=head2 isValidEmail

Return a boolean response to validate if an email address is well formed.

=cut

sub isValidEmail {
        my ($self,$fieldValue) = @_;
        if ($fieldValue !~ /^\w+[\w|\.|-]*\w+@(\w+[\w|\.|-]*\w+\.[a-z]{2,4}|(\d{1,3}\.){3}\d{1,3})$/i) { return (0) }
        return (1);
        }

##########################################################################################
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
