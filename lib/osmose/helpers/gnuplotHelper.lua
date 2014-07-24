local lub = require 'lub'
local lib = {}

local lustache = require "lib.osmose.eiampl.vendor.lustache"

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
set font 'Verdana,14'  
set output "{{dir}}{{graphTitle}}{{time}}.{{format}}"
	]]
	end

	script = script .. [[
 set title "{{graphTitle}} for Periode {{periode}} and Time {{time}}"
 set font '"Verdana",10'  
set xlabel "Heat Load [MW]"
set ylabel "Temperature [C]"
set xrange [{{minX}}:{{maxX}}]
set yrange [{{minY}}:{{maxY}}]
# define grid
set style line 12 lc rgb '#808080' lt 0 lw 1
set grid back ls 12
plot {{#datas}}"{{dir}}{{file}}" title "{{title}}" w lp lc {{lc}} pt 0 ps 0.3,{{/datas}}
]]
--set xlabel "Heat Load [MW]"
--set ylabel "Temperature [C]"
--set xrange [{{minX}}:{{maxX}}]
--set yrange [{{minY}}:{{maxY}}]
--set mouse zoomcoordinates
--set mxtics
--set mytics
--set style line 13 lc rgb '#707070' lt 1 lw 0.5
--set grid xtics mxtics ytics mytics back ls 13
--
--plot {{#datas}}"{{dir}}{{file}}" title "{{title}}" w l lw 2 lc {{lc}},{{/datas}}


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