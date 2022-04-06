/*This do-file is an extesion of the 2.0.dhs_exposure do-file. The 2.0 dhs_exposure do-file created population for all age 
groups except 0-1,1-4, 80-85 and 85+. This do-file estimates the population for the 0-1 age group.
*in the age groups 0-1, 1-4, and 0-5 for kerala 
*using a cubic interpolation 


**Either Sneha or Aashish made edits

*created aashish 15 aug 2020
*edited sneha 15 aug 2020
*edited sneha 19 oct 2020

*****/ 

**importing population estimates

use "$inter\dhs_exposures.dta", clear

**creating a dataset of the total population by year and sex

	keep if age_group_old=="totl"
	rename population tot_pop
	keep district tot_pop female year

tempfile totpop
save `totpop'


/*bring in estimates for population count and population proportion for age groups 0-1 and 1-5
 from Census 2001, Census 2011, and projected population estimates for 2016*/

	import excel ///
	"$raw\pop_0_1_mipolate.xlsx", ///
	sheet("estimates") firstrow case(lower) clear 
	
	
*run a cubic interplolation to calculate the proportions for 2005-2010,2012-2015. 
	
	cap drop prop_0_1_f_int
	mipolate prop_0_1_f year, spline gen(prop_0_1_int_f) e
	mipolate prop_0_1_m year, spline gen(prop_0_1_int_m) e
	mipolate prop_1_5_f year, spline gen(prop_1_5_int_f) e
	mipolate prop_1_5_m year, spline gen(prop_1_5_int_m) e

	keep year *_int*
	
	*Reshape the data to long format by sex
	
	reshape long prop_0_1_int_  prop_1_5_int_ , i(year) j(female) string
    replace female="1" if female=="f"
    replace female="0" if female=="m"
	rename   prop_1_5_int_  prop_1_5
	rename  prop_0_1_int_  prop_0_1
	destring ,replace
	
	save "$inter\interpolate_0_1_pop_proportion.dta", replace
	
	****Merging in total population data for age groups by sex. The tempfile was created in the beginning.
	
	merge 1:m year female using "`totpop'", keep(3) nogen
	
	****Keeping only the necessary variables in the dataset
	
	keep year district female tot_pop prop_*
	
	*calculating the population count for all years for age groups 0-1 and 1-5
	
	gen population_0=prop_0_1*tot_pop
	gen population_1=prop_1_5*tot_pop
	
	*reshaping the data into long format again

	reshape long population_ , i(year female prop* district) j(age_group) 
	
	*basic cleaning for better presentation of data.
	
	sort year age_group female	
	order year age_group female	
	rename population_ population	
	drop prop* tot_pop
	
	
	*merging the 0-1,1-5 population count data calculated in this do-file with the dhs_exposure data which 
	*contains the population counts for ages 5 to 80 in 5 year age intervals. 
	
	merge 1:1 year age_group female district using "$inter\dhs_exposures.dta",nogen
	
	
	*final cleaning of the data
    replace population=int(population)	
	sort year age_group female population
	drop if age_group==.

save "$inter\dhs_exposures_mod.dta",replace


/**checks - population pyramin check for one district in kerala. 

	keep if year==2007 & district=="kollam"
	replace population=-population if female==0
	twoway bar population age_group if female==0, horizontal xscale(r(-100000 0))|| bar  population age_group if female==1, horizontal xscale(r(0 100000))

