ns = @edsc.map.L

ns.GranuleLayer = do (L
                      $ = jQuery
                      GibsTileLayer = ns.GibsTileLayer
                      projectPath=ns.interpolation.projectPath
                      dateUtil = @edsc.util.date
                      dividePolygon = ns.sphericalPolygon.dividePolygon
                      capitalize = @edsc.util.string.capitalize
                      arrayUtil = @edsc.util.array
                      ) ->


  isClockwise = (path) ->
    sum = 0
    for [p0, p1] in arrayUtil.pairs(path)
      sum += (p1.x - p0.x) * (p1.y + p0.y)
    sum > 0

  addPath = (ctx, path, isCounterclockwise) ->
    {path, poly, line, point} = path

    if poly? || line?
      poly ?= line
      len = poly.length
      return if len < 2

      if isCounterclockwise != !isClockwise(poly)
        poly = poly.concat().reverse()

      ctx.moveTo(poly[0].x, poly[0].y)
      ctx.lineTo(p.x, p.y) for p in poly[1...]
    else if point?
      {x, y} = point
      ctx.moveTo(x + 10, y)
      ctx.arc(x, y, 10, 0, 2 * Math.PI, isCounterclockwise);
    null

  clipped = (ctx, boundary, maskedPaths, drawnPaths, fn) ->
    ctx.save()
    if maskedPaths.length > 0
      ctx.beginPath()
      addPath(ctx, boundary, false)
      for path in maskedPaths
        unless path.line?
          addPath(ctx, path, true)
          ctx.clip()

    if drawnPaths.length > 0
      ctx.beginPath()
      for path in drawnPaths
        addPath(ctx, path, true)
      ctx.clip()

    fn()
    ctx.restore()

    null

  # The first few methods are ported from L.TileLayer.Canvas, which is in our leaflet version but
  # seems to be removed from more recent versions.
  GranuleCanvasLayer = L.TileLayer.extend
    options:
      async: true

    setResults: (results) ->
      @_results = results
      @redraw()

    redraw: ->
      if @_map
        @_reset(hard: true)
        @_update()
        @_redrawTile(tile) for tile in @_tiles

      this

    _redrawTile: (tile) ->
      tilePoint = tile._tilePoint
      @drawTile(tile, @_getBackTile(tilePoint), tilePoint, @_map._zoom)

    _createTile: ->
      tile = L.DomUtil.create('canvas', 'leaflet-tile')
      tile.width = tile.height = @options.tileSize
      tile.onselectstart = tile.onmousemove = L.Util.falseFn
      tile

    _reset: (e) ->
      @_backTiles = {}
      tilesToLoad = @_tilesToLoad
      L.TileLayer.prototype._reset.call(this, e)
      @fire('load') if tilesToLoad > 0

    _getBackTile: (tilePoint) ->
      key = "#{tilePoint.x}:#{tilePoint.y}"
      @_backTiles ?= {}
      @_backTiles[key] ?= @_createTile()
      @_backTiles[key]

    _loadTile: (tile, tilePoint) ->
      tile._layer = this

      # This line isn't in the leaflet source, which is seemingly a bug
      @_adjustTilePoint(tilePoint)

      tile._tilePoint = tilePoint

      @_redrawTile(tile)

      @tileDrawn() unless @options.async

    _addIntersections: (result, paths, bounds, type, interpolation) ->
      return null unless paths?

      for path in paths
        shapeBounds = L.latLngBounds(path)
        if shapeBounds.intersects(bounds)
          intersection = {}
          intersection[type] = projectPath(@_map, path, [], interpolation, 2, 5).boundary
          result.push(intersection)
      null

    _granulePathsOverlappingTile: (granule, tileBounds) ->
      result = []
      map = @_map
      intersects = @_intersects

      for polygon in granule.getPolygons() ? []
        interiors = dividePolygon(polygon[0]).interiors
        @_addIntersections(result, interiors, tileBounds, 'poly', 'geodetic')

      @_addIntersections(result, granule.getRectangles(), tileBounds, 'poly', 'geodetic')
      @_addIntersections(result, granule.getLines(), tileBounds, 'line', 'geodetic')

      for point in granule.getPoints() ? [] when tileBounds.contains(point)
        result.push({point: @_map.latLngToLayerPoint(point)})

      result

    _drawFootprint: (canvas, nwPoint, boundary, maskedPaths, drawnPaths) ->
      ctx = canvas.getContext('2d')
      ctx.save()

      # Faint stroke of whole path
      ctx.lineWidth = 1
      ctx.translate(-nwPoint.x, -nwPoint.y)
      ctx.strokeStyle = 'rgba(128, 128, 128, .2)'
      for path in drawnPaths
        addPath(ctx, path, true)
        ctx.stroke()

      # Bold stroke of unclipped portion of path, black + white
      clipped ctx, boundary, maskedPaths, [], ->
        for path in drawnPaths
          ctx.beginPath()
          addPath(ctx, path, true)
          ctx.lineWidth = 2
          ctx.strokeStyle = 'rgba(0, 0, 0, 1)'
          ctx.stroke()
          ctx.lineWidth = 1
          ctx.strokeStyle = 'rgba(255, 255, 255, 1)'
          ctx.stroke()
      ctx.restore()

    granuleAt: (p) ->
      origin = @_map.getPixelOrigin()
      tileSize = @_getTileSize()
      tilePoint = p.add(origin).divideBy(tileSize).floor()

      canvas = @_getBackTile(tilePoint)

      tilePixel = p.subtract(@_getTilePos(tilePoint))

      result = null
      ctx = canvas.getContext('2d')
      data = ctx.getImageData(tilePixel.x, tilePixel.y, 1, 1).data
      if data[3] != 0
        index = (data[0] << 16) + (data[1] << 8) + data[2]
        result = @_results?[index]

      result

    _drawBackTile: (canvas, index, nwPoint, boundary, maskedPaths, drawnPaths) ->
      ctx = canvas.getContext('2d')
      ctx.save()

      # http://www.w3.org/TR/2011/WD-2dcontext-20110405/#imagedata
      ctx.strokeStyle = ctx.fillStyle = '#' + (index + 0x1000000).toString(16).substr(-6)
      ctx.lineWidth = 4

      ctx.translate(-nwPoint.x, -nwPoint.y)
      clipped ctx, boundary, maskedPaths, [], ->
        for path in drawnPaths
          ctx.beginPath()
          addPath(ctx, path, true)
          if path.line?
            ctx.stroke()
          else
            ctx.fill()
      ctx.restore()


    getTileUrl: (tilePoint, date) ->
      L.TileLayer.prototype.getTileUrl.call(this, tilePoint) + "&time=#{date}" if @_url?

    _loadClippedImage: (canvas, tilePoint, date, nwPoint, boundary, maskedPaths, drawnPaths, retries=0) ->
      url = @getTileUrl(tilePoint, date)

      if url?
        image = new Image()
        image.onload = (e) =>
          ctx = canvas.getContext('2d')
          ctx.save()
          ctx.translate(-nwPoint.x, -nwPoint.y)
          clipped ctx, boundary, maskedPaths, drawnPaths, ->
            ctx.drawImage(image, nwPoint.x, nwPoint.y)

          ctx.restore()

          for path, i in drawnPaths
            masked = maskedPaths.concat(drawnPaths.slice(0, i))
            @_drawFootprint(canvas, nwPoint, boundary, masked, [path])

        image.onerror = (e) =>
          if retries == 0
            @_loadClippedImage(canvas, tilePoint, date, nwPoint, boundary, maskedPaths, drawnPaths, 1)
          else
            console.error("Failed to load tile after 2 tries: #{url}")

        image.src = url
      else
        for path, i in drawnPaths
          masked = maskedPaths.concat(drawnPaths.slice(0, i))
          @_drawFootprint(canvas, nwPoint, boundary, masked, [path])

    drawTile: (canvas, back, tilePoint) ->
      return unless @_results? && @_results.length > 0

      layerPointToLatLng = @_map.layerPointToLatLng.bind(@_map)
      tileSize = @options.tileSize
      nwPoint = @_getTilePos(tilePoint)
      nePoint = nwPoint.add([tileSize, 0])
      sePoint = nwPoint.add([tileSize, tileSize])
      swPoint = nwPoint.add([0, tileSize])
      boundary = {poly: [nwPoint, nePoint, sePoint, swPoint]}
      bounds = new L.latLngBounds(boundary.poly.map(layerPointToLatLng))
      bounds = bounds.pad(0.1)

      date = null
      drawnPaths = []
      maskedPaths = []

      for granule, i in @_results
        start = granule.time_start?.substring(0, 10)

        paths = @_granulePathsOverlappingTile(granule, bounds)

        if paths.length > 0
          @_drawBackTile(back, i, nwPoint, boundary, maskedPaths.concat(drawnPaths), paths)

        # Note: GIBS is currently ambiguous about which day to use
        if start != date
          if drawnPaths.length > 0
            @_loadClippedImage(canvas, tilePoint, date, nwPoint, boundary, maskedPaths, drawnPaths)

          maskedPaths = maskedPaths.concat(drawnPaths)
          drawnPaths = paths
          date = start
        else
          drawnPaths = drawnPaths.concat(paths)

      if drawnPaths.length > 0
        @_loadClippedImage(canvas, tilePoint, date, nwPoint, boundary, maskedPaths, drawnPaths)

        maskedPaths = maskedPaths.concat(drawnPaths)


      console.log "#{maskedPaths.length} Overlapping Granules [(#{bounds.getNorth()}, #{bounds.getWest()}), (#{bounds.getSouth()}, #{bounds.getEast()})]"
      @tileDrawn(canvas)
      null

    tileDrawn: (tile) ->
      # If we do upgrade, this will break, as well as our tile reloading calls.
      # Tile loading seems to be handled via callbacks now.
      @_tileOnLoad.call(tile)

  class GranuleLayer extends GibsTileLayer
    constructor: (@dataset, options) ->
      @granules = @dataset.granulesModel
      @_hasGibs = options?.product?
      super(options)

    onAdd: (map) ->
      super(map)

      @_handle(map, 'on', 'edsc.focusdataset')
      @setFocus(map.focusedDataset?.id() == @dataset.id())

      @_resultsSubscription = @granules.results.subscribe(@_loadResults.bind(this))
      @_loadResults(@granules.results())

    onRemove: (map) ->
      super(map)

      @setFocus(false, map)
      @_handle(map, 'off', 'edsc.focusdataset')
      @_resultsSubscription.dispose()
      @_results = null

      if @_restoreBounds
        map.fitBounds(@_restoreBounds)
        @_restoreBounds = null

    url: ->
      super() if @_hasGibs

    setFocus: (focus, map=@_map) ->
      return if @_isFocused == focus
      @_isFocused = focus
      events = ['edsc.mousemove', 'edsc.mouseout', 'click', 'edsc.focusgranule', 'edsc.stickygranule']
      if focus
        @_handle(map, 'on', events...)
      else
        @_handle(map, 'off', events...)
        @_granuleFocusLayer?.onRemove(map)
        @_granuleFocusLayer = null
        @_granuleStickyLayer?.onRemove(map)
        @_granuleStickyLayer = null

    _handle: (obj, onOrOff, events...) ->
      for event in events
        method = '_on' + event.split('.').map(capitalize).join('')
        obj[onOrOff] event, this[method]

    _onEdscFocusdataset: (e) =>
      @setFocus(e.dataset?.id() == @dataset.id())

    _onEdscMouseout: (e) =>
      if @_granule?
        @_map.fire('edsc.focusgranule', granule: null)

    _onEdscMousemove: (e) =>
      granule = @layer?.granuleAt(e.layerPoint)
      if @_granule != granule
        @_map.fire('edsc.focusgranule', granule: granule)

    _onClick: (e) =>
      return unless $(e.originalEvent.target).closest('a').length == 0
      granule = @layer?.granuleAt(e.layerPoint)
      granule = null if @_stickied == granule
      @_map.fire('edsc.stickygranule', granule: granule)

    _onEdscFocusgranule: (e) =>
      @_granule = granule = e.granule

      @_granuleFocusLayer?.onRemove(@_map)
      @_granuleFocusLayer = @_focusLayer(granule, false)
      @_granuleFocusLayer?.onAdd(@_map)

    _onEdscStickygranule: (e) =>
      granule = e.granule
      return if @_stickied == granule

      @_stickied = granule

      @_granuleStickyLayer?.onRemove(@_map)
      @_granuleStickyLayer = null

      if !granule? && @_restoreBounds?
        @_map.fitBounds(@_restoreBounds)
        @_restoreBounds = null

      @_granuleStickyLayer = @_stickyLayer(granule, true)
      if @_granuleStickyLayer?
        @_granuleStickyLayer.onAdd(@_map)

        if @layer.options.endpoint == 'geo'
          @_restoreBounds ?= @_map.getBounds()
          bounds = @_granuleFocusLayer.getBounds()
          # Avoid zooming and panning tiny amounts
          unless @_map.getBounds().contains(bounds)
            @_map.fitBounds(bounds.pad(0.2))

      @_loadResults(@_results)

    _buildLayerWithOptions: (newOptions) ->
      @_restoreBounds = null
      # GranuleCanvasLayer needs to handle time
      newOptions = L.extend({}, newOptions)
      delete newOptions.time

      layer = new GranuleCanvasLayer(@url(), @_toTileLayerOptions(newOptions))

      # For tests to figure out if things are still loading
      map = @_map
      map.loadingLayers ?= 0
      layer.on 'loading', -> map.loadingLayers++
      layer.on 'load', -> map.loadingLayers--

      layer.setResults(@_results)
      layer

    _loadResults: (results) ->
      @_results = results

      if @_stickied?
        results = results.concat()
        index = results.indexOf(@_stickied)
        if index == -1
          @_stickied = null
          @_granuleStickyLayer?.onRemove(@_map)
          @_granuleStickyLayer = null
        else
          results.splice(index, 1)
          results.unshift(@_stickied)

      @layer?.setResults(results)

    _granuleLayer: (granule, options) ->
      layer = L.featureGroup()
      layer.addLayer(L.circleMarker(point, options)) for point in granule.getPoints() ? []
      layer.addLayer(L.sphericalPolygon(poly, options)) for poly in granule.getPolygons() ? []
      layer.addLayer(L.polyline(line, options)) for line in granule.getLines() ? []

      for rect in granule.getRectangles() ? []
        # granule.getRectanges() returns a path, so it's really a polygon
        shape = L.polygon(rect, options)
        shape._interpolationFn = 'cartesian'
        layer.addLayer(shape)
      layer

    _focusLayer: (granule) ->
      return null unless granule?

      @_granuleLayer(granule, clickable: false)


    _stickyLayer: (granule) ->
      return null unless granule?

      layer = @_granuleLayer(granule, fillOpacity: 0, clickable: false)

      temporal = granule.getTemporal()
      icon = L.divIcon
        className: 'granule-spatial-label',
        html: '<span class="granule-spatial-label-temporal">' + temporal +
              '</span><a class="panel-list-remove" href="#" title="remove"><i class="fa fa-times"></i></a>'

      marker = L.marker([0, 0], icon: icon)

      firstShape = layer.getLayers()[0]
      firstShape = firstShape._interiors if firstShape._interiors?

      firstShape?.on 'add', (e) ->
        map = @_map

        center = @getLatLng?()
        unless center?
          latlngs = @getLatLngs()
          latlngs = latlngs[0] if Array.isArray(latlngs[0])
          bounds = L.bounds(map.latLngToLayerPoint(latlng) for latlng in latlngs)
          center = map.layerPointToLatLng(bounds.getCenter())

        marker.setLatLng(center)
        layer.addLayer(marker)

      layer

  exports = GranuleLayer