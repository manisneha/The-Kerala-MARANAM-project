*This do file is to estimate the life table by year and sex (2006-2017)
*The deaths counts are from the kerala register data and the population counts are from the
*DHS++ population count dataset


*********************************************************************************

clear all
*creating an empty dataset

foreach var in age_group female nLx lx nmx nqx ex nax {
gen `var'=.
}
save "$results\paper1\lifetable\dataset\lifetable_2006to2017.dta", replace
	
*bring in nmx estimates created earlier using the DHS++ population counts as a denominator and the deaths
*counts from the kerala register data

	use "$inter\nmx_allyears.dta", clear
	
*keep necessary variables 

	keep year age_group female nmx 	
	sort year female age_group	
	drop if year < 2006	
	drop if year > 2017
	
*merge nax values calculated from the SRS data (The do-file 3.0 nax_srs has the details)

	merge 1:1 year age_group female using "$inter\nax_srs.dta"
	tab _merge year
	cap drop period 
	
   foreach var in nax  nmx  {	
	format `var' %9.4f
	}	

	tempfile data
	save `data'
	
**Creating life table variables using the nmx calculated using the kerala register data and the 
**DHS++ population counts.
**The calculation for the life table variables can be found in any standard demography textbook

**The data outsheets as latex tables 	
	
	
	forval x=2006/2017 {
	
	forval y=0/1 {
	
	use "`data'", clear
	
	gen f=""

	*create life tables by year and sex
	keep if year == `x'
	keep if female == `y'
	
	*this chunk of code is only to enable easier labeling of final dataset
	replace f="female" if female==1
	replace f="male" if female==0	
	local fem=f

*make life tables
	
	*nqx
	cap drop nqx
	gen nqx = (n*nmx) / (1 + (n-nax)*nmx)
	replace nqx = 1 if nqx==.
	
	gen npx=1-nqx
		
	*radix
	cap drop lx
	sort female age_group
	by female: gen lx = 1 if _n==1
		
	*lx
	forval i=2(1)19 {
		by female: replace lx = (lx[_n-1]*(1-nqx[_n-1])) if _n==`i'
	}
	
	*nLx
	cap drop nLx
	gen nLx=.
	forval i=1(1)18 {
		by female: replace nLx = (lx[_n+1]*n) + (lx*nqx*nax) if _n==`i'
	}
	by female: replace nLx = lx/nmx if _n==19 /*open interval*/
	
	*total PY (for Tx)
	cap drop total_py
	bysort female: egen total_py = total(nLx) 

	*Tx
	cap drop Tx
	gen Tx = .
	by female: replace Tx = total_py - sum(nLx) + nLx

	*ex
	cap drop ex
	gen ex = Tx / lx
	replace ex = round(ex, .1)
	
	*keep only life table things that we will put in tables 
	keep year age_group female nax nLx lx nmx nqx ex npx Tx 
	
	
	
	label var age_group "Age x"
	label var  female "1=Female, 0=Male"
	label var  nLx "\(_nL_x\)"
	label var lx "\(l_x\)"
	label var nmx "\(_nm_x\)"
	label var nqx "\(_nq_x\)"
	label var ex "\(e_x\)"
	label var nax "\(_na_x\)"
	label var npx "\(_np_x\)"
	
		
   foreach var in nax  nmx nqx npx lx nLx {
	
	format `var' %9.4f
	}	
	
	format ex %9.1f
		
	save "$results\paper1\lifetable\dataset\lifetable_`x'_`fem'.dta",replace
	
	
     texsave age_group nmx nqx  lx nLx ex ///
	 using "${results}\paper1\lifetable\latex\lifetable_`x'_`fem'.tex", ///
	 varlabels replace nofix
	 
	 outsheet age_group nmx nqx npx lx nLx Tx ex using "${results}\paper1\lifetable\csv\lifetable_`x'_`fem'.csv", comma replace
	 
	}
	
	
}



	



use "$results\paper1\lifetable\dataset\lifetable_2006to2017.dta", clear
forval x=2006/2017 {	
	foreach var in female male {
append using "$results\paper1\lifetable\dataset\lifetable_`x'_`var'.dta"
	save "$results\paper1\lifetable\dataset\lifetable_2006to2017.dta",replace
	
	}
	}

	


*combine male female life tables - this is useful for presentations. 

	forval x=2006/2017 {
	
	
	*combine male female files
	use "$results\paper1\lifetable\dataset\lifetable_`x'_female.dta", clear
	
	append using "$results\paper1\lifetable\dataset\lifetable_`x'_male.dta"
	
	keep year age_group female nmx nqx lx nLx ex
	
	foreach var in nmx nqx lx nLx ex {
	
	rename `var' `var'_
	
	}
	
	replace lx = lx*1000
	replace nLx = nLx*1000
	
	format lx %9.0fc
	format nLx %9.1fc
	
	gen male = female == 0
	drop female 
	
	reshape wide nmx nqx lx nLx ex, i(year age_group) j(male)
	
	*0 IS FEMALE HERE
	
	label var age_group "Age x"
	label var  nLx_0 "\(_nL_x\)"
	label var  nLx_1 "\(_nL_x\)"
	label var lx_0 "\(l_x\)"
	label var lx_1 "\(l_x\)"
	label var nmx_1 "\(_nm_x\)"
	label var nmx_0 "\(_nm_x\)"
	label var nqx_1 "\(_nq_x\)"
	label var nqx_0 "\(_nq_x\)"
	label var ex_1 "\(e_x\)"
	label var ex_0 "\(e_x\)"

	 texsave age_group nmx_0 nqx_0 lx_0 nLx_0 ex_0 nmx_1 nqx_1 lx_1 nLx_1 ex_1  ///
	 using "${results}\paper1\lifetable\latex\lifetable_`x'_combined.tex", ///
	 varlabels replace nofix

	
	
	
	}


