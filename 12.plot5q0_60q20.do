**create the dataset necessary to plot the graph comparing 5q0 to 20q60 and 5q0 to 45q15

*******************************************************************************************************************************
*HMD data
*Data source: Life tables from the HMD website were downloaded thorugh R and the necessary years combined

   foreach var in m f {

	import delimited ///
	"$raw\hmd_`var'.csv", clear
	drop v1
	save "$raw\hmd_`var'.dta",replace
	
	*Calculating 5q0=5d0/l0
	
	*5d0
	use "$raw\hmd_`var'.dta", clear 
	*replace dx="" if dx=="NA"
	*destring dx,replace
	keep if age>=0 & age<5	
    collapse (sum) dx , by(country year)
		
	tempfile deaths_`var'	
	save `deaths_`var''
	
	*l0 (you dont need to calculate it since l0 is constant but doing it to be extra sure
	use "$raw\hmd_`var'.dta", clear 	
	keep if age==0	
	keep country year lx	
	merge 1:1 country year using "`deaths_`var''",nogen
	
	*generating 5q0=5d0/l0
	
	gen q5_0= dx/lx
	
    tempfile final_`var'
	save `final_`var''
	
	
	
	*Calculating 20q60=20d60/l60

	use "$raw\hmd_`var'.dta", clear 
	*replace dx="" if dx=="NA"
	*destring dx,replace	
	keep if age>=60 & age<80	
    collapse (sum) dx , by(country year)
	
	tempfile deaths6080_`var'	
	save `deaths6080_`var''
	
	use "$raw\hmd_`var'.dta", clear 	
	keep if age==60	
	keep country year lx	
	merge 1:1 country year using "`deaths6080_`var''",nogen
	
	*generating 20q60=20d60/l20
	
	**destring lx,replace
	gen q20_60= dx/lx
	
	merge 1:1 country year using "`final_`var''", nogen	
	save "$inter\hmd_`var'_calc.dta",replace
	
	
	*Calculating 45q15=45d615/l15

	use "$raw\hmd_`var'.dta", clear 
	*replace dx="" if dx=="NA"
	*destring dx,replace	
	keep if age>=15 & age<60	
    collapse (sum) dx , by(country year)
	
	tempfile deaths6080_`var'	
	save `deaths6080_`var''
	
	use "$raw\hmd_`var'.dta", clear 	
	keep if age==15
	keep country year lx	
	merge 1:1 country year using "`deaths6080_`var''",nogen
	

	gen q45_15= dx/lx
	
	merge 1:1 country year using "$inter\hmd_`var'_calc.dta", nogen	
	save "$inter\hmd_`var'_calc.dta",replace
	
	
	}
***Repeating the calculations for the Kerala register data
	
	
	use "$results\paper1\lifetable\dataset\lifetable_2006to2017.dta", clear
	gen dx= (lx - (lx[_n+1]))
	keep if age>=0 & age<5	
    collapse (sum) dx , by( year female)
		
	gen q5_0= dx /* since lx=1 for l0*/
	
    tempfile final_crs
	save `final_crs', replace
	
	
	
	*Calculating 20q60=20d60/l60 for kerala

	use "$results\paper1\lifetable\dataset\lifetable_2006to2017.dta", clear
	gen dx= (lx - (lx[_n+1]))
	keep if age>=60 & age<80	
    collapse (sum) dx , by(year female)	
	tempfile deaths6080_crs	
	save `deaths6080_crs'	
	
	use "$results\paper1\lifetable\dataset\lifetable_2006to2017.dta", clear
	keep if age==60	
	keep  year lx female	
	merge 1:1  year female using "`deaths6080_crs'",nogen	
	gen q20_60= dx/(lx)	
	
	tempfile q20_60
	save "`q20_60'"

	
	*Calculating 45q15=45d15/l15 for kerala
	
	use "$results\paper1\lifetable\dataset\lifetable_2006to2017.dta", clear

	gen dx= (lx - (lx[_n+1]))
	keep if age>=15 & age<60	
    collapse (sum) dx , by(year female)	
	tempfile deaths1560_crs
	save `deaths1560_crs'
	
	*Calculating 45q15=45d15/l15 for kerala

	
	use "$results\paper1\lifetable\dataset\lifetable_2006to2017.dta", clear
	keep if age==15	
	keep  year lx female
	merge 1:1 year female using "`deaths1560_crs'"	
	gen q45_15=dx/lx
	tempfile q45_15
	save "`q45_15'"
	
   *Mergin all the tempfiles together
	use "`q20_60'", clear
	merge 1:1  year female using "`final_crs'", nogen
	gen country=99
	merge 1:1 year female using "`q45_15'",nogen
	save "$inter\kerala_qmod_calc.dta",replace
	
	
	*Bringing all the datasets together 

	use "$inter\hmd_f_calc.dta", clear
	gen female=1 
	merge 1:1 year female country using "$inter\kerala_qmod_calc.dta",nogen
	append using "$inter\hmd_m_calc.dta"
	replace female=0 if female==. & country!=99
    keep year q20_60 q5_0 q45_15 country female
	label define f 0"Male" 1"Female"
	label value female f
	save "$inter\nqx_0to5_60to80_15to45.dta", replace

	
	
	*plotting the results - old age mortality
	
	use "$inter\nqx_0to5_60to80_15to45.dta", clear
	
	graph twoway ///
	scatter q20_60 q5_0 if country!=99,   ///
	msize(.9) msymbol(Oh) mlw(vthin) mcolor(navy*.75) || ///
	scatter q20_60 q5_0 if country==99,  xscale(titlegap(5)) ///
	mlabposition(6) msize(.9) msymbol(Sh) mlw(*.9) by(female, rows(1) ///
		graphregion(lcolor(white) fcolor(white)) 	///
		note("{sub:n}q{sub:x} estimated using CRVS data for Kerala and Human Mortality Database (HMD) for HMD populations.", pos(6) size(vsmall) color(navy)))   ///
		legend(order(2 "Kerala (2006-2017)" 1 "HMD countries (1971-2017)") row(1)  ///
			ring(0) region(lcolor(white)) ///
			size(small)) ///
		ytitle("Old age mortality ({sub:20}q{sub:60})" "",size(small)) ///
		xtitle("Child mortality ({sub:5}q{sub:0})" "",size(small)) ///
		ylabel(.2 .4 .8, nogrid labsize(small)) legend(off) ///
		xlabel(.00125 .01 .08, labsize(small))  ///
		subtitle(, fcolor(none) ///
			lcolor(white)) ///
		xscale(log r(0.001 .08)) ///
		yscale(log)
	graph save "$results\paper1\individual_graph\nqx_0to5_60to80.gph", replace
	graph export "$results\paper1\individual_graph\nqx_0to5_60to80.tif", width(6000) replace
	graph export "$results\paper1\individual_graph\nqx_0to5_60to80.pdf", replace
   graph export "$base\Keralam\writing\genus\draft1\nqx_0to5_60to80.pdf", replace
	
	
	
	
	
	*plotting the results - 45q15

	
	use "$inter\nqx_0to5_60to80_15to45.dta", clear
	
	graph twoway ///
	scatter q45_15 q5_0 if country!=99,   ///
	msize(.9) msymbol(Oh) mlw(vthin) mcolor(navy*.75) || ///
	scatter q45_15 q5_0 if country==99,  xscale(titlegap(5)) ///
	mlabposition(6) msize(.9) msymbol(Sh) mlw(*.9) by(female, rows(1) ///
		graphregion(lcolor(white) fcolor(white)) 	///
		note("{sub:n}q{sub:x} estimated using CRVS data for Kerala and Human Mortality Database (HMD) for HMD populations.", pos(6) size(vsmall) color(navy)))   ///
		legend(order(2 "Kerala (2006-2017)" 1 "HMD countries (1971-2017)") row(1)  ///
			ring(0) region(lcolor(white)) ///
			size(small)) ///
		ytitle("Adult Mortality ({sub:45}q{sub:15})" "",size(small)) ///
		xtitle("Child mortality ({sub:5}q{sub:0})" "",size(small)) ///
		ylabel(.05 .1 .2 .4 .8, nogrid labsize(small)) legend(off) ///
		xlabel(.00125 .01 .08, labsize(small))  ///
		subtitle(, fcolor(none) ///
			lcolor(white)) ///
		xscale(log r(0.001 .08)) ///
		yscale(log)
	graph save "$results\paper1\individual_graph\nqx_0to5_15to60.gph", replace
	graph export "$results\paper1\individual_graph\nqx_0to5_15to60.tif", width(6000) replace
	graph export "$results\paper1\individual_graph\nqx_0to5_15to60.pdf", replace
   graph export "$base\Keralam\writing\genus\draft1\nqx_0to5_15to60.pdf", replace
	
	
	
	
	
	
	
	