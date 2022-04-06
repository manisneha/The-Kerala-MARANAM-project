***Estimate life table using census 2016 population projections - follows the same methods
*as 6.0.lifetable_2016censusproj



*bring in nmx_census estimates 

	use "$inter\nmx2016_census_vs_dhs_population.dta", clear

	
*keep necessary variables 

	keep year age_group female nmx_census 
	
	sort year female age_group
	
	drop if year < 2006
	
	drop if year > 2017

*merge nax values 

	merge 1:1 year age_group female using "$inter\nax_srs.dta"
	*years for which nax not yet available not matched
	*drop _merge 
	tab _merge year
	cap drop period 
	
   foreach var in nax  nmx_census  {
	
	format `var' %9.4f
	}	

	tempfile data
	save `data'
	
	
	

	
	
	forval x=2016/2016 {
	
	forval y=0/1 {
	
	use "`data'", clear
	
		gen f=""

	keep if year == `x'
	keep if female == `y'
	
	replace f="female" if female==1
	replace f="male" if female==0	
	local fem=f

*make life tables
	
	*nqx
	cap drop nqx
	gen nqx = (n*nmx_census) / (1 + (n-nax)*nmx_census)
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
	by female: replace nLx = lx/nmx_census if _n==19
	
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
	keep year age_group female nax nLx lx nmx_census nqx ex npx Tx 
	
	
	
	label var age_group "Age x"
	label var  female "1=Female, 0=Male"
	label var  nLx "\(_nL_x\)"
	label var lx "\(l_x\)"
	label var nmx_census "\(_nm_x\)"
	label var nqx "\(_nq_x\)"
	label var ex "\(e_x\)"
	label var nax "\(_na_x\)"
	label var npx "\(_np_x\)"
	
		
   foreach var in nax  nmx_census nqx npx lx nLx {
	
	format `var' %9.4f
	}	
	
	format ex %9.1f
		
	save "$results\paper1\lifetable\dataset\lifetablecensus_`x'_`fem'.dta",replace
	
	
     texsave age_group nmx_census nqx  lx nLx ex ///
	 using "${results}\paper1\lifetable\latex\lifetablecensus_`x'_`fem'.tex", ///
	 varlabels replace nofix
	 
	 outsheet age_group nmx_census nqx npx lx nLx ex using "${results}\paper1\lifetable\csv\lifetablecensus_`x'_`fem'.csv", comma replace
	 
	}
}




	use "$results\paper1\lifetable\dataset\lifetablecensus_2016_female",clear
	append using "$results\paper1\lifetable\dataset\lifetablecensus_2016_male"

	save "$results\paper1\lifetable\dataset\lifetablecensus_2016",replace
	
	
