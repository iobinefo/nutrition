



clear

global Nigeria_GHS_W1_raw_data 		"C:\Users\obine\Music\Documents\Smallholder lsms STATA\NGA_2010_GHSP-W1_v03_M_STATA (1)" 
global Nigeria_GHS_W1_created_data  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_one"








********************************************************************************
* AG FILTER *
********************************************************************************

use "${Nigeria_GHS_W1_raw_data}/Post Planting Wave 1\Agriculture\sect11a_plantingw1.dta" , clear

keep hhid s11aq1
rename (s11aq1) (ag_rainy_10)
save  "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", replace



*merge m:1 hhid using ""${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

*keep if ag_rainy_10==1


********************************************************************************
* WEIGHTS *
********************************************************************************

use "${Nigeria_GHS_W1_raw_data}/Post Planting Wave 1\Household\secta_plantingw1.dta" , clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave1 rural
ren wt_wave1 weight
collapse (max) weight rural, by (hhid)
save  "${Nigeria_GHS_W1_created_data}/weight.dta", replace



************************
*Geodata Variables
************************
use "${Nigeria_GHS_W1_raw_data}\Geodata\NGA_PlotGeovariables_Y1.dta", clear

collapse (max) srtmslp_nga srtm_nga twi_nga, by (hhid)

merge 1:m hhid using "${Nigeria_GHS_W1_raw_data}\Geodata\NGA_HouseholdGeovariables_Y1.dta"

merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

ren srtmslp_nga plot_slope
ren srtm_nga  plot_elevation
ren twi_nga   plot_wetness
ren af_bio_12 annual_precipitation
ren af_bio_1 annual_mean_temp
ren dist_market dist_market



tab1 plot_slope plot_elevation plot_wetness, missing

egen med_slope = median( plot_slope)
egen med_elevation = median( plot_elevation)
egen med_wetness = median( plot_wetness)
egen med_prep = median( annual_precipitation)
egen med_temp = median( annual_mean_temp)

replace plot_slope= med_slope if plot_slope==.
replace plot_elevation= med_elevation if plot_elevation==.
replace plot_wetness= med_wetness if plot_wetness==.
replace annual_precipitation= med_prep if annual_precipitation==.
replace annual_mean_temp= med_temp if annual_mean_temp==.

sum annual_precipitation, detail
sum annual_mean_temp, detail
sum dist_market, detail


collapse (max) plot_slope plot_elevation plot_wetness  annual_precipitation annual_mean_temp dist_market, by (hhid)
sort hhid


merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

************winzonrizing total_qty
foreach v of varlist  dist_market  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 1%"
}


tab dist_market
tab dist_market_w, missing
sum dist_market dist_market_w, detail

keep hhid plot_slope plot_elevation plot_wetness  annual_precipitation annual_mean_temp dist_market_w

la var plot_slope "slope of plot"
la var plot_elevation "Elevation of plot"
la var plot_wetness "Potential wetness index of plot"
save "${Nigeria_GHS_W1_created_data}\geodata.dta", replace






********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
												//ALT NB: These are the 2017 values because we convert to PPP after inflation 
global Nigeria_GHS_W1_exchange_rate 401.15  		// https://www.bloomberg.com/quote/USDETB:CUR, https://data.worldbank.org/indicator/PA.NUS.FCRF?end=2023&locations=NG&start=2011
// {2017:315,2021:401.15}
global Nigeria_GHS_W1_gdp_ppp_dollar 146.72		// https://data.worldbank.org/indicator/PA.NUS.PRVT //2021
global Nigeria_GHS_W1_cons_ppp_dollar 155.72		// https://data.worldbank.org/indicator/PA.NUS.PRVT.P //2021
global Nigeria_GHS_W1_inflation 0.312729		//2017: 110.8/214.2, 2021: 110.8/354.3		// inflation rate 2011-2016. Data was collected during 2010-2011. We want to adjust value to 2016 //ALT 03.09.23 Now 2017 per WB's fall update to the poverty line

global Nigeria_GHS_W1_poverty_190 (1.90*83.58) //Calculation for WB's previous $1.90 (PPP) poverty threshold, 158 N. This controls the indicator poverty_under_1_9; change the 1.9 to get results for a different threshold
global Nigeria_GHS_W1_poverty_npl (151 *(1.108)) //2009-2010 poverty line from https://nigerianstat.gov.ng/elibrary/read/544 adjusted to 2011
global Nigeria_GHS_W1_poverty_215 (2.15 * (0.5173 * 112.1))	 // 2017 poverty line - 124.68 N
global Nigeria_GHS_W1_poverty_300 (3.00 *($Nigeria_GHS_W1_inflation * $Nigeria_GHS_W1_cons_ppp_dollar)) //New 2021 poverty line ~690N
 
********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables



*DYA.11.1.2020 Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Nigeria_GHS_W1_pop_tot 158503197
global Nigeria_GHS_W1_pop_rur 89586007
global Nigeria_GHS_W1_pop_urb 68917190







********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Nigeria_GHS_W1_raw_data}/secta_plantingw1.dta", clear
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave1 rural
ren wt_wave1 weight
save  "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhids.dta", replace




********************************************************************************
* INDIVIDUAL IDS *
********************************************************************************
use "${Nigeria_GHS_W1_raw_data}/sect1_plantingw1.dta", clear
gen season="plan"
append using "${Nigeria_GHS_W1_raw_data}/sect1_harvestw1.dta"
replace season="harv" if season==""

ren s1q2 sex
ren s1q4 age
gen female= sex==2

gen fhh = s1q3==1 & female
recode fhh (.=0)
preserve 
collapse (max) fhh, by(hhid)
tempfile fhh
save `fhh'
restore 
la var female "1= individual is female"
la var age "Individual age"
keep hhid indiv female age season
ren female female_
ren age age_ 
reshape wide female_ age_, i(hhid indiv) j(season) string
gen age = age_plan 
replace age=age_harv if age==.
gen female=female_plan 
replace female=female_harv if female==.
drop *harv *plan
merge m:1 hhid using `fhh', nogen

la var female "1= individual is female"
la var age "Individual age"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_person_ids.dta", replace






********************************************************************************
* HOUSEHOLD SIZE *
********************************************************************************
use "${Nigeria_GHS_W1_raw_data}/sect1_plantingw1.dta", clear
gen hh_members = 1
ren s1q3 relhead 
ren s1q2 gender
gen fhh = (relhead==1 & gender==2)
collapse (sum) hh_members (max) fhh, by (hhid)
lab var hh_members "Number of household members"
lab var fhh "1= Female-headed household"
*DYA.11.1.2020 Re-scaling survey weights to match population estimates
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhids.dta", nogen
*Adjust to match total population
total hh_members [pweight=weight]
matrix temp =e(b)
gen weight_pop_tot=weight*${Nigeria_GHS_W1_pop_tot}/el(temp,1,1)
total hh_members [pweight=weight_pop_tot]
lab var weight_pop_tot "Survey weight - adjusted to match total population"
*Adjust to match total population but also rural and urban
total hh_members [pweight=weight] if rural==1
matrix temp =e(b)
gen weight_pop_rur=weight*${Nigeria_GHS_W1_pop_rur}/el(temp,1,1) if rural==1
total hh_members [pweight=weight_pop_tot]  if rural==1

total hh_members [pweight=weight] if rural==0
matrix temp =e(b)
gen weight_pop_urb=weight*${Nigeria_GHS_W1_pop_urb}/el(temp,1,1) if rural==0
total hh_members [pweight=weight_pop_urb]  if rural==0

egen weight_pop_rururb=rowtotal(weight_pop_rur weight_pop_urb)
total hh_members [pweight=weight_pop_rururb]  
lab var weight_pop_rururb "Survey weight - adjusted to match rural and urban population"
drop weight_pop_rur weight_pop_urb
recast double weight*
/*
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhsize.dta", replace
*/
keep hhid zone state lga ea weight* rural hh_members fhh
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_weights.dta", replace






















****************************
*Subsidized Fertilizer
****************************
use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Agriculture\sect11d_plantingw1.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
*graph bar (count), over(s11dq13)

*s11dq13 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq24 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq15 s11dq26  qty of inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer




encode s11dq13, gen(institute)
label list institute


encode s11dq24, gen(institute2)
label list institute2

**THIS IS BASED ON THE ASSUMPTION THAT GOVERNMENT PURCHASED FERTILIZER IS LESS THAN FERTILIZER PURCHASED IN THE LOCAL MARKET


*************Getting Subsidized quantity and Dummy Variable ******************* we are using N2 and N3
gen subsidy_qty1 = s11dq15 if institute ==6 | institute ==7 //8 should be government extension worker
tab subsidy_qty1
gen subsidy_qty2 = s11dq26 if institute2 ==3 | institute2 ==4 // 5 should be government extension worker
tab subsidy_qty2


egen subsidy_qty = rowtotal(subsidy_qty1 subsidy_qty2)  //or should we replace with the second qty (s11dq26), where the first qty is missing (s11dq15==.)
tab subsidy_qty,missing
sum subsidy_qty,detail


gen subsidy_dummy = (subsidy_qty !=0)

tab subsidy_dummy, missing





collapse (sum)subsidy_qty (max) subsidy_dummy, by (hhid)


merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

************winzonrizing subsidy_qty
foreach v of varlist  subsidy_qty  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 1%"
}

tab subsidy_qty
tab subsidy_qty_w, missing
sum subsidy_qty subsidy_qty_w, detail







keep hhid  subsidy_qty_w subsidy_dummy
label var subsidy_qty_w "Quantity of Fertilizer Purchased in kg"
label var subsidy_dummy "=1 if acquired any subsidied fertilizer"
save "${Nigeria_GHS_W1_created_data}\subsidized_fert.dta", replace




******************************* 
*Purchased Fertilizer
*******************************

use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Agriculture\sect11d_plantingw1.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
*graph bar (count), over(s11dq13)

*s11dq13 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq24 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq15 s11dq26  qty of inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer





encode s11dq13, gen(institute)
label list institute


encode s11dq24, gen(institute2)
label list institute2


***fertilzer total quantity, total value & total price***

gen private_fert1_qty = s11dq15 if institute ==4
tab private_fert1_qty
gen private_fert2_qty = s11dq26 if institute2 ==2
tab private_fert2_qty

gen private_fert1_val = s11dq18 if institute ==4


/*
egen val2_cens = median (s11dq31)
tab val2_cens
replace s11dq31= val2_cens if s11dq31==.
tab s11dq31

*/
gen private_fert2_val = s11dq31 if institute2 ==2
tab private_fert2_val



egen total_qty = rowtotal(private_fert1_qty private_fert2_qty)
tab  total_qty, missing

egen total_valuefert = rowtotal(private_fert1_val private_fert2_val)
tab total_valuefert,missing

gen tpricefert = total_valuefert/total_qty
tab tpricefert


gen tpricefert_cens = tpricefert 
replace tpricefert_cens = 600 if tpricefert_cens > 600 & tpricefert_cens < . //winzonrizing at bottom 3%
replace tpricefert_cens = 12 if tpricefert_cens < 12
tab tpricefert_cens, missing  //winzonrizing at top 5%
*graph box total_valuefert if total_valuefert!=0
*hist total_valuefert, normal width(5)



egen medianfert_pr_ea = median(tpricefert_cens), by (ea)

egen medianfert_pr_lga = median(tpricefert_cens), by (lga)

egen num_fert_pr_ea = count(tpricefert_cens), by (ea)

egen num_fert_pr_lga = count(tpricefert_cens), by (lga)

egen medianfert_pr_state = median(tpricefert_cens), by (state)
egen num_fert_pr_state = count(tpricefert_cens), by (state)

egen medianfert_pr_zone = median(tpricefert_cens), by (zone)
egen num_fert_pr_zone = count(tpricefert_cens), by (zone)



tab medianfert_pr_ea
tab medianfert_pr_lga
tab medianfert_pr_state
tab medianfert_pr_zone



tab num_fert_pr_ea
tab num_fert_pr_lga
tab num_fert_pr_state
tab num_fert_pr_zone

gen tpricefert_cens_mrk = tpricefert_cens

replace tpricefert_cens_mrk = medianfert_pr_ea if tpricefert_cens_mrk ==. & num_fert_pr_ea >= 7

tab tpricefert_cens_mrk


replace tpricefert_cens_mrk = medianfert_pr_lga if tpricefert_cens_mrk ==. & num_fert_pr_lga >= 7

tab tpricefert_cens_mrk



replace tpricefert_cens_mrk = medianfert_pr_state if tpricefert_cens_mrk ==. & num_fert_pr_state >= 7

tab tpricefert_cens_mrk


replace tpricefert_cens_mrk = medianfert_pr_zone if tpricefert_cens_mrk ==. & num_fert_pr_zone >= 7
*/
tab tpricefert_cens_mrk

***************
*organic fertilizer
***************
gen org_fert = 1 if  s11dq3==3 | s11dq7==3 | s11dq14==3 |  s11dq25==3
tab org_fert, missing
replace org_fert = 0 if org_fert==.
tab org_fert, missing



collapse zone lga sector ea (sum) total_qty total_valuefert (max)  org_fert tpricefert_cens_mrk, by(hhid)

tab total_qty, missing
tab tpricefert_cens_mrk, missing



merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

************winzonrizing total_qty
foreach v of varlist  total_qty  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 1%"
}


tab total_qty
tab total_qty_w, missing
sum total_qty total_qty_w, detail


/*

************winzonrizing fertilizer market price
foreach v of varlist  tpricefert_cens_mrk  {
	_pctile `v' [aw=weight] , p(5 95) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}

*/
*
gen rea_tpricefert_cens_mrk = tpricefert_cens_mrk   //0.4164266
gen real_tpricefert_cens_mrk = rea_tpricefert_cens_mrk
tab real_tpricefert_cens_mrk
sum real_tpricefert_cens_mrk, detail


keep hhid zone lga sector ea org_fert total_qty_w total_valuefert real_tpricefert_cens_mrk

la var org_fert "1 = if used organic fertilizer"
label var total_qty_w "Total quantity of Commercial Fertilizer Purchased in kg"
label var total_valuefert "Total value of commercial fertilizer purchased in naira"
label var real_tpricefert_cens_mrk "price of commercial fertilizer purchased in naira"
sort hhid
save "${Nigeria_GHS_W1_created_data}\purchasefert.dta", replace



***************************
*Savings 
*************************

use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect4_plantingw1.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

*s4q1  1= formal bank account
*s4q5b  s4q5d   s4q5f  types of formal fin institute used to save 
*s4q6   1= used informal saving group

ren s4q1 formal_bank
tab formal_bank, missing
replace formal_bank =0 if formal_bank ==2 | formal_bank ==.
tab formal_bank, nolabel
tab formal_bank,missing

 gen formal_save = 1 if s4q5b !=. | s4q5d !=.| s4q5f !=.
 tab formal_save, missing
 replace formal_save = 0 if formal_save ==.
 tab formal_save, missing

 ren s4q6 informal_save
 tab informal_save, missing
 replace informal_save =0 if informal_save ==2 | informal_save ==.
 tab informal_save, missing

 collapse (max) formal_bank formal_save informal_save, by (hhid)
 la var formal_bank "=1 if respondent have an account in bank"
 la var formal_save "=1 if used formal saving group"
 la var informal_save "=1 if used informal saving group"
save "${Nigeria_GHS_W1_created_data}\savings.dta", replace



***************************
*Credit access 
***************************

use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect4_plantingw1.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
*s4q8b  s4q8d   s4q8f   types of formal fin institute used to borrow 
*s4q9      1= used inoformal group to borrow money


 gen formal_credit =1 if s4q8b !=. | s4q8d !=. | s4q8f !=.
 tab formal_credit,missing
 replace formal_credit =0 if formal_credit ==.
 tab formal_credit,missing
 
 ren  s4q9 informal_credit
 tab informal_credit, missing
 replace informal_credit =0 if informal_credit ==2 | informal_credit ==.
 tab informal_credit,missing


 collapse (max) formal_credit informal_credit, by (hhid)
 la var formal_credit "=1 if borrowed from formal credit group"
 la var informal_credit "=1 if borrowed from informal credit group"
save "${Nigeria_GHS_W1_created_data}\credit_access.dta", replace


*****************************
*Community 
****************************

use "${Nigeria_GHS_W1_raw_data}\Post Harvest Wave 1\Community\sectc2_harvestw1.dta", clear

*is_cd  219 for market infrastructure
*sc2q3  distance to infrastructure in km

gen mrk_dist = sc2q3 if is_cd==219
tab mrk_dist,missing
egen median_lga = median(mrk_dist), by (zone state lga)
egen median_state = median(mrk_dist), by (zone state)
egen median_zone = median(mrk_dist), by (zone)


replace mrk_dist =0 if is_cd==219 & mrk_dist==. & sc2q1==1
tab mrk_dist if is_cd==219, missing

replace mrk_dist = median_lga if mrk_dist==. & is_cd==219
replace mrk_dist = median_state if mrk_dist==. & is_cd==219
replace mrk_dist = median_zone if mrk_dist==. & is_cd==219
tab mrk_dist if is_cd==219, missing

replace mrk_dist= 45 if mrk_dist>=45 & mrk_dist<. & is_cd==219
tab mrk_dist if is_cd==219, missing

sort zone state ea
collapse (max) median_lga median_state median_zone mrk_dist, by (zone state lga sector ea)
replace mrk_dist = median_lga if mrk_dist ==.
tab mrk_dist, missing
replace mrk_dist = median_lga if mrk_dist ==.
tab mrk_dist, missing



la var mrk_dist "=distance to the market"




save "${Nigeria_GHS_W1_created_data}\market_distance.dta", replace 




***************************** 
*Extension Visit 
*******************************
use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Agriculture\sect11l1_plantingw1.dta", clear
ren s11lq1 ext_acess
preserve



use "${Nigeria_GHS_W1_raw_data}/Post Harvest Wave 1\Agriculture\secta5a_harvestw1.dta", clear
ren sa5aq1 ext_acess
tempfile advie_ph
save `advie_ph'
restore
append using `advie_ph'
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

replace ext_acess =0 if ext_acess ==.
 
collapse (max) ext_acess, by (hhid)
la var ext_acess "=1 if received advise from extension services"
save "${Nigeria_GHS_W1_created_data}\extension_visit.dta", replace 


******************************** 
*Demographics 
*********************************
use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect1_plantingw1.dta", clear

merge 1:1 hhid indiv using "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect2_plantingw1.dta", gen(household)

merge m:1 zone state lga sector ea using "${Nigeria_GHS_W1_created_data}\market_distance.dta", keepusing (median_lga median_state median_zone mrk_dist)

merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
**************
*market distance
*************
replace mrk_dist = median_lga if mrk_dist==.
tab mrk_dist, missing

replace mrk_dist = median_state if mrk_dist==.
tab mrk_dist, missing

replace mrk_dist = median_zone if mrk_dist==.
tab mrk_dist, missing




*s1q2   sex
*s1q3   relationship to hhead
*s1q4   age in years


sort hhid indiv 
 
gen num_mem = 1


******** female head****

gen femhead = 0
replace femhead = 1 if s1q2== 2 & s1q3==1

********Age of HHead***********
ren s1q4 hh_age
gen hh_headage = hh_age if s1q3==1

tab hh_headage

replace hh_headage = 100 if hh_headage > 100 & hh_headage < .
tab hh_headage
tab hh_headage, missing

************generating the median age**************

egen medianhh_pr_ea = median(hh_headage), by (ea)

egen medianhh_pr_lga = median(hh_headage), by (lga)

egen num_hh_pr_ea = count(hh_headage), by (ea)

egen num_hh_pr_lga = count(hh_headage), by (lga)

egen medianhh_pr_state = median(hh_headage), by (state)
egen num_hh_pr_state = count(hh_headage), by (state)

egen medianhh_pr_zone = median(hh_headage), by (zone)
egen num_hh_pr_zone = count(hh_headage), by (zone)


tab medianhh_pr_ea
tab medianhh_pr_lga
tab medianhh_pr_state
tab medianhh_pr_zone



tab num_hh_pr_ea
tab num_hh_pr_lga
tab num_hh_pr_state
tab num_hh_pr_zone



replace hh_headage = medianhh_pr_ea if hh_headage ==. & num_hh_pr_ea >= 30

tab hh_headage,missing


replace hh_headage = medianhh_pr_lga if hh_headage ==. & num_hh_pr_lga >= 30

tab hh_headage,missing



replace hh_headage = medianhh_pr_state if hh_headage ==. & num_hh_pr_state >= 30

tab hh_headage,missing


replace hh_headage = medianhh_pr_zone if hh_headage ==. & num_hh_pr_zone >= 30

tab hh_headage,missing

sum hh_headage, detail



********************Education****************************************************


*s2q4  1= attended school
*s2q7  highest education level
*s1q3 relationship to hhead

ren s2q4 attend_sch
tab attend_sch
replace attend_sch = 0 if attend_sch ==2
tab attend_sch, nolabel
*tab s1q4 if s2q7==.

replace s2q7= 0 if attend_sch==0
tab s2q7
tab s1q3 if _merge==1

tab s2q7 if s1q3==1
replace s2q7 = 16 if s2q7==. &  s1q3==1

*** Education Dummy Variable*****

 label list s2q7

gen pry_edu = 1 if s2q7 >= 1 & s2q7 < 16 & s1q3==1
gen finish_pry = 1 if s2q7 >= 16 & s2q7 < 26 & s1q3==1
gen finish_sec = 1 if s2q7 >= 26 & s2q7 < 43 & s1q3==1

replace pry_edu =0 if pry_edu==. & s1q3==1
replace finish_pry =0 if finish_pry==. & s1q3==1
replace finish_sec =0 if finish_sec==. & s1q3==1
tab pry_edu if s1q3==1 , missing
tab finish_pry if s1q3==1 , missing 
tab finish_sec if s1q3==1 , missing

collapse (sum) num_mem (max) mrk_dist hh_headage femhead attend_sch pry_edu finish_pry finish_sec, by (hhid)


merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1


tab mrk_dist
************winzonrizing distance to market
foreach v of varlist  mrk_dist  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}


tab mrk_dist
tab mrk_dist_w, missing
sum mrk_dist mrk_dist_w, detail


keep hhid mrk_dist_w num_mem femhead hh_headage attend_sch pry_edu finish_pry finish_sec

tab attend_sch, missing
egen mid_attend= median(attend_sch)
replace attend_sch = mid_attend if attend_sch==.
/*
tab pry_edu, missing
tab finish_pry, missing
tab finish_sec, missing

egen mid_pry_edu= median(pry_edu)
egen mid_finish_pry= median(finish_pry)
egen mid_finish_sec= median(finish_sec)

replace pry_edu = mid_pry_edu if pry_edu==.
replace finish_pry = mid_finish_pry if finish_pry==.
replace finish_sec = mid_finish_sec if finish_sec==.
*/

la var num_mem "household size"
la var mrk_dist_w "distance to the nearest market in km"
la var femhead "=1 if head is female"
la var hh_headage "age of household head in years"
la var attend_sch "=1 if respondent attended school"
la var pry_edu "=1 if household head attended pry school"
la var finish_pry "=1 if household head finished pry school"
la var finish_sec "=1 if household head finished sec school"
save "${Nigeria_GHS_W1_created_data}\demographics.dta", replace




********************************* 
*Labor Age 
*********************************
use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect1_plantingw1.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
ren s1q4 hh_age

gen worker = 1
replace worker = 0 if hh_age < 15 | hh_age > 65

tab worker
sort hhid
collapse (sum) worker, by (hhid)
la var worker "number of members age 15 and older and less than 65"
sort hhid

save "${Nigeria_GHS_W1_created_data}\labor_age.dta", replace



********************************
*Safety Net
*****************************
use "${Nigeria_GHS_W1_raw_data}\Post Harvest Wave 1\Household\sect14_harvestw1.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
gen safety_net = 0
replace safety_net =1 if s14q1 ==1
tab safety_net
collapse (max) safety_net, by (hhid)
tab safety_net
la var safety_net "=1 if received cash transfer, cash for work, food for work or other assistance"
save "${Nigeria_GHS_W1_created_data}\safety_net.dta", replace


**************************************
*Food Prices
**************************************


use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Community\sectc2_plantingw1.dta", clear

*s7bq3a   qty purchased by household (7days)
*sc2q3c     units purchased by household (7days)
*s7bq4    cost of purchase by household (7days)




*********Getting the price for maize only**************
//   Unit           Conversion Factor for maize







gen conversion =1
tab conversion, missing
gen food_size=1 //This makes it easy for me to copy-paste existing code rather than having to write a new block
replace conversion = food_size*0.087 if sc2q3c== 1
replace conversion = food_size*0.175 if  sc2q3c== 2		
replace conversion = food_size*0.23 if  sc2q3c== 3
replace conversion = food_size*0.35 if  sc2q3c== 4	
replace conversion = food_size*0.70 if  sc2q3c== 5
replace conversion = food_size*1.50 if  sc2q3c== 6
replace conversion = food_size*3.00 if  sc2q3c== 7
replace conversion = food_size*20.0 if  sc2q3c== 11	
replace conversion = food_size*50.0 if  sc2q3c== 12
replace conversion = food_size*100 if   sc2q3c== 13	
replace conversion = food_size*120 if   sc2q3c== 14
replace conversion = food_size*30.0 if  sc2q3c== 22		
replace conversion = food_size*10.0 if  sc2q3c== 31
replace conversion = food_size*25 if   sc2q3c== 32	
replace conversion = food_size*40 if   sc2q3c== 33
replace conversion = food_size*3.0 if  sc2q3c== 51					
tab conversion, missing	



gen food_price_maize = sc2q3b* conversion if item_cd==12

gen maize_price = sc2q3a/food_price_maize if item_cd==12  

*br  sc2q3b conversion sc2q3c sc2q3a  food_price_maize maize_price item_cd if item_cd<=17

tab maize_price,missing
sum maize_price,detail
tab maize_price

replace maize_price = 270 if maize_price >270 & maize_price<.  //bottom 1%
replace maize_price = 1 if maize_price< 1       ////top 1%



egen median_pr_ea = median(maize_price), by (ea)
egen median_pr_lga = median(maize_price), by (lga)
egen median_pr_state = median(maize_price), by (state)
egen median_pr_zone = median(maize_price), by (zone)

egen num_pr_ea = count(maize_price), by (ea)
egen num_pr_lga = count(maize_price), by (lga)
egen num_pr_state = count(maize_price), by (state)
egen num_pr_zone = count(maize_price), by (zone)

tab num_pr_ea
tab num_pr_lga
tab num_pr_state
tab num_pr_zone


gen maize_price_mr = maize_price

replace maize_price_mr = median_pr_ea if maize_price_mr==. & num_pr_ea>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_lga if maize_price_mr==. & num_pr_lga>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_state if maize_price_mr==. & num_pr_state>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_zone if maize_price_mr==. & num_pr_zone>=2
tab maize_price_mr,missing



*********Getting the price for rice only**************
//   Unit           Conversion Factor for maize






gen food_price_rice = sc2q3b* conversion if item_cd==14

gen rice_price = sc2q3a/food_price_rice if item_cd==14

*br  sc2q3b conversion sc2q3c sc2q3a  food_price_rice rice_price item_cd if item_cd==14

sum rice_price,detail
tab rice_price

replace rice_price = 300 if rice_price >300 & rice_price<.   //bottom 3%
replace rice_price = 25 if rice_price< 25   //top 3%
tab rice_price,missing



egen median_rice_ea = median(rice_price), by (ea)
egen median_rice_lga = median(rice_price), by (lga)
egen median_rice_state = median(rice_price), by (state)
egen median_rice_zone = median(rice_price), by (zone)

egen num_rice_ea = count(rice_price), by (ea)
egen num_rice_lga = count(rice_price), by (lga)
egen num_rice_state = count(rice_price), by (state)
egen num_rice_zone = count(rice_price), by (zone)

tab num_rice_ea
tab num_rice_lga
tab num_rice_state
tab num_rice_zone


gen rice_price_mr = rice_price

replace rice_price_mr = median_rice_ea if rice_price_mr==. & num_rice_ea>=7
tab rice_price_mr,missing

replace rice_price_mr = median_rice_lga if rice_price_mr==. & num_rice_lga>=7
tab rice_price_mr,missing

replace rice_price_mr = median_rice_state if rice_price_mr==. & num_rice_state>=7
tab rice_price_mr,missing

replace rice_price_mr = median_rice_zone if rice_price_mr==. & num_rice_zone>=7
tab rice_price_mr,missing


sort zone state ea
collapse (max) maize_price_mr rice_price_mr  median_pr_lga median_pr_state median_pr_zone median_pr_ea , by (zone state lga sector ea)


save "${Nigeria_GHS_W1_created_data}\food_prices.dta", replace



**************
*Net Buyers and Sellers
***************
use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect7b_plantingw1.dta", clear
merge m:1 zone state lga sector ea using "${Nigeria_GHS_W1_created_data}\food_prices.dta", keepusing (median_pr_ea median_pr_lga median_pr_state median_pr_zone maize_price_mr rice_price_mr)
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

**************
*maize price
*************
//missing values persists even after i did this
replace maize_price_mr = median_pr_ea if maize_price_mr==.
tab maize_price_mr, missing

replace maize_price_mr = median_pr_lga if maize_price_mr==.
tab maize_price_mr, missing

replace maize_price_mr = median_pr_state if maize_price_mr==.
tab maize_price_mr, missing

replace maize_price_mr = median_pr_zone if maize_price_mr==.
tab maize_price_mr, missing


tab rice_price_mr, missing





*s7bq3a from purchases
*s7bq5a from own production

tab s7bq5a
tab s7bq3a

replace s7bq5a = 0 if s7bq5a<=0 |s7bq5a==.
tab s7bq5a,missing
replace s7bq3a = 0 if s7bq3a<=0 |s7bq3a==.
tab s7bq3a,missing

gen net_seller = 1 if s7bq5a > s7bq3a
tab net_seller,missing
replace net_seller=0 if net_seller==.
tab net_seller,missing

gen net_buyer = 1 if s7bq5a < s7bq3a
tab net_buyer,missing
replace net_buyer=0 if net_buyer==.
tab net_buyer,missing


collapse  (max) maize_price_mr rice_price_mr net_seller net_buyer, by(hhid)



gen rea_maize_price_mr = maize_price_mr  //0.4164266
gen real_maize_price_mr = rea_maize_price_mr
tab real_maize_price_mr
sum real_maize_price_mr, detail
gen rea_rice_price_mr = rice_price_mr   //0.4164266
gen real_rice_price_mr = rea_rice_price_mr
tab real_rice_price_mr
sum real_rice_price_mr, detail


label var real_maize_price_mr "commercial price of maize in naira"
label var real_rice_price_mr "commercial price of rice in naira"
la var net_seller "1= if respondent is a net seller"
la var net_buyer "1= if respondent is a net buyer"
sort hhid
save "${Nigeria_GHS_W1_created_data}\net_buyer_seller.dta", replace



/*
************************************
*cpi
********************************
  wbopendata, language(en - English) country() topics() indicator(fp.cpi.totl) clear
*save a copy for use off-line
  *save "wbopendata_cpi_timeseries.dta", replace

*use "wbopendata_cpi_timeseries.dta", clear

*keep SSA
keep if inlist(region,"SSF")
	*does the same thing: keep if regioncode=="SSF"

*keep our study countries
keep if inlist(countrycode,"NGA")
	* does the same thing: drop if !(inlist(countrycode,"TZA"))


*drop very old years
drop yr1960-yr1989

*take a look at recent values (note these all use 2010 as base year)
l countrycode yr2004-yr2017

*rebase to 2015
gen baseyear = yr2023
forvalues i=1990(1)2023 {
	replace yr`i' = yr`i'/baseyear
}
forvalues i=1990(1)2023 {
	di "year is: `i'" 
}


*reformat to match panel structure 
reshape long yr, i(countrycode) j(year)
rename yr cpi
keep countrycode countryname year cpi
order countrycode countryname year cpi
la var year "Year"
la var cpi "CPI (base=2023)"


*save for use in analysis
*save "tza_cpi_b2019.dta", replace


*/

















*****************************
*Household Assests
****************************


use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect5_plantingw1.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
sort hhid item_cd

collapse (sum) s5q1, by (zone state lga ea hhid item_cd)
tab item_cd
save "${Nigeria_GHS_W1_created_data}\assest_qty.dta", replace

use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect5b_plantingw1.dta", clear

collapse (mean) s5q4, by (zone state lga ea hhid item_cd)
tab item_cd
save "${Nigeria_GHS_W1_created_data}\assest_cost.dta", replace

*******************Merging assest***********************
sort hhid item_cd
merge 1:1 hhid item_cd using "${Nigeria_GHS_W1_created_data}\assest_qty.dta", keepusing(zone state lga ea s5q1)

drop _merge

merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
gen hhasset_value = s5q4*s5q1


tab hhasset_value
/*
replace hhasset_value=. if hhasset_value==0
replace hhasset_value= 5700000 if hhasset_value> 5700000 & hhasset_value<.
tab hhasset_value, missing
*/
sum hhasset_value, detail







collapse (sum) hhasset_value, by (hhid)

merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1


foreach v of varlist  hhasset_value  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}


tab hhasset_value
tab hhasset_value_w, missing
sum hhasset_value hhasset_value_w, detail


*Winzorized variables**

*winsor2 hhasset_value, suffix(_s) cuts(5 95) 

*summarize  hhasset_value_w hhasset_value_s , detail

gen rea_hhvalue = hhasset_value_w   //0.4164266
gen real_hhvalue = rea_hhvalue/1000
sum hhasset_value_w real_hhvalue, detail


keep  hhid real_hhvalue
la var real_hhvalue "total value of household asset"
save "${Nigeria_GHS_W1_created_data}\assest_value.dta", replace





 ********************************************************************************
* PLOT AREAS *
********************************************************************************
*starting with planting
clear


*using conversion factors from LSMS-ISA Nigeria Wave 2 Basic Information Document (Waves 1 & 2 are identical)
*found at http://econ.worldbank.org/WBSITE/EXTERNAL/EXTDEC/EXTRESEARCH/EXTLSMS/0,,contentMDK:23635560~pagePK:64168445~piPK:64168309~theSitePK:3358997,00.html
*General Conversion Factors to Hectares
//		Zone   Unit         Conversion Factor
//		All    Plots        0.0667
//		All    Acres        0.4
//		All    Hectares     1
//		All    Sq Meters    0.0001
*Zone Specific Conversion Factors to Hectares
//		Zone           Conversion Factor
//				 Heaps      Ridges      Stands
//		1 		 0.00012 	0.0027 		0.00006
//		2 		 0.00016 	0.004 		0.00016
//		3 		 0.00011 	0.00494 	0.00004
//		4 		 0.00019 	0.0023 		0.00004
//		5 		 0.00021 	0.0023 		0.00013
//		6  		 0.00012 	0.00001 	0.00041
set obs 42 //6 zones x 7 units
egen zone=seq(), f(1) t(6) b(7)
egen area_unit=seq(), f(1) t(7)
gen conversion=1 if area_unit==6
gen area_size=1 //This makes it easy for me to copy-paste existing code rather than having to write a new block
replace conversion = area_size*0.0667 if area_unit==4									//reported in plots
replace conversion = area_size*0.404686 if area_unit==5		    						//reported in acres
replace conversion = area_size*0.0001 if area_unit==7									//reported in square meters

replace conversion = area_size*0.00012 if area_unit==1 & zone==1						//reported in heaps
replace conversion = area_size*0.00016 if area_unit==1 & zone==2
replace conversion = area_size*0.00011 if area_unit==1 & zone==3
replace conversion = area_size*0.00019 if area_unit==1 & zone==4
replace conversion = area_size*0.00021 if area_unit==1 & zone==5
replace conversion = area_size*0.00012 if area_unit==1 & zone==6

replace conversion = area_size*0.0027 if area_unit==2 & zone==1							//reported in ridges
replace conversion = area_size*0.004 if area_unit==2 & zone==2
replace conversion = area_size*0.00494 if area_unit==2 & zone==3
replace conversion = area_size*0.0023 if area_unit==2 & zone==4
replace conversion = area_size*0.0023 if area_unit==2 & zone==5
replace conversion = area_size*0.00001 if area_unit==2 & zone==6

replace conversion = area_size*0.00006 if area_unit==3 & zone==1						//reported in stands
replace conversion = area_size*0.00016 if area_unit==3 & zone==2
replace conversion = area_size*0.00004 if area_unit==3 & zone==3
replace conversion = area_size*0.00004 if area_unit==3 & zone==4
replace conversion = area_size*0.00013 if area_unit==3 & zone==5
replace conversion = area_size*0.00041 if area_unit==3 & zone==6

drop area_size
save "${Nigeria_GHS_W1_created_data}\land_cf.dta", replace

 
 
 
 
 
 
*********************
*Plot Size 
**********************

use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Agriculture\sect11a1_plantingw1.dta", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using  "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Agriculture\sect11b_plantingw1.dta"
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W1_raw_data}\Post Harvest Wave 1\Agriculture\secta1_harvestw1.dta", gen(plot_merge)
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
 
ren s11aq4a area_size
ren s11aq4b area_unit
ren sa1q9a area_size2
ren sa1q9b area_unit2
ren s11aq4d area_meas_sqm
ren sa1q9d area_meas_sqm2

*If land was cultivated by household, then cultivate is equal to 1
gen cultivate = s11bq16 ==1 
tab cultivate
*assuming new plots are cultivated
replace cultivate = 1 if sa1q3==1
tab cultivate


******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W1_created_data}\land_cf.dta", nogen keep(1 3) 


 
 *farmer reported field size for post-planting
gen field_size= area_size*conversion
 sum field_size, detail
*replacing farmer reported with GPS if
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.  
 sum field_size, detail 
 
 gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
tab gps_meas
 
 
 
 ***************Measurement in hectares for the additional plots from post-harvest************
 *farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit
******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W1_created_data}\land_cf.dta", nogen keep(1 3) 

replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.               
la var field_size "Area of plot (ha)"
ren plotid plot_id
sum field_size, detail
*Total land holding including cultivated and rented out
collapse (sum) field_size, by (hhid)


merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1


foreach v of varlist  field_size  {
	_pctile `v' [aw=weight] , p(5 99) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top 5% & bottom 1%"
}

tab field_size
tab field_size_w, missing
sum field_size field_size_w, detail









sort hhid
ren field_size_w land_holding
keep hhid land_holding
label var land_holding "land holding in hectares"
save "${Nigeria_GHS_W1_created_data}\land_holdings.dta", replace

 









************************* Merging Agricultural Datasets ********************

use "${Nigeria_GHS_W1_created_data}\purchasefert.dta", replace


*******All observations Merged*****


merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}\subsidized_fert.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/weight.dta"
drop _merge
sort hhid

merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}\savings.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}\credit_access.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}\extension_visit.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}\demographics.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}\labor_age.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}\safety_net.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}\assest_value.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}\net_buyer_seller.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}\geodata.dta"
drop _merge
sort hhid
merge 1:1 hhid using "C:\Users\obine\Music\Documents\Smallholder lsms STATA\analyzed_data\nga_wave2012\soil_quality_2012.dta"

drop if _merge==2
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}\land_holdings.dta"
drop _merge
gen year = 2010
sort hhid
order year



tabstat total_qty_w subsidy_qty_w dist_market_w mrk_dist_w real_tpricefert_cens_mrk num_mem hh_headage real_hhvalue worker real_maize_price_mr real_rice_price_mr land_holding [aweight = weight], statistics( mean median sd min max ) columns(statistics)

*soil_qty_rev2 soil_qty_rev2 hhasset_value

misstable summarize total_qty_w subsidy_qty_w mrk_dist_w real_tpricefert_cens_mrk num_mem hh_headage real_hhvalue worker real_maize_price_mr real_rice_price_mr land_holding subsidy_dummy femhead informal_save formal_credit informal_credit ext_acess attend_sch pry_edu finish_pry finish_sec safety_net net_seller net_buyer 

egen median_maize = median(real_maize_price_mr)
replace real_maize_price_mr = median_maize if real_maize_price_mr==.

egen median_rice = median (real_rice_price_mr)
replace real_rice_price_mr = median_rice if real_rice_price_mr==.

egen median_dist = median (mrk_dist_w)
replace mrk_dist_w = median_dist if mrk_dist_w==.

egen median_real_tpricefert_cens_mrk = median(real_tpricefert_cens_mrk)
replace real_tpricefert_cens_mrk = median_real_tpricefert_cens_mrk if real_tpricefert_cens_mrk==.


misstable summarize total_qty_w subsidy_qty_w mrk_dist_w real_tpricefert_cens_mrk num_mem hh_headage real_hhvalue worker real_maize_price_mr real_rice_price_mr land_holding subsidy_dummy femhead informal_save formal_credit informal_credit ext_acess attend_sch pry_edu finish_pry finish_sec safety_net net_seller net_buyer 


proportion subsidy_dummy femhead informal_save formal_credit informal_credit ext_acess attend_sch pry_edu finish_pry finish_sec safety_net net_seller net_buyer soil_qty_rev2

save "${Nigeria_GHS_W1_created_data}\Nigeria_wave1_complete_datan.dta", replace

