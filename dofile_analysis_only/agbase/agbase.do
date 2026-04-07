
***********************************************************************************************************************************************
*Merging Dataset
***********************************************************************************************************************************************


use  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_one\final_10.dta", replace
keep if ag_rainy_10==1
save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_one\final_100.dta", replace


use  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_two\final_12.dta" , replace
keep if ag_rainy_12==1
save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_two\final_120.dta" , replace

use  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_three\final_15.dta", replace
keep if ag_rainy_15==1
save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_three\final_150.dta", replace


use  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_four\final_19.dta", replace
keep if ag_rainy_18==1
save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_four\final_190.dta", replace


use  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five\final_23.dta", replace
keep if ag_rainy_23==1
save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five\final_230.dta", replace








use  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_one\final_100.dta", replace
append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_two\final_120.dta" 
append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_three\final_150.dta"

append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five\final_230.dta" 

append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_four\final_190.dta"


*keep if child==1

/*
use  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_one\final_10.dta", replace
append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_two\final_12.dta" 
append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_three\final_15.dta"

append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five\final_23.dta" 

append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_four\final_19.dta"
*/




save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five\apppend.dta", replace





use "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five\apppend.dta", clear

order year


gen dummy = 1

collapse (sum) dummy, by (hhid)
tab dummy
keep if dummy==5
sort hhid

merge 1:m hhid  using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five\apppend.dta", gen(fil)

drop if fil==2

order year

sort hhid  year


tab child, missing
replace child = 0 if child ==.

//% of HHs that bought commercial fertilizer by each survey wave
bysort year : tabstat child , stat(mean sem)


replace haz2 = 0 if haz2==.
replace peraeq_cons_protein =0 if peraeq_cons_protein ==.



//% of HHs that bought commercial fertilizer by each survey wave
bysort year : tabstat haz2 [w=weight], stat(mean sem)




gen lperaeq_cons_cereal = log(peraeq_cons_cereal + 1)


replace peraeq_cons_cereal = 0 if peraeq_cons_cereal ==.

replace peraeq_cons_veg = 0 if peraeq_cons_veg ==.

gen lperaeq_cons_veg = log(peraeq_cons_veg + 1)
gen lperaeq_cons = log(peraeq_cons + 1)

misstable summarize haz peraeq_cons_protein peraeq_cons_cereal peraeq_cons_veg
replace peraeq_cons_protein = 0 if peraeq_cons_protein ==.

gen lperaeq_cons_protein = log(peraeq_cons_protein + 1)


local time_avg "mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch  real_tpricefert_cens_mrk value_harvest annual_salary_agwage annual_salary mean_annual_rainfall shock hh_members"

foreach x in `time_avg' {

	bysort hhid : egen TAvg_`x' = mean(`x')

}




preserve
keep if year ==2010

tabstat haz haz2 peraeq_cons_protein value_harvest shock shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea

count
restore



preserve
keep if year ==2012
tabstat haz haz2 peraeq_cons_protein value_harvest shock shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea

count
restore

preserve
keep if year ==2015

tabstat haz haz2 peraeq_cons_protein value_harvest shock shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea

count
restore


preserve
keep if year ==2018

tabstat haz haz2 peraeq_cons_protein value_harvest shock shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea
count
restore


preserve
keep if year ==2023

tabstat haz haz2 peraeq_cons_protein value_harvest shock shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea
count
restore








/********************************************************************
Fancy bar-line graph by year:
- Bars: mean haz and mean peraeq_cons_protein
- Line: mean value_harvest
- Uses weights if available
********************************************************************/

preserve

keep year haz2 value_harvest weight

collapse (mean) haz2 value_harvest [aw=weight], by(year)

sort year

twoway ///
    (connected haz year, lwidth(medthick) msymbol(circle) msize(medium)) ///
    (line value_harvest year, yaxis(2) lwidth(medthick) msymbol(diamond) msize(medium)), ///
    xlabel(2010 2012 2015 2018 2023, labsize(medlarge)) ///
    xtitle("Survey year", size(medlarge)) ///
    ytitle("Mean HAZ", axis(1) size(medlarge)) ///
    ytitle("Mean value of harvest", axis(2) size(medlarge)) ///
    title("Children's HAZ and household harvest value over time", size(large)) ///
    subtitle("Connected points show mean HAZ; line shows mean value of harvest", size(medsmall)) ///
    legend(order(1 "Mean HAZ" 2 "Mean value of harvest") ///
           rows(1) size(small) position(6)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    yline(0, lwidth(thin)) ///
    name(haz_harvest_connected, replace)

restore



preserve

keep year haz value_harvest weight

collapse (mean) haz value_harvest [aw=weight], by(year)

sort year

twoway ///
    (scatter haz year, msize(large) msymbol(circle)) ///
    (line haz year, lwidth(medium)) ///
    (line value_harvest year, yaxis(2) lwidth(medthick) msymbol(diamond) msize(medium)), ///
    xlabel(2010 2012 2015 2018 2023, labsize(medlarge)) ///
    xtitle("Survey year", size(medlarge)) ///
    ytitle("Mean HAZ", axis(1) size(medlarge)) ///
    ytitle("Mean value of harvest", axis(2) size(medlarge)) ///
    title("Children's HAZ and household harvest value over time", size(large)) ///
    subtitle("Points and line show mean HAZ; line shows mean value of harvest", size(medsmall)) ///
    legend(order(1 "Mean HAZ" 3 "Mean value of harvest") ///
           rows(1) size(small) position(6)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    yline(0, lwidth(thin)) ///
    name(haz_harvest_scatterline, replace)

restore









*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************




preserve

keep year peraeq_cons_protein value_harvest weight

collapse (mean) peraeq_cons_protein value_harvest [aw=weight], by(year)

sort year

twoway ///
    (bar peraeq_cons_protein year, barwidth(0.6)) ///
    (line value_harvest year, yaxis(2) lwidth(medthick) msymbol(circle) msize(medium)), ///
    xlabel(2010 2012 2015 2018 2023, labsize(medlarge)) ///
    xtitle("Survey year", size(medlarge)) ///
    ytitle("Mean protein consumption", axis(1) size(medlarge)) ///
    ytitle("Mean value of harvest", axis(2) size(medlarge)) ///
    title("Protein consumption and household harvest value over time", size(large)) ///
    subtitle("Bar shows mean protein consumption; line shows mean value of harvest", size(medsmall)) ///
    legend(order(1 "Mean protein consumption" 2 "Mean value of harvest") ///
           rows(1) size(small) position(6)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(protein_harvest_graph, replace)

restore



*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************

********************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************

/********************************************************************
Transitions in NUMBER of children aged 0–59 months across waves
using child1 = number of children in household

Assumptions:
- hhid = household id
- year = survey year
- child1 = number of children aged 0–59 months in household
********************************************************************/
preserve
*-------------------------------*
* 1. Sort and create lag values
*-------------------------------*
sort hhid year
bysort hhid (year): gen child1_lag = child1[_n-1]
bysort hhid (year): gen year_lag   = year[_n-1]

*-------------------------------------------------------------*
* 2. Keep only valid consecutive wave comparisons
*    2010->2012, 2012->2015, 2015->2018, 2018->2023
*-------------------------------------------------------------*
gen valid_pair = ///
    (year==2012 & year_lag==2010) | ///
    (year==2015 & year_lag==2012) | ///
    (year==2018 & year_lag==2015) | ///
    (year==2023 & year_lag==2018)

*-------------------------------------------------------------*
* 3. Replace missing counts with zero if appropriate
*    Only do this if missing means "no children"
*-------------------------------------------------------------*
replace child1     = 0 if missing(child1)
replace child1_lag = 0 if valid_pair==1 & missing(child1_lag)

*-------------------------------------------------------------*
* 4. Create child-count transitions
*    stayed_children  = number of children present in both waves
*    left_children    = number of children lost since previous wave
*    entered_children = number of children added since previous wave
*-------------------------------------------------------------*
gen stayed_children  = .
gen left_children    = .
gen entered_children = .

replace stayed_children  = min(child1_lag, child1) if valid_pair==1
replace left_children    = max(child1_lag - child1, 0) if valid_pair==1
replace entered_children = max(child1 - child1_lag, 0) if valid_pair==1

*-------------------------------------------------------------*
* 5. Total number of children in each year
*-------------------------------------------------------------*
gen all_children = child1

*-------------------------------------------------------------*
* 6. Display yearly totals
*-------------------------------------------------------------*

collapse ///
    (sum) all_children stayed_children left_children entered_children, by(year)

keep if inlist(year, 2010, 2012, 2015, 2018, 2023)

list year all_children stayed_children left_children entered_children, sep(0)

*-------------------------------------------------------------*
* 7. Plot bar graph by year
*    Note:
*    - 2010 has no previous wave, so stayed/left/entered = missing/0
*    - This is a bar chart, not a histogram
*-------------------------------------------------------------*
replace stayed_children  = 0 if missing(stayed_children)
replace left_children    = 0 if missing(left_children)
replace entered_children = 0 if missing(entered_children)

graph bar all_children left_children entered_children, ///
    over(year, gap(20) label(angle(0))) ///
    blabel(bar, format(%9.0g)) ///
    ytitle("Number of children aged 0–59 months") ///
    title("Children aged 0–59 months in households by year") ///
    subtitle("All children, those who left, and those who entered between waves") ///
    legend(order(1 "All children in year" 2 "Children who left" 3 "Children who entered")) ///
    name(childcount_transition_bar, replace)

restore


********************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************

/*
preserve
keep if year==2010

gen group = 1 if child == 5 // HHs that purchased comm fert in all waves

replace group= 2 if child>0 & child<5 //HHs that purchased comm fert in some waves

replace group = 3 if child==0 // HHs that never purchased comm fert in all waves

//% of HHs in each comm fert particiaption group 
tab group
restore

/////////////checking for 2 or more waves////////////////
	


gen use_two = 1 if group ==1 | group ==2 
replace use_two = 0 if use_two ==.
tab use_two



ttest nworker_off_farm, by(year) unequal
ttest nworker_on_farm, by(year) unequal
ttest  mrk_dist_w, by(year) unequal
 */         


*****************************************************************************************************************************************
********************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
********************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************


save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\child_nutrition2.dta", replace ///everything









*******************************************************
*ivreg2
*******************************************************
use "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\child_nutrition2.dta", clear //everything



//worker total_qty_w
replace haz = 0 if haz==.

gen inc_shock  = value_harvest*ag_shock
gen rain_shock = shortfall_Mar*ag_shock

ivregress 2sls peraeq_cons_protein ///
    (value_harvest inc_shock = shortfall_Mar rain_shock) ///
    ag_shock mrk_dist_w real_maize_price_mr  real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
    i.year, vce(cluster hhid)

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock




ivreghdfe peraeq_cons_protein ///
    (value_harvest inc_shock = shortfall_Mar rain_shock) ///
    ag_shock mrk_dist_w real_maize_price_mr   real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
    , absorb(hhid year) cluster(hhid)

lincom value_harvest
lincom value_harvest + inc_shock



************************************
*Child height for age**************
***********************************

* Endogenous variables: value_harvest and its interaction with shock
* Instruments: dev_rain_Mar, dev_rain_Aug and their interactions with shock


ivregress 2sls haz ///
    (c.value_harvest c.value_harvest#c.ag_shock = ///
     c.dev_rain_Mar  c.dev_rain_Aug ///
     c.dev_rain_Mar#c.ag_shock c.dev_rain_Aug#c.ag_shock) ///
    ag_shock mrk_dist_w real_maize_price_mr   real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
    i.year, vce(cluster hhid)

estat firststage

* Marginal effect of value_harvest when shock=0
lincom value_harvest

* Marginal effect of value_harvest when shock=1  (if shock is binary)
lincom value_harvest + c.value_harvest#c.ag_shock



ivreghdfe haz ///
    (c.value_harvest c.value_harvest#c.shock = ///
     c.dev_rain_Mar  c.dev_rain_Aug ///
     c.dev_rain_Mar#c.ag_shock c.dev_rain_Aug#c.ag_shock) ///
    ag_shock mrk_dist_w real_maize_price_mr  real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall, ///
    absorb(hhid year) cluster(hhid)

lincom value_harvest
lincom value_harvest + c.value_harvest#c.shock











*************************
*2
*************************
use "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\child_nutrition2.dta", clear //everything

* Endogenous interaction
gen inc_shock = value_harvest*ag_shock

  
* Excluded instruments interacted with shock
gen zMar_shock = dev_rain_Mar*ag_shock
gen zAug_shock = dev_rain_Aug*ag_shock




eststo clear
ivregress 2sls lperaeq_cons_protein ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    ag_shock mrk_dist_w real_maize_price_mr   real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr  TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
    i.year, vce(cluster hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\result\protein.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock


eststo clear
ivreghdfe lperaeq_cons_protein ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    ag_shock mrk_dist_w real_maize_price_mr  real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
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
    ag_shock  i.year, vce(cluster hhid)

ivreghdfe haz ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    ag_shock  , absorb(hhid year) cluster(hhid)





eststo clear
ivregress 2sls haz2 ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    ag_shock mrk_dist_w real_maize_price_mr real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr  TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
    i.year, vce(cluster hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\result\haz.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock



ivreghdfe haz ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    ag_shock mrk_dist_w real_maize_price_mr  real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr  TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
    , absorb(hhid year) cluster(hhid)

lincom value_harvest
lincom value_harvest + inc_shock

