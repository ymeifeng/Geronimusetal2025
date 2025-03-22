clear all
cls
capture log close
/*******************************************************************************
PROJECT:	Create denominator for all ed version by using ACS data
				
CREATED BY:	Vincent Pancini 
UPDATED ON: 2023-07-12	

INPUTS:		decennial_1990_2000_wide_alled.dta
OUTPUTS:    
*******************************************************************************/
 global logs       "[log file directory]"
 global do	   "[do file directory]"
 global data	   "[central data directory]"
 global out	   "[analtyic file directory]"
 global geoxwalks  "[geographic crosswalk directory]"
********************************************************************************
use $out\acs5yr_2008_2017_wide_alled.dta, clear

tostring statefip, gen(statefips) format("%02.0f")
drop statefip
  	

********************************************************************************
*Add commuting zone information, collapse, and finalize
********************************************************************************
*Join/merge with dorn data (FYI: very much on purpose used joinby and not merge)
joinby multiyear statefips puma using $data\pop/cz_puma.dta, unmatched(both) _merge(czmerge)
keep if inrange(multiyear, 2006, 2020)

drop if statefips=="33" 
tab czmerge
gen byte noedst=inlist(statefips,"13", "22", "36", "40", "44", "46", "53")

*assert czmerge==3


*Simply multiplying all these vars by allocation factors given that one puma  
*might map to several commuting zones
foreach var of varlist pop_tot obs_tot {
	replace `var' = `var' * afactor
}

*Last collapse, but this time by state/cz combinations instead of state/puma 
collapse (sum) pop_tot obs_tot, by(year  czone  noedst sex race age_lt)

*Get rid of duplicates, surplus should be zero
duplicates tag year sex race age_lt  czone noedst, gen(twofiles)
duplicates report year sex race age_lt  czone noedst

*Last styling lines
tostring czone, gen(cza) format("%05.0f")
order year  cza noedst race sex age_lt pop_tot obs_tot czone
sort year  cza noedst race sex age_lt


*Save final population file
compress
save $out\poped_wide_acs_nostcz_alled.dta, replace
