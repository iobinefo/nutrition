






clear

global Nigeria_GHS_W2_raw_data 		"C:\Users\obine\Music\Documents\Smallholder lsms STATA\NGA_2012_GHSP-W2_v02_M_STATA_Copy" 
global Nigeria_GHS_W2_created_data  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_two"



********************************************************************************
* AG FILTER *
********************************************************************************

use "${Nigeria_GHS_W2_raw_data}/Post Planting Wave 2\Agriculture\sect11a_plantingw2.dta" , clear

keep hhid s11aq1
rename (s11aq1) (ag_rainy_12)
save  "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", replace



*merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

*keep if ag_rainy_12==1




********************************************************************************
* WEIGHTS *
********************************************************************************

use "${Nigeria_GHS_W2_raw_data}/Post Planting Wave 2\Household\secta_plantingw2.dta" , clear
merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave2 rural
ren wt_wave2 weight
collapse (max) weight, by (hhid)
save  "${Nigeria_GHS_W2_created_data}/weight.dta", replace






********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
global Nigeria_GHS_W2_exchange_rate 401.15  		// https://www.bloomberg.com/quote/USDETB:CUR, https://data.worldbank.org/indicator/PA.NUS.FCRF?end=2023&locations=NG&start=2011
// {2017:315,2021:401.15}
global Nigeria_GHS_W2_gdp_ppp_dollar  146.72		// https://data.worldbank.org/indicator/PA.NUS.PRVT //2021
global Nigeria_GHS_W2_cons_ppp_dollar  155.72		// https://data.worldbank.org/indicator/PA.NUS.PRVT.P //2021
global Nigeria_GHS_W2_inflation 0.380751		// 2017: 134.9/214.2, 2021: 134.9/354.3 inflation rate 2013-2016. Data was collected during 2012-2013. We want to ajhust value to 2017


//Poverty threshold calculation
//Per W3, we convert WB's international poverty threshold to 2011$ using the PA.NUS.PRVT.PP WB info then inflate to the last year of the survey using CPI
global Nigeria_GHS_W2_poverty_190 ((1.90*83.58) * (134.9/110.8))
global Nigeria_GHS_W2_poverty_npl (376.52 * $Nigeria_GHS_W2_inflation ) //ALT: To do: adjust for inflation
global Nigeria_GHS_W2_poverty_215 (2.15*(0.587791 * 112.0983276))  //New 2023 WB poverty threshold
global Nigeria_GHS_W2_poverty_300 (3*($Nigeria_GHS_W2_inflation * $Nigeria_GHS_W2_cons_ppp_dollar ))  //New 2025 WB poverty threshold

********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables



*DYA.11.1.2020 Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Nigeria_GHS_W2_pop_tot 170075932
global Nigeria_GHS_W2_pop_rur 93123376
global Nigeria_GHS_W2_pop_urb 76952556

/*
********************************************************************************
*PRIORITY CROPS //change these globals if you are interested in a different crop
********************************************************************************
////Limit crop names in variables to 6 characters or the variable names will be too long! 
global topcropname_area "maize rice sorgum millet cowpea grdnt yam swtptt cassav banana cocoa soy" 
global comma_topcrop_area "1080, 1110, 1070, 1100, 1010, 1060, 1120, 2181, 1020, 2030, 3040, 2220"
global topcrop_area = subinstr("$comma_topcrop_area",","," ",.) //removing commas from the list above
global nb_topcrops : list sizeof global(topcropname_area) // Gets the current length of the global macro list "topcropname_area" 
display "$nb_topcrops"
global nb_topcrops : list sizeof global(topcropname_area) // Gets the current length of the global macro list "topcropname_area" 
set obs $nb_topcrops //Update if number of crops changes
egen rnum = seq(), f(1) t($nb_topcrops)
gen crop_code = .
gen crop_name = ""
forvalues k=1(1)$nb_topcrops {
	local c : word `k' of $topcrop_area
	local cn : word `k' of $topcropname_area 
	replace crop_code = `c' if rnum==`k'
	replace crop_name = "`cn'" if rnum==`k'
}
drop rnum
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_cropname_table.dta", replace //This gets used to generate the monocrop files.
*/





********************************************************************************
* CONSUMPTION *
********************************************************************************





********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Nigeria_GHS_W2_raw_data}/HHTrack.dta", clear
keep if (hhstatus_w2v1==1 | hhstatus_w2v1==5) & (hhstatus_w2v2==1 | hhstatus_w2v2==5)
gen filesource=1
append using "${Nigeria_GHS_W2_raw_data}/secta_plantingw2.dta"
replace filesource=2 if file==.
gen rural = (sector==2)
lab var rural "1= Rural"
//keep hhid zone state lga ea wt_wave2 rural
ren wt_wave2 weight
replace weight = wt_w2v1 if weight==.
replace weight= wt_w2v2 if weight==.
collapse (mean) weight (max) ea rural filesource, by(hhid zone state lga) //A few households reported as moving or with inconsistent urban/rural assignments
//Some households moved from the hhtrack location, leading to duplicates. We'll take the moved location.
duplicates tag hhid, g(dupes)
drop if dupes & file==1
drop dupes file
recast double weight
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_hhids.dta", replace






********************************************************************************
* INDIVIDUAL IDS *
********************************************************************************
use "${Nigeria_GHS_W2_raw_data}/sect1_plantingw2.dta", clear
gen season="plan"
append using "${Nigeria_GHS_W2_raw_data}/sect1_harvestw2.dta", force
replace season="harv" if season==""
*keep if s1q4==1 //Drop individuals who've left household   // AYW_3.5.20 This question wasn't asked of all individuals. 
gen member = s1q4
replace member = 1 if s1q3 != . 
drop if member!=1
gen female= s1q2==2
gen fhh = s1q3==1 & female
recode fhh (.=0)
preserve 
collapse (max) fhh, by(hhid)
tempfile fhh
save `fhh'
restore 
la var female "1= individual is female"
ren s1q6 age
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
//merge m:1 hhid using  "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_hhids.dta", keep(2 3) nogen  // keeping hh surveyed //Dropping households with recorded harvest info.
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_person_ids.dta", replace




















































************************
*Geodata Variables
************************

use "${Nigeria_GHS_W2_raw_data}\Geodata Wave 2\NGA_PlotGeovariables_Y2.dta", clear

collapse (max) srtmslp_nga srtm_nga twi_nga, by (hhid)

merge 1:m hhid using "${Nigeria_GHS_W2_raw_data}\Geodata Wave 2\NGA_HouseholdGeovars_Y2.dta"

merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1

ren dist_market dist_market
sum dist_market, detail


collapse (max) dist_market, by (hhid)
sort hhid



merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1

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

keep hhid dist_market_w

save "${Nigeria_GHS_W2_created_data}\geodata_2012.dta", replace







****************************
*Subsidized Fertilizer
****************************


use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11d_plantingw2.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1
*************Checking to confirm its the subsidized price *******************

*s11dq14 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq26 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq16 s11dq28  qty of inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer






encode s11dq14, gen(institute)
label list institute


encode s11dq26, gen(institute2)
label list institute2




gen pricefert = s11dq19/ s11dq16


gen subsidy_check = pricefert if institute ==1
sum subsidy,detail


gen private_check = pricefert if institute ==4
sum private,detail




*N2 AND N3 IS 4 AND 5 WHILE N1 IS 1
*institute2 is N2 AND N3 2 and 3 WHILE N1 IS 1


*************Getting Subsidized quantity and Dummy Variable *******************
gen subsidy_qty1 = s11dq16 if institute ==4 | institute ==5 //6 
tab subsidy_qty1
gen subsidy_qty2 = s11dq28 if institute2 ==2 | institute2 ==3  //
tab subsidy_qty2


egen subsidy_qty = rowtotal(subsidy_qty1 subsidy_qty2)
tab subsidy_qty,missing
sum subsidy_qty,detail


gen subsidy_dummy = (subsidy_qty !=0)

tab subsidy_dummy, missing

collapse (sum)subsidy_qty (max) subsidy_dummy, by (hhid)



merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1

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







keep hhid  subsidy_qty_w

save "${Nigeria_GHS_W2_created_data}\subsidized_fert_2012.dta", replace




***************************************************
*Transport Cost
***************************************************



use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11d_plantingw2.dta",clear  
merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1


encode s11dq14, gen(institute)
label list institute


encode s11dq26, gen(institute2)
label list institute2

gen tp1 = s11dq17 if institute ==1
tab tp1
gen tp2 = s11dq31  if institute2 ==1
tab tp2

egen transport = rowtotal(tp1 tp2)



collapse  (sum) transport, by(hhid)
merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)
merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1


************winzonrizing fertilizer market price
foreach v of varlist  transport  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}

sum transport transport_w, detail

gen transport_cost = transport_w    /0.5179256
sum transport_cost, detail
keep hhid transport_cost

save "${Nigeria_GHS_W2_created_data}\transport.dta", replace




*********************************************** 
*Purchased Fertilizer
***********************************************

use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11d_plantingw2.dta",clear  
merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1
*s11dq14 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq26 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq16 s11dq28  qty of inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer




encode s11dq14, gen(institute)
label list institute


encode s11dq26, gen(institute2)
label list institute2




***fertilzer total quantity, total value & total price****

gen private_fert1_qty = s11dq16 if institute ==1
tab private_fert1_qty, missing
gen private_fert2_qty = s11dq28 if institute2 ==1
tab private_fert2_qty,missing

gen private_fert1_val = s11dq19 if institute ==1
tab private_fert1_val,missing
gen private_fert2_val = s11dq29 if institute2 ==1
tab private_fert2_val,missing

egen total_qty = rowtotal(private_fert1_qty private_fert2_qty)
tab  total_qty, missing

egen total_valuefert = rowtotal(private_fert1_val private_fert2_val)
tab total_valuefert,missing

gen tpricefert = total_valuefert/total_qty
tab tpricefert



gen tpricefert_cens = tpricefert
replace tpricefert_cens = 600 if tpricefert_cens > 600 & tpricefert_cens < . //winzorizing at top 5%
replace tpricefert_cens = 12 if tpricefert_cens < 12
tab tpricefert_cens, missing  //winzorizing at bottom 5%


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

tab tpricefert_cens_mrk,missing


replace tpricefert_cens_mrk = medianfert_pr_lga if tpricefert_cens_mrk ==. & num_fert_pr_lga >= 7

tab tpricefert_cens_mrk,missing



replace tpricefert_cens_mrk = medianfert_pr_state if tpricefert_cens_mrk ==. & num_fert_pr_state >= 7

tab tpricefert_cens_mrk,missing


replace tpricefert_cens_mrk = medianfert_pr_zone if tpricefert_cens_mrk ==. & num_fert_pr_zone >= 7
*/
tab tpricefert_cens_mrk,missing


***************
*organic fertilizer
***************
gen org_fert = 1 if  s11dq3==3 | s11dq7==3 | s11dq15==3 |  s11dq27==3
tab org_fert, missing
replace org_fert = 0 if org_fert==.
tab org_fert, missing




collapse zone lga sector ea (sum) total_qty total_valuefert (max)  org_fert tpricefert_cens_mrk, by(hhid)


merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)
merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1



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




************winzonrizing fertilizer market price
foreach v of varlist  tpricefert_cens_mrk  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}

sum tpricefert_cens_mrk tpricefert_cens_mrk_w, detail

gen rea_tpricefert_cens_mrk = tpricefert_cens_mrk_w   /0.5179256
gen real_tpricefert_cens_mrk = rea_tpricefert_cens_mrk
replace real_tpricefert_cens_mrk= 364 if hhid == 10062 
replace real_tpricefert_cens_mrk= 286 if hhid == 20064 
tab real_tpricefert_cens_mrk
sum real_tpricefert_cens_mrk, detail


keep hhid zone lga sector ea org_fert total_qty_w total_valuefert real_tpricefert_cens_mrk

sort hhid
save "${Nigeria_GHS_W2_created_data}\purchased_fert_2012.dta", replace




******************************* 
*Extension Visit 
*******************************



use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11l1_plantingw2.dta",clear  

merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1

ren s11l1q1 ext_acess

tab ext_acess, missing
tab ext_acess, nolabel

replace ext_acess = 0 if ext_acess==2 | ext_acess==.
tab ext_acess, missing
collapse (max) ext_acess, by (hhid)
la var ext_acess "=1 if received advise from extension services"
save "${Nigeria_GHS_W2_created_data}\extension_visit_2012.dta", replace





*****************************
*Community 
****************************

use "${Nigeria_GHS_W2_raw_data}\Post Harvest Wave 2\Community\sectc2_harvestw2.dta", clear

*is_cd  219 for market infrastructure
*c2q3  distance to infrastructure in km

gen mrk_dist = c2q3 if is_cd==219
tab mrk_dist,missing
egen median_lga = median(mrk_dist), by (zone state lga)
egen median_state = median(mrk_dist), by (zone state)
egen median_zone = median(mrk_dist), by (zone)


replace mrk_dist =0 if is_cd==219 & mrk_dist==. & c2q1==1
tab mrk_dist if is_cd==219, missing

replace mrk_dist = median_lga if mrk_dist==. & is_cd==219
replace mrk_dist = median_state if mrk_dist==. & is_cd==219
replace mrk_dist = median_zone if mrk_dist==. & is_cd==219
tab mrk_dist if is_cd==219, missing

*replace mrk_dist= 45 if mrk_dist>=45 & mrk_dist<. & is_cd==219
*tab mrk_dist if is_cd==219, missing

sort zone state ea
collapse (max) median_lga median_state median_zone mrk_dist, by (zone state lga sector ea)
replace mrk_dist = median_lga if mrk_dist ==.
tab mrk_dist, missing
replace mrk_dist = median_state if mrk_dist ==.
tab mrk_dist, missing
replace mrk_dist = median_zone if mrk_dist ==.
tab mrk_dist, missing
la var mrk_dist "=distance to the market"

save "${Nigeria_GHS_W2_created_data}\market_distance.dta", replace 






*********************************
*Demographics 
*********************************

use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Household\sect1_plantingw2.dta",clear 

merge 1:1 hhid indiv using "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Household\sect2_plantingw2.dta", gen(household)

merge m:1 zone state lga sector ea using "${Nigeria_GHS_W2_created_data}\market_distance.dta", keepusing (median_lga median_state median_zone mrk_dist)
merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1

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
*s1q6   age in years




sort hhid indiv 
 
gen num_mem = 1



******** female head****

gen femhead = 0
replace femhead = 1 if s1q2== 2 & s1q3==1
tab femhead,missing

********Age of HHead***********
ren s1q6 hh_age
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

*s2q5  1= attended school
*s2q8  highest education level
*s1q3 relationship to hhead


ren s2q5 attend_sch
tab attend_sch
replace attend_sch = 0 if attend_sch ==2
tab attend_sch, nolabel
*tab s1q4 if s2q7==.

replace s2q8= 0 if attend_sch==0
tab s2q8
tab s1q3 if _merge==1

tab s2q8 if s1q3==1
replace s2q8 = 16 if s2q8==. &  s1q3==1

*** Education Dummy Variable*****

 label list S2Q8

gen pry_edu = 1 if s2q8 >= 1 & s2q8 < 16 & s1q3==1
gen finish_pry = 1 if s2q8 >= 16 & s2q8 < 26 & s1q3==1
gen finish_sec = 1 if s2q8 >= 26 & s2q8 < 43 & s1q3==1

replace pry_edu =0 if pry_edu==. & s1q3==1
replace finish_pry =0 if finish_pry==. & s1q3==1
replace finish_sec =0 if finish_sec==. & s1q3==1
tab pry_edu if s1q3==1 , missing
tab finish_pry if s1q3==1 , missing 
tab finish_sec if s1q3==1 , missing

collapse (sum) num_mem (max) mrk_dist hh_headage femhead attend_sch pry_edu finish_pry finish_sec, by (hhid)

merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1


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

tab pry_edu, missing
tab finish_pry, missing
tab finish_sec, missing

egen mid_pry_edu= median(pry_edu)
egen mid_finish_pry= median(finish_pry)
egen mid_finish_sec= median(finish_sec)

replace pry_edu = mid_pry_edu if pry_edu==.
replace finish_pry = mid_finish_pry if finish_pry==.
replace finish_sec = mid_finish_sec if finish_sec==.



la var num_mem "household size"
la var mrk_dist_w "distance to the nearest market in km"
la var femhead "=1 if head is female"
la var hh_headage "age of household head in years"
la var attend_sch "=1 if respondent attended school"
la var pry_edu "=1 if household head attended pry school"
la var finish_pry "=1 if household head finished pry school"
la var finish_sec "=1 if household head finished sec school"
save "${Nigeria_GHS_W2_created_data}\demographics_2012.dta", replace


**************************************
*Food Prices
**************************************
use "${Nigeria_GHS_W2_raw_data}\Post Harvest Wave 2\Community\sectc8_harvestw2.dta", clear



gen maize_price=c8q2 if item_cd==3
tab maize_price,missing
sum maize_price,detail
tab maize_price

replace maize_price = 900 if maize_price >900 & maize_price<.  //bottom 2%



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



****************
*rice price
***************


gen rice_price=c8q2 if item_cd==7
tab rice_price,missing
sum rice_price,detail
tab rice_price

replace rice_price = 750 if rice_price >750 & rice_price<.   //top 2%
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

replace rice_price_mr = median_rice_ea if rice_price_mr==. & num_rice_ea>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_lga if rice_price_mr==. & num_rice_lga>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_state if rice_price_mr==. & num_rice_state>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_zone if rice_price_mr==. & num_rice_zone>=2
tab rice_price_mr,missing


sort zone state ea
collapse (max) maize_price_mr rice_price_mr , by (zone state lga sector ea)


save "${Nigeria_GHS_W2_created_data}\food_prices.dta", replace

use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Household\sect7b_plantingw2.dta", clear
merge m:1 zone state lga sector ea using "${Nigeria_GHS_W2_created_data}\food_prices.dta", keepusing ( maize_price_mr rice_price_mr)
merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1
**********
*maize
*********
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



replace maize_price_mr = median_pr_ea if maize_price_mr==. & num_pr_ea>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_lga if maize_price_mr==. & num_pr_lga>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_state if maize_price_mr==. & num_pr_state>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_zone if maize_price_mr==. & num_pr_zone>=2
tab maize_price_mr,missing


****************
*rice price
***************


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



replace rice_price_mr = median_rice_ea if rice_price_mr==. & num_rice_ea>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_lga if rice_price_mr==. & num_rice_lga>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_state if rice_price_mr==. & num_rice_state>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_zone if rice_price_mr==. & num_rice_zone>=2
tab rice_price_mr,missing

collapse  (max) maize_price_mr rice_price_mr, by(hhid)

gen rea_maize_price_mr = maize_price_mr   /0.5179256
gen real_maize_price_mr = rea_maize_price_mr
tab real_maize_price_mr
sum real_maize_price_mr, detail
gen rea_rice_price_mr = rice_price_mr   /0.5179256
gen real_rice_price_mr = rea_rice_price_mr
tab real_rice_price_mr
sum real_rice_price_mr, detail

sort hhid
save "${Nigeria_GHS_W2_created_data}\food_prices_2012.dta", replace





*****************************
*Household Assests
****************************



use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Household\sect5a_plantingw2.dta",clear 

sort hhid item_cd

collapse (sum) s5q1, by (zone state lga ea hhid item_cd)
tab item_cd,missing
save "${Nigeria_GHS_W2_created_data}\item_qty_2012.dta", replace


use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Household\sect5b_plantingw2.dta",clear 
sort hhid item_cd
collapse (mean) s5q4, by (zone state lga ea hhid item_cd)
tab item_cd
save "${Nigeria_GHS_W2_created_data}\item_cost_2012.dta", replace

*******************Merging assest***********************
sort hhid item_cd
merge 1:1 hhid item_cd using "${Nigeria_GHS_W2_created_data}\item_qty_2012.dta", keepusing (zone state lga ea s5q1)
drop _merge
merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1
gen hhasset_value = s5q4*s5q1
tab hhasset_value


replace hhasset_value=. if hhasset_value==0

/*
replace hhasset_value = 1000000 if hhasset_value > 1000000 & hhasset_value <.  //bottom 2%
replace hhasset_value = 100 if hhasset_value <100  //top 2%
*/

sum hhasset_value, detail

tab hhasset_value,missing





collapse (sum) hhasset_value, by (hhid)


merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1


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

gen rea_hhvalue = hhasset_value_w    /0.5179256
gen real_hhvalue = rea_hhvalue/1000
sum hhasset_value_w real_hhvalue, detail


keep  hhid real_hhvalue


la var real_hhvalue "total value of household asset"
save "${Nigeria_GHS_W2_created_data}\asset_value_2012.dta", replace





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
save "${Nigeria_GHS_W2_created_data}\land_cf.dta", replace

 
 
 
 
 
 
 *************** Plot Size **********************

use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11a1_plantingw2",clear  
*merging in planting section to get cultivated status

merge 1:1 hhid plotid using  "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11b1_plantingw2"
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W2_raw_data}\Post Harvest Wave 2\Agriculture\secta1_harvestw2.dta", gen(plot_merge)

merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1
ren s11aq4a area_size
ren s11aq4b area_unit
ren sa1q9a area_size2
ren sa1q9b area_unit2
ren s11aq4c area_meas_sqm
ren sa1q9c area_meas_sqm2
gen cultivate = s11b1q27 ==1 
*assuming new plots are cultivated
replace cultivate = 1 if sa1q3==1

******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}\land_cf.dta", nogen keep(1 3) 


gen field_size= area_size*conversion
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
 
 
 ***************Measurement in hectares for the additional plots from post-harvest************
 *farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit
******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}\land_cf.dta", nogen keep(1 3) 


replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.                
la var field_size "Area of plot (ha)"
ren plotid plot_id
sum field_size, detail
*Total land holding including cultivated and rented out
collapse (sum) field_size, by (hhid)

merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1

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
save "${Nigeria_GHS_W2_created_data}\land_holding_2012.dta", replace

 




*******************************
*Soil Quality
*******************************

use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11a1_plantingw2",clear  
*merging in planting section to get cultivated status

merge 1:1 hhid plotid using  "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11b1_plantingw2"
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W2_raw_data}\Post Harvest Wave 2\Agriculture\secta1_harvestw2.dta", gen(plot_merge)

merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1
ren s11aq4a area_size
ren s11aq4b area_unit
ren sa1q9a area_size2
ren sa1q9b area_unit2
ren s11aq4c area_meas_sqm
ren sa1q9c area_meas_sqm2
gen cultivate = s11b1q27 ==1 
*assuming new plots are cultivated
replace cultivate = 1 if sa1q3==1

******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}\land_cf.dta", nogen keep(1 3) 


gen field_size= area_size*conversion
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
 
 
 ***************Measurement in hectares for the additional plots from post-harvest************
 *farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit
******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}\land_cf.dta", nogen keep(1 3) 


replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.                
la var field_size "Area of plot (ha)"
sum field_size, detail
*Total land holding including cultivated and rented out
keep zone state lga sector ea hhid plotid field_size

merge 1:1 hhid plotid using "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11b1_plantingw2.dta"

merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

keep if ag_rainy_12==1
ren s11b1q45 soil_quality
tab soil_quality, missing



egen max_fieldsize = max(field_size), by (hhid)
replace max_fieldsize= . if max_fieldsize!= max_fieldsize
order field_size soil_quality hhid max_fieldsize
sort hhid
keep if field_size== max_fieldsize
sort hhid plotid field_size

duplicates report hhid

duplicates tag hhid, generate(dup)
tab dup
list field_size soil_quality dup


list hhid plotid field_size soil_quality dup if dup>0

egen soil_qty_rev = max(soil_quality) 
gen soil_qty_rev3 = soil_quality

replace soil_qty_rev3 = soil_qty_rev if dup>0

list hhid plotid  field_size soil_quality soil_qty_rev soil_qty_rev3 dup if dup>0


gen good_soil = (soil_qty_rev3==1)
gen fairr_soil = (soil_qty_rev3==2)
egen med_soil = median(soil_qty_rev3)

egen med_soil_ea = median(soil_qty_rev3), by (ea)
egen med_soil_lga = median(soil_qty_rev3), by (lga)
egen med_soil_state = median(soil_qty_rev3), by (state)
egen med_soil_zone = median(soil_qty_rev3), by (zone)

replace soil_qty_rev3= med_soil_ea if soil_qty_rev3==.
tab soil_qty_rev3, missing
replace soil_qty_rev3= med_soil_lga if soil_qty_rev3==.
tab soil_qty_rev3, missing
replace soil_qty_rev3= med_soil_state if soil_qty_rev3==.
tab soil_qty_rev3, missing
replace soil_qty_rev3= med_soil_zone if soil_qty_rev3==.
tab soil_qty_rev3, missing


replace soil_qty_rev3= med_soil if soil_qty_rev3==.
tab soil_qty_rev3, missing

tab zone if soil_qty_rev3== 1

collapse (mean) soil_qty_rev3 (max) good_soil fairr_soil , by (hhid)
save "${Nigeria_GHS_W2_created_data}\soil_quality_2012.dta", replace












************************* Merging Agricultural Datasets ********************

use "${Nigeria_GHS_W2_created_data}\purchased_fert_2012.dta", replace


*******All observations Merged*****


merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}\subsidized_fert_2012.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}\weight.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}\extension_visit_2012.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}\demographics_2012.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}\food_prices_2012.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}\geodata_2012.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}\soil_quality_2012.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}\asset_value_2012.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}\land_holding_2012.dta"
drop _merge
gen year = 2012
sort hhid

drop if hhid == 310100 //didnt report price****
drop if hhid == 340089 //didnt report price****



tabstat total_qty_w real_tpricefert_cens_mrk subsidy_qty_w dist_market_w real_maize_price_mr real_rice_price_mr land_holding real_hhvalue org_fert hh_headage attend_sch femhead num_mem ext_acess [aweight = weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize total_qty_w real_tpricefert_cens_mrk subsidy_qty_w dist_market_w real_maize_price_mr real_rice_price_mr land_holding real_hhvalue org_fert hh_headage attend_sch femhead num_mem ext_acess

egen median_maize = median(real_maize_price_mr)
replace real_maize_price_mr = median_maize if real_maize_price_mr==.
egen median_rice = median (real_rice_price_mr)
replace real_rice_price_mr = median_rice if real_rice_price_mr==.
egen median_head = median(hh_headage)
replace hh_headage = median_head if hh_headage==.
egen median_real_tpricefert_cens_mrk = median(real_tpricefert_cens_mrk)
replace real_tpricefert_cens_mrk = median_real_tpricefert_cens_mrk if real_tpricefert_cens_mrk==.


tabstat total_qty_w real_tpricefert_cens_mrk subsidy_qty_w dist_market_w real_maize_price_mr real_rice_price_mr land_holding real_hhvalue org_fert hh_headage attend_sch femhead num_mem ext_acess [aweight = weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize total_qty_w real_tpricefert_cens_mrk subsidy_qty_w dist_market_w real_maize_price_mr real_rice_price_mr land_holding real_hhvalue org_fert hh_headage attend_sch femhead num_mem ext_acess




save "${Nigeria_GHS_W2_created_data}\Nigeria_wave2_complete_data.dta", replace





