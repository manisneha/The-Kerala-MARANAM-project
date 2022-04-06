*Purpose: this do file estimates nax values 
*Includes interpolation for the years we do  mot have nax estimates from other sources
*All the calculation carried out in the do-files follows standard life table estimations. 


**********************************************************************************
clear all

*set directory 

	
*bring in  data from srs
*This dataset provides life table values in 4 year intervals. For example, 2005-2009,
*2004-2008, etc. We use this data to estimate the nax values. These nax values are required to estimate 
*life tables for the Kerala register data. 

	import excel ///
	"$dir\2.raw_data\alt.xlsx", ///
	sheet("Sheet1") firstrow case(lower) clear
	
	*generate age groups following standard life table age cut-offs
	gen age_group = . 
	replace age_group = 0 if age == "0-1"
	replace age_group = 1 if age == "1-5" 
	
	forval age_int = 5(5)80 {	
	local age_int2 = `age_int' + 5	
	replace age_group = `age_int' if age == "`age_int'-`age_int2'"
	}
	
	replace age_group = 80 if age == "80+85"
	replace age_group = 85 if age == "85+"
	
	*dropping unnecessary variables 
	drop residence total* age place
	
	*gen n (lenght of the age interval)
	gen n = . 
	sort period age_group
	forval i = 1(1)18 {
	bysort period: replace n = age_group[_n+1] - age_group[_n] if _n == `i'
	}
	
	*gen life table deaths, ndx and age-specific mortality rates 
	foreach sex in male female {
	gen `sex'_ndx = . 
	sort period age_group
	forval i = 1(1)18 {
	bysort period: replace `sex'_ndx = `sex'_lx[_n] - `sex'_lx[_n+1] if _n == `i' 
	replace `sex'_ndx = `sex'_lx if age_group == 85	
	}
	
	*nmx 
	cap drop `sex'_nmx
	gen `sex'_nmx = `sex'_ndx / `sex'_nlx	
	}
	
	*gen nax values 
	*From life table calculations, we know that nLx = n*l(x+n) + nax*ndx 
	*so nax = (nLx - n*l(x+n)) / ndx 
	
	foreach sex in male female {
	
	gen `sex'_nax = . 
	
	sort period age_group 
	forval i = 1(1)18 {
	by period: replace `sex'_nax = (`sex'_nlx - (n*`sex'_lx[_n+1])) / `sex'_ndx if _n == `i' 
		
	}
	
	replace `sex'_nax = `sex'_ex if age_group == 85 
	}
	
	*generate average year for which period the data corresponds to 
	
	gen year = . 
	replace year = 2006 if period == "2004-2008"
	replace year = 2007 if period == "2005-2009"
	replace year = 2008 if period == "2006-2010"
	replace year = 2009 if period == "2007-2011"
	replace year = 2010 if period == "2008-2012"
	replace year = 2011 if period == "2009-2013"
	replace year = 2012 if period == "2010-2014"
	replace year = 2013 if period == "2011-2015"
	replace year = 2014 if period == "2012-2016"
	replace year = 2015 if period == "2013-2017"

		
	*keep just the nax values  
	drop male_nqx male_lx male_nlx male_ex female_nqx female_lx female_nlx female_ex male_ndx male_nmx female_ndx female_nmx 
	
		
	*rename before reshape 
	rename male_nax nax_0
	rename female_nax nax_1 
	
	*reshape 
	reshape long nax_, i(period age_group n year) j(female)
	
	*rename again 
	rename nax_ nax 
	
	*reorder sort etc 
	sort period female age_group 
	
	order year period female age_group n nax
	
	*reshape in order to interpolate 
	drop period n 
	
	*reshape wide by sex 
	reshape wide nax, i(year age_group) j(female)
	rename nax* nax_*
	
	*reshape wide by age_group 
	reshape wide nax_0 nax_1, i(year) j(age_group)
	rename nax_0* nax_0_*
	rename nax_1* nax_1_*
	
	*add two rows 
	set obs `=_N+1'
	replace year = 2016 if year == . 
	
	set obs `=_N+1'
	replace year = 2017 if year == . 
	
	*interpolate to 2017
	foreach female in 0 1 {
	foreach age in 0 1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 {
	mipolate nax_`female'_`age' year, spline e gen(int_nax_`female'_`age')
	}
	}

	*drop nax values and make them true nax values 
	drop nax*
	rename int_n* n*
	
	*reshape long by age_group 
	reshape long nax_1_ nax_0_, i(year) j(age_group)
	
	*reshape long by female 
	rename nax_0_ nax_0
	rename nax_1_ nax_1
	
	reshape long nax_, i(year age_group) j(female)
	rename nax_ nax
	
	*gen n (lenght of the age interval)
	gen n = . 
	sort year female age_group
	forval i = 1(1)18 {
	bysort year female: replace n = age_group[_n+1] - age_group[_n] if _n == `i'
	}
	
	*saveold 
	saveold "$dir\3.intermediate_data\nax_srs.dta", replace
	
	
	
