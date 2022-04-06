/*do file to calculate 3 year averages of age specific mortality rates 



*/
*******************************************************************************************************************************

*Sneha's base files 
global base "C:\Users\sneha\Dropbox"
*Aashish's base files 
*global base "C:\Users\aashi\Dropbox"


*Creating other global file paths
global raw "$base\Keralam\data\stata\2.programs\6.submission_code\datasets\2.raw_data"
global results "$base\Keralam\data\stata\2.programs\6.submission_code\datasets\4.outputs"
global inter "$base\Keralam\data\stata\2.programs\6.submission_code\datasets\3.intermediate_data"
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
	
	keep if year>=2015 & year<=2017
	
	collapse srs_nmx , by(female age_group)
	
	rename srs_nmx srs_nmx_3avg
			

	drop if age_group=="0-4" /*additional age group*/
	drop if age_group=="All" /*additional age group*/

	destring age_group,replace
	

	save "$inter/srs_nmx_3year.dta" , replace	
	
	
*******************************************************************************************************************************
*Creating the dataset to generate graphs to compare srs vs crvs nmx values. 
	
*bring and merge kerala death data 

	use "$inter/stateagg_agesexpop.dta" , clear	

*gen mortality rates for the register data from the daataset which has population and death counts

	
	keep if year>=2015 & year<=2017
	
	collapse deaths population , by(female age_group)
	gen nmx = deaths/ population

	gen nmx_3avg=nmx*1000
	
	drop nmx
	
	*gen nmx_3avg=nmx_3tot/3
*Merging the data with asdr	of the srs data

   merge 1:1 age_group female using "$inter/srs_nmx_3year.dta", nogen	
   
	
*gen logs of the nmx values of srs and crvs. The graphs are on the log scale. 

	gen log_srs = ln(srs_nmx_3avg)
	gen log_crvs = ln(nmx_3avg)
	
	
 save "$inter/nmx_2015to2017.dta", replace

 
*******************************************************************************************************************************
*generating nmx plots comparing crvs and srs for all years 
 
	
 *tempfile base 
 *save `base'
	



   *use "`base'", clear

	
	*Female

	graph twoway ///
	(connected log_crvs age_group if female == 1, ///
		lpattern(solid) lcolor(navy) msymbol(Oh)) ///
	(connected log_srs age_group if female == 1, ///
			lpattern(dash) lcolor(maroon) mcolor(maroon) msymbol(Sh)), ///
		legend(order(1 "CRVS" 2 "SRS") row(1) pos(11) ///
			ring(0) region(lcolor(white)) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("average mortality rates per 1,000 (log scale)" " ") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Female, Kerala, 2015-2017", pos(11)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_female3year.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_female3year.tif", width(2000) replace
		
	*Male
	
	
graph twoway ///
	(connected log_crvs age_group if female == 0, ///
		lpattern(solid) lcolor(navy) msymbol(Oh)) ///
				(connected log_srs age_group if female == 0, ///
		lpattern(dash) lcolor(maroon) mcolor(maroon) msymbol(Sh)), ///
		legend(order(1 "CRVS" 2 "SRS" ) row(1) pos(11) ///
			ring(0) region(lcolor(white)) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("average mortality rates per 1,000 (log scale)" " ") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Male, Kerala, 2015-2017", pos(11)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_male3year.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_male3year.tif", width(2000) replace

	

	graph combine ///
	"$results\paper1\individual_graph\nmx_compare_female3year.gph" ///
	"$results\paper1\individual_graph\nmx_compare_male3year.gph", /// 
		row(1) ///
		xcom ycom ///
		graphregion(lcolor(white) fcolor(white)) ///
		xsize(2) ysize(1) ///
		note( ///
		"Sample Registration System (SRS) morality rates are three year averages from SRS Statistical Reports for 2015-2017." ///
		"Civil Registration System (CRVS) mortality rates are the 3 year average rates for 2015-2017.", pos(6))
	graph export "$results\paper1\combined_graph\nmx_compare3year.pdf", replace
	graph export "$results\paper1\combined_graph\nmx_compare3year.png", width(1000) replace
	
		graph combine ///
	"$results\paper1\individual_graph\nmx_compare_female3year.gph" ///
	"$results\paper1\individual_graph\nmx_compare_male3year.gph", /// 
		row(2) ///
		xcom ycom ///
		graphregion(lcolor(white) fcolor(white)) ///
		xsize(1.5) ysize(2) ///
		note( ///
		"Sample Registration System (SRS) morality rates are three year averages from SRS Statistical" ///
		"Reports for 2015-2017. Civil Registration System (CRVS) mortality rates are the 3 year average" ///
		"rates for 2015-2017.", size(vsmall) pos(6))
	graph export "$results\paper1\combined_graph\nmx_compare3year_long.pdf",  replace
	graph export "$results\paper1\combined_graph\nmx_compare3year_long.png", width (500) replace
    graph export "$base\Keralam\writing\genus\draft1\nmx_compare3year_long.pdf",  replace


	*******************************************************************************************************************************

