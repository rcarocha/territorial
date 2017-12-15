	// Zoom

	function zoomToFeature(e) {
    	map.fitBounds(e.target.getBounds());
	}

	function onEachFeature(feature, layer) {
	    layer.on({
	        mouseover: highlightFeature,
	        mouseout: resetHighlight,
	        click: zoomToFeature
	    });
	}

	geojson = L.geoJson(statesData, {
    	style: style,
    	onEachFeature: onEachFeature
	}).addTo(map);

