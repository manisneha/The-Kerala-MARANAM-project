*do file to compare srs, crs, and nfhs 1m0 rates and create graphs



**********************************************************************************
clear all

*set directory 


*bring in nfhs estimates calculated in 8.nfhs_nmx_child

	use "$inter\nfhs_4_child_mortality_year_kerala.dta", clear
	
	keep if age_group == 0
	drop age_group 
	drop deaths person_years 

	rename nmx nmx_nfhs
	rename tv_year year 
	
	replace nmx_nfhs = nmx_nfhs*1000
	
	tempfile nfhs
	save `nfhs'
	
*bring in srs nmx estimates (published by srs)

	use "$inter\srs_nmx.dta", clear	
	
	keep if age_group == 0
	drop age_group place age_group_old
	
	rename srs_nmx nmx_srs
	
	tempfile srs 
	save `srs'
	
*bring in crs nmx estimates using death counts from the kerala register data and 
*the DHS++ population


	use "$inter\nmx_allyears.dta", clear
	keep if age_group == 0

	keep year female nmx 
	rename nmx nmx_crs
	
	merge 1:1 female year using `nfhs'
	drop _merge 
	
	merge 1:1 female year using `srs'
	
	replace nmx_crs = nmx_crs * 1000 
	
	label define female 0 "male" 1 "female"
	lab val female female
	
	gen male = female == 0 
	label define male 0 "female" 1 "male"
	lab val male male
	
	
	
*make a graph 

	graph twoway ///
	(connected nmx_crs year, lpattern(longdash) msymbol(Sh)) ///
	(connected nmx_srs year, lpattern(dash) msymbol(Dh)) ///
	(lpoly nmx_nfhs year, lpattern(solid) bwidth(2)), ///
	by(male, ///
		graphregion(lcolor(white) fcolor(white)) ///
		note("Demographic Health Survey (DHS) estimates are smoothed and reflect two-year moving averages." ///
		     "DHS estimates are calculated by estimating person-years lived and deaths in each year. Sample" ///
			 "Registration System (SRS) estimates are from SRS annual reports. Civil Registration System (CRS)" ///
			 "estimates are calculated from observed CRS deaths and estimated mid-year population.", color(navy) size(small))) ///
	graphregion(lcolor(white) fcolor(white)) ///
	legend(order(2 "SRS" 1 "CRS" 3 "DHS") row(1) ///
	region(lcolor(white))) ///
	ylabel(0(4)16) ///
	xlabel(2004(4)2016) ///
	ytitle("mortality rate, 0-1, per 1,000 ({sub:1}m{sub:0})" "") ///
	subtitle(, margin(vsmall) ///
			fcolor(none) ///
			lcolor(white)) ///
	xtitle("") 
	graph export "$results\robustness\comparison1m0.pdf", replace
	graph export "$base\Keralam\writing\genus\draft1\comparison1m0.pdf", replace
	
	
*imr, crs v srs 

	import excel ///
	"$raw\comparison_imr2.xlsx", ///
	sheet("Sheet1") firstrow case(lower) clear
	
	graph twoway ///
	(connected crs_imr year, lpattern(longdash) msymbol(Sh)) ///
	(connected srs_imr year, lpattern(dash) msymbol(Dh)), ///
	graphregion(lcolor(white) fcolor(white)) ///
	legend(order(2 "SRS" 1 "CRS") row(2) ///
	region(lcolor(white)) ring(0) pos(7)) ///
	ylabel(0(4)16) ///
	xlabel(2006(4)2018) ///
	ytitle("infant mortality rate per 1,000 births " "") ///
	xtitle("") ///
	note("Civil Registration System (CRS) estimates are calculated by dividing infant deaths by births in a year." ///
	"Sample Registration System (SRS) rates are from annual summary reports prepared by the SRS", color(navy) size(small) pos(6))
	graph export "$results\robustness\comparison_imr.pdf", replace
	graph export "$base\Keralam\writing\genus\draft1\comparison_imr.pdf", replace

	
