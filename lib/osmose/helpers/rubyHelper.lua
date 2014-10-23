local lib={}

lib.connectOsmose = [[
require 'socket'
require 'json'
HOST = "127.0.0.1"
PORT = 3333


def get(type,name="",periode=1,time=1)
	tcp = TCPSocket.new HOST, PORT

	tcp.send("get"<<type<<","<<name<<","<<periode.to_s<<","<<time.to_s<<"\n",0)
	str = tcp.gets().chomp
	tcp.close	
	unless str.nil? or str=="null" then 
		JSON.parse(str)
	else
		nil
	end
end

def getTag(name, periode=1, time=1)
	return get('Tag', name, periode, time)
end

def getStream(name, periode=1, time=1)
	return get('Stream', name, periode, time)
end

def getUnit(name, periode=1, time=1)
	return get('Unit', name, periode, time)
end

def getResults()
	return get('Results')
end

def setTag(tag,value, periode=1, time=1)
	tcp = TCPSocket.new HOST, PORT
	tcp.send("setTag,"<<tag<<","<<value.to_s<<","<<periode.to_s<<","<<time.to_s<<"\n",0)
	str = tcp.gets()
	puts str
	tcp.close
	return str.chomp.to_f if str
end

def solve()
	tcp = TCPSocket.new HOST, PORT
	tcp.send("solve\n",0)
	print(tcp.gets().chomp)
	tcp.close
end

def stop()
	begin
		tcp = TCPSocket.new HOST, PORT
		tcp.send("stop\n",0)
		tcp.close
	rescue
		nil
	end
end
]]

function lib.copyFile(name, sourceDir, tmpDir)
	f = assert(io.open(sourceDir..name..'.rb','r'))
	local content = (f:read("*all"))
	f:close()

	f = io.open(tmpDir..'/'..name..'.rb',"w")
	f:write(content)
	f:close()
end

function lib.prepareCompute(tmpDir, sourceDir, obj)

	lib.copyFile(obj, sourceDir, tmpDir)
	local wrapper = tmpDir..obj..'_wrapper.rb'

	f = io.open(wrapper,"w")
	f:write(lib.connectOsmose)
	f:write(string.format("\nrequire_relative '%s'",obj))
	f:write(string.format("\n%s",obj))
	f:write("\nstop")
	f:close()

	return (OSMOSE_ENV["RUBY_EXE"] or 'ruby')..' '..wrapper 

end

return lib