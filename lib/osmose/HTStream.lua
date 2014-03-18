--[[---------------------------------------
	
# HTStream

Use this class to create HT Stream in your ET model.

Exemples :

	osmose.HTStream { 
		1750, -- tin 
		{300,300,300,300,300,300,300,300,300,300}, -- hin
		{730,700,650,638,603,570,558,420,385,345}, -- tout
		{0,0,0,0,0,0,0,0,0,0},  -- hout
		5 -- dtmin
	}

or with key name :

	osmose.HTStream {
		tin 	= 1750,
		tout 	= {730,700,650,638,603,570,558,420,385,345}, 
		hin 	= {300,300,300,300,300,300,300,300,300,300},
		hout 	= {0,0,0,0,0,0,0,0,0,0},
		dtmin = 5
	}

You can use ht{} as synonyme of osmose.HTSream {}.
--]]---------------------------------------

local lub = require 'lub'
local lib = lub.class 'osmose.HTStream'
local qt   = require('osmose.QTStream')

-- The private functions are stored here.
local private={}

-- This is the valid params of QTStream initialization.
local validParamTable = {'tin', 'hin','tout','hout','dtmin','alpha'}

-- lib is the metatable
function lib.__index(table, key)
  return lib[key]
end

-- HTStream type
lib.type = 'HTStream'

lib.new = function(params)
	local HTstream = {}

	if params then
		for k,v in pairs(params) do
			if private.validParam(k) then
				HTstream[k] = v
			else
				HTstream[validParamTable[k]] = v
			end
		end
	end

	local QTStreams = {}
	setmetatable(QTStreams, lib)

	local tin
	local dtmin
	local alpha
	if type(HTstream.tin) == 'number' then
		tin = HTstream.tin
	elseif type(HTstream.tin) == 'table' then
		tin = HTstream.tin[1]
	end
	if type(HTstream.dtmin) == 'number' then
		dtmin = HTstream.dtmin
	elseif type(HTstream.dtmin) == 'table' then
		dtmin = HTstream.dtmin[1]
	end
	if type(HTstream.alpha) == 'number' then
		alpha = HTstream.alpha
	elseif type(HTstream.alpha) == 'table' then
		alpha = HTstream.alpha[1]
	end

	for i, temp in ipairs(HTstream.tout) do
		local tout = temp
		local hin = HTstream.hin[i]
		local hout = HTstream.hout[i]
		local _qt = qt { tin, hin, tout, hout, dtmin, alpha  }
		--print('qt', tin, tout, hin, hout, dtmin, apha)
		table.insert(QTStreams, _qt)

		tin = temp
	end

	return QTStreams

end

private.validParam = function(element)
  for _, value in pairs(validParamTable) do
    if value == element then
      return true
    end
  end
  return false
end

return lib