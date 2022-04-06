/* Purpose : This do-files calculates the deaths rates nmx using 2016 census projections and compares it 
to the death rates calculated using the dhs population projections. The death counts are from the kerala register data


*/

*******************************************************************************************************************************

*using the Census projections dataset for 2016 downloaded from the Census website
*Excel sheet: Projected Population By Age and Sex As on 01st March : 2011-2036 ('000)

	import excel ///
	"$raw\2011_36.xlsx", ///
	sheet("projected population")  clear

*cleaning the dataset - keeping necessary variables and renaming variables

	keep A E F G /*keeping only 2016 numbers*/
	
	drop if E=="" | F=="" /*dropping empty rows*/
	
	rename E total_all /*total*/
	rename F total_0 /*male*/
	rename G total_1 /*female*/
	rename A age_group
	gen year=2016
	drop if total_all=="Person" /*droppign additional variable names*/
	drop total_all /*we only need male and female*/
	
	rename age_group age_group_old
			gen age_group=.
			**Need to create pop counts for ages 0-1 and 1-4
			replace age_group=0 if age_group_old=="0-1"
			replace age_group=1 if age_group_old=="0-4"
			replace age_group=5  if age_group_old=="5-9"
			replace age_group=10 if age_group_old=="10-14"
			replace age_group=15 if age_group_old=="15-19"
			replace age_group=20 if age_group_old=="20-24"
			replace age_group=25 if age_group_old=="25-29"
			replace age_group=30 if age_group_old=="30-34"
			replace age_group=35 if age_group_old=="35-39"
			replace age_group=40 if age_group_old=="40-44"
			replace age_group=45 if age_group_old=="45-49"
			replace age_group=50 if age_group_old=="50-54"
			replace age_group=55 if age_group_old=="55-59"
			replace age_group=60 if age_group_old=="60-64"
			replace age_group=65 if age_group_old=="65-69"
			replace age_group=70 if age_group_old=="70-74"
			replace age_group=75 if age_group_old=="75-79"
			replace age_group=80 if age_group_old=="80+"
			
	       
		   *since we do not have population counts for 15, 80-85, and 85+, we need to create
		   *placeholder rows for future imputation
	        expand 2 if age_group_old=="80+"
			bysort year age_group_old : gen n=_n
			replace age_group=85 if n==2 & age_group_old=="80+"
			foreach var in total_1 total_0 {
			replace `var'="" if age_group==85 |age_group_old=="0-4" /*Need to calcualte shares for */
			}
			drop n 

	destring,replace

	reshape long  total_, i(year age_group age_group_old) j(female) 
	rename total_ population_census
	replace population_census=population*1000
	gen population_old=population_census
	
	tempfile census2016_v1
	save `census2016_v1'
	
*******************************************************************************************************************************

*creating 80-85 and 85 plus population shares and calculating the population


**importing population estimates

	use "`census2016_v1'", clear

		keep if age_group_old=="Total" 
		rename population_census tot_pop
		keep tot_pop female year
		
	tempfile totpop
	save `totpop'

*bring in srs estimates 
	import excel "$raw\age_births_srs.xlsx", ///
	sheet("age") firstrow case(lower) clear
		replace age_group="80" if age_group=="80-84"
		replace age_group="85" if age_group=="85+"
		destring, replace
	
	tempfile base
	save `base'

	
	foreach var in 80 85 {
	
		use `base',clear
		
		keep if age_group=="`var'"
	 
		gen prop_f=total_female/100
		gen prop_m=total_male/100

		keep year age_group prop_f prop_m
		
		reshape long prop_ , i(year age_group) j(female) string
		replace female="1" if female=="f"
		replace female="0" if female=="m"
		rename  prop_ proportion	
		destring ,replace

		merge 1:m year female using "`totpop'", keep(3)
		
		tempfile data`var'
		save `data`var''
	
	}
	
	use "`data80'", clear
	append using "`data85'"
	

	gen population_census=int(proportion*tot_pop)	
	keep year age_group female population_census	
	merge 1:1 year age_group female using "`census2016_v1'", nogen 
	
	tempfile census2016_v2
	save `census2016_v2', replace

****************************************************************************************

*creating 0-1 and 1-4 shares and calculating the population
*Following the same process as in 4.0.nmx_allyears
 		
	use "$inter\interpolate_0_1_pop_proportion.dta", clear
		

		merge 1:m year female using "`totpop'", keep(3) nogen
	
		gen population_0=prop_0_1*tot_pop
	    gen population_1=prop_1_5*tot_pop
		
		reshape long population_ , i(year female prop*) j(age_group) 
		
		keep year female age_group population_ 
		rename population_ population_census
		
		replace population_census=int(population_census)
		sort year age_group female
		
		merge 1:1 year age_group female using "`census2016_v2'", nogen 

		drop if age_group_old=="Total"
		drop population_old age_group_old
		
		
	tempfile census2016_v3
	save `census2016_v3', replace

		

*******************************************************************************************************************************

	
*bring and merge kerala register death data 

	use "$inter\death_by_data.dta", clear
		
	*restrict to census period 

		keep if death_date >= td(01sep2015)
		keep if death_date <= td(31aug2016)
		
	*collapse into death counts by age group and sex 

		gen counter = 1
		
		collapse (sum) counter, by(age_group female)
		
		rename counter deaths 
		
		gen year=2016
		
		merge 1:1 age_group female year using "$inter/stateagg_agesexpop.dta" 



*gen mortality rates 

	gen nmx_dhs = deaths/ population
	
	keep nmx_dhs deaths year age_group female /*keeping only relevant variables*/
	
*Merging the data with census 2016

   merge 1:1 year age_group female using "`census2016_v3'", nogen	
   	gen nmx_census = deaths/ population_census

	
*gen logs

	gen log_dhs = ln(nmx_dhs*1000)
	gen log_census = ln(nmx_census*1000)
	
	
	save "$inter/nmx2016_census_vs_dhs_population.dta" , replace	

 
*******************************************************************************************************************************
*generating nmx plots comparing dhs and Census for all years 
 
	
 tempfile base 
 save `base'
	

forval x=2016/2016 {

   use "`base'", clear

    keep if year==`x'
	
	*Female

	graph twoway ///
	(connected log_dhs age_group if female == 1, ///
		lpattern(longdash) lcolor(navy)) ///
	(connected log_census age_group if female==1, ///
		lpattern(dash) lcolor(maroon)), ///
		legend(order(1 "Using estimated population" 2 "Using projected population") row(1) pos(11) ///
			ring(0) region(lcolor(white)) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("mortality rates per 1,000 (log scale)" " ") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Female, Kerala, `x'", pos(11) size(medsmall)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_dhscensus_female_`x'.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_dhscensus_female_`x'.tif", width(2000) replace
		
	*Male
	
	
	graph twoway ///
	(connected log_dhs age_group if female == 0, ///
		lpattern(longdash) lcolor(navy)) ///
	(connected log_census age_group if female==0, ///
		lpattern(dash) lcolor(maroon)), ///
		legend(order(1 "Using estimated population" 2 "Using projected population") row(1) pos(11) ///
			ring(0) region(lcolor(white)) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("mortality rates per 1,000 (log scale)" " ") ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid) ///
		xlabel(0 10 "10 years" 20(10)80) ///
		subtitle("Male, Kerala, `x'", pos(11) size(medsmall)) ///
		yscale(r(-2.5 5.5))
	graph save "$results\paper1\individual_graph\nmx_compare_dhscensus_male_`x'.gph", replace
	graph export "$results\paper1\individual_graph\nmx_compare_dhscensus_male_`x'.tif", width(2000) replace

	
	
	graph combine ///
	"$results\paper1\individual_graph\nmx_compare_dhscensus_female_`x'.gph" ///
	"$results\paper1\individual_graph\nmx_compare_dhscensus_male_`x'.gph", /// 
		row(2) ///
		xcom ycom ///
		graphregion(lcolor(white) fcolor(white)) ///
		xsize(3) ysize(4.5) ///
		note("Estimated population rates are calculated by dividing deaths for the calendar year by the" ///
		"population estimated by DHS program (2020). Census population rates are calculated by" ///
		"dividing deaths for the calendar year by the projected Census population for 2016.", size(vsmall) pos(6) color(navy))
	graph export "$results\paper1\combined_graph\nmx_compare_dhscensus_`x'.pdf", replace
	graph export "$results\paper1\combined_graph\nmx_compare_dhscensus_`x'.png", width(1000) replace
	graph export "$base\Keralam\writing\genus\draft1\nmx_compare_dhscensus_`x'.pdf", replace


		
	
	
}

