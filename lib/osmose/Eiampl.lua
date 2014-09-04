
--[[---------------------------------------
  
  # Eiampl

	This class is responsible to prepare the ET models
	for the solver.
	
	local eiampl = osmose.Eiampl(project)
--]]---------------------------------------

local lub = require 'lub'
local lib = lub.class 'osmose.Eiampl'
local helper = require "osmose.helpers.EiamplHelper"


-- # Class function

-- Initialize a `project` for the eiampl solver.
-- It parses the *processes* and the *utilities* and their *streams*.
-- If the project is *MER* type, it add 2 default utilties.
-- 
-- Exemple:
--
--   local project = osmose.Project('LuaJam', 'MER')
--   project:load(
--   {cip = "ET.Cip"},
--   {cm1 = "ET.CookingMixing"},
--   {cm2 = "ET.CookingMixing", with = 'CM2_inputs.csv'}
--   )
--   local eiampl = osmose.Eiampl(project)
function lib.new(project)

	for periode in ipairs(project.periodes) do

		-- All project units (processes and utilities) will be stored in this table.
		project.units[periode]={}

		project.equations[periode]={}

		-- This is the workind direcories
		local dir = ('./results/'..project.name..'/run_'..project.run..'/periode_'..periode..'/')		
		local dirTmp = ('./results/'..project.name..'/run_'..project.run..'/periode_'..periode..'/tmp/')
	 	lub.makePath(dirTmp)

	 	-- We parse each model to look for units.
		for i,model in pairs(project.models) do

			-- The current periode must be stored in model.
			model.periode = periode

			-- If the model is dependend of a VALI resolution, we must execute to get the input values.
			if model.software and model.software[1] == 'VALI' then

				-- a bls file must be given.
	    	local blsFile = model.software[2]
	    	if blsFile == nil then
					error('A bls file must be given to run Vali')
				end
	
				-- Generate files for VALI, execute it and recover the results.
				local vali = require 'lib.osmose.Vali' (model, dirTmp, blsFile)
				vali:copyBlsFile()
	    	vali:generateMeaFile()
	    	vali:generateVifFile(d)
	    	vali:execute()
	    	vali:parseResult()
			end

			-- Process are parsed.
			for name, process in pairs(model.processes) do

				if type(process.addToProblem) == 'string' then
					process.addToProblem = model[process.addToProblem]()
				end
				if process.addToProblem == 1 then
					local unit = {}
					-- The unit name must be different for GLPK.
					unit.shortName = name
					unit.name = project.name..'_'..model.name..'_'..name
					-- Streams will also be parsed later on.
					unit.rawStreams = process.streams
					process.name = nil
					for key, val in pairs(process) do
						if key ~= '__index' and key ~= 'streams' then
							unit[key] = val
						end
					end
					-- Process initialization.
					local unitInit = helper.initProcess(unit, model)
					unitInit.freeze = lib.freezeUnit
					table.insert(project.units[periode], unitInit)
				end
			end 

			-- Utilities ared parses only if the project is not a MER.
			if project.objective ~= 'MER' and project.objective ~=nil then
				for name, utility in pairs(model.utilities) do
					if type(utility.addToProblem) == 'string' then
						utility.addToProblem = model[utility.addToProblem]()
					end
					if utility.addToProblem == 1 then
						local unit = {}
						unit.shortName = name
						unit.name = project.name..'_'..model.name..'_'..name
						unit.rawStreams = utility.streams
						utility.name = nil
						-- Utilities may have specific key such as costs.
						for key, val in pairs(utility) do
							if key ~= '__index' and key ~= 'streams' then
								unit[key] = val
							end
						end
						local unitInit = helper.initUtility(unit, model)
						unitInit.freeze = lib.freezeUnit
						table.insert(project.units[periode], unitInit)
					end
				end
			end


			-- Prepare and store equations.
			for name, args in pairs(model.equations) do
				local statement = args.statement
				if type(args.addToProblem) == 'string' then
					args.addToProblem = model[args.addToProblem]()
				end
				if args.addToProblem == 1 then
					local name = project.name..'_'..model.name..'_'..name
					
					local left, condition, right = statement:match("(.[^<>=]*)([<>=]+)(.*)")

					for i, unit in ipairs(project.units[periode]) do
						if left:match(unit.shortName) then
							local stringToReplace = string.format("%s", unit.shortName)
							local newString = string.format("Units_Mult_t['%s',t]", unit.name)
							left = left:gsub(stringToReplace, newString )
						end
					end
					local initStatement = string.format("subject to %s{t in Time}: %s %s %s;",name, left, condition, right)
					table.insert(project.equations[periode], initStatement)
				end
			end
	  end -- for models loop

	end -- for _periodes loop

  return project
end

function lib.freezeUnit(self, periode, time)

	local freeze = {}
  local model = self.model
  model.periode = periode or 1
  model.time = time or 1
  freeze.frozen = true
  freeze.shortName = self.shortName
  freeze.name = self.name
  freeze.type = self.type
  freeze.model = self.model
  freeze.streams = {}
  for i,s in ipairs(self.streams) do
  	table.insert(freeze.streams, s:freeze(periode, time) )
  end
  return freeze

end

return lib
