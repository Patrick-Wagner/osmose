--[[---------------------------------------

  # QTStream

  Use this class to create HT Stream in your ET model.

  There is 2 ways to initialize QT streams. 
  1) With named parameters : tin, hin, tout, hout, dtmin and alpha.

    osmose.QTStream  { 
      -- temperature in
      tin = 'source_temp',
      -- enthalpy in
      hin = 0,
      -- temperature out
      tout = 'tank_temp',
      -- enthalpy out
      hout = 'fresh_water_load',
      -- delta t min
      dtmin = 3,
      -- alpha
      alpha = 'water_h',
    }
    
  2) With ordered parameters :
    
    osmose.QTStream { source_temp', 0, 'tank_temp','fresh_water_load',3,'water_h' }

  You can use qt{} as synonyme of osmose.QTStream {}.

  QTStream is a special case of HTStream.

--]]---------------------------------------


local lub = require 'lub'
local lib = lub.class 'osmose.QTStream'

-- The private functions are stored here.
local private={}

-- This is the valid params of QTStream initialization.
local validParamTable = {'tin', 'hin','tout','hout','dtmin','alpha'}

-- Class function that create QTStream.
lib.new = function(params)

  -- self in the QTStream instance.
  local stream= lub.class('QTStream')
  setmetatable(stream, lib)

  if params then
    for k,v in pairs(params) do
      if private.validParam(k) then
        stream[k] = v
      else
        stream[validParamTable[k]] = v
      end
    end
  end

  stream.ftin   = stream:initTag(model,'tin','T')

  stream.ftout  = stream:initTag(model,'tout','T')

  stream.fhin   = stream:initTag(model,'hin')

  stream.fhout  = stream:initTag(model,'hout')

  stream.fdtmin = stream:initTag(model,'dtmin')

  stream.falpha = stream:initTag(model,'alpha')

  stream.addToProblem = 1

  return stream
end



-- Private function to define a stream value (tin, tout, hin, hout).
function lib:initTag(model, tag, temp) 
  -- If the tag is a Temperature (temp=='T') then we add 273 automatically, 0 otherwise.
  local delta = 0
  if temp=='T' then
    delta = 273
  end

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
    if type(value) == 'table' and value.type ~= 'PhysicalUnit'  then
      value = value[1][1]
    end
    if type(value) == 'table' and value.type == 'PhysicalUnit'  then
      value = value()
    end
    return value + delta
  end

  return fct
end

private.validParam = function(element)
  for _, value in pairs(validParamTable) do
    if value == element then
      return true
    end
  end
  return false
end

return lib

