********************************************************************************
* Table for descriptive statistics
* descriptive statistics.do
* Kim McErlean
********************************************************************************

use  "$created_data/PSID_marriage_recoded_sample.dta", clear
unique unique_id if inlist(IN_UNIT,0,1,2) // starting sample

gen cohort=.
replace cohort=0 if inrange(rel_start_all,1970,1994)
replace cohort=1 if inrange(rel_start_all,1995,2014)

// finer grained (per reviewer comments)
gen cohort_det=.
replace cohort_det=1 if inrange(rel_start_all,1970,1979)
replace cohort_det=2 if inrange(rel_start_all,1980,1989)
replace cohort_det=3 if inrange(rel_start_all,1990,1999)
replace cohort_det=4 if inrange(rel_start_all,2000,2014)

label define cohort_det 1 "1970s" 2 "1980s" 3 "1990s" 4 "2000s"
label values cohort_det cohort_det

tab rel_start_all cohort_det, m

gen cohort_det_v2=.
replace cohort_det_v2=1 if inrange(rel_start_all,1970,1979)
replace cohort_det_v2=2 if inrange(rel_start_all,1980,1989)
replace cohort_det_v2=3 if inrange(rel_start_all,1990,2014)

label define cohort_det_v2 1 "1970s" 2 "1980s" 3 "1990s+" 
label values cohort_det_v2 cohort_det_v2

********************************************************************************
* Additional sample restrictions
********************************************************************************
// let's get rid of 2021
drop if survey_yr==2021

// need to decide - ALL MARRIAGES or just first? - killewald restricts to just first, so does cooke. My validation is MUCH BETTER against those with first marraiges only...
keep if (AGE_HEAD_>=18 & AGE_HEAD_<=55) &  (AGE_WIFE_>=18 & AGE_WIFE_<=55)
unique unique_id if inlist(IN_UNIT,0,1,2) // sample now

// keep if matrix_marr_num==1 // so I actually think this is wrong because only accounts for relationships ONCE PANEL STARTED
keep if marr_no_estimated==1
unique unique_id if inlist(IN_UNIT,0,1,2) // sample now

// drop those with no earnings or housework hours the whole time
bysort id: egen min_type = min(hh_earn_type_t1) // since no earners is 4, if the minimum is 4, means that was it the whole time
label values min_type hh_earn_type
sort id survey_yr
browse id survey_yr min_type hh_earn_type_t1

tab min_type // okay very few people had no earnings whole time
drop if min_type ==4

bysort id: egen min_hw_type = min(housework_bkt_t1) // since no earners is 4, if the minimum is 4, means that was it the whole time
label values min_hw_type housework_bkt
sort id survey_yr
browse id survey_yr min_hw_type housework_bkt_t1

tab min_hw_type // same here
drop if min_hw_type ==4

********************************************************************************
* Additional variables that need to be created
********************************************************************************
// joint religion

tab religion_head religion_wife, m
tab religion_head, m
tab religion_wife, m // lots of missing wife religions

browse unique_id partner_unique_id survey_yr religion_head religion_wife // going to fill this in

sort unique_id partner_unique_id survey_yr
replace religion_head = religion_head[_n-1] if religion_head==. & unique_id==unique_id[_n-1] & partner_unique_id==partner_unique_id[_n-1]
replace religion_wife = religion_wife[_n-1] if religion_wife==. & unique_id==unique_id[_n-1] & partner_unique_id==partner_unique_id[_n-1]

gsort unique_id partner_unique_id -survey_yr
replace religion_head = religion_head[_n-1] if religion_head==. & unique_id==unique_id[_n-1] & partner_unique_id==partner_unique_id[_n-1]
replace religion_wife = religion_wife[_n-1] if religion_wife==. & unique_id==unique_id[_n-1] & partner_unique_id==partner_unique_id[_n-1]
sort unique_id partner_unique_id survey_yr

gen couple_joint_religion=.
replace couple_joint_religion = 0 if religion_head==0 & religion_wife==0
replace couple_joint_religion = 1 if religion_head==1 & religion_wife==1
replace couple_joint_religion = 2 if inlist(religion_head,3,4,5,6) & inlist(religion_wife,3,4,5,6)
replace couple_joint_religion = 3 if (religion_head==1 & religion_wife!=1 & religion_wife!=.) | (religion_head!=1 & religion_head!=. & religion_wife==1)
replace couple_joint_religion = 4 if ((religion_head==0 & religion_wife!=0 & religion_wife!=.) | (religion_head!=0 & religion_head!=. & religion_wife==0)) & couple_joint_religion==.
replace couple_joint_religion = 5 if inlist(religion_head,2,7,8,9,10) & inlist(religion_wife,2,7,8,9,10)
replace couple_joint_religion = 5 if couple_joint_religion==. & religion_head!=. & religion_wife!=. 
// tab religion_head religion_wife if couple_joint_religion==.

label define couple_joint_religion 0 "Both None" 1 "Both Catholic" 2 "Both Protestant" 3 "One Catholic" 4 "One No Religion" 5 "Other"
label values couple_joint_religion couple_joint_religion

tab couple_joint_religion, m

// fix region
gen region = REGION_
replace region = . if inlist(REGION_,0,9)
label define region 1 "Northeast" 2 "North Central" 3 "South" 4 "West" 5 "Alaska,Hawaii" 6 "Foreign"
label values region region

// other division of labor measures
gen overwork_head = 0
replace overwork_head =1 if weekly_hrs_t1_head >50 & weekly_hrs_t1_head<=200 // used by Cha 2013

gen overwork_wife = 0 
replace overwork_wife = 1 if weekly_hrs_t1_wife > 50 & weekly_hrs_t1_wife<=200

gen bw_type=.
replace bw_type=1 if inlist(ft_pt_t1_head,1,2) & ft_pt_t1_wife==0
replace bw_type=2 if ft_pt_t1_head==2 & ft_pt_t1_wife==1
replace bw_type=3 if (ft_pt_t1_head==2 & ft_pt_t1_wife==2) | (ft_pt_t1_wife==1 & ft_pt_t1_head==1)
replace bw_type=4 if ft_pt_t1_head==1 & ft_pt_t1_wife==2
replace bw_type=5 if ft_pt_t1_head==0 & inlist(ft_pt_t1_wife,1,2)

label define bw_type 1 "Male BW" 2 "Male and a half" 3 "Dual" 4 "Female and a half" 5 "Female BW"
label values bw_type bw_type

gen bw_type_alt=.
replace bw_type_alt=1 if inlist(ft_pt_t1_head,1,2) & ft_pt_t1_wife==0
replace bw_type_alt=2 if ft_pt_t1_head==2 & ft_pt_t1_wife==1
replace bw_type_alt=3 if ft_pt_t1_head==2 & ft_pt_t1_wife==2
replace bw_type_alt=4 if ft_pt_t1_wife==1 & ft_pt_t1_head==1
replace bw_type_alt=5 if ft_pt_t1_head==1 & ft_pt_t1_wife==2
replace bw_type_alt=6 if ft_pt_t1_head==0 & inlist(ft_pt_t1_wife,1,2)

label define bw_type_alt 1 "Male BW" 2 "Male and a half" 3 "Dual FT" 4 "Dual PT" 5 "Female and a half" 6 "Female BW"
label values bw_type_alt bw_type_alt

gen employ_type=.
replace employ_type=1 if (ft_pt_t1_head==2 & ft_pt_t1_wife==2) | (ft_pt_t1_head==1 & ft_pt_t1_wife==1) // both FT or both PT
replace employ_type=2 if (ft_pt_t1_head==2 & inlist(ft_pt_t1_wife,0,1)) | (ft_pt_t1_head==1 & ft_pt_t1_wife==0) // just husband FT
replace employ_type=3 if (ft_pt_t1_wife==2 & inlist(ft_pt_t1_head,0,1)) | (ft_pt_t1_wife==1 & ft_pt_t1_head==0) // just wife FT
replace employ_type=4 if ft_pt_t1_head==0 & ft_pt_t1_wife==0 // neither employed

label define employ_type 1 "Both" 2 "Just Male" 3 "Just Fem" 4 "Neither"
label values employ_type employ_type

// combined dol measures
browse unique_id partner_unique_id survey_yr hh_earn_type_t hh_earn_type_t1 housework_bkt_t housework_bkt_t1 housework_head housework_wife

gen earn_type_hw=.
replace earn_type_hw=1 if hh_earn_type_t1==1 & housework_bkt_t==1
replace earn_type_hw=2 if hh_earn_type_t1==1 & housework_bkt_t==2
replace earn_type_hw=3 if hh_earn_type_t1==1 & housework_bkt_t==3
replace earn_type_hw=4 if hh_earn_type_t1==2 & housework_bkt_t==1
replace earn_type_hw=5 if hh_earn_type_t1==2 & housework_bkt_t==2
replace earn_type_hw=6 if hh_earn_type_t1==2 & housework_bkt_t==3
replace earn_type_hw=7 if hh_earn_type_t1==3 & housework_bkt_t==1
replace earn_type_hw=8 if hh_earn_type_t1==3 & housework_bkt_t==2
replace earn_type_hw=9 if hh_earn_type_t1==3 & housework_bkt_t==3

gen earn_type_hw_t1=.
replace earn_type_hw_t1=1 if hh_earn_type_t1==1 & housework_bkt_t1==1
replace earn_type_hw_t1=2 if hh_earn_type_t1==1 & housework_bkt_t1==2
replace earn_type_hw_t1=3 if hh_earn_type_t1==1 & housework_bkt_t1==3
replace earn_type_hw_t1=4 if hh_earn_type_t1==2 & housework_bkt_t1==1
replace earn_type_hw_t1=5 if hh_earn_type_t1==2 & housework_bkt_t1==2
replace earn_type_hw_t1=6 if hh_earn_type_t1==2 & housework_bkt_t1==3
replace earn_type_hw_t1=7 if hh_earn_type_t1==3 & housework_bkt_t1==1
replace earn_type_hw_t1=8 if hh_earn_type_t1==3 & housework_bkt_t1==2
replace earn_type_hw_t1=9 if hh_earn_type_t1==3 & housework_bkt_t1==3

label define earn_type_hw 1 "Dual: Equal" 2 "Dual: Woman" 3 "Dual: Man" 4 "Male BW: Equal" 5 "Male BW: Woman" 6 "Male BW: Man" 7 "Female BW: Equal" 8 "Female BW: Woman" 9 "Female BW: Man"
label values earn_type_hw earn_type_hw_t1 earn_type_hw

tab earn_type_hw, m
tab earn_type_hw_t1, m
tab earn_type_hw earn_type_hw_t1, m

tab earn_type_hw couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==1, col
tab earn_type_hw_t1 couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==1, col

// combining so the less theoretically interesting ones are combined
gen earn_housework_det=.
replace earn_housework_det=1 if hh_earn_type_t1==1 & housework_bkt_t==1 // dual both (egal)
replace earn_housework_det=2 if hh_earn_type_t1==1 & housework_bkt_t==2 // dual earner, female HM (second shift)
replace earn_housework_det=3 if hh_earn_type_t1==2 & housework_bkt_t==2 // male BW, female HM (traditional)
replace earn_housework_det=4 if hh_earn_type_t1==3 & housework_bkt_t==3 // female BW, male HM (counter-traditional)
replace earn_housework_det=5 if hh_earn_type_t1==3 & inlist(housework_bkt_t,1,2) // all other female BW
replace earn_housework_det=6 if inlist(ft_pt_t1_head,0,1) & inlist(ft_pt_t1_wife,0,1) // underwork
replace earn_housework_det=7 if earn_housework_det==. & hh_earn_type_t1!=. & housework_bkt_t!=. // all others

label define earn_housework_det 1 "Egalitarian" 2 "Second Shift" 3 "Traditional" 4 "Counter Traditional" 5 "All Other Female BW" 6 "Underwork" 7 "All others"
label values earn_housework_det earn_housework_det 

tab earn_housework_det, m
tab earn_type_hw, m
tab earn_type_hw earn_housework_det, m

tab hh_earn_type_t1 housework_bkt_t if earn_housework_det==7

// this doesn't capture OVERWORK
sum weekly_hrs_t1_head if ft_pt_t1_head==2, detail
sum weekly_hrs_t1_wife if ft_pt_t1_wife==2, detail

replace weekly_hrs_t1_head=. if weekly_hrs_t1_head==99
replace weekly_hrs_t1_wife=. if weekly_hrs_t1_wife==99

egen total_weekly_hrs = rowtotal(weekly_hrs_t1_head weekly_hrs_t1_wife)

// more discrete measures of work contributions
input group_earn
.10
.20
.30
.40
.50
.60
.70
.80
1
end

input group_hw
.20
.30
.40
.50
.60
.70
.80
.90
1
end

xtile female_earn_bucket = female_earn_pct_t1, cut(group_earn)
tabstat female_earn_pct_t1, by(female_earn_bucket)
xtile female_hw_bucket = wife_housework_pct_t, cut(group_hw)
tabstat wife_housework_pct_t, by(female_hw_bucket)
browse female_earn_bucket female_earn_pct_t1 female_hw_bucket wife_housework_pct_t 

/*
// dissimilarity
gen hours_diff = weekly_hrs_head - weekly_hrs_wife
browse hours_diff weekly_hrs_head weekly_hrs_wife
gen hours_diff_bkt = .
replace hours_diff_bkt = 1 if hours_diff <=10 & hours_diff >=-10
replace hours_diff_bkt = 2 if hours_diff >10 & hours_diff <=150
replace hours_diff_bkt = 3 if hours_diff <-10 & hours_diff >=-150

label define hours_diff_bkt 1 "Similar" 2 "Skew Male" 3 "Skew Female"
label values hours_diff_bkt hours_diff_bkt 

browse hours_diff_bkt hours_diff

gen hw_diff = housework_wife - housework_head
browse hw_diff housework_wife housework_head
gen hw_diff_bkt = .
replace hw_diff_bkt = 1 if hw_diff <=10 & hw_diff >=-10
replace hw_diff_bkt = 2 if hw_diff >10 & hw_diff <=150
replace hw_diff_bkt = 3 if hw_diff <-10 & hw_diff >=-150

label define hw_diff_bkt 1 "Similar" 2 "Skew Female" 3 "Skew Male"
label values hw_diff_bkt hw_diff_bkt 

browse hw_diff_bkt hw_diff

// test spline at 0.5
mkspline earn_ratio1 0.5 earn_ratio2 = female_earn_pct
browse female_earn_pct earn_ratio1 earn_ratio2 

mkspline hrs_ratio1 0.5 hrs_ratio2 = female_hours_pct
browse female_hours_pct hrs_ratio1 hrs_ratio2
*/


// alternate earnings measures
*Convert to 1000s
gen earnings_1000s = couple_earnings_t1 / 1000

*log
gen earnings_total = couple_earnings_t1 + 1 
gen earnings_ln = ln(earnings_total)
* browse TAXABLE_T1_HEAD_WIFE_ couple_earnings_t1

*square
gen earnings_sq = earnings_1000s * earnings_1000s

* groups
gen earnings_bucket_t1=.
replace earnings_bucket_t1 = 0 if couple_earnings_t1 <=0
replace earnings_bucket_t1 = 1 if couple_earnings_t1 > 0 		& couple_earnings_t1 <=10000
replace earnings_bucket_t1 = 2 if couple_earnings_t1 > 10000 	& couple_earnings_t1 <=20000
replace earnings_bucket_t1 = 3 if couple_earnings_t1 > 20000 	& couple_earnings_t1 <=30000
replace earnings_bucket_t1 = 4 if couple_earnings_t1 > 30000 	& couple_earnings_t1 <=40000
replace earnings_bucket_t1 = 5 if couple_earnings_t1 > 40000 	& couple_earnings_t1 <=50000
replace earnings_bucket_t1 = 6 if couple_earnings_t1 > 50000 	& couple_earnings_t1 <=60000
replace earnings_bucket_t1 = 7 if couple_earnings_t1 > 60000 	& couple_earnings_t1 <=70000
replace earnings_bucket_t1 = 8 if couple_earnings_t1 > 70000 	& couple_earnings_t1 <=80000
replace earnings_bucket_t1 = 9 if couple_earnings_t1 > 80000 	& couple_earnings_t1 <=90000
replace earnings_bucket_t1 = 10 if couple_earnings_t1 > 90000 	& couple_earnings_t1 <=100000
replace earnings_bucket_t1 = 11 if couple_earnings_t1 > 100000 & couple_earnings_t1 <=150000
replace earnings_bucket_t1 = 12 if couple_earnings_t1 > 150000 & couple_earnings_t1 !=.

label define earnings_bucket_t1 0 "0" 1 "0-10000" 2 "10000-20000" 3 "20000-30000" 4 "30000-40000" 5 "40000-50000" 6 "50000-60000" 7 "60000-70000" ///
8 "70000-80000" 9 "80000-90000" 10 "90000-100000" 11 "100000-150000" 12 "150000+"
label values earnings_bucket_t1 earnings_bucket_t1

*Spline
mkspline knot1 0 knot2 20 knot3 = earnings_1000s

// alternate wealth measures
replace HOUSE_VALUE_ = 0 if inlist(HOUSE_VALUE_,9999998,9999999)
replace VEHICLE_VALUE_i = 0 if inlist(VEHICLE_VALUE_i,9999998,9999999)

*Convert to 1000s
gen wealth_no_1000s = WEALTH_NO_EQUITY_i / 1000
gen wealth_eq_1000s = WEALTH_EQUITY_i / 1000

*log
gen wealth_no_ln = ln(WEALTH_NO_EQUITY_i+.01) // oh wait, this is less good for wealth, because you can't log negatives gah
gen wealth_eq_ln = ln(WEALTH_EQUITY_i+.01) // oh wait, this is less good for wealth, because you can't log negatives gah
gen house_value_ln = ln(HOUSE_VALUE_+.01) // just a note - Killewald 2023 uses linear
gen vehicle_value_ln = ln(VEHICLE_VALUE_i+.01) // just a note - Killewald 2023 uses linear

*splines at different values?
sum wealth_eq_1000s, detail
sum wealth_eq_1000s if survey_yr>=1990, detail
mkspline wealth1 0 wealth2 `r(p25)' wealth3 `r(p50)' wealth4 `r(p75)' wealth5 = wealth_eq_1000s
browse wealth_eq_1000s wealth1 wealth2 wealth3 wealth4 wealth5

// alt cohab
gen ever_cohab=0
replace ever_cohab=1 if cohab_with_wife==1 | cohab_with_other==1

// categorical for number of children
recode NUM_CHILDREN_ (0=0)(1=1)(2=2)(3/13=3), gen(num_children)
label define num_children 0 "None" 1 "1 Child" 2 "2 Children" 3 "3+ Children"
label values num_children num_children

// square age of marriage
gen age_mar_head_sq = age_mar_head * age_mar_head
gen age_mar_wife_sq = age_mar_wife * age_mar_wife

// create binary ownership variables
gen home_owner=0
replace home_owner=1 if HOUSE_STATUS_==1

gen vehicle_owner=.
replace vehicle_owner=0 if VEHICLE_OWN_e==5
replace vehicle_owner=1 if VEHICLE_OWN_e==1

// create new variable for having kids under 6 in household
gen children_under6=0
replace children_under6=1 if children==1 & AGE_YOUNG_CHILD_ < 6

// create dummy variable for interval length
gen interval=.
replace interval=1 if inrange(survey_yr,1968,1997)
replace interval=2 if inrange(survey_yr,1999,2021)

// need to combine weight variables
gen weight=.
replace weight=CORE_WEIGHT_ if inrange(survey_yr,1968,1992)
replace weight=COR_IMM_WT_ if inrange(survey_yr,1993,2021)

gen weight_rescale=.

forvalues y=1991/1997{
	summarize weight if survey_yr==`y'
	local rescalefactor `r(N)'/`r(sum)'
	display `rescalefactor'
	replace weight_rescale = weight*`rescalefactor' if survey_yr==`y'
	summarize weight_rescale if survey_yr==`y'
}

forvalues y=1999(2)2021{
	summarize weight if survey_yr==`y'
	local rescalefactor `r(N)'/`r(sum)'
	display `rescalefactor'
	replace weight_rescale = weight*`rescalefactor' if survey_yr==`y'
	summarize weight_rescale if survey_yr==`y'
}

tabstat weight, by(interval)
tabstat weight_rescale, by(interval)

// think need to update the cds eligiblity variable to not be missing
gen cds_sample=0
replace cds_sample=1 if CDS_ELIGIBLE_==1

/*
// also add weight adjustment thing - "$temp\psid_weight_adjustment.dta"
merge m:1 AGE_HEAD_ survey_yr using "$temp\psid_weight_adjustment.dta"
drop if _merge==2
drop _merge

browse survey_yr children children_ever num_children AGE_YOUNG_CHILD_ FIRST_BIRTH_YR
tab AGE_YOUNG_CHILD_ num_children, m

gen weight_adjust=weight
replace weight_adjust = weight * adjust_child if race_head==2 & inrange(survey_yr,1997,2019) & num_children>=1 & AGE_YOUNG_CHILD <=13
replace weight_adjust = weight * adjust_no_child if race_head==2 & inrange(survey_yr,1997,2019) & (num_children==0 | (num_children>=1 & AGE_YOUNG_CHILD >13))

browse survey_yr race_head AGE_YOUNG_CHILD_ weight weight_adjust adjust_child adjust_no_child
*/

// for ref:
global controls "c.age_mar_wife c.age_mar_wife_sq c.age_mar_head c.age_mar_head_sq i.raceth_head i.same_race i.either_enrolled i.region i.cohab_with_wife i.cohab_with_other i.pre_marital_birth  i.num_children i.interval i.home_owner"

********************************************************************************
**# Table starts here: over time
********************************************************************************
keep if inrange(cohort_det_v2,1,3) & inlist(IN_UNIT,0,1,2)

tab hh_earn_type_t1, gen(earn_type)
tab housework_bkt_t, gen(hw_type)
tab earn_housework_det, gen(earn_hw)
tab couple_educ_gp, gen(couple_educ)

putexcel set "$results/Table1_Descriptives_time", replace
putexcel B1:D1 = "Total", merge border(bottom)
putexcel E1:G1 = "No College", merge border(bottom)
putexcel H1:J1 = "College-Educated", merge border(bottom)
putexcel B2 = ("1970s") C2 = ("1980s") D2 = ("1990s") E2 = ("1970s") F2 = ("1980s") G2 = ("1990s") H2 = ("1970s") I2 = ("1980s") J2 = ("1990s"), border(bottom)
putexcel A3 = "Unique Couples"
putexcel A4 = "% Dissolved"

// Means
putexcel A5 = "Wife's share of earnings"
putexcel A6 = "Dual Earning HH"
putexcel A7 = "Male Breadwinner"
putexcel A8 = "Female Breadwinner"
putexcel A9 = "Wife's share of unpaid hours"
putexcel A10 = "Equal"
putexcel A11 = "Female Primary"
putexcel A12 = "Male Primary"
putexcel A13 = "Egalitarian"
putexcel A14 = "Second Shift"
putexcel A15 = "Traditional"
putexcel A16 = "Counter-Traditional"
putexcel A17 = "All Other Female-Breadwinning"
putexcel A18 = "Underwork"
putexcel A19 = "All Others"
putexcel A20 = "Average marital duration"
putexcel A21 = "Age at marriage (wife)"
putexcel A22 = "Age at marriage (husband)"
putexcel A23 = "Couple owns home"
putexcel A24 = "Couple has children"
putexcel A25 = "Average number of children"
putexcel A26 = "Cohabited prior to marriage"
putexcel A27 = "Had premarital birth"
putexcel A28 = "No College Degree"
putexcel A29 = "College Degree"

local meanvars_ovrl "female_earn_pct_t1 earn_type1 earn_type2 earn_type3 wife_housework_pct_t hw_type1 hw_type2 hw_type3 earn_hw1 earn_hw2 earn_hw3 earn_hw4 earn_hw5 earn_hw6 earn_hw7 dur age_mar_wife age_mar_head home_owner  children NUM_CHILDREN_  cohab_with_wife pre_marital_birth couple_educ1 couple_educ2" // 25
local meanvars "female_earn_pct_t1 earn_type1 earn_type2 earn_type3 wife_housework_pct_t hw_type1 hw_type2 hw_type3 earn_hw1 earn_hw2 earn_hw3 earn_hw4 earn_hw5 earn_hw6 earn_hw7 dur age_mar_wife age_mar_head home_owner  children NUM_CHILDREN_ cohab_with_wife pre_marital_birth" // 23


// Overall: 1970s
forvalues w=1/25{
	local row=`w'+4
	local var: word `w' of `meanvars_ovrl'
	mean `var' if cohort_det_v2==1
	matrix t`var'= e(b)
	putexcel B`row' = matrix(t`var'), nformat(#.#%)
}


// Overall: 1980s
forvalues w=1/25{
	local row=`w'+4
	local var: word `w' of `meanvars_ovrl'
	mean `var' if cohort_det_v2==2
	matrix t`var'= e(b)
	putexcel C`row' = matrix(t`var'), nformat(#.#%)
}


// Overall: 1990s
forvalues w=1/25{
	local row=`w'+4
	local var: word `w' of `meanvars_ovrl'
	mean `var' if cohort_det_v2==3
	matrix t`var'= e(b)
	putexcel D`row' = matrix(t`var'), nformat(#.#%)
}


**By education:

// No college degree: 1970s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	mean `var' if couple_educ_gp==0 & cohort_det_v2==1
	matrix t`var'= e(b)
	putexcel E`row' = matrix(t`var'), nformat(#.#%)
}

// No college degree: 1980s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	mean `var' if couple_educ_gp==0 & cohort_det_v2==2
	matrix t`var'= e(b)
	putexcel F`row' = matrix(t`var'), nformat(#.#%)
}

// No college degree: 1990s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	mean `var' if couple_educ_gp==0 & cohort_det_v2==3
	matrix t`var'= e(b)
	putexcel G`row' = matrix(t`var'), nformat(#.#%)
}

// College degree: 1970s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	mean `var' if couple_educ_gp==1 & cohort_det_v2==1
	matrix t`var'= e(b)
	putexcel H`row' = matrix(t`var'), nformat(#.#%)
}

// College degree: 1980s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	mean `var' if couple_educ_gp==1 & cohort_det_v2==2
	matrix t`var'= e(b)
	putexcel I`row' = matrix(t`var'), nformat(#.#%)
}

// College degree: 1990s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	mean `var' if couple_educ_gp==1 & cohort_det_v2==3
	matrix t`var'= e(b)
	putexcel J`row' = matrix(t`var'), nformat(#.#%)
}


// uniques
*Overall
unique unique_id partner_unique_id, by(cohort_det_v2)
unique unique_id partner_unique_id if dissolve==1, by(cohort_det_v2)

*No College
unique unique_id partner_unique_id if couple_educ_gp==0, by(cohort_det_v2)
unique unique_id partner_unique_id if dissolve==1 & couple_educ_gp==0, by(cohort_det_v2)

*College
unique unique_id partner_unique_id if couple_educ_gp==1, by(cohort_det_v2)
unique unique_id partner_unique_id if dissolve==1 & couple_educ_gp==1, by(cohort_det_v2)


********************************************************************************
**# Weighted
********************************************************************************
svyset [pweight=weight]

putexcel set "$results/Table1_Descriptives_weighted", replace
putexcel B1:D1 = "Total", merge border(bottom)
putexcel E1:G1 = "No College", merge border(bottom)
putexcel H1:J1 = "College-Educated", merge border(bottom)
putexcel B2 = ("1970s") C2 = ("1980s") D2 = ("1990s") E2 = ("1970s") F2 = ("1980s") G2 = ("1990s") H2 = ("1970s") I2 = ("1980s") J2 = ("1990s"), border(bottom)
putexcel A3 = "Unique Couples"
putexcel A4 = "% Dissolved"

// Means
putexcel A5 = "Wife's share of earnings"
putexcel A6 = "Dual Earning HH"
putexcel A7 = "Male Breadwinner"
putexcel A8 = "Female Breadwinner"
putexcel A9 = "Wife's share of unpaid hours"
putexcel A10 = "Equal"
putexcel A11 = "Female Primary"
putexcel A12 = "Male Primary"
putexcel A13 = "Egalitarian"
putexcel A14 = "Second Shift"
putexcel A15 = "Traditional"
putexcel A16 = "Counter-Traditional"
putexcel A17 = "All Other Female-Breadwinning"
putexcel A18 = "Underwork"
putexcel A19 = "All Others"
putexcel A20 = "Average marital duration"
putexcel A21 = "Age at marriage (wife)"
putexcel A22 = "Age at marriage (husband)"
putexcel A23 = "Couple owns home"
putexcel A24 = "Couple has children"
putexcel A25 = "Average number of children"
putexcel A26 = "Cohabited prior to marriage"
putexcel A27 = "Had premarital birth"
putexcel A28 = "No College Degree"
putexcel A29 = "College Degree"

local meanvars_ovrl "female_earn_pct_t1 earn_type1 earn_type2 earn_type3 wife_housework_pct_t hw_type1 hw_type2 hw_type3 earn_hw1 earn_hw2 earn_hw3 earn_hw4 earn_hw5 earn_hw6 earn_hw7 dur age_mar_wife age_mar_head home_owner  children NUM_CHILDREN_  cohab_with_wife pre_marital_birth couple_educ1 couple_educ2" // 25
local meanvars "female_earn_pct_t1 earn_type1 earn_type2 earn_type3 wife_housework_pct_t hw_type1 hw_type2 hw_type3 earn_hw1 earn_hw2 earn_hw3 earn_hw4 earn_hw5 earn_hw6 earn_hw7 dur age_mar_wife age_mar_head home_owner  children NUM_CHILDREN_ cohab_with_wife pre_marital_birth" // 23


// Overall: 1970s
forvalues w=1/25{
	local row=`w'+4
	local var: word `w' of `meanvars_ovrl'
	svy: mean `var' if cohort_det_v2==1
	matrix t`var'= e(b)
	putexcel B`row' = matrix(t`var'), nformat(#.#%)
}


// Overall: 1980s
forvalues w=1/25{
	local row=`w'+4
	local var: word `w' of `meanvars_ovrl'
	svy: mean `var' if cohort_det_v2==2
	matrix t`var'= e(b)
	putexcel C`row' = matrix(t`var'), nformat(#.#%)
}


// Overall: 1990s
forvalues w=1/25{
	local row=`w'+4
	local var: word `w' of `meanvars_ovrl'
	svy: mean `var' if cohort_det_v2==3
	matrix t`var'= e(b)
	putexcel D`row' = matrix(t`var'), nformat(#.#%)
}


**By education:

// No college degree: 1970s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	svy: mean `var' if couple_educ_gp==0 & cohort_det_v2==1
	matrix t`var'= e(b)
	putexcel E`row' = matrix(t`var'), nformat(#.#%)
}

// No college degree: 1980s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	svy: mean `var' if couple_educ_gp==0 & cohort_det_v2==2
	matrix t`var'= e(b)
	putexcel F`row' = matrix(t`var'), nformat(#.#%)
}

// No college degree: 1990s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	svy: mean `var' if couple_educ_gp==0 & cohort_det_v2==3
	matrix t`var'= e(b)
	putexcel G`row' = matrix(t`var'), nformat(#.#%)
}

// College degree: 1970s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	svy: mean `var' if couple_educ_gp==1 & cohort_det_v2==1
	matrix t`var'= e(b)
	putexcel H`row' = matrix(t`var'), nformat(#.#%)
}

// College degree: 1980s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	svy: mean `var' if couple_educ_gp==1 & cohort_det_v2==2
	matrix t`var'= e(b)
	putexcel I`row' = matrix(t`var'), nformat(#.#%)
}

// College degree: 1990s
forvalues w=1/23{
	local row=`w'+4
	local var: word `w' of `meanvars'
	svy: mean `var' if couple_educ_gp==1 & cohort_det_v2==3
	matrix t`var'= e(b)
	putexcel J`row' = matrix(t`var'), nformat(#.#%)
}
