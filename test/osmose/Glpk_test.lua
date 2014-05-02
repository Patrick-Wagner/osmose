package.path = './lib/?/init.lua;./lib/?.lua;'..package.path
local osmose = require 'osmose'
local lut    = require 'lut'
local tmp_dir = ('./test/tmp/')
local should = lut.Test 'osmose.Glpk'
local helper = require 'osmose.helpers.glpkHelper'
local periode = 1

OSMOSE_ENV["GLPSOL_EXE"] = '/usr/local/bin/glpsol'

function createProject()
	local project = osmose.Project('LuaJam', 'MER')
	project:load({cip = "ET.Cip"})
	osmose.Eiampl(project)

	project.result_filename='eiamplAll.out'
	project.results.gcc[periode]={}
	project.results.delta_hot[periode]={}
	project.results.delta_cold[periode]={}
	for time=1,3 do
		project.results.gcc[periode][time]={}
		project.results.delta_hot[periode][time]=nil
		project.results.delta_cold[periode][time]=nil
		for i=1,14 do
			project.results.gcc[periode][time][i]={}
		end
	end

	return project
end

function should.runGlpk()
	local project = osmose.Project('LuaJam', 'MER')
	project:load({cip = "ET.Cip"})
	local oneRun = osmose.Eiampl(project)
	osmose.Glpk(oneRun)
	
	assertType('table', project.results.gcc[1][1])
end


function should.parseHCRK()
	local project = createProject()

	helper.parseResultGlpkFile(project, tmp_dir, periode)	
	assertEqual(4.27, project.results.gcc[1][1][4].Q, 0.01)
end

function should.parseDeltaHotAndCold()
	local project = createProject()

	helper.parseResultGlpkFile(project, tmp_dir, periode)
	assertEqual(816.16, project.results.delta_hot[1][1], 0.01)
	assertEqual(0, project.results.delta_cold[1][1])
end


should:test()