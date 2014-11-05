Osmose
=========
Osmose is a new implementation of OSMOSE in Lua. Osmose is:

> OSMOSE is an acronym for 'OptimiSation Multi-Objectifs de Systèmes Énergétiques intégrés', Multi-Objective OptimiZation of integrated Energy Systems.

> OSMOSE is an optimization software. Its philosophy is based on the association of genetic algorithms and energy integration. This marriage allows the optimization of thermodynamic processes and a rational use of energy at the same time.

## Documentation
Please browse the project [generated doc](http://ipese.github.io/osmose/docs/osmose.html).

## Installation

### OSX and Linux

On Mac OSX and linux, the easiest way is to run these two commands :

	curl -s https://raw.github.com/ipese/osmose-install/master/install-dps | bash

	curl -s https://raw.github.com/ipese/osmose-install/master/install-osmose | bash
	
The first line will install brew (package management), glpk, gnuplot, lua and luarocks.

The secone line will install lua specific dependencies and osmose itself, which is a luarocks.

### Windows

There is an installation program that you you can [download](https://dl.dropboxusercontent.com/u/6739730/osmose/install/Osmose-install-01.exe). It will install Lua, Luarocks, Gnuplot and Glpsol.

After that you will install Osmose as a rock. Open a command Windows (cmd.exe) and type : 

	luarocks install --from=http://ipese.github.io/osmose-install osmose


### Luarocks

Osmose can also be installed as a luarock (OSX and Linux):

	luarocks install --server=http://ipese.github.io/osmose-install osmose

or on Windows :

	luarocks install --from=http://ipese.github.io/osmose-install osmose

### Gnuplot

Note that on a mac, you have to install [X11](http://xquartz.macosforge.org)  or  [Aquaterm] (http://aquaterm.sourceforge.net). It is recommended that you install first the terminal, since gnuplot will add it in the list of terminals. In this case, the default terminal will become aqua instead of X11. If you want to use another therminal, this can be defined in your .profile by adding the line export GNUTERM='X11'.

if you do not see the terminal aqua (by the command set terminal in gnuplot), then do the following :

	$ brew remove gnuplot
	$ brew install gnuplot --with-aquaterm --qt --pdf
	
if gnuplot is issuing the error : "dyld: Library not loaded: /usr/local/lib/libfreetype.6.dylib" then do the following

	$ brew link --overwrite freetype

## IDE/Text editor

You can use your text editor of your choice. All of them have text highlight for lua. You may need to specify the path to the lua executable.

In [ZeroBrane Studio](http://studio.zerobrane.com/) you can specify the lua path in the menu Edit > Preferences > Settings:System :
	
	-- Windows
	path.lua = "C:\Program Files (x86)\Osmose\Lua\5.1\lua.exe"

	-- OSX
	path.lua = "/usr/local/bin/lua"

## Dakota

Install the version 6.0 of [Dakota](http://dakota.sandia.gov/distributions/dakota/6.0/download.html) following the [installation instructions](http://dakota.sandia.gov/distributions/dakota/6.0/install.html)


## After installation

Once Osmose is installed, you need to create a repository to manage osmose project and ET. A typical working repository should the following folders and file :

	config.lua 		_the osmose config file_
	/ET 					_folder to store ET models_
	/projects      _folder to store frontends_
	/results      _folder where osmose results will be generated_

### config.lua

You must create a config.lua file to store the executables, like this :

	OSMOSE_ENV["GLPSOL_EXE"] 	= '/usr/local/bin/glpsol'
	OSMOSE_ENV["GNUPLOT_EXE"] = '/usr/local/bin/gnuplot'
	OSMOSE_ENV["DAKOTA_EXE"] = '/usr/local/dakota/bin/dakota'
	OSMOSE_ENV["LUA_EXE"] = '/usr/local/Cellar/lua/5.1.5/bin/lua'

or on Windows :

	OSMOSE_ENV["GLPSOL_EXE"] = '"C:\\Program Files (x86)\\Osmose\\GnuWin32\\bin\\glpsol.exe"'
	OSMOSE_ENV["GNUPLOT_EXE"]= '"C:\\Program Files (x86)\\Osmose\\gnuplot\\bin\\wgnuplot.exe"'

### execute

To run a project, you simply run the following in a terminal window :

	lua project/my_project.lua

Results will be stored in results folder.


## How to install Edge version (latest version on Github)

* Download the latest version in github : https://github.com/ipese/osmose/archive/master.zip

* Unzip the folder 

* Copy the _lib_ folder in your working directory

* Your working directory will be like this :

/ET
/lib
/projects
/results

* From now require osmose with "lib.osmose" in your frontend :


```	
local osmose = require 'lib.osmose'
```

## How to develop on Github

* Get a version of git source control management : http://git-scm.com/

* Clone osmose on your computer

```
git clone https://github.com/ipese/osmose.git
``

* Develop in _lib_ folder and create test in _test_ folder

* You can create frontends in _projects_ folder and models in _ET_ folder to test your development. All files in these folders will be ignored by git.

* Run test suite with the  command 

```
lua test/all.lua
```

* Commit and push to Github


## License

The Osmose code is proprietary of [IPESE, EPFL, Lausanne](http://ipese.epfl.ch/)
