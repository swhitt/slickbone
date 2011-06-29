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
      
    @bind 'refresh', (model) => @_setGridData()
      
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
  initialize: ->
    @bind 'change', => @deriveFields()
  
  @_setUpDerivations: ->
    @_derivations ||= []
    if @_derivations == @__super__.constructor._derivations
      @_derivations = _.clone(@__super__.constructor._derivations) 

  @derivedField: (fieldName, derivationFunction) ->
    @_setUpDerivations()
    @_derivations.push
      field: fieldName
      func:  derivationFunction

  @prependDerivedField: (fieldName, derivationFunction) ->
    @_setUpDerivations()
    @_derivations.unshift
      field: fieldName
      func: derivationFunction
  
  deriveFields: ->  
    for derivation in @constructor._derivations
      result = {}
      result[derivation.field] = derivation.func(@)
      @set(result, silent: true)
  