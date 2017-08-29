'use strict';

var config = {
  mapboxAccessToken: 'pk.eyJ1IjoiamowaG5zMG4iLCJhIjoiY2o1YjRtMjZpMGd2MDJ3bW00bnA5NXdyMiJ9.qlR4a_qfTlKZs1Qisk6sAg',
  digitalGlobeAccessToken: 'pk.eyJ1IjoiZGlnaXRhbGdsb2JlIiwiYSI6ImNqNWIyMHkxdzBmNGczNG55bGNhc2tlcncifQ.lQXsl-GCFgJWmIKEeaRpPg',
  digitalGlobeMapId:'digitalglobe.nal0g75k',
  startingCenter: [-117.15117725013909, 32.72269876352742],
  startingZoom: 15,
  mapboxStyle: function(style) {
    return '/styles/'+style+'3d.json';
  },
  ol3Style: function(style) {
    return '/styles/'+style+'.json';
  },
  lambda: "https://d39scxemoxfvki.cloudfront.net/capabilities/osm.json?debug=true",
  ec2: "http://tegola-cdn.terranodo.io/capabilities/osm.json?debug=true"
};

var map, currentLib, currentStyle, currentServer;

var openlayers = {
  openLayersSatellite: new ol.layer.Tile({
    title: 'DigitalGlobe Maps API: Recent Imagery',
    source: new ol.source.XYZ({
      url: 'http://api.tiles.mapbox.com/v4/'+config.digitalGlobeMapId+'/{z}/{x}/{y}.png?access_token='+config.digitalGlobeAccessToken,
      attribution: "© DigitalGlobe, Inc"
    })
  }),
  init: function() {
    map = olms.apply('map', config.ol3Style(currentStyle));
    map.getView().setCenter(ol.proj.fromLonLat(config.startingCenter));
    map.getView().setZoom(config.startingZoom);

    if (window.location.hash !== '') {
    // try to restore center, zoom-level and rotation from the URL
      var hash = window.location.hash.replace('#', '');
      var parts = hash.split('/');
      if (parts.length === 3) {
        var zoom = Math.ceil(parts[0]);
        var center = [
        parseFloat(parts[2]),
        parseFloat(parts[1])
        ];
      }
      map.getView().setCenter(ol.proj.fromLonLat(center));
      map.getView().setZoom(zoom);
    }

		map.getView().on('propertychange', function(e) {
      openlayers.updateHash();
    });
  },
  switchStyle: function(style) {
    map.getLayers().getArray().forEach(function(layer) {
      map.removeLayer(layer);
    });
    map = olms.apply(map, config.ol3Style(style));
    //  TODO: move this to a gloabl config that maps the style names with style.json files and satellite basemaps if necessary.
    //  bonus: build the style buttons from the config on app init
    if(style === 'night-vision') {
      map.addLayer(this.openLayersSatellite);
    }
  },
  updateHash: function() {
    var view = map.getView();
    var center = view.getCenter();
    var lonLat = ol.proj.toLonLat(center);
    var hash = '#' +
      view.getZoom() + '/' +
      lonLat[1] + '/' +
      lonLat[0];
    var state = {
      zoom: view.getZoom(),
      center: view.getCenter()
    };
    window.history.pushState(state, 'map', hash);
  },
  updatePosition: function(lat, lon, zoom) {
    map.getView().setCenter(ol.proj.fromLonLat([lon,lat]));
    map.getView().setZoom(zoom);
  }
}

var mapbox = {
  init: function() {
    mapboxgl.accessToken = config.mapboxAccessToken;
    map = new mapboxgl.Map({
      container: 'map', // container id
      style: config.mapboxStyle(currentStyle),
      center: config.startingCenter,
      zoom: config.startingZoom,
      hash: true
    });
    map.addControl(new mapboxgl.NavigationControl());
  },
  switchStyle: function(style) {
    d3.json(config.mapboxStyle(style), function(error, data) {
      data.sources["tegola-osm"].url = currentServer;
      map.setStyle(data)
    });
    //  TODO: move this to a gloabl config that maps the style names with style.json files and satellite basemaps if necessary.
    if(style === 'night-vision') {
    }
  },
  updatePosition: function(lat, lon, zoom) {
    map.setCenter([lon, lat]);
    map.setZoom(zoom);
  }
};
var switchLib = function(lib) {
  currentLib = lib;
  document.getElementById('map').innerHTML = '';
  lib.init();
}
var switchStyle = function(style) {
  currentStyle = style;
  currentLib.switchStyle(style);
}
var switchServer = function(type) {
  currentServer = config[type];
  currentLib.switchStyle(currentStyle);
}
document.getElementById('server-switch').addEventListener('change', function(event) {
  switchServer(this.value);
})
document.getElementById('city-switch').addEventListener('change', function(event) {
  var coordinates = this.value.split(",")
  currentLib.updatePosition(parseFloat(coordinates[0]), parseFloat(coordinates[1]), 12);
})
currentLib = mapbox;
currentStyle = 'mapbox';
currentServer = 'ec2';
currentLib.init();
