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
    if self.sourceDir == nil then
        local sourcePath = debug.getinfo(2).source:sub(2)
        self.sourceDir = sourcePath:match("(.*[/\\])")
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
  if name==nil then return nil end
  local periode = periode or 1
  local time = time or 1
  local tag_name = nil
  local model_name = nil

  local splited = lub.split(name,'%.')
  if table.getn(splited) == 2 then
    model_name = splited[1]
    tag_name = splited[2]
  else
    tag_name = name
  end

  for i,m in ipairs(self.models or {}) do
    if (model_name==nil or m.name==model_name) and m.present(tag_name) then
      m.periode = periode
      m.time = time
      return m[tag_name]
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
  if name==nil or value==nil then return nil end

  local periode = periode or 1
  local time = time or 1
  local tag_name = nil
  local model_name = nil

  local splited = lub.split(name,'%.')
  if (model_name==nil or m.name==model_name) and table.getn(splited) == 2 then
    model_name = splited[1]
    tag_name = splited[2]
  else
    tag_name = name
  end

  local found = false
  for i,m in ipairs(self.models or {}) do
    if (model_name==nil or m.name==model_name) and m.present(tag_name) then
      m.periode = periode
      m.time = time
      m[tag_name] = value
      found = true
    end
  end
  if found then return value end
end

--[[
  Parse, check and prepare ET models.

    p1:eiampl()
--]]
function lib:eiampl()
  return Eiampl(self)
end

--[[
  Call GLPK solver. See osmose.Glpk class for details

    p1:glpk()
--]]
function lib:glpk()
  local self = Glpk(self)
  setmetatable(self, lib)
  return self
end

--[[
  Call graph with format and options. See osmose.Graph class for details.
    
    project:graph('png')
--]]
function lib:graph(format,options)
  return Graph(self,format,options)
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
    precomputes={'S_problem_MOO_precompute'},
    objectives={'S_problem_MOO_postcompute1'},
    objectives_size=2,
    variables={x1={lower_bound='0', upper_bound='1.0', initial='0.5'},
               x2={lower_bound='0', upper_bound='1.0', initial='0.5'}},
    method={name = 'moga', max_iterations=100},
    }
--]]
function lib:optimize(args)

  local socket = lib.requireSocket()

  if self.sourceDir == nil then
    local sourcePath = debug.getinfo(2).source:sub(2)
    self.sourceDir = sourcePath:match("(.*[/\\])")
  end
  local sourceDir = self.sourceDir


  local software = args['software']
  local cmd = ''
  local tmpDir = ''
  if software == nil then
    print('You must specify a software name for opimization.')
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

  local server = assert(socket.bind("*", 3333))

  print('Dakota command is', cmd)
  local file = assert(io.popen(cmd,"w"))

  lib.privateListen(project,server)

  print("Optimization finished")
  print("Result direcory is", tmpDir)

end



function lib:listen()
  local socket = lib.requireSocket()

  local server = assert(socket.bind("*", 3333))

  lib.privateListen(self, server,'json')

end


--[[
  Lauch post compute function, which must writen in a lua file 
  with the same name.

  Exemple:
    fonction:  jam_postcompute
    file: jam_postcomplute.lua

    project:compute('jam_postcompute') 

--]]
function lib:compute(name)
  if self.sourceDir == nil then
    local sourcePath = debug.getinfo(2).source:sub(2)
    self.sourceDir = sourcePath:match("(.*[/\\])")
  end

  local baseName, ext = name:match("([%w_]+)%.?([%w_]*)")

  ext = ext or 'lua'

  if ext=='lua' and baseName ~= nil then 
    local full_path = (self.sourceDir or "")..baseName.."."..ext
    if  io.open(full_path) == nil then  
      return nil
    end

    local fct = loadfile(full_path)()

    return _G[baseName](self)

  elseif ext=="rb" then
    print("Call ruby file")
    local ruby_helper = require 'osmose.helpers.rubyHelper'

    local socket = lib.requireSocket()

    local server = assert(socket.bind("*", 3333))

    local cmd = ruby_helper.prepareCompute(self.dirRun,self.sourceDir,baseName)
    print("ruby command is",cmd)

    local file = assert(io.popen(cmd,"w"))

    lib.privateListen(self, server,'json')

  elseif ext=='m' then
    print("Call matlab file")

    local socket = lib.requireSocket()

    local matlab_helper = require 'osmose.helpers.matlabHelper'

    local socket = lib.requireSocket()

    local server = assert(socket.bind("*", 3333))

    local cmd = matlab_helper.prepareCompute(self.dirRun,self.sourceDir,baseName)
    print("matlab command is",cmd)

    local file = assert(io.popen(cmd,"w"))

    lib.privateListen(self, server,'json')

  end

  return self
end

-- Private method.
function lib:call(str,encoding)

  local _encode

  if encoding == 'serpent' or encoding == nil then 
    -- Serpent is used for serializing results
    local ok, serpent = pcall(require ,'serpent')
    if ok==false then 
      print('serpent is not installed. Please install it :')
      print('luarocks install serpent')
      os.exit()
    end
    -- print('Encoding with Serpent.')
    _encode = function(value) return serpent.dump(value) end

  elseif encoding == 'json' then
    local json = (loadfile "./lib/osmose/helpers/json.lua")()
    -- print('Encoding with JSON.')

    _encode = function(value) 
      --print(serpent.dump(value))
      return json:encode(value) 
    end
  end

  if str==nil or str=='' then return _encode(nil) end

  -- Split arguments between comma (',')
  local str = lub.strip(str)
  local args = lub.split(str,',')
  --if table.getn(args) <=1 then return serpent.dump(nil)  end

  -- First arg is the project function (getTag, getUnit, getStream,...)
  local fct = lub.strip(args[1])
  -- Second arg is the name of the object (tag, unit, stream,...)
  local name = args[2]

  local result = nil
  --print('FCT', fct)

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
    local self = Eiampl(self)
    Glpk(self)
    setmetatable(self, lib)
    result = true
  elseif fct == 'getResults' then
    result = self.results
  else
    result =  nil
  end

  return _encode(result)
end

-- Private method.
function lib.privateListen(project,server,encoding)
  -- if lub.plat() == 'macosx' or lub.plat() == 'linux' then
  -- os.execute "lsof -t -i tcp:3333 | xargs kill"
  -- end
  --print('Startin listening...')
  while true do
    print('Listen to port 3333')

    local client = server:accept()
    local line, err, partial = client:receive("*l")
    --print('receive', line, err, partial)
    if line=="stop" or partial=="stop" then
      print("Closing port 3333")
      client:close()
      server:close()
      return "stop"
    end
    if err then
      client:close()
      print(err)
    end
    --print('LINE',line)
    local rslt = lib.call(project,line,encoding)
    --print('result', line, rslt)
    if rslt then 
      client:send(rslt.."\n")
      client:close()
    else
      client:send("nil\n")
      client:close()
    end
  end
end

-- private method
function lib.requireSocket() 
 local ok, socket = pcall(require,"socket")
  if ok==false then
    print('Lua socket is not installed. Please install with this command :')
    print('luarocks install socket')
    os.exit()
  end

  return socket
end


return lib