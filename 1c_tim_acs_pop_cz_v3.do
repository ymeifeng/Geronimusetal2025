clear all
cls
capture log close
/*******************************************************************************
PROJECT:		NIH Weathering Project - Create denominator for levels version  
                by using ACS data
				
CREATED BY:		Justin Morgan
UPDATED ON:		3/8/21
UPDATED BY:     Luis Basurto
UPDATED BY:	    Tim Waidmann
	THIS VERSION ONLY READS IN 2017 ACS DATA
INPUTS:			
*******************************************************************************/
global	data	"[your central data directory]"
gl do 		"[your code directory]"
global	acs	"$data\acs"
global  logs    "[your log file directory]"
gl geoxwalk 	"[your crosswalk directory]"
global	dorn	"$data\dorn" /*data downloaded from https://www.ddorn.net/data.htm*/
global  pop     "$data\pop"
gl  dosource 	"$do\1c_tim_acs_pop_cz_v3.do"
********************************************************************************

use $pop\acs5yr_2017_wide.dta, clear

tostring statefip, gen(statefips) format("%02.0f")
drop statefip
  	

********************************************************************************
*Add commuting zone information, collapse, and finalize
********************************************************************************
*Join/merge with dorn data (FYI: very much on purpose used joinby and not merge)
joinby multiyear statefips puma using $geoxwalk/cz_puma.dta, unmatched(both) _merge(czmerge)
drop if inlist(statefips,"13","22","36","40","44","46","53")
keep if inrange(multiyear,2015,2019)

tab czmerge

assert czmerge==3


*Simply multiplying all these vars by allocation factors given that one puma  
*might map to several commuting zones
foreach var of varlist pop* obs* {
	replace `var' = `var' * afactor
}

*Last collapse, but this time by state/cz combinations instead of state/puma 
collapse (sum) pop* obs*, by(year statefips czone sex race age_lt)

*Get rid of duplicates, surplus should be zero
duplicates tag year sex race age_lt statefips czone , gen(twofiles)
duplicates report year sex race age_lt statefips czone

*Last styling lines
tostring czone, gen(cza) format("%05.0f")
order year statefips cza race sex age_lt pop* obs* czone
sort year statefips cza race sex age_lt


*Save final population file
compress
notes : Created on ${S_DATE} by $dosource 
save $pop\poped_wide_acs.dta, replace
