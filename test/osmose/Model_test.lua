--[[------------------------------------------------------

  # test osmose.Model

--]]------------------------------------------------------
package.path = './lib/?/init.lua;./lib/?.lua;'..package.path
local lut    = require 'lut'
local should = lut.Test 'osmose.Model'
local osmose = require 'osmose'


local function makeModel()
  -- Simple model definition
  local lib    = osmose.Model 'Heater'

  lib.inputs = {
    -- Initial water temperature.
    start_temp = {default = 10, min = 0, max = 100, unit = 'C'},

    -- Amount of water to heat.
    mass      = {default = 1, min = 0, unit = 'kg'}, 

    -- Specific heat of the liquid.
    specific_heat = {default = 4.1813, min = 0, max = 100, unit = 'kJ/(kg·K)'},

    -- Available energy for heating.
    heat = {default = 200, min = 0, unit = 'kJ' },
  }

  lib.outputs = {
    -- Liquid temperature after heating.
    final_temp = {unit = 'C', job = function()
      return start_temp + heat / (specific_heat * mass)
    end}
  }

  return lib
end

function should.createNewModel()
  local lib = makeModel()
  assertEqual('Heater', lib.type)
end


-- local default_job = Heater.jobs.default

function should.teardown()
  -- Revert to initial job definition
  -- Heater.jobs.default = default_job
end  

function should.compute()
  local model = require "ET.Cip" ('cip')
  assertEqual(116.11, model.discharge_load(), 0.01)
end

function should.markAsDirtyOnSet()
  local heater = makeModel() ('heater')

  assertEqual(57.83, heater.final_temp(), 0.01)

  heater:set {start_temp = 20 }

  assertNil(rawget(heater, 'final_temp'))
  assertEqual(67.83, heater.final_temp(), 0.01)
end

function should.markAsDirtyOnSetParam()
  local heater = makeModel() ('heater')

  assertEqual(57.83, heater.final_temp(), 0.01)

  heater.start_temp = 20 -- C
  assertNil(rawget(heater, 'final_temp'))
  assertEqual(67.83, heater.final_temp(), 0.01)
end



function should.cacheValues()
  local heater = makeModel() ('heater')

  -- Initial value copied in cache.
  assertEqual(10, heater.start_temp)
  -- assertEqual(10, rawget(heater._cache, 'start_temp'))
  -- assertNil(rawget(heater._cache, 'final_temp'))
  -- Compute
  -- assertEqual(57.83, heater.final_temp(), 0.01)
  -- assertEqual(57.83, rawget(heater._cache, 'final_temp'), 0.01)
end

function should.loadValueFromCSV()
  local helper = require "lib.osmose.helpers.modelHelper"
  local values = helper.loadValuesFromCSV('test/fixtures/CM2_inputs_multi_periodes.csv')
  assertEqual(3000, values.prod_1_flow[1][1])
  assertEqual(4000, values.prod_1_flow[2][1])
end

function should.loadValueFromODS()
  local helper = require "lib.osmose.helpers.modelHelper"
  local values = helper.loadValuesFromODS('test/fixtures/CIP_inputs.ods', nil)
  assertEqual(80, values.tank_temp[1][1])
  assertEqual(87, values.tank_temp[2][1])
end

function should.addEquations()
  local lib = osmose.Model 'TEST'
  lib:addEquations {eq="0.2*u1 + 0.8u2 = 1"}
  assertType('table', lib.equations.eq)
  assertEqual("0.2*u1 + 0.8u2 = 1", lib.eq.statement )
end

function should.addLayers()
  local lib = osmose.Model 'TEST'
  lib:addLayers {electricity = {type='MassBalance', unit='kW', addToProblem=1}}
  assertType('table', lib.layers.electricity)
  assertEqual('MassBalance', lib.electricity.type)
end

function should.addUnits()
  local lib = osmose.Model 'TEST'
  lib:addUnits {u1   = {type='Process', Fmax=1,  Cost2=10},
                u2   = {type='Utility', Fmax=100,  Cost2=30} }
  assertType('table', lib.utilities.u2)
  assertType('table', lib.processes.u1)

  assertEqual('Process', lib.u1.type)
  assertEqual('Utility', lib.u2.type)
end

function should.defineJobs()
  local lib = osmose.Model 'TEST'
  lib.jobs = {
    j1 = 2-1,
    j2 = '2-1',
    j3 = function() return 2-1 end,
    j4 = 3-1,
    j5 = '3-1'
  }
  assertEqual(1, lib.jobs.j1)
  assertEqual(1, lib.jobs['j1'])

  assertEqual(1, lib().j1())
  assertEqual(1, lib().j2())
  assertEqual(1, lib().j3())
  assertEqual(2, lib().j4())
  assertEqual(2, lib().j5())
end

function should.defineExternalModelsDirectly()
  local lib = osmose.Model 'TEST'
  local cip = require "ET.Cip" ()
  lib.inputs = {
    cip_tank_temp = {default = cip.tank_temp}
  }

  local model = lib('test')

  assertEqual(85, model.cip_tank_temp)
end

function should.defineExternalModelsIndirectly()
  local lib = osmose.Model 'TEST'
  local cip = require "ET.Cip" ()
  lib.models = {m1 = cip}
  lib.outputs = {
    cip_tank_temp = {job = 'm1.tank_temp'},
  }
  lib.inputs = {
    cip_return_temp = {inlet='m1.return_temp'}
  }

  local model = lib('test')
  assertEqual(85, model.cip_tank_temp())
  assertEqual(40, model.cip_return_temp())
end

should:test()

