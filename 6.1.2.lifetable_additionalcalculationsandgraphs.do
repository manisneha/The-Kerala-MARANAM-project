*Purpose : this do file calculates e1560 e015 e6085 using values that were ///
*calculated in the previous do-file

*This is part of the descriptive table in the paper



***********************************************nqx

use "$results\paper1\lifetable\dataset\lifetable_2006to2017.dta", clear

*keep necessary variables and ages
keep age_group lx female year nqx

keep if inlist(age_group,0,15,60,85)

*reshape by age group
reshape wide  lx nqx, i(year female) j(age_group)

*generate temp life expectancies
gen nqx1560=(lx15-lx60)/(lx15)
gen nqx015=(lx0-lx15)/(lx0)
gen nqx6085=(lx60-lx85)/(lx60)

keep female year nqx015 nqx1560 nqx6085
order year female nqx015 nqx1560 nqx6085

*rename before reshape
foreach var in nqx015 nqx1560 nqx6085 {
rename `var' `var'_
}

*reshape
reshape wide nqx015 nqx1560 nqx6085, i(year) j(female)

*order
order year nqx015* nqx1560* nqx6085*

*format
format nq* %9.4f

 
	 
*export tex file
     texsave year nqx015_1 nqx015_0 nqx1560_1 nqx1560_0 nqx6085_1 nqx6085_0 ///
	 using "${results}\paper1\lifetable\latex\nqx_estimates_015_1560_6085.tex", ///
	 replace nofix 
