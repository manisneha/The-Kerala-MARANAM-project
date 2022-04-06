*do file to create nmx using 2011 census populations - follows the same methods as the earlier do-files


*******************************************************************************************************************************
*Importing population counts by age and sex for Census 2011

use "$inter\c2011_age_count_total.dta", clear
	rename pop population_census
	gen year=2011
	
	tempfile census2011
	save `census2011'
	
	

*******************************************************************************************************************************

	
*bring and merge kerala death data calculated using DHS++ population exposure.

	use "$inter/stateagg_agesexpop.dta" , clear
	

*gen mortality rates when the denominator is the population from the DHS++ data. The reference period for the deaths counts is 
*January 1 2011 to Decemeber 31 2011. 

	gen nmx_dhs = deaths/ population
	
*Merging the data with Census 2011 population counts

   merge 1:1 year age_group female using "`census2011'", nogen	
   	gen nmx_census = deaths/ population_census

	
*gen logs

	gen log_dhs = ln(nmx_dhs*1000)
	gen log_census = ln(nmx_census*1000)
	
	
	save "$inter/census2011_nmx.dta" , replace	

 
*******************************************************************************************************************************
*generating nmx plots comparing crvs and Census for 2011
 
	
 tempfile base 
 save `base'
	

forval x=2011/2011 {

   use "`base'", clear

    keep if year==`x'
	
	*Female

	graph twoway ///
	(connected log_dhs age_group if female == 1, ///
		lpattern(longdash) lcolor(navy)) ///
	(connected log_census age_group if female==1, ///
		lpattern(dash) lcolor(maroon)), ///
		legend(order(1 "Estimated population" 2 "Census population") row(1) pos(11) ///
			ring(0) region(lcolor(white)) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("mortality rates per 1,000" "") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Female, Kerala, `x'", pos(11)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_dhscensus_female_`x'.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_dhscensus_female_`x'.tif", width(2000) replace
		
	*Male
	
	
	graph twoway ///
	(connected log_dhs age_group if female == 0, ///
		lpattern(longdash) lcolor(navy)) ///
	(connected log_census age_group if female==0, ///
		lpattern(dash) lcolor(maroon)), ///
		legend(order(1 "Estimated population" 2 "Census population") row(1) pos(11) ///
			ring(0) region(lcolor(white)) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("mortality rates per 1,000" "") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Male, Kerala, `x'", pos(11)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_dhscensus_male_`x'.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_dhscensus_male_`x'.tif", width(2000) replace

	
	
	graph combine ///
	"$results\paper1\individual_graph\nmx_compare_dhscensus_female_`x'.gph" ///
	"$results\paper1\individual_graph\nmx_compare_dhscensus_male_`x'.gph", /// 
		row(1) ///
		xcom ycom ///
		graphregion(lcolor(white) fcolor(white)) ///
		xsize(2) ysize(1) ///
		note("Eestimated population rates are calculated by dividing deaths for the calendar year by the population estimated by Leddy Jr (2016)." ///
		"Census population rates are calculated by dividing deaths for the calendar year by the 2011 Census population", size(vsmall))
	graph export "$results\paper1\combined_graph\nmx_compare_dhscensus_`x'.pdf", replace
	graph export "$results\paper1\combined_graph\nmx_compare_dhscensus_`x'.png", width(1000) replace
	graph export "$base\Keralam\writing\genus\draft1\nmx_compare_dhscensus_`x'.pdf", replace
	
	
}

******************************************************************
*In this section of the code, we repeat the previous exercise but the reference period for the death counts from the kerala
*register data is 1 Sep 2010 to 31 Aug 2011

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

*merge death count data with the Census 2011 population counts by sex and age group

	merge 1:1 age_group female using "$inter\c2011_age_count_total.dta", nogen

*gen mortality rates 

	gen nmx_censusmid = deaths / pop
	
	gen year=2011
	
	keep nmx_censusmid year female age_group /*keeping only necessary variables*/
	
	*bring and merge kerala death count data and DHS++ population counts

	merge 1:1 age_group female year using "$inter/stateagg_agesexpop.dta" 
	

*gen mortality rates 

	gen nmx_dhs = deaths/ population

	
*gen logs

	gen log_dhs = ln(nmx_dhs*1000)
	gen log_censusmid = ln(nmx_censusmid*1000)
	
	
	save "$inter/censusmid2011_nmx.dta" , replace	

 
*******************************************************************************************************************************
*generating nmx plots comparing crvs and censusmid for all years 
 
	
 tempfile base 
 save `base'
	

forval x=2011/2011 {

   use "`base'", clear

    keep if year==`x'
	
	*Female

	graph twoway ///
	(connected log_dhs age_group if female == 1, ///
		lpattern(longdash)    lcolor(navy) msymbol(Sh) mlw(medthin) msize(small)) ///
	(connected log_censusmid age_group if female==1, ///
		lpattern(dash)  lcolor(maroon) msymbol(Dh) mlw(medthin) msize(small) ), ///
		legend(order(1 "Using estimated population" 2 "Using Census population") row(1) pos(11) ///
			ring(0) region(lcolor(white)) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("mortality rates per 1,000 (log scale)" " ") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Female, Kerala, `x'", pos(11) size(medsmall)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_dhscensusmid_female_`x'.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_dhscensusmid_female_`x'.tif", width(2000) replace
		
	*Male
	
	
	graph twoway ///
	(connected log_dhs age_group if female == 0, ///
		lpattern(longdash)   lcolor(navy) msymbol(Sh) mlw(medthin) msize(small) mfcolor(navy)) ///
	(connected log_censusmid age_group if female==0, ///
		lpattern(dash)  lcolor(maroon) msymbol(Dh) mlw(medthin) msize(small) mfcolor(maroon)), ///
		legend(order(1 "Using estimated population" 2 "Using Census population") row(1) pos(11) ///
			ring(0) region(lcolor(white)) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("mortality rates per 1,000 (log scale)" " ") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Male, Kerala, `x'", pos(11) size(medsmall)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_dhscensusmid_male_`x'.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_dhscensusmid_male_`x'.tif", width(2000) replace

	
	
	graph combine ///
	"$results\paper1\individual_graph\nmx_compare_dhscensusmid_female_`x'.gph" ///
	"$results\paper1\individual_graph\nmx_compare_dhscensusmid_male_`x'.gph", /// 
		row(2) ///
		xcom ycom ///
		graphregion(lcolor(white) fcolor(white)) ///
		xsize(3) ysize(4.5) ///
		note("Estimated population rates are calculated by dividing deaths for the calendar year by the" ///
		"population estimated by DHS program (2020). Census population rates are calculated by" ///
		"dividing deaths from Sep 1, 2010 to Aug 31, 2011 by the 2011 Census population.",   ///                                                                                                                                               ", ///
		size(vsmall) pos(6)  color(navy))
	graph export "$results\paper1\combined_graph\nmx_compare_dhscensusmid_`x'.pdf", replace
	graph export "$results\paper1\combined_graph\nmx_compare_dhscensusmid_`x'.png", width(1000) replace
	graph export "$base\Keralam\writing\genus\draft1\nmx_compare_dhscensusmid_`x'.pdf", replace


		
	
	
}


