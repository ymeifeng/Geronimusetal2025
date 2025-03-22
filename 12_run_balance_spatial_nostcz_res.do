cls
clear all
putexcel clear
capture log close
global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global  output	"[tabular output file directory]"
global 	data	"[data directory]"

/*******************************************************************************
PURPOSE: Runs core models of mortality on bartik measures
         separately by sex,race, for several age brackets
		 BUT mortality change is 1960-1980, and BARTIK measure is 1980-2017
			
CREATED BY:	Tim Waidmann
CREATED ON: 03/24/2022

INPUTS:	mortchg_bartik_6080.dta

OUTPUTS: placebo_$S_DATE.xlsx

 Note: There are two options for bartik instruments. One (bartik_tot`btype') uses
 the same 1980 local industrial shares for all groups. The other (bartik_tot`btype'_`edgrp')
 uses education-specific shares. Both use aggregate changes in shares, undifferentiated
 by education group. Only use one of the two regress commands and one of the log file
 names ($outputxl). (comment out the other)

Cause codes
tot  All-cause
can  Cancer
cvd  Cardiovascular disease

regress D_Mstd_tot bartik_totemp_all if agrp==2564 & sex==1 & race==1 [aw=pop_1960]
regress D_Mstd_can bartik_totemp_all if agrp==2564 & sex==1 & race==1 [aw=pop_1960]
regress D_Mstd_cvd bartik_totemp_all if agrp==2564 & sex==1 & race==1 [aw=pop_1960]
regress D_Mstd_tot  if agrp==2564 & sex==1 & race==1 [aw=pop_1960]
regress D_Mstd_cvd  if agrp==2564 & sex==1 & race==1 [aw=pop_1960]
regress D_Mstd_can  if agrp==2564 & sex==1 & race==1 [aw=pop_1960]
*******************************************************************************/

global analysisfile "$out\mortchg_bartik_6080_cznost_res.dta"
global outputxl 	"$output\spatial\placebo\balance80_res_$S_DATE.xlsx"
global logfile		"$logs\balance80_res_$S_DATE.log"

do "$do\ols_spatial_HAC.ado"
do "$do\reg2hdfespatial.ado"

/**/
* log using "$logfile", replace

gl wtvar "pop_1990"




********************************************************************************

capture program drop allmods
program define allmods
local age_group `1'
local race_group `2'

	if "`race_group'" == "White" {
		local rg nhw
		local rnum = 1
		global spec_1 "pc_inc_nhw_1980 pctcol_`age_group'"
		global spec_2 "pc_inc_nhw_1980 pcthi75_`age_group'"
		global spec_3 "pc_inc_nhw_1980"
		global spec_4 ""
	}
	else {
		local rg nhb
		local rnum = 2
		global spec_1 "pc_inc_nhb_1980  pctcol_`age_group'"
		global spec_2 "pc_inc_nhb_1980 pcthi75_`age_group'"
		global spec_3 "pc_inc_nhb_1980"
		global spec_4 ""
	}
	if "`age_group'"=="2584" {
		global causelist "tot"
		global mortvar "yll"
	}
	else {
		global causelist "tot"
		global mortvar "Mx"
	}
***********************************************************************************
* EXPECTED ECONOMIC GROWTH EFFECTS (bartik) ON MALE (i=1) and FEMALE (i=0), 
***********************************************************************************
	forval i = 0/1 {
		di "Started Bartik male = `i' / race = `race_group' / age = `age_group'"
		foreach cod in $causelist {
		forval j = 1/4 {
				reg2hdfespatial ${mortvar}_`cod'_1980 bartik_totemp_r_`rg' ${spec_`j'} [aw=$wtvar] ///
				if male == `i' & agecat == `age_group' & race == `rnum', ///
				lat(_CY) lon(_CX) timevar(year) panelvar(panel) distcutoff(100)
				
				matrix b = get(_b) 
				matrix v = vecdiag(cholesky(get(VCE)))
				local dfr = e(df_r)
				local dfm = e(df_m)
				scalar Fstat=(e(mss)/e(df_m))/(e(rss)/e(df_r))
				if `j' == 1 {
					matrix b1 = b[1,1..3], Fstat \ v[1,1..3], .
					matrix colnames b1 = bartik pc_inc pct_coll F(`dfm',`dfr')
					matrix rownames b1 = b_`cod' se_`cod'
				}
				
				else if `j' == 2 {
					matrix b2 = b[1,1..3], Fstat \ v[1,1..3], .
					matrix colnames b2 = bartik pc_inc pct_hi75 F(`dfm',`dfr')
					matrix rownames b2 = b_`cod' se_`cod'
				}
				else if `j' == 3 {
					matrix b3 = b[1,1..2], Fstat \ v[1,1..2], .
					matrix colnames b3 = bartik pc_inc F(`dfm',`dfr')
					matrix rownames b3 = b_`cod' se_`cod'
				}
				else if `j' == 4 {
					matrix b4 = b[1,1..1], Fstat \ v[1,1..1], .
					matrix colnames b4 = bartik F(`dfm',`dfr')
					matrix rownames b4 = b_`cod' se_`cod'
				}
			}
			
			matrix b_`cod'_emp = b1, b2, b3, b4
			matrix b_`cod' = b_`cod'_emp
				
	
			if "`cod'" == "tot" {
				matrix b_allc = b_`cod'
			}
			else {
				matrix b_allc = b_allc \ b_`cod'
			}
		}
	
		if `i' == 1 {
			matrix bBARTIK_male_`race_group' = b_allc
		}
		else if `i' == 0 {
			matrix bBARTIK_female_`race_group' = b_allc
		}
	
	}
	
di "Finished Bartik male = `i' / race = `race_group' / age = `age_group'"


*output to excel file	
putexcel set "${outputxl}", modify sheet("`race_group'_`age_group'" replace)

putexcel A2  = "Cause of Death" ///
		 A5  = "All Causes" , bold

	 
putexcel A12  = "Cause of Death" ///
		 A15  = "All Causes" , bold
		 
putexcel (A1:A20),    left
putexcel (A1:n1),     border(bottom,double)
putexcel (A10:n10),   border(bottom,double)
putexcel (A3:n3),     border(bottom,thin)
putexcel b1    =       "balance 1980",  bold
putexcel (B2:n2) =       "MALE", hcenter merge bold italic
putexcel (B3:e3)	=	"[Spec 1]" , hcenter merge italic
putexcel (f3:i3)	=	"[Spec 2]" , hcenter merge italic
putexcel (j3:l3)	=	"[Spec 3]" , hcenter merge italic
putexcel (m3:n3)	=	"[Spec 4]" , hcenter merge italic
putexcel b4 =          matrix(bBARTIK_male_`race_group'), colnames nformat(#.00) right
putexcel (A13:n13),   border(bottom,thin)
putexcel (B12:n12) =     "FEMALE", hcenter merge bold italic
putexcel (B13:e13)	=	"[Spec 1]" , hcenter merge italic
putexcel (f13:i13)	=	"[Spec 2]" , hcenter merge italic
putexcel (j13:l13)	=	"[Spec 3]" , hcenter merge italic
putexcel (m13:n13)	=	"[Spec 4]" , hcenter merge italic
putexcel b14 =         matrix(bBARTIK_female_`race_group'), colnames nformat(#.00) right
putexcel (A20:n20), border(bottom, double)
putexcel save

end 

use "$analysisfile" , clear
gen byte male = (sex == 1)
replace pc_inc_nhw_1980=pc_inc_nhw_1980/1000
replace pc_inc_nhb_1980=pc_inc_nhb_1980/1000

foreach var of varlist bartik_totemp*{
	replace `var'=`var'*10
	}
cap drop _merge
merge m:1 czone sex race using "$data/ed_in_1980_cz"
tab _merge
capture drop _merge

tempfile core
save `core'


use "$data\cz1990.dta", clear
	merge 1:m czone using `core', gen(merge_spatial)
	gen byte panel = 1
	gen int year = 1990
	gen byte const = 1
	keep if merge_spatial==3

merge m:1 czone sex race using "$data\fullsample"
keep if _merge==3
drop _merge	
foreach race_group in White Black {
	foreach age_group in 2584   4564  {
		di "race group `race_group' ; age group `age_group'"
		allmods `age_group' `race_group'
	}
}
