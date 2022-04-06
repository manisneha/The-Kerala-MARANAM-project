/***Descriptives/ Looking at cdr and missing information on age and sex


*****/



********************************************************************************************************************


*Starting the cleaning work



*Creating a tempfile of the number of deaths by year and sex.
use "$inter\death_by_data.dta",clear
	rename death_year year
	bysort year female : gen deaths=_N
	bysort year female  : gen n=_n
	keep if n==1
	keep year female deaths
tempfile deaths
save `deaths'


*Calculating the CDR for the total population, females, and males by merging the deaths counts and population counts 

use "$inter\dhs_exposures.dta", replace

	keep if district=="all districts"
	keep if age_group_old=="totl"
	keep year female population
	merge 1:1 year female using "`deaths'", keep(3) nogen
	gen cdr=deaths/population

	reshape wide population deaths cdr, i(year) j(female)
	egen populationtot=rowtotal (population0 population1)
	egen deathstot=rowtotal (deaths0 deaths1)
	gen cdr=deathstot/populationtot

tempfile cdr
save `cdr'


*Checking the number of observations that were dropped from the original raw data of the register data
*And calculate the share of the missings of the original data

use "$raw\death_by_data_raw.dta",clear /*this dataset is not available for public access*/

	gen death_year = year(death_date)
	drop if death_year == . // 4 dropped
	drop if death_year < 2006 // 55593 dropped 
	drop if death_year > 2017 // 11 dropped - probably 2013, but dont care 

	
	rename death_year year
	tempfile dt
	save `dt'
	bysort year  : gen deathsfull=_N
	bysort year : gen n=_n
	keep if n==1
	keep year deathsfull

	merge 1:1 year using "`cdr'", keep(3) nogen
	gen missingn=deathsfull-deathstot
	gen missingperc=(missingn/deathsfull)*100
	tempfile dtmiss
	save `dtmiss'
	
		
**Cleaning, organizing, formatting the variables present in the final table

	replace cdr0 = cdr0 * 1000
	replace cdr1 = cdr1 * 1000
	replace cdr = cdr * 1000

	keep year deaths1 cdr1 deaths0 cdr0 deathstot cdr missingn missingperc*
	order year deaths1 cdr1 deaths0 cdr0 deathstot cdr missingn missingperc 
	label var year "Year"
	label var cdr1 "Female CDR"
	label var cdr0 "Male CDR"
	label var cdr "CDR"
	label var deaths1 "Female deaths"
	label var deaths0 "Male deaths"
	label var deathstot "Deaths"
	label var missingn "Missing information"
	label var missingperc "\%"


    format  cd* %9.1f
    format missingperc*  %9.2f



*Saving the table as a latex table - 
     texsave year deaths1 cdr1 deaths0 cdr0 deathstot cdr missingn missingperc ///
	 using "${results}\paper1\lifetable\latex\descriptives.tex", ///
	 varlabels replace nofix
	 
	 
	 
*Missing patterns of age by sex
	use `dt', clear
	gen female=1 if sex==2
	replace female=0 if sex==1 
	drop if sex==9
	bysort year female  : gen deathsfull=_N
	bysort year female : gen n=_n
	keep if n==1
	keep year female deathsfull*
	reshape wide deathsfull , i(year) j(female)
	merge 1:1 year using "`cdr'", keep(3) nogen
	gen missing_age1=deathsfull1-deaths1
	gen missing_age0=deathsfull0-deaths0
	keep year missing_age0 missing_age1 deathsfull1 deathsfull0 deaths1

	gen missingperc_agef=missing_age1/(deathsfull1)*100 /*Female missing age/Female deaths*/
	gen missingperc_agem=missing_age0/(deathsfull0)*100 /*Male missing age/male deaths*/
	merge 1:1 year using "`dtmiss'", keep(3) nogen

	gen missingperc_agetot=(missing_age0+missing_age1)/(deathsfull)*100 
	keep year missingperc* deathsfull  
	tempfile dtmiss
	save `dtmiss', replace
	
	*Missing patterns of sex
	use `dt', clear
	bysort year sex : gen count=_N
	bysort year  : gen total=_N
	keep if sex==9
	bysort year  : gen n=_n
	keep if n==1
	gen missingperc_sex=(count/total)*100 /*missing sex*/
	merge 1:1 year using "`dtmiss'", keep(3) nogen
	keep year missingperc* deathsfull  
	tempfile dtmiss
	save `dtmiss', replace

	*Missing patterns of sex and age 

	use `dt', clear
	gen age_death = age_year if age_year!=999
	replace age_death = 0 if age_month< 12 & age_year == 999
	replace age_death = 0 if age_days < 32 & age_month == 999 & age_year == 999
	egen age_group = cut(age_death), at(0, 1, 5(5)85)
	replace age_group = 85 if age_death > 84 & age_death!=.
	tempfile dt1
	save `dt1'
	

	use `dt1', clear
	gen miss=1 if age_death==. & sex==9
	replace miss=0 if miss!=1
	bysort year miss: gen deaths=_N
	bysort year miss: gen n=_n
	keep if n==1
	keep year deaths miss
	reshape wide deaths, i(year) j(miss)
	merge 1:1 year using "`dtmiss'", keep(3) nogen
	gen missingperc_sexandage=deaths1/(deathsfull)*100
	replace missingperc_sexandage=0 if missingperc_sexandage==.
	merge 1:1 year using "`dtmiss'", keep(3) nogen
	keep year missingperc* deathsfull  
	tempfile dtmiss
	save `dtmiss', replace
	
		*Missing patterns of sex or age 

	use `dt1', clear
	gen miss=1 if age_death==. | sex==9
	replace miss=0 if miss!=1
	bysort year miss: gen deaths=_N
	bysort year miss: gen n=_n
	keep if n==1
	keep year deaths miss
	reshape wide deaths, i(year) j(miss)
	merge 1:1 year using "`dtmiss'", keep(3) nogen
	gen missingperc_sexorage=deaths1/(deathsfull)*100
	merge 1:1 year using "`dtmiss'", keep(3) nogen
	keep year missingperc* deathsfull  
	tempfile dtmiss
	save `dtmiss', replace

 
	 keep year missingperc*
	order year missingperc_agef missingperc_agem missingperc_agetot missingperc_sex missingperc_sexandage missingperc_sexorage
	label var year "Year"
	label var missingperc_agef "Among females"
	label var missingperc_agem "Among males"
	label var missingperc_agetot "Total"
	label var missingperc_sex "Only sex missing"
	label var missingperc_sexandage "Sex and age missing"
	label var missingperc_sexorage "Sex or age missing"
    format missingperc*  %9.2f



*Saving the table as a latex table - 
     texsave year  missingperc_agef missingperc_agem missingperc_agetot missingperc_sex missingperc_sexandage missingperc_sexorag ///
	 using "${results}\paper1\lifetable\latex\descriptives_missing.tex", ///
	 varlabels replace nofix
