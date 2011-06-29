#= require 'slickgrid/slick.editors'
exports = {}

exports.Car    = class Car extends Backbone.Model

exports.Garage = class Garage extends SlickBone.Collection
  model: Car

data = []
for i in [0..50]
  data[i] =
    id: i
    title: "Task #{i}"
    duration: '5 days'
    percentComplete: Math.round(Math.random() * 100)
    start: '01/01/2009'
    finish: '01/05/2009'
    effortDriven: (i % 5 == 0)

exports.myGarage = myGarage = new Garage
myGarage.refresh(data)

columns = [
  {id:"title", name:"Title", field:"title", editor: TextCellEditor}
	{id:"duration", name:"Duration", field:"duration"}
	{id:"%", name:"% Complete", field:"percentComplete"}
	{id:"start", name:"Start", field:"start"}
	{id:"finish", name:"Finish", field:"finish"}
	{id:"effort-driven", name:"Effort Driven", field:"effortDriven"}
]

options = 
  enableCellNavigation: true
  enableColumnReorder: false
  editable: true
  enableAddRow: true

$ ->
  window.grid = grid = new Slick.Grid '#myGrid', [], columns, options
  myGarage.setGrid grid
  $('#myGrid').show()

_.extend (global ? window), exports
