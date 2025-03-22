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
UPDATED BY:	tim, vincent pancini
EDITED ON:  07/10/2024;2022-03-30

INPUTS:	stdzd_deathrates.dta

OUTPUTS: mortchg_bartik.dta	
*******************************************************************************/
global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global	dorn	"$data\dorn" /*data downloaded from https://www.ddorn.net/data.htm*/
global mortfile   "$out\stdzd_deathrates_cznost_res.dta"
global bartikfile "$data\bartik_1980_2017_cz_edrace.dta"
global outfile    "$out\mortchg_bartik_byedrace_cznost_res.dta"
global  dosource "$do\7_mrg_mortchg_bartik_byrace3_cznost_res.do"
*********************************************************************************
log using "$logfile", replace
gl causelist "0 1 2 3 4 5 5a 5b 5c 5d 6 6a 6b 7 8 9 10 11 11a 11b 12 13 13a 13b 14 15 16 16a 16b 16c 16d 17 18 19 20 21 22 23 24 25 26 27"
gl edlist "all ghs lehs coll ltcol hi75 lo25"  /*TW added all to this list 03-20-22*/

use "$mortfile", clear
keep if inlist(year, 1990, 2017)

foreach cod of global causelist {
    rename Mx_deaths_`cod' Mx_deaths_`cod'_all
	foreach ed of global edlist {
	    gen lnasdr_`cod'_`ed'_ = ln(Mx_deaths_`cod'_`ed')
		gen asdr_`cod'_`ed'_ = (100000 * Mx_deaths_`cod'_`ed')
	}
}

foreach yll of varlist yll_? yll_?? yll_??? {
    rename `yll' `yll'_all
}

foreach yll of varlist yll_?_all yll_??_all yll_???_all {
    rename `yll' `yll'_
}

keep lnasdr* asdr* Px* yll* year sex race cza agecat

reshape wide lnasdr* asdr* Px* yll*, j(year) i(cza race sex agecat) 

foreach var in lnasdr asdr yll {
    foreach cod of global causelist {
	    foreach ed of global edlist {
		    gen d_`var'_`cod'_`ed' = `var'_`cod'_`ed'_2017 - `var'_`cod'_`ed'_1990
		}
	}
}

rename cza czone
destring czone, replace

merge m:1 czone using "$bartikfile"

sort czone
list czone if _merge == 2

describe
summarize
notes:  Created on ${S_DATE} by $dosource
save "$outfile", replace
