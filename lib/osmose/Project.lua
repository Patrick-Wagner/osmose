--[[---------------------------------------
  
  # Project

  Create an Osmose Project that specify an objective, load the ET models
  and indicate the periode and time cycle.

--]]---------------------------------------

local lub   = require 'lub'
local lib   = lub.class 'osmose.Project'
local lfs = require "lfs"
local helper = require 'osmose.helpers.projectHelper'
local Eiampl = require 'osmose.Eiampl'
local Glpk   = require 'osmose.Glpk'
local Graph  = require 'osmose.Graph'
local PostPrint  = require 'osmose.PostPrint'


-- Function for metatable.
function lib.__index(table, key)
  return lib[key]
end


--[[
  Create a new *project* with a `name` and an `objective` ('MER', 'YOC',...).

  Exemple :
    
    local project = osmose.Project('LuaJam', 'MER')
--]]
function lib.new(name, objective)
  local project = lub.class('Project')
  setmetatable(project, lib)

  -- Storing project parameters
  project.name = name
  project.objective = objective
  project.run = lib.getRun(name)

  -- The project store units, models, equations.
  project.units   = {}
  project.models  = {}
  project.equations = {}

  --Create directory for the current run.
  project.dirRun = ('./results/'..name..'/run_'..project.run..'/')
  lub.makePath(project.dirRun)

  -- Times are vectors inside periode vectors.
  project.periodes = {{times=1}}
  project.results  = {gcc={}, delta_hot={}, delta_cold={}, opcost={}, impact={}, mechpower={}, invcost={}}

  -- Each run has a directory to store the results. Inside the run, each periode has a directory.
  local dirTmp =  (project.dirRun..'/periode_1/tmp/')
  lub.makePath(dirTmp)

  return project
  
end

-- Returns the current run number of a `project name`.
function lib.getRun(projectName)
  local dir = './results/'..projectName..'/'
  local run, runs = 0, {}
  
  local currentDir = lfs.currentdir()

  if lfs.chdir(dir) == nil then
    lfs.mkdir(dir)
  end
  
  table.insert(runs, run)
  for filename in lfs.dir('.') do
    run = filename:match("run_(%d*)")
    if run then 
      table.insert(runs, run)
    end
  end
  lfs.chdir(currentDir)
  return(math.max(unpack(runs))+1)
end


--[[
  Loads the models for the project and their values file.
  The model must be in the ET directory.

  Exemple :

    project:load(
    {cip = "ET.Cip"},
    {cm1 = "ET.CookingMixing"},
    {cm2 = "ET.CookingMixing", with = 'CM2_inputs.csv'} )
--]]
function lib:load(...)
  local arg = {...}
  local model, name, modelPath, valuesPath
  for idx,_model in ipairs(arg) do
    for key,value in pairs(_model) do
      if key == 'with' then
        valuesPath = value
      else
        name = key
        modelPath = value
      end
    end
    
    -- Instantiate the model with the name given in the key.
    if type(modelPath) == 'string' then
      model = require(modelPath) (name)
    else
      model = modelPath (name)
    end

    helper.loadUndeclaredTags(model)

    -- Get the path of the file that has launched the script.
    if valuesPath then
      local sourcePath = debug.getinfo(2).source:sub(2)
      local sourceFile = sourcePath:match("(%w*%.%w*)") 
      local sourceDir  = sourcePath:match("(.*[/\\])")
      self.sourceDir = sourceDir
      model.loadValues(sourceDir..valuesPath)
    end

    table.insert(self.models, model)
  end
  return nil
end

--[[
  Allow to specify periodes and times values.

  Exemple:

    project:periode(1):time(12)
    project:periode(2):time(13)
    project:periode(3):time(11)
--]]--
function lib:periode(periode)

  local periodeTbl = {times=1}
  --setmetatable(periodeTbl,{__call = function(times) return 'toto' end })
  function periodeTbl:time(times)
    self.times = times
  end

  self.periodes[periode] = periodeTbl
  
  return self.periodes[periode]
end


--[[
  Return the unit corresponding to the name given
  and the periode, which is 1 by default.

  Exemple:

    project:getUnit('unit_name')
    project:getUnit('unit_name',2)
--]]--
function lib:getUnit(name, periode)
  local periode = periode or 1
  for i,u in ipairs(self.units[periode] or {}) do    
    if u.name == name or u.shortName == name then
      return u
    end
  end
end

--[[
  Return the stream corresponding to the name given
  and the periode, which is 1 by default.

  Exemple:

    project:getStream('stream_name')
    project:getStream('stream_name',2)
--]]--
function lib:getStream(name, periode)
  local periode = periode or 1
  for i,u in ipairs(self.units[periode] or {}) do
    for j,s in  ipairs(u.streams or {}) do
      if s.name == name or s.shortName == name then
        return s
      end
    end
  end
end


--[[
  Return the tag value corresponding to the name, periode
  and time given.

  Exemple:

    project:getTag('stream_name')
    project:getTag('stream_name',2,2)
--]]--
function lib:getTag(name, periode, time)
  local periode = periode or 1
  local time = time or 1

  for i,m in ipairs(self.models or {}) do
    if m.present(name) then
      m.periode = periode
      m.time = time
      return m[name]
    end
  end
end


--[[
  Set the tag value corresponding to the name, periode
  and time given.

  Exemple:

    project:setTag('tank_temp',85)
    project:getTag('tank_temp',85,2,2)
--]]--
function lib:setTag(name, value, periode, time)
  local periode = periode or 1
  local time = time or 1

  for i,m in ipairs(self.models or {}) do
    if m.present(name) then
      m.periode = periode
      m.time = time
      m[name] = value
      return m[name]
    end
  end
end




--[[
  Solve the project with Glpk by default and do graphs.

    local p1 = osmose.Project('LuaJam', 'MER')
    p1:load({cip = "ET.Cip"})
    p1:solve()

  To skip the graph generation :

    p1:solve({graph=false})

  To specify graph format :

    p1:solve({graph={format='svg'}})
--]]
function lib:solve(args)
  local args = args or {}

  -- prepare project for Eiampl
  local self = Eiampl(self)

  -- solve project
  if args.solver=='GLPK' or args.solver==nil then
    self = Glpk(self)
    setmetatable(self, lib)
  end

  -- write graph if necessary
  if args.graph~=false and self.solved==true then
    local format = nil
    if args.graph then
      format = args.graph.format
    end
    Graph(self,format)
  end
  
  -- Print the results
  if self.solved==true then
    PostPrint(self)
  end
  
  return self
end

--[[
  Launch mutlti objectives optimization.

  Exemple :

    project:optimize {
    software='dakota',
    precomputes={'jam_precompute'},
    objectives={'jam_rosenbrock'},
    -- variables={x1={model='cm1', tag='prod_2_flow', lower_bound='1800', uper_bound='2200', initial='2100'},
    --           x2={model='cm1', tag='prod_1_flow', lower_bound='800', uper_bound='1200', initial='900'}},
    variables={x1={lower_bound='-2', uper_bound='2', initial='-1'},
               x2={lower_bound='-2', uper_bound='2', initial='1'}},
    method='conmin_frcg',
    }
--]]
function lib:optimize(args)

  local ok, socket = pcall(require,"socket")
  if ok==false then
    print('Lua socket is not installed. Please install with this command :')
    print('luarocks install socket')
    os.exit()
  end

  local sourceDir = self.sourceDir
  local software = args['software']
  local cmd = ''
  local tmpDire = ''
  if software == nil then
    print('Yous must specify a software name for opimization.')
    return nil
  elseif software == 'dakota' then
    local dakota_helper = require 'osmose.helpers.dakotaHelper'

    -- create the directory that will run dakota
    tmpDir = ('./results/'..self.name..'/run_'..self.run..'/dakota')
    lub.makePath(tmpDir)

    -- prepare objective file for Dakota
    cmd = dakota_helper.prepareFiles(tmpDir,sourceDir, args)
    cmd = cmd .." > "..tmpDir.."/output.txt"
    cmd = cmd .." && lua "..tmpDir.."/stop.lua"
  end

  -- prepare project with Eiampl
  local project = Eiampl(self)

  print(lub.plat())
  if lub.plat() == 'macosx' or lub.plat() == 'linux' then
    os.execute "lsof -t -i  tcp:3333 | xargs kill"
  end
  local server = assert(socket.bind("*", 3333))


  local dakota_output = assert(io.popen(cmd,"w"))
  

  function listen(server, tmpDir, project)
    local client = server:accept()
    client:settimeout(10)
    local line, err, partial = client:receive("*l")
    --print('listen', line, err, partial)
    if line=="stop" or partial=="stop" then
      print("Optimization finished")
      print("Result direcory is", tmpDir)
      client:close()
      server:close()
      return "stop"
    end
    --print('LINE',line)
    local rslt = lib.call(project,line)
    --print('result', rslt)
    if rslt then 
      client:send(rslt.."\n")
      client:close()
    else
      client:close()
    end
  end

  while true do
    if listen(server,tmpDir, project) == "stop" then break end
  end

end

--[[
  Lauch post compute function, which must writen in a lua file 
  with the same name.

  Exemple:
    fonction:  jam_postcompute
    file: jam_postcomplute.lua

    project:postCompute('jam_postcompute') 

--]]
function lib:postCompute(name)
  if self.sourceDir == nil then
    local sourcePath = debug.getinfo(2).source:sub(2)
    self.sourceDir = sourcePath:match("(.*[/\\])")
  end

  local full_path = (self.sourceDir or "")..name..".lua"
  if  io.open(full_path) == nil then  
    return nil
  end

  local fct = loadfile(full_path)()

  return _G[name](self)
end

-- Private method.
function lib:call(str)
  --print('CALL',str)
  -- Serpent is used for serializing results
  local ok, serpent = pcall(require ,'serpent')
  if ok==false then 
    print('serpent is not installed. Please install it :')
    print('luarocks install serpent')
    os.exit()
  end

  if str==nil or str=='' then return serpent.dump(nil) end


  -- Split arguments between comma (',')
  local str = lub.strip(str)
  local args = lub.split(str,',')
  --if table.getn(args) <=1 then return serpent.dump(nil)  end

  -- First arg is the project function (getTag, getUnit, getStream,...)
  local fct = lub.strip(args[1])
  -- Second arg is the name of the object (tag, unit, stream,...)
  local name = args[2]

  local result = nil

  -- Call the function and return result in string for socket communication.
  if fct == 'getTag' then
    local periode = tonumber(args[3] or '1')
    local time = tonumber(args[4] or '1')
    result = lib.getTag(self,name, periode, time)
    if type(result) == 'function' then
      result = result()
    end
  elseif fct == 'setTag' then
    local value = tonumber(args[3]) or args[3]
    local periode = tonumber(args[4] or '1')
    local time = tonumber(args[5] or '1')
    result = lib.setTag(self,name, value, periode, time)
  elseif fct == 'getStream' then
    local periode = tonumber(args[3] or '1')
    local time = tonumber(args[4] or '1')
    local stream = lib.getStream(self, name, periode, time)
    if stream then
      result = stream:freeze(periode,time)
    end
  elseif fct == 'getUnit' then
    local periode = tonumber(args[3] or '1')
    local time = tonumber(args[4] or '1')
    local unit = lib.getUnit(self, name, periode, time)
    if unit then
      result = unit:freeze(periode,time)
    end
  elseif fct == 'solve' then
    print('Solving with GLPK...')
    Glpk(self)
    result = true
    --Graph(self, {format='svg'})
  else
    result =  nil
  end

  return serpent.dump(result)
end


return lib