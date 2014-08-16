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
local helper = require 'osmose.helpers.tagHelper'

-- The private functions are stored here.
local private={}

-- This is the valid params of QTStream initialization.
local validParamTable = {'tin', 'hin','tout','hout','dtmin','alpha'}


-- Class function that create QTStream.
lib.new = function(params)

  -- self in the QTStream instance.
  --local stream= lub.class('QTStream')
  local stream = {}
  setmetatable(stream, lib)
  stream.type = 'QTStream'

  if params then
    for k,v in pairs(params) do
      if private.validParam(k) then
        stream[k] = v
      else
        stream[validParamTable[k]] = v
      end
    end
  end

  stream.ftin   = helper.initTag(stream,'tin','T')

  stream.ftout  = helper.initTag(stream,'tout','T')

  stream.ftinNoCorr   = helper.initTag(stream,'tin','T')

  stream.ftoutNoCorr  = helper.initTag(stream,'tout','T')

  stream.ftinCorr = helper.initTag(stream,'tin','Tcorr')

  stream.ftoutCorr  = helper.initTag(stream,'tout','Tcorr')

  stream.fhin   = helper.initTag(stream,'hin')

  stream.fhout  = helper.initTag(stream,'hout')

  stream.fdtmin = helper.initTag(stream,'dtmin')

  stream.falpha = helper.initTag(stream,'alpha')

  stream.addToProblem = 1

  return stream
end

function lib:freeze(model)
  local freeze = {}
  freeze.frozene = true
  freeze.type = self.type
  freeze.tin = self.ftin(model)
  freeze.tout = self.ftout(model)
  freeze.hin = self.fhin(model)
  freeze.hout = self.fhout(model)
  freeze.dtmin = self.fdtmin(model)
  freeze.alpha = self.falpha(model)
  freeze.load = self.load
  return freeze
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

