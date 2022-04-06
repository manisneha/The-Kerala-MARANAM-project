*Purpose : To create the final nmx graph using the data generated in 4.0.nmx_allyears

	
 use "$inter/nmx_allyears.dta", replace

 
*******************************************************************************************************************************
*generating nmx plots comparing crvs and srs for all years 
 
	
 tempfile base 
 save `base'
 
 *drop years not in analysis sample 
 drop if year < 2006
 drop if year > 2017	
 
 *make combined female male nmx graphs by year 
 
 forval x=0/1 {

	
	graph twoway ///
	(connected log_crvs age_group if female == `x', ///
		lpattern(longdash) lcolor(navy)  msymbol(Sh) mlw(medthin) msize(small)) ///
	(connected log_srs age_group if female==`x', ///
		lpattern(dash) lcolor(maroon) msymbol(Dh) mlw(medthin) msize(small) ), ///
		by(year, rows(4) ///
			graphregion(lcolor(white) fcolor(white)) ///
			note("",size(vsmall))) ///
		legend(order(1 "Civil Registration System (CRS)" 2 "Sample Registration System (SRS)") row(1)  ///
			ring(0) region(lcolor(white)) ///
			size(vsmall) symp(12) keygap(*.4) stack) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("age-specific mortality rates ({sub:n}m{sub:x}) per 1,000 (log scale)" " ", size(small)) ///
		xtitle("") ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid labsize(medsmall)) ///
		xlabel(0 20 "20 years" 40(20)80, labsize(medsmall)) ///
		subtitle(, fcolor(none) ///
			lcolor(white)) ///
			xsize(4.5) ysize(6)
		graph export "$results\paper1\combined_graph\nmx_compare_`x'.pdf", replace
		graph export "$base\Keralam\writing\genus\draft1\nmx_compare_`x'.pdf", replace

		}
 
 *make combined graphs male female for posters
 
	forval x=0/1 {

	
	graph twoway ///
	(connected log_crvs age_group if female == `x', ///
		lpattern(solid) lcolor(navy)  msymbol(Sh) mlw(medthin) msize(small)) ///
	(connected log_srs age_group if female==`x', ///
		lpattern(dash) lcolor(maroon) msymbol(Dh) mlw(medthin) msize(small) ), ///
		by(year, rows(3) ///
			graphregion(lcolor(white) fcolor(white)) ///
			note("",size(vsmall)) imargin(vsmall) noix noiy style(stata7) norescale) ///
		legend(order(1 "Civil Registration System (CRS)" 2 "Sample Registration System (SRS)") row(1)  ///
			ring(0) region(lcolor(white)) ///
			size(vsmall)) ///
		graphregion(lcolor(white) fcolor(white)) ///
		ytitle("age-specific mortality rates ({sub:n}m{sub:x}) per 1,000 (log scale)" " ", size(small)) ///
		ylabel(-1.61 "0.2" .69 "2" 3 "20" 5.3 "200", nogrid labsize(medsmall)) ///
		xtitle("") ///
		xlabel(0 20 "20 years" 40(20)80, labsize(medsmall)) ///
		subtitle(, fcolor(none) ///
			lcolor(white) ring(0) pos(12) size(medium)) ///
			xsize(5) ysize(3) 
		graph export "$results\paper1\combined_graph\nmx_compare_`x'_poster.tif", width(3000) replace

		}
