clear all
cls
capture log close
/*******************************************************************************
			
CREATED BY:	vincent pancini
UPDATED ON: 2022-04-07 
			2022-04-13 vincent ran on personal machine bc Urban-Users is being weird
*******************************************************************************/
 global logs       "[log file directory]"
 global do	   "[do file directory]"
 global data	   "[central data directory]"
 global out	   "[analtyic file directory]"
 global hist_race  "$data\historical_race"
 global hist_inc   "$data\historical_income"
 
 global mortbart   "$out\mortchg_bartik_byrace_nostcz_alled_res.dta"
 global outdata    "$out\hist_race_income_bartik_mortchg_nostcz_alled_res.dta"
 global dosource   "$do\7b_merge_his_race_inc_bartik3_nostcz_alled_res.do"
********************************************************************************
use "${hist_inc}/pc_inc_8090_cznost.dta", clear
	*rename statea state_fips
	
merge 1:1  CZ90 using "${hist_race}/county_hist_race_clean_cznost.dta", gen(merge1)
	rename CZ90 czone
		destring czone, replace
	*rename state_fips statefips

merge 1:m  czone using "$mortbart", gen(merge2)
notes: Created by $dosource on ${S_DATE}
	save "$outdata", replace


