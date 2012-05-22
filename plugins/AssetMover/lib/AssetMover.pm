package AssetMover;


package MT::Asset;

use strict;
use warnings;
use MT::Util qw( dirify );

sub relocate {
    my ( $asset, $path ) = @_;

    # If the asset doesn't have a file_path, just move on. Assets don't 
    # need to be files. Also check that the asset actually exists. If the 
    # file can't be found then we don't need to try to move it!
    return 0 unless $asset->file_path && -e $asset->file_path;

    if ( File::Spec->file_name_is_absolute( $path ) ) {
        return $asset->error(
              'Destination path must be relative to a blog or the '
            . 'static_path (for system-level assets only)'
        );
    }

    return $asset->error('System-level assets cannot be relocated')
        unless $asset->blog_id;

    my $blog      = MT->model('blog')->load( $asset->blog_id );
    my $fmgr      = $blog->file_mgr;
    my @dirs      = map { dirify($_) } split( '/', $path );
    my $dest_path = File::Spec->catdir( $blog->site_path, @dirs );
    my $dest_file = File::Spec->catfile( $dest_path, $asset->file_name );

    return $asset->error('Destination path is identical to current path');
        if $asset->file_path eq $dest_file;

    if ( ! $fmgr->exists($dest_path) ) {
        $fmgr->mkpath($dest_path)
            or return $asset->errtrans( 'Error making path [_1]: [_2]',
                                            $dest_path, $fmgr->errstr );
    }

    $fmgr->rename( $asset->file_path, $dest_file )
        or return $asset->errtrans(
            'Error moving asset file: [_1]', $fmgr->errstr );

    $asset->file_path( File::Spec->catfile('%r', @dirs, $asset->file_name) );
    $asset->url( join('/', '%r', @dirs, $asset->file_name ) );
    $asset->save;
}


1;