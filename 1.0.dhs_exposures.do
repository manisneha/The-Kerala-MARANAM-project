/*Purpose: Coverting DHS exposures excel into a stata data format that can be merged with register data for Kerala
*The DHS exposures are used to calculate the population by age-group and year. 
*The source of the excel files: Please add hyperlink

Authors:
**Created by Aashish Gupta
**Updated by Sneha Mani

 */



****************************************************************************************************************************************
	
**Code

	
*bring in dhs exposures at the district year level 

	import excel ///
	"$raw\kerala_dhs_exposures_estimates.xlsx", ///
	sheet("Sheet1") firstrow case(lower) clear 
	
	
******************************************Data cleaning***********************************************************


*keep necessary variables 

	gen place = ""
	replace place = "kerala" if adm1_name == "KERALA"
	**do it for other the other districts as well
	
	*clean district names
    	
	gen district =""
	replace district="alappuzha" if adm2_name=="ALAPPUZHA"
	replace district="ernakulam" if adm2_name=="ERNĀKULAM"
	replace district="idukki"  if adm2_name=="IDUKKI"
	replace district="kannur" if adm2_name=="KANNUR"
	replace district="kasaragod" if adm2_name=="KASARAGOD"
	replace district="kollam" if adm2_name=="KOLLAM"
	replace district="kottayam" if adm2_name=="KOTTAYAM"
	replace district="kozhikode" if adm2_name=="KOZHIKODE"
	replace district="malappuram" if adm2_name=="MALAPPURAM"
	replace district="palakkad" if adm2_name=="PĀLGHĀT"
	replace district="pathanamthitta" if adm2_name=="PATHANAMTHITTA"
	replace district="thiruvananthapuram" if adm2_name=="TRIVANDRUM"
 	replace district="thrissur" if adm2_name=="TRICHŪR"
	replace district="wayanad" if adm2_name=="WAYANAD"
	replace district ="all districts" if adm2_name==""

	*drop some variables 
	drop area_name geo_match geo_label country adm3_name adm_level ///
	nso_code comment genc fips 
	
	*don't need overall population 
	drop b*
*******************************************************************************************************************************	
*This block of code reshapes the base KERALAM data to convert data into a more readable format. It creates year, age group, and sex variables. 

	*create a year variable 
	
		*reshape
		reshape long ///
		mtotl_ m0004_ m0509_ m1014_ m1519_ m2024_ m2529_ m3034_ m3539_ m4044_ ///
		m4549_ m5054_ m5559_ m6064_ m6569_ m7074_ m7579_ m80pl_ ///
		ftotl_ f0004_ f0509_ f1014_ f1519_ f2024_ f2529_ f3034_ f3539_ f4044_ ///
		f4549_ f5054_ f5559_ f6064_ f6569_ f7074_ f7579_ f80pl_ , ///
		i(adm1_name adm2_name) j(year) 
		
		tab year
		*the reshape works
	
	*create an age-group variable 
	
		*remove underscores
		foreach s in m f {
		
		foreach var in `s'totl `s'0004 `s'0509 `s'1014 `s'1519 `s'2024 `s'2529 ///
		`s'3034 `s'3539 `s'4044 ///
		`s'4549 `s'5054 `s'5559 `s'6064 `s'6569 `s'7074 `s'7579 `s'80pl {
		
		rename `var'_ `var'
		
		} 
		}
		
		*add underscores before age-group 
		rename m* m_*
		rename f* f_*
		
		*reshape
		reshape long m_ f_, i(adm1_name adm2_name year) j(age_group) string
		rename m_ female_0
		rename f_ female_1
		
		
	*create a female variable 
	
		reshape long female_, i(adm1_name adm2_name year age_group place) j(female)
		
		rename female_ population 
		

********************************************************************************************************************
*This section of the code focuses on cleaning the age group variables. The age groups variable are created to follow the standard life table format.
	*fixing age groups
		
			rename age_group age_group_old
			gen age_group=.
			**Need to create pop counts for ages 0-1 and 1-4
			replace age_group=5  if age_group_old=="0509"
			replace age_group=10 if age_group_old=="1014"
			replace age_group=15 if age_group_old=="1519"
			replace age_group=20 if age_group_old=="2024"
			replace age_group=25 if age_group_old=="2529"
			replace age_group=30 if age_group_old=="3034"
			replace age_group=35 if age_group_old=="3539"
			replace age_group=40 if age_group_old=="4044"
			replace age_group=45 if age_group_old=="4549"
			replace age_group=50 if age_group_old=="5054"
			replace age_group=55 if age_group_old=="5559"
			replace age_group=60 if age_group_old=="6064"
			replace age_group=65 if age_group_old=="6569"
			replace age_group=70 if age_group_old=="7074"
			replace age_group=75 if age_group_old=="7579"
			replace age_group=80 if age_group_old=="80pl"
			
	
	        expand 2 if age_group_old=="0004" /*in a life table the age categories are defined as 0-1 and 1-4, so we need to create a place marker for this*/
	        expand 2 if age_group_old=="80pl" /*in a life table the age categories are defined as 80-84 and 85+, so we need to create a place marker for this*/
			
			bysort year age_group_old district female : gen n=_n
			
/**n identifies the new rows creating by the expand variable. when n=1 it identifies the first observation
uniquely identified by age_group_old district female. n=2 is the duplicate row created. for example, for year
2017, we have 480 observations when n=1 which contains all age groups. n=2 is 30 observations
and for the new rows created*/
		
			
			replace age_group=0 if n==1 & age_group_old=="0004" /*creating the additional age categories*/
			replace age_group=1 if n==2 & age_group_old=="0004" /*creating the additional age categories*/
			
			replace age_group=80 if n==1 & age_group_old=="80pl" /*creating the additional age categories*/
			replace age_group=85 if n==2 & age_group_old=="80pl" /*creating the additional age categories*/

			
			gen population_old=population
			replace population=. if age_group_old=="0004" | age_group_old=="80pl"/*We need to updated the population numbers for the age groups 0-1 and 1-4*/
		    
			drop n
		
	sort year district age_group female population	place

	order year district age_group female population	place
	
	*creating the length of the age group interval. It is 5 years for all age groups except 0-1,1-4 and 85+. 
	
	gen n=5 if age_group!=0 & age_group!=85 & age_group!=1
	replace n=1 if age_group==0
	replace n=4 if age_group==1
	
		
save "$inter\dhs_exposures.dta", replace


