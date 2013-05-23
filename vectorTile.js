

L.Util.ajax = function (url,options, cb) {
    var cbName,ourl,cbSuffix,scriptNode, head, cbParam, XMHreq;
	if(typeof options === "function"){
		cb = options;
		options = {};
	}
	if(options.jsonp){
		head = document.getElementsByTagName('head')[0];
		cbParam = options.cbParam || "callback";
		if(options.callbackName){
			cbName= options.callbackName;
		}else{
			cbSuffix = "_" + ("" + Math.random()).slice(2);
			cbName = "L.Util.ajax.cb." + cbSuffix;
		}
		scriptNode = L.DomUtil.create('script', '', head);
		scriptNode.type = 'text/javascript';
		if(cbSuffix) {
			L.Util.ajax.cb[cbSuffix] = function(data){
				head.removeChild(scriptNode);
				delete L.Util.ajax.cb[cbSuffix]
				cb(data);
			};
		}
		if (url.indexOf("?") === -1 ){
			ourl =  url+"?"+cbParam+"="+cbName;
		}else{
			ourl =  url+"&"+cbParam+"="+cbName;
		}
		scriptNode.src = ourl;
		return {
            abort:function(){
    		    L.Util.ajax.cb[cbSuffix]=function(){
                    head.removeChild(scriptNode);
    			    delete L.Util.ajax.cb[cbSuffix];
                    return true;
                };
		    }
		};
	}else if (L.Util.ajax.workers){	
		return L.Util.ajax.workers.data(url).then(cb);
	}else{
		
		// the following is from JavaScript: The Definitive Guide
		if (window.XMLHttpRequest === undefined) {
			XMHreq = function() {
				try {
					return new ActiveXObject("Microsoft.XMLHTTP.6.0");
				}
				catch  (e1) {
					try {
						return new ActiveXObject("Microsoft.XMLHTTP.3.0");
					}
					catch (e2) {
						throw new Error("XMLHttpRequest is not supported");
					}
				}
			};
		}else{
			XMHreq = window.XMLHttpRequest
		}
		var response, request = new XMHreq();
		try{
		request.open("GET", url);
		}catch(e){
			if(typeof XDomainRequest != "undefined") {
				request=new XDomainRequest();
				request.open("GET", url);
			}else{
				options.jsonp=true;
				return L.Util.ajax(url,options, cb);
			}
		}
		request.onreadystatechange = function() {
			if (request.readyState === 4 && request.status === 200) {
				if(window.JSON) {
					response = JSON.parse(request.responseText);
				} else {
					response = eval("("+ request.responseText + ")");
				}
				cb(response);
			}
		};
		request.send();	
		return request;
	
	}
};
L.Util.ajax.Workers=function(num){
 if(typeof Worker === "function" && !("workers" in L.Util.ajax)){
 	
			L.Util.ajax.workers=communist({data:function (url, _cb) {
			var request = new XMLHttpRequest();
			request.open("GET", url);
				request.onreadystatechange = function() {
				var _resp;
				if (request.readyState === 4 && request.status === 200) {
					_resp = JSON.parse(request.responseText);
					if(typeof _resp!=="undefined"){_cb(_resp);}
					}
			};
			request.onerror=function(e){throw(e);};
		request.send();
	}},num);
	
}}
L.Util.ajax.cb = {};
L.TileLayer.GeoJSON = L.TileLayer.extend({
    _requests: [],
    _data: [],
    _geojson: {"type":"FeatureCollection","features":[]},
    initialize: function (url, options, geojsonOptions) {
        if(options.jsonp){
            this.jsonp=true;
        }
        options.unloadInvisibleTiles =true;
        L.TileLayer.prototype.initialize.call(this, url, options);
        this.geojsonLayer = L.featureGroup([], geojsonOptions);
        this.geojsonOptions = geojsonOptions;
    },
    bringToBack:function(){
    	this.back=true;
    	this.front=false;
    	return this.geojsonLayer.bringToBack();
    },
    bringToFront:function(){
    	this.front=true;
    	this.back=false;
    	return this.geojsonLayer.bringToFront();
    },
     onAdd: function (map) {
        this._map = map;
       L.Util.ajax.Workers(6);
        L.TileLayer.prototype.onAdd.call(this, map);
        map.addLayer(this.geojsonLayer);
    },
    onRemove: function (map) {
        map.removeLayer(this.geojsonLayer);
        L.TileLayer.prototype.onRemove.call(this, map);
        this.workers.close();
    },
    _addTile: function(tilePoint, container) {
        var tile = { datum: null, processed: false, id : tilePoint.x + ':' + tilePoint.y};
        this._tiles[tile.id] = tile;
        this._loadTile(tile, tilePoint);
    },
    // Load the requested tile via AJAX
    _loadTile: function (tile, tilePoint) {
        this._adjustTilePoint(tilePoint);
        
        tile._layer  = this;
        tile.onload  = this._tileOnLoad;
     	var _reqs = this._requests;
        var len = _reqs.length
        this._requests[len]=L.Util.ajax(this.getTileUrl(tilePoint),{jsonp:this.jsonp,workers:this.workers},function(data){
            tile.datum=data;
            tile.onload();
            _reqs[len]=false;
        });
    },    
    _update: function() {
        if (this._map._panTransition && this._map._panTransition._inProgress) { return; }
        if (this._tilesToLoad < 0) this._tilesToLoad = 0;
        
        L.TileLayer.prototype._update.apply(this, arguments);
    },
    _removeTile: function (id) {
    	if(id in this._tiles){
    		if(this._tiles[id]._jsonLayer&&this.geojsonLayer){
    			this.geojsonLayer.removeLayer(this._tiles[id]._jsonLayer);
    		}
        	delete this._tiles[id];
    	}

    },
    _tileOnLoad: function (e) {
    		this._jsonLayer = L.geoJson(this.datum,this._layer.geojsonOptions);
    		this._layer.geojsonLayer.addLayer(this._jsonLayer);
    		this._jsonLayer.bringToBack();
    		if(this._layer.front){
    			this._jsonLayer.bringToFront();
    		}else if(this._layer.back){
    			this._jsonLayer.bringToBack();
    		}
    		
    }
});
L.tileLayer.geoJson=function(a,b,c){
    return new L.TileLayer.GeoJSON(a,b,c);
}