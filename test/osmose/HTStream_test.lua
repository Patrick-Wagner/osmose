package.path = './lib/?/init.lua;./lib/?.lua;'..package.path
local osmose = require 'osmose'
local lut    = require 'lut'


local should = lut.Test 'osmose.HTStream'

local ht = osmose.HTStream { 
		1750, -- tin 
		{300,300,300,300,300,300,300,300,300,300}, -- hin
		{730,700,650,638,603,570,558,420,385,345}, -- tout
		{0,0,0,0,0,0,0,0,0,0},  -- hout
		5 -- dtmin
	}

local ht2 = osmose.HTStream {
	tin 	= 1750,
	tout 	= {730,700,650,638,603,570,558,420,385,345}, 
	hin 	= {300,300,300,300,300,300,300,300,300,300},
	hout 	= {0,0,0,0,0,0,0,0,0,0},
	dtmin = 5
}

function should.createNewObject()
	assertEqual('table', type(ht))
end

function should.createWithNamedParams()
	assertEqual('HTStream', ht2.type)
end

function should.callMetatable()
	local ht = osmose.HTStream {1750, {300}, {730}, {0}, 5}
	assertEqual('HTStream', ht.type)
end

function should.createSingleStream()
	local ht = osmose.HTStream {{1750}, {300}, {730}, {0}, {5}}
	assertEqual('HTStream', ht.type)
	assertEqual(1750, ht[1].tin)
	assertEqual(5, ht[1].dtmin)
end

function should.returnQTStreams()
	assertEqual('QTStream', ht[1].type)
	assertEqual(1750, ht[1].tin)
	assertEqual(730, ht[1].tout)
	assertEqual(0, ht[1].hout)
	assertEqual(5, ht[1].dtmin)
end

function should.unitAddHTstreams()
	local unit = osmose.Unit('unit2',{type='Utility'})
	unit:addStreams{ht = ht}

	assertEqual('QTStream',unit.streams.ht1.type)
	assertEqual('QTStream',unit.streams.ht10.type)
end


should:test()