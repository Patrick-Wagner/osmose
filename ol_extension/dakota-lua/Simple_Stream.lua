#!/usr/bin/lua
--[[------------------------------------------------------

    # Simple_Stream

  The model class was designed in order to be used in OL_Dakora as a test case.
  Simple_Stream extends the initial osmose.Model definition according to an object-oriented way:
    * inheritance of existing methods for Stream, Unit, Layer definitions
    * new definition of PreModelCompute Process, PreInitialise, 

--]]------------------------------------------------------

local osmose = require 'osmose'
local theModel = osmose.Model 'Simple_Stream'


-- some local variables restricted to my Model object here
local intermediateFile =''
-- local inParamfile = './Stream_Dakota.'..getCurIter()..'/params.in'    -- this is the file with directory from which the Dakota Suggested input params can be retrieved
local myModelName = 'stream_model.'
local x_st1 = 20   -- default x1 value to use
local x_st2 = 20   -- default x2 value to sue
local x1 = x_st1
local x2 = x_st2


---
-- Any Pre-initialisation phase to put here
function theModel:PreInitialise (filename)
   print ('\n^^^^^  Initialisation of Params.in file name :: '..filename)
   -- intermediateFile = filename     -- another possibility of using filename
   
   local iternum = ''
   local numf = assert(io.open('numfile', "r"))     -- the numfile is defined according to the need for Dakota integration
   local tempn = numf:read("*a")
   --print ("\n ---- Content of file read == "..tempn)    - for checking
   numf:close()
     
   iternum = string.match (tempn, "%d+")  
   self.intermediateFile = './'..myModelName..iternum..'/params.in'

end


-- For this test, Putting this part of pre model compute in the model part, considering that a Model is created with this flexibility
-- of modification.
-- The following definition of PreModel can be modified or extended according to specific needs.
function theModel:PreModelCompute ()

   print ('\n   PreModelCompute called')

  x1 = theModel:getInputValue ('x1')
  x2 = theModel:getInputValue ('x2')
  
  theModel.inputs = theModel:initialise_input (x1, x2)
end


---
-- function getInputValue receives tag names to be searched and find the corresponding value
-- @function getInputValue
-- @param filename
-- @param str1 first tag name
-- @param str2 second tag name
function theModel:getInputValue (valstr)
    local filename = './stream_model.'..getCurIter()..'/params.in'

    local file = assert(io.open(filename, "r"))
    local temp = file:read("*all")
    -- print ("\n ---- Content of file read == "..temp)
   
    file:close()

    local parsedNum = 1.0   -- initialization of a certain value (0 will not be pertinent for several reasons. Therefore use 1 as a default initial value.
    -- print ('used valstr is .. '..valstr)
    local word = string.match(temp, '[+%-]?%d+%.?%d*[eE+%-]*%d?%d?%s'..valstr)
    local word2 = string.sub(word,1, (string.find (word, valstr))-2)
    
    --- Check found word
    -- print ('\n          ----- Found Word Scientific Num == '..word)
    -- print ('          ----- Found Word Scientific Num == '..word2)
    -- print ('          ---   Second value will be used ')
    

return word2
end


-- the function initialise_input is used in two ways: i) at the first run, initialize the input stream load, 
--                ii) during the iteration (multi-time), re-initialize the stream load using the dakota proposed x1 and x2 
function theModel:initialise_input (xval1, xval2)
  local inputs= {}
  print (' \n---------- FOR NEW INPUT VALUES x1 == '..xval1..',  x2 == '..xval2)
  
  inputs = { 
     
     stream1_load = {default = xval1, min=10, max=300, unit = 'kW'},   -- this is x1 used between dakota and lua
     stream2_load = {default = xval2, min=10, max=350, unit = 'kW'},   -- this is x2 used between dakota and lua
     stream3_load = {default = 40, min=10, max=200, unit = 'kW'},
     stream4_load = {default = 350, min=300, max=450, unit = 'kW'}
     
  }

return inputs
end

------------  End of PreModelCompute ----------------



theModel.values={
    CpAir=1.005,            --[kJ/kg/K]
    CpAirVol=1.2,               --[kJ/m3/K] 
    CpWaterVol=4.18*1000,       --[kJ/m3/K] 
    CpWater=4.18,           --[kJ/kg/K] 
    WaterDensity=1,                 --[kg/L]
    pi=3.1415,                  --             
    abs_pressure=1.01325*10^5,  --[N/m^2]
    r_specific=287.058,      
}


--- How to call PreModelCompute
-- 

-- The following line depends on how to implement user's PreModelCompute 
-- According to the objective to achieve, there might be another way of putting code
if (getCurIter() == '1') then   -- if it is the first run, use the default value
   theModel.inputs = theModel:initialise_input (x_st1, x_st2)
else                            -- otherwise, do some preModelCompute after the previous iteration
   theModel:PreModelCompute ()
end

---
-- The main Model definitions

theModel:addLayers {electricity = {type= 'MassBalance', unit = 'kW'}}

theModel:addUnit ("elec_from_grid", {type ='Utility'})  -- this is a dummy model added in order to learn the total amount of elec to supply
theModel:addUnit ("building", {type= 'Process'})

theModel:addUnit ("boiler", {type = 'Utility', Fmax= 100, Cost1=20, Cost2= 12, Impact = 10})
theModel:addUnit ("hp", {type = 'Utility', Fmax= 100, Cost1=10, Cost2= 5, Impact = 5})
theModel:addUnit ("solar", {type = 'Utility', Fmax = 100, Cost1=1000, Cost2= 0.1330, Impact = 1})


theModel["boiler"]:addStreams {
   Q_output_boiler= qt{100, 'stream1_load', 80, 0, 2},
   Elec_bld_out = ms ({'electricity', 'in', 10})
}

theModel["hp"]:addStreams {
   Q_hp_cond= qt {80, 'stream2_load', 60, 0, 5},   -- load=300 (run1), load=100 (run4), electricity was changed anyway
   Elec_hp_in = ms ({'electricity', 'in', 100})
}

theModel["building"]:addStreams {
   Heating= qt {10, 0, 25, 'stream3_load', 5},
   Elec_demand = ms ({'electricity', 'in', 80})
}

theModel["elec_from_grid"]:addStreams {
   Elec_supply = ms ({'electricity', 'out', 10})
}

return theModel