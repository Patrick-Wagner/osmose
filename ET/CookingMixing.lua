#!/usr/bin/lua
--[[------------------------------------------------------

  # Cooking Mixing

  The model class stores the elements of the energy technology
  such as  *utility*, *stream* and *operational costs*.
  
  
  TODO: ADD tank losses
        ADD Mass and energy balances with a checking tag (isvit=2)
        
        CHANGE Ambient temperature in global ??
        

--]]------------------------------------------------------

local osmose = require 'osmose'
local lib = osmose.Model 'CookingMixing'

-- ## Inlet Parameters  (isVIT = 1)
lib.inputs = { -- doc
  
  -- Average mass flow rate of the inlet first product.  
  prod_1_flow = {default = 1000, min=1000, max=1000, unit = 'kg/h'},

  -- Heat capacity of the inlet first product.  
  prod_1_cp = {default = 3.85, min = 3.85, max = 3.85, unit = 'kJ/kg C'},
  
  -- Temperature of the inlet first product.  
  prod_1_temp = {default = 5, min=5, max=5, unit = 'C'},
  
  -- Temperature of the first product before mixing.  
  prod_1_btemp = {default = 80, min=80, max=80, unit = 'C'},
  
  -- Average mass flow rate of the inlet second product.  
  prod_2_flow = {default = 2000, min=2000, max=2000, unit = 'kg/h'},
  
  -- Heat capacity of the inlet second product.   
  prod_2_cp = {default = 1.24, unit = 'kJ/kg C'},
  
  -- Temperature of the inlet second product.  
  prod_2_temp = {default = 7,  unit = 'C'},
  
  -- Temperature of the second product before mixing.  
  prod_2_btemp = {default = 80, min=60, max=90, unit = 'C'},
  
  -- Temperature of the final product.  
  prod_final_temp = {default = 60, unit = 'C'},

  --return_temp = {default = 80, min = 0, max = 1, unit = 'C'},

  hrin_1_dtmin = {default = 3, min = 0, max=10},

  hrin_2_dtmin = {default = 3, min = 0, max=10},

  hrout_dtmin = {default = 3, min = 0, max = 10},
}

-- ## Result (isVIT = 2)
lib.outputs = { -- doc
  
  -- Mass flow rate of the mixture (first product + second prod.).  
  -- [math] mixture_flow = prod_1_flow + prod_2_flow [/math]
  mixture_flow = {unit = 'kg/h', job =
    function()
      return prod_1_flow + prod_2_flow
    end},

  
  -- Heat capacity of the mixture.  
  -- [math]prod_final_cp = ((prod_1_flow * prod_1_cp) +(prod_2_flow * prod_2_cp)) / mixture_flow [/math]
  prod_final_cp = {unit = 'kJ/kg C', job = 
  function()
      return ((prod_1_flow * prod_1_cp) +(prod_2_flow * prod_2_cp))/ mixture_flow()
    end},
  
  
  -- Temperature of the mixture.  
  -- [[math]((prod_1_flow * prod_1_cp * prod_1_temp) + (prod_2_flow * prod_2_cp * prod_2_temp))]
  --((prod_1_flow * prod_1_cp * prod_1_temp) + (prod_2_flow * prod_2_cp * prod_2_temp))/ ((prod_1_flow * prod_1_cp)+(prod_2_flow * prod_2_cp))
  --[/math]
  prod_mix_temp = {unit = 'C', job =
  function()
      return ((prod_1_flow * prod_1_cp * prod_1_btemp) + (prod_2_flow * prod_2_cp * prod_2_btemp)) / ((prod_1_flow * prod_1_cp)+(prod_2_flow * prod_2_cp))
    end},
  
    
  -- Heat load required for the preheating/cooling of the inlet first product.  
  -- [math]  prod_1_load = (prod_1_flow /3600) * prod_1_cp * (prod_1_temp - prod_1_btemp) [/math]
 prod_1_load = {unit = 'kW', job =
  function()
      if prod_1_btemp > prod_1_temp then
        return (prod_1_flow /3600) * prod_1_cp * (prod_1_btemp - prod_1_temp)
      else
        return (prod_1_flow /3600) * prod_1_cp * (prod_1_temp - prod_1_btemp)
      end
    end},
  
  -- Heat load required for the preheating/cooling of the inlet second product.  
  -- [math]  prod_2_load = (prod_2_flow /3600) * prod_2_cp * (prod_2_temp - prod_2_btemp) [/math]
 prod_2_load = {unit = 'kW', job =
  function()
      if prod_2_btemp > prod_2_temp then 
        return (prod_2_flow /3600) * prod_2_cp * (prod_2_btemp - prod_2_temp)
      else
        return (prod_2_flow /3600) * prod_2_cp * (prod_2_temp - prod_2_btemp)
      end
    end},
  
  
  -- Heat load required for the preheating/cooling of the outlet mixture.  
  -- [math]  prod_final_load = (prod_final_flow /3600) * prod_final_cp * (prod_final_temp - prod_mix_temp) [/math]
 prod_final_load = {unit = 'kW', job=
  function()
      if prod_mix_temp() > prod_final_temp then
        return (mixture_flow() /3600) * prod_final_cp() * (prod_final_temp - prod_mix_temp())
      else
        return (mixture_flow() /3600) * prod_final_cp() * (prod_mix_temp() - prod_final_temp)
      end
    end},

  -- Tank heat losses, taking into account the thermal losses by convection and
  -- by radiation.  
  -- [math][/math]
  -- tank_losses = {default = 0, min = 0, max = 1, unit = 'kW'},
}

-- ## Advanced Parameters  (isVIT = 3)
lib.advanced = { -- doc
  
  -- Heat transfer coefficient of the inlet first product.  
  -- [math][/math]
  prod_1_h = {default = 1.136,  unit = 'kW/m2 C'},
  
  -- Heat transfer coefficient of the inlet second product.  
  -- [math][/math]
  prod_2_h  = {default = 1.136, unit = 'kW/m2 C'},
  
  -- Heat transfer coefficient of the mixture.  
  -- [math][/math]
  mixture_h = {default = 1.136, unit = 'kW/m2 C'},
   
  -- Ambient temperature.  
  -- [math][/math]
  --ambient_t = {default = 25, min = 0, max = 1, unit = 'C'},
  
  -- Natural convective heat transfer coefficient for ambient air.  
  -- [math][/math]
  --h_amb = {default = 0.02, min = 0, max = 1, unit = 'kW/m2 C'},
  
  -- Emissivity of the tank surface (epsilon) used to compute the heat losses.
  -- Select 0.6 - 0.7 for oxidized iron steel surface and 0.2 for iron steel
  -- with thin oxyde layer. If the surface is highly polished, select 0.05.  
  -- [math][/math]
  --epsilon = {default = 0.2, min = 0, max = 1, unit = '-'},

}


-- lib.processes = {
--   cmUnit = {
--     hrin_1 = {
--       -- temperature in
--       tin = function(self) return self.prod_1_temp + 273 end,
--       -- enthalpy in
--       hin = function() return 0 end,
--       -- temperature out
--       tout = function(self) return self.prod_1_btemp + 273 end,
--       -- enthalpy out
--       hout = function(self) return self.prod_1_load() end,
--       -- delta t min
--       dtmin = function(self) return self.hrin_1_dtmin end,
--       -- alpha
--       alpha = function(self) return self.prod_1_h end,
--     },
    
--     hrin_2 = {
--       -- temperature in
--       tin = function(self) return self.prod_2_temp + 273 end,
--       -- enthalpy in
--       hin = function() return 0 end,
--       -- temperature out
--       tout = function(self) return self.prod_2_btemp + 273 end,
--       -- enthalpy out
--       hout = function(self) return self.prod_2_load() end,
--       -- delta t min
--       dtmin = function(self) return self.hrin_2_dtmin end,
--       -- alpha
--       alpha = function(self) return self.prod_2_h end,
--     },
    
--     hrout = {
--       -- temperature in
--       tin = function(self) return self.prod_mix_temp() + 273 end,
--       -- enthalpy in
--       hin = function(self) return 0 end,
--       -- temperature out
--       tout = function(self) return self.prod_final_temp + 273 end,
--       -- enthalpy out
--       hout = function(self) return self.prod_final_load() end,
--       -- delta t min
--       dtmin = function(self) return self.hrout_dtmin end,
--       -- alpha
--       alpha = function(self) return self.mixture_h end,
--     },
--   }
-- }
lib:addUnit("CookingMixingUnit", {type = 'Process'})

lib["CookingMixingUnit"]:addStreams({
  hrin_1 = {'prod_1_temp',0,'prod_1_btemp','prod_1_load','hrin_1_dtmin','prod_1_h'},
  hrin_2 = {'prod_2_temp',0,'prod_2_btemp','prod_2_load','hrin_2_dtmin','prod_2_h'},
  hrout  = {'prod_mix_temp',0,'prod_final_temp','prod_final_load','hrout_dtmin','mixture_h' },
})




return lib
