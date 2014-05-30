
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
			
		local u1 = lib.conversion[u.unit]				-- actuall unit
		local u2 = lib.conversion[newUnit]			-- unit to convert

		if u1 and u2 and u1.class == u2.class then
			if type(u1.mult()) == 'number' and type(u2.mult()) == 'number' then
				local newValue =  (u.value +u1.offset  )* u1.mult() / (u2.mult()) -u2.offset
				return lib.new(newValue, newUnit)
			else
				return nil, u1.mult()
			end
		else
			return nil, "Units doesn't have the same class."
		end
	end

	return u
end


function lib.compareUnits(u1,u2,method)
	local conv = lib.conversion
	if u1 == nil then
		return nil, "Try to compare nil"
	elseif type(u1) == 'number' then
		return u2
	elseif type(u2) == 'table' and u2.type == 'PhysicalUnit' then
		if u1.unit == u2.unit then
			return u2
		elseif conv[u1.unit] and  conv[u2.unit] and conv[u1.unit].class == conv[u2.unit].class then
			return u2:convert(u1.unit)
		elseif method == 'strict' then
			return nil, string.format("Units doesn't have the same values: %s != %s", u1.unit, u2.unit)
		else	
			return u2
		end
	elseif type(u2) == 'number' then
		return lib.new(u2,u1.unit)
	end
end

function lib.loadConversion()
	local f = assert(io.open(lub.path('&'):gsub('Unit.lua','')..'/conversion.txt'))
	local conversion = {__index=function(t,k) return conversion[k] end }

	for line in f:lines() do
		local dim = lub.split(line,'|')
		local mult=0
		local offset=nil
		local class=lub.strip(dim[3])
		local key=lub.strip(dim[1])
		local symbol= lub.strip(dim[2])
		-- facteur multiplicatif numérique
		if tonumber(dim[4]) then
			mult = function() return tonumber(dim[4]) end
		-- gram = 0.001 kg
		elseif dim[4] and string.match(dim[4],'(%d+%.?%d*) (%a+)') then
			local relativeCoef, relativeUnit = string.match(dim[4],'(%d+%.?%d*) (%a+)')
			mult = function() return conversion[lub.strip(relativeUnit)].mult() * tonumber(relativeCoef) end
		else
			mult = assert(loadstring("return "..dim[4]))
			local conv_env = setmetatable({}, {__index=function(t,k) return conversion[k].mult() end })
			setfenv(mult, conv_env)
		end
		-- offset
		if tonumber(dim[5]) then
			offset = tonumber(dim[5])
		end
		conversion[key] = {class=class, mult=mult, offset=(offset or 0), symbol=symbol}
		conversion[symbol] = conversion[key]
	end
	return conversion
end

function lib.__call(u)
	return u.value
end

function lib.__tostring(u)
	return string.format("%.2f %s", u.value, u.unit)
end

function lib.__add(u1, u2)
	local u2 = lib.compareUnits(u1,u2,'strict')
	
	if type(u1) == 'number' then 
		return lib.new(u1+u2.value, u2.unit)
	elseif u2 then
		local newValue = u1.value + u2.value
		return lib.new(newValue, u1.unit)
	end
end

function lib.__sub(u1,u2)
	local u2 = lib.compareUnits(u1,u2,'strict')

	if type(u1) == 'number' then
		return lib.new(u1 - u2.value, u2.unit)
	elseif u2 then
		local newValue = u1.value - u2.value
		return lib.new(newValue, u1.unit)
	end
end

function lib.__mul(u1,u2)
	local u2 = lib.compareUnits(u1,u2)
	if type(u1) == 'number' then
		return lib.new(u1*u2.value, u2.unit)
	elseif u2 then
		local newValue = u1.value * u2.value
		if u1.unit == u2.unit then
			return lib.new(newValue, u1.unit)
		else
			return lib.new(newValue, u1.unit.."*"..u2.unit)
		end
	end
end

function lib.__div(u1,u2)
	local u2 = lib.compareUnits(u1,u2)
	
	if type(u1) == number then
		return lib.new(u1/u2.value, u2.unit)
	elseif u2 then
		local newValue = u1.value / u2.value
		if u1.unit == u2.unit then
			return lib.new(newValue, u1.unit)
		else
			return lib.new(newValue, u1.unit.."/"..u2.unit)
		end
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
	local u2 = lib.compareUnits(u1,u2,'strict')
	if u2 then
		if u1.value == u2.value then
			return true
		else
			return false
		end
	end
end

function lib.__lt(u1, u2)
	local u2 = lib.compareUnits(u1,u2,'strict')
	if u2 then
		if u1.value < u2.value then
			return true
		else
			return false
		end
	end
end

function lib.__le(u1, u2)
	local u2 = lib.compareUnits(u1,u2,'strict')
	if u2 then
		if u1.value <= u2.value then
			return true
		else
			return false
		end
	end
end

lib.conversion = lib.loadConversion()

return lib