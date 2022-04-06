*This do file is to estimate the life table by year and sex with gomperz corrections (2006-2017)


**********************************************************************************
	
clear all
*creating an empty dataset
	
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
	drop _merge
	
   foreach var in nax  nmx  {	
	format `var' %9.4f
	}	

	tempfile data
	save `data'
	
	**Gompertz is only for ages 40 and above
	
	sort year female age_group	
	keep if age_group>=40
	
    *generating gompertz coefficeints
	
	gen l_nmx = ln(nmx)		
	statsby, by(female year) clear: reg l_nmx age_group
	rename (_b_cons _b_age_group) (alpha beta)
	
	
	*merging gompertz coefficients with the data
	
	merge 1:m year female using "`data'", nogen
	
	keep if age_group>=40
	
	gen mxhat=exp(alpha + (beta*age_group)) if age_group>=40 /*noymer paper formula*/
	
	
	*the rest of it follows the standard life table method. mxhat are the reestimated mortality rates. 
	
	*nqx
	cap drop nqx
	gen nqx = (n*mxhat) / (1 + (n-nax)*mxhat)
	replace nqx = 1 if nqx==.
	
	gen npx=1-nqx
		
	*radix
	cap drop lx
	sort year female age_group
	by year female: gen lx = 1 if _n==1
		
	*lx
	forval i=2(1)10 {
		by year female: replace lx = (lx[_n-1]*(1-nqx[_n-1])) if _n==`i'
	}
	
	
	sort year female age_group	
	
	rename (lx nqx npx) (lxmod qxmod pxmod )
	 
	cap drop nLx
	gen nLx_gomp=.
	forval i=1(1)10 {
		by year female: replace nLx_gomp = (lxmod[_n+1]*n) + (nax*lxmod*qxmod) if _n==`i'
	}
	by year female: replace nLx_gomp = lxmod/mxhat if _n==10 /*open interval*/
	
	*total PY (for Tx)
	cap drop total_py
	bysort year female: egen total_py = total(nLx_gomp) 

	*Tx
	cap drop Tx_gomp
	gen Tx_gomp = .
	by year female: replace Tx_gomp = total_py - sum(nLx_gomp) + nLx_gomp

	*ex_gomp
	cap drop ex_gomp
	gen ex_gomp = Tx_gomp / lxmod
	replace ex_gomp = round(ex_gomp, .1)
	
	merge 1:1 year female age_group using  "$results\paper1\lifetable\dataset\lifetable_2006to2017.dta"
	
	tempfile excomp
	save `excomp'
	
	***********************
	
	*Graph
	forval x=0/1 {
	
	use "`excomp'", clear
	
	keep if female==`x'
	
	keep if age_group>=40
	
	graph twoway ///
	 (connected ex age_group , lpattern(longdash) lcolor(navy)  msymbol(Sh) mlw(medthin) msize(small) mlabel(ex) ///
	 mlabposition(8) mlabsize(vsmall)) ///
	 (connected ex_gomp age_group , lpattern(dash) lcolor(maroon) msymbol(Dh) mlw(medthin) msize(small)  ///
	 mlabel(ex_gomp) ///
	 mlabsize(vsmall)),  ///
	by(year, rows(4) ///
			graphregion(lcolor(white) fcolor(white)) ///
			note("",size(vsmall))) ///
		legend(order(1 "Unadjusted Life expectancy" 2 "Gompertz adjusted Life Expectancy") row(1)  ///
			ring(0) region(lcolor(white)) ///
			size(vsmall)) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("Life expectancy (e{sub:x})" "", size(small)) ///
		xtitle("") ///
		ylabel( 0 20 "20 years" 40 , nogrid labsize(medsmall)) ///
		xlabel(35 " " 40 60 "60 years" 80, labsize(medsmall)) ///
		subtitle(, fcolor(none) ///
			lcolor(white)) ///
			xsize(4.5) ysize(6)
		
    graph export "$results\paper1\combined_graph\ex_compare_`x'.pdf", replace
		graph export "$base\Keralam\writing\genus\draft1\ex_compare_`x'.pdf", replace
			
		}
