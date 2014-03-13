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

### Luarocks

Osmose can alse be installed as a rock :

	luarocks install --only-server=http://ipese.github.io/osmose-install osmose

### Gnuplot

Note that on a mac, you have to install [X11](http://xquartz.macosforge.org)  or  [Aquaterm] (http://http://aquaterm.sourceforge.net). It is recommended that you install first the terminal, since gnuplot will add it in the list of terminals. In this case, the default terminal will become aqua instead of X11. If you want to use another therminal, this can be defined in your .profile by adding the line export GNUTERM='X11'

## After installation

Once Osmose is installed, you need to create a repository to manage osmose project and ET. A typical working repository should the following folders and file :

config.lua 		_the osmose config file_
/ET 					_folder to store ET models_
/project      _folder to store frontends_
/results      _folder where osmose results will be generated_

### config.lua

You must create a config.lua file to store the executables, like this :

OSMOSE_ENV["GLPSOL_EXE"] 	= '/usr/local/bin/glpsol'
OSMOSE_ENV["GNUPLOT_EXE"] = '/usr/local/bin/gnuplot'

### execute

To run a project, you simply run the following in a terminal window :

	lua project/my_project.lua

Results will be stored in results folder.


## License

The Osmose code is proprietary of [LENI, EPFL, Lausanne](http://leni.epfl.ch/)