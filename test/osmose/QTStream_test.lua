package.path = './lib/?/init.lua;./lib/?.lua;'..package.path
local osmose = require 'osmose'
local lut    = require 'lut'


local should = lut.Test 'osmose.QTStream'

function should.createNewObject()
	local qt1 = osmose.QTStream { 'cleaning_agent_temp', 0,'tank_temp','cleaning_agent_load',3, 'water_h'}
  local qt2 = osmose.QTStream { 'source_temp', 0,'tank_temp','fresh_water_load', 3,'water_h'} 
  local qt3 = osmose.QTStream { 'return_temp','discharge_load','max_temp', 0, 3, 'water_h'}

  assertEqual('cleaning_agent_temp', qt1.tin )
  assertEqual(0, qt2.hin )
  assertEqual('max_temp', qt3.tout )
  assertEqual('cleaning_agent_load', qt1.hout )
  assertEqual(3, qt2.dtmin)
  assertEqual('water_h', qt3.alpha)

  assertEqual('function', type(qt1.ftin))
end

function should.createTagFunctions()
  local qt1 = osmose.QTStream { 'cleaning_agent_temp', 0,'tank_temp','cleaning_agent_load',3, 'water_h'}
  local model = require "ET.Cip" ('cip')

  assertEqual(283, qt1.ftin(model))
end

function should.createTagFunctionsWithMultiPeriodes()
  local qt1 = osmose.QTStream { 'cleaning_agent_temp', 0,'tank_temp','cleaning_agent_load',3, 'water_h'}
  local model = require "ET.Cip" ('cip')
  model.loadValues('test/fixtures/CM2_inputs_multi_periodes.csv')
  model.time=1

  model.periode=1
  assertEqual(293, qt1.ftin(model))

  model.periode=2
  assertEqual(303, qt1.ftin(model))
end

function should.createTagFunctionsWithMultiTimes()
  local qt1 = osmose.QTStream { 'cleaning_agent_temp', 0,'tank_temp','cleaning_agent_load',3, 'water_h'}
  local model = require "ET.Cip" ('cip')
  model.loadValues('test/fixtures/CM2_inputs_multi_times.csv')
  model.periode=1

  model.time=1
  assertEqual(293, qt1.ftin(model))

  model.time=2
  assertEqual(303, qt1.ftin(model))
end

function should.addToProblem()
  local qt1 = osmose.QTStream { 'cleaning_agent_temp', 0,'tank_temp','cleaning_agent_load',3, 'water_h'}
  assertEqual(1, qt1.addToProblem)

  local qt2 = osmose.QTStream { 'cleaning_agent_temp', 0,'tank_temp','cleaning_agent_load',3, 'water_h'}
  qt2.addToProblem = 0
  assertEqual(0, qt2.addToProblem)
end

should:test()

