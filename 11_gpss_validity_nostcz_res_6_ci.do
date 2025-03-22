capture log close
clear all
global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global	dorn	"$data\dorn" /*data downloaded from https://www.ddorn.net/data.htm*/
gl dosource "$do\11_gpss_validity_nostcz_res.do"
use "$out\rotemb_mort_bartik_nostcz_res_6"
keep if agecat==2584 & ed=="all"
keep shr* Bartik_gr czone  race sex pc_inc_1990 Px_1990 totemp_gr_1980

merge m:1  czone using "$data\gpss_test_1980_nostcz"
gen pc_inc_1990_000=pc_inc_1990/1000
gen oth_rate=1-nhw_rate-nhb_rate-fborn_rate-his_rate
drop _merge

merge m:1 czone using "$data\AHRF\AHRF8020_cz"
drop _merge

merge m:1 czone race sex using $data\spatial\fullsample_cznost
keep if _merge==3
drop _merge


gl rhs1vars "nhw_rate nhb_rate fborn_rate"   
gl rhs2vars "coll_rate nohs_rate"
gl rhs3vars "pov_rate assist_rate noemp_rate workdis_rate divsep_rate"

label variable Bartik_gr "Bartik composite"
label variable shr_13 "Ind 13_: Tobacco mfg & textiles (knits)"
label variable shr_14 "Ind 14_: Textiles (Rugs,thread,cloth)"
label variable shr_15 "Ind 15_: Textiles (other) and Apparel"
label variable shr_27 "Ind 27_: Metal mfg (iron, steel, aluminum)"
label variable shr_24 "Ind 24_: Furniture and Wood products"
foreach raceg in 1 2{
	foreach sexg in 1 2{
		if "`raceg'"== "1"{
			local racetext "Non-Hispanic White"
		}
		else{
			local racetext "Non-Hispanic Black"
		}
		if "`sexg'"== "1"{
			local sextext "Males"
		}
		else{
			local sextext "Females"
		}
mark touse_`raceg'_`sexg' [aw=Px_1990]
markout touse_`raceg'_`sexg'  Bartik_gr shr_13 shr_14 shr_15 shr_27 shr_24 pc_inc_1990_000 lnchBedsPC BedsPC1980 lnchPhysPC PhysPC1980  $rhs1vars $rhs2vars $rhs3vars
foreach dv in Bartik_gr shr_13 shr_14 shr_15 shr_27 shr_24{
		qui regress `dv' pc_inc_1990_000 [aw=Px_1990] if race==`raceg' & sex==`sexg' & touse_`raceg'_`sexg'==1
		outreg2 using "$home\output\appendix\gpss_out_res_`dv'_s`sexg'_r`raceg'", excel replace coef se noaster noparen
		qui regress `dv' pc_inc_1990_000 BedsPC1980 PhysPC1980 [aw=Px_1990] if race==`raceg' & sex==`sexg' & touse_`raceg'_`sexg'==1
		outreg2 using "$home\output\appendix\gpss_out_res_`dv'_s`sexg'_r`raceg'", excel coef se  noaster noparen
		qui regress `dv' pc_inc_1990_000 lnchBedsPC BedsPC1980 lnchPhysPC PhysPC1980  [aw=Px_1990] if race==`raceg' & sex==`sexg' & touse_`raceg'_`sexg'==1
		outreg2 using "$home\output\appendix\gpss_out_res_`dv'_s`sexg'_r`raceg'", excel coef se  noaster noparen
		qui regress `dv' pc_inc_1990_000 $rhs1vars $rhs2vars $rhs3vars [aw=Px_1990] if race==`raceg' & sex==`sexg' & touse_`raceg'_`sexg'==1
		outreg2 using "$home\output\appendix\gpss_out_res_`dv'_s`sexg'_r`raceg'", excel coef se  noaster noparen
		qui regress `dv' pc_inc_1990_000 lnchBedsPC BedsPC1980 lnchPhysPC PhysPC1980  $rhs1vars $rhs2vars $rhs3vars [aw=Px_1990] if race==`raceg' & sex==`sexg' & touse_`raceg'_`sexg'==1
		outreg2 using "$home\output\appendix\gpss_out_res_`dv'_s`sexg'_r`raceg'", excel coef se  noaster noparen
}
}
}
foreach r in 1 2{
foreach s in 1 2{
summ Bartik_gr [aw=Pop1980], meanonly
scalar m`s'`r'=r(mean)
gen msd_`s'_`r'=(Bartik_gr-m`s'`r')^2
}
}
gen invpop=1/totemp_gr_1980
foreach r in 1 2{
foreach s in 1 2{
regress msd_`s'_`r' invpop if sex==`s' & race==`r'
}
}