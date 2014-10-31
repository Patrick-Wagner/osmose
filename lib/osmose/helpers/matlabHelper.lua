local lib={}

function lib.copyGetOsmose(tmpDir)
	local content = [[
function [r] = getOsmose(type, name,periode,time)
	if nargin < 3
		periode = 1;
		time = 1;
	end

	echotcpip('on',3333);
	t = tcpip('localhost', 3333);
	set(t,'InputBufferSize', 30000);
	fopen(t);
	get = strcat('get',type);
	x = strjoin({get,name,int2str(periode),int2str(time),'\n'},',');
	fprintf(t,x);
	s = fgets(t);
	j = parse_json(s);
	r = j{1};
	echotcpip('off');
	fclose(t);
	delete(t);
	clear t;
end
]]

	f = io.open(tmpDir..'/'..'getOsmose.m',"w")
	f:write(content)
	f:close()
	return tmpDir.."getOsmose.m"
end

function lib.copyGetUnit(tmpDir)
	local content = [[
function [r] = getUnit(name, periose, time)
	if nargin < 3
		periode = 1;
		time = 1;
	end
	r = getOsmose('Unit',name,periode,time);
end
]]
	f = io.open(tmpDir..'/'..'getUnit.m',"w")
	f:write(content)
	f:close()
	return tmpDir.."getUnit.m"
end

function lib.copyGetStream(tmpDir)
	local content = [[
function [r] = getStream(name, periose, time)
	if nargin < 3
		periode = 1;
		time = 1;
	end
	r = getOsmose('Stream',name,periode,time);
end
]]
	f = io.open(tmpDir..'/'..'getStream.m',"w")
	f:write(content)
	f:close()
	return tmpDir.."getStream.m"
end

function lib.copyGetTag(tmpDir)
	local content = [[
function [r] = getTag(name, periose, time)
	if nargin < 3
		periode = 1;
		time = 1;
	end
	r = getOsmose('Tag',name,periode,time);
end
]]
	f = io.open(tmpDir..'/'..'getTag.m',"w")
	f:write(content)
	f:close()
	return tmpDir.."getTag.m"
end

function lib.copySetTag(tmpDir)
	local content = [[
function [r] = setTag(tag,value, periose, time)
	if nargin < 3
		periode = 1;
		time = 1;
	end
	echotcpip('on',3333);
	t = tcpip('localhost', 3333);
	set(t,'InputBufferSize', 30000);
	fopen(t);
	x = strjoin({'setTag',tag,num2str(value),int2str(periode),int2str(time),'\n'},',');
	fprintf(t,x);
	s = fgets(t);
	j = parse_json(s);
	r = j{1};
	echotcpip('off');
	fclose(t);
	delete(t);
	clear t;
end
]]
	f = io.open(tmpDir..'/'..'setTag.m',"w")
	f:write(content)
	f:close()
	return tmpDir.."setTag.m"
end

function lib.copyStop(tmpDir)
	local content = [[
disp('Matlab sending stop.');
t = tcpip('localhost', 3333, 'NetworkRole', 'client');
fopen(t);
fprintf(t,'stop\n');
fclose(t);
delete(t);
clear t;
]]

	f = io.open(tmpDir..'/'..'stop.m',"w")
	f:write(content)
	f:close()
	return tmpDir.."stop.m"
end

function lib.copyFile(name, sourceDir, tmpDir)
	f = assert(io.open(sourceDir..name..'.m','r'))
	local content = (f:read("*all"))
	f:close()

	f = io.open(tmpDir..'/'..name..'.m',"w")
	f:write(content)
	f:close()

	return tmpDir..name..'.m'
end

function lib.prepareCompute(tmpDir, sourceDir, obj)
	local wrapper = lib.copyFile(obj, sourceDir, tmpDir)
	local json = lib.copyFile('parse_json', "./lib/osmose/helpers/", tmpDir)
	local stop = lib.copyStop(tmpDir)

	lib.copyGetOsmose(tmpDir)
	lib.copyGetUnit(tmpDir)
	lib.copyGetStream(tmpDir)
	lib.copyGetTag(tmpDir)
	lib.copySetTag(tmpDir)


	return (OSMOSE_ENV["MATLAB_EXE"] or 'matlab')..' -nosplash -nodesktop'.." -r "..
				  string.format('"run(\'%s\');run(\'%s\');quit force;"',wrapper, stop) 
end

return lib