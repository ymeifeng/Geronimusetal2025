clear all
cls
capture log close
/*******************************************************************************
PROJECT:	

when you've got that file, can you merge (by state and CZ) it with 

then merge that combination with the analysis file for 8.

We want to add a couple of variables to the bartik regressions in 8, controlling for (1) baseline income per capita in the CZ and (2) black migration
We have a couple of options for each of these.
For inc/capita, we can use the value for white and black residents combined or race-specific values. Let's start with race-specific versions
For migration, we can either use log change in black population or log change in black share. (1920-1970 in both cases) I lean toward the share version.

We're still interested in the same output (i.e, bartik coefficients and mean predicted values in high and low bartik areas), so no need to make wholesale changes to the program.
			
CREATED BY:	vincent pancini
UPDATED ON: 2022-04-07 
			2022-04-13 vincent ran on personal machine bc Urban-Users is being weird

INPUTS:		county_hist_race_clean.dta, czlma903.xls

OUTPUTS:    
*******************************************************************************/
global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global	dorn	"$data\dorn" /*data downloaded from https://www.ddorn.net/data.htm*/
global hist_race  "$data\historical_race"
global hist_inc   "$data\historical_income"
global mortbart	"$out\mortchg_bartik_byedrace_cznost_res.dta"
global outdata 	"$out\hist_race_income_bartik_mortchg_cznost_res.dta"
global dosource "$do\7b_merge_his_race_inc_bartik3_cznost_res.do"
********************************************************************************
use "${hist_inc}/pc_inc_8090_cznost.dta", clear
	
merge 1:1  CZ90 using "${hist_race}/county_hist_race_clean_cznost.dta", gen(merge1)
	rename CZ90 czone
		destring czone, replace

merge 1:m  czone using "$mortbart", gen(merge2)
notes: Created by $dosource on ${S_DATE}
	save "$outdata", replace


