--[[---------------------------------------

  # Cost Stream

-- Use this class to create Cost Stream (Cost1/2, Power1/2, Cinv1/2, Impact1/2) into your ET Model.
 
-- osmose.CostStream() work in combinaison with osmose.Layer().

-- @author: Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)

-- @copyright IPESE

-- @param: Project.objective

-- @release 0.1

-- @return: the cost streams of each unit considering;
  
    unit.Cost1 
    unit.Cost2 
    unit.Cinv1 
    unit.Cinv2 
    unit.Power1 
    unit.Power2 
    unit.Impact1
    unit.Impact2 

-- @status _proposed
--]]---------------------------------------
local lub = require 'lub'
local lib = lub.class 'osmose.CostStream'

lib.new = function(model, layerName,unit)

  local cost= lub.class('CostStream')
  setmetatable(cost, lib)

  local tag1
  local tag2
  
  local val1
  local val2
  
  if layerName=='DefaultImpact' then
    tag1=unit.Impact1 or 0
    tag2=unit.Impact2 or 0
  elseif layerName=='DefaultMechPower' then
    tag1=unit.Power1 or 0
    tag2=unit.Power2 or 0
  elseif layerName=='DefaultInvCost' then
    tag1=unit.Cinv1 or 0
    tag2=unit.Cinv2 or 0
  else
    tag1=unit.Cost1 or 0
    tag2=unit.Cost2 or 0
  end
  
    
    if type(tag1) == 'number' then
      val1=tag1
    else
      val1=model[tag1]
    end
    if type(val1) == 'table' then
      val1 = val1[1][1]
    elseif type(val1) == 'function' then
      val1=val1()
    end
    
    
    if type(tag2) == 'number' then
      val2 = tag2
    else
      val2 = model[tag2]
    end
    if type(val2) == 'table' then
      val2 = val2[1][1]
    elseif type(val2) == 'function' then
      val2=val2()
    end
    
    
    cost.fcoefficient1=val1
    cost.fcoefficient2=val2
    --cost.fcoefficient1=cost:initCostcoefficient(model, tag1)
    --cost.fcoefficient2=cost:initCostcoefficient(model, tag2)
    
  return cost
end

function lib:initCostcoefficient(model, tag) 

  local fctmass = function(model)
    local value = 0
    if type(tag) == 'number' then
      value = tag
    else
      value = model[tag]
    end
    if type(value) == 'table' then
      value = value[1][1]
    elseif type(value) == 'function' then
      value=value()
    end
    return value 
  end

  return fctmass
end

return lib