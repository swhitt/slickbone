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
    @_setGridData()
    
    @grid.onCellChange.subscribe (event, args) =>
      modelToUpdate = if args.item.id? then @get(args.item.id) else @getByCid(args.item.cid)
      modelToUpdate.set(args.item)
    
    @grid.onAddNewRow.subscribe (event, args) => @add(args.item)

    @bind 'add', (model)  => 
      @grid.updateRowCount()
      @grid.invalidateRow(@length - 1)
      @grid.render()

    @bind 'change', (model) =>
      @grid.invalidateRow @indexOf(model)
      @grid.render()
    
    @bind 'remove', (model) => 
      @grid.updateRowCount()
      @grid.render()
      
    @bind 'reset', (model) => @_setGridData()
  
  # replace the grid's data with us.
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
    
    @setupAssociations()
    @setupConverters()
    @setupDerivations()
    
    # we NEED this so that Backbone.js is happy.
    super
    
    # we want the derivations functionality to load after the call to `super` so 
    # that the Backbone.js model is all set up.
    @bind 'change', => @_executeDerivations()

  setupAssociations:  ->
  setupConverters:    ->
  setupDerivations:   ->

  # Helper method used by the association definition methods. Actually modifies the
  # assocation definition hash.
  _addAssociation: (name, model, type) ->
    @associations[name] = { model: model, associationType: type }
  
  # indicates that a given attribute is actually a Collection. Adds the correct settings to
  # the association hash.
  hasMany:   (name, collection) -> @_addAssociation(name, collection, 'hasMany')

  # indicates that a given attribute is actually a Model. Adds the correct settings to
  # the association hash.
  hasOne:    (name, model)      -> @_addAssociation(name, model, 'hasOne')
  
  # Actually calculate and set the derived fields in the prescribed order as
  # specified by the derivation chain.
  _executeDerivations: ->  
    for derivation in @derivations
      result = {}
      result[derivation.field] = derivation.func(@)
      @set(result, silent: true)
  
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
    for attribute, value of attrs
      if association = @associations[attribute]
        attrs[attribute] = switch association.associationType
          when 'hasOne' then (new association.model(value))
          when 'hasMany' then (new association.model).reset(value)
      if converter = @converters[attribute]
        if _.isFunction(converter)
          attrs[attribute] = converter(value)
        else
          throw "The conversion function for #{attribute} is invalid; it must be a function."
    super

  # Override the default Backbone.js `toJSON` method to handle associations.
  toJSON: ->
    result = super
    for attribute, value of result when _.include(_.keys(@associations), attribute)
      result[attribute] = value.toJSON?()
    result
