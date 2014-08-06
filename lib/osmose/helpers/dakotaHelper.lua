local lib={}
local lustache = require "osmose.eiampl.vendor.lustache"
local lub = require 'lub'

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
f:write(tostring(result)..'/n')
f:close()
]]

lib.objectives_path={}	
lib.precomputes_path={}
lib.postcomputes_path={}

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
		table.insert(lib.precomputes_path, tmpDir..'/'..obj..'_wrapper.lua')

		-- write objective wrapper
		f = io.open(tmpDir..'/'..obj..'_wrapper.lua',"w")
		f:write(lib.readParams )

		-- write code to load project
		f:write("local serpent = require 'serpent'")
		f:write(string.format("local f = io.open('%s/project.dump','r')", tmpDir))
		f:write("local dump = f:read('*a')")
		f:write("f:close()")
		f:write("local ok, project = serpent.load(dump)")

		-- write code to call function
		f:write(string.format("require '%s/%s'", tmpDir, obj))
		f:write(string.format("local result = %s(params)", obj))
		f:close()

	end

end

function lib.prepareObjective(tmpDir,sourceDir, args)
	-- copy the objectives function and wrapper files
	for i,obj in ipairs(args['objectives']) do

		-- copy the objective file
		lib.copyFile(obj, sourceDir, tmpDir)

		-- store objective path for the dakota input file
		table.insert(lib.objectives_path, tmpDir..'/'..obj..'_wrapper.lua')

		-- write objective wrapper
		f = io.open(tmpDir..'/'..obj..'_wrapper.lua',"w")
		f:write(lib.readParams )

		-- write code to load project
		f:write("local serpent = require 'serpent'")
		f:write(string.format("local f = io.open('%s/project.dump','r')", tmpDir))
		f:write("local dump = f:read('*a')")
		f:write("f:close()")
		f:write("local ok, project = serpent.load(dump)")

		-- write code to call function
		f:write(string.format("require '%s/%s'", tmpDir, obj))
		f:write(string.format("local result = %s(project,params)", obj))
		f:write(lib.writeResult)
		f:close()

	end
end

function lib.prepareFiles(tmpDir,sourceDir, args)

	lib.prepareObjective(tmpDir,sourceDir, args)	

	lib.preparePreCompute(tmpDir,sourceDir, args)

	-- load dakota template for input
	local f,err = assert(io.open(lub.path('&'):gsub('dakotaHelper.lua','')..'../templates/dakota_in.mustache'))
	local dakota_template = f:read('*a')
	f:close()

	-- fill the dakota template
	local dakota = lustache:render(dakota_template, 
		{method=args['method'],
		objectives=lib.objectives_path,
		objectives_size=table.getn(args['objectives']),
		})

	-- store the template in dakota.in file
	local dakota_in = tmpDir..'/dakota.in'
	local f = io.open(dakota_in,"w")
	f:write(dakota)
	f:close()

	return 'dakota -i '.. dakota_in

end


return lib