local lub 	= require 'lub'
local lib 	= lub.class 'osmose.Layer'


function lib.new(name, args)
	if not args.type then
		print('Layer should have a type:',name)
		os.exit()
	end

	local layer = lub.class(args.type)
	setmetatable(layer, lib)

	layer.name = name
	layer.streams = {}
	for key, val in pairs(args) do
		layer[key]=val
	end
	return layer
end


return lib