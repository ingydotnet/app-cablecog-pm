Cog.App = 'CableCog';

$CableCog = (CableCog = function() {this.init()}).prototype = new Cog;

$CableCog.cable_list = function() {
    $.getJSON('/view/cable-list.json', this.bind('cable_list_received'));
}

$CableCog.cable_list_received = function(ajax, data) {
    var stash = {
        title: 'All Cables',
        cables: data
    };
    Jemplate.process('cable-list.html.tt', stash, $('.content')[0]);
    $('table.sortable').tablesorter();
}

$CableCog.tag_cloud = function() {
    Jemplate.process('tag-cloud.html.tt', {}, $('div.content')[0]);
    $.getJSON('/view/tag-cloud.json', function(data) {
        var tc = TagCloud.create();
        for (var i = 0; i < data.length; i++) {
            var tag = data[i][0];
            var num = data[i][1];
            var time = data[i][2];
            tc.add(
                tag,
                num,
                '/tag/' + tag,
                time
            )
        }
        tc.loadEffector('CountSize').base(30).range(15);
        tc.loadEffector('DateTimeColor');
        tc.setup('mytagcloud');
    });
};

$CableCog.tag_page_list = function(tag) {
    var self = this;
    $.getJSON('/view/tag/' + tag + '.json', function(data) {
        data = {cables: data};
        data.title = 'Tag: ' + tag.replace(/%20/g, ' ');
        Jemplate.process('cable-list.html.tt', data, $('div.content')[0]);
        $('table.sortable').tablesorter();
    });
};

$CableCog.cable_display = function(id) {
    var self = this;
    $.getJSON('/view/' + id + '.json', this.bind('cable_display_data', id));
};

$CableCog.cable_display_data = function(id, ajax, data) {
    Jemplate.process('cable-display.html.tt', data, $('div.content')[0]);
    $.get('/view/' + id + '.txt', function(text) {
        var html = text.replace(/\n/g, '<br>\n');
        $('div.cable').html(html);
    });
};

