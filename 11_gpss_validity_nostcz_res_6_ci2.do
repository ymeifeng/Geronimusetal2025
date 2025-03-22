capture log close
clear all
global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global  output	"[tabular output directory]"
global	dorn	"$data\dorn" /*data downloaded from https://www.ddorn.net/data.htm*/

gl dosource "$do\11_gpss_validity_nostcz_res.do"


use "$out\cens_inc_1980_2017", replace
gen pc_inc_1980_000=mn_inctot1980/1000
gen pc_inc_2017_000=mn_inctot2017/1000
keep race czone pc_inc* 
keep if inlist(race,1,2)
tempfile inc8017
save `inc8017', replace

use "$out\rotemb_mort_bartik_nostcz_res_6"
keep if agecat==2584 & ed=="all"
keep shr* Bartik_gr czone  race sex pc_inc_1990 Px_1990 totemp_gr_1980

merge m:1 czone race using `inc8017'
drop _merge

merge m:1  czone using "$data\gpss_test_1980_nostcz"
gen pc_inc_1990_000=pc_inc_1990/1000
gen oth_rate=1-nhw_rate-nhb_rate-fborn_rate-his_rate
drop _merge

merge m:1 czone using "$data\AHRF\AHRF8020_cz"
drop _merge

merge m:1 czone race sex using $data\spatial\fullsample_cznost
keep if _merge==3
drop _merge

merge m:1 czone using $data\geocode\urb_rur_cz
keep if _merge==3
drop _merge

gl rhs1vars "nhw_rate nhb_rate fborn_rate urb1_share urb2_share"   
gl rhs2vars "coll_rate nohs_rate"
gl rhs3vars "pov_rate assist_rate noemp_rate workdis_rate divsep_rate"

label variable Bartik_gr "Bartik composite"
label variable shr_13 "Ind 13_: Tobacco mfg & textiles (knits)"
label variable shr_14 "Ind 14_: Textiles (Rugs,thread,cloth)"
label variable shr_15 "Ind 15_: Textiles (other) and Apparel"
label variable shr_27 "Ind 27_: Metal mfg (iron, steel, aluminum)"
label variable shr_24 "Ind 24_: Furniture and Wood products"
foreach raceg in 1 2{
		if "`raceg'"== "1"{
			local racetext "Non-Hispanic White"
		}
		else{
			local racetext "Non-Hispanic Black"
		}
mark touse_`raceg' [aw=Px_1990]
markout touse_`raceg'  Bartik_gr shr_13 shr_14 shr_15 shr_27 shr_24 pc_inc_1980_000 lnchBedsPC BedsPC1980 lnchPhysPC PhysPC1980  $rhs1vars $rhs2vars $rhs3vars
keep Bartik_gr shr_13 shr_14 shr_15 shr_27 shr_24 pc_inc_1980_000 lnchBedsPC BedsPC1980 lnchPhysPC PhysPC1980  $rhs1vars $rhs2vars $rhs3vars Px_1990 czone race touse_?
collapse (mean)Bartik_gr shr_13 shr_14 shr_15 shr_27 shr_24 pc_inc_1980_000 lnchBedsPC BedsPC1980 lnchPhysPC PhysPC1980  $rhs1vars $rhs2vars $rhs3vars Px_1990 touse_? , by(czone race)
  *pcorr shr_13 pc_inc_1980_000  [aw=Px_1990] if race==`raceg' & touse_`raceg'==1
  pcorr shr_13 pc_inc_1980_000  BedsPC1980  PhysPC1980  $rhs1vars $rhs2vars $rhs3vars [aw=Px_1990] if race==`raceg'  & touse_`raceg'==1
  regress shr_13 pc_inc_1980_000  [aw=Px_1990] if race==`raceg' & touse_`raceg'==1
	outreg2 using "$home\output\appendix\gpss_out_res_r`raceg'", excel replace coef se noaster noparen
  regress shr_13 pc_inc_1980_000  BedsPC1980  PhysPC1980  $rhs1vars $rhs2vars $rhs3vars [aw=Px_1990] if race==`raceg'  & touse_`raceg'==1
	outreg2 using "$home\output\appendix\gpss_out_res_r`raceg'", excel coef se  noaster noparen
foreach dv in  shr_14 shr_15 shr_27 shr_24{
		*pcorr `dv' pc_inc_1980_000  [aw=Px_1990] if race==`raceg' & touse_`raceg'==1
		pcorr `dv' pc_inc_1980_000  BedsPC1980  PhysPC1980  $rhs1vars $rhs2vars $rhs3vars [aw=Px_1990] if race==`raceg' & touse_`raceg'==1
		 regress `dv' pc_inc_1980_000  [aw=Px_1990] if race==`raceg' & touse_`raceg'==1
		outreg2 using "$home\output\appendix\gpss_out_res_r`raceg'", excel coef se  noaster noparen
		 regress `dv' pc_inc_1980_000  BedsPC1980  PhysPC1980  $rhs1vars $rhs2vars $rhs3vars [aw=Px_1990] if race==`raceg' & touse_`raceg'==1
		outreg2 using "$home\output\appendix\gpss_out_res_r`raceg'", excel coef se  noaster noparen
}
tabstat shr_13 shr_14 shr_15 shr_27 shr_24 pc_inc_1980_000  BedsPC1980  PhysPC1980  $rhs1vars $rhs2vars $rhs3vars [aw=Px_1990] if race==`raceg' & touse_`raceg'==1, s(p25 p50 p75) c(s) nosep longstub
}

