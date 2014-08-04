local lub = require 'lub'
local lib = {}

function lib.loadUndeclaredTags(model)

	for unitName, unitTable in pairs(model.processes) do
		for streamName, streamTable in pairs(unitTable.streams) do
			for k,v in pairs(streamTable) do
				local present = false
				if type(v)=='string' and k~='type' and k~='inOut' and k~='layerName' then
					--if pcall(function() return model[v] end) then
					if model.present(v) then
						-- do noting... 
					else
						--print(v, 'not present', model.present(v))
						print(string.format("Tag '%s' from stream '%s' in unit '%s' is not declared.", v, streamName, unitName))
						os.exit()
					end
				end
			end
		end
	end

end

return lib