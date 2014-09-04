--[[---------------------------------------

  # Mass Stream

  Use this class to create Mass Stream into your ET Model.

  osmose.MassStream() work in combinaison with osmose.Layer().
  
  Exemple :

  local power = ms({'electricity', 'out', 'p2', AddToProblem=1}) 

  ms{} is a short cut for osmose.MassStream {}.
  
  mass['flow'] and mass.fFlow are introduced in order to update the flowrate in each time step
  
  Modified by Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)

--]]---------------------------------------
local lub = require 'lub'
local lib = lub.class 'osmose.MassStream'

lib.new = function(params)

  local mass= lub.class('MassStream')
  setmetatable(mass, lib)


mass.layerName   = params[1]
mass.inOut   = params[2]
mass['flow'] = params[3]
mass['AddToProblem'] = params[4] or 1

mass.fFlow   = mass:initFlow(model,'flow')
mass.fAddToProblem   = mass:initFlow(model,'AddToProblem')
--[[
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
  
  --local flow = params[3]
  --mass.fFlow=lib:initFlow(model, 'flow')
 --]] 
  return mass
end


function lib:initFlow(model, tag) 

  -- iniTag return a function that depend of the model.
  local fct = function(model)
    local value = 0
    if type(self[tag]) == 'string' then
      local res = model[self[tag]]
      if type(res) == 'function' then
        value = res()
      else
        value = res
      end
    elseif type(self[tag]) == 'number' then
      value = self[tag]
    else
      value = self[tag](model)
    end
    if type(value) == 'table' then
      value = value[1][1]
    end
    return value
  end

  return fct
end


return lib