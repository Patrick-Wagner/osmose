local lib={}
local lustache = require "osmose.eiampl.vendor.lustache"
local lub = require 'lub'

lib.stop = [[
local host, port = "127.0.0.1", 3333
local socket = require("socket")
local tcp = assert(socket.tcp())
tcp:connect(host, port);
tcp:send("stop\n");
tcp:close()
]]

lib.connectOsmose = [[

local host, port = "127.0.0.1", 3333
local socket = require("socket")

function solve()
	local tcp = assert(socket.tcp())
	tcp:connect(host, port)
	tcp:send("solve,".."\n")
	local s, status, partial
	while true do
	  s, status, partial = tcp:receive("*l")
	  if status == "closed" or status=="timeout" then break end
	end
	tcp:close()
	return s
end

function get(type,name,periode,time)
	local periode = periode or 1
	local time = time or 1
	local tcp = assert(socket.tcp())
	tcp:connect(host, port);
	tcp:send("get"..type..","..name..","..tostring(periode)..","..tostring(time).."\n")
	local s, status, partial
	while true do
	  s, status, partial = tcp:receive("*l")
	  if status == "closed" or status=="timeout" then 
	  	break 
	  else
	  	tcp:close()
	  	return(loadstring(s)())
	  end
	end
	tcp:close()
	return(loadstring(s)())
end

function getTag(name, periode, time)
	return get('Tag', name, periode, time)
end

function getStream(name, periode, time)
	return get('Stream', name, periode, time)
end

function getUnit(name, periode, time)
	return get('Unit', name, periode, time)
end

function getResults()
	return get('Results',"")
end

function setTag(tag,value,periode,time)
	local periode = periode or 1
	local time = time or 1
	local tcp = assert(socket.tcp())
	tcp:connect(host, port);
	tcp:send("setTag,"..tag..","..value..","..periode..","..time.."\n")
	local s, status, partial
	while true do
	  s, status, partial = tcp:receive("*l")
	  if status == "closed" or status=="timeout" then 
	  	break 
	  else
	  	tcp:close()
	  	return(loadstring(s)())
	  end
	end
	tcp:close()
	return(loadstring(s)())
end

]]


lib.readParams = [[
-- setup for params in pattern matching
local rTag = '[%w_:]+'
local rValue = '%d*.*'

-- open DAKOTA parameters file for reading
local f = assert(io.open(arg[1],"r"))

-- extract the parameters and store them in the params table
local params = {}
for line in f:lines() do
	local value,tag = line:match('^%s*('..rValue..')%s+('..rTag..')$')
	if tag then 
		params[tag] = value
	end
end

]]

lib.writeResult = [[
-- store result in output file
local f = assert(io.open(arg[2],"w"))
if type(result) == 'number' or type(result) == 'string' then
	f:write(tostring(result)..'  fn_obj\n')
elseif type(result) == 'table' then
	for i,obj in ipairs(result) do
		f:write(tostring(obj)..'  fn_obj'..i..'\n')
	end
end
f:close()

]]

lib.objectives_path={}	
lib.precomputes_path={}
lib.postcomputes_path={}
lib.variables={}

function lib.copyFile(name, sourceDir, tmpDir)
		f = assert(io.open(sourceDir..name..'.lua','r'))
		local content = (f:read("*all"))
		f:close()

		f = io.open(tmpDir..'/'..name..'.lua',"w")
		f:write(content)
		f:close()
end

function lib.preparePreCompute(tmpDir, sourceDir, args)
	for i,obj in ipairs(args['precomputes']) do

		-- copy the objective file
		lib.copyFile(obj, sourceDir, tmpDir)

		-- store objective path for the dakota input file
		table.insert(lib.precomputes_path, (OSMOSE_ENV["LUA_EXE"] or 'lua')..' '..tmpDir..'/'..obj..'_wrapper.lua')

		-- write objective wrapper
		f = io.open(tmpDir..'/'..obj..'_wrapper.lua',"w")
		f:write(lib.readParams )
		f:write(lib.connectOsmose)

		-- write code to call function
		f:write(string.format("\nrequire '%s/%s'", tmpDir, obj))
		f:write(string.format("\nlocal result = %s(params)", obj))
		f:close()

	end

end

function lib.prepareObjective(tmpDir,sourceDir, args)
	-- copy the objectives function and wrapper files
	for i,obj in ipairs(args['objectives']) do

		-- copy the objective file
		lib.copyFile(obj, sourceDir, tmpDir)

		-- store objective path for the dakota input file
		table.insert(lib.objectives_path, (OSMOSE_ENV["LUA_EXE"] or 'lua')..' '.. tmpDir..'/'..obj..'_wrapper.lua')

		-- write objective wrapper
		f = io.open(tmpDir..'/'..obj..'_wrapper.lua',"w")
		f:write(lib.readParams )
		f:write(lib.connectOsmose)

		-- write code to call function
		f:write(string.format("\nrequire '%s/%s'", tmpDir, obj))
		f:write(string.format("\nlocal result = %s(params)", obj))
		f:write(lib.writeResult)
		f:close()

	end
end

function lib.prepareVariables(variables)
	for name, option in pairs(variables) do
		local variable = {}
		variable.name = name
		variable.lower_bound = option.lower_bound
		variable.upper_bound = option.upper_bound
		variable.initial = option.initial
		table.insert(lib.variables, variable)
	end
end

function lib.prepareFiles(tmpDir,sourceDir, args)

	local file_dakota_version = assert(io.popen((OSMOSE_ENV["DAKOTA_EXE"] or 'dakota')..' -v' ,"r"))
	local dakota_version = file_dakota_version:read('*all')
	file_dakota_version:close()
	print(dakota_version)

	lib.prepareObjective(tmpDir,sourceDir, args)	

	lib.preparePreCompute(tmpDir,sourceDir, args)

	lib.prepareVariables(args.variables)

	local method = args['method']

	-- load dakota template for input
	local dakota_template
	print('Dakota method is', method.name)
	if method.name == 'moga' then
		local f,err = assert(io.open(lub.path('&'):gsub('dakotaHelper.lua','')..'../templates/dakota_in_moga_v60.mustache'))
		dakota_template = f:read('*a')
		f:close()
	else
		local f,err = assert(io.open(lub.path('&'):gsub('dakotaHelper.lua','')..'../templates/dakota_in_v60.mustache'))
		dakota_template = f:read('*a')
		f:close()
	end

	method.max_iterations = method.max_iterations or 50

	local graphics = args['graphics']

	local graphics_path = tmpDir..'/graphics.dat'

	-- fill the dakota template
	local dakota = lustache:render(dakota_template, 
		{method=method,
		objectives=lib.objectives_path,
		objectives_size=args['objectives_size'],
		precomputes = lib.precomputes_path,
		variables = lib.variables,
		variables_size=table.getn(lib.variables),
		params_in = tmpDir..'/params.in',
		results_out = tmpDir..'/results.out',
		graphics_path = graphics_path,
		graphics = graphics,
		})

	-- store the template in dakota.in file
	local dakota_in = tmpDir..'/dakota.in'
	local f = io.open(dakota_in,"w")
	f:write(dakota)
	f:close()

	-- create stop.lua file
	f = io.open(tmpDir..'/stop.lua',"w")
	f:write(lib.stop)
	f:close()

	local dakota_out = tmpDir..'/dakota.out'
	local dakota_err = tmpDir..'/dakota.err'

	return 	(OSMOSE_ENV["DAKOTA_EXE"] or 'dakota').. 
					' -i '..dakota_in..
					' -o '..dakota_out..
					' -e '..dakota_err

end


return lib