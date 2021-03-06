package AssetMover::Plugin;

use warnings;
use strict;

use MT::Util qw( dirify );

# The user has selected some assets on the Manage Assets screen and chosen to 
# move them.
sub action {
    my ($app) = @_;
    $app->validate_magic or return;
    my $q = $app->query;

    # Grab the folder name the user entered. Ensure that it's a valid folder 
    # name and that the location is writable. Fall back to no folder (''), 
    # which is the blog root -- a valid location to place an asset.
    my $folder = $q->param('itemset_action_input') || '';

    # If the user has specified a folder structure, such as 'my/asset/folder',
    # we want to be sure to retain that. Dirify each part of the folder 
    # structure, then turn it back into a path.
    my @folders = split('/', $folder);
    map { $_ = dirify($_) } @folders;

    # This flag is used to return a message to the user about the success of 
    # the asset move. If no assets were moved because they are missing or 
    # non-file assets we want to report it to them.
    my $moved_flag;

    my @asset_ids = $q->param('id');
    foreach my $asset_id (@asset_ids) {
        my $asset = MT->model('asset')->load($asset_id)
            or next;

        # If the asset doesn't have a file_path, just move on. Assets don't 
        # need to be files. Also check that the asset actually exists. If the 
        # file can't be found then we don't need to try to move it!
        next unless $asset->file_path && -e $asset->file_path;

        my $blog = MT->model('blog')->load($asset->blog_id);
        my $fmgr = $blog->file_mgr;
        
        my $dest_path = File::Spec->catdir($blog->site_path, @folders);

        # Check if the destination exists, and create it if necessary.
        if ( !$fmgr->exists($dest_path) ) {
            $fmgr->mkpath($dest_path)
                or die $fmgr->errstr;
        }

        # Now that the destination exists we can move the file there.
        my $dest_file = File::Spec->catfile($dest_path, $asset->file_name);
        $fmgr->rename($asset->file_path, $dest_file)
            or die $fmgr->errstr;

        # Set the asset file_path to a relative ('%r') location.
        $asset->file_path(
            File::Spec->catfile('%r', @folders, $asset->file_name)
        );

        # Set the asset URL to a relative location.
        $asset->url(
            join('/', '%r', @folders) . '/' . $asset->file_name
        );

        $asset->save or die $asset->errstr;

        # Now that the asset has been successfully moved, mark $moved_flag as 
        # true. This will be used to display the correct notification on the 
        # Manage Assets screen about the move's success.
        $moved_flag = 1;
    }

    # All valid selected assets were successfully moved. Use a transformer
    # callback to add this message.
    $moved_flag 
        ? $app->add_return_arg( assets_moved => 1 )
        : $app->add_return_arg( assets_not_moved => 1 );

    $app->call_return;
}

# Including success/fail messages on the Manage Assets screen.
sub messaging_source {
    my ($cb, $app, $tmpl) = @_;

    my ($old, $new);

    $old = q{<mt:setvarblock name="system_msg">};
    $new = <<HTML;
<mt:setvarblock name="system_msg">
    <mt:if name="assets_moved">
        <mtapp:statusmsg
            id="assets_moved"
            class="success">
            The selected asset(s) have been successfully moved. Be sure to 
            republish and double-check for any existing use of the old URL!
        </mtapp:statusmsg>
    </mt:if>
    <mt:if name="assets_not_moved">
        <mtapp:statusmsg
            id="assets_not_moved"
            class="success">
            The selected asset(s) have <em>not</em> been successfully moved. 
            The selected asset(s) are not file-based or are missing.
        </mtapp:statusmsg>
    </mt:if>
HTML

    $$tmpl =~ s/$old/$new/;
}

sub messaging_param {
    my ($cb, $app, $param, $tmpl) = @_;
    my $q = $app->query;

    $param->{assets_moved} = $q->param('assets_moved') || '';
    $param->{assets_not_moved} = $q->param('assets_not_moved') || '';
}

# Display the Move Assets list action at the blog level only.
sub condition {
    return 1 if MT->instance->blog;
    return 0;
}

1;
