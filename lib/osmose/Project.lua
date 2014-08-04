--[[---------------------------------------
  
  # Project

  Create an Osmose Project that specify an objective, load the ET models
  and indicate the periode and time cycle.

--]]---------------------------------------

local lub   = require 'lub'
local lib   = lub.class 'osmose.Project'
local lfs = require "lfs"


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


    local helper = require 'osmose.helpers.projectHelper'
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
  local Eiampl = require 'osmose.Eiampl'
  local Glpk   = require 'osmose.Glpk'
  local Graph  = require 'osmose.Graph'

  local self = Eiampl(self)

  if args.solver=='GLPK' or args.solver==nil then
    Glpk(self)
  end

  if args.graph~=false and self.solved==true then
    local format = nil
    if args.graph then
      format = args.graph.format
    end
    Graph(self,format)
  end

  return self
end

return lib