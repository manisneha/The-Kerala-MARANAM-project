/****Do-file related to checks for migration data - All checks for 2011
**The do-file does the following

a.	INTERNAL: Remove migrants from census 

*We do not calculate any age specific death rates here. 
*We calculate mainly cdr with different nominators
*We only use Census 2011 population counts
*Dearhs counts are for Sep 1 2010 to Aug 31 2011





***********************************************************************************************

*Checking the death count data for out of state cases


***Removing migrant cases from the numerator

*taking the death data, keeping only the relevant time reference, creating a datasets of deaths  of
*migrants and non-migrants*/

use "$inter\death_by_data.dta", clear

	gen migrant=0 if own_state_!=""
	replace migrant=1 if own_state_!="Kerala"
	rename death_year year
	tab year migrant

	*restrict to census period 

	keep if death_date >= td(01sep2010)
	keep if death_date <= td(31aug2011)
	
	tempfile m
	save `m'
	
*collapse into death counts by age group and sex 

	gen counter = 1	
	collapse (sum) counter, by(female migrant)	
	rename counter deaths 
	
	destring, replace
	
	save "$inter/migrantdeaths_2011.dta",replace
	
	collapse (sum) deaths, by(migrant)	
	append using "$inter/migrantdeaths_2011.dta"	
	gen year=2011
	
	gen cat="Female" if female==1
	replace cat="Male" if female==0
	replace cat="Total" if female==.
	save "$inter/migrantdeaths_2011.dta",replace
	
		
*creating a dataset of the population in 2011 from census 2011 numbers


use "$inter\c2011_age_count_total.dta", clear
	rename pop population_census
	gen year=2011
	
	collapse (sum) population, by(year female)
	
	tempfile pop_2011
	save `pop_2011'
	
	collapse (sum) population, by(year)
	append using "`pop_2011'"
	
	gen cat="Female" if female==1
	replace cat="Male" if female==0
	replace cat="Total" if female==.
	
	save "$inter/pop_2011.dta",replace

	
	merge 1:m year cat using "$inter/migrantdeaths_2011.dta", nogen keep(3)	
	keep if migrant==0 /*we only want to calculate the cdr for residents*/
	gen cdr_res=deaths/population if migrant==0
	
		
	keep year cat female cdr**
	label var cdr_res "Dem: Total population,Num: Only residents"
	replace cdr_res=cdr_res*1000
	save "$inter/cdr_keralaresidents.dta",replace
	
	
	
*****************Removing migrant cases from the denominator**********************************************8
   
**This can be done only for 2011
**Need to bring in the number of migrants in Kerala from the Census 2011 files

*Importing and cleaning the excel files
import excel ///
	"$raw\DS-3200-D02-MDDS.xlsx", ///
	sheet("Sheet1") firstrow clear
	
	rename Totalmigrants mig_tot
	rename I mig_male
	rename J mig_female
	rename less1year mig1yr_tot
	rename L mig1yr_male
	rename M mig1yr_female

*We are interested in migrants from other states/internal migrants
	keep if inlist(Lastresidence,"States in India beyond the state of enumeration")
	keep if inlist(AreaName,"State - KERALA")
	keep if Placeofenumeration=="Total"
	keep if F=="Total"
	rename Lastresidence migrant_resloc
	keep  mig*
	
	reshape long mig_ mig1yr_, i(migrant_resloc) string
	rename mig_ mig_total
	rename mig1yr mig_lessthan1yr
	gen female=1 if _j=="female"
	replace female=0 if _j=="male"
	
	destring mig_total mig_lessthan1yr female,replace
	
	gen mig_morethan1yr=mig_total-mig_lessthan1yr
	rename _j category
	
	label var migrant_resloc "the residence location of the migrants living in Kerala"
	label var category "female/male/tot"
	label var mig_total "total number of other state migrants in Kerala (2011)"
	label var mig_lessthan1yr "tot no. of other state migrants in Kerala for less than 1 year (2011)"
	label var mig_morethan1yr "tot no. of other state migrants in Kerala for more than 1 year (2011)"
    label var female "female=1, male=0"
	order migrant_*  female mig* 
	
	gen year=2011
	
	save "$inter/otherstatemigrants_kerala.dta", replace
	
**Merging this with population dataset so that the required denominators can be calculated

	use "$inter/pop_2011.dta",clear	
	merge 1:1 year female using "$inter/otherstatemigrants_kerala.dta",nogen
	
	drop category
	
	gen pop_exallmig=population - mig_total
	gen pop_exless1yrmig=population - mig_lessthan1yr
	gen pop_exmore1yrmig=population - mig_morethan1yr
	
	label var female "female=1, male=0, total=."	
	label var population "total population"	
	label var pop_exallmig "pop excluding all other state migrants"
	label var pop_exless1yrmig "pop excluding other state migrants living in kerala for less than 1 year"
	label var pop_exmore1yrmig "pop excluding other state migrants living in kerala for more than 1 year"
	
	save "$inter/2011population_excludingmigrants.dta", replace
	
	merge 1:m cat year using "$inter/migrantdeaths_2011.dta",nogen
	
	keep if migrant==0 /*we only want to caculate the CDR for residents/non-migrants*/
	
	gen cdr_res_exallmig=(deaths/pop_exallmig)*1000
	gen cdr_res_exless1yrmig=(deaths/pop_exless1yrmig )*1000
	gen cdr_res_exmore1yrmig=(deaths/pop_exmore1yrmig)*1000
	
	label var cdr_res_exallmig "Dem: Ex all migrants from other states,Num: Only residents, "
	label var cdr_res_exless1yrmig "Dem: Ex migrants living <1 year from other states,Num: Only residents"
	label var cdr_res_exmore1yrmig "Dem: Ex migrants living >1 year from other states,Num: Only residents"
	
	keep year cat female cdr* 	
	merge 1:1 year cat using "$inter/cdr_keralaresidents.dta",nogen
	
	save "$inter/cdr_keralaresidents.dta",replace 
*******************************************************

**Calculating the general CDR (NO MODIFICATIONS to the numerator and denominator
use "$inter\death_by_data.dta", clear

	gen migrant=0 if own_state_!=""
	replace migrant=1 if own_state_!="Kerala"
	rename death_year year
	tab year migrant

	*restrict to census period 

	keep if death_date >= td(01sep2010)
	keep if death_date <= td(31aug2011)
	
*collapse into death counts by age group and sex 

	gen counter = 1	
	collapse (sum) counter, by(female)
	
	tempfile all
	save `all'
	
	collapse (sum) counter	
	append using "`all'"
	rename counter deaths	
	merge 1:m female using  "$inter/pop_2011.dta",nogen
	
	gen cdr=(deaths/population)*1000
	
	keep year cat cdr	
	merge 1:1 year cat using "$inter/cdr_keralaresidents.dta",nogen	
		foreach var of varlist cdr* {
		format %9.3g `var'
	}
	order cat cdr cdr_res cdr_res_exallmig cdr_res_exless1yrmig 
	label var cat "Female/Male/Tot"
	label var cdr "NO modifications"
	label var year "2011"
	
	
save "$inter/cdr_keralaresidents.dta",replace 


	 texsave cat cdr cdr_res_exallmig cdr_res_exless1yrmig cdr_res_exmore1yrmig  ///
	 using "${results}\paper1\robustness\migration.tex", ///
	 varlabels replace nofix

	
	

 