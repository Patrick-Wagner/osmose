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
	local value = stream.getValue(model)
	if type(value) == 'function' then
		value = value(model)
	end
	stream.value = value
	local layerFound = 0
	for layerName, layer in pairs(model.layers) do
		if layerName == stream.layerName then
			unit.layers[layerName] = layer
			layerFound = 1
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
	unit.Fmin = unit.Fmin or 1
	unit.Fmax = unit.Fmax or 1
	unit.Cost1 = unit.Cost1 or 0
	unit.Cost2 = unit.Cost2 or 0
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
			elseif stream.layerName ~= nil then

				local streamInit = lib.initMassStream(stream, model, unit)
				table.insert(unit.massStreams, streamInit)
			else
				print(string.format("Stream %s can't be initialized: it has no temperature in or no layer.",stream.shortName))
				os.exit()
			end
			unit[key] = nil
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
	unit.Cost1 = unit.Cost1 or 0
	unit.Cost2 = unit.Cost2 or 0
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
			elseif stream.layerName ~= nil then
				local streamInit = lib.initMassStream(stream, model,unit)
				table.insert(unit.massStreams, streamInit)
			else
				print(string.format("Stream %s can't be initialized",stream.shortName))
				os.exit()
			end
			unit[key] = nil
		end
	end
	return unit
end



return lib