local lub = require 'lub'
local lib = {}

-- Function that parse the default GLPK result file.
function lib.parseResultGlpkFile(project, tmp_dir, periode)

	project.result = {}
	-- Opening the result file.
	local f = assert(io.open(tmp_dir..project.result_filename,"r"))
	-- Reading each line.
	for line in f:lines() do

		-- Capture the param, domain, value regarding the pattern "param[domaine].val = value"
		local param, layer, tag, time,int, value = line:match("(.*)%[([%w_]+),([%w_]*),*(%d*),*(%d*)%].*=%s*(%d*.*)")
		
		-- We need to store the heat load for the Grant Composite Curve (GCC)
		if param == 'HC_Rk' then
			--print(param, layer, tag, time,int, value)
			--print(time, int, project.results.gcc[periode][tonumber(time)])
			project.results.gcc[periode][tonumber(time)][tonumber(int)].Q = tonumber(value)
		end

		-- Storing the returned heat load for each stream
		if param == 'Streams_Q' then
			for i, unit in ipairs(project.units[periode]) do 
				local model = unit.model
				for i, stream in ipairs(unit.streams) do
					if tag:find(stream.name) then
						stream.load[tonumber(time)] = tonumber(value)
					end
				end
			end

			if project.objective == 'MER'  then
				if tag:find("DHCS_h") then
					print("DHCS_h","P="..periode,"T="..time,value)
					project.results.delta_hot[periode][tonumber(time)] = tonumber(value)
				elseif tag:find("DHCS_c") then
					print("DHCS_c","P="..periode,"T="..time,value)
					--project.delta_cold = value
					project.results.delta_cold[periode][tonumber(time)] = tonumber(value)
				end
			else
				project.delta_hot = 0
				project.delta_cold = 0
			end
		end
	end
	f:close()
end



return lib