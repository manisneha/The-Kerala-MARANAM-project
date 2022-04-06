*graph which compres the crude death rates from the kerala register data and DHS++ populations
*and from the srs 

*************************

*bring in estimates from excel file 

	import excel ///
	"$inter\comparison_all_ages.xlsx", ///
	sheet("Sheet1") firstrow case(lower) clear 
	
*make a graph 

	graph twoway ///
	(connected crs year, lpattern(longdash) msymbol(Sh) mlw(medthin)) ///
	(connected srs year, lpattern(dash) msymbol(Dh) mlw(medthin)), ///
	graphregion(lcolor(white) fcolor(white)) ///
	legend(order(1 "CRS" 2 "SRS") row(2) ///
		ring(0) pos(2) region(lcolor(white)) bmargin(medium)) ///
	ylabel(2(2)10) ///
	xlabel(1971(5)2016) ///
	ytitle("Crude Death Rate (per 1,000)" "" "") ///
	subtitle(, margin(vsmall) ///
			fcolor(none) ///
			lcolor(white)) ///
	xtitle("") ///
	note("SRS: Sample Registration System. CRS: Civil Registration System.", pos(6) size(small) color(navy))
	graph export "$results\paper1\robustness\srs_crs_cdr_compare.pdf", replace
