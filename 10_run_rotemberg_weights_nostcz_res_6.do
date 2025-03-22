capture log close
clear all
set maxvar 20000
global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
gl output	"[tabular output file directory]
gl dosource "$do\10_run_rotemberg_weights.do"
use "$out\hist_race_income_bartik_mortchg_cznost_res"
keep  czone pc_inc_*_1990 race sex agecat Px_*_1990 d_asdr_0_* d_yll_0_*
rename Px_tot_1990 Px_all_1990
gen pc_inc_1990=pc_inc_NHW_1990 if race==1
replace pc_inc_1990=pc_inc_NHB_1990 if race==2
foreach ed in all ghs lehs coll ltcol hi75 lo25{
	rename Px_`ed'_1990 Px_1990_`ed'
}
keep if agecat==4564 | agecat==2584
*
reshape long Px_1990_ d_asdr_0_ d_yll_0_, j(ed) string i(czone sex race agecat pc_inc_1990 )
rename Px_1990_ Px_1990
rename d_asdr_0_ d_asdr_0
rename d_yll_0_ d_yll_0 
*
save $out\rotemb1_nostcz_res, replace


merge m:1 czone race using $out\bartik_shares_cz_byrace.dta
qui forvalues k=1/93{
 cap replace shr_`k'=0 if shr_`k'==.
}
save $out\rotemb_mort_bartik_nostcz_res_6, replace
	gen dm_res=.
	gen dyl_res=.
	gen B_res=.
	gen wt=.
foreach ed in all ghs lehs coll ltcol hi75 lo25{
	foreach sex in 1 2{
		foreach race in 1 2{
			foreach agecat in 4564 2584{
				regress d_asdr_0 pc_inc_1990 if race==`race' & sex==`sex' &agecat==`agecat' & ed=="`ed'" [aw=Px_1990]
					predict dm_res_ if e(sample), resid
					replace dm_res=dm_res_ if e(sample)
					drop dm_res_
					tempvar poptot
					egen `poptot'=total(Px_1990*e(sample))
					replace wt=Px_1990/`poptot' if e(sample)
					drop `poptot'
				regress d_yll_0 pc_inc_1990 if race==`race' & sex==`sex' &agecat==`agecat' & ed=="`ed'" [aw=Px_1990]
					predict dyl_res_ if e(sample), resid
					replace dyl_res=dyl_res_ if e(sample)
					drop dyl_res_
				regress Bartik_gr pc_inc_1990 if race==`race' & sex==`sex' &agecat==`agecat' & ed=="`ed'" [aw=Px_1990]
					predict B_res_ if e(sample), resid
						replace B_res=B_res_ if e(sample)
						drop B_res_
			}
		}
	}
}

summ wt*

qui forvalues k=1/93{
		cap gen double _beta_dm_`k'_n=shr_`k'*dm_res
		cap gen double _beta_dm_`k'_n_w=_beta_dm_`k'_n*wt
		cap gen double _beta_dm_`k'_d=shr_`k'*B_res
		cap gen double _beta_dm_`k'_d_w=_beta_dm_`k'_d*wt
		cap gen double _beta_dyl_`k'_n=shr_`k'*dyl_res
		cap gen double _beta_dyl_`k'_n_w=_beta_dyl_`k'_n*wt
		cap gen double _beta_dyl_`k'_d=shr_`k'*B_res
		cap gen double _beta_dyl_`k'_d_w=_beta_dyl_`k'_d*wt
		cap gen double _alpha_`k'_n=lnchsh_`k'*shr_`k'*B_res
		cap gen double _alpha_`k'_n_w=_alpha_`k'_n*wt

}
collapse (sum) _beta_* _alpha_* , by(sex race agecat ed)

	egen _alpha_d=rowtotal(_alpha_*_n)
	egen _alpha_d_w=rowtotal(_alpha_*_n_w)
forvalues k=1/93{
		cap gen double alpha_`k'=_alpha_`k'_n/_alpha_d
		cap gen double alpha_`k'_w=_alpha_`k'_n_w/_alpha_d_w
		cap gen double beta_dm_`k'=_beta_dm_`k'_n/_beta_dm_`k'_d
		cap gen double beta_dm_`k'_w=_beta_dm_`k'_n_w/_beta_dm_`k'_d_w
		cap gen double beta_dyl_`k'=_beta_dyl_`k'_n/_beta_dyl_`k'_d
		cap gen double beta_dyl_`k'_w=_beta_dyl_`k'_n_w/_beta_dyl_`k'_d_w
}
drop *_n  *_n_w *_d *_d_w

keep if agecat==2584 & inlist(ed,"all", "hi75", "lo25")
keep sex race ed alpha_*_w 
export excel using "$output\rotemberg_weights_nostcz_6.xls", firstrow(variables) replace