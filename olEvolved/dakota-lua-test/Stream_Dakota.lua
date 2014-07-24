----
-- This is a test Frontend example for testing Simple_Stream model with Dakota Integration.
-- @module Stream_Dakota

local osmose = require 'lib.osmose'
--local global = require 'olEvolved.global'

local eii = amplInTag (pathstr, {{x1, 'DefaultHeatCascade&sStream%_Dakota%_stester%_building%_Heating%s&d%s*(%d+)'}, 
                        {x2, 'DefaultHeatCascade%sStream%_Dakota%_stester%_hp%_Q%_hp%_cond%s%d%s*(%d+)'}, 
                        {x3, 'DefaultHeatCascade%sStream%_Dakota%_stester%_boiler%_Q%_output%_boiler%s&d%s*(%d+)'}})


local project = osmose.Project('Stream_Dakota', 'OperatingCost')
project.operationalCosts = {cost_elec_in = 17.19, cost_elec_out = 16.9, op_time=8000.0}


-- params3 must be the current period number (? run number ?)

local params = {...}
local pathstr ='.'    -- as its default value, current directory
--print (' Lua called with number of param = '..#params..' param1 = '..params[1]..' param2 = '..params[2])

-- Using Coroutine, we can trace the period count in order to find the dakota interface directory

-- function getResultFpath receives the iteration number (run) used as a postfix of path name
-- and return the composed path name where the EnergyIntegration saved the eiAmplAll.out file
-- Outputs a good 'Hello World.
-- @function [parent=#hello] getResultFpath
-- @param pn Path name in a string format
function getResultFpath (pn)

    print ('\n   .......... get ResultFpath method called   .............\n')
    local pathstr = '/Users/minjyoo/Documents/workspace/LuaOsmose_Evolved/src/results/Stream_Dakota/run_'
    pathstr = pathstr..getCurIter()..'/periode_1/tmp/'
    
return pathstr
end

-- function getCurIter returns the value of current time (iteration) number
-- @function getCurIter
-- @param nothing
function getCurIter ()

    local numf = assert(io.open('numfile', "r"))   
    local tempn = numf:read("*a")
    --print ("\n ---- Content of file read == "..tempn)
    numf:close()
     
return string.match (tempn, "%d+") 
end

-- function setCurIter set the iteration nuber in a numfile (a text file)
-- @function serCurIter
-- @param curnum the new iteration value in integer type
function setCurIter (curnum)
    numf = assert (io.open('numfile', "w"))  
       print ("%%% After modification , content of file :: "..curnum)

    numf:write(curnum)
    numf:close()   
end

-- function which should be developped in the future and used for the purpose of cleaing intermediate result values
-- @function initialiseAll
-- @param
function initialiseAll ()
print (' before execution, initialise the dakota directory and lua working directly as well as numfile content set to 0')
-- steps to develop
end

--[[
-- Read optimized total energy consumption and use it for integrated computation with total environmental impact values
-- The multiplication factor is used in order to quantify the negative impact of some impact, for example (-1.3)
function postComputeDakota (var1, var2)
    local multfact = -1.3
    local newOfv = var1 + multfact*var2
return newOfv  
end

--]]

-- function getInputValue receives tag names to be searched and find the corresponding value
-- @function getInputValue
-- @param filename
-- @param str1 first tag name
-- @param str2 second tag name
function getInputValue (filename, str1, str2)
    print ("\n ---- New Function GetInputValue called with "..filename..' '..str1..' '..str2)
    local file = assert(io.open(filename, "r"))
    local temp = file:read("*all")
    print ("\n ---- Content of file read == "..temp)
   
    local parsed = string.match (temp, "%d+") 
       
    print (" ---- Target Value Read "..parsed)
    file:close()
    return parsed
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


-- Post compute concerns: reading x1 & x2 values from the input file (read values in model in order to recover x1 & x2 values
-- And write them in the results.out file in order for dakota to use for the next input variable decision.
--
-- Ultimately, the patten string used in the function should be replaced with the tag structure and their corresponding value search.
function PostEICompute (x1, x2, x3, filename)

    
    -- Here, get decision variables from  eiampldata.in file
    local ampldata = assert(io.open(filename, "r"))
    local tempdata = ampldata:read("*all")
    x1 = string.match (tempdata, 'DefaultHeatCascade&sStream%_Dakota%_stester%_building%_Heating%s&d%s*(%d+)')
    x2 = string.match (tempdata, 'DefaultHeatCascade%sStream%_Dakota%_stester%_hp%_Q%_hp%_cond%s%d%s*(%d+)')
    x3 = string.match (tempdata, 'DefaultHeatCascade%sStream%_Dakota%_stester%_boiler%_Q%_output%_boiler%s&d%s*(%d+)')
    
    local eii = amplInTag (pathstr, {{x1, 'DefaultHeatCascade&sStream%_Dakota%_stester%_building%_Heating%s&d%s*(%d+)'}, 
                        {x2, 'DefaultHeatCascade%sStream%_Dakota%_stester%_hp%_Q%_hp%_cond%s%d%s*(%d+)'}, 
                        {x3, 'DefaultHeatCascade%sStream%_Dakota%_stester%_boiler%_Q%_output%_boiler%s&d%s*(%d+)'}})
    eii.printAll()
      
    ampldata:close()
end



-- The following values should be returned from a Pre Model Computing function
--local st1val = 230  -- initial value
--local st1val = 270    -- second test
--st1val2 = getInputValue ('/Users/minjyoo/Documents/workspace/LuaOsmose_Evolved/src/projects/params.in', 'stream1_load', 'defval')

------------------------------------------------------------------------
-- Read Params.in is done by the Stream_tester module 
-- But ultimately, this must be done by a Pre-computing process

-- And then 
-- ---------------------------------------------------------------------

-- And instantiation of the project & OneRun executed

project:load(
  {stester = "ET.Simple_Stream"}
)


-- The following step is a part of PreModelCompute
-- So further thinking of it 
local curfile = './text_book.'..getCurIter()..'/params.in'
-- The following line PROBLEM to solve !!!!!
--stester.PreInitialise (curfile)

local oneRun = osmose.Eiampl(project)

osmose.Glpk(oneRun)

osmose.Graph(oneRun)

---
-- 

-- After oneRun create the output file 
-- the result will be returned by Dakota
-- here, Read the output file (param2) and rewrite the input file (param1) should be done.
-- Ultimately, this concerns the post-computing at the end of process integration. 
-- 
-- Here, reading the Ampl outfile
-- And put it on the following formula
-- read the eiamplAll.out file and get the ObjectiveFunction Value
-- in this example, OperatingCost is used.
---
-- @function [parent=Stream_Dakota] 
-- @param #number n Parameter description
-- @return #number Typed return description
-- @return #nil, #string Traditional nil and error message
function PostEiProcess (objfTbl, inputTbl)

end

------------------------------------------------------------------------
-- After oneRun create the output file 
-- the result will be returned by Dakota
-- here, Read the output file (param2) and rewrite the input file (param1) should be done.
-- Ultimately, this concerns the post-computing at the end of process integration. 
-- 
-- Here, reading the Ampl outfile
-- And put it on the following formula
-- read the eiamplAll.out file and get the ObjectiveFunction Value
-- in this example, OperatingCost is use

    local newObf = 1.0 -- initialize the objective function value to 1 as a default value
    local x1 = 1.11 -- this should be the first element of inputTbl
    local x2 = 1.11 -- this should be the second element of inputTbl
    local x3 = 1.11 -- this should be the third element of inputTbl
    

    local pattern1 = 'DefaultHeatCascade&sStream%_Dakota%_stester%_building%_Heating%s&d%s*(%d+)'
    local pattern2 = 'DefaultHeatCascade%sStream%_Dakota%_stester%_hp%_Q%_hp%_cond%s%d%s*(%d+)'
    local pattern3 = 'DefaultHeatCascade%sStream%_Dakota%_stester%_boiler%_Q%_output%_boiler%s&d%s*(%d+)'
  
  
    local direcStr = getResultFpath(getCurIter())

    --- 'GlpkOutMsg.txt' is a lua-dependent output file.
    local amplRslt = assert(io.open(direcStr..'GlpkOutMsg.txt', "r"))
    local temp = amplRslt:read("*all")
    
    local valPattern = "Objective:  ObjectiveFunction =%s*(%d+)"    
    local val = string.match (temp, valPattern)
    print ('  \n --->>>   Objective Function Value 1 Found ---'..val)
    if (val ~= nil) then 
      newObf = val 
    end

    amplRslt:close()
    
    
    local obj2Pattern = 'Units%_supply%[layers%_electricity%,Stream_Dakota%_stester%_elec%_from%_grid%,%d*]%.val%s=%s(%d+)'
    local amplout = assert(io.open(direcStr..'eiamplAll.out', "r"))
    local tempout = amplout:read("*all")
    local objval2 = string.match (tempout, obj2Pattern)
    print ('  \n --->>>   Objective Function Value 2 Found ---'..objval2)
     
    
    --- in order to recover the decision variable used for obtaining above objective function values
    --PostEICompute (x1, x2, x3, direcStr..'eiampldata.in')    
    
    -- Here, get decision variables from  eiampldata.in file
    local ampldata = assert(io.open(direcStr..'eiampldata.in', "r"))
    
    local tempdata = ampldata:read("*all")
    --print('\n\n    ------------- eiample In Data Read ----------------\n'..tempdata)
    
    x1 = string.match (tempdata, 'DefaultHeatCascade%sStream%_Dakota%_stester%_building%_Heating%s%d%s*(%d+)')
    x2 = string.match (tempdata, 'DefaultHeatCascade%sStream%_Dakota%_stester%_hp%_Q%_hp%_cond%s%d%s*(%d+)')
    x3 = string.match (tempdata, 'DefaultHeatCascade%sStream%_Dakota%_stester%_boiler%_Q%_output%_boiler%s%d%s*(%d+)')
    
    --- test command
    eii.printAll()
    ampldata:close()
    
    print ('\n  Decision variables for Next Iteration ::  x1= '..x1..', x2= '..x2..', x3 = '..x3)
    
    -- 'results.out' is a dakota-dependent output file.
    local file = assert(io.open("results.out", "w"))

    file:write(newObf.." obj_fn_cost\n")
    file:write(objval2.." obj_fn_energy\n")
    file:write(x1.." x1\n")
    file:write(x2.." x2\n")
    file:write(x3.." x3\n")
    file:close()
        
    local curnum = getCurIter()
       
    -- Shell dependent command line
    -- Ultimately, these lines of code should be replaced by appropriate handling in Lua PostComputing
--    dirStr = '/usr/local/dakota-5.4.0.Darwin.i386/examples/script_interfaces/Lua/lua_work.'..curnum

    cpStr = 'cp results.out ./text_book.'..curnum
    os.execute (cpStr)
    
    print (' ---------\n Copy of result file in LUA DIRECTORY Executed \n----------')
    dirStr = '/usr/local/dakota-5.4.0.Darwin.i386/examples/script_interfaces/text_book_wd/text_book.'..curnum
    mkcmdStr = 'mkdir '..dirStr
    os.execute (mkcmdStr)
    
    -- I should decide whether to use mv or cp
    --cmdStr = 'mv results.out '..dirStr    -- with move, I had an error !!
    cmdStr = 'cp results.out '..dirStr
    os.execute(cmdStr)

    print (' =========== \n Copy or move of result file in DAKOTA DIRECTORY Executed \n ==========')
    
    curnum = curnum+1
    setCurIter(curnum)

