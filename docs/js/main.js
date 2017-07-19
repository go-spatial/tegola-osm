var map, currentLib, currentStyle;
var openLayersSatellite = new ol.layer.Tile({
            title: 'DigitalGlobe Maps API: Recent Imagery',
            source: new ol.source.XYZ({
                                url: 'http://api.tiles.mapbox.com/v4/digitalglobe.nal0g75k/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiZGlnaXRhbGdsb2JlIiwiYSI6ImNqNWIyMHkxdzBmNGczNG55bGNhc2tlcncifQ.lQXsl-GCFgJWmIKEeaRpPg',
            attribution: "© DigitalGlobe, Inc"
                            })})
var openlayers = {
  init: function() {
    map = olms.apply('map', '/styles/'+currentStyle+'.json');
    map.getView().setCenter(ol.proj.fromLonLat([-117.15117725013909, 32.72269876352742]));
    map.getView().setZoom(15);
  },
  switchStyle: function(style) {
    map.getLayers().getArray().forEach(function(layer) {
      map.removeLayer(layer);
    });
    map = olms.apply(map, '/styles/'+style+'.json');
    if(style === 'night-vision3d') {
      map.addLayer(openLayersSatellite);
    }
  }
}
mapboxgl.accessToken = 'pk.eyJ1IjoiamowaG5zMG4iLCJhIjoiY2o1YjRtMjZpMGd2MDJ3bW00bnA5NXdyMiJ9.qlR4a_qfTlKZs1Qisk6sAg';
var mapbox = {
  init: function() {
    map = new mapboxgl.Map({
      container: 'map', // container id
      style: '/styles/'+currentStyle+'.json',
      center: [-117.15117725013909, 32.72269876352742], 
      zoom: 15,
      hash: true 
    });
    map.addControl(new mapboxgl.NavigationControl());
  },
  switchStyle: function(style) {
    map.setStyle('/styles/'+style+'3d.json');
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
mapbox.init();
