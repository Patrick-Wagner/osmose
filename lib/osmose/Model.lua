--[[------------------------------------------------------

  # Model

  Use this class to create new models. A model stores the
  energy technology definitions such as *inputs*, *outputs*
  and *processes*. A model does not store actual
  parameter values. The "model" is like a formula. You create
  instances of the model with specific parameter values to
  create an experiment.

  Model definition example:

    -- doc:lit
    local osmose = require 'osmose'
    local lib    = osmose.Model 'demo.Heater'

    lib.inputs = {
      -- Initial water temperature.
      start_temp = {default = 20, min = 0, max = 100, unit = 'C'},

      -- Amount of water to heat.
      mass      = {min = 0, unit = 'kg'}, 

      -- Specific heat of the liquid.
      specific_heat = {default = 4.1813, min = 0, max = 100, unit = 'kJ/(kg·K)'},

      -- Available energy for heating.
      heat = {min = 0, unit = 'kJ' },
    }

    lib.outputs = {
      -- Liquid temperature after heating.
      final_temp = {unit = 'C'},
    }

    lib.jobs = {
      -- Compute final temperature by using:
      -- [math]Q = C_p \times m \times dT[/math].
      default = function()
        final_temp = start_temp + heat / (specific_heat * mass)
      end,
    }

    return lib

  Model usage example:

    local demo = require 'demo'

    local heater = demo.Heater {
      start_temp = 10,  -- C
      mass       = 1,   -- kg
      heat       = 200, -- KJ
    }

    -- Using the output values triggers necessary computations.
    print(heater.final_temp)
    --> 57.83

  ## Model structure

  A model instance is defined as follows:

    #txt ascii
    +------------+     +--------+     +-----------+
    | instance   | --> | Heater | --> | model_api |
    |------------|     +--------+     +-----------+
    | cache      |
    +------------+

  The `cache` field contains computed values. The `model_api` enables
  functions on instance such as #set. Heater is an instance of osmose.Model
  with field definitions.

--]]------------------------------------------------------
local lub = require 'lub'
local lib = lub.class 'osmose.Model'
local private   = {}
-- Methods on model instances.
local model_api = {}
-- Methods on instance cache.
local cache_api = {}

-- Used for Lua 5.2 compatibility
local NO_FENV = not rawget(_G, 'setfenv')

-- Creates osmose model class `type`.
function lib.new(modelName)
  local class = lub.class(modelName)

  class.utilities = {}
  class.processes = {}
  class.software  = {}
  class.jobs      = {}
  class.layers    = {}
  class.equations = {}

  -- All public methods in model API are set here.
  class.__index    = model_api.__index

  class.__newindex = model_api.__newindex

  class.new = function(params)
    return model_api.new(class, params)
  end

--[[
  # Model API

  ## addUnit(name, type)

  Add units to the model. Must be Process or Utility.
  It'possible then to add streams to the unit.

  For exemple:

    local lib = osmose.Model 'Cip'
    lib:addUnit("CipUnit", {type = 'Process'})

    cip["CipUnit"]:addStreams({  
    cleaning_agent= { 'cleaning_agent_temp', 0,'tank_temp','cleaning_agent_load',3, 'water_h'},
    fresh_water   = { 'source_temp', 0,'tank_temp','fresh_water_load', 3,'water_h'},
    discharge     = { 'return_temp','discharge_load','max_temp', 0, 3, 'water_h'},
    })
--]]
  function class:addUnit(name, tbl)

    local unit = require('osmose.Unit')
    class[name] = unit(name, tbl)
    if tbl.type == 'Process' then
      class.processes[name] = class[name]
    elseif tbl.type == 'Utility' then
      class.utilities[name] = class[name]
    end
    
  end

--[[
  ## addUnits(units)

  Add mutliples units in one function like this :

    lib:addUnits {coldproc  = {type='Process', Fmax=1,  Cost2=10},
                hotproc   = {type='Process', Fmax=1,  Cost2=10},
                u1        = {type='Utility', Fmax=100,  Cost2=30},
                u2        = {type='Utility', Fmax=100,  Cost2=30},
                u3        = {type='Process', Fmax=1,  Cost2=0},
                u4        = {type='Process', Fmax=1,  Cost2=0}}
--]]  
  function class:addUnits(units)
    for name,args in pairs(units) do
      class:addUnit(name,args)
    end
  end

--[[
  ## addLayers(layers)

  Add layers to model :

    lib:addLayers {electricity = {type='MassBalance', unit='kW'}}
--]]
  function class:addLayers(layers)
    local layer = require('osmose.Layer')
    for name, args in pairs(layers) do
      class[name] = layer(name, args)
      class.layers[name] = class[name]
    end
  end

--[[
  ## addEquations(equations)

  Add equations to model :
    lib:addEquations {eq_1 = "-1*u2 + 1*u4 <= 0"}
  or 
    lib:addEquations {eq_2 = { statement = "-1*u2 + 1*u4 <= 0", addToProblem=1 } }

--]]
  function class:addEquations(equations)
    for name, args in pairs(equations) do
      if type(args) == 'string' then
        class[name] = {statement = args, addToProblem=1}
        class.equations[name] = {statement = args, addToProblem=1}
      elseif type(args) == 'table' then
        if args.statement then
          class[name] = args
          class.equations[name] = args
        else
          print(string.format('Table argument for equation %s should have a `statement` key.', name))
          os.exit()
        end
      else
        print(string.format('Argument for equation %s is not recognized.', name))
        os.exit()
      end
    end
  end

--[[
  ## Allowed tables

    lib.inputs    = {tank_temp = {default = 85, min = 80, max = 90, unit = 'C'}}

    lib.outputs   = {raw_water_flow = {unit = 't/h', job = "(raw_water_rate/100) * distributed_water_flow" }}

    lib.values    = {air_cp=1.007}

    lib.advanced  = {max_temp = {default = 20, min = 0, max = 100, unit = 'C'}}

--]]
  class.inputs  = {}
  class.outputs = {}
  class.values = {}
  class.advanced = {}


  class.set = model_api.set

	return class
end



--=============================================== MODEL API
-- # Instance API
--
--
-- This method is called to fetch values in the cache or compute them
-- as needed when accessing a model instance:
--
--   local heater = Heater {...}
--   print(heater.final_temp) -- Calls this method to solve value.

function model_api:__index(key)
  local class = getmetatable(self)
  local cache = rawget(self, '_cache')
  local mpt   = rawget(cache,'_mpt')

  -- mpt is for Multi Periode and Time. Value is index by periode and time. 
  -- For exemple, value for time 4 in periode 2 is mpt[4][2].
  -- Value are stored in the _mtp table of the cache. 
  -- The periode and time must be saved in the instance of the model (self) before retrieving the value.
  if rawget(mpt, key) then
    return rawget(mpt, key)[self.periode][self.time] or rawget(mpt, key)[self.periode][1]
  else
    return rawget(cache, key) or rawget(class, key) or cache[key]
  end

end

-- When setting a value, store the value in the cache and clear computed output values.
-- function lib:__newindex(key, value)
function model_api:__newindex(key, value)
  -- clear output values
  model_api.clear(self)
  self._cache[key] = value
end

-- Set new parameters (this clears the cached output values).
-- function lib:set(params)
function model_api:set(params)
  local cache = self._cache
  -- clear output values
  model_api.clear(self)

  for k, v in pairs(params) do
    cache[k] = v
  end
end

-- Clear output parameters (remove values from cache).
-- function lib:clear(params)
function model_api:clear()
  local cache = self._cache
  if not cache._cleared then
    for k, v in pairs(self.outputs) do
      cache[k] = nil
    end
    cache._cleared = true
  end
end

function model_api.new(class, params)
  local self = {
    -- This is set to true once input default values have been added to
    -- defined inputs.
    _parsed_defaults = false
  }

  local cache = {
    _self    = self,
    _cleared = true,
    _in_job  = false,
  }
  self._cache = cache

  setmetatable(self, class)
  setmetatable(cache, cache_api)

  if type(params) == 'table' then
    model_api.set(self, params)
  elseif type(params) == 'string' then
    cache.name = params
  end

  class.toto = function()
    return 'toto'
  end

  class.get = function(key)
    if class[key] and type(class[key])=='table' then
      local values={}
      for k,v in pairs(class[key]) do
        values[k] = v
      end
      return values
    elseif cache[key] then
      return cache[key]
    else
      return nil
    end
  end

  -- Return true if the key is present in the model.
  class.present = function(key)
    return class[key] or class.inputs[key] or class.outputs[key] or class.advanced[key] or class.values[key]
  end

  -- The multi periodes and times values will be stored here.
  cache._mpt = {}

  -- Load the input values from an external file.
  class.loadValues = function(path)
    local helper = require "osmose.helpers.modelHelper"
    local values
    if path and path:find('.csv') then
      values = helper.loadValuesFromCSV(path)
    elseif path and path:find('.ods') then
      values = helper.loadValuesFromODS(path,self.name)
    end

    for key, tbl in pairs(values) do
      if class.inputs[key] then
        cache._mpt[key] = tbl
      end
    end

  end

  class.generateData = function(periodes, times, fullPath)
    local f=(io.open(fullPath, "w"))
    
    for name,input in pairs(class.inputs) do
      for periode=1, periodes do
        f:write(name..',')
        for time=1, times do
          local value = math.random((input.min or input.default), (input.max or input.default))
          f:write(value..',')
        end
        f:write("\n")
      end
    end
   
    f:close()
    return nil
  end

  return self
end

function model_api.__call(class, ...) return class.new(...) end

--=============================================== CACHE API
-- # Solver API
--
-- Methods used during job execution or cache query.
-- 
-- This is called when trying to access `nil` keys in the cache. It is the
-- `__index` method of the cache's metatable.
function cache_api.__index(cache, key)

  local self = rawget(cache, '_self')
  local mpt = cache._mpt

  if mpt[key] then
    if mpt[key][self.periode] then
      return (mpt[key][self.periode][self.time] or mpt[key][self.periode][1])
    end
  end



  -- if not self._parsed_defaults then
  --   private.parseDefaults(self)
  -- end

  -- Global values are passed through during job execution.
  if cache._in_job then
    local v = _G[key]
    if v ~= nil then return v end
  end
  
  local class = getmetatable(self)

  -- Try to look in values params
  local value = class.values[key]
  if value then 
    return value
  end

  -- Try to look in inputs params 
  local input = class.inputs[key]
  if input then
    return input.value or input.default
  end

  -- Try to look in advenced params
  local advanced = class.advanced[key]
  if advanced then
    return advanced.value or advanced.default
  end

  local job = class.jobs[key]
  if type(job) == 'number' then
    return function() return job end
  elseif type(job) == 'string' then
    local fct = string.format("return %s ", job)
    return assert(loadstring(fct))
  elseif type(job) == 'function' then
    return job
  end
  
  -- This is an output, solve value.
  local def = class.outputs[key]
  if not def then
    return nil
    -- error(string.format(
    --   "Trying to access unknown parameter '%s' in '%s'.", key, self.type
    -- ))
  end

  local job = def.job

  if type(job) == 'string' then
    --job = class.jobs[job]
    local fct = string.format("return %s ", job)
    job = assert(loadstring(fct))

    if not job then
      error(string.format(
        "Could not find job '%s' in '%s'.", def.job, self.type
      ))
    end
  elseif not job then
    job = class.jobs.default
    if not job then
      error(string.format(
        "Could not find tag '%s' in '%s'.",key, self.type
      ))
    end
  end
  --self._cache[key] = private.executeJob(self, job)

  -- variable should now be in cache
  --v = rawget(cache, key)
  -- if v == nil then
  --   error(string.format(
  --     "Running job did not resolve '%s' in '%s'.", key, self.type
  --   ))
  -- end

  return private.executeJob(self, job)
end


--=============================================== PRIVATE


-- Add default values to cache.
function private:parseDefaults()
  local cache = self._cache
  local mpt = cache._mpt
  for k, def in pairs(self.inputs) do
    if rawget(cache, k) == nil and rawget(mpt,k) then
      cache[k] = def.value or def.default
    end
  end
  self._parsed_defaults = true
end

-- Execute a job to solve output values.
function private:executeJob(job)

  local cache = self._cache
  cache._in_job  = true
  cache._cleared = false
  -- jobs are executed in "self" env.
  if NO_FENV then
    local _ENV = cache
    local job = job()
  else
    setfenv(job, cache)
    local job = job()
  end
  cache._in_job = false

  return job
end

return lib
