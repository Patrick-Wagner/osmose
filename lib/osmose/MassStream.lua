local lub = require 'lub'
local lib = lub.class 'osmose.MassStream'

lib.new = function(params)

	local mass= lub.class('MassStream')
	setmetatable(mass, lib)

	mass.layerName = params[1]
	mass.inOut = params[2]
	mass.getValue = function(model)
		local val = params[3]
		if type(val) == 'number' then
			return val
		else
			return model[val]
		end
	end

	return mass
end

return lib