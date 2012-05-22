package AssetMover::Plugin;

use warnings;
use strict;

use File::Spec;
use MT::FileMgr;
use MT::Util qw( dirify );
use AssetMover;

# The user has selected some assets on the Manage Assets screen
# and chosen to move them.
sub action {
    my ($app)       = @_;
    my $q           = $app->query;
    my @asset_ids   = $q->param('id');
    my $folder      = $q->param('itemset_action_input') || '';  # '' = blog root
    my $asset_class = MT->model('asset');

    $app->validate_magic or return;

    my $moved_cnt = my $failed_cnt = 0;

    foreach my $asset_id ( @asset_ids ) {

        my $asset = $asset_class->load( $asset_id ) or next;

        if ( $asset->relocate( $folder ) ) {
            $moved_cnt++;
        }
        else{
            $app->log({
                message => $app->translate( 'AssetMover error: [_1]', 
                                            $asset->errstr || 'Unknown error'),
                level    => MT::Log::ERROR(),
                class    => 'asset',
                category => 'relocate',
            });
            $failed_cnt++;
        }
    }

    $app->add_return_arg( assets_failed => $failed_cnt ) if $failed_cnt;
    $app->add_return_arg( assets_moved  =>
                            $moved_cnt == @asset_ids ? 'All' : $moved_cnt );
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
        <mtapp:statusmsg id="assets_moved" class="success">
            <mt:var name="assets_moved"> of the selected asset(s) were
            successfully moved. Be sure to republish the blog and
            double-check for any existing use of the old URL!
        </mtapp:statusmsg>
    </mt:if>
    <mt:if name="assets_failed">
        <mtapp:statusmsg id="assets_failed" class="error">
            <mt:var name="assets_failed"> of the selected asset(s) were
            <em>not</em> successfully moved. Please see the activity log
            for any error messages encountered in the process.
        </mtapp:statusmsg>
    </mt:if>
HTML

    $$tmpl =~ s/$old/$new/;
}

sub messaging_param {
    my ($cb, $app, $param, $tmpl) = @_;
    my $q = $app->query;

    $param->{assets_moved}     = $q->param('assets_moved')  || 0;
    $param->{assets_not_moved} = $q->param('assets_failed') || 0;
}

# # Display the Move Assets list action at the blog level only.
# sub condition {
#     return 1 if MT->instance->blog;
#     return 0;
# }

1;

__END__

=head1 NAME

AssetMover::Plugin

=head1 DESCRIPTION

=head1 METHODS

=head2 action

The method is the C<move_assets> C<list_action> handler which is accessible
from the asset listing screen.

=head2 messaging_source

A application template source callback through which the plugin adds its
success/error message conditionals to the application template

=head2 messaging_param

A application template param callback through which the plugin populates the
parameters needed to display the appropriate success and/or error message.

=cut

# =head2 condition
