/*Purpose : This do file is to estimate the proportion of 80-85 and 85+ in the population for 2005-2017 
and calculate the population counts for 80-85 and 85+ age groups. 
Currently, the open interval starts at 80. It is a followup  to the do-files 2.0. and 2.1. 
This do-file creates the population dataset with popultion 
counts for the age-groups present in the standard life table notation. 

*****/


**importing population estimates to create a dataset with the total population in each year using the dhs 
*exposure dataset

use "$inter\dhs_exposures.dta", clear

	keep if age_group_old=="totl" 
	rename population tot_pop
	keep district tot_pop female year
	tempfile totpop
	save `totpop'

*bring in srs estimates. The SRS estimates provides the proportion of the population belonging to different
*age groups and provides the share of the population in the 80-84 and 85+ age group for 2004 to 2018. 

	import excel "$dir\exposures\age_births_srs.xlsx", ///
	sheet("age") firstrow case(lower) clear
	replace age_group="80" if age_group=="80-84"
 	replace age_group="85" if age_group=="85+"
	destring, replace
	
	tempfile base
	save `base'


*tabulating the population counts for the two age groups 

	foreach var in 80 85 {
	
	use `base',clear
	
	keep if age_group=="`var'" 
	gen prop_f=total_female/100
	gen prop_m=total_male/100

	keep year age_group prop_f prop_m
	
	reshape long prop_ , i(year age_group) j(female) string
    replace female="1" if female=="f"
    replace female="0" if female=="m"
	rename  prop_ proportion	
	destring ,replace

	merge 1:m year female using "`totpop'", keep(3)
	
	tempfile data`var'
	save `data`var''
	
	}
	
	
	*Merging in the data for the two age groups with the dhs_exposure dataset and created the final dhs_exposures
	*dataset which is called dhs_exposires_mod.dta
	
	use "`data80'", clear
	append using "`data85'"	
	
	keep year district female prop tot_pop age_group	
	gen population=int(proportion*tot_pop)	
	
	merge 1:1 year age_group female district using "$inter\dhs_exposures_mod.dta",nogen
	
    replace population=int(population)	
	drop prop tot_pop 	
	drop if age_group==.	
	sort year age_group female population

save "$inter\dhs_exposures_mod.dta",replace

/*checks by creating population pyramids for a visual check

keep if year==2007 & district=="kollam"

replace population=-population if female==0

twoway bar population age_group if female==0, horizontal || bar  population age_group if female==1, horizontal 


