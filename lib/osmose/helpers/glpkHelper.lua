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
    --  HC_Rk[DefaultHeatCascade,mt_test_def_location,2,4].val = 90
		local param, layer, tag, time,int, value = line:match("(.*)%[([%w_]+),([%w_]*),*(%d*),*(%d*)%].*=%s*(%d*.*)")
    
    -- Recover the cost values (Stephane Laurent Bungener <stephane.bungener@epfl.ch>)
    if param == nil then
      local c,d = line:find("Costs_Cost%[")
      if (c ~= nil) then
        local param1, layer1, value1 = line:match("(.*)%[([%w_]+)%].*=%s*(%d*.*)")
          local oper1,oper2 = layer1:find("DefaultOpCost")
          local inver1,inver2 = layer1:find("DefaultInvCost")
          local mecher1,mercher2 = layer1:find("DefaultMechPower")
          local impacter1,impacter2 = layer1:find("DefaultImpact")
          if oper1 ~= nil then
               project.results.opcost[periode] = tonumber(value1)
          elseif impacter1  ~= nil then
               project.results.impact[periode] = tonumber(value1)
          elseif mecher1 ~= nil then
               project.results.mechpower[periode] = tonumber(value1)
          elseif inver1  ~= nil then
               project.results.invcost[periode] = tonumber(value1)
          end
      end 
    end
      
		-- We need to store the heat load for the Grant Composite Curve (GCC)
		if param == 'HC_Rk' then
			--print(param, layer, tag, time,int, value)
			--print(time, int, project.results.gcc[periode][tonumber(time)])
			project.results.gcc[periode][tonumber(time)][tonumber(int)].Q = tonumber(value)
		end
    
    -- Recover the Units_Mult_t values (Stephane Laurent Bungener <stephane.bungener@epfl.ch>)
    if param == 'Units_Mult_t' then
     
      --tag is time
      --layer is stream name
      -- value is mult
      for uniter=1,table.getn(project.units[periode]) do 
          units = project.units[periode][uniter]
          if units.name == layer then
            local param1, tag1, time1, value1 = line:match("(.*)%[([%w_]+),*(%d*)%].*=%s*(%d*.*)")
            if not units.mult_t then
              project.units[periode][uniter].mult_t = {tonumber(value1)}
            else
              table.insert(project.units[periode][uniter].mult_t,tonumber(value1))
            end
          end
        
      end
    end
    
    -- Recover the Units_Use_t values (Stephane Laurent Bungener <stephane.bungener@epfl.ch>)
    if param == 'Units_Use_t' then
     
      --tag is time
      --layer is stream name
      -- value is mult
      for uniter=1,table.getn(project.units[periode]) do 
          units = project.units[periode][uniter]
          if units.name == layer then
            local param1, tag1, time1, value1 = line:match("(.*)%[([%w_]+),*(%d*)%].*=%s*(%d*.*)")
            if not units.use_t then
              project.units[periode][uniter].use_t = {tonumber(value1)}
            else
              table.insert(project.units[periode][uniter].use_t,tonumber(value1))
            end
          end
        
      end
    end
    
    
     
--       if param == 'Costs_Cost_t' then
     
--      --tag is time
--      --layer is stream name
--      -- value is mult
--           local param1, tag1, time1, value1 = line:match("(.*)%[([%w_]+),*(%d*)%].*=%s*(%d*.*)")
--            if not project.results.cost_t then
--              project.results.cost_t = {tonumber(value1)}
--            else
--              table.insert(project.results.cost_t,tonumber(value1))
--            end
--        end
        
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
					print(tag,"P="..periode,"T="..time,value)
					project.results.delta_hot[periode][tonumber(time)] = tonumber(value)
				elseif tag:find("DHCS_c") then
					print(tag,"P="..periode,"T="..time,value)
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