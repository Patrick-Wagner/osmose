local lub = require 'lub'
local lib = {}



function lib.initQTStream(stream, model)
	stream.isHot = function(model)
		if stream.ftinNoCorr(model) > stream.ftoutNoCorr(model) and stream.fhin(model) > stream.fhout(model)  then
			stream.ftin = stream.ftinNoCorr
			stream.ftout = stream.ftoutNoCorr
			return true
		elseif stream.ftinNoCorr(model) < stream.ftoutNoCorr(model) and stream.fhin(model) < stream.fhout(model)  then
			stream.ftin = stream.ftinNoCorr
			stream.ftout = stream.ftoutNoCorr
			return false
		elseif (stream.ftinNoCorr(model) < stream.ftoutNoCorr(model) and stream.fhin(model) > stream.fhout(model)) or (stream.ftinNoCorr(model) > stream.ftoutNoCorr(model) and stream.fhin(model) < stream.fhout(model)) then
			print("The stream " .. stream.shortName .." is inconsistent in enthalpy and temperature.") 
			print(string.format("TIN=%s, TOUT=%s, HIN=%s, HOUT=%s",stream.ftinNoCorr(model), stream.ftoutNoCorr(model), stream.fhin(model), stream.fhout(model)))
		elseif stream.ftinNoCorr(model) == stream.ftoutNoCorr(model) then
			print(string.format("This stream '%s' is a simple dot.", stream.shortName))
			print(string.format("TIN=%s, TOUT=%s, HIN=%s, HOUT=%s",stream.ftinNoCorr(model), stream.ftoutNoCorr(model), stream.fhin(model), stream.fhout(model)))
			if stream.fhin(model) > stream.fhout(model)  then
				stream.ftin = function(model) return stream.ftinCorr(model) end
				stream.ftout = stream.ftoutNoCorr
				return true
			elseif stream.fhin(model) < stream.fhout(model)  then
				stream.ftin = stream.ftinNoCorr
				stream.ftout = function(model) return stream.ftoutCorr(model) end
				return false
			else	
				print(string.format("Can not determine if stream '%s' is hot or cold.", stream.shortName))
				os.exit()
			end
		else
			print(string.format("Can not determine if stream '%s' is hot or cold.", stream.shortName))
			print(string.format("TIN=%s, TOUT=%s, HIN=%s, HOUT=%s",stream.ftin(model), stream.ftout(model), stream.fhin(model), stream.fhout(model)))
			os.exit()
		end
	end

	stream.Tin = function(model) return stream.ftin(model) end
	stream.Tout = function(model) return stream.ftout(model) end
	stream.Hin = function(model) return stream.fhin(model) end
	stream.Hout = function(model) return stream.fhout(model) end 

	stream.Tin_corr = function(model) 
		if stream.isHot(model) then
			return stream.ftin(model) - stream.fdtmin(model) 
		else
			return stream.ftin(model) + stream.fdtmin(model)
		end
	end 

	stream.Tout_corr = function(model) 
		if stream.isHot(model) then
			return stream.ftout(model) - stream.fdtmin(model) 
		else
			return stream.ftout(model) + stream.fdtmin(model) 
		end
	end

	return stream
end

function lib.initMassStream(stream,model,unit)
  
  -- stream.Flow is used by Glpk.lua to update the flowrate in each time step
  -- Modified by Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)
  stream.value = function(model) return stream.fFlow(model) end
  if type(stream.value) == 'function' then
		stream.value = stream.value(model)
	end
  stream.Flow=function(model) return stream.fFlow(model) end
	
  
	local layerFound = 0
	for layerName, layer in pairs(model.layers) do
		if layerName == stream.layerName then
      if layer.type =='MassBalance' then
        unit.layers[layerName] = layer
        layerFound = 1
      else
        print(string.format("The stream %s is a MassStream, while its layer %s is not MassBalance layer", stream.shortName, stream.layerName))
        os.exit()
      end
		end
	end
	if layerFound == 0 then			
		print(string.format("The layer %s of stream %s is not found.", stream.layerName , stream.shortName))
		os.exit()
	end
	return stream
end

function lib.initResourceStream(stream,model,unit)
  
  -- stream.Flow is used by Glpk.lua to update the flowrate in each time step
  -- author: Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)
  stream.value = function(model) return stream.fFlow_r(model) end
  if type(stream.value) == 'function' then
		stream.value = stream.value(model)
	end
  stream.Flow_r=function(model) return stream.fFlow_r(model) end
	
  
	local layerFound = 0
	for layerName, layer in pairs(model.layers) do
		if layerName == stream.layerName then
			if layer.type =='ResourceBalance' then
        unit.layers[layerName] = layer
        layerFound = 1
      else
        print(string.format("The stream %s is a ResourceStream, while its layer %s is not ResourceBalance layer", stream.shortName, stream.layerName))
        os.exit()
      end
		end
	end
	if layerFound == 0 then			
		print(string.format("The layer %s of stream %s is not found.", stream.layerName , stream.shortName))
		os.exit()
	end
	return stream
end
function lib.initProcess(unit, model)
	unit.model = model
	unit.type = 'Process'
	unit.force_use = unit.force_use or 1 
  
  -- Fmin and Fmax are equal to the unit.Mult If the user defines the unit.Mult
  -- for a process in project definition, otherwise they are equal to 1
  -- Modified by Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)
	unit.Fmin = unit.Mult or 1
	unit.Fmax = unit.Mult or 1

  -- unit.costing1 = {Cost= (unit.Cost1 or 0), Cinv= (unit.Cinv1 or 0), Power=(unit.Power1 or 0), Impact=(unit.Impact1 or 0)}
	-- unit.costing2 = {Cost= (unit.Cost2 or 0), Cinv= (unit.Cinv2 or 0), Power=(unit.Power2 or 0), Impact=(unit.Impact2 or 0)}

	-- unit.cost_value1 = function(this) 
	-- 	return unit.costing1.Cost
	-- end
	-- unit.cost_value2 = function(this) 
	-- 	return unit.costing2.Cost
	-- end
	unit.streams = {}
	unit.massStreams = {}
  unit.resourceStreams = {}
  unit.costStreams = {}
	unit.layers = {}

	for key,tbl in pairs(unit.rawStreams) do
		local stream={}
		if type(tbl)=='table' then
			stream.shortName = key
			stream.name = unit.name..'_'..key
			stream.unitName = unit.name
			stream.load = {}
			for key, val in pairs(tbl) do
				if key ~= '__index' then
					stream[key] = val
				end
			end
      if stream.tin ~= nil and tbl.hin ~= nil then
				local streamInit = lib.initQTStream(stream, model)
				table.insert(unit.streams, streamInit)
			elseif stream.layerName ~= nil and stream.type == 'MassStream' then
				local streamInit = lib.initMassStream(stream, model,unit) ---????
				table.insert(unit.massStreams, streamInit)
      elseif stream.layerName ~= nil and stream.type == 'ResourceStream' then
				local streamInit = lib.initResourceStream(stream, model,unit) ---????
				table.insert(unit.resourceStreams, streamInit)
        
			else
				print(string.format("Stream %s can't be initialized: it has no temperature in or no layer.",stream.shortName))
				os.exit()
			end
			unit[key] = nil
		end
	end

  -- add Cost layers and CostStreams to each unit
  -- Modified by Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)
  for layerName, layer in pairs(model.layers) do
		if layer.type == 'Costing' then
			unit.layers[layerName] = layer
      local coststream=lib.initCostStream(layerName,unit, model)
      table.insert(unit.costStreams,coststream)
      
		end
	end

  
	return unit
end

function lib.initUtility(unit, model)
	unit.model = model
	unit.type	= 'Utility'
	unit.force_use = unit.force_use or 0
	unit.Fmin = unit.Fmin or 0
	unit.Fmax = unit.Fmax or 10000

	-- unit.costing1 = {Cost= (unit.Cost1 or 0), Cinv= (unit.Cinv1 or 0), Power=(unit.Power1 or 0), Impact=(unit.Impact1 or 0)}
	-- unit.costing2 = {Cost= (unit.Cost2 or 0), Cinv= (unit.Cinv2 or 0), Power=(unit.Power2 or 0), Impact=(unit.Impact2 or 0)}
	
	-- unit.cost_value1 = function(this) 
	-- 	return unit.costing1[this.Cost]
	-- end
	-- unit.cost_value2 = function(this) 
	-- 	return unit.costing2[this.Cost]
	-- end
	unit.streams={}
	unit.massStreams = {}
  unit.resourceStreams = {}
  unit.costStreams = {}
	unit.layers={}
	for key,tbl in pairs(unit.rawStreams) do
		local stream={}
		if type(tbl)=='table'  then
			stream.shortName = key
			stream.name = unit.name..'_'..key
			stream.unitName = unit.name
			stream.load={}
			for key, val in pairs(tbl) do
				local value
				if type(val) == 'number' then
					value = function() return val end 
				else
					value = val
				end
				stream[key] = value
			end
			if stream.tin ~= nil and tbl.hin ~= nil then
				local streamInit = lib.initQTStream(stream, model)
				table.insert(unit.streams, streamInit)
			elseif stream.layerName ~= nil and stream.type == 'MassStream' then
				local streamInit = lib.initMassStream(stream, model,unit) 
				table.insert(unit.massStreams, streamInit)
      elseif stream.layerName ~= nil and stream.type == 'ResourceStream' then
				local streamInit = lib.initResourceStream(stream, model,unit) 
				table.insert(unit.resourceStreams, streamInit)
        
			else
				print(string.format("Stream %s can't be initialized",stream.shortName))
				os.exit()
			end
			unit[key] = nil
		end
	end
  
  -- add Cost layers and CostStreams to each unit
  -- Modified by Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)
  for layerName, layer in pairs(model.layers) do
		if layer.type == 'Costing' then
			unit.layers[layerName] = layer
      local coststream=lib.initCostStream(layerName,unit, model)
      table.insert(unit.costStreams,coststream)
      
		end
	end
  
  
	return unit
end


--[[
 lib.initCostStream(layerName,unit, model) is defined to add costs streams to each unit.
 @author: Samira Fazlollahi (samira.fazlollahi@a3.epfl.ch)
 
 The cost streams are;
  1- OpCost in layer of 'DefaultOpCost',
  2- InvCost in layer of 'DefaultInvCost',
  3- Power in layer of 'DefaultMechPower',
  4- Impact in layer of 'DefaultImpact'.
--]]
function lib.initCostStream(layerName,unit, model)
      
      local coststream={}
      
      if layerName=='DefaultOpCost' then
        coststream.shortName= 'OpCost'
        coststream.name=unit.name..'_Cost' 
      elseif layerName=='DefaultInvCost' then
        coststream.shortName='InvCost'
        coststream.name=unit.name..'_Cinv'
      elseif layerName=='DefaultMechPower' then
        coststream.shortName='Power'
        coststream.name=unit.name..'_Power'
      else
        coststream.shortName='Impact'
        coststream.name=unit.name..'_Impact'
      end
      
      coststream.unitName= unit.name
      coststream.layerName=layerName
      

      local coststreamFunction = require('osmose.CostStream')
      coststream.coefficient1= function(model) return coststreamFunction(model, layerName, unit).fcoefficient1 end
      coststream.coefficient2= function(model) return coststreamFunction(model, layerName, unit).fcoefficient2 end

    
	return coststream
end

return lib