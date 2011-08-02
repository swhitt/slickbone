#= require 'slickgrid/slick.editors'
exports = {} 

exports.Car = class Car extends SlickBone.Model
  initialize: ->
    @derivedField 'derivedField', (model) -> 
      "Title: #{model.get('title')}"

exports.Garage = class Garage extends SlickBone.Collection
  model: Car

data = []

for i in [0..50]
  data[i] =
    id: i
    title: "Task #{i}"
    duration: '5 days'
    percent: Math.round(Math.random() * 100)
    start: '01/01/2009'
    finish: '01/05/2009'
    effortDriven: (i % 5 == 0)

exports.myGarage = myGarage = new Garage
myGarage.reset(data)

columns = [
  { id: "title",          name: "Title",          width: 120, field: "title",           editor: TextCellEditor  }
  { id: "duration",       name: "Duration",       width: 55,  field: "duration"                                 }
  { id: "%",              name: "%",              width: 50,  field: "percent"                                  }
  { id: "start",          name: "Start",          width: 70,  field: "start"                                    }
  { id: "finish",         name: "Finish",         width: 70,  field: "finish"                                   }
  { id: "effort-driven",  name: "Effort Driven",  width: 75,  field: "effortDriven"                             }
  { id:  "random-title",  name: "Derived Field",  width: 140, field: "derivedField"                             }
]

options = 
  enableCellNavigation: true
  enableColumnReorder: false
  editable: true
  enableAddRow: true

jQuery(window).load ->
  exports.grid = grid = new Slick.Grid '#slickBoneGrid', [], columns, options
  myGarage.setGrid grid

_.extend (global ? window), { Demo: exports }
