Osmose
=========
Osmose is a new implementation of OSMOSE in Lua. Osmose is:

> OSMOSE is an acronym for 'OptimiSation Multi-Objectifs de Systèmes Énergétiques intégrés', Multi-Objective OptimiZation of integrated Energy Systems.

> OSMOSE is an optimization software. Its philosophy is based on the association of genetic algorithms and energy integration. This marriage allows the optimization of thermodynamic processes and a rational use of energy at the same time.

## Quick Overview
You may want to check the [wiki](https://github.com/ipese/LuaOsmose/wiki/_pages), the [doc](http://ipese.github.com/LuaOsmose/), our [Domain-specific Langage (DSL)](https://github.com/ipese/LuaOsmose/wiki/Domain-Specific-Language)) or the [Open Issuses](https://github.com/ipese/LuaOsmose/issues?state=open).

## Documentation
Please browse the project [generated doc](http://ipese.github.com/LuaOsmose/).

## Installation

### OSX and Linux

On Mac OSX and linux, the easiest way is to run these two commands :

	curl -s https://raw.github.com/ipese/osmose-install/master/install-dps | bash

	curl -s https://raw.github.com/ipese/osmose-install/master/install-osmose | bash

	
The first line will install brew (package management), glpk, gnuplot, lua and luarocks.

The secone line will install lua specific dependencies and osmose itself, which is a luarocks.

## License

The Osmose code is proprietary of [LENI, EPFL, Lausanne](http://leni.epfl.ch/)