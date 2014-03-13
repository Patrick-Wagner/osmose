#!/usr/bin/lua
--[[------------------------------------------------------

  # Cooking Mixing

  The model class stores the elements of the energy technology
  such as  *utility*, *stream* and *operational costs*.
  
  
  TODO: 
        

--]]------------------------------------------------------

local osmose = require 'osmose'
local lib = osmose.Model 'generic_utilities'

-- ## Inlet Parameters  (isVIT = 1)
lib.inputs = { }

-- ## Result (isVIT = 2)
lib.outputs = {  }



lib:addUnit("Boiler", {type = 'Utility'})
lib["Boiler"].Cost2 = 10
lib["Boiler"]:addStreams({
  boilingSteam = {120, 100, 119, 0,5}
  })

lib:addUnit("Cooling", {type = 'Utility'})
lib["Cooling"]:addStreams({
  coolingSteam = {3,0,30,100,3}
  })

return lib