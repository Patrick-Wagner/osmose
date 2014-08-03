----
-- This is a Frontend example for testing Simple_Stream model with Dakota Integration.
-- @module Stream_Dakota
-- @param 
-- @param
-- @param 3rd must be the current period number

local osmose = require 'osmose'      

local params = {...}
local pathstr ='.'    -- Default value: set to current directory, But its use should be evaluated later 2014-07-31
local projectName = 'Stream_Dakota'

print (' Lua called with number of param = '..#params..' param1 = '..params[1]..' param2 = '..params[2])

---
-- function getCurIter returns the value of current time (iteration) number
-- For the moment, I would like to use getCurIter() as one of the global variables even though it is very Dakota-dependent definition
-- @function getCurIter
-- @param nothing
function getCurIter ()

    local numf = assert(io.open('numfile', "r"))   
    local tempn = numf:read("*a")
    --print ("\n ---- Content of file read == "..tempn)
    numf:close()
     
return string.match (tempn, "%d+") 
end

---
-- function setCurIter set the iteration nuber in a numfile (a text file)
-- idem for the reason of defining it as one of the global veriables
-- @function serCurIter
-- @param curnum the new iteration value in integer type
function setCurIter (curnum)
    numf = assert (io.open('numfile', "w"))  
    --print ("%%% After modification , content of file :: "..curnum)

    numf:write(curnum)
    numf:close()   
end


local theProject = osmose.Project('Stream_Dakota', 'OperatingCost')
theProject.operationalCosts = {cost_elec_in = 17.19, cost_elec_out = 16.9, op_time=8000.0}


-- Using Coroutine, we can trace the period count in order to find the dakota interface directory

---
-- function getResultFpath receives the iteration number (run) used as a postfix of path name
-- and return the composed path name from where the eiAmplAll.out file can be retrieved.
-- WIP the pathstr variable should be retrieved, during the initialization, by parameter passing (pn as user specific environment) 
-- @function getResultFpath
-- @param pn Path name in a string format
function theProject:getResultFpath (pn)

    print ('\n   .......... get ResultFpath method called   .............\n')
    local pathstr = '/Users/minjyoo/Documents/workspace/LuaOsmose_Evolved/src/results/Stream_Dakota/run_'
    pathstr = pathstr..getCurIter()..'/periode_1/tmp/'
    
return pathstr
end


---
-- function which should be developped in the future and used for the purpose of cleaing intermediate result values
-- @function initialiseAll
-- @param
function theProject:initialiseAll ()
print (' before execution, initialise the dakota directory and lua working directly as well as numfile content set to 0')
-- steps to develop
end


--[[ 
-- The following definition of postComputeDakota is the next step to implement
-- Read optimized total energy consumption and use it for integrated computation with total environmental impact values
-- The multiplication factor is used in order to quantify the negative impact of some impact, for example (-1.3)
function postComputeDakota (var1, var2)
    local multfact = -1.3
    local newOfv = var1 + multfact*var2
return newOfv  
end

--]]

---
-- After oneRun, the result is returned by Dakota.
-- Read the output file (param2) and rewrite the input file (param1).
-- Ultimately, this concerns the post-computing at the end of process integration. 
-- read the eiamplAll.out file and get the ObjectiveFunction Value
-- in this example, OperatingCost is use
-- @function [parent=Stream_Dakota] 
-- @param #number n Parameter description
-- @return #number Typed return description
-- @return #nil, #string Traditional nil and error message
-- The output variables retrieval is currently rewritten using Tag value Tables and be integrated with the ol_Extension package
function theProject:PostEiCompute ()


    local newObf = 1.0 -- initialize the objective function value to 1 as a default value  
    local direcStr = theProject:getResultFpath(getCurIter())

    --- 'GlpkOutMsg.txt' is a lua-dependent output file.
    local amplRslt = assert(io.open(direcStr..'GlpkOutMsg.txt', "r"))   -- String GlpkOutMsg.txt should be declared as a VAR
    local temp = amplRslt:read("*all")
    
    local valPattern = "Objective:  ObjectiveFunction =%s*(%d+)"        -- The Pattern String should be declared as a VAR
    local val = string.match (temp, valPattern)
    print ('  \n --->>>   Objective Function Value 1 Found ---'..val)
    if (val ~= nil) then 
      newObf = val 
    end

    amplRslt:close()
    
    
    local obj2Pattern = 'Units%_supply%[layers%_electricity%,Stream_Dakota%_simple_stream%_elec%_from%_grid%,%d*]%.val%s=%s(%d+)'
    local amplout = assert(io.open(direcStr..'eiamplAll.out', "r"))   -- eiamplALL.out should be declared as a CONST
    local tempout = amplout:read("*all")
    
    print ('eiamplALL OUT opened for finding Objective Function Value 2')
    print (tempout)
    print ('  String Pattern to find ::: '..obj2Pattern)
    local objval2 = string.match (tempout, obj2Pattern)
    if (objval2 ~= nil) then 
      print ('  \n --->>>   Objective Function Value 2 Found ---  '..objval2)
    else
      print (' ERROR -- NOT FOUND')
    end
     
   
    
    -- Here, get decision variables from  eiampldata.in file
    local ampldata = assert(io.open(direcStr..'eiampldata.in', "r"))  -- eiampldata.in should be declared as a CONST
    
    local tempdata = ampldata:read("*all")
    --print('\n\n    ------------- eiample In Data Read ----------------\n'..tempdata)
    
    x1 = string.match (tempdata, 'DefaultHeatCascade%sStream%_Dakota%_simple_stream%_building%_Heating%s%d%s*(%d+)')
    x2 = string.match (tempdata, 'DefaultHeatCascade%sStream%_Dakota%_simple_stream%_hp%_Q%_hp%_cond%s%d%s*(%d+)')
    x3 = string.match (tempdata, 'DefaultHeatCascade%sStream%_Dakota%_simple_stream%_boiler%_Q%_output%_boiler%s%d%s*(%d+)')

    ampldata:close()
    
    print ('\n  Decision variables for Next Iteration ::  x1= '..x1..', x2= '..x2..', x3 = '..x3)
    
    -- 'results.out' is a dakota-dependent output file.
    local file = assert(io.open("results.out", "w"))                  -- results.out should be declared as a VAR

    file:write(newObf.." obj_fn_cost\n")                              -- the write content is specific to each user/problem
    file:write(objval2.." obj_fn_energy\n")                           -- both strings should be defined as tag elements
    file:write(x1.." x1\n")
    file:write(x2.." x2\n")
    file:write(x3.." x3\n")
    file:close()
        
    local curnum = getCurIter()
       
    -- Shell dependent command line

    cpStr = 'cp results.out ./stream_model.'..curnum
    os.execute (cpStr)
    
    dirStr = '/usr/local/dakota-5.4.0.Darwin.i386/examples/script_interfaces/Lua/stream_model.'..curnum
    mkcmdStr = 'mkdir '..dirStr
    os.execute (mkcmdStr)
    
    -- I should decide whether to use mv or cp
    --cmdStr = 'mv results.out '..dirStr    -- with move, I had an error !!
    cmdStr = 'cp results.out '..dirStr
    os.execute(cmdStr)

    print (' =========== \n Copy or move of result file in DAKOTA DIRECTORY Executed \n ==========')
    
    -- increase the iteration counter for Dakota environment
    curnum = curnum+1
    setCurIter(curnum)

end

--------- End of PostEiCompute Process
-- 
--------- Start of conventional osmose.Project creation and use
-- 

theProject:load(
  {simple_stream = "ET.Simple_Stream"}
)

local oneRun = osmose.Eiampl(theProject)

osmose.Glpk(oneRun)

osmose.Graph(oneRun)

---
-- After the usual osmose.Project execution, call the predefiend PostEiCompute procedure
theProject:PostEiCompute ()
