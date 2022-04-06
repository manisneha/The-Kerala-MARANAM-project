*Purpose : To create the final nmx graph using the data generated in 4.0.nmx_allyears
**tabulate the sd in the nmx values
**Either Sneha or Aashish made edits


****************************************************************************************************************

*******************************************************************************************************************************
	
 use "$inter/nmx_allyears.dta", replace

 gen ratio= (nmx*1000) / srs_nmx
 
 gen ratio_ln =ln(ratio)
 
*******************************************************************************************************************************
*generating nmx plots comparing crvs and srs for all years 
 
	
 tempfile base 
 save `base'
 
 *drop years not in analysis sample 
	 drop if year < 2006
	 drop if year > 2017	
 
 *generate othe variables needed for graphs
	 sort year female age_group
	 bysort year female  : gen tick=_n
	 
	 gen male = female == 0
	 label define male 0 "female" 1 "male"
	 lab val male male
	 
	 gen line = 0
  
	 
 
 	graph twoway ///
	(line line tick, mcolor(black)) ///
	 (scatter ratio_ln tick if female==1 , mcolor(maroon)  msymbol(S) mlw(thin) msize(1.1)) ///
	 (scatter ratio_ln tick if female==0 , mcolor(navy)  msymbol(D) mlw(thin) msize(1.1)),  ///
		by(year, rows(4) ///
			graphregion(lcolor(white) fcolor(white)) ///
			note("",size(vsmall))) ///
		legend(order(2 "Female" 3 "Male") row(1)  ///
			ring(0) region(lcolor(white)) ///
			size(vsmall) symp(12) keygap(*.4) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("Ratio of mortality rates ({sub:n}m{sub:x} ratio): log (CRS/SRS)" " ", size(small)) ///
		xtitle("") ///
		ylabel(-1.39 "0.25" -0.69 "0.5" 0 "1" .69 "2" 1.39 "4", nogrid labsize(small)) ///
		xlabel( 1 "0" 2 "1" 3 "5" 7 "25 yrs" 11"45" 15 "65" 19 "85", labsize(small)) ///
		subtitle(, fcolor(none) ///
			lcolor(white)) ///
			xsize(4.5) ysize(6)
	graph export "$results\paper1\combined_graph\mx_crvs_vs_srs.pdf", replace
	graph export "$results\paper1\combined_graph\mx_crvs_vs_srs.png", width(1000) replace
	graph export "$base\Keralam\writing\genus\draft1\mx_crvs_vs_srs.pdf", replace 
 
 
 
 ***********generating table values
 
  use "$inter/nmx_allyears.dta", replace
	keep year age_group female nmx srs_nmx
	gen crvs_nmx=nmx*1000
	drop nmx
	keep if year>2005 & year<2018
	rename crvs_nmx crvs_nmx_
	rename srs_nmx srs_nmx_
	reshape wide crvs_nmx srs_nmx, i(year age_group) j(female) 

	foreach var in srs_nmx_0 crvs_nmx_0 srs_nmx_1 crvs_nmx_1 {
		rename `var' `var'_
	}
	
	order year age_group  crvs_nmx_1_ crvs_nmx_0_ srs_nmx_1_ srs_nmx_0_

	reshape wide  crvs_nmx_1_ crvs_nmx_0_ srs_nmx_1_ srs_nmx_0_, i(year) j(age_group)
	tempfile data
	save `data'
	
	
	foreach var of varlist crvs_nmx_1_0 -srs_nmx_0_85 {
	sum `var'
	gen sd_`var'=`r(sd)'
	}
	
	keep sd*
	keep if _n==1
	gen n=1
	reshape long sd_crvs_nmx_1_ sd_crvs_nmx_0_ sd_srs_nmx_1_ sd_srs_nmx_0_, i(n)
	format %9.2f sd_crvs_nmx_1_ sd_crvs_nmx_0_ sd_srs_nmx_1_ sd_srs_nmx_0_	  
	
	label var _j  "Age x"
	label var sd_crvs_nmx_1_ "Female"
	label var  sd_crvs_nmx_0_ "Male"
	label var sd_srs_nmx_1_ "Female"
	label var  sd_srs_nmx_0_ "Male"


	 texsave _j sd_crvs_nmx_1_ sd_crvs_nmx_0_ sd_srs_nmx_1_ sd_srs_nmx_0_ ///
	 using "${results}\paper1\lifetable\latex\srs_crs_sd.tex", ///
	 varlabels replace nofix
	
	save "$inter\srsvscrs_nmx.dta", replace
	

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
