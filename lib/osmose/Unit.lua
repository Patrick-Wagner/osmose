--[[------------------------------------------------------
  
  # Unit

  Use this class to create Process or Utility in ET models.

  Exemple :

    local osmose = require 'osmose'
    local lib = osmose.Model 'CookingMixing'

    lib:addUnit("CMUnit", {type = 'Process'})

    cip["CMUnit"]:addStreams({  
      cleaning_agent = qt { 'cleaning_agent_temp', 0,'tank_temp','cleaning_agent_load',3, 'water_h'},
      fresh_water = qt { 'source_temp', 0,'tank_temp','fresh_water_load', 3,'water_h'},
    })

--]]------------------------------------------------------
local lub   = require 'lub'
local lib   = lub.class 'osmose.Unit'
local helper = require 'osmose.helpers.tagHelper'

-- Add by default to problem
lib.addToProblem = 1

-- Metatable function.
lib.__index = function(tbl, key)
  return lib[key] or tbl.streams[key]
end

--[[
  Create unit of type Process or Utility.

  Exemple :

    local osmose = require 'osmose'

    local u1 = osmose.Unit('unit1',{type='Process'})
    local u2 = osmose.Unit('unit2',{type='Utility'})

--]]--
function lib.new(name, args)
  if args.type ~= 'Process' and args.type ~= 'Utility' then
    print('Unit type should be either Process or Utility:',name, args.type)
    os.exit()
  end

  local unit = lub.class(args.type)
  setmetatable(unit, lib)

  unit.name       = name
  unit.streams    = {}
  
  for key, val in pairs(args) do
    unit[key]=val
  end

  -- Fmin and Fmax are equal to the unit.Mult If the user defines the unit.Mult
  -- for a process in project definition, otherwise they are equal to 1
  if unit.type == 'Process' then
    unit.Fmin = unit.Mult or 1
    unit.Fmax = unit.Mult or 1
  else
    unit.Fmin = unit.Fmin or 0
    unit.Fmax = unit.Fmax or 10000
  end

  unit.fFmax   = helper.initTag(unit,'Fmax')
  unit.fFmin   = helper.initTag(unit,'Fmin')

  return unit
end

--[[
  Add streams to a Unit.

  This exemple add a QT stream named 'stream1'

    local osmose = require 'osmose'
    local u1 = osmose.Unit('unit1',{type='Process'})

    u1:addStreams( {stream1 = { 'return_temp','discharge_load','max_temp', 0, 3, 'water_h'}})

  This exemple add a HT stream :

    u1:addStreams({ stream2 = ht{
      tin   = 1750,
      tout  = {730,700,650,638,603,570,558,420,385,345}, 
      hin   = {300,300,300,300,300,300,300,300,300,300},
      hout  = {0,0,0,0,0,0,0,0,0,0},
      dtmin = 5}  })

  The streams can be QTStream, HTStream or MassStream. By default, it's a QTStream. There is
  shortcuts for each of one : ht(), ms() and qt()

--]]--
function lib:addStreams(tbl)
  if tbl then
    local qt   = require('osmose.QTStream')
    for name,values in pairs(tbl) do
      if values.type=='QTStream' then
        self.streams[name] = values
      elseif values.type=='MassStream' then
        self.streams[name] = values
      elseif values.type=='HTStream' then
        for i, stream in ipairs(values) do
          local HTname = name..i
          self.streams[HTname] = stream
        end
      else
        self.streams[name] = qt(values)
      end
    end
  else
    return {}
  end

end

return lib