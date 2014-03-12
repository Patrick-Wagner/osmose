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
local lustache = require "lib.osmose.eiampl.vendor.lustache"


function lib.new(project, format)
	
	if OSMOSE_ENV["GNUPLOT_EXE"] == nil then
		print('Gnuplot executable must be specified config.lua file with OSMOSE_ENV["GNUPLOT_EXE"] variable.')
		os.exit()
	end

	for periode in ipairs(project.periodes) do 
		local units = project.units[periode]
		for time=1, project.periodes[periode].times do
			-- Split of hot and cold streams.
			local hotStreams, coldStreams = lib.splitHotAndCold(units,periode,time)

			if hotStreams==nil and coldStreams==nil then
				print('Could not draw graph')
				os.exit()
			end

			-- Cumulation of streams Heat Load
			local hotCurve 	= lib.getCumulateHeatLoad(hotStreams,time)
		  local coldCurve = lib.getCumulateHeatLoad(coldStreams,time)

		  -- Composite Curve creation
		  local hotCC  = lib.getCompositeCurve(hotCurve)
		  local coldCC = lib.getCompositeCurve(coldCurve)

		  -- We translate the cold curve according the solver result (self.delta_hot)
		  local coldLoad = (coldCC[table.getn(coldCC)].Q)
		  local coldLoadTarget = (hotCC[table.getn(hotCC)].Q) + project.delta_hot
		  local deltaLoad = coldLoadTarget - coldLoad

		  for i,stream in pairs(coldCC) do
		  	stream.Q = stream.Q + deltaLoad
		  end


		  -- Write the data for Gnuplot
			local dir = ('./results/'..project.name..'/run_'..project.run..'/periode_'..periode..'/')

			local coldCC = lib.equlibrateCurve(hotCC, coldCC) 

			-- Add hot temperatures points into cold curve
			local coldCC = lib.addPoints(hotCC, coldCC)
			

			-- Add cold temperatures points into hot curve
			local hotCC 	= lib.addPoints(coldCC, hotCC) 

			-- Draw the composite curve
			local datas = {	{curve=hotCC, file=string.format('hotCC%i.txt',time),	title="Hot streams", lc=1}, 
											{curve=coldCC, file=string.format('coldCC%i.txt',time), title="Cold streams", lc=3}}
			lib.plotCurves(dir, periode, time, format, datas, "Composite Curve")

			-- Get the Grand Composite Curve (temperature difference between hot and cold)
			-- local GCCcurve = lib.getGCCcurve(hotCC, coldCC)
			-- local datas = {{curve=GCCcurve, file=string.format('GCC%i.txt',time), title="All streams", lc=1} }
			-- lib.plotCurves(dir, periode, time, format, datas, "Grand Composite Curve")

			local GCCcurve2 =  project.results.gcc[periode][time] 
			if project.objective == 'MER' then
				table.remove(GCCcurve2, 1)
				table.remove(GCCcurve2, 1)
				table.remove(GCCcurve2, table.getn(GCCcurve2))
				table.remove(GCCcurve2, table.getn(GCCcurve2))
			end
			local datas = {{curve=GCCcurve2, file=string.format('GCC%i.txt',time), title="All streams", lc=1} }
			--lib.plotCurves(dir, periode, time, format, datas, "Grand Composite Curve")

			hotCC, coldCC = lib.cc2(GCCcurve2, project.delta_hot)
			local datas = {	{curve=hotCC, file=string.format('hotCC%i.txt',time),	title="Hot streams", lc=1}, 
											{curve=coldCC, file=string.format('coldCC%i.txt',time), title="Cold streams", lc=3}}
			--lib.plotCurves(dir, periode, time, format, datas, "Composite Curve")
		end
	end -- for periodes loop

end

function lib.cc2(curve, delta_hot)
	local hotCC={}
	local coldCC={}
	for i, stream in ipairs(curve) do
		if stream.isHot then
			table.insert(hotCC, stream)
		else
			table.insert(coldCC, stream)
		end
	end

	table.sort(coldCC, function(a,b) return a.T<b.T  end)

	-- cumulative CP
	for i, stream in ipairs(coldCC) do
		local t = stream.T
		local cp = 0
		if t > stream.Tin_corr and t <= stream.Tout_corr then
			cp = cp + ((stream.Hin - stream.Hout) / (stream.Tin_corr - stream.Tout_corr))
		end
		stream.CP = cp
	end

	local lastTemp=0
	for i, stream in ipairs(coldCC) do
		local deltaT = stream.T - lastTemp
		stream.Q = stream.Q + (stream.CP * deltaT)
		lastTemp = stream.T
	end

	

	return hotCC, coldCC
end



-- If a temperature is between the Tmin and Tmax of a stream, a cumulative slope is calculated.
function lib.getCompositeCp(streams,t)
	local cp = 0
	for i,stream in pairs(streams) do
		if t > stream.Tmin and t <= stream.Tmax then
			cp = cp + stream.CP
		end
	end
	return cp
end


-- The hot streams and cold streams are dispatched in different arrays and are sorted by their minimal temperature.
-- Tmin and Tmax are defined for each stream.
function lib.splitHotAndCold(units, periode, time)
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
				if stream.isHot(model) then
					stream.Tmin = stream.Tout_corr(model)
					stream.Tmax = stream.Tin_corr(model)
					--stream.CP = (stream.Hin(model)-stream.Hout(model))/(stream.Tmax-stream.Tmin)
					table.insert(hotStreams, stream)
				elseif stream.load[time] then
					stream.Tmin = stream.Tin_corr(model)
					stream.Tmax = stream.Tout_corr(model)
					--stream.CP = (stream.Hin(model)-stream.Hout(model))/(stream.Tmin-stream.Tmax)
					table.insert(coldStreams, stream)
				else
					print('Could not draw graph. No Heat Load for stream', stream.name)
					os.exit()
				end
			end
		end

	end

	-- Sort cold and hot streams
	table.sort(hotStreams, function(a,b) return a.Tmax<b.Tmax end)
	table.sort(coldStreams, function(a,b) return a.Tmin<b.Tmin end)
	
	return hotStreams, coldStreams
end

-- The cumulative Heat Load of the streams is calculated from the Tmin to the Tmax.
function lib.getCumulateHeatLoad(streams,time)
	local curve = {}
	local Q = 0
	local Tmin = 0
	local Tmax = 0
	for i,stream in pairs(streams) do
		--If 2 streams have same Temperature boundaries, only 1 is kept but the heat load is cumulated.
		if stream.Tmin == Tmin and stream.Tmax == Tmax then
			curve[i] = {Tmin = stream.Tmin, Qmin=curve[i-1].Qmin, Tmax=stream.Tmax, Qmax = curve[i-1].Qmax + stream.load[time] }
			Q=curve[i-1].Qmax + stream.load[time]
			curve[i-1] = nil
		else
			curve[i] = {Tmin = stream.Tmin, Qmin=Q, Tmax=stream.Tmax, Qmax = Q+stream.load[time] }
			Q=Q+stream.load[time] 
		end
		curve[i] = {Tmin = stream.Tmin, Qmin=Q, Tmax=stream.Tmax, Qmax = Q+stream.load[time] }
		Q=Q+stream.load[time] 

		Tmin = stream.Tmin
		Tmax = stream.Tmax
	end

	return curve
end


function lib.getCompositeCurve(curve)
	-- Slope (CP) can be defined by the slope of the Q/T diagram.
	for i, stream in pairs(curve) do
		stream.CP = (stream.Qmax-stream.Qmin) / (stream.Tmax-stream.Tmin)
		if stream.CP < 0 then
			print('Stream slope is negative:',stream.name, stream.CP)
			os.exit()
		end
	end
	
	-- We calculate the composte slope of each stream curve. We sum the slope for temperature intervals 
  -- which are between a larger stream.
	local compositeCP={}
	for i, stream in pairs(curve) do
		compositeCP[stream.Tmin] = compositeCP[stream.Tmin] or lib.getCompositeCp(curve,stream.Tmin)
		compositeCP[stream.Tmax] = compositeCP[stream.Tmax] or lib.getCompositeCp(curve,stream.Tmax)
	end

	-- We build an associative array with the Temperature (T) and it's composite slope (CP).
	-- This array is sorted asc by Temperature
	local compositeCurve={}
	for t, cp in pairs(compositeCP) do
		table.insert(compositeCurve, {T=t,CP=cp})
	end
	table.sort(compositeCurve, function(a,b) return a.T<b.T end)

	-- We need to cumulate the Heat capacity (Q) for each temperature. The heat capacity is calculate as the 
	-- differential temperature multiplied by the slope : (∆T) * CP. 
	local Q=0
	for i,cc in pairs(compositeCurve) do
		local q = (cc.T - (compositeCurve[i-1] or cc).T)*cc.CP
		cc.Q = Q + q
		Q=Q+q
	end

	return compositeCurve
end


function lib.equlibrateCurve(fromCurve, toCurve) 

	local returnCurve = {}
	if fromCurve[1].T < toCurve[1].T then
		for i,c in ipairs(toCurve) do
			table.insert(returnCurve, c)
		end

		local intoT = fromCurve[1].T
		local intoQ = toCurve[1].Q
		--print('heat load: ', intoQ)
		table.insert(returnCurve, {T=intoT, Q=intoQ, CP=0})
		--print('equilibre', intoT-273, intoQ)
		table.sort(returnCurve, function(a,b) return a.T<b.T end)
	else
		returnCurve = toCurve
	end
	


	return returnCurve
end


-- Used for the Grand Composite Curve.
-- It completes a 'toCurve' with missing temperatures that comes from a 'fromCurve'.
-- It returns the 'toCurve' with new temparatures 'toCurve' have the same temperature that 'formCurve'.
function lib.addPoints(fromCurve, toCurve) 
	local returnCurve = {}
	for i,c in ipairs(toCurve) do
		table.insert(returnCurve, c)
	end
	local fromTT = fromCurve[1].T


	local GCC={}
	for f,fromP in ipairs(fromCurve) do
		local fromT, fromQ 	= fromP.T, fromP.Q
		local intoT, intoQ	= 0,0
		local minT, maxT 	= fromP.T,0
		local minQ, maxQ 	= 0,0
		local minCP = 0
		
		local inserted = false
		
		for i, intoP in ipairs(toCurve) do

			maxT = intoP.T 
			maxQ = intoP.Q

			 
			if fromT >= minT and fromT < maxT then
				intoT = fromT
				intoQ = minQ + (intoT-minT)*intoP.CP
				table.insert(returnCurve, {T=intoT, Q=intoQ})

				inserted = true
			end
			minT = maxT
			minQ = maxQ
		end 
	
		
		if not inserted then
			table.insert(returnCurve, {T=fromT, Q=minQ})
		end
	end

	table.sort(returnCurve, function(a,b) return a.T<b.T end)

	return returnCurve
end


function lib.getGCCcurve(hotCC, coldCC)
	local gccT=0
	local gccQ=0
	local GCCcurve={}
	for h,hotP in ipairs(hotCC) do
		for c,coldP in ipairs(coldCC) do
			if hotP.T == coldP.T then
				gccT = hotP.T
				gccQ = (coldP.Q - hotP.Q)
				table.insert(GCCcurve, {T=gccT, Q=gccQ})
			end
		end
	end
	table.sort(GCCcurve, function(a,b) return a.T<b.T end)
	return GCCcurve
end


function lib.writeGnuplotDataFile(filepath, curve)
	local f = io.open(filepath,"w")
	for i,cc in ipairs(curve) do
		f:write(cc.Q.." "..(cc.T-273).."\n")
	end
	f:close()
end

function lib.writeScriptPlot(dir, periode, time, format, datas, title)

	-- range scalling
	local minX,maxX,minY,maxY= 100000,0,100000,0

	for d,data in ipairs(datas) do
		for c, point in ipairs(data.curve) do
			if point.T < minY then
				minY = point.T
			end
			if point.T > maxY then
				maxY = point.T
			end
			if point.Q < minX then
				minX = point.Q
			end
			if point.Q > maxX then
				maxX = point.Q
			end
		end
	end

	minX=(minX )
	maxX=(maxX + 0.05*maxX)
	minY=(minY ) - 273
	maxY=(maxY + 0.05*maxY) - 273


	local script = ""
	if format then
		script = [[
set terminal {{format}}
set output "{{dir}}{{graphTitle}}{{time}}.{{format}}"
	]]
	end

	script = script .. [[
set title "{{graphTitle}} for Periode {{periode}} and Time {{time}}"
set xlabel "Heat Load [kW]"
set ylabel "Temperature [C]"
set xrange [{{minX}}:{{maxX}}]
set yrange [{{minY}}:{{maxY}}]
plot {{#datas}}"{{dir}}{{file}}" title "{{title}}" w lp lc {{lc}},{{/datas}}
]]

	local values = {	
						format = format, 
						periode=periode, 
						time=time, 
						dir=dir, 
						datas=datas, 
						graphTitle=title,
						minX=minX, maxX=maxX, minY=minY, maxY=maxY }

	script = lustache:render(script, values )
	script = string.gsub(script, "&#x2F;", "/")
	script = string.gsub(script, ',%s*$','')
	--print(script)
	local filePath = dir.."script2file.txt"
	local f = io.open(filePath,"w")
	f:write(script)
	f:close()

	return filePath
end

function lib.plotScript(script)
	-- Gnuplot
	-- If output is specifed, 'persist' option (-p) is not needed and the graph will be saved.
	local cmd
	if format then
		cmd = (OSMOSE_ENV["GNUPLOT_EXE"] .. ' ' .. script)
	else
  	cmd = (OSMOSE_ENV["GNUPLOT_EXE"] .. ' -p ' .. script)
  end
  os.execute(cmd)
end

function lib.plotCurves(dir, periode, time, format, datas, title)
	
	for i, data in ipairs(datas) do
		lib.writeGnuplotDataFile(dir..data.file, data.curve)
	end
	local script = lib.writeScriptPlot(dir,periode,time,format, datas, title)

	lib.plotScript(script)

end


return lib
