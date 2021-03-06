local lut = require 'lut'

lut.Doc.make {
  sources = {
    'lib/osmose.lua',
    'lib/osmose/Model.lua',
    'lib/osmose/Eiampl.lua',
    'lib/osmose/Glpk.lua', 
    'lib/osmose/Graph.lua',
    'lib/osmose/Project.lua',
    'lib/osmose/HTStream.lua',
    'lib/osmose/QTStream.lua',
    'lib/osmose/Unit.lua',
    'lib/osmose/MassStream.lua',
    'lib/osmose/ResourceStream.lua',
    'lib/osmose/Layer.lua',
    'lib/osmose/ObjectiveFunction.lua',
    'lib/osmose/PostPrint.lua',
    'lib/osmose/Vali.lua'
  },
  target = 'docs',
  format = 'html',
  header = [[  <h1>Osmose documentation</h1> ]]
}

