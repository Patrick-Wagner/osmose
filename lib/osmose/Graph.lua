--[[---------------------------------------
  
  # Graph

	Create a Gnuplot graph. Just create new instance to create plain Gnuplot graph.

	Exemple:
		osmose.Graph(project)

	An output can be specified to created. This to be used for multitimes project.

	Exemple to create SVG files :
		osmose.Graph(project, 'svg') 

--]]---------------------------------------

local lub 	= require 'lub'
local lib 	= lub.class 'osmose.Graph'


function lib.new(project, format)
	
	if OSMOSE_ENV["GNUPLOT_EXE"] == nil then
		print('Gnuplot executable must be specified config.lua file with OSMOSE_ENV["GNUPLOT_EXE"] variable.')
		os.exit()
	end

	local helper = require 'osmose.helpers.gnuplotHelper'

	for periode in ipairs(project.periodes) do 
		--local units = project.units[periode]
		for time=1, project.periodes[periode].times do

			local dir = ('./results/'..project.name..'/run_'..project.run..'/periode_'..periode..'/')

			-- ===========
			-- Drawing GCC
			-- ===========
			local GCCcurve2 =  project.results.gcc[periode][time] 
			if project.objective == 'MER' then
				table.remove(GCCcurve2, 1)
				table.remove(GCCcurve2, 1)
				table.remove(GCCcurve2, table.getn(GCCcurve2))
				table.remove(GCCcurve2, table.getn(GCCcurve2))
			end
			local datas = {{curve=GCCcurve2, file=string.format('GCC%i.txt',time), title="All streams", lc=1} }
			helper.plotCurves(dir, periode, time, format, datas, "Grand Composite Curve")


			-- ===========
			-- Drawing CC
			-- ===========

			-- Split of hot and cold streams.
			local hotStreams, coldStreams = lib.splitHotAndCold(project,periode,time)

			if hotStreams==nil and coldStreams==nil then
				print('Could not draw graph')
				os.exit()
			end

			-- Cumulation of streams Heat Load
			local hotStreams 	= lib.getCumulateHeatLoad(hotStreams,time)
		  local coldStreams = lib.getCumulateHeatLoad(coldStreams,time)

		  -- Composite Curve creation
		  local hotCC  = lib.getHotCC(hotStreams)
		  local coldCC = lib.getColdCC(coldStreams)


		  -- We translate the cold curve according the solver result (self.delta_hot)
		  if project.objective == 'MER' then
		  	print('Delta hot =', project.delta_hot)
		  	local coldLoad = coldCC[table.getn(coldCC)].Q
		 	  local coldLoadTarget = (hotCC[1].Q) + project.delta_hot
		 	  local deltaLoad = coldLoadTarget - coldLoad
			  for i,stream in pairs(coldCC) do
			  	stream.Q = stream.Q + deltaLoad
			  end

			  local hotCC, coldCC = lib.complete(hotCC,coldCC, GCCcurve2)
		 	else
		 		local hotCC, coldCC = lib.complete(hotCC,coldCC, GCCcurve2)
		 	end

			-- Draw the composite curves 
			local datas = {	{curve=hotCC, file=string.format('hotCC%i.txt',time),	title="Hot streams", lc=1}, 
											{curve=coldCC, file=string.format('coldCC%i.txt',time), title="Cold streams", lc=3}}
			helper.plotCurves(dir, periode, time, format, datas, "Composite Curve")

		end
	end -- for periodes loop

end

function lib.complete(hotCurve, coldCurve, gccCurve)

	local presentCold = nil
	local presentHot = nil
	for i,streamGcc in ipairs(gccCurve) do

		-- look in cold curve if gcc temp is present
		for c, streamCold in ipairs(coldCurve) do
			if streamCold.T == streamGcc.T then
				presentCold = streamCold
				
			end
		end

		-- look in hot curve if fcc temp is present
		for h, streamHot in ipairs(hotCurve) do
			if streamHot.T == streamGcc.T then
				presentHot = streamHot
			end
		end

		if presentCold ~= nil and presentHot == nil  then
			--print('complete hot', streamGcc.T, streamGcc.Q, presentCold.Q, (presentCold.Q - streamGcc.Q), '--'  )
			table.insert(hotCurve, {T=streamGcc.T, Q=(presentCold.Q - streamGcc.Q)})
		end
		
		if presentHot ~= nil and presentCold == nil then
			--print('complete cold', streamGcc.T, streamGcc.Q, presentHot.Q, (streamGcc.Q + presentHot.Q), '--'  )
			table.insert(coldCurve, {T=streamGcc.T, Q=(streamGcc.Q + presentHot.Q)})
		end

		presentCold = nil
		presentHot = nil

	end

	table.sort(coldCurve, function(a,b) return a.T<b.T end)
	table.sort(hotCurve, function(a,b) return a.T>b.T end)

	return coldCurve, hotCurve

end


-- If a temperature is between the Tmin and Tmax of a stream, a cumulative slope is calculated.
function lib.getCompositeCp(streams,t)
	local cp = 0
	for i,stream in pairs(streams) do
		-- if t > stream.Tmin and t <= stream.Tmax then
		-- 	cp = cp + stream.CP
		-- end
		if stream.isHot then
			if t >= stream.Tout_corr and t < stream.Tin_corr then
				cp = cp + stream.CP
			end
		else
			if t > stream.Tin_corr and t <= stream.Tout_corr then
				cp = cp + stream.CP
			end
		end
	end
	
	return cp
end






-- The hot streams and cold streams are dispatched in different arrays and are sorted by their minimal temperature.
-- Tmin and Tmax are defined for each stream.
function lib.splitHotAndCold(project, periode, time)
	local units = project.units[periode]
	local delta_hot = tonumber(project.delta_hot)
	local hotStreams={}
	local coldStreams={}
	for i, unit in ipairs(units) do 
		
		local model = unit.model
		if model then
			model.periode = periode
			model.time = 1
		end
		for i, stream in ipairs(unit.streams) do
			if stream.draw ~= false then	
				stream.isHot = stream.isHot(model)
				stream.Tin_corr = stream.Tin_corr(model)
				stream.Tout_corr = stream.Tout_corr(model)
				stream.Hin = stream.Hin(model)
				stream.Hout = stream.Hout(model)
				stream.Q = stream.load[time]
				

				if stream.isHot and stream.Q then
					if project.objective == 'MER' and delta_hot <= 0.001 and delta_hot >= -0.001 then
						stream.CP = (stream.Hin - stream.Hout) / (stream.Tin_corr - stream.Tout_corr)
					else
						stream.CP 	= stream.Q / (stream.Tin_corr - stream.Tout_corr)
					end
					stream.CP 	= stream.Q / (stream.Tin_corr - stream.Tout_corr)
					table.insert(hotStreams, stream)
					--print('hot', stream.name, stream.Tin_corr-273, stream.Tout_corr-273, stream.Q, stream.CP)
				elseif stream.Q then
					if project.objective == 'MER' and delta_hot <= 0.001 and delta_hot >= -0.001 then
						stream.CP = (stream.Hin - stream.Hout) / (stream.Tin_corr - stream.Tout_corr)
					else
						stream.CP 	= stream.Q / (stream.Tout_corr - stream.Tin_corr)
					end
					stream.CP 	= stream.Q / (stream.Tout_corr - stream.Tin_corr)
					table.insert(coldStreams, stream)
				else
					print('Could not draw graph. No Heat Load for stream', stream.name)
					os.exit()
				end
			end
		end

	end

	-- Sort cold and hot streams
	-- table.sort(hotStreams, function(a,b) return a.Tin_corr<b.Tin_corr end)
	-- table.sort(coldStreams, function(a,b) return a.Tout_corr<b.Tout_corr end)
	
	return hotStreams, coldStreams
end

-- The cumulative Heat Load of the streams is calculated from the Tmin to the Tmax.
function lib.getCumulateHeatLoad(streams,time)
	local curve = {}
	local Q = 0
	local Tmin = 0
	local Tmax = 0
	for i,stream in pairs(streams) do
		stream.Q = stream.Q+ Q
		Q = stream.Q
	end

	return streams
end

function lib.getColdCC(streams)

	local compositeCP={}
	for i, stream in pairs(streams) do
		--print('COLD CP', stream.CP, stream.Tin_corr, stream.Tout_corr )
		compositeCP[stream.Tin_corr] = lib.getCompositeCp(streams,stream.Tin_corr)
		compositeCP[stream.Tout_corr] = lib.getCompositeCp(streams,stream.Tout_corr)
	end

	local compositeCurve={}
	for t, cp in pairs(compositeCP) do
		table.insert(compositeCurve, {T=t,CP=cp})
	end
	table.sort(compositeCurve, function(a,b) return a.T<b.T end)

	local Q=0
	for i,cc in pairs(compositeCurve) do
		local q = (cc.T - (compositeCurve[i-1] or cc).T)*cc.CP
		cc.Q = Q + q
		Q=Q+q
		--print('--', cc.T-273, (compositeCurve[i-1] or cc).T, cc.CP)
	end

	return compositeCurve

end


function lib.getHotCC(streams)

	local compositeCP={}
	for i, stream in pairs(streams) do
		--print('HOT CP', stream.CP, stream.Tin_corr, stream.Tout_corr )
		compositeCP[stream.Tin_corr] = lib.getCompositeCp(streams,stream.Tin_corr)
		compositeCP[stream.Tout_corr] = lib.getCompositeCp(streams,stream.Tout_corr)
	end

	local compositeCurve={}
	for t, cp in pairs(compositeCP) do
		table.insert(compositeCurve, {T=t,CP=cp})
	end
	table.sort(compositeCurve, function(a,b) return a.T>b.T end)


	local Q=streams[table.getn(streams)].Q
	for i,cc in pairs(compositeCurve) do
		local q = (cc.T - (compositeCurve[i-1] or cc).T)*cc.CP
		cc.Q = Q + q
		Q=Q+q
		--print('--', cc.T-273, (compositeCurve[i-1] or cc).T, cc.CP)
	end

	return compositeCurve

end









return lib
