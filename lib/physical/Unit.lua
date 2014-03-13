
local lub 	= require 'lub'
local lib 	= lub.class 'physical.Unit'


function lib.new(value, unit)

	local u = lub.class('PhysicalUnit')
	setmetatable(u, lib)

	if type(value) == 'number' or type(tonumber(value)) == 'number' then
		u.value = tonumber(value)
	else
		return nil, ('Value must be a number')
	end
	if type(unit) == 'string' then
		u.unit  = unit
	else
		return nil, ('Unit must be a string')
	end

	function u:convert(newUnit)
		local conv = lib.loadConversion()
		local u1 = conv[u.unit]				-- actuall unit
		local u2 = conv[newUnit]			-- unit to convert
		if u1.class == u2.class then
			if type(u1.mult) == 'number' and type(u2.mult) == 'number' then
				local newValue =  (u.value +u1.offset  )* u1.mult / (u2.mult) -u2.offset
				return lib.new(newValue, newUnit)
			end
		else
			return nil, "Units doesn't have the same class."
		end
	end

	return u
end



function lib.compareUnits(u1,u2)
	local conv = lib.loadConversion()
	if type(u2) == 'table' and u2.type == 'PhysicalUnit' then
		if u1.unit == u2.unit then
			return u2
		elseif conv[u1.unit].class == conv[u2.unit].class then
			return u2:convert(u1.unit)
		else
			return nil, string.format("Units doesn't have the same values: %s != %s", u1.unit, u2.unit)
		end
	end
end

function lib.loadConversion()
	local f = assert(io.open('lib/physical/conversion.txt'))
	local conversion = {}

	for line in f:lines() do
		local dim = lub.split(line,'|')
		local mult=0
		local offset=nil
		local class=lub.strip(dim[2])
		local key=lub.strip(dim[1])
		if tonumber(dim[3]) then
			mult = tonumber(dim[3])
		elseif string.match(dim[3],'function') then
			assert(loadstring("convert = "..dim[3]) )()
			mult=convert
		elseif dim[3] and string.match(dim[3],'(%d+%.?%d*) (%a+)') then
			local relativeCoef, relativeUnit = string.match(dim[3],'(%d+%.?%d*) (%a+)')
			mult = conversion[relativeUnit].mult * tonumber(relativeCoef)
		end
		if tonumber(dim[4]) then
			offset = tonumber(dim[4])
		end
		conversion[key] = {class=class, mult=mult, offset=(offset or 0)}
	end
	return conversion
end

function lib.__tostring(u)
	return string.format("%.2f %s", u.value, u.unit)
end

function lib.__add(u1, u2)
	local u2 = lib.compareUnits(u1,u2)
	if u2 then
		local newValue = u1.value + u2.value
		return lib.new(newValue, u1.unit)
	end
end

function lib.__sub(u1,u2)
	local u2 = lib.compareUnits(u1,u2)
	if u2 then
		local newValue = u1.value - u2.value
		return lib.new(newValue, u1.unit)
	end
end

function lib.__mul(u1,u2)
	local u2 = lib.compareUnits(u1,u2)
	if u2 then
		local newValue = u1.value * u2.value
		return lib.new(newValue, u1.unit)
	end
end

function lib.__div(u1,u2)
	local u2 = lib.compareUnits(u1,u2)
	if u2 then
		local newValue = u1.value / u2.value
		return lib.new(newValue, u1.unit)
	end
end

function lib.__pow(u1,u2)
	local u2 = lib.compareUnits(u1,u2)
	if u2 then
		local newValue = u1.value ^ u2.value
		return lib.new(newValue, u1.unit)
	end
end

function lib.__mod(u1,u2)
	local u2 = lib.compareUnits(u1,u2)
	if u2 then
		local newValue = u1.value % u2.value
		return lib.new(newValue, u1.unit)
	end
end

function lib.__unm(u)
	local newValue = -u.value
	return lib.new(newValue, u.unit)
end

function lib.__eq(u1, u2)
	local u2 = lib.compareUnits(u1,u2)
	if u2 then
		if u1.value == u2.value then
			return true
		else
			return false
		end
	end
end

function lib.__lt(u1, u2)
	local u2 = lib.compareUnits(u1,u2)
	if u2 then
		if u1.value < u2.value then
			return true
		else
			return false
		end
	end
end

function lib.__le(u1, u2)
	local u2 = lib.compareUnits(u1,u2)
	if u2 then
		if u1.value <= u2.value then
			return true
		else
			return false
		end
	end
end

return lib