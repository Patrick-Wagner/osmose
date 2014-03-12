package.path = './lib/?/init.lua;./lib/?.lua;'..package.path
local osmose = require 'osmose'
local lut    = require 'lut'

local should = lut.Test 'osmose.Eiampl'

function table.find(streams,name)
	for i,stream in ipairs(streams) do
		if stream.name and string.find(stream.name, name) then
			return stream
		end
	end
end


function should.returnProject()
	local project = osmose.Project('Test')
	local eiampl = osmose.Eiampl(project)

	assertEqual(project, eiampl)
end

function should.initUnits()
	local lib = osmose.Model 'TEST'
	lib:addUnit("unit", {type = 'Process'})

	local p=osmose.Project('project')
	p:load({test = lib})

	local eiampl = osmose.Eiampl(p)

	assertEqual('project_test_unit', eiampl.units[1][1].name)
end

function should.initStreams()
	local lib = osmose.Model 'TEST'
	lib:addUnit("unit", {type = 'Process'})
	lib["unit"]:addStreams({  
  	stream1 =  { 20, 0, 80,800,3,1},
  	stream2 =  { 80, 800, 20, 0,3,1},

  	stream_dot1 = { 80, 0, 80,800,3,1},
  	stream_dot2 =  { 80, 800, 80, 0,3,1},

  	stream_bug = { 80, 0, 20,800,3,1},
	})

	local p=osmose.Project('project')
	p:load({test = lib})

	local eiampl = osmose.Eiampl(p)
	local streams = eiampl.units[1][1].streams

	-- Test stream name
	assertEqual('project_test_unit_stream1', table.find(streams, 'stream1').name)

	-- Test isHot()
	assertEqual(false,	table.find(streams, 'stream1').isHot())
	assertEqual(true, 	table.find(streams, 'stream2').isHot())

	-- Test when stream is a dot
	assertEqual(false,	table.find(streams, 'stream_dot1').isHot())
	assertEqual(true, 	table.find(streams, 'stream_dot2').isHot())

	-- Test when stream is inconsistent
	assertEqual(nil, 	table.find(streams, 'stream_bug').isHot())
end

function should.initMassStreamsWithOneLayer()
	local lib = osmose.Model 'TEST1LAYER'
	lib.inputs = {p2 = {default = 10, 	unit = 'kW'},}
  lib:addLayers {electricity = {type='MassBalance', unit='kW'}}
  lib:addUnits {u1 = {type='Utility', Fmax=100,  Cost2=30}}
  lib["u1"]:addStreams {hot_uti   = qt{1600-273,1400,1550-273,0,10} , power = ms({'electricity', 'out', 'p2'}) }
  
  local p=osmose.Project('project','OperatingCost')
	p:load({test = lib})
	local eiampl = osmose.Eiampl(p)
	local ms = eiampl.units[1][1].massStreams[1]
	assertEqual('project_test_u1_power', ms.name )
	assertEqual(10, ms.value )
	assertEqual('electricity', ms.layerName)
	assertEqual('out', ms.inOut)
end

function should.initMassStreamsWithSeveralLayers()
	local lib = osmose.Model 'TEST2LAYER'
	lib:addLayers {electricity = {type='MassBalance', unit='kW'}}
	lib:addLayers {wood = {type='MassBalance', unit='kW'}}
	lib:addUnits {u1 = {type='Utility', Fmax=100,  Cost2=30}}
	lib["u1"]:addStreams { power = ms({'electricity', 'out', 10}), cons = ms({'wood', 'in', 20}) }
	local p=osmose.Project('project','OperatingCost')
	p:load({test = lib})
	local eiampl = osmose.Eiampl(p)
	local ms = eiampl.units[1][1].massStreams[2]
	assertEqual('project_test_u1_cons', ms.name )	
	assertEqual('wood', ms.layerName)
end

function should.notInitUnitIfAddToProblemIsZero()
	local lib = osmose.Model 'TEST'
	lib:addUnit("unit1", {type = 'Process', addToProblem = 0})
	lib:addUnit("unit2", {type = 'Utility', addToProblem = 0})
	lib["unit2"]:addStreams({ stream1 =  { 20, 0, 80,800,3,1} })

	local p=osmose.Project('project')
	p:load({test = lib})
	local eiampl = osmose.Eiampl(p)

	assertNil( eiampl.units[1][1])
end

function should.AddEquations()
  local lib = osmose.Model 'TEST'
  lib.jobs = {j1 = function() return 3-2 end}
  lib:addEquations {
  	eq0={statement="0.2*u1 + 0.8u2 = 1", addToProblem=0},
  	eq1={statement="0.2*u1 + 0.8u2 = 1", addToProblem=1},
  	eq2={statement="0.2*u1 + 0.8u2 = 1", addToProblem='j1'}
  }

  local p=osmose.Project('project')
  p:load({test = lib})

  local eiampl = osmose.Eiampl(p)

  assertType('string', eiampl.equations[1][1] )
  assertEqual(2, table.getn(eiampl.equations[1]))
end

function should.evalAddToProblem()
	local lib = osmose.Model 'TestAddToProblem'
	lib.jobs = { j1 = '2-1', j2 = function() return 2-1 end, j3 = '3-1'}
	lib:addUnit("add1", {type = 'Process', addToProblem = 'j1'})
	lib:addUnit("add2", {type = 'Utility', addToProblem = 'j2'})
	lib:addUnit("add3", {type = 'Process', addToProblem = 'j3'})


	local p=osmose.Project('project','YearlyOperatingCost')
	p:load({test = lib})
	local eiampl = osmose.Eiampl(p)

	assertEqual(2, table.getn(eiampl.units[1]))
end

should:test()