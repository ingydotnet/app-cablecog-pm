package App::CableCog;
use Mouse;
extends 'Cog::App';

our $VERSION = '0.10';

use constant webapp_class => 'App::CableCog::WebApp';
use constant store_class => 'App::CableCog::Store';
use constant content_class => 'App::CableCog::Content';
use constant view_class => 'App::CableCog::View';

package App::CableCog::WebApp;
use Mouse;
extends 'Cog::WebApp';

use constant site_navigation => [
    '()',
    ['All Cables' => ['/list/cable/']],
    ['Tag Cloud' => ['/tag/cloud/']],
];

use constant url_map => [
    '()',
    ['/?' => 'redirect', '/list/cable/'],
    ['/list/cable/' => 'cable_list'],
    ['/tag/cloud/' => 'tag_cloud'],
    ['/tag/([^/]+)/?' => 'tag_page_list', ('$1')],
    ['/cable/([A-Z0-9]{4})/?' => 'cable_display', ('$1')],
];

use constant js_files => [qw(
    jquery.tablesorter.js
    tag-cloud.js
    cablecog.js
)];

use constant css_files => [qw(
    cablecog.css
    tag-cloud.css
)];

sub handle_save_cable {
    my $self = shift;
    my $data = $self->env->{post_data} or die;
    my $node = $self->store->add('cable');
    $data->{Name} = [delete $data->{publish_title}];
    $self->store->update_node_from_hash($node, $data);
    $self->store->put($node);
    $self->store->flush;
    return;
}

sub handle_save_html {
    my $self = shift;
    my $data = $self->env->{post_data} or die;
    my $html = $data->{html} or die;
    io('all.html')->print($html);
    return;
}

package App::CableCog::Store;
use Mouse;
extends 'Cog::Store';

use constant schemata => [
    'App::CableCog::Cable::Schema',
];

sub put {
    my ($self, $node) = @_;
    my $pointer = $self->content->content_pointer($node);
    return if -e $pointer and not $self->importing;
    $self->view->update($node);
    $self->content->update($node);
}

package App::CableCog::Cable::Schema;
use Mouse;
extends 'Cog::Schema';

use constant type => 'cable';
use constant parent => 'CogNode';
use constant fields => [
    'publish_date',
    'cable_title',
    'cable_sent',
    'cable_number',
];

package App::CableCog::Content;
use Mouse;
extends 'Cog::Content';

sub cog_files {
    my $self = shift;
    my $root = $self->config->content_root;
    return [
        map { chomp; $_ }
            `find $root/cable -name *.cog`,
    ];
}

package App::CableCog::View;
use Mouse;
extends 'Cog::View';

use IO::All;

sub update_page_list {
    my ($self, $blob) = @_;
    my $meta = {
        map {($_, $blob->{$_})} qw(
            Id
            Rev
            Title
            cable_number
            cable_sent
        )
    };
    my $list = $self->views->{'cable-list'} ||= [];
    push @$list, $meta;
}

my @tags = (
    'United States',
    'Taiwan',
    'China',
    'Taipei',
    'San Franciso',
    'Obama',
    'Libya',
    'Egypt',
    'Beijing',
    'Japan',
    'Tokyo',
    'Earthquake',
    'Tsunami',
);

my $time = time;
sub update_tag_cloud {
    my ($self, $blob) = @_;
    my $cloud = $self->views->{'tag-cloud'} ||= {};
    my $meta = {
        map {($_, $blob->{$_})} qw(
            Id
            Rev
            Title
            cable_number
            cable_sent
        )
    };
    for my $tag (@tags) {
        next unless $blob->{Body} =~ /\b$tag\b/i or
            $blob->{Title} =~ /$tag/;
        $self->add_tag($cloud, $tag, $time, $meta);
    }
}

sub update_page_html {
    my ($self, $id, $node) = @_;
    io($self->root . "/$id.txt")->print($node->Body);
}

1;
