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
