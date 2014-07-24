

echo ——————————————————

# set num `cat tempf | cut -c80-85`
#echo found number is
#echo $num


cd /Users/minjyoo/Documents/workspace/LuaOsmose_Evolved/src
# the path name should be replaced with the name of your directory 

lua projects/Stream_Dakota.lua ‘params.in’ ‘results.out’ 

# echo ls results.out
# ls /Users/minjyoo/Documents/workspace/LuaOsmose_Evolved/src/results.out
# above command lines if you want to check the result file

mv /Users/minjyoo/Documents/workspace/LuaOsmose_Evolved/src/results.out /usr/local/dakota-5.4.0.Darwin.i386/examples/script_interfaces/Lua/results.$num
# move the result file to your Dakota working directory 
# Ensure whether your dakota/example directory has the /script_interfaces/Lua sub-directory

