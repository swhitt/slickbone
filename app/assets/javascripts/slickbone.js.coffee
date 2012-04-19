$.extend true, window, 
  SlickBone: {}

# SlickBone.Collection. A sub-class of Backbone.Collection that implements the
# basic interface required to be used as a backing-object for SlickGrid.
class SlickBone.Collection extends Backbone.Collection
  # The setGrid method is the meat of SlickBone. It sets the specified SlickGrid's data source
  # to the collection. It subscribes to several events coming from the Grid to ensure that
  # its subsituent models stay up-to-date. It also sets a few callbacks so that the grid will
  # be notified in case any of the models chagne. 
  # Do NOT call this method on a grid that already has another, established data source unless
  # you are CERTAIN you do not mind losing the other data. 
  setGrid: (@grid) ->
    # Set the grid's data property to the instance of SlickboneCollection, and then tell it to
    # invalidate itself.
    @_setGridData()
    
    # Listen for cell change events from the grid, update our models with new data
    @grid.onCellChange.subscribe (event, args) =>
      modelToUpdate = if args.item.id? then @get(args.item.id) else @getByCid(args.item.cid)
      modelToUpdate.set(args.item)
    
    # Create a new model instance if a row is added to the grid
    @grid.onAddNewRow.subscribe (event, args) => @add(args.item)
    
    # SlickGrid only sends a onSort message when the user clicks the column headers to sort
    # Listen for the event, change the Collection's comparator appropriately and re-sort.
    # The grid will pick up the changes because we raise a `reset` event after sort().
    @grid.onSort.subscribe (event, args) =>
      sortType = args.sortCol.sortType || 'string'
      @comparator = @comparatorDefinitions[sortType](@, args.sortCol.field, args.sortAsc)
      @sort()
    
    # Tell the grid when a model is added to SlickBone.Collection.
    @bind 'add', (model)  =>
      @grid.updateRowCount()
      @grid.invalidateRow(@length - 1)
      @grid.render()
    
    # Tell the grid when a model is changed in a SlickBone.Collection.
    @bind 'change', (model) =>
      @grid.invalidateRow @indexOf(model)
      @grid.render()
    
    # Tell the grid that a model has been removed from a SlickBone.Collection.
    @bind 'remove', (model) =>
      @grid.updateRowCount()
      @grid.render()
    
    # Reset the grid when the collection's contents are reset. 
    @bind 'reset', (model) => @_setGridData()
    
  # replace the grid's data with us and tell it to recalculate everything.
  _setGridData: ->
    @grid.setData @
    @grid.invalidate()
  
  # Return the JSON associated with a particular index in the collection.
  getItem: (index) ->
    model = @at(index)
    if model?
      attrs = model.toJSON()
      attrs.cid = model.cid
    attrs
  
  # You can modify this hash to define different comparator types.
  comparatorDefinitions:
    number: (collection, field, sortAsc) ->
      (model) ->
        val = Number(model.get(field))
        if sortAsc then val else -val
    string: (collection, field, sortAsc) ->
      (model) ->
        fieldValue = model.get(field)
        if sortAsc then fieldValue else -(collection.sortedIndex(model, (m) -> m.get(field)))

# SlickBone.Model is not necessary to use SlickBone; it is simply a collection of 
# useful-for-SlickGrid extensions to Backbone.Model.
# Among the improvements are pseud-assocations, derived fields and atrribute type-casting.
# The model also handles the Backbone.js toJSON method when there are associations defined.
class SlickBone.Model extends Backbone.Model
  constructor: ->
    # a new instance of the model has blank associations, converters and derivations
    @associations = {}
    @converters   = {}
    @derivations  = []
    
    # these convenience methods should be overridden in classes that inherit from SlickBone.Model
    @setupAssociations()
    @setupConverters()
    @setupDerivations()
    
    # we NEED this so that Backbone.js is happy.
    super
    
    # we want the derivations functionality to load after the call to `super` so 
    # that the Backbone.js model is all set up.
    # First, we execute them immediately
    @_executeDerivations()
    
    @_createEmptyCollections()
    
    # Then, we set them up to run whenever a model changes
    @bind 'change', => @_executeDerivations()
    
    @_slickboneInitialized = true
  
  # Stubs for associations, converters and derivations that can be overridden in implementing classes
  setupAssociations:  ->
  setupConverters:    ->
  setupDerivations:   ->
  
  # indicates that a given attribute is actually a Collection. Adds the correct settings to
  # the association hash.
  hasMany:   (name, collection) ->
    @associations[name] = { model: collection, associationType: 'hasMany' }
    
  # indicates that a given attribute is actually a Model. Adds the correct settings to
  # the association hash.
  hasOne:    (name, model)      ->
    @associations[name] = { model: model, associationType: 'hasOne' }
  
  # Actually calculate and set the derived fields in the prescribed order as
  # specified by the derivation chain.
  _executeDerivations: ->
    for derivation in @derivations
      result = {}
      result[derivation.field] = derivation.func(@)
      @set(result, silent: true)
  
  _createEmptyCollections: ->
    return if @_emptyCollectionsCreated
    for name, definition of @associations when definition.associationType == 'hasMany'
      @attributes[name] = (new definition.model).bind('all', @handleAssociatedCollectionEvent)
    @_emptyCollectionsCreated = true
  
  # Add a derived field to the end of the derivation chain.
  derivedField: (fieldName, derivationFunction) ->
    @derivations.push
      field: fieldName
      func:  derivationFunction
  
  # Add a derived field at the start of the derivation field. 
  prependDerivedField: (fieldName, derivationFunction) ->
    @derivations.unshift
      field: fieldName
      func: derivationFunction
  
  addConverter: (fieldName, conversionFunction) ->
    @converters[fieldName] = conversionFunction
  
  # Override the default Backbone.js set method to handle our added functionality.
  # Iterate through the attributes being set and:
  # * If the attribute name is one of the associations, set that as the attribute instead of
  #   the options hash passed in.
  # * If an attribute being set is subject to conversion, execute the type conversion.
  set: (attrs, options) ->
    if attrs.attributes then attrs = attrs.attributes
    @_createEmptyCollections() unless @_emptyCollectionsCreated
    for attribute, value of attrs
      if association = @associations[attribute]
        currentValue = @attributes[attribute]
        
        attrs[attribute] = switch association.associationType
          when 'hasOne'
            if currentValue
              currentValue.set(value)
            else
              (new association.model(value)).bind 'all', @handleAssociatedModelEvent
          when 'hasMany'
            @attributes[attribute].reset(value)
      if converter = @converters[attribute]
        if _.isFunction(converter)
          attrs[attribute] = converter(value)
        else
          throw "The conversion function for #{attribute} is invalid; it must be a function."
    super
  
  handleAssociatedModelEvent: =>
    alert('models')
  
  handleAssociatedCollectionEvent: (event, changedItem, options) =>
    switch event
      when 'change', 'add', 'remove', 'reset'
        @change(options)
  
  # Override the default Backbone.js `toJSON` method to handle associations.
  toJSON: ->
    result = super
    for attribute, value of result when _.include(_.keys(@associations), attribute)
      result[attribute] = value.toJSON?()
    result
