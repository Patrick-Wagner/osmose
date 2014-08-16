package.path = './lib/?/init.lua;./lib/?.lua;'..package.path
local osmose = require 'osmose'
local lut    = require 'lut'


local should = lut.Test 'osmose.Project'

function initProject()
	local p1 = osmose.Project('LuaJam', 'MER')
	p1:load({cip = "ET.Cip"})
	local Eiampl = require 'osmose.Eiampl'
	return Eiampl(p1)
end

function should.createNewObject()
	local p1 = osmose.Project('LuaJam', 'MER')
	assertEqual('LuaJam', p1.name)
end

function should.loadModules()
	local p1 = osmose.Project('LuaJam', 'MER')
	p1:load({cip = "ET.Cip"})
	assertEqual(1, table.getn(p1.models))
end

function should.loadPeriode()
	local p1 = osmose.Project('LuaJam', 'MER')
	local periode=p1:periode(2)
	assertEqual(1, periode.times)
	assertNil(p1.periodes[3])
end

function should.loadTimes()
	local p1 = osmose.Project('LuaJam', 'MER')
	assertEqual(1, p1.periodes[1].times)
	p1:periode(2):time(4)
	p1:periode(3):time(6)
	assertEqual(4, p1.periodes[2].times)
	assertEqual(6, p1.periodes[3].times)
end

function should.solve()
	local p1 = osmose.Project('LuaJam', 'MER')
	p1:load({cip = "ET.Cip"})
	local solution = p1:solve()

	assertEqual(p1, solution)
end

function should.getStream()
	local p1=initProject()

	local s = p1:getStream('dot_cold')
	assertEqual('dot_cold', s.shortName)

	s=p1:getStream('LuaJam_cip_CipUnit_dot_cold')
	assertEqual('LuaJam_cip_CipUnit_dot_cold', s.name)

	assertNil(p1:getStream('dot_cold',2))
end

function should.getUnit()
	local p1=initProject()

	local u = p1:getUnit("CipUnit")
	assertEqual('CipUnit', u.shortName)

	u = p1:getUnit("LuaJam_cip_CipUnit")
	assertEqual('LuaJam_cip_CipUnit', u.name)
end

function should.getTag()
	local p1=initProject()

	local tag = p1:getTag('tank_temp')
	assertEqual(85, tag)

	tag = p1:getTag('raw_water_flow')
	assertEqual(5, tag())

	assertEqual( 40, p1:getTag('cleaning_agent_load')(),1)

	assertNil(p1:getTag('nothing'))

	assertEqual(85, p1.getTag(p1, 'tank_temp'))
end




function should.setTag()
	local p1=initProject()

	local tag = p1:setTag('tank_temp', 75)
	assertEqual(75, tag)

	tag = p1:setTag('foo', 1)
	assertNil(tag)
end

function should.call()
	local p1=initProject()

	local val = p1:call("getTag,tank_temp")
	assertEqual(85, val)

	val = p1:call("getTag,raw_water_flow")
	assertEqual(5, val())

	val = p1:call("setTag,tank_temp, 70")
	assertEqual(70, val)
end

function should.callWithNilValue()
	local p1=initProject()

	local val = p1:call("")
	assertNil(val)

	val=p1:call()
	assertNil(val)

	val=p1:call("getTag")
	assertNil(val)


	val=p1:call("getTag,foo")
	assertNil(val)
end

function should.optimize()
	local p1 = initProject()

	assertNil(p1:optimize({}))
end

function should.postCompute()
	local p1 = initProject()

	assertNil(p1:postCompute(""))
end

should:test()