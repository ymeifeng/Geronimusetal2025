cls
clear all
capture log close
/*******************************************************************************
PURPOSE: Creates dataset of changes in various mortality outcomes (in this case, 
         standardized death rates: all cause, opioids, other despair, total 
		 despair, cancer, cardiovascular, other internal, other external). 
		 Variables are of the form of arithmetic and logarithmic changes 
		 (e.g., dndx_opi_9014 and dlndx_opi_9014, respectively).
			
CREATED BY:	Tim Waidmann
UPDATED BY:	vincent pancini
EDITED ON:  2022-03-30

INPUTS:	stdzd_deathrates.dta

OUTPUTS: mortchg_bartik.dta	
*******************************************************************************/
 global logs       "[log file directory]"
 global do	   "[do file directory]"
 global data	   "[central data directory]"
 global out	   "[analtyic file directory]"
global logfile 	  "$logs\all_ed_version\7_mrg_mortchg_bartik_plus_alled_res.log"
global mortfile   "$out\stdzd_deathrates_nostcz_alled_res.dta"
global bartikfile "$data\bartik_1980_2017_cz_edrace.dta"
global outfile    "$out\mortchg_bartik_byrace_nostcz_alled_res.dta"
********************************************************************************
* log using "$logfile", replace
gl causelist "0 1 2 3 4 5 5a 5b 5c 5d 6 6a 6b 7 8 9 10 11 11a 11b 12 13 13a 13b 14 15 16 16a 16b 16c 16d 17 18 19 20 21 22 23 24 25 26 27"

use "$mortfile", clear
keep if inlist(year, 1990, 2017)

foreach cod of global causelist {
	gen lnasdr_`cod'_ = ln(Mx_deaths_`cod')
	gen asdr_`cod'_ = (100000 * Mx_deaths_`cod')
}

    rename yll_tot yll_tot_


keep lnasdr* asdr* Px* yll* year sex  race cza noedst agecat

reshape wide lnasdr* asdr* Px* yll*, i( cza noedst race sex agecat) j(year)

foreach var in lnasdr asdr {
    foreach cod of global causelist {
		    gen d_`var'_`cod' = `var'_`cod'_2017 - `var'_`cod'_1990
	}
}
gen d_yll_0=yll_tot_2017-yll_tot_1990

rename cza czone
destring czone, replace

merge m:1 czone using "$bartikfile"

sort czone
list czone if _merge == 2

describe
summarize
save "$outfile", replace
