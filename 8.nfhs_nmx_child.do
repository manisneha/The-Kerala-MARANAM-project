**************************************************
*Project: age specific mortality in ages 0-1 and 1-4 for Kerala
*Purpose: Use birth history data to gen child mortality
*Last modified: 24 Aug 2020 by AG
**************************************************



**************************************************
*Prepare dataset
*************************************************

	*Load in data
	use "$datadir\IABR71DT\IABR71FL.DTA", clear
	
	*Keep only necessary variables
	keep v001 v002 v003 v005 v006 v007 v016 v024 v130 v131 v135 ///
	b1 b2 b3 b4 b5 b6 b7 b16
	
	*Drop non-residents
	drop if v135==2
	
	*keep only kerala 
	keep if v024 == 17 
	
	
**************************************************	
*Set up key dates
**************************************************

	*Date of birth
	cap drop birth_date 
	gen birth_date = ym(b2, b1)
	format birth_date %tm

	*Date of exit

		*Make an indicator for died
		cap drop died
		gen died = b5 == 0 
				
		*Date of death for those who died
		cap drop death_date
		gen death_date = birth_date + b7 + 1 if died==1
		format death_date %tm

		*Date of interview for those who survived	
		cap drop interview_date 
		gen interview_date = ym(v007, v006)
		format interview_date %tm 		

		*exit date 
		gen exit_date = . 
		replace exit_date = death_date if died == 1 
		replace exit_date = interview_date if died == 0 
		replace exit_date = exit_date + 0.1 if exit_date == birth_date

**************************************************
*Clean other important variables
*************************************************
				
				
	*Create female variable
	cap drop female
	gen female = (b4==2)
	
	*Create sample weight
	cap drop sample_weight
	gen sample_weight=v005/1000000

**************************************************
*Convert to person-month time
**************************************************

	*Gen an id
	gen id = _n
	
	*STset
	stset exit_date, failure(died) origin(birth_date) id(id)
	
	*STsplit
	stsplit split, every(1)
	
	*Running count of person-month obs
	bysort id: gen pm_obs = _n
		
	*Time varying date
	gen tv_date = birth_date + pm_obs - 1 
	format tv_date %tm 

	*Time varying age
	gen tv_age = (pm_obs - 1) / 12 
	
*Restrictions
	
	*No person-months above 5
	drop if tv_age >=5 
	
	*age groups of 0-1, 1-4
	egen age_group = cut(tv_age), at(0,1,5)
	drop if age_group == .

	
	*drop periods after 2015 december 
	drop if tv_date > tm(2015m12)
	
	*drop periods before 2005 january 
	drop if tv_date < tm(2004m1)
	
	*Restrict to five years prior to interview date
	*drop if tv_date < interview_date - 120
	
*generate year 
	
	cap drop tv_year 
	gen tv_year = yofd(dofm(tv_date))
	
	
	
**************************************************
*Collapse into death rates
**************************************************
	
	*deaths and person years by sample weights 
	cap drop deaths person_years
	g deaths = _d*sample_weight
	g person_years = sample_weight / 12
	replace person_years = sample_weight / 24 if _d == 1 & _t0 == 0	

	*collapse
	collapse (sum) deaths person_years, by(tv_year age_group female)
	gen nmx = deaths / person_years

	*Save
	save "$dir\data\stata\3.intermediate_data\nfhs_4_child_mortality_year_kerala.dta", replace 
	

