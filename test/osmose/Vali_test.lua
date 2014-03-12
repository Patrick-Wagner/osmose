package.path = './lib/?/init.lua;./lib/?.lua;'..package.path
local osmose = require 'osmose'
local lut    = require 'lut'

local should = lut.Test 'osmose.Vali'
local model = require "ET.Evap" ('test')
local dirTmp = ('./test/tmp/')
local blsFile = 'evap.bls'

function makeVali()
	return osmose.Vali(model, dirTmp, blsFile)
end

function should.createNew()
	local vali = makeVali()
	assertEqual(model, vali.model)
	assertEqual('./test/tmp/', vali.dirTmp)
	assertEqual('evap.bls', vali.blsFile)
end

function should.copyBlsFile()
	local vali = makeVali()
	vali:copyBlsFile()
	assert(io.open(dirTmp..blsFile,"r"))
end

function should.execute()
	local vali = makeVali()
	local status = vali:execute()
	assertEqual(0,status)
end

function should.generateMeaFile()
	local vali = makeVali()
	vali:generateMeaFile()
	assert(io.open(dirTmp..'/temp_mea.mea',"r") )
end

function should.generateVifFile()
	local vali = makeVali()
	vali:generateVifFile()
	assert(io.open(dirTmp..'/pc.vif',"r") )
end

function should.parseResult()
	local vali = makeVali()
	vali.dirTmp = 'test/fixtures/'
	vali:parseResult()
	assertEqual(728.245, vali.model.QCC1_LOAD)
end

should:test()