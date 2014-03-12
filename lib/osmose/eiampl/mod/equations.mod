# $Id: equations.mod 2116 2010-06-23 14:56:33Z bolliger $

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# General Equations Layer, to support EI.Equations and EI.EqTerms 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
###It is ok

# Sets
set Equations;
set EqTerms;

# Subsets
set EqTermsOfEquations{Equations} within EqTerms;


# Parameters
param Eqs_Sign{e in Equations} symbolic in {'<','=<','=','>=','>','!='};
param Eqs_Rht{e in Equations};

param EqTs_Coeff{t in EqTerms};
param EqTs_Var{t in EqTerms} symbolic;



# Constraints
subject to Eqs_solve_l{e in Equations}:
	sum {t in EqTermsOfEquations[e]} EqTs_Coeff[t]*EqTs_Var[t]  <= Eqs_Rht[e];
