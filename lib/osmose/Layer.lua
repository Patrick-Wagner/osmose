--[[

  # Layer

  Use this class to create layers in your ET model.

  Exemple :

    lib:addLayers {electricity = {type='MassBalance', unit='kW'}}

    local osmose = require 'osmose'
    local lib = osmose.Model 'ET'
--]]

local lub   = require 'lub'
local lib   = lub.class 'osmose.Layer'

--[[
  Class function to create Layer.

  Use addLayers() methode from osmose.Model() class to create layer 
  in your ET model.
--]]
function lib.new(name, args)
  if not args.type then
    print('Layer should have a type:',name)
    os.exit()
  end

  local layer = lub.class(args.type)
  setmetatable(layer, lib)

  layer.name = name
  layer.streams = {}
  for key, val in pairs(args) do
    layer[key]=val
  end
  return layer
end


return lib