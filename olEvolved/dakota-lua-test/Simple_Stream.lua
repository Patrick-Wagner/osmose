#!/usr/bin/lua
--[[------------------------------------------------------

    # Simple_Stream

  The model class was designed in order to be used in OL_Dakora as a test case.
  

--]]------------------------------------------------------

local osmose = require 'lib.osmose'
-- local ext = require 'olEvolved.global'
local tester = osmose.Model 'Simple_Stream'
--local extfun = ext.envFuns ''
local intermediateFile =''

-- local tester = olEvolved.Model_Evolved 'Stream_tester' -- This is the model for testing Dakota integration
-- the input parameters are passed in order to (re-)initialize the default stream value of each stream load 
--local params = {...}


function getCurIter ()

    local numf = assert(io.open('numfile', "r"))   
    local tempn = numf:read("*a")
    --print ("\n ---- Content of file read == "..tempn)
    numf:close()
     
return string.match (tempn, "%d+") 
end


-- is this necessary or not ?
-- Any Pre-initialisation phase to put here

function PreInitialise (filename)
  print ('^^^^^ \n Initialisation of Params.in file name :: '..filename)
  -- intermediateFile = filename
  local iternum = ''
    local numf = assert(io.open('numfile', "r"))   
    local tempn = numf:read("*a")
    --print ("\n ---- Content of file read == "..tempn)
    numf:close()
     
    iternum = string.match (tempn, "%d+") 
  
  intermediateFile = './text_book.'..iternum..'/params.in'

end



function getInputValue (filename, str1)
    print ("\n ---- Function GetInputValue called with "..filename..' '..str1)
    local file = assert(io.open(filename, "r"))
    local temp = file:read("*all")
    print ("\n ---- Content of file read == "..temp)
   
   local parsed = getSciNumVar (temp, str1) 
       
    print (" ---- Target Value Read "..parsed)
    file:close()
return parsed
end


-- getSciNumVar is used in order for i) finding a line, from the contentStr, which contains 'term';
--    ii) and extract the scientific number part from this line;
--    iii) return the numerical value
--  
function getSciNumVar (contentStr, term)
    local parsedNum = 1.0   -- initialization of a certain value (0 will not be pertinent for several reasons. Therefore use 1 as a default initial value.

    local word = string.match(contentStr, '[+%-]?%d+%.?%d*[eE+%-]*%d?%d?%s'..term)
                   --- Check found word
                   print ('Found Word Scientific Num == '..word)
    
    local word2 = string.sub(word,1, (string.find (word, term))-2)
return word2
end
  

-- For this test, Putting this part of pre model compute in the model part, considering that a Model is created with this flexibility
-- of modification.
-- The following definition of PreModel can be modified or extended according to specific needs.
function PreModelCompute (x1, x2, filename)
  x1 = getInputValue ('./text_book.'..getCurIter()..'/params.in', 'x1')
  x2 = getInputValue ('./text_book.'..getCurIter()..'/params.in', 'x2')
  tester.inputs = initialise_input (x1, x2)
end




-- the function initialise_input is used in two ways: i) in the first run, initialize the input stream load, 
--                ii) during the iteration (multi-time), re-initialize the stream load using the dakota proposed x1 and x2 
function initialise_input (x1, x2)
  local inputs= {}
  print (' \n---------- FOR NEW INPUT VALUES x1 == '..x1..',  x2 == '..x2)
  
  inputs = { 
  --   stream1_load = {default = 30, min=10, max=300, unit = 'kW'},  
  --   stream2_load = {default = 100, min=10, max=350, unit = 'kW'},
  --   stream3_load = {default = 40, min=10, max=200, unit = 'kW'},
  --   stream4_load = {default = 350, min=300, max=450, unit = 'kW'}
     
     stream1_load = {default = x1, min=10, max=300, unit = 'kW'},   -- this is x1 used between dakota and lua
     stream2_load = {default = x2, min=10, max=350, unit = 'kW'},   -- this is x2 used between dakota and lua
     stream3_load = {default = 40, min=10, max=200, unit = 'kW'},
     stream4_load = {default = 350, min=300, max=450, unit = 'kW'}
     
  }

return inputs
end

local x_st1 = 20   
local x_st2 = 20
local x1 = x_st1
local x2 = x_st2


--local st1val2 = getInputValue ('/Users/minjyoo/Documents/workspace/LuaOsmose_Evolved/src/projects/params.in', 'stream1_load', 'defval')

tester.values={
    CpAir=1.005,            --[kJ/kg/K]
    CpAirVol=1.2,               --[kJ/m3/K] 
    CpWaterVol=4.18*1000,       --[kJ/m3/K] 
    CpWater=4.18,           --[kJ/kg/K] 
    WaterDensity=1,                 --[kg/L]
    pi=3.1415,                  --             
    abs_pressure=1.01325*10^5,  --[N/m^2]
    r_specific=287.058,      
}

--[[
tester.advanced = { -- doc 

    -- ####  ENERGY INTEGRATION DATA

    -- Delta T min for space and air heating  -- dtmin_2_space
    DtminSpace = {default = 5, min = 0, max = 1, unit = 'K '}, 

    -- Delta T min for water -- dtmin_2_water
    DtminWater = {default = 2, min = 0, max = 5, unit = 'K '}, 

    -- Delta T min for Waste Water heat recovery-- dtmin_2_waste_water
    DtminWw = {default = 3, min = 0, max = 1, unit = 'K '},

    --Water
    WaterH = {default = 3, min = 0, max = 1, unit = 'K '},

    --Air
    AirH = {default = 3, min = 0, max = 1, unit = 'K '},
    
}
--]]

-- My question (1): How to compute Total Elec demand and put it as output?
--

-- The following line is depend on the implementaion  of PreModelCompute 
-- According to the objective to achieve, there might be another way of putting code
if (getCurIter() == '1') then
  tester.inputs = initialise_input (x_st1, x_st2)
else
  --x1 = get_x1()
  --x2 = get_x2()
  PreModelCompute (x1, x2, intermediateFile)
end


tester:addLayers {electricity = {type= 'MassBalance', unit = 'kW'}}

tester:addUnit ("elec_from_grid", {type ='Utility'})  -- this is a dummy model added in order to learn the total amount of elec to supply
tester:addUnit ("building", {type= 'Process'})

tester:addUnit ("boiler", {type = 'Utility', Fmax= 100, Cost1=20, Cost2= 12, Impact = 10})
tester:addUnit ("hp", {type = 'Utility', Fmax= 100, Cost1=10, Cost2= 5, Impact = 5})
tester:addUnit ("solar", {type = 'Utility', Fmax = 100, Cost1=1000, Cost2= 0.1330, Impact = 1})


tester["boiler"]:addStreams {
   Q_output_boiler= qt{100, 'stream1_load', 80, 0, 2},
   Elec_bld_out = ms ({'electricity', 'in', 10})
}

tester["hp"]:addStreams {
   Q_hp_cond= qt {80, 'stream2_load', 60, 0, 5},   -- load=300 (run1), load=100 (run4), electricity was changed anyway
   Elec_hp_in = ms ({'electricity', 'in', 100})
}

tester["building"]:addStreams {
   Heating= qt {10, 0, 25, 'stream3_load', 5},
   Elec_demand = ms ({'electricity', 'in', 80})
}

tester["elec_from_grid"]:addStreams {
   Elec_supply = ms ({'electricity', 'out', 10})
}


return tester