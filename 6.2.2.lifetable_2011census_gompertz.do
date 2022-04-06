/***Estimate life table using census 2011 population and mid year deaths
*the deaths counts refer to 1sep2010 to 31aug2011
*with gompertz corrections

*****/


	*import
	
	import excel ///
	"$raw\census_2011_single_age_sex_residence.xls", ///
	sheet("overall") firstrow clear
	
	keep age male_total female_total
	rename male_total male 
	rename female_total female 
	
	drop if age == . 


*create life table age categories 
	
	
*reshape 

	rename male pop0
	rename female pop1 
	
	reshape long pop, i(age) j(female)
	
	*need to replace the population of 90 and above by 90
	gsort female -age	
	by female : gen t=sum(pop)	
	replace pop=t if age==90	
	drop if age>90
	drop t
		
*save 

	save "$inter\c2011_age_count_single.dta", replace 
	
	
	
*notes
*so the census estimates pop on march 1, 2011
*see http://censusindia.gov.in/2011census/PCA/PCA_Highlights/pca_highlights_file/India/4Executive_Summary.pdf
*so what if we restrict the data to 6 months before, and 6 months after this date
*so we are restrincting it to deaths from 1sep2010 to 31aug2011

*bring and merge death data 
*lets do this in single year age groups 

	use "$inter\death_by_data.dta", clear
	
*restrict to census period 

	keep if death_date >= td(01sep2010)
	keep if death_date <= td(31aug2011)
	
*let 110 be the last age 
	drop if age_death == .
	replace age_death = 90 if age_death >90
	
*collapse into death counts by age group and sex 

	gen counter = 1
	
	collapse (sum) counter, by(age_death female)
	
	rename counter deaths 
	rename age_death age

*merge pop data 

	merge 1:1 age female using "$inter\c2011_age_count_single.dta", nogen
	
	*save 
	save "$inter\c2011_pop_deaths_single.dta", replace

*gen mortality rates 

	gen nmx = deaths / pop
	
	gen year=2011
	
	
	tempfile data
	save `data'
	
	keep if age>=40

*Calculating gompertz coefficients and calculating mxhat
	
	gen l_nmx = ln(nmx)		
	statsby, by(female year) clear: reg l_nmx age
	rename (_b_cons _b_age) (alpha beta)
	
	merge 1:m year female using "`data'", nogen	
	
	keep if age>=40
	gen mxhat=exp(alpha + (beta*age)) if age>=40 /*noymer paper formula*/
	gen nax=0.5	
	gen n=1
	
	
	**************************************************************************************************
	*Gompertz life expectancy 
	
	*the rest of it follows the standard life table method. mxhat are the reestimated mortality rates. 
	
	*nqx
	cap drop nqx_g
	gen nqx_g = (n*mxhat) / (1 + (n-nax)*mxhat)
	replace nqx_g = 1 if age==90 
	
	gen npx_g=1-nqx_g
		
	*radix
	cap drop lx_g
	sort year female age
	by year female: gen lx_g = 1 if _n==1
		
	*lx
	forval i=2(1)51 {
	by year female: replace lx_g = (lx_g[_n-1]*(1-nqx_g[_n-1])) if _n==`i'
	}
	
	sort year female age	
	 
	*ndx 
	gen ndx_g = . 
	forval i=1(1)51 {
	by year female: replace ndx_g = (lx_g[_n] - lx_g[_n+1]) if _n==`i'
	}

		
	*nLx
	cap drop nLx_g
	gen nLx_g=.
	forval i=1(1)51 {
		by year female: replace nLx_g = (lx_g[_n+1]*n) + (nax*lx_g*nqx_g) if _n==`i'
	}
	by year female: replace nLx_g = lx_g/mxhat if _n==51 /*open interval*/
	
	*total PY (for Tx)
	cap drop total_py_g
	bysort year female: egen total_py_g = total(nLx_g) 

	*Tx
	cap drop Tx_g
	gen Tx_g = .
	by year female: replace Tx_g = total_py_g - sum(nLx_g) + nLx_g

	*ex_gomp
	cap drop ex_g
	gen ex_g = Tx_g / lx_g
	replace ex_g = round(ex_g, .1)
	
	**********************************************************************************************
	*Unadjusted life expectancy 
	
	cap drop nqx
	gen nqx = (n*nmx) / (1 + (n-nax)*nmx)
	replace nqx = 1 if age==90 

	
	gen npx=1-nqx
		
	*radix
	sort year female age
	by year female: gen lx = 1 if _n==1
		
	*lx
	forval i=2(1)51 {
		by year female: replace lx = (lx[_n-1]*(1-nqx[_n-1])) if _n==`i'
	}
	
	
	sort year female age	
	
	*ndx 
	gen ndx = . 
		forval i=1(1)51 {
		by year female: replace ndx = (lx[_n] - lx[_n+1]) if _n==`i'
	}

	 
	gen nLx=.
	forval i=1(1)51 {
		by year female: replace nLx = (lx[_n+1]*n) + (nax*lx*nqx) if _n==`i'
	}
	by year female: replace nLx = lx/nmx if _n==51 /*open interval*/
	
	*total PY (for Tx)
	bysort year female: egen total_py = total(nLx) 

	*Tx
	gen Tx= .
	by year female: replace Tx= total_py - sum(nLx) + nLx

	*ex
	gen ex = Tx/ lx
	replace ex = round(ex, .1)
	
	tempfile excomp_census2011
	save `excomp_census2011'
	
	gen male = female == 0
	 label define male 0 "Female" 1 "Male"
	 lab val male male
	
*********************************************************************************
*graphs 

	*ex comparison
	
	graph twoway ///
	 (line ex age , lpattern(solid) lcolor(navy)  msymbol(Sh) mlw(medthin) msize(vsmall)) ///
	 (line ex_g age , lpattern(dash_dot) lcolor(maroon) msymbol(Dh) mlw(medthin) msize(vsmall)),  ///
	by(male, rows(1) ///
			graphregion(lcolor(white) fcolor(white)) ///
			note("",size(vsmall)) ///
			subtitle("life expectancy at age x (e{sub:x})", size(small))) ///
		legend(order(1 "Unadjusted" 2 "Gompertz") row(1)  ///
			ring(0) region(lcolor(white)) ///
			size(small)) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("e{sub:x} (years)" "", size(small)) ///
		xtitle("", size(medium)) ///
		ylabel( 0 10 20 "20" 30 40 , nogrid labsize(small)) ///
		xlabel(40 50 60 "60 years" 70 80 90 "90+", labsize(small)) ///
		subtitle(, fcolor(none) ///
			lcolor(white) size(small))
	graph save "$results\paper1\combined_graph\ex_gompertz_c2011.gph", replace
	
	
	*nmx comparison
	gen log_nmx = ln(nmx*1000)
	gen log_nmx_gomp = ln(mxhat*1000)
		
	*nmx comparison	
	graph twoway ///
	 (line log_nmx age , lpattern(solid) lcolor(navy)  msymbol(Sh) mlw(medthin) msize(vsmall)) ///
	 (line log_nmx_gomp age , lpattern(dash_dot) lcolor(maroon) msymbol(Dh) mlw(medthin) msize(vsmall)),  ///
	by(male, rows(1) ///
			graphregion(lcolor(white) fcolor(white)) ///
			note("",size(vsmall)) ///
			subtitle("mortality rate in the age interval ({sub:1}m{sub:x})", size(small))) ///
		legend(order(1 "Unadjusted" 2 "Gompertz") row(1)  ///
			ring(0) region(lcolor(white)) ///
			size(small)) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("{sub:1}m{sub:x} per 1,000 (log scale)" "" "", size(small)) ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid labsize(small)) ///
		xlabel(40 50 60 "60 years" 70 80 90 "90+", labsize(small)) ///
		subtitle(, fcolor(none) ///
			lcolor(white) size(small))
			
	graph save "$results\paper1\combined_graph\nmx_gompertz_c2011.gph", replace
	
			
	
	*lx comparison 
	replace lx = lx*1000 
	replace lx_g = lx_g*1000
	
	graph twoway ///
	 (line lx age , lpattern(solid) lcolor(navy)  msymbol(Sh) mlw(medthin) msize(vsmall)) ///
	 (line lx_g age , lpattern(dash_dot) lcolor(maroon) msymbol(Dh) mlw(medthin) msize(vsmall)),  ///
	by(male, rows(1) ///
			graphregion(lcolor(white) fcolor(white)) ///
			note("", size(vsmall)) ///
			subtitle("survivors to age x (l{sub:x})", size(small))) ///
		legend(order(1 "Unadjusted" 2 "Gompertz") row(1)  ///
			ring(0) region(lcolor(white)) ///
			size(small)) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("l{sub:x}" "" "", size(small)) ///
		xtitle("") ///
		ylabel(0(250)1000, nogrid labsize(small)) ///
		xlabel(40 50 60 "60 years" 70 80 90 "90+", labsize(small)) ///
		subtitle(, fcolor(none) ///
			lcolor(white) size(small))
	graph save "$results\paper1\combined_graph\lx_gompertz_c2011.gph", replace

	
	*ndx comparison 
	replace ndx = ndx*1000 
	replace ndx_g = ndx_g*1000
	
	graph twoway ///
	(line ndx age , lpattern(solid) lcolor(navy)  msymbol(Sh) mlw(medthin) msize(vsmall)) ///
	(line ndx_g age , lpattern(dash_dot) lcolor(maroon) msymbol(Dh) mlw(medthin) msize(vsmall)),  ///
	by(male, rows(1) ///
			graphregion(lcolor(white) fcolor(white)) ///
			note("", size(vsmall)) ///
			subtitle("life-table deaths in the age-interval ({sub:1}d{sub:x})", size(small))) ///
		legend(order(1 "Unadjusted" 2 "Gompertz") row(1)  ///
			ring(0) region(lcolor(white)) ///
			size(small)) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("{sub:1}d{sub:x}" "" "", size(small)) ///
		xtitle("") ///
		ylabel(, nogrid labsize(small)) ///
		xlabel(40 50 60 "60 years" 70 80 90 "90+", labsize(small)) ///
		subtitle(, fcolor(none) ///
			lcolor(white) size(small))
	graph save "$results\paper1\combined_graph\ndx_gompertz_c2011.gph", replace

	
*combine graph 

	graph combine ///
	"$results\paper1\combined_graph\nmx_gompertz_c2011.gph" ///
	"$results\paper1\combined_graph\lx_gompertz_c2011.gph" ///
	"$results\paper1\combined_graph\ndx_gompertz_c2011.gph" ///
	"$results\paper1\combined_graph\ex_gompertz_c2011.gph", ///
	col(2) ///
	graphregion(lcolor(white) fcolor(white)) ///
	xsize(3) ysize(2) imargin(vsmall) ///
	note("Note: Radix in the l{sub:x} graphs starts at age 40. The open-ended age interval is age 90. Age-groups in x axis are in single age years. Unadusted rates " ///
	"use Census 2011 as exposures, and deaths in the period Sep 1, 2010 -- Aug 31, 2011. Gompertz mortality rates are predicted age-specific " ///
	"mortality rates using the unadjusted mortality rates in single ages. Both sets of life tables assume an {sub:n}a{sub:x} of 0.5." ///
	, pos(6) size(vsmall) color(navy))
	graph export "$results\paper1\combined_graph\gompertz_c2011.pdf", replace

	
	

	
