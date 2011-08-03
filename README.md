SlickBone
=========

SlickBone is an attempt to marry [Backbone.js][backbone]'s Collections with [SlickGrid][slick]. The main implementation is done in [CoffeeScript][coffee].

Demo
----
There is a [Rails][rails] application included in this repository that demonstrates SlickBone's functionality. To get it running:

  1. Run `bundle install` to install its dependencies.
  2. Run `rails s` to start the demo application.
  3. Access the demo application from your web browser at [http://localhost:3000][demo].

SlickBone.Collection
--------------------
`SlickBone.Collection` is the main component of SlickBone. It implements the API used by the `DataView` example in the [SlickGrid][slick] repository for [Backbone.js][backbone] collections. In order to keep the Collection in-synch with the grid at all times, it subscribes to several events emitted by the SlickGrid grid. It also subscribes the grid to events emitted by the Collection.

Here's an example SlickBone.Collection that adds an additional comparator definition that can be used in a SlickGrid column definition: 

```coffeescript
class Garage extends SlickBone.Collection
  model: Car
  initialize: ->
    @comparatorDefinitions.random = (collection, field, sortAsc) ->
      (model) -> 
        val = model.get('description').length
        if sortAsc then val else -val
```

And here is the corresponding column definition that allows sorting of the `description` column using this new comparator by setting the `sortType` option:

```coffeescript
myGarage = new Garage
myGarage.reset(preloadData)

columns = [
  { id: "description", name: "Description", width: 100, field: "description", sortable: true, sortType: 'random' }
]

grid = new Slick.Grid '#slickBoneGrid', [], columns, 
  enableCellNavigation: true
  enableColumnReorder: false
  editable: true
  enableAddRow: true

myGarage.setGrid grid
```

### SlickBone.Collection#setGrid
`setGrid()` sets up all of the event publishing/subscribing with the corresponding SlickGrid. 

SlickBone.Model
---------------
```coffeescript
class Parts extends Backbone.Model

class PartList extends Backbone.Collection
  model: Parts

class Car extends SlickBone.Model
  setupDerivations: ->
    @derivedField 'title_length', (model) -> "Length: #{model.get('title').length}"
  setupConverters: ->
    @addConverter 'start_date', (field) -> new Date(field)
  setupAssociations: ->
    @hasMany('parts', PartList)
```

[backbone]: http://documentcloud.github.com/backbone/
[slick]: https://github.com/mleibman/SlickGrid
[coffee]: http://jashkenas.github.com/coffee-script/
[rails]: http://rubyonrails.org/
[demo]: http://localhost:3000
