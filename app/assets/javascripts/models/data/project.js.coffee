#= require models/data/datasets
#= require models/data/dataset

ns = @edsc.models.data

ns.Project = do (ko,
                 QueryModel = ns.Query,
                 DatasetsModel = ns.Datasets
                 Dataset = ns.Dataset) ->

  class Project
    constructor: (@query) ->
      @_datasetIds = ko.observableArray()
      @_datasetsById = {}

      @id = ko.observable(null)
      @datasets = ko.computed(read: @getDatasets, write: @setDatasets, owner: this)
      @searchGranulesDataset = ko.observable(null)
      @allReadyToDownload = ko.computed(@_computeAllReadyToDownload, this, deferEvaluation: true)

    _computeAllReadyToDownload: ->
      result = true
      for ds in @datasets()
        result = false if !ds.serviceOptions.readyToDownload()
      result

    getDatasets: ->
      @_datasetsById[id] for id in @_datasetIds()

    setDatasets: (datasets) ->
      datasetIds = []
      datasetsById = {}
      for ds in datasets
        id = ds.id()
        ds.reference()
        datasetIds.push(id)
        datasetsById[id] = ds
      @_datasetsById = datasetsById
      @_datasetIds(datasetIds)
      null

    isEmpty: () ->
      @_datasetIds.isEmpty()

    addDataset: (dataset) =>
      id = dataset.id()

      dataset.reference()
      @_datasetsById[id] = dataset
      @_datasetIds.remove(id)
      @_datasetIds.push(id)

      # Force results to start being calculated
      dataset.granulesModel.results()

      null

    removeDataset: (dataset) =>
      id = dataset.id()
      @_datasetsById[id]?.dispose()
      delete @_datasetsById[id]
      @_datasetIds.remove(id)
      null

    hasDataset: (other) =>
      @_datasetIds.indexOf(other.id()) != -1

    isSearchingGranules: (dataset) =>
      @searchGranulesDataset() == dataset

    searchGranules: (dataset) =>
      @searchGranulesDataset(dataset)

    clearSearchGranules: =>
      @searchGranulesDataset(null)

    fromJson: (jsonObj) ->
      query = @query

      query.fromJson(jsonObj.datasetQuery)

      @datasets(Dataset.findOrCreate(dataset, query) for dataset in jsonObj.datasets)

      new DatasetsModel(@query).search {echo_collection_id: @_datasetIds()}, (results) =>
        for result in results
          dataset = @_datasetsById[result.id()]
          if dataset?
            dataset.fromJson(result.json)

    serialize: (datasets=@datasets) ->
      datasetQuery: @query.serialize()
      datasets: (ds.serialize() for ds in datasets)

  exports = Project