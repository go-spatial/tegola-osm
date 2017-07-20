'use strict'

var config = {
  mapboxAccessToken: 'pk.eyJ1IjoiamowaG5zMG4iLCJhIjoiY2o1YjRtMjZpMGd2MDJ3bW00bnA5NXdyMiJ9.qlR4a_qfTlKZs1Qisk6sAg',
  startingCenter: [-117.15117725013909, 32.72269876352742],
  startingZoom: 15
};

var map, currentLib, currentStyle;

//  TODO: init this later?
var openLayersSatellite = new ol.layer.Tile({
  title: 'DigitalGlobe Maps API: Recent Imagery',
  source: new ol.source.XYZ({
    url: 'http://api.tiles.mapbox.com/v4/digitalglobe.nal0g75k/{z}/{x}/{y}.png?access_token='+config.mapboxAccessToken,
    attribution: "© DigitalGlobe, Inc"
  })
});

var openlayers = {
  init: function() {
    //  TODO: use the switchStyle method?
    map = olms.apply('map', 'styles/'+currentStyle+'.json');
    map.getView().setCenter(ol.proj.fromLonLat(config.startingCenter));
    map.getView().setZoom(config.startingZoom);
  },
  switchStyle: function(style) {
    map.getLayers().getArray().forEach(function(layer) {
      map.removeLayer(layer);
    });
    map = olms.apply(map, 'styles/'+style+'.json');
    //  TODO: move this to a gloabl config that maps the style names with style.json files and satellite basemaps if necessary.
    //  bonus: build the style buttons from the config on app init
    if(style === 'night-vision3d') {
      map.addLayer(openLayersSatellite);
    }
  }
}

//  TODO: move to the mapbox.init() method?
mapboxgl.accessToken = config.mapboxAccessToken;
var mapbox = {
  init: function() {
    map = new mapboxgl.Map({
      container: 'map', // container id
      style: '/styles/'+currentStyle+'3d.json',
      center: config.startingCenter, 
      zoom: config.startingZoom,
      hash: true 
    });
    map.addControl(new mapboxgl.NavigationControl());
  },
  switchStyle: function(style) {
    map.setStyle('/styles/'+style+'3d.json');
    //  TODO: move this to a gloabl config that maps the style names with style.json files and satellite basemaps if necessary.
    if(style === 'night-vision3d') {
    }
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
currentLib = mapbox;
currentStyle = 'mapbox';
//  TODO: it appears you're using an "interface" strategy, so wouldn't it be appropriate to call currentLib.init()?
mapbox.init();
