import excel "$geoxwalk\czlma903_fix.xls", sheet("CZLMA903") cellrange(A1:C3158) firstrow allstring clear
gen county_fips=real( CountyFIPSCode)
gen czone=real(CZ90)
save $geoxwalk\czlma903_fix, replace
merge 1:m county_fips using $pop\pop_cty_1990_2017
gen int stfips=floor(county_fips/1000)
gen byte noedst=inlist(stfips,13, 22, 36, 40, 44, 46, 53)
gen byte nohst=(stfips==33)
preserve
collapse (sum) poptot , by(  year czone race sex age_lt)
rename race race_s
rename sex sex_s
gen byte sex=1*(sex_s=="male")+2*(sex_s=="female")
gen byte race=1*(race_s=="white")+2*(race_s=="black")
compress
keep if inrange(age_lt,25,80)&inlist(race,1,2)
save $data\pop\brcz9017, replace

restore
drop if noedst==1 | nohst==1
collapse (sum) poptot , by(  year  czone race sex age_lt)
rename race race_s
rename sex sex_s
gen byte sex=1*(sex_s=="male")+2*(sex_s=="female")
gen byte race=1*(race_s=="white")+2*(race_s=="black")
compress
keep if inrange(age_lt,25,80)&inlist(race,1,2)
save $pop\brcz9017_base, replace
