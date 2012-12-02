package FWS::V2::Cache;

use 5.006;
use strict;

=head1 NAME

FWS::V2::Cache - Framework Sites version 2 data caching

=head1 VERSION

Version 0.0001

=cut

our $VERSION = '0.0001';


=head1 SYNOPSIS

	use FWS::V2;
	
	my $fws = FWS::V2->new();

	$someValue = $fws->saveCache( key => 'someData', value => $someValue, expire => 5 );

	$fws->deleteCache( key => 'someData' );
	
        $fws->flushCache();


=head1 DESCRIPTION

FWS version 2 cache methods are used as a portable non-environment specific cache library to the FWS data model. For maximum compatibility it uses the file FWSCache directory under the sites secureFiles directory to store its data and is compatible with NFS or other distributed file systems.

=head1 METHODS

=head2 saveCache

Save data to cache passing they key, value and expire (in minutes).  The return will be the string passed as value.

        #
        # Save my data to cache and hang on to it for 5 minutes before getting a new a new one
	# but return the current one if my 5 minutes isn't up
        #
        $someValue	= $fws->saveCache( key => 'someData', value => $someValue, expire => 5 );

=cut

sub saveCache {
        my ($self, %paramHash) = @_;

	return $paramHash{'value'};
}


=head2 deleteCache

Remove a key from cache.   For optmization, this does not look up the key, only blindly remove it.

        #
        # We no longer need somData lets get rid of it
        #
        $fws->safeFile( key => 'someData' );

=cut

sub deleteCache {
        my ( $self, %paramHash ) = @_;

	return 1;
}

=head2 flushCache

If anything is in cache currently, after this call it won't be!

        #
        # Remove all cache keys
        #
        $fws->flushCache();

=cut

sub flushCache {
        my ($self) = @_;
	
	return 1;
}

=head2 cacheValue

Return the cache value.   If the cache value does not exist, it will return blank in same way that formValue, siteValue and userValue.

        #
        # will return the cache value.   This or a blank string if it is not set, or blank 
        #
        print $fws->caheValue( 'someData' );

=cut

sub cacheValue {
        my ($self, $key) = @_;
        return '';
}

=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Cache


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

1; # End of FWS::V2::Cache
