echo — run dakota shell command

# the value Stream_Dakota must be defined as a shell variable
# Pre-Computing here

cd /Users/minjyoo/Documents/workspace/LuaOsmose_Evolved/src
lua projects/Stream_Dakota.lua 'params.in' 'results.out'

mv /Users/minjyoo/Documents/workspace/LuaOsmose_Evolved/src/results.out /usr/local/dakota-5.4.0.Darwin.i386/examples/script_interfaces/Lua/stream_model.$num


# Post-Computing here

