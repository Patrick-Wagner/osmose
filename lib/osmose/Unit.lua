

local lub 	= require 'lub'
local lib 	= lub.class 'osmose.Unit'

lib.addToProblem = 1

lib.__index = function(tbl, key)
	return lib[key] or tbl.streams[key]
end

function lib.new(name, args)
	if args.type ~= 'Process' and args.type ~= 'Utility' then
		print('Unit type should be either Process or Utility:',name, args.type)
		os.exit()
	end

	local unit = lub.class(args.type)
	setmetatable(unit, lib)

	unit.name 			= name
	unit.streams 		= {}
	
	for key, val in pairs(args) do
		unit[key]=val
	end
	return unit
end

function lib:addStreams(tbl)
	if tbl then
		local qt   = require('osmose.QTStream')
		for name,values in pairs(tbl) do
			if values.type=='QTStream' then
				self.streams[name] = values
			elseif values.type=='MassStream' then
				self.streams[name] = values
			elseif values.type=='HTStream' then
				for i, stream in ipairs(values) do
					local HTname = name..i
					self.streams[HTname] = stream
				end
			else
				self.streams[name] = qt(values)
			end
		end
	else
		return {}
	end

end

return lib