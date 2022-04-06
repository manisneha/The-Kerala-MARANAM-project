**Estimate life table using census 2011 population and mid year deaths
*the deaths counts refer to 1sep2010 to 31aug2011



	*import
	
	import excel ///
	"$raw\census_2011_single_age_sex_residence.xls", ///
	sheet("overall") firstrow clear
	
	keep age male_total female_total
	rename male_total male 
	rename female_total female 
	
	drop if age == . 

*create life table age categories 
	
	cap drop age_group 
	egen age_group = cut(age), at(0,1,5(5)85)
	replace age_group = 85 if age> 84 
	
*reshape 

	rename male pop0
	rename female pop1 
	
	reshape long pop, i(age age_group) j(female)
	
	collapse (sum) pop, by(female age_group)
	
*save 

	save "$inter\c2011_age_count_total.dta", replace 
	
	
	
*notes
*so the census estimates pop on march 1, 2011
*see http://censusindia.gov.in/2011census/PCA/PCA_Highlights/pca_highlights_file/India/4Executive_Summary.pdf
*so what if we restrict the data to 6 months before, and 6 months after this date
*so we are restrincting it to deaths from 1sep2010 to 31aug2011

*bring and merge death data 

	use "$inter\death_by_data.dta", clear
	
*restrict to census period 

	keep if death_date >= td(01sep2010)
	keep if death_date <= td(31aug2011)
	
*collapse into death counts by age group and sex 

	gen counter = 1
	
	collapse (sum) counter, by(age_group female)
	
	rename counter deaths 

*merge pop data 

	merge 1:1 age_group female using "$inter\c2011_age_count_total.dta", nogen

*gen mortality rates 

	gen nmx = deaths / pop
	
	gen year=2011
	
	merge 1:1 year age_group female using "$dir\stata\3.intermediate_data\nax_srs.dta"

	tab _merge year
	cap drop period 
	
   foreach var in nax  nmx  {
	
	format `var' %9.4f
	}	


	tempfile data
	save `data'
	
	
	
	
	
	forval x=2011/2011 {
	
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
	by female: replace nLx = lx/nmx if _n==19
	
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
		
	save "$results\paper1\lifetable\dataset\lifetablecensus_`x'_`fem'.dta",replace
	
	
     texsave age_group nmx nqx  lx nLx ex ///
	 using "${results}\paper1\lifetable\latex\lifetablecensus_`x'_`fem'.tex", ///
	 varlabels replace nofix
	 
	 outsheet age_group nmx nqx npx lx nLx ex using "${results}\paper1\lifetable\csv\lifetablecensus_`x'_`fem'.csv", comma replace
	 
	}
}




	use "$results\paper1\lifetable\dataset\lifetablecensus_2011_female",clear
	append using "$results\paper1\lifetable\dataset\lifetablecensus_2011_male"

	save "$results\paper1\lifetable\dataset\lifetablecensus_2011",replace
	
	
