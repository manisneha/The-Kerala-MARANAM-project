*do file to create age specific mortality rates using Kerala death counts, DHS population estimates. 
*Compares SRS and CRS estimates




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
	
	drop if age_group=="0-4" /*additional age group*/
	drop if age_group=="All" /*additional age group*/

	destring age_group,replace
	
	save "$inter/srs_nmx.dta" , replace	
	
*******************************************************************************************************************************
*Creating the dataset to generate graphs to compare srs vs crvs nmx values. 
	
*bring and merge kerala death data 

	use "$inter/stateagg_agesexpop.dta" , clear	

*gen mortality rates for the register data from the daataset which has population and death counts

	gen nmx = deaths/ population
	
*Merging the data with asdr	of the srs data

   merge 1:1 year age_group female using "$inter/srs_nmx.dta", nogen	
	
*gen logs of the nmx values of srs and crvs. The graphs are on the log scale. 

	gen log_srs = ln(srs_nmx)
	gen log_crvs = ln(nmx*1000)
	
	
 save "$inter/nmx_allyears.dta", replace

 
*******************************************************************************************************************************
*generating nmx plots comparing crvs and srs for all years 
 
	
 tempfile base 
 save `base'
	

forval x=2006/2017 {

   use "`base'", clear

    keep if year==`x'
	
	*Female

	graph twoway ///
	(connected log_crvs age_group if female == 1, ///
		lpattern(solid) lcolor(navy)) ///
	(connected log_srs age_group if female==1, ///
		lpattern(dash) lcolor(maroon)), ///
		legend(order(1 "CRVS" 2 "SRS") row(1) pos(11) ///
			ring(0) region(lcolor(white)) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("mortality rates per 1,000" "") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Female, Kerala, `x'", pos(11)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_female_`x'.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_female_`x'.tif", width(2000) replace
		
	*Male
	
	
	graph twoway ///
	(connected log_crvs age_group if female == 0, ///
		lpattern(solid) lcolor(navy)) ///
	(connected log_srs age_group if female==0, ///
		lpattern(dash) lcolor(maroon)), ///
		legend(order(1 "CRVS" 2 "SRS") row(1) pos(11) ///
			ring(0) region(lcolor(white)) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("mortality rates per 1,000" "") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Male, Kerala, `x'", pos(11)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_male_`x'.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_male_`x'.tif", width(2000) replace

	
	
	graph combine ///
	"$results\paper1\individual_graph\nmx_compare_female_`x'.gph" ///
	"$results\paper1\individual_graph\nmx_compare_male_`x'.gph", /// 
		row(1) ///
		xcom ycom ///
		graphregion(lcolor(white) fcolor(white)) ///
		xsize(2) ysize(1) ///
		note("SRS rates are based on Sample Registration System Statistical Reports. CRVS rates are calculated by dividing" ///
		"deaths for the calendar year by the population estimated by the Demographic and Health Surveys", pos(6))
	graph export "$results\paper1\combined_graph\nmx_compare_`x'.pdf", replace
	graph export "$results\paper1\combined_graph\nmx_compare_`x'.png", width(1000) replace


		
	
	
}

graph combine ///
	"$results\paper1\individual_graph\nmx_compare_female_2006.gph" ///
	"$results\paper1\individual_graph\nmx_compare_female_2007.gph" ///
	"$results\paper1\individual_graph\nmx_compare_female_2008.gph" ///
	"$results\paper1\individual_graph\nmx_compare_female_2009.gph" ///
	"$results\paper1\individual_graph\nmx_compare_female_2010.gph" ///
	"$results\paper1\individual_graph\nmx_compare_female_2011.gph" ///
	"$results\paper1\individual_graph\nmx_compare_female_2012.gph" ///
	"$results\paper1\individual_graph\nmx_compare_female_2013.gph" ///
	"$results\paper1\individual_graph\nmx_compare_female_2014.gph" ///
	"$results\paper1\individual_graph\nmx_compare_female_2015.gph" ///
	"$results\paper1\individual_graph\nmx_compare_female_2016.gph" ///
	"$results\paper1\individual_graph\nmx_compare_female_2017.gph", ///		
		row(4) col(3) ///
		xcom ycom ///
		graphregion(lcolor(white) fcolor(white)) ///
		note("SRS rates are based on Sample Registration System Statistical Reports. CRVS rates are calculated by dividing" ///
		"deaths for the calendar year by the population estimated by the Demographic and Health Surveys", pos(6))
	graph export "$results\paper1\combined_graph\nmx_compare_female.pdf", replace
	graph export "$results\paper1\combined_graph\nmx_compare_female.png", width(1000) replace
	
	
*******************************************************************************************************************************

