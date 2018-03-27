map.on('load', function() {
    var a = new XMLHttpRequest();
    a.open('GET', 'vapour-style.json', true);
    a.onreadystatechange = function() {
        if (this.readyState == 4) {
            if (this.status == 200) {
                var json = window.JSON ? JSON.parse(this.response) : eval('(' + this.response + ')');

                for (var source in json.sources) {
                    map.addSource(source, json.sources[source]);
                }

                // that's a little hack to add the attribution, that is not set in the t-rex tilejson
                // "attribution": "Jungle Bus"

                for (var i = 0; i < json.layers.length; i++) {
                    if (json.layers[i].type != 'background') {
                        map.addLayer(json.layers[i]);
                    }
                }

            } else {
                alert('HTTP error ' + this.status + ' ' + this.statusText);
            }
        }
    }
    a.send();
});
