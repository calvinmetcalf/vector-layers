window.m = L.map('map')

unless location.hash
	m.setView([42.3453,-71.0647],16)

m.addHash()
parks = L.tileLayer.geoJson('http://{s}.tile.openstreetmap.us/vectiles-land-usages/{z}/{x}/{y}.json',{},
	onEachFeature: (f,l)->
		array = for key, value of f.properties
			"#{key}: #{value}"
		l.bindPopup(array.join('<br/>'))
	style:(f)->
		out=
			fillOpacity:1
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
			else out.fillColor = 'rgb(224,224,224)'
		out
)
window.water = L.tileLayer.geoJson('http://{s}.tile.openstreetmap.us/vectiles-water-areas/{z}/{x}/{y}.json',{},{style:
	fillColor: 'rgb(151,219,242)'
	fillOpacity:1
	stroke:false
	clickable:false
})
roads = L.tileLayer.geoJson('http://{s}.tile.openstreetmap.us/vectiles-highroad/{z}/{x}/{y}.json',{},
	onEachFeature: (f,l)->
		array = for key, value of f.properties
			"#{key}: #{value}"
		l.bindPopup(array.join('<br/>'))
	style:
		fillColor: 'rgb(255,255,255)'
		fillOpacity:1
		weight:2
		color:'rgb(240,240,240)'
)
roads.addTo(m)
water.addTo(m)
parks.addTo(m)

roads.bringToFront()
parks.bringToBack()

window.water=water
window.parks=parks
window.roads=roads