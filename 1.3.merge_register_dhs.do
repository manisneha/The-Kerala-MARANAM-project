**************************************************************************************
/*Purpose: Merging the register data with the population data estimated using DHS exposire data for ages 5-80,
* interpolation from the census for 0-1,1-4 age groups, and the SRS data for 80-85 and 85+. The population 
*dataset will be refered to as the DHS++ population data

*/
*************************************************************************************************************************************************


***********************************************************************************************8

*the base dataset is the kerala register data to create a state level dataset of the death counts by year, 
*sex and age_group. The dataset us called stateagg_agesex.dta

use "$inter\death_by_data.dta",clear /*dataset not available for public use*/
	
	gen counter=1
	collapse (sum) counter, by(reg_year age_group female)	
	rename counter deaths
	rename reg_year year
    destring age_group,replace
	
	
save "$inter\stateagg_agesex.dta",replace

***Merging the death count data with dhs++ population dataset and creating the state level dataset 
*containing death counts and population counts.

use "$inter\dhs_exposures_mod.dta" , clear

	keep if district=="all districts" /*estimating it at the state level*/
	drop if age_group_old=="totl" /*we only need counts by age age_group*/
	keep if year>2005 & year<2018 /*restricting it to the years for which we have the register data*/
	destring year female, replace
	merge 1:1 year age_group female using "$inter\stateagg_agesex.dta", nogen


	order year age_group female population deaths place
	drop adm*

save "$inter\stateagg_agesexpop.dta", replace

*************************************************************************************************************************************************
*******************************************************DISTRICT LEVEL DATA***********************************************************************

**the similar process is repeacted but for the district level data. 

*creating district level death count data

use "$inter\death_by_data.dta",clear

    foreach var of varlist district_name {
	gen Z=lower(`var')
	drop `var'
	rename Z `var'
	}


	
	gen counter=1
	collapse (sum) counter, by(reg_year age_group female district_name )
	
	rename counter deaths
	rename reg_year year
    destring age_group,replace
	
	
save "$inter\districtagg_agesex.dta",replace 

***Merging with dhs exposures data to create district level data of population and death counts. 

use "$inter\dhs_exposures_mod.dta" , clear

	keep if district!="all districts"
	drop if age_group_old=="totl"
	keep if year>2005 & year<2018
	rename district district_name
	destring year female, replace


merge 1:1 year age_group female district_name  using "$inter\districtagg_agesex.dta", nogen

	order year district_name age_group female population deaths  place
	drop adm*

save "$inter\districtagg_agesexpop.dta", replace

*************************************************************************************************************************************************
*************************************************************************************************************************************************


