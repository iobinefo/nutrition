
***********************************************************************************************************************************************
*Merging Dataset
***********************************************************************************************************************************************


use "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five\final_23.dta" , replace



keep if s4bq1==1
append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_four\final_19.dta"

append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_two\final_12.dta" 
append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_three\final_15.dta"




preserve
keep if year ==2012
misstable summarize haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue    hh_members  soil_qty_rev2 mrk_dist_w num_mem hh_headage femhead attend_sch worker zone state lga ea peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg 


count
restore

preserve
keep if year ==2015
misstable summarize haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue    hh_members  soil_qty_rev2 mrk_dist_w num_mem hh_headage femhead attend_sch worker zone state lga ea peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg 


count
restore


preserve
keep if year ==2018
misstable summarize haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue    hh_members  soil_qty_rev2 mrk_dist_w num_mem hh_headage femhead attend_sch worker zone state lga ea peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg 


count
restore


preserve
keep if year ==2023
misstable summarize haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue    hh_members  soil_qty_rev2 mrk_dist_w num_mem hh_headage femhead attend_sch worker zone state lga ea peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg 


count
restore



save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five\apppend.dta", replace





use "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five\apppend.dta", clear

order year


gen dummy = 1

collapse (sum) dummy, by (hhid)
tab dummy
keep if dummy==4
sort hhid

merge 1:m hhid  using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five\apppend.dta", gen(fil)

drop if fil==2

order year

sort hhid  year

misstable summarize haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue    hh_members  soil_qty_rev2 mrk_dist_w num_mem hh_headage femhead attend_sch worker zone state lga ea peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg 




preserve
keep if year ==2012
misstable summarize haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue    hh_members  soil_qty_rev2 mrk_dist_w num_mem hh_headage femhead attend_sch worker zone state lga ea peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg 


count
restore

preserve
keep if year ==2015
misstable summarize haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue    hh_members  soil_qty_rev2 mrk_dist_w num_mem hh_headage femhead attend_sch worker zone state lga ea peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg 


count
restore


preserve
keep if year ==2018
misstable summarize haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue    hh_members  soil_qty_rev2 mrk_dist_w num_mem hh_headage femhead attend_sch worker zone state lga ea peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg 


count
restore


preserve
keep if year ==2023
misstable summarize haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue    hh_members  soil_qty_rev2 mrk_dist_w num_mem hh_headage femhead attend_sch worker zone state lga ea peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg 


count
restore













*tab if ha_planted == 0 | ha_planted == .
*drop if ha_planted == 0 | ha_planted == .

gen yield_plot =  quant_harv_kg/ ha_planted
gen fert_rate = total_qty/ ha_planted
*gen n_rate = n_kg/ field_size
gen productivity = value_harvest/ ha_planted
foreach v of varlist  productivity  {
	_pctile `v' , p(5 95) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 1%"
}




/////real variables

gen input_ratio =  real_tpricefert_cens_mrk/real_maize_price_mr
gen output_ratio =  real_maize_price_mr/ real_tpricefert_cens_mrk
gen good = (soil_qty_rev2 ==1)
gen fair = (soil_qty_rev2==2)
gen poor = (soil_qty_rev2==3)
gen good_soil_plant = ha_planted if ha_planted !=. & good==1
gen fair_soil_plant = ha_planted if ha_planted !=. & fair==1
gen poor_soil_plant = ha_planted if ha_planted !=. & poor==1



misstable summarize haz value_harvest totalcons_protein peraeq_cons_protein ha_planted field_size quant_harv_kg  maize_price_mr real_maize_price_mr total_qty  real_tpricefert_cens_mrk  real_hhvalue hh_members soil_qty_rev2 good fair poor mrk_dist_w num_mem hh_headage femhead attend_sch worker peraeq_cons_cereal  peraeq_cons_veg totalcons_cereal  totalcons_veg  mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug 





//// annual_salary annual_salary_agwage
preserve
keep if year ==2018
sum hrs_wage_off_farm, detail
tabstat haz value_harvest totalcons_protein peraeq_cons_protein ha_planted field_size quant_harv_kg  maize_price_mr real_maize_price_mr total_qty  real_tpricefert_cens_mrk  real_hhvalue hh_members soil_qty_rev2 good fair poor mrk_dist_w num_mem hh_headage femhead attend_sch worker peraeq_cons_cereal  peraeq_cons_veg totalcons_cereal  totalcons_veg  mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  good_soil_plant fair_soil_plant poor_soil_plant mrk_dist_w num_mem hh_headage femhead attend_sch worker hrs_ag_activ mean_annual_rainfall dev_rain_Mar dev_rain_Aug [w=weight], statistics( mean median sd min max ) columns(statistics)
count
restore


preserve
keep if year ==2023
sum hrs_wage_off_farm, detail
tabstat haz value_harvest totalcons_protein peraeq_cons_protein ha_planted field_size quant_harv_kg  maize_price_mr real_maize_price_mr total_qty  real_tpricefert_cens_mrk  real_hhvalue hh_members soil_qty_rev2 good fair poor mrk_dist_w num_mem hh_headage femhead attend_sch worker peraeq_cons_cereal  peraeq_cons_veg totalcons_cereal  totalcons_veg  mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  good_soil_plant fair_soil_plant poor_soil_plant mrk_dist_w num_mem hh_headage femhead attend_sch worker hrs_ag_activ mean_annual_rainfall dev_rain_Mar dev_rain_Aug [w=weight], statistics( mean median sd min max ) columns(statistics)
count
restore

gen commercial_dummy = (total_qty >0)
//% of HHs that bought commercial fertilizer by each survey wave
bysort year : tabstat commercial_dummy [w=weight], stat(mean sem) //

// By HH, sum the binary variable of commerical fert market particapation for all waves
bysort hhid : egen sum_4waves_com_fer_bin = sum(commercial_dummy) 



/*
**********************************
ttest household_diet_cut_off2, by(year) unequal
ttest number_foodgroup, by(year) unequal
ttest totcons_pc, by(year) unequal
ttest peraeq_cons, by(year) unequal
ttest ha_planted, by(year) unequal
ttest field_size, by(year) unequal
ttest quant_harv_kg, by(year) unequal
ttest yield_plot, by(year) unequal
ttest value_harvest, by(year) unequal
ttest productivity_w, by(year) unequal
ttest maize_price_mr, by(year) unequal
ttest real_maize_price_mr, by(year) unequal
ttest input_ratio, by(year) unequal
ttest total_qty, by(year) unequal
ttest n_kg, by(year) unequal
ttest n_rate, by(year) unequal
ttest tpricefert_cens_mrk, by(year) unequal
ttest real_tpricefert_cens_mrk, by(year) unequal
ttest good, by(year) unequal
ttest fair, by(year) unequal
ttest poor, by(year) unequal
ttest good_soil_plant, by(year) unequal
ttest fair_soil_plant, by(year) unequal
ttest poor_soil_plant, by(year) unequal
ttest hh_members, by(year) unequal
ttest hhasset_value_w, by(year) unequal
ttest peraeq_cons_cereal, by(year) unequal
ttest peraeq_cons_protein, by(year) unequal
ttest peraeq_cons_veg, by(year) unequal
ttest hrs_wage_off_farm, by(year) unequal
ttest hrs_wage_on_farm, by(year) unequal
ttest nworker_wage_off_farm, by(year) unequal
ttest nworker_wage_on_farm, by(year) unequal
ttest hrs_off_farm, by(year) unequal
ttest hrs_on_farm, by(year) unequal
ttest nworker_off_farm, by(year) unequal
ttest nworker_on_farm, by(year) unequal
ttest  mrk_dist_w, by(year) unequal
 */         

save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\child_nutrition.dta", replace ///everything




use "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\child_nutrition.dta", clear //everything


gen lperaeq_cons_cereal = log(peraeq_cons_cereal)

*gen lperaeq_cons_protein = log(peraeq_cons_protein + 1)
gen value_harvest1 = -value_harvest
gen shockk = (shock==0)
misstable summarize haz peraeq_cons_protein
replace peraeq_cons_protein = 0 if peraeq_cons_protein ==.
gen inc__shock = value_harvest1*shockk

gen lperaeq_cons_veg = log(peraeq_cons_veg)
gen lperaeq_cons = log(peraeq_cons)

gen lproductivity_w = log(productivity_w + 1)

save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\child_nutrition2.dta", replace ///everything



local time_avg "mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker real_tpricefert_cens_mrk value_harvest annual_salary_agwage annual_salary mean_annual_rainfall shock shock1"

foreach x in `time_avg' {

	bysort hhid : egen TAvg_`x' = mean(`x')

}


*******************************************************
*ivreg2
*******************************************************

count
*keep if child ==1
count


preserve
keep if year ==2012
tabstat haz shock shock1 peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize haz shock shock1 peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug 

count
restore

*/
preserve
keep if year ==2015
tabstat haz shock shock1 peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize haz shock shock1 peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug 
count
restore



preserve
keep if year ==2018
tabstat haz shock shock1 peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize haz shock shock1 peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug 
count
restore


preserve
keep if year ==2023
tabstat haz shock shock1  peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug [w=weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize haz shock shock1 peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug 
count
restore


* ln_cv_rain_Mar_June ln_cv_gdd_Mar_June ln_cv_hot_Mar_June ln_cv_temp_Mar shortfall_Mar dev_rain_2017_Mar dev_gdd_2017_Mar dev_hot_2017_Mar ln_cv_rain_Aug_Dec ln_cv_gdd_Aug_Dec ln_cv_hot_Aug_Dec dev_rain_2017_Aug dev_hot_2017_Aug dev_gdd_2017_Aug




gen inc_shock  = value_harvest*shock
gen rain_shock = shortfall_Mar*shock

ivregress 2sls peraeq_cons_protein ///
    (value_harvest inc_shock = shortfall_Mar rain_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
    i.year, vce(cluster hhid)

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock




ivreghdfe peraeq_cons_protein ///
    (value_harvest inc_shock = shortfall_Mar rain_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
    , absorb(hhid year) cluster(hhid)

lincom value_harvest
lincom value_harvest + inc_shock




************************************
*Child height for age**************
***********************************

* Endogenous variables: value_harvest and its interaction with shock
* Instruments: dev_rain_Mar, dev_rain_Aug and their interactions with shock


ivregress 2sls haz ///
    (c.value_harvest c.value_harvest#c.shock = ///
     c.dev_rain_Mar  c.dev_rain_Aug ///
     c.dev_rain_Mar#c.shock c.dev_rain_Aug#c.shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
    i.year, vce(cluster hhid)

estat firststage

* Marginal effect of value_harvest when shock=0
lincom value_harvest

* Marginal effect of value_harvest when shock=1  (if shock is binary)
lincom value_harvest + c.value_harvest#c.shock



ivreghdfe haz ///
    (c.value_harvest c.value_harvest#c.shock = ///
     c.dev_rain_Mar  c.dev_rain_Aug ///
     c.dev_rain_Mar#c.shock c.dev_rain_Aug#c.shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall, ///
    absorb(hhid year) cluster(hhid)

lincom value_harvest
lincom value_harvest + c.value_harvest#c.shock


*************************
*2
*************************


* Endogenous interaction
gen inc_shock = value_harvest*shock

  
* Excluded instruments interacted with shock
gen zMar_shock = dev_rain_Mar*shock
gen zAug_shock = dev_rain_Aug*shock

misstable summarize haz peraeq_cons_protein
replace peraeq_cons_protein = 0 if peraeq_cons_protein ==.

gen lperaeq_cons_protein = log(peraeq_cons_protein + 1)



eststo clear
ivregress 2sls lperaeq_cons_protein ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr TAvg_good TAvg_fair TAvg_total_qty TAvg_real_hhvalue ///
    TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker TAvg_mean_annual_rainfall ///
    i.year, vce(cluster hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\result\protein.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock


eststo clear
ivreghdfe lperaeq_cons_protein ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr TAvg_good TAvg_fair TAvg_total_qty TAvg_real_hhvalue ///
    TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker TAvg_mean_annual_rainfall ///
    , absorb(hhid year) cluster(hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\result\protein.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

lincom value_harvest
lincom value_harvest + inc_shock





*************************
*2 HAZ
*************************

eststo clear
ivregress 2sls haz ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock  i.year, vce(cluster hhid)

ivreghdfe haz ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock  , absorb(hhid year) cluster(hhid)





eststo clear
ivregress 2sls haz ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr TAvg_good TAvg_fair TAvg_total_qty TAvg_real_hhvalue ///
    TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker TAvg_mean_annual_rainfall ///
    i.year, vce(cluster hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\result\haz.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock



ivreghdfe haz ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr TAvg_good TAvg_fair TAvg_total_qty TAvg_real_hhvalue ///
    TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker TAvg_mean_annual_rainfall ///
    , absorb(hhid year) cluster(hhid)

lincom value_harvest
lincom value_harvest + inc_shock


