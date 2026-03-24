












clear



global Nigeria_GHS_W3_raw_data 		"C:\Users\obine\Music\Documents\Smallholder lsms STATA\NGA_2015_GHSP-W3_v02_M_Stata"
global Nigeria_GHS_W3_created_data  "C:\Users\obine\Music\Documents\Project\codess\Nigeria_medianc\nga_wave2015"




********************************************************************************
* AG FILTER *
********************************************************************************

use "${Nigeria_GHS_W3_raw_data}/sect11a_plantingw3.dta" , clear

keep hhid s11aq1
rename (s11aq1) (ag_rainy_15)
save  "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", replace



*merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

*keep if ag_rainy_15==1


********************************************************************************
* WEIGHTS *
********************************************************************************

use "${Nigeria_GHS_W3_raw_data}/secta_plantingw3.dta" , clear
merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave3 rural
ren wt_wave3 weight
collapse (max) weight, by (hhid)
save  "${Nigeria_GHS_W3_created_data}/weight.dta", replace




************************
*Geodata Variables
************************

use "${Nigeria_GHS_W3_raw_data}\NGA_PlotGeovariables_Y3.dta", clear

collapse (max) srtmslp_nga srtm_nga twi_nga, by (hhid)

merge 1:m hhid using "${Nigeria_GHS_W3_raw_data}\NGA_HouseholdGeovars_Y3.dta"

merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1
ren dist_market dist_market
sum dist_market, detail


collapse (max) dist_market, by (hhid)
sort hhid

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1

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

save "${Nigeria_GHS_W3_created_data}\geodata_2015.dta", replace












****************************
*Subsidized Fertilizer
****************************

use "${Nigeria_GHS_W3_raw_data}\secta11d_harvestw3.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1

*s11dq14 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq26 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq16a s11dq28a  qty of inorg purchased fertilizer
*s11dq16b s11dq28b  units for inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer

*************Checking to confirm its the subsidized price *******************


encode s11dq14, gen(institute)
label list institute

encode s11dq26, gen(institute2)
label list institute2

*encode s11dq40, gen(institute3)
*label list institute3

label list s11dq16b
******conversion from gram to kilogram
replace s11dq16a = 0.001*s11dq16a if s11dq16b==2
tab s11dq16a
replace s11dq28a = 0.001*s11dq28a if s11dq28b==2
tab s11dq28a
*replace s11dq37a = 0.001*s11dq37a if s11dq37b==2
*tab s11dq37a



*************Getting Subsidized quantity and Dummy Variable ******************* N2 AND N3 ARE 2 AND 3 RESPECTIVELY WHILE N1 IS 1

gen subsidy_qty1 = s11dq16a if institute ==2 | institute ==3
tab subsidy_qty1
gen subsidy_qty2 = s11dq28a if institute2 ==2 | institute2 ==3
tab subsidy_qty2


**************
*E-WALLET SUBSIDY
**************

ren s11dq5a esubsidy_dummy 
tab esubsidy_dummy,missing
tab esubsidy_dummy, nolabel
replace esubsidy_dummy =0 if esubsidy_dummy==2 | esubsidy_dummy==.
tab esubsidy_dummy,missing
tab esubsidy_dummy, nolabel


ren s11dq5c1 esubsidy_qty 
tab esubsidy_qty, missing











************
*Getting total subsidy_dummy
**********

egen subsidy_qty = rowtotal(subsidy_qty1 subsidy_qty2 esubsidy_qty)
tab subsidy_qty,missing
sum subsidy_qty,detail



gen subsidy_dummy = (subsidy_qty !=0)

tab subsidy_dummy, missing
replace subsidy_dummy = 1 if esubsidy_dummy ==1
tab subsidy_dummy, missing

collapse (sum)subsidy_qty (max) subsidy_dummy, by (hhid)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1

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

save "${Nigeria_GHS_W3_created_data}\subsidized_fert_2015.dta", replace



***********************************
*Transport Cost
***********************************

use "${Nigeria_GHS_W3_raw_data}\secta11d_harvestw3.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1


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
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1


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

gen transport_cost = transport_w   /0.7730376
sum transport_cost, detail
keep hhid transport_cost

save "${Nigeria_GHS_W3_created_data}\transport.dta", replace


*********************************************** 
*Purchased Fertilizer
***********************************************

use "${Nigeria_GHS_W3_raw_data}\secta11d_harvestw3.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1

*s11dq14 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq26 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq16a s11dq28a  qty of inorg purchased fertilizer
*s11dq16b s11dq28b  units for inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer

encode s11dq14, gen(institute)
label list institute
encode s11dq26, gen(institute2)
label list institute2

encode s11dq40, gen(institute3)
label list institute3


*****Coversion of fertilizer's gram into kilogram using 0.001
replace s11dq16a = 0.001*s11dq16a if s11dq16b==2 
tab s11dq16a

replace s11dq28a = 0.001*s11dq28a if s11dq28b==2
tab s11dq28a


*replace s11dq37a = 0.001*s11dq37a if s11dq37b==2
*tab s11dq37a



***fertilzer total quantity, total value & total price****

gen private_fert1_qty = s11dq16a if institute ==1
tab private_fert1_qty, missing
gen private_fert2_qty = s11dq28a if institute2 ==1
tab private_fert2_qty,missing
*gen private_fert3_qty = s11dq37a if institute3 ==1
*tab private_fert3_qty,missing

gen private_fert1_val = s11dq19 if institute ==1
tab private_fert1_val,missing
gen private_fert2_val = s11dq29 if institute2 ==1
tab private_fert2_val,missing
*gen private_fert3_val = s11dq39 if institute3 ==1
*tab private_fert3_val,missing

egen total_qty  = rowtotal(private_fert1_qty private_fert2_qty)
tab  total_qty, missing

egen total_valuefert  = rowtotal(private_fert1_val private_fert2_val)
tab total_valuefert,missing

gen tpricefert  = total_valuefert /total_qty 
tab tpricefert , missing

gen tpricefert_cens = tpricefert  
replace tpricefert_cens = 800 if tpricefert_cens > 800 & tpricefert_cens < .
replace tpricefert_cens = 12 if tpricefert_cens < 12
tab tpricefert_cens, missing 



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


***************
*organic fertilizer
***************
gen org_fert = 1 if  s11dq36==1
tab org_fert, missing
replace org_fert = 0 if org_fert==.
tab org_fert, missing



collapse  zone lga sector ea (sum) total_qty  total_valuefert  (max)  org_fert tpricefert_cens_mrk, by(hhid)


merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1

sum tpricefert_cens_mrk, detail

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


gen rea_tpricefert_cens_mrk = tpricefert_cens_mrk_w  /0.7730376
gen real_tpricefert_cens_mrk = rea_tpricefert_cens_mrk
replace real_tpricefert_cens_mrk= 416 if hhid == 10062 
replace real_tpricefert_cens_mrk= 184 if hhid == 20064
tab real_tpricefert_cens_mrk
sum real_tpricefert_cens_mrk, detail


keep hhid zone lga sector ea org_fert total_qty_w total_valuefert real_tpricefert_cens_mrk

sort hhid
save "${Nigeria_GHS_W3_created_data}\purchased_fert_2015.dta", replace


******************************* 
*Extension Visit 
*******************************


use "${Nigeria_GHS_W3_raw_data}\sect11l1_plantingw3.dta",clear 

merge 1:1 hhid topic_cd using "${Nigeria_GHS_W3_raw_data}\secta5a_harvestw3.dta"
merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1
replace s11l1q1=1 if s11l1q1==. & sa5aq1==1
ren s11l1q1 ext_acess 

tab ext_acess, missing
tab ext_acess, nolabel

replace ext_acess = 0 if ext_acess==2 | ext_acess==.
tab ext_acess, missing
collapse (max) ext_acess, by (hhid)
la var ext_acess "=1 if received advise from extension services"
save "${Nigeria_GHS_W3_created_data}\extension_access_2015.dta", replace




*****************************
*Community 
****************************

use "${Nigeria_GHS_W3_raw_data}\sectc2_harvestw3.dta", clear
*is_cd  219 for market infrastructure
*c2q3  distance to infrastructure in km

gen mrk_dist = c2q3 if is_cd==222
tab mrk_dist if is_cd==222, missing
egen median_lga = median(mrk_dist), by (zone state lga)
egen median_state = median(mrk_dist), by (zone state)
egen median_zone = median(mrk_dist), by (zone)


replace mrk_dist =0 if is_cd==222 & mrk_dist==. & c2q1==1
tab mrk_dist if is_cd==222, missing

replace mrk_dist = median_lga if mrk_dist==. & is_cd==222
replace mrk_dist = median_state if mrk_dist==. & is_cd==222
replace mrk_dist = median_zone if mrk_dist==. & is_cd==222
tab mrk_dist if is_cd==222, missing

replace mrk_dist= 50 if mrk_dist>=50 & mrk_dist<. & is_cd==222
tab mrk_dist if is_cd==222, missing

sort zone state ea
collapse (max) median_lga median_state median_zone mrk_dist, by (zone state lga sector ea)
replace mrk_dist = median_lga if mrk_dist ==.
tab mrk_dist, missing
replace mrk_dist = median_state if mrk_dist ==.
tab mrk_dist, missing
replace mrk_dist = median_zone if mrk_dist ==.
tab mrk_dist, missing
la var mrk_dist "=distance to the market"

save "${Nigeria_GHS_W3_created_data}\market_distance.dta", replace 




*********************************
*Demographics 
*********************************



use "${Nigeria_GHS_W3_raw_data}\sect1_plantingw3.dta",clear 


merge 1:1 hhid indiv using "${Nigeria_GHS_W3_raw_data}\sect2_harvestw3.dta", gen(household)

merge m:1 zone state lga sector ea using "${Nigeria_GHS_W3_created_data}\market_distance.dta", keepusing (median_lga median_state median_zone mrk_dist)
merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1
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
*s1q3   relationship to household head
*s1q6   age in years


sort hhid indiv 
 
gen num_mem = 1



******** female head****

gen femhead  = 0
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
*s2aq6   1= attended school
*s2aq9	 highest education level
*s1q3    relationship to household head


ren  s2aq6 attend_sch 
tab attend_sch
replace attend_sch = 0 if attend_sch ==2
tab attend_sch, nolabel
*tab s1q4 if s2q7==.

replace s2aq9= 0 if attend_sch==0
tab s2aq9
tab s1q3 if _merge==1

tab s2aq9 if s1q3==1
replace s2aq9 = 16 if s2aq9==. &  s1q3==1

*** Education Dummy Variable*****

 label list s2aq9

gen pry_edu  = 1 if s2aq9 >= 1 & s2aq9 < 16 & s1q3==1
gen finish_pry  = 1 if s2aq9 >= 16 & s2aq9 < 26 & s1q3==1
gen finish_sec  = 1 if s2aq9 >= 26 & s2aq9 < 43 & s1q3==1

replace pry_edu =0 if pry_edu ==. & s1q3==1
replace finish_pry  =0 if finish_pry==. & s1q3==1
replace finish_sec =0 if finish_sec ==. & s1q3==1
tab pry_edu if s1q3==1 , missing
tab finish_pry if s1q3==1 , missing 
tab finish_sec if s1q3==1 , missing

collapse (sum) num_mem (max) mrk_dist hh_headage femhead attend_sch pry_edu finish_pry finish_sec , by (hhid)


merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1

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
la var femhead  "=1 if head is female"
la var hh_headage "age of household head in years"
la var attend_sch "=1 if respondent attended school"
la var pry_edu "=1 if household head attended pry school"
la var finish_pry "=1 if household head finished pry school"
la var finish_sec  "=1 if household head finished sec school"
save "${Nigeria_GHS_W3_created_data}\demographics_2015.dta", replace



**************************
*Food Prices from Community
**************************
use "${Nigeria_GHS_W3_raw_data}\sectc2a_plantingw3.dta", clear

*br if item_cd == 20
*br if item_cd ==20 & c2q2==1
tab c2q3 if item_cd ==20 & c2q2==1
tab c2q2 if item_cd==20



gen conversion =1
tab conversion, missing
gen food_size=1 //This makes it easy for me to copy-paste existing code rather than having to write a new block
replace conversion = food_size*2.696 if c2q2 == 11
replace conversion = food_size*0.001 if  c2q2 == 2
replace conversion = food_size*0.175 if  c2q2 == 12		
replace conversion = food_size*0.23 if  c2q2 == 13
replace conversion = food_size*1.5 if  c2q2 == 20 |c2q2 == 21  |c2q2 == 30  |c2q2 == 31 	
replace conversion = food_size*0.35 if  c2q2 == 40 
replace conversion = food_size*0.70 if  c2q2 == 41
replace conversion = food_size*3.00 if  c2q2 == 51  |c2q2 == 52 
replace conversion = food_size*0.718 if  c2q2 == 70	 |c2q2 == 71  |c2q2 == 72
replace conversion = food_size*1.615 if  c2q2 == 80  |c2q2 == 81  |c2q2 == 82
replace conversion = food_size*1.135 if   c2q2 == 90  |c2q2 == 91  |c2q2 == 92
				
tab conversion, missing	



gen maize_price= c2q3* conversion if item_cd==20
tab maize_price

sum maize_price, detail


tab maize_price,missing
sum maize_price,detail
tab maize_price

replace maize_price = 400 if maize_price >400 & maize_price<.  //bottom 5%
replace maize_price = 0.04 if maize_price< 0.04        ////top 1%



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






****************rice

gen rice_price = c2q3* conversion if item_cd==13

sum rice_price,detail
tab rice_price

replace rice_price = 1350 if rice_price >1350 & rice_price<.   //bottom 5%
replace rice_price = 5 if rice_price< 5   //top 5%
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


save "${Nigeria_GHS_W3_created_data}\food_prices.dta", replace


use "${Nigeria_GHS_W3_raw_data}\sect7b_plantingw3.dta", clear
merge m:1 zone state lga sector ea using "${Nigeria_GHS_W3_created_data}\food_prices.dta", keepusing (median_pr_ea median_pr_lga median_pr_state median_pr_zone maize_price_mr rice_price_mr)
merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1


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


collapse  (max) maize_price_mr rice_price_mr, by(hhid)


gen rea_maize_price_mr = maize_price_mr   /0.7730376
gen real_maize_price_mr = rea_maize_price_mr
tab real_maize_price_mr
sum real_maize_price_mr, detail
gen rea_rice_price_mr = rice_price_mr    /0.7730376
gen real_rice_price_mr = rea_rice_price_mr
tab real_rice_price_mr
sum real_rice_price_mr, detail

sort hhid
save "${Nigeria_GHS_W3_created_data}\food_prices_2015.dta", replace




*****************************
*Household Assests
****************************


use "${Nigeria_GHS_W3_raw_data}\sect5_plantingw3.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1
*s5q1 qty of items
*s5q4 scrap value of item 

sort hhid item_cd

gen hhasset_value  = s5q4*s5q1
tab hhasset_value,missing
sum hhasset_value,detail

/*
replace hhasset_value = 1000000 if hhasset_value > 1000000 & hhasset_value <.
replace hhasset_value = 200 if hhasset_value <200
*/

tab hhasset_value,missing

sum hhasset_value, detail



collapse (sum) hhasset_value, by (hhid)



merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1


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

gen rea_hhvalue = hhasset_value_w    /0.7730376
gen real_hhvalue = rea_hhvalue/1000
sum hhasset_value_w real_hhvalue, detail


keep  hhid real_hhvalue

la var real_hhvalue "total value of household asset"
save "${Nigeria_GHS_W3_created_data}\household_asset_2015.dta", replace





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
save "${Nigeria_GHS_W3_created_data}\land_cf.dta", replace

 
 
 
 
 
 
 *************** Plot Size **********************

use "${Nigeria_GHS_W3_raw_data}\sect11a1_plantingw3",clear 
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using  "${Nigeria_GHS_W3_raw_data}\sect11b1_plantingw3"
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W3_raw_data}\secta1_harvestw3.dta", gen(plot_merge)

 merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1
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
merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}\land_cf.dta", nogen keep(1 3) 


 
 *farmer reported field size for post-planting
gen field_size= area_size*conversion
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
*farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit

 
 
 ***************Measurement in hectares for the additional plots from post-harvest************
******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}\land_cf.dta", nogen keep(1 3) 


replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.               
la var field_size "Area of plot (ha)"
ren plotid plot_id
sum field_size, detail


*Total land holding including cultivated and rented out
collapse (sum) field_size, by (hhid)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1

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
save "${Nigeria_GHS_W3_created_data}\land_holding_2015.dta", replace

 





*******************************
*Soil Quality
*******************************

use "${Nigeria_GHS_W3_raw_data}\sect11a1_plantingw3",clear 
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using  "${Nigeria_GHS_W3_raw_data}\sect11b1_plantingw3"
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W3_raw_data}\secta1_harvestw3.dta", gen(plot_merge)

 
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
merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}\land_cf.dta", nogen keep(1 3) 


 
 *farmer reported field size for post-planting
gen field_size= area_size*conversion
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
*farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit
 ***************Measurement in hectares for the additional plots from post-harvest************
******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}\land_cf.dta", nogen keep(1 3) 


replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.               
la var field_size "Area of plot (ha)"
sum field_size, detail
keep zone state lga sector ea hhid plotid field_size

merge 1:1 hhid plotid using "${Nigeria_GHS_W3_raw_data}\sect11b1_plantingw3.dta"

merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

keep if ag_rainy_15==1


ren s11b1q45 soil_quality
tab soil_quality, missing


order field_size soil_quality hhid 
sort hhid


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

replace soil_qty_rev3= 2 if soil_qty_rev3==1.5
tab soil_qty_rev3, missing

collapse (mean) soil_qty_rev3  (max)  good_soil fairr_soil, by (hhid)

save "${Nigeria_GHS_W3_created_data}\soil_quality_2015.dta", replace






************************* Merging Agricultural Datasets ********************

use "${Nigeria_GHS_W3_created_data}\purchased_fert_2015.dta", replace


*******All observations Merged*****


merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}\subsidized_fert_2015.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}\weight.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}\E-wallet_subsidized_fert_2015.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}\extension_access_2015.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}\demographics_2015.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}\food_prices_2015.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}\geodata_2015.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}\soil_quality_2015.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}\household_asset_2015.dta"
drop _merge
sort hhid
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}\land_holding_2015.dta"
drop _merge
gen year = 2015
sort hhid
drop if hhid == 310100 //didnt report price****
drop if hhid == 340089 //didnt report price****



tabstat total_qty_w real_tpricefert_cens_mrk subsidy_qty_w dist_market_w real_maize_price_mr real_rice_price_mr land_holding real_hhvalue org_fert hh_headage attend_sch femhead num_mem ext_acess [aweight = weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize total_qty_w real_tpricefert_cens_mrk subsidy_qty_w dist_market_w real_maize_price_mr real_rice_price_mr land_holding real_hhvalue org_fert hh_headage attend_sch femhead num_mem ext_acess
egen median_real_tpricefert_cens_mrk = median (real_tpricefert_cens_mrk)
replace real_tpricefert_cens_mrk = median_real_tpricefert_cens_mrk if real_tpricefert_cens_mrk==.

egen median_maize = median(real_maize_price_mr)
replace real_maize_price_mr = median_maize if real_maize_price_mr==.

egen median_rice = median (real_rice_price_mr)
replace real_rice_price_mr = median_rice if real_rice_price_mr==.

egen median_dist = median (mrk_dist_w)
replace mrk_dist_w = median_dist if mrk_dist_w==.

misstable summarize total_qty_w real_tpricefert_cens_mrk subsidy_qty_w dist_market_w real_maize_price_mr real_rice_price_mr land_holding real_hhvalue org_fert hh_headage attend_sch femhead num_mem ext_acess

save "${Nigeria_GHS_W3_created_data}\Nigeria_wave3_completedata_2015.dta", replace



