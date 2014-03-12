local lub = require 'lub'
local lib = {}


-- Load a CSV file seperated with coma (,).
-- Each line is a periode. The values on a line are the times of the periode.
-- The tag must be on the first place.
-- The unit is opational on the second place.
--
-- Exemple a CSV file :
	-- prod_1_flow,kg/h, 3000
	-- prod_1_flow,kg/h, 4000, 5000
	-- prod_1_cp, 2.11
	-- prod_1_cp, 2.56
	-- prod_1_temp,C, 60
	-- prod_1_btemp,C, 90
function lib.loadValuesFromCSV(fileName)
	local f = assert(io.open(fileName))
	local result={}
	local times, key, unit, periode

	for line in f:lines() do
		times = lub.split(line,',')

		-- The tag name must be on the first place.
		key = times[1]

		-- Try to find if there is optional unit on the second place
		if tonumber(times[2]) then
		else
			unit = table.remove(times,2)
		end
		table.remove(times,1)

		-- Clean values.
		for i,value in ipairs(times) do
			times[i] = tonumber(value)
		end

		result[key] = result[key] or {}

		-- Each line of the file is a periode.
		periode = table.getn(result[key]) + 1

		-- The rest of the lines are times values.
		result[key][periode] = times
	end
	return result
end

-- Load data from a LibreOffice SpreadSheat file.
-- File can have multiple sheets, but their names must correspond to model name.
-- The first colonne is for tag name.
-- The rest of colons are for Time value.
-- Multiple rows is for multiple periodes.
-- Require luazip and luaxml.
function lib.loadValuesFromODS(fullPath,modelName)
	if not require 'zip'	then
		print('luazip must be installed. Please run `luarocks install luazip` .')
		os.exit()
	end
	if not require("LuaXml") then
		print('luaxml must be installed. Please run `luarocks install luaxml` .')
		os.exit()
	end

	-- Ods file are zipped.
	local zf,err = zip.open(fullPath)

	if err then
		print('Could not find or read file:',fullPath)
		os.exit()
	end

	-- The data are stored in content.xml file.
	local f, err = zf:open('content.xml')
	local content = f:read("*a")
	f:close()

	-- Parse the xml into xf table.
	local xf = xml.eval(content)

	-- Find the spreadsheat with the model name or the first spreadsheat.
	local sheet = xf:find('table:table', 'table:name',tableName) or xf:find('table:table')

	if not sheet then
		print('Could not find a sheet with the model name. Please rename sheet with model name.')
		os.exit()
	end

	local result={}
	local periode = 1
	local tag = ""
	for rowIdx,row in ipairs(sheet) do
		for i,cell in ipairs(row) do
			-- If cell contains string then it's input name (key).
			if cell["office:value-type"]=="string" then
				key = cell[1][1]
				result[key] = result[key] or {}

				-- Each line of the file is a periode.
				periode = table.getn(result[key]) + 1
				result[key][periode] = {}
			-- Otherwise it contains time values.
			elseif cell["office:value-type"]=="float" then
				-- Values can be repeated.
				if cell['table:number-columns-repeated'] then
					for r=1, cell['table:number-columns-repeated'] do
						table.insert(result[key][periode], tonumber(cell['office:value']))
					end
				else
					table.insert(result[key][periode], tonumber(cell['office:value']))
				end
			end
		end
	end
	zf:close()

	return result
end





return lib