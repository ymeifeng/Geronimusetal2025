clear all
cls
capture log close


global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global output 	"[tabular output directory]"
 global hist_race  "$data\historical_race"
 global hist_inc   "$data\historical_income"
 global mortbart	"$out\mortchg_bartik_byedrace_cznost_br.dta"
 global outdata 	"$out\hist_race_income_bartik_mortchg_cznost_br.dta"
 global dosource 	"$do\7b_merge_his_race_inc_bartik3_cz_nost_br.do"
********************************************************************************
use "${hist_inc}/pc_inc_8090_cznost.dta", clear
	
merge 1:1  CZ90 using "${hist_race}/county_hist_race_clean_cznost.dta", gen(merge1)
	rename CZ90 czone
		destring czone, replace

merge 1:m  czone using "$mortbart", gen(merge2)
notes: Created by $dosource on ${S_DATE}
	save "$outdata", replace


