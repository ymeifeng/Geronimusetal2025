/*estimates correlation between bartik and ln employment change

cd $data
use bartik_1980_2017_cz_edrace.dta
keep czone bartik_totemp_r_* bartik_totemp_all
rename bartik_totemp_all bartik_totemp_r_all
reshape long bartik_totemp_r_, j(race) string i(czone)
rename bartik_totemp_r_ bartik_totemp
rename race races
gen race=0*(races=="all")+1*(races=="nhw")+2*(races=="nhb")
merge 1:1 czone race using g:\data\analysis\cens_inc_1980_2017
regress pc_inc_lnchg_8017 bartik_totemp if race==0 [aw=pop1980]
regress pc_inc_lnchg_8017 bartik_totemp if race==1 [aw=pop1980]
regress pc_inc_lnchg_8017 bartik_totemp if race==2 [aw=pop1980]
summ bartik, d