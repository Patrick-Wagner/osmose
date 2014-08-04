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
lib.get_pre_solve_mod_p= {"eiampl_p.mod", "costing_p.mod", "heat_cascade_base_glpsol_p.mod", "heat_cascade_no_restrictions_p.mod", "mass_p.mod", "resource_p.mod"}
-- The post solve mod files that are required for the solver.
--lib.get_post_solve_mod = {"eiampl_glpsol_postSolve.mod", "costing_postSolve.mod", "heat_cascade_base_postSolve.mod"}
lib.get_post_solve_mod_p = {"costing_postSolve_p.mod", "heat_cascade_base_postSolve_p.mod", "mass_postSolve_p.mod", "resource_postSolve_p.mod"}


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
		project.results.delta_hot[periode]={}
		project.results.delta_cold[periode]={}
		local intervals, temps = lib.streamsTinWithTimes(project.units[periode], periode, project.periodes[periode].times)

		for i,tbl in ipairs(temps) do
			project.results.gcc[periode][tbl.time] = project.results.gcc[periode][tbl.time] or {}
			project.results.gcc[periode][tbl.time][tbl.interval] = tbl
			
			project.results.delta_hot[periode][tbl.time]=nil
			project.results.delta_cold[periode][tbl.time]=nil
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
				' -y '..tmp_dir..lib.result_filename..
				' --log '..tmp_dir..'logs.txt')
      
		 print('-------------------------------------------------------------------------------------------')
     print('Executing Command line:')
     print('-----------------------')
     print(cmd)
		 print('-------------------------------------------------------------------------------------------')
		
		os.execute(cmd)
					
		if return_solver then
			local f = io.open(tmp_dir..lib.result_filename,"r")
			local result = f:read("*all")
			f:close()
			return loadstring("return "..result)()
		else
			helper.parseResultGlpkFile(project, tmp_dir, periode)
		end
  print('-------------------------------------------------------------------------------------------')
  print('Warning message;')
  print(" 1-There is no FEASIBLE SOLUTION if the project has a layer with only 'in' process stream(s) or only 'out' process stream(s)") 
  print(" 2-Temperature of the hot utility is not high enough to close the heat cascade balance")
  print(" 3-Temperature of the cold utility is not low enough to close the heat cascade balance")
  print(" 4-In and Out mass/resource streams cannot be defined simultaneously for a given unit")
  print(" 5-To help the solver, try to avoid large value for the Fmax of units.")
	end -- for periodes loop

	project.solved = true
	
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
		print('-------------------------------------------------------------------------------------------')
    print('MER Objective')
		print('-------------------------------------------------------------------------------------------')
    
    local add_MER_units = require('osmose.AddMerUnits')
		project.units[periode] = add_MER_units(project.units[periode], project.name)
    
	end

	local times = {}
	local timesValues = {}
	for t=1,project.periodes[periode].times do
		table.insert(timesValues, t)
    
		local streams = {}
    local coststreams = {}
    local massstreams = {}
    local resourcestreams = {}
    local forceUseUnits = {}
    
		for iu, unit in ipairs(project.units[periode]) do
      
			local model = unit.model
			if model then
				model.periode = periode 
				model.time = t
			end
			
			unit.Fmin =  unit.fFmin(model)
			unit.Fmax =  unit.fFmax(model)
      
      -- recover the unit forceUse in each time step
      -- Modified by Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)
      local forceUse={}
      forceUse.forceValue=unit.force_use
      forceUse.forceUnitName=unit.name
      table.insert(forceUseUnits, forceUse)
      
      -- recover the qt streams' value in each time step
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
      -- recover the cost streams' value (Power, Impact, Cost, Cin) in each time step
      -- (samira.fazlollahi@a3.epfl.ch)
      for isc, Scoststream in ipairs(unit.costStreams) do
        local coststream = {}
        coststream.time=t
        coststream.name=Scoststream.name
        coststream.layerName =Scoststream.layerName
        coststream.coefficient1=Scoststream.coefficient1(model, layerName, unit)
        coststream.coefficient2=Scoststream.coefficient2(model, layerName, unit)
        table.insert(coststreams, coststream)
       end
      -- recover the mass streams' value (flowrate in and flowrate out) in each time step
      -- (samira.fazlollahi@a3.epfl.ch)
      for ism, Smassstream in ipairs(unit.massStreams) do
        local massstream = {}
        massstream.time=t
        massstream.name=Smassstream.name
        massstream.unitName=unit.name
        massstream.layerName ='layers_'..Smassstream.layerName
        if Smassstream.inOut == 'in' then
          massstream.flowrateIn=Smassstream.Flow(model)
          massstream.flowrateOut=0
        elseif Smassstream.inOut == 'out' then
          massstream.flowrateIn=0
          massstream.flowrateOut=Smassstream.Flow(model)
        end
        table.insert(massstreams, massstream)        
      end
      -- recover the resource streams' value (flowrate_r in and flowrate_r out) in each time step
      -- (samira.fazlollahi@a3.epfl.ch)    
      for isr, Sresourcestream in ipairs(unit.resourceStreams) do
        local resourcestream = {}
        resourcestream.time=t
        resourcestream.name=Sresourcestream.name
        resourcestream.unitName=unit.name
        resourcestream.layerName ='layers_'..Sresourcestream.layerName
        if Sresourcestream.inOut == 'in' then
          resourcestream.flowrateIn_r=Sresourcestream.Flow_r(model)
          resourcestream.flowrateOut_r=0
        elseif Sresourcestream.inOut == 'out' then
          resourcestream.flowrateIn_r=0
          resourcestream.flowrateOut_r=Sresourcestream.Flow_r(model)
        end
        table.insert(resourcestreams, resourcestream)        
      end
		end

		table.insert(times, {time = t, streams = streams, coststreams = coststreams, massstreams = massstreams, resourcestreams = resourcestreams, forceUseUnits = forceUseUnits})
    
	end


	local intervals, temps = lib.streamsTinWithTimes(project.units[periode], periode, project.periodes[periode].times)
  
	local layers = {'DefaultHeatCascade'}

	local massBalanceLayer = {}
  local resourceBalanceLayer = {}
  local costingLayer={}
  local modelLayers={}
  

	for m, model in ipairs(project.models) do
		for layerName, layer in pairs(model.layers) do
      ---add costing Layers (samira.fazlollahi@a3.epfl.ch) 
      local fullName
      if layer ~= nil and layer.type == 'Costing' then
			  fullName = layerName
      else
        fullName =  'layers_'..layerName
      end
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
          ---add ResourceBalance Layers (samira.fazlollahi@a3.epfl.ch) 
        elseif layer.type == 'ResourceBalance' then
					table.insert(resourceBalanceLayer, fullName)
          ---add costing Layers (samira.fazlollahi@a3.epfl.ch) 
        elseif layer.type == 'Costing' then
          table.insert(costingLayer, fullName)
				else
					print(string.format("Layer of type '%s' is not recognized.", layer.type))
					print("Valid layer types are : Costing, HeatCascade, MassBalance, ResourceBalance")
					os.exit()
				end
				modelLayers[layerName] = {units={}, name=fullName, streams={}}
				-- table.insert(layersOfType, {type=layer.type, layers={fullName}})
				-- table.insert(layers, {layer=fullName, type=layer.type})
			end
		end
	end
	
	for i,unit in ipairs(project.units[periode]) do
		for layerName, layer in pairs(unit.layers) do
     table.insert(modelLayers[layerName].units, {name = unit.name})
      if layer ~= nil and layer.type == 'MassBalance' then
        for is, stream in ipairs(unit.massStreams) do
          if stream.layerName == layerName then 
            table.insert(modelLayers[layerName].streams, {name = stream.name})
          end
        end
      -- recover ResourceBalance Layers' units and streams (samira.fazlollahi@a3.epfl.ch) 
      elseif layer ~= nil and layer.type == 'ResourceBalance' then
        for is, stream in ipairs(unit.resourceStreams) do
          if stream.layerName == layerName then 
            table.insert(modelLayers[layerName].streams, {name = stream.name})
          end
        end
      -- recover costing Layers' units and streams (samira.fazlollahi@a3.epfl.ch) 
      elseif layer ~= nil and layer.type == 'Costing' then
        for is, stream in ipairs(unit.costStreams) do
          if stream.layerName == layerName then 
            table.insert(modelLayers[layerName].streams, {name = stream.name})
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
   
  -- recover cost_elec_in, cost_elec_out and op_time
  -- from project.operationalCosts
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

  elseif project.objective == 'YearlyOperatingCost' and project.operationalCosts == nil then
  	print("Operation costs must be defined as the project's objective is 'YearlyOperatingCost'.")
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
  ---updated by adding costing Layers (samira.fazlollahi@a3.epfl.ch) 
	return lustache:render(template, {
		times 				= times,
		timesValues		= timesValues,
		project 			= project, 
		project_name  	= project.name,
		cost_elec_in  = operationalCosts.cost_elec_in,
		cost_elec_out = operationalCosts.cost_elec_out,
		op_time				= operationalCosts.op_time,
		units 				= project.units[periode], 
		intervals			= intervals,
		temps 				= temps,
		massBalanceLayer 	= massBalanceLayer,
    resourceBalanceLayer = resourceBalanceLayer,
    costingLayer = costingLayer,
    Layers 				= layers,
		UnitsOfLayer   = unitLayers,
		StreamsOfLayer	= streamLayers,

		Locations 		= {{location_name = 'def_location'}},
	})

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

-- Add objective function to the optimisation model (samira.fazlollahi@a3.epfl.ch)
	local Objective_function_definition = require('osmose.ObjectiveFunction')
	content = content .. Objective_function_definition(project.objective)

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