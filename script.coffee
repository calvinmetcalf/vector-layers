class L.TileLayer.Ajax extends L.TileLayer
	_requests: []
	_data: []
	data: ->
		for t of @_tiles
			tile = @_tiles[t]
			unless tile.processed
				@_data = @_data.concat(tile.datum)
				tile.processed = true
		@_data

	_addTile: (tilePoint, container) ->
		tile =
			datum: null
			processed: false

		@_tiles[tilePoint.x + ":" + tilePoint.y] = tile
		@_loadTile tile, tilePoint

	
	# Load the requested tile via AJAX
	_loadTile: (tile, tilePoint) ->
		@_adjustTilePoint tilePoint
		layer = this
		head = document.getElementsByTagName('head')[0]
		cbParam = "callback"
		cbSuffix = "_" + ("" + Math.random()).slice(2)
		cbName = "L.TileLayer.Ajax.cb." + cbSuffix
		scriptNode = L.DomUtil.create('script', '', head)
		scriptNode.type = 'text/javascript'
		L.TileLayer.Ajax.cb[cbSuffix] = (data)=>
			head.removeChild(scriptNode)
			delete L.TileLayer.Ajax.cb[cbSuffix]
			tile.datum=data
			layer._tileLoaded()
		url = @getTileUrl(tilePoint)
		if url.indexOf("?") == -1 
			ourl =  url+"?"+cbParam+"="+cbName;
		else
			ourl =  url+"&"+cbParam+"="+cbName;
		
		scriptNode.src = ourl;
		@_requests.push  {abort:()=> 
			L.TileLayer.Ajax.cb[cbSuffix]=()->
				head.removeChild(scriptNode)
				delete L.TileLayer.Ajax.cb[cbSuffix]
				false
		}

	_resetCallback: (params...)->
		@_data = []
		super(params...)
		for i of @_requests
			@_requests[i].abort()
		@_requests = []

	_update: (params...)->
		return	if @_map._panTransition and @_map._panTransition._inProgress
		@_tilesToLoad = 0	if @_tilesToLoad < 0
		super params...
L.TileLayer.Ajax.cb={}
class L.TileLayer.GeoJSON extends L.TileLayer.Ajax
	_geojson:
		type: "FeatureCollection"
		features: []

	initialize: (url, options, geojsonOptions) ->
		super url, options
		@geojsonLayer = new L.GeoJSON(@_geojson, geojsonOptions)
		@geojsonOptions = geojsonOptions

	onAdd: (map) ->
		@_map = map
		super map
		@on "load", @_tilesLoaded
		map.addLayer @geojsonLayer

	onRemove: (map) ->
		map.removeLayer @geojsonLayer
		@off "load", @_tilesLoaded
		super map

	data: ->
		tileData = super()
		for t,tileDatum of tileData
			console.log tileDatum.features
			@geojsonLayer.addData(tileDatum)
		@geojsonLayer


	_resetCallback: (params...)->
		super params...

	_tilesLoaded: (evt) ->
		@data()
L.tileLayer.geoJson=(params...)->
	new L.TileLayer.GeoJSON(params...)

m = L.map('map').setView([42.3221,-71.0335], 12).addHash()

parks = L.tileLayer.geoJson('http://{s}.tile.openstreetmap.us/vectiles-land-usages/{z}/{x}/{y}.json',{},
	onEachFeature: (f,l)->
		array = for key, value of f.properties
			"#{key}: #{value}"
		l.bindPopup(array.join('<br/>'))
	style:(f)->
		out=
			fillOpacity:1,
			stroke:false
		switch f.properties.kind
			when 'park','common','grass' then out.fillColor = 'rgb(115,178,115)'
			when 'golf_course','recreation_ground','pitch','playground' then out.fillColor = 'rgb(110,183,110)'
			when 'conservation','farm','farmland' then out.fillColor = 'rgb(143,219,143)'
			when 'cemetery' then out.fillColor = 'rgb(78,120,78)'
			when 'university','college' then out.fillColor = 'rgb(77,50,230)'
			when 'school' then out.fillColor = 'rgb(125,106,235)'
			when 'forest' then out.fillColor = 'rgb(26,112,26)'
			when 'parking','industrial','fuel' then out.fillColor = 'rgb(0,0,0)'
			when 'commercial','retail','hospital' then out.fillColor = 'rgb(255,193,69)'
			when 'residential' then out.fillColor = 'rgb(212,47,58)'
			when 'railway','pedestrian','parking' then out.fillColor = 'rgb(204,204,204)'
			else out.fillColor = 'rgb(255,255,255)'
		out
).addTo(m)
water = L.tileLayer.geoJson('http://{s}.tile.openstreetmap.us/vectiles-water-areas/{z}/{x}/{y}.json',{},{style:
	fillColor: 'rgb(151,219,242)',
	fillOpacity:1,
	stroke:false,
	clickable:false
}).addTo(m)
water.bringToFront()