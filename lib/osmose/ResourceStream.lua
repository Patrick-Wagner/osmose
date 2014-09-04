--[[---------------------------------------
  
  # Resource Stream
  
  Use this class to create Resource Stream for your ET Model.
--]]---------------------------------------


-- osmose.ResourceStream() work in combinaison with osmose.Layer().

-- Exemple : local power = rs({'electricity', 'out', 'p2', AddToProblem=1}) 

-- rs{} is a short cut for osmose.ResourceStream {}.
  
-- resource['flow'] and resource.fFlow_r are introduced in order to update the flowrate in each time step

-- @author: Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)

-- @copyright IPESE

-- @param: Presource stream

-- @release 0.1

-- @status _proposed


local lub = require 'lub'
local lib = lub.class 'osmose.ResourceStream'


lib.new = function(params)

  local resource= lub.class('ResourceStream')
  setmetatable(resource, lib)


resource.layerName   = params[1]
resource.inOut   = params[2]
resource['flow'] = params[3]
resource['AddToProblem'] = params[4] or 1

resource.fFlow_r   = resource:initFlow(model,'flow')
resource.fAddToProblem   = resource:initFlow(model,'AddToProblem')

  return resource
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