local lib={}


function lib.copyStop(tmpDir)
	local content = [[
disp('Matlab sending stop.');
echotcpip('on',3333);
t = tcpip('localhost', 3333, 'NetworkRole', 'client');
fopen(t);
fprintf(t,'stop\n');
echotcpip('off');
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
	local stop = lib.copyStop(tmpDir)

	return (OSMOSE_ENV["MATLAB_EXE"] or 'matlab -nosplash -nodesktop ').." -r "..
				  string.format('"run(\'%s\');run(\'%s\');quit force;"',wrapper, stop) 

end

return lib