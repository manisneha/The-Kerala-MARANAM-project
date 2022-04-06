*do file to create 5 year averages of age specific mortality rates 

*******************************************************************************************************************************


*******************************************************************************************************************************

*SRS DATA
*bring in and save asdr_kerala_srs data, this is the SRS data for Kerala. 
*the srs_nmx dataset is organized, formatted by age groups, sex and year.
*0-4 agr  
*Data source: 


	import excel ///
	"$raw\asdr_kerala_srs.xlsx", ///
	sheet("Sheet1") firstrow clear
	
	keep place age_group* year total_female total_male	
	reshape long total_ , i(year age_group) j(female) string	
	rename total_ srs_nmx	
	
	replace female="1" if female=="female"
	replace female="0" if female=="male"
	
	destring female srs_nmx, replace
	
	keep if year>=2013 & year<=2017
	
	collapse srs_nmx , by(female age_group)
	
	rename srs_nmx srs_nmx_5avg
	
	*gen =srs_nmx_5tot/5
		
	save "$base\Keralam\data\srs\asdr_kerala_srs_5year.dta", replace

	drop if age_group=="0-4" /*additional age group*/
	drop if age_group=="All" /*additional age group*/

	destring age_group,replace
	

	save "$inter/srs_nmx_5year.dta" , replace	
	
**********************************************************************************************
*SRS abridged life tables

import excel ///
	"$base\Keralam\data\srs\alt.xlsx", ///
	sheet("Sheet1") firstrow clear

	keep if period=="2013-2017"
	
	keep age male* female*
	
	*gen nmx from lx nLx
	
	foreach var in male female {
	
	
	gen ndx_`var'=`var'_lx[_n]-`var'_lx[_n+1]
	replace ndx_`var' = `var'_lx if ndx_`var' == . 
	
	
	
	gen nmx_`var'=(ndx_`var'/`var'_nlx)*1000
	
	}
*	replace nmx_`var'=(`var'_lx/`var'_nlx)*1000 if age=="85+"
*	gen srsalt_nmx_5avg_`var'=nmx_`var'/5
*	}

	keep *nmx*  age
	
	
	reshape long nmx_ , i(age) string
	gen female=1 if _j=="female"
	replace female=0 if _j=="male"
	drop _j
	
	rename nmx_ srsalt_nmx_5avg
	
	gen age_group=.
	replace age_group=0 if age=="0-1"
	replace age_group=1 if age=="1-5"
	replace age_group=5 if age=="5-10"
	replace age_group=10 if age=="10-15"
	replace age_group=15 if age=="15-20"
	replace age_group=20 if age=="20-25"
	replace age_group=25 if age=="25-30"
	replace age_group=30 if age=="30-35"
	replace age_group=35 if age=="35-40"
	replace age_group=40 if age=="40-45"
	replace age_group=45 if age=="45-50"
	replace age_group=50 if age=="50-55"
	replace age_group=55 if age=="55-60"
	replace age_group=60 if age=="60-65"
	replace age_group=65 if age=="65-70"
	replace age_group=70 if age=="70-75"
	replace age_group=75 if age=="75-80"
	replace age_group=80 if age=="80-85"
	replace age_group=85 if age=="85+"

	save "$inter/altsrs_nmx_5year.dta" , replace	

	
*******************************************************************************************************************************
*Creating the dataset to generate graphs to compare srs vs crvs nmx values. 
	
*bring and merge kerala death data 

	use "$inter/stateagg_agesexpop.dta" , clear	

*gen mortality rates for the register data from the daataset which has population and death counts

	
	keep if year>=2013 & year<=2017
	
	collapse deaths population , by(female age_group)
	
	gen nmx = deaths/ population

	gen nmx_5avg=nmx*1000
	
	drop nmx
	
	*gen nmx_5avg=nmx_5tot/5
*Merging the data with asdr	of the srs data

   merge 1:1 age_group female using "$inter/srs_nmx_5year.dta", nogen	
   
*Merging the data with asdr	of the 5 year abrdged srs life table data

   merge 1:1 age_group female using "$inter/altsrs_nmx_5year.dta", nogen	
	
*gen logs of the nmx values of srs and crvs. The graphs are on the log scale. 

	gen log_srs = ln(srs_nmx_5avg)
	gen log_crvs = ln(nmx_5avg)
	gen log_altsrs = ln(srsalt_nmx_5avg)
	
	
 save "$inter/nmx_2013to2017.dta", replace

 
*******************************************************************************************************************************
*generating nmx plots comparing crvs and srs for all years 
 
	
 tempfile base 
 save `base'
	



   use "`base'", clear

	
	*Female

	graph twoway ///
	(connected log_crvs age_group if female == 1, ///
		lpattern(solid) lcolor(navy) msymbol(Oh) msize(*1.1)) ///
	(connected log_altsrs age_group if female==1, ///
		lpattern(dash_dot) lcolor(dkgreen) mcolor(green) msymbol(D) msize(*.8)) ///
	(connected log_srs age_group if female == 1, ///
		lpattern(dash) lcolor(maroon) mcolor(maroon) msymbol(Sh)), ///
		legend(order(1 "CRVS" 3 "SRS 5-year average" 2 "SRS Abridged life table") row(1) pos(11) ///
			ring(0) region(lcolor(white)) symysize(3) colgap(1.5) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("average mortality rates per 1,000 (log scale)" " ") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Female, Kerala, 2013-2017", pos(11)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_female5year.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_female5year.tif", width(2000) replace
		
	*Male
	
	
graph twoway ///
	(connected log_crvs age_group if female == 0, ///
		lpattern(solid) lcolor(navy) msymbol(Oh)  msize(*1.1)) ///
	(connected log_altsrs age_group if female==0, ///
		lpattern(dash_dot) lcolor(dkgreen) mcolor(green) msymbol(D) msize(*.8)) ///
	(connected log_srs age_group if female == 0, ///
		lpattern(dash) lcolor(maroon) mcolor(maroon) msymbol(Sh)), ///
		legend(order(1 "CRVS" 3 "SRS 5-year average" 2 "SRS Abridged life table") row(1) pos(11) ///
			ring(0) region(lcolor(white)) symysize(3) colgap(0.8) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("average mortality rates per 1,000 (log scale)" " ") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Male, Kerala, 2013-2017", pos(11)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_male5year.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_male5year.tif", width(2000) replace

	
	
	graph combine ///
	"$results\paper1\individual_graph\nmx_compare_female5year.gph" ///
	"$results\paper1\individual_graph\nmx_compare_male5year.gph", /// 
		row(1) ///
		xcom ycom ///
		graphregion(lcolor(white) fcolor(white)) ///
		xsize(2) ysize(1) ///
		note( ///
		"Sample Registration System (SRS) morality rates are the 5 year average rates calculated using annual SRS" ///
		"Statistical Reports for 2013-2017 Civil Registration System (CRVS) mortality rates are the 5 year period" ///
		"2013-2017. The CRVS mortality rates use population estimates" ///
		"calculated by the DHS Program (2020).  The SRS Abridged Life Table mortality rates are for 2013-2017.", pos(6))
	graph export "$results\paper1\combined_graph\nmx_compare5year.pdf", replace
	graph export "$results\paper1\combined_graph\nmx_compare5year.png", width(1000) replace

	
	
		graph combine ///
	"$results\paper1\individual_graph\nmx_compare_female5year.gph" ///
	"$results\paper1\individual_graph\nmx_compare_male5year.gph", /// 
		row(2) ///
		xcom ycom ///
		graphregion(lcolor(white) fcolor(white)) ///
		xsize(1.5) ysize(2) ///
		note( ///
		"Sample Registration System (SRS) morality rates are the 5 year average rates calculated using annual" ///
		"SRS Statistical Reports for 2013-2017. Civil Registration System (CRVS) mortality rates are the 5 year" ///
		"period 2013-2017. The CRVS mortality rates use population estimates calculated by the DHS" ///
		"Program (2020). The SRS Abridged Life Table mortality rates are for 2013-2017.", pos(6) size(vsmall))
	graph export "$results\paper1\combined_graph\nmx_compare5year_long.pdf", replace
	graph export "$results\paper1\combined_graph\nmx_compare5year_long.png", width(1000) replace
    graph export "$base\Keralam\writing\genus\draft1\nmx_compare5year_long.pdf",  replace


	*******************************************************************************************************************************
