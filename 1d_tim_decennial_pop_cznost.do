clear all
cls
capture log close
/*******************************************************************************
PROJECT:		NIH Weathering Project - Create denominator for rank version  
                by using ACS data
				
CREATED BY:		Justin Morgan
UPDATED ON:		3/8/21
UPDATED BY:     Luis Basurto
UPDATED BY:	    Tim Waidmann

INPUTS:			pop_edrank_wide_90_00.dta
THIS VERSION ONLY KEEPS 1990 DATA
*******************************************************************************/
global	data	"[your main data directory]"
gl do 		"[your code directory]"
global	acs	"$data\acs"
global  logs    "[your log file directory]"
gl geoxwalk 	"[your crosswalk directory]"
global	dorn	"$data\dorn" /*data downloaded from https://www.ddorn.net/data.htm*/
global	clean	"$data\clean"
global  pop     "$data\pop"
gl  dosource 	"$do\1d_decennial_pop_cznost.do"
********************************************************************************

use $pop\decennial_1990_2000_wide.dta, clear

tostring statefip, gen(statefips) format("%02.0f")
drop statefip
  	

********************************************************************************
*Add commuting zone information, collapse, and finalize
********************************************************************************
*Join/merge with dorn data (FYI: very much on purpose used joinby and not merge)
rename year multiyear
joinby multiyear statefips puma using $geoxwalk/cz_puma.dta, unmatched(both) _merge(czmerge)
drop if inlist(statefips,"13","22","36","40","44","46","53")
drop if multiyear>2000
keep if multiyear==1990
rename multiyear year
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


*Save final LEVELS population file
compress
append using $pop\poped_wide_acs.dta
*collapse by czone but not state
collapse (sum) pop* obs*, by(year cza czone sex race age_lt)

notes : Created on ${S_DATE} by $dosource 
save $pop\poped_wide_cznost, replace
