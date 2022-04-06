*do file to run all the do-file in sequence for this folder
**Either Sneha or Aashish made edits
*created sneha 15 aug 2020

*****/ 
*Sneha's base files ( need this till Sneha can set up the config base file)
global base "C:\Users\sneha\Dropbox\Keralam\data\stata\2.programs\6.submission_code"
*Aashish's base files ( need this till Sneha can set up the config base file)
*global base "C:\Users\aashi\Dropbox\Keralam\data\stata\2.programs\6.submission_code"


**Run the do-files in succession
do "$base\1.0.dhs_exposures.do"
do "$base\2.0.descriptives.do" 
do "$base\3.0.nax_srs.do" 
do "$base\4.0.nmx_allyears.do" 
do "$base\4.0.nmx_allyears_srs_3year averages.do"
do "$base\4.0.nmx_allyears_srs_5year averages.do"
do "$base\4.1.nmx_finalgraphs.do" 
do "$base\4.2.1.nmx_2016_census.do" 
do "$base\4.2.2.nmx_2011_census.do" 
do "$base\4.2.2.nmx_2011_census.do" 
do "$base\4.2.nmx_CRSvsSRS"
do "$base\6.0.estimate_life_tables_allyears.do" 
do "$base\6.1.2.lifetable_additionalcalculationsandgraphs" 
do "$base\6.2.1.lifetable_2016censusproj.do" 
do "$base\6.2.2.lifetable_2011census.do" 
do "$base\6.2.2.lifetable_2011census_gompertz.do" 
do "$base\6.2.3.gompertz_allyears.do" 
do "$base\8.nfhs_nmx_child.do" 
do "$base\9.nfhs_srs_crs_0_1_comparison.do" 
do "$base\10.srs_crs_all_ages_CDRcomparison.do" 
do "$base\11.1.migration_crvsdata.do" 
do "$base\12.plot5q0_60q20.do" 
