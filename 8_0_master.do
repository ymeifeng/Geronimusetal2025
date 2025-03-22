* Meifeng Yang on 2/21/2025
* Master file for Github

* the following packages need to be installed before running step 8
ssc install tmpdir, replace 
ssc install hdfe, replace 
ssc install reg2hdfe, replace 

* paths 
gl data "[Your data path]"
gl logs "[Your log path]"
gl code "[Your code path]"
gl output "[Your output path] \spatial\\`mdir'"
gl logfile "$logs\spatial\\`mdir'\run_spatial6_res_${sample_restriction}_${distance}_$S_DATE.log"

gl vintage "[Your analysis date]"


* in this step you will need to go into the do file to select the sample restrictions
do "$code\8_1_run_model_spatial6_res_czones_MY.do" 
do "$code\8_2_run_model_spatial6_res_czones_SD_MY.do" // for SD - see readme
do "$code\8_3_run_model_spatial6_res_nostcz_alled.do" // for alled - see readme
do "$code\8_4_run_model_spatial6_res_czones_alled_SD_MY" // for alled and SD - see readme