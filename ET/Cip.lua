#!/usr/bin/lua
--[[------------------------------------------------------

  # Cip - Cleaning In Place Tank

--]]------------------------------------------------------

local osmose = require 'osmose'
local cip = osmose.Model 'Cip'

cip.values={
  air_cp=1.007,--;% kJ/kg/C 
  water_cp=4.18,--;% kJ/kg/C 
  ice_cp=2.09,--;% kj/kg/C 
  water_molarmass=18,--; % g/mol 
  air_molarmass=29,--;% g/mol
}

-- cip.inputs = 'exemples/jam/CIP_inputs.csv'

cip.inputs = { -- doc
  -- Temperature of the cleaning tank. The distributed cleaning liquid
  -- temperature is the same (CW1). 
  -- [math][/math]
  tank_temp = {default = 85, min = 88, max = 90, unit = 'C'},
  
  -- Mass flowrate of cleaning liquid distributed to the process. (CW1)
  -- [math][/math]
  distributed_water_flow = {default = 10, min = 5, max = 10, unit = 't/h'},
  
  -- Percentage of the mass flowrate of the raw water that is recovered from the
  -- process. Ratio of the mass flowrate of the raw water recovered from the
  -- process over the total mass flowrate of the raw water.
  -- [math][/math]
  raw_water_rate = {default = 50, min = 50, max = 50, unit = '%m/m'},
  
  -- Temperature of the raw water that is recovered from the process. (RW2)
  -- [math][/math]
  return_temp = {default = 40, min = 40, max = 40, unit = 'C'},
  
  -- Percentage of the mass flowrate of the recovered raw water (RW3) that is
  -- purged. 
  -- [math][/math]
  purge_rate = {default = 100, min = 100, max = 100, unit = '%m/m'},
  
  -- Specific heat capacity of cleaning agent (CA0)
  -- [math][/math]
  cleaning_agent_cp = {default = 4.05, min = 4.05, max = 4.05, unit = 'kJ/kg C'},
  
  -- Temperature of inlet cleaning agent before preheating. (CA0)
  -- [math][/math]
  cleaning_agent_temp = {default = 10, min = 10, max = 10, unit = 'C'},

  base_load1 = {default = 0, unit='kW'},

  base_load2 = {default = 800, unit='kW'},
}

-- ## Result (isVIT = 2)
cip.outputs = { -- doc
  -- Mass flowrate of the raw water that is recovered from the process. (RW2)
  -- [math] (raw_water_rate/100) * distributed_water_flow [/math]
  -- raw_water_flow = {unit = 't/h', job =
  --   function()
  --     return (raw_water_rate/100) * distributed_water_flow
  --   end},
  raw_water_flow = {unit = 't/h', job = "(raw_water_rate/100) * distributed_water_flow" },
  
  -- Mass flowrate of the raw water that is recovered from the process after purge. (RW3)
  -- [math]  (1-purge_rate/100) * raw_water_flow  [/math]
  -- return_raw_water_flow = {unit = 't/h', job =
  --   function()
  --     return (1-purge_rate/100) * raw_water_flow() 
  --   end},
  return_raw_water_flow = {unit='t/h', job="(1-purge_rate/100) * raw_water_flow()"},
  
  -- Mass flowrate of the recovered raw water that is purged. (RW4)
  -- [math] (purge_rate/100) * raw_water_flow   [/math]
  -- discharged_raw_water_flow = {unit = 't/h' , job =
  --   function()
  --     return (purge_rate/100) * raw_water_flow() 
  --   end},
  discharged_raw_water_flow = {unit='t/h', job="(purge_rate/100) * raw_water_flow()"},
  
  -- Rate of fresh water as a mass percentage of  the cleaning liquid
  -- distributed to the process. Ratio of the mass flowrate of the fresh water
  -- (FW0) over the total mass flowrate of the distributed cleaning liquid
  -- (CW1).
  -- [math] (1-purge_rate/100) * raw_water_flow  [/math]
  -- renew_rate = {unit = '%m/m' , job =
  --   function()
  --     return (1-purge_rate/100) * raw_water_flow() 
  --   end},
  renew_rate = {unit='%m/m', job="(1-purge_rate/100) * raw_water_flow()"},
  
  -- Mass flowrate of fresh water added to the process. (FW0)
  -- [math] (distributed_water_flow - return_raw_water_flow) / (1 + (cleaning_agent_rate /100))  [/math]
  -- fresh_water_flow = {unit = 't/h' , job = 
  --   function()
  --     return (distributed_water_flow - return_raw_water_flow()) / (1 + (cleaning_agent_rate /100))
  --   end},
  fresh_water_flow = {unit='t/h', job="(distributed_water_flow - return_raw_water_flow()) / (1 + (cleaning_agent_rate /100))"},


  -- Mass flowrate of cleaing agent added in the tank
  -- [math]  (cleaning_agent_rate /100 ) * fresh_water_flow  [/math]
  -- cleaning_agent_flow = {unit = 't/h', job = 
  --   function()
  --     return (cleaning_agent_rate /100 ) * fresh_water_flow() 
  --   end},
  cleaning_agent_flow = {unit = 't/h', job ="(cleaning_agent_rate /100 ) * fresh_water_flow()"},
  
  -- Cleaning agent heat load. Heat load required to heat the cleaning agent up
  -- to the tank temperature.  
  -- [math]cleaning_agent_flow / 3.6 * cleaning_agent_cp * (tank_temp - cleaning_agent_temp)[/math]
  -- cleaning_agent_load = {unit = 'kW', job =
  --   function()
  --     return cleaning_agent_flow() / 3.6 * cleaning_agent_cp * (tank_temp - cleaning_agent_temp)
  --   end},
  cleaning_agent_load = {unit='kW', job="cleaning_agent_flow() / 3.6 * cleaning_agent_cp * (tank_temp - cleaning_agent_temp)"},

  -- Fresh water heat load. Heat load required to heat the fresh water up to the
  -- tank temperature
  -- [math] fresh_water_flow / 3.6 * water_cp * (tank_temp - source_temp)  [/math]
  -- fresh_water_load = {unit = 'kW' , job =
  --   function()
  --     return fresh_water_flow() / 3.6 * water_cp * (tank_temp - source_temp)
  --   end},
  fresh_water_load = {unit='kW', job="fresh_water_flow() / 3.6 * water_cp * (tank_temp - source_temp)"},
  
  -- Heat load required to heat the recycled part of raw water up to the tank
  -- temperature. 
  -- [math] return_raw_water_flow / 3.6 * water_cp * (tank_temp - return_temp ) [/math]
  -- main_load = {unit = 'kW', job =
  --   function()
  --     return return_raw_water_flow() / 3.6 * water_cp* (tank_temp - return_temp )
  --   end},
  main_load = {unit='kW', job="return_raw_water_flow() / 3.6 * water_cp* (tank_temp - return_temp )"},
  
  -- Discharge cooling load. Cooling load released by cooling the discharged raw
  -- water to the temperature required for the sewage treatment
  -- [math] discharged_raw_water_flow / 3.6 * water_cp * (return_temp - max_temp) [/math]
  -- discharge_load = {unit = 'kW', job =
  --   function()
  --     return discharged_raw_water_flow() / 3.6 * water_cp * (return_temp - max_temp)
  --   end},
  discharge_load = {unit = 'kW', job = "discharged_raw_water_flow() / 3.6 * water_cp * (return_temp - max_temp)"},
  
  -- To test addToProblem with a tag:
  j1 = {job = '3-2'},

  }

-- ## Advanced (isVIT = 3)
cip.advanced = {
  -- Temperature of the waste water at the sewage treatment plant : it is the
  -- maximal temperature accepted at the inlet of the waste water treatment
  -- plant.
  -- [math][/math]
  max_temp = {default = 20, min = 0, max = 100, unit = 'C'},
  
  -- Heat transfer film coefficient of water is used for all stream definitions.
  -- [math][/math]
  water_h = {default = 1.136, min = 1, max = 2, unit = 'kW/m2 C'},
  
  -- Temperature of inlet fresh water before preheating
  -- [math][/math]
  source_temp = {default = 10, min = 0, max = 100, unit = 'C'},
  
  -- Rate of cleaning agent expressed as percentage of the water make_up mass
  -- flowrate (FW0). Ratio of the mass flowrate of the cleaning agent over the
  -- total mass flowrate of fresh water
  -- [math][/math]
  cleaning_agent_rate = {default = 5, min = 0, max = 100, unit = '%m/m'},
  
}

-- streams in processes
-- cip.processes = { cipUnit = {
--     cleaning_agent = osmose.QTStream { 'cleaning_agent_temp', 0,'tank_temp','cleaning_agent_load',3, 'water_h'},
    
--     fresh_water = osmose.QTStream { 'source_temp', 0,'tank_temp','fresh_water_load', 3,'water_h'},
    
--     discharge = osmose.QTStream { 'return_temp','discharge_load','max_temp', 0, 3, 'water_h'},
--   }
-- }

cip:addUnit("CipUnit", {type = 'Process', addToProblem='j1'})

cip["CipUnit"]:addStreams({  
  cleaning_agent = qt { 'cleaning_agent_temp', 0,'tank_temp','cleaning_agent_load',3, 'water_h'},
  fresh_water = qt { 'source_temp', 0,'tank_temp','fresh_water_load', 3,'water_h'},
  -- test HT Stream
  discharge = ht { {'return_temp'},{'discharge_load'},{'max_temp'}, {0},{ 3}, {'water_h'}},
  dot_cold = qt {80,'base_load1',80,'base_load2',3},
  dot_hot = qt{80,'base_load2',80,'base_load1',3}
})

-- optional :
cip["CipUnit"]["cleaning_agent"].addToProblem = 1



return cip

