package.path = './lib/?/init.lua;./lib/?.lua;'..package.path
local osmose = require 'osmose'
local lut    = require 'lut'


local should = lut.Test 'osmose.Project'

function should.createNewObject()
	p1 = osmose.Project('LuaJam', 'MER')
	assertEqual('LuaJam', p1.name)
end

function should.loadModules()
	p1 = osmose.Project('LuaJam', 'MER')
	p1:load({cip = "ET.Cip"})
	assertEqual(1, table.getn(p1.models))
end

function should.loadPeriode()
	p1 = osmose.Project('LuaJam', 'MER')
	local periode=p1:periode(2)
	assertEqual(1, periode.times)
	assertNil(p1.periodes[3])
end

function should.loadTimes()
	p1 = osmose.Project('LuaJam', 'MER')
	assertEqual(1, p1.periodes[1].times)
	p1:periode(2):time(4)
	p1:periode(3):time(6)
	assertEqual(4, p1.periodes[2].times)
	assertEqual(6, p1.periodes[3].times)
end


should:test()