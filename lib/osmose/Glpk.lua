--[[---------------------------------------

# Glpk

This class interfaces with the Glpk solver.
It generates the *data*, copy the *mod* files, call the solver executable and parse the results.

--]]---------------------------------------
local lustache = require "osmose.eiampl.vendor.lustache"
local helper = require "osmose.helpers.glpkHelper"
local lub 	= require 'lub'
local lib 	= lub.class 'osmose.Glpk'

-- The directory where mod files are stored.
lib.mod_directory=lub.path('&'):gsub('Glpk.lua','')..'/eiampl/mod'
-- The filename for the solver.
lib.run_filename='eiampl.run'
-- The data filename for the solver.
lib.data_filename='eiampldata.in'
-- The message out file for the solver.
lib.outmsg_filename='GlpkOutMsg.txt'
-- The result file for the solver.
lib.result_filename='eiamplAll.out'
-- The pre solve mod files that are required for the solver.
--lib.get_pre_solve_mod= {"eiampl.mod", "costing.mod", "heat_cascade_base_glpsol.mod", "heat_cascade_no_restrictions.mod"}
lib.get_pre_solve_mod_p= {"eiampl_p.mod", "costing_p.mod", "heat_cascade_base_glpsol_p.mod", "heat_cascade_no_restrictions_p.mod", "mass_p.mod"}
-- The post solve mod files that are required for the solver.
--lib.get_post_solve_mod = {"eiampl_glpsol_postSolve.mod", "costing_postSolve.mod", "heat_cascade_base_postSolve.mod"}
lib.get_post_solve_mod_p = {"costing_postSolve_p.mod", "heat_cascade_base_postSolve_p.mod", "mass_postSolve_p.mod"}
-- The default solve function used by the solver
lib.generate_solve_function = "minimize ObjectiveFunction : Costs_Cost['osmose_default_model_DefaultOpCost']; solve; \n\n"
-- "def_location" is the default location.
lib.locations={{name='def_location'}}
-- Default operations costs
lib.defaultOperationalCosts={cost_elec_in=5, cost_elec_out=2, op_time=8600}
-- Default name for Heat Cascade
lib.default_heat_cascade = "DefaultHeatCascade"



-- # Class method
-- The method to run the solving process.
-- It prepares the files for the solver in a model's name directory.
-- Call then solver.
function lib.new(project, return_solver)
	lib.__index = lib
	setmetatable(project, lib)

	for periode in ipairs(project.periodes) do 

		local tmp_dir = ('./results/'..project.name..'/run_'..project.run..'/periode_'..periode..'/tmp/')

		-- Create the data file and the mod files for the solver.
		local mod_date, mod_content, f, times
		local times = project.periodes[periode].times

		if times >= 1 then
			mod_data 		= lib.generateDataWithTimes(project, periode)
			mod_content = lib.generateModWithTimes(project,return_solver, periode)
		else
			print('Project times is not valid: it must greater or equal to 1. Actually =', times)
			os.exit()
		end

		-- preparing project to store results
		project.results.gcc[periode] = {}
		local intervals, temps = lib.streamsTinWithTimes(project.units[periode], periode, project.periodes[periode].times)

		for i,tbl in ipairs(temps) do
			project.results.gcc[periode][tbl.time] = project.results.gcc[periode][tbl.time] or {}
			project.results.gcc[periode][tbl.time][tbl.interval] = tbl
		end

		-- replace default name by project name
		mod_data = string.gsub(mod_data, 'osmose_default_model', project.name)
		mod_content = string.gsub(mod_content, 'osmose_default_model', project.name)

		-- writing files for the solver
		f = io.open(tmp_dir..lib.data_filename,"w")
		f:write(mod_data)
		f:close()

		local mod_content = mod_content..string.format('\nend;\n')
		f = io.open(tmp_dir..lib.run_filename,"w")
		f:write(mod_content)
		f:close()

		local cmd = (	OSMOSE_ENV["GLPSOL_EXE"] ..
				' -m '..tmp_dir..lib.run_filename..
				' -d '..tmp_dir..lib.data_filename..
				' -o '..tmp_dir..lib.outmsg_filename..
				' -y '..tmp_dir..lib.result_filename)
		
		print(cmd)
		os.execute(cmd)
					
		if return_solver then
			local f = io.open(tmp_dir..lib.result_filename,"r")
			local result = f:read("*all")
			f:close()
			return loadstring("return "..result)()
		else
			helper.parseResultGlpkFile(project, tmp_dir, periode)
		end

	end -- for periodes loop
	return project
end

-- # Privates methodes

-- This function generate the datas for a `project` on a given `periode`.
function lib.generateDataWithTimes(project, periode)

	-- Load glpk template.
	--local f,err = assert(io.open(lub.path('|')..'/templates/glpkWithTimes.mustache'))
	local f,err = assert(io.open(lub.path('&'):gsub('Glpk.lua','')..'templates/glpkWithTimes.mustache'))
	local template = f:read('*a')
	f:close()

	-- Create Default Heatcascade Units if objective is MER.
	if project.objective == 'MER' or project.objective == nil then
		print('MER Objective')
		project.units[periode] = lib.addMerUnits(project.units[periode], project.name)
	end

	local times = {}
	local timesValues = {}
	for t=1,project.periodes[periode].times do
		table.insert(timesValues, t)
		local streams={}
		for iu, unit in ipairs(project.units[periode]) do
			local model = unit.model
			if model then
				model.periode = periode 
				model.time = t
			end
			for is,s in ipairs(unit.streams) do
				local stream = {}
				stream.time = t
				stream.name = s.name
				stream.Tin_corr = s.Tin_corr(model)
				stream.Tout_corr = s.Tout_corr(model)
				stream.Hin = s.Hin(model)
				stream.Hout = s.Hout(model)
				table.insert(streams, stream)
			end
		end

		table.insert(times, {time = t, streams = streams })
	end

	local intervals, temps = lib.streamsTinWithTimes(project.units[periode], periode, project.periodes[periode].times)

	local layers = {'DefaultHeatCascade',
	'osmose_default_model_DefaultImpact',	
	'osmose_default_model_DefaultMechPower',
	'osmose_default_model_DefaultInvCost',
	'osmose_default_model_DefaultOpCost'}

	local massBalanceLayer = {}


  local modelLayers={}
	for m, model in ipairs(project.models) do
		for layerName, layer in pairs(model.layers) do
			local fullName =  'layers_'..layerName
			local layerFound = 0
			for i,l in ipairs(layers) do
				if l==fullName then
					layerFound = 1
				end
			end
			if layerFound == 0 then
				table.insert(layers, fullName)

				if layer.type == 'MassBalance' then
					table.insert(massBalanceLayer, fullName)
				else
					print(string.format("Layer of type '%s' is not recognized.", layer.type))
					print("Valid layer types are : Costing, HeatCascade, MassBalance")
					os.exit()
				end
				modelLayers[layerName] = {units={}, name=fullName, streams={}}
				-- table.insert(layersOfType, {type=layer.type, layers={fullName}})
				-- table.insert(layers, {layer=fullName, type=layer.type})
			end
		end
	end

	local streamLayers = {}
	local flowrateIn = {}
	local flowrateOut = {}
	for i,unit in ipairs(project.units[periode]) do
		for layerName, layer in pairs(unit.layers) do
			table.insert(modelLayers[layerName].units, {name = unit.name})
			for is, stream in ipairs(unit.massStreams) do
				if stream.layerName == layerName then 
					table.insert(modelLayers[layerName].streams, {name = stream.name})
					if stream.inOut == 'in' then
						table.insert(flowrateIn, {layerName='layers_'..layerName, unitName=unit.name, value=stream.value })
					elseif stream.inOut == 'out' then
						table.insert(flowrateOut, {layerName='layers_'..layerName, unitName=unit.name, value=stream.value })
					end
				end
			end
		end
	end



	local unitLayers = {}
	local streamLayers = {}
	for layerName, layer in pairs(modelLayers) do
		table.insert(unitLayers, {name = layer.name, units=layer.units })
		table.insert(streamLayers, {name = layer.name, streams=layer.streams })
	end

	-- load file if type is string
	local loadedValues = {}
	if type(project.operationalCosts) == 'string' then
		local path = project.sourceDir .. project.operationalCosts
		local helper = require "osmose.helpers.modelHelper"
		if path and path:find('.csv') then
      loadedValues = helper.loadValuesFromCSV(path)
    elseif path and path:find('.ods') then
      loadedValues = helper.loadValuesFromODS(path)
    end
  elseif type(project.operationalCosts) == 'table' then
  	for key, val in pairs(project.operationalCosts) do
  		loadedValues[key] = {{val}}
  	end
  elseif project.objective == 'MER' then
  	for key, val in pairs(lib.defaultOperationalCosts) do
  		loadedValues[key] = {{val}}
  	end
  elseif project.objective == 'OperatingCost' and project.operationalCosts == nil then
  	print("Operation costs must be defined as the project's objective is 'OperationCost'.")
  	print("Exemple in fronted : ")
  	print("  project.operationalCosts = {cost_elec_in = 17.19, cost_elec_out = 16.9, op_time=8000.0}")
  	os.exit()
	end 

	local operationalCosts = {}
	for costLabel,costValues in pairs(loadedValues) do
		local timesValues = {}
		for i,value in ipairs(costValues[periode]) do
			table.insert(timesValues, {time=i, value=value})
		end
		operationalCosts[costLabel] = timesValues
	end



	-- Create output text with given values.
	return lustache:render(template, {
		times 				= times,
		timesValues		= timesValues,
		project 			= project, 
		project_name  	= project.name,
		cost_elec_in  = operationalCosts.cost_elec_in,
		cost_elec_out = operationalCosts.cost_elec_out,
		op_time				= operationalCosts.op_time,
		units 				= project.units[periode], 
		attr 					= {"Cinv", "Cost", "Impact", "Power","HC"}, 
		intervals			= intervals,
		temps 				= temps,
		CostGroups 	  = {"Cost1", "Cost2"},

		massBalanceLayer 	= massBalanceLayer,

		Layers 				= layers,
		UnitsOfLayer   = unitLayers,
		StreamsOfLayer	= streamLayers,
		Costing 			= {{layer='osmose_default_model_DefaultImpact',			attr='Impact'},
										 {layer='osmose_default_model_DefaultMechPower',		attr='Power'},
										 {layer='osmose_default_model_DefaultInvCost',			attr='Cinv'},
										 {layer='osmose_default_model_DefaultOpCost',			attr='Cost'},
										},

		-- Layers 				= {
		-- 	Costing 			= {	{layer='DefaultOpCost', 		cost='Cost'}, 
		-- 										{layer='DefaultInvCost', 		cost='Cinv'},
		-- 										{layer='DefaultMechPower', 	cost='Power'},
		-- 										{layer='DefaultImpact', 		cost='Impact'} },
		-- 	HeatCascade   = { {layer='DefaultHeatCascade' }}
		-- },
		Locations 		= {{location_name = 'def_location'}},
		flowrateIn 		= flowrateIn,
		flowrateOut 	= flowrateOut
	})

end



-- This function add 2 Units to solve the MER Objective : Default HeatCascade Unit Hot (DHCU_h) and
-- Default HeatCascade Unit Cold (DHCU_c). Each of them has 1 stream, hot and cold.
function lib.addMerUnits(units, project_name)
	table.insert(units,{ name="DHCU_h", force_use=1, 
		Fmin=0, 
		Fmax=10000000000, 
		Cost1=1000,
		Cost2=1000,
		layers={},
		-- cost_value1 = function(this) 
		-- 	local costing = {Cost=1000, Cinv=0, Power=0, Impact=0}
		-- 	return costing[this.cost]	
		-- end,
		-- cost_value2 = function(this) 
		-- 	local costing = {Cost=1000, Cinv=0, Power=0, Impact=0}
		-- 	return costing[this.cost]	
		-- end,
		streams={{name="DHCS_h", unitName="DHCU_h",
					Tin				=function() return 99999 end, 
					Tout			=function() return 99998 end, 
					Tin_corr	=function() return 99999 end, 
					Tout_corr	=function() return 99998 end, 
					Hin 			=function() return 1000 end, 
					Hout 			=function() return 0 end, 
					isHot			=function() return true end,
					load 			={},
					draw			=false }}
		})

	table.insert(units,{name="DHCU_c", force_use=1, 
		Fmin=0, 
		Fmax=10000000000, 
		Cost1 = 1000,
		Cost2 = 1000,
		layers={},
	 --  cost_value1 = function(this) 
	 --  	local costing = {Cost=1000, Cinv=0, Power=0, Impact=0}
	 --  	return costing[this.cost]	
	 --  end,
	 --  cost_value2 = function(this) 
		-- 	local costing = {Cost=1000, Cinv=0, Power=0, Impact=0}
		-- 	return costing[this.cost]	
		-- end,
		streams={{name="DHCS_c", unitName="DHCU_c",  
					Tin 			=function() return 100 end, 
					Tout 			=function() return 105 end, 
					Tin_corr 	=function() return 100 end, 
					Tout_corr =function() return 105 end, 
					Hin 			=function() return 0 end, 
					Hout 			=function() return 1000 end, 
					isHot			=function() return false end,
					load 			={},
					draw			=false }}
		})

	return units
end


-- This function return all the mininum streams of the *units* and sort them ascendingly.
function lib.streamsTinWithTimes(units, periode, times)
	local streams_temp_in = {}
	local intervals = {}
	for time=1, times do 
		local uniq_tin = {}
		for iu, unit in pairs(units) do
			local model = unit.model
			if model then
				model.periode = periode
				model.time = time
			end
			for is, stream in pairs(unit.streams) do
				if stream.Tin_corr then 
					local Tin_corr = stream.Tin_corr(model)
					local Tout_corr = stream.Tout_corr(model)
					local tbl = {	Tin_corr = stream.Tin_corr(model), 
												Tout_corr = stream.Tout_corr(model), 
												Hin = stream.Hin(model),
												Hout = stream.Hout(model),
												isHot=stream.isHot(model)}
					uniq_tin[Tin_corr] = tbl
					uniq_tin[Tout_corr] = tbl
				end
			end
		end
		

		local temps = {}
		for t, tbl in pairs(uniq_tin) do 
			table.insert( temps, {T=t, temp=t, time=time, Hin=tbl.Hin, Hout=tbl.Hout, Tin_corr=tbl.Tin_corr, Tout_corr = tbl.Tout_corr, isHot = tbl.isHot }) 
		end

		table.sort(temps, function(a,b) return a.T<b.T  end)

		for i,t in pairs(temps) do
			t.interval = i
			table.insert(streams_temp_in, t)
		end

		table.insert(intervals, {time=time, temps=temps})
	end -- times loop
		
	return intervals, streams_temp_in
end



-- This function read all the mod files and concatenate them in one single content.
-- It add the solve function depending of the objective of the project.
function lib.generateModWithTimes(project,return_solver, periode)
	local content=""
	for i,mod in pairs(lib.get_pre_solve_mod_p) do
		local f= assert(io.open(lib.mod_directory..'/'..mod,'r'))
		--content = content .. (f:read("*all"):gsub("osmose_default_model", project.name ))
		content = content .. (f:read("*all"))
		f:close()
	end

	for i,equation in ipairs(project.equations[periode]) do
		content = content .."\n\n".. equation
	end

	if project.objective=='MER' then
		--content = content .. lib.generate_solve_function:gsub("osmose_default_model", project.name)
		content = content .. lib.generate_solve_function
	elseif project.objective=='OperatingCost' then
		--content = content .. lib.generate_solve_function:gsub("osmose_default_model", project.name)
		content = content .. lib.generate_solve_function
  elseif project.objective=='YearlyOperatingCost' then
		content = content .. "# Objective function\n minimize ObjectiveFunction : YearlyOperatingCost; solve;\n\n"
  else
    print("Project Objective is not valid: ", project.objective)
    os.exit()
	end
	
	if return_solver then
		content = content..return_solver.."\n"
	else
		for i,mod in pairs(lib.get_post_solve_mod_p) do
			local f= assert(io.open(lib.mod_directory..'/'..mod,'r'))
			content = content .. f:read("*all")
			f:close()
		end
	end

	return content
end	


return lib