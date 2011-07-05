$.extend true, window, 
  SlickBone: {}

class SlickBone.Collection extends Backbone.Collection
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
      
  _setGridData: ->
    @grid.setData @
    @grid.invalidate()
  
  getItem: (index) -> 
    model = @at(index)
    if model?
      attrs = model.toJSON()
      attrs.cid = model.cid
    attrs

class SlickBone.Model extends Backbone.Model
  constructor: ->
    @_associations = {}
    @_derivations  = []
    super
    @bind 'change', => @_deriveFields()
    

  _addAssociation: (name, model, type) ->
    @_associations[name] = { model: model, associationType: type }

  hasMany:   (name, model) -> @_addAssociation(name, model, 'hasMany')
  hasOne:    (name, model) -> @_addAssociation(name, model, 'hasOne')
    
  derivedField: (fieldName, derivationFunction) ->
    @_derivations.push
      field: fieldName
      func:  derivationFunction

  prependDerivedField: (fieldName, derivationFunction) ->
    @_derivations.unshift
      field: fieldName
      func: derivationFunction
  
  _deriveFields: ->  
    for derivation in @_derivations
      result = {}
      result[derivation.field] = derivation.func(@)
      @set(result, silent: true)

  toJSON: ->
    result = super
    for attribute, value of result when _.include(_.keys(@_associations), attribute)
      result[attribute] = value.toJSON?()
    result

  set: (attrs, options) ->
    for attribute, value of attrs
      if _.include(_.keys(@_associations), attribute)
        associationDef = @_associations[attribute]
        attrs[attribute] = switch associationDef.associationType
          when 'hasOne' then (new associationDef.model(value))
          when 'hasMany' then (new associationDef.model).reset(value)
    super

