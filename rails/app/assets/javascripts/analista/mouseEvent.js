// Adicionando Interacao com mouse	
	// Hover do mouse
	function highlightFeature(e) {
	    var layer = e.target;

	    layer.setStyle({
	        weight: 5,
	        color: '#666',
	        dashArray: '',
	        fillOpacity: 0.7
	    });

	    if (!L.Browser.ie && !L.Browser.opera && !L.Browser.edge) {
	        layer.bringToFront();
	    }
	    info.update(layer.feature.properties);
	}
	// MouseOut
	function resetHighlight(e) {
    	geojson.resetStyle(e.target);
    	 info.update();
	}
