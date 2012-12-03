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


	my $cacheData = $fws->cacheValue( 'someData' ) || &{ sub {
	        my $value = 'This is a testineeg!';
	        #
	        # do something...
	        #
	        return $fws->saveCache( key=>'someData', expire=>1, value=>$value );
	} };

	print $cacheData;
	
	$fws->deleteCache( key => 'someData' );
	
        $fws->flushCache();


=head1 DESCRIPTION

FWS version 2 cache methods are used as a portable non-environment specific cache library to the FWS data model. For maximum compatibility it uses the file FWSCache directory under the sites fileSecurePath directory to store its data and is compatible with NFS or other distributed file systems.

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

	#
	# set default expire if not passed
	#
	$paramHash{'expire'} ||= 60;

        #
        # make the dir for the cache
        #
	my $cacheDir = $self->{'fileSecurePath'}."/cache/".$self->safeFile( $paramHash{key} ) ;
       	$self->makeDir( $cacheDir );

	#
	# set cache file based on expire date
	#
	my $newFile = $cacheDir.'/'.( time + ( $paramHash{expire} * 60 ) );
	
	#
	# set the file name as the exp epoch with its content
	#
        open( FILE, ">$newFile" );
	print FILE ( time + ( $paramHash{expire} * 60 ) )."\n";
        print FILE $paramHash{value};
	close( FILE );
	
	#
	# Move it to the live value, or if we have something nasty from file locking happen
	# what ever is there will be good in those rare cases
	#
        rename $newFile, $cacheDir.'/value';

	#
	# return what we were givin
	#
	return $paramHash{'value'};
}


=head2 deleteCache

Remove a key from cache.   For optmization, this does not look up the key, only blindly remove it.

        #
        # We no longer need somData lets get rid of it
        #
        $fws->deleteCache( key => 'someData' );

=cut

sub deleteCache {
        my ( $self, %paramHash ) = @_;
	
	my $cacheDir = $self->{'fileSecurePath'}."/cache/".$self->safeFile( $paramHash{key} );
       
	my @fileArray = @{$self->fileArray( directory=>$cacheDir ) };
        for my $i (0 .. $#fileArray) { unlink $fileArray[$i]{'fullFile'} }

	rmdir $cacheDir;
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

	my $cacheDir = $self->{'fileSecurePath'}."/cache" ;

        #
        # pull the directory into an array
        #
        opendir( DIR, $cacheDir );
        my @getDir = grep(!/^\.\.?$/,readdir( DIR ));
        closedir( DIR );

	#
	# eat each cache in the dir
	#
        foreach my $dirFile (@getDir) { if (-d $cacheDir.'/'.$dirFile) { $self->deleteCache( key => $dirFile ) }
        }
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

	#
        # set cache file based on expire date
        #
	my $cacheDir = $self->{'fileSecurePath'}."/cache/".$self->safeFile( $key );
        my $newFile = $cacheDir.'/value';

        #
        # set the value to blank to start
        #
	my $value = '';


	#
	# if the cache file does not exist then return the blank
	#
	if ( !-e $newFile ) { return $value }

	#
	# open the file and get the first line
	# 
        open( FILE, $newFile );
        chomp( my $timeStamp = <FILE> );

	#
	# if we are still within timestamp lets return it
	#
	if ( $timeStamp > time ) { while (<FILE>) { $value .= $_ } }
	
	#
	# Return the value and close the file
	#
        close( FILE );
        return $value;
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
