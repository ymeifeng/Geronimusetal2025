cls
clear all
capture log close


global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global output 	"[tabular output directory]"
global logfile 	  "$logs\mrg_mortchg_bartik_byrace3_cznost_res.log"
global mortfile   "$out\stdzd_deathrates_cznost_br.dta"
global bartikfile "$data\bartik_1980_2017_cz_edrace.dta"
global outfile    "$out\mortchg_bartik_byedrace_cznost_br.dta"
global  dosource "$do\7_mrg_mortchg_bartik_byrace3_cznost_br.do"
*********************************************************************************
log using "$logfile", replace
gl causelist "0 "
gl edlist "all "  /*TW added all to this list 03-20-22*/

use "$mortfile", clear
keep if inlist(year, 1990, 2017)

    rename Mx_deaths_0 Mx_deaths_0_all
    gen lnasdr_0_all_ = ln(Mx_deaths_0_all)
	gen asdr_0_all_ = (100000 * Mx_deaths_0_all)
    rename yll_0 yll_0_all_

keep lnasdr* asdr* Px* yll* year sex race czone agecat

reshape wide lnasdr* asdr* Px* yll*, j(year) i(czone race sex agecat) 

foreach var in lnasdr asdr yll {
 	gen d_`var'_0_all = `var'_0_all_2017 - `var'_0_all_1990
	}

merge m:1 czone using "$bartikfile"

sort czone
list czone if _merge == 2

describe
summarize
notes:  Created on ${S_DATE} by $dosource
save "$outfile", replace
