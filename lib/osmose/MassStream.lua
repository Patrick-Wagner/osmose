--[[---------------------------------------

  # Mass Stream

  Use this class to create Mass Stream into your ET Model.

  osmose.MassStream() work in combinaison with osmose.Layer().

--]]---------------------------------------
local lub = require 'lub'
local lib = lub.class 'osmose.MassStream'


--[[
  Class method to create Mass Stream.

  Exemple :

    local power = ms({'electricity', 'out', 'p2'}) 

  ms{} is a short cut for osmose.MassStream {}.

--]]
lib.new = function(params)

  local mass= lub.class('MassStream')
  setmetatable(mass, lib)

  mass.layerName = params[1]
  mass.inOut = params[2]
  mass.getValue = function(model)
    local val = params[3]
    if type(val) == 'number' then
      return val
    else
      return model[val]
    end
  end

  return mass
end

return lib