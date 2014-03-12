package.path = './lib/?/init.lua;./lib/?.lua;'..package.path
local osmose = require 'osmose'
local lut    = require 'lut'


local should = lut.Test 'osmose.Unit'

function should.createNewObject()
	local u1 = osmose.Unit('unit1',{type='Process'})
	local u2 = osmose.Unit('unit2',{type='Utility'})
	assertEqual('unit1',u1.name)
	assertEqual('unit2',u2.name)
	assertEqual('Process',u1.type)
	assertEqual('Utility',u2.type)
end

function should.addStreams()
	local u1 = osmose.Unit('unit1',{type='Process'})
	u1:addStreams( {stream1 = { 'return_temp','discharge_load','max_temp', 0, 3, 'water_h'}})
	assertEqual('QTStream', u1.streams.stream1.type)
end

function should.addToProblem()
	local u1 = osmose.Unit('unit1', {type='Process', addToProblem=0})
	assertEqual(0, u1.addToProblem)
	local u2 = osmose.Unit('unit2', {type='Process'})
	assertEqual(1, u2.addToProblem)
end

function should.accessToStreamDirectly()
	local u1 = osmose.Unit('unit1',{type='Process'})
	u1:addStreams( {stream1 = { 'return_temp','discharge_load','max_temp', 0, 3, 'water_h'}})
	assertEqual('QTStream', u1.stream1.type)
end

should:test()

