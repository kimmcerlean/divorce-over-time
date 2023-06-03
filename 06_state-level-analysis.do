********************************************************************************
* Adding in state-level data
* state-level-analysis.do
* Kim McErlean
********************************************************************************

********************************************************************************
* First just get data and do all the restrictions that are in file 3
********************************************************************************

use "$data_keep\PSID_marriage_recoded_sample.dta", clear // created in 1a

gen cohort=.
replace cohort=1 if inrange(rel_start_all,1969,1979)
replace cohort=2 if inrange(rel_start_all,1980,1989)
replace cohort=3 if inrange(rel_start_all,1990,2010)
replace cohort=4 if inrange(rel_start_all,2011,2019)


// keep if cohort==3, need to just use filters so I don't have to keep using and updating the data
// need to decide - ALL MARRIAGES or just first? - killewald restricts to just first, so does cooke. My validation is MUCH BETTER against those with first marraiges only...
keep if marriage_order_real==1
keep if (AGE_REF_>=18 & AGE_REF_<=55) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=55)

// drop those with no earnings or housework hours the whole time
bysort id: egen min_type = min(hh_earn_type) // since no earners is 4, if the minimum is 4, means that was it the whole time
label values min_type hh_earn_type
sort id survey_yr
browse id survey_yr min_type hh_earn_type

tab min_type // okay very few people had no earnings whole time
drop if min_type ==4

bysort id: egen min_hw_type = min(housework_bkt) // since no earners is 4, if the minimum is 4, means that was it the whole time
label values min_hw_type housework_bkt
sort id survey_yr
browse id survey_yr min_hw_type housework_bkt

tab min_hw_type // same here
drop if min_hw_type ==4

// need to make religion
// religion is new, but think I need to add given historical research. coding changes between 1984 and 1985, then again between 1994 and 1995. using past then, so this is fine. otherwise, need to recode in MAIN FILE before combining. okay still somewhat sketchy. coding like this for now, will update in real analysis

label define update_religion  ///
       1 "Catholic"  ///
       2 "Jewish"  ///
       8 "Protestant unspecified"  ///
      10 "Other non-Christian: Muslim, Rastafarian, etc."  ///
      13 "Greek/Russian/Eastern Orthodox"  ///
      97 "Other"  ///
      98 "DK"  ///
      99 "NA; refused"  ///
       0 "None"

recode RELIGION_HEAD_ (3/7=97)(9=97)(11/12=97)(14/31=97), gen(religion_head)
recode RELIGION_WIFE_ (3/7=97)(9=97)(11/12=97)(14/31=97), gen(religion_wife)
	   
label values religion_head religion_wife update_religion

// fix region
gen region = REGION_
replace region = . if inlist(REGION_,0,9)
label define region 1 "Northeast" 2 "North Central" 3 "South" 4 "West" 5 "Alaska,Hawaii" 6 "Foreign"
label values region region

// splitting the college group into who has a degree. also considering advanced degree as higher than college -- this currently only works for cohort 3. I think for college - the specific years matter to split advanced, but for no college - distinguishing between grades less relevant?
gen college_bkd=.
replace college_bkd=1 if (EDUC_WIFE_==16 & EDUC_HEAD_==16) | (EDUC_WIFE_==17 & EDUC_HEAD_==17)
replace college_bkd=2 if (EDUC_WIFE_==17 & EDUC_HEAD_ <= 16) | (EDUC_WIFE_==16 & EDUC_HEAD_ <= 15) 
replace college_bkd=3 if (EDUC_HEAD_==17 & EDUC_WIFE_ <= 16) | (EDUC_HEAD_==16 & EDUC_WIFE_ <= 15)
replace college_bkd=0 if couple_educ_gp==0

label define college_bkd 1 "Both" 2 "Wife" 3 "Husband"
label values college_bkd college_bkd

gen no_college_bkd=.
replace no_college_bkd=1 if couple_educ_gp==0 & educ_wife==educ_head
replace no_college_bkd=2 if couple_educ_gp==0 & educ_wife>educ_head & educ_wife!=.
replace no_college_bkd=3 if couple_educ_gp==0 & educ_wife<educ_head & educ_head!=.
replace no_college_bkd=0 if couple_educ_gp==1
label values no_college_bkd college_bkd

// more discrete measures of work contributions
input group
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

xtile female_hours_bucket = female_hours_pct, cut(group)
browse female_hours_bucket female_hours_pct weekly_hrs_wife ft_pt_wife weekly_hrs_head ft_pt_head

// something went wrong here
drop ft_pt_head
drop ft_pt_wife

gen ft_pt_head=0
replace ft_pt_head=1 if weekly_hrs_head>0 & weekly_hrs_head <=35
replace ft_pt_head=2 if weekly_hrs_head >35 & weekly_hrs_head<=200

gen ft_pt_wife=0
replace ft_pt_wife=1 if weekly_hrs_wife>0 & weekly_hrs_wife <=35
replace ft_pt_wife=2 if weekly_hrs_wife >35 & weekly_hrs_wife<=200

gen overwork_head = 0
replace overwork_head =1 if weekly_hrs_head >50 & weekly_hrs_head<=200 // used by Cha 2013

gen overwork_wife = 0 
replace overwork_wife = 1 if weekly_hrs_wife > 50 & weekly_hrs_wife<=200

gen bw_type=.
replace bw_type=1 if inlist(ft_pt_head,1,2) & ft_pt_wife==0
replace bw_type=2 if ft_pt_head==2 & ft_pt_wife==1
replace bw_type=3 if (ft_pt_head==2 & ft_pt_wife==2) | (ft_pt_wife==1 & ft_pt_head==1)
replace bw_type=4 if ft_pt_head==1 & ft_pt_wife==2
replace bw_type=5 if ft_pt_head==0 & inlist(ft_pt_wife,1,2)

label define bw_type 1 "Male BW" 2 "Male and a half" 3 "Dual" 4 "Female and a half" 5 "Female BW"
label values bw_type bw_type

gen hours_type_hw=.
replace hours_type_hw=1 if bw_type==3 & housework_bkt==1
replace hours_type_hw=2 if bw_type==3 & housework_bkt==2
replace hours_type_hw=3 if bw_type==3 & housework_bkt==3
replace hours_type_hw=4 if inlist(bw_type,1,2) & housework_bkt==1
replace hours_type_hw=5 if inlist(bw_type,1,2) & housework_bkt==2
replace hours_type_hw=6 if inlist(bw_type,1,2) & housework_bkt==3
replace hours_type_hw=7 if inlist(bw_type,4,5) & housework_bkt==1
replace hours_type_hw=8 if inlist(bw_type,4,5) & housework_bkt==2
replace hours_type_hw=9 if inlist(bw_type,4,5) & housework_bkt==3

label define hours_type_hw 1 "Dual: Equal" 2 "Dual: Woman" 3 "Dual: Man" 4 "Male BW: Equal" 5 "Male BW: Woman" 6 "Male BW: Man" 7 "Female BW: Equal" 8 "Female BW: Woman" 9 "Female BW: Man"
label values hours_type_hw hours_type_hw


gen earn_type_hw=.
replace earn_type_hw=1 if hh_earn_type==1 & housework_bkt==1
replace earn_type_hw=2 if hh_earn_type==1 & housework_bkt==2
replace earn_type_hw=3 if hh_earn_type==1 & housework_bkt==3
replace earn_type_hw=4 if hh_earn_type==2 & housework_bkt==1
replace earn_type_hw=5 if hh_earn_type==2 & housework_bkt==2
replace earn_type_hw=6 if hh_earn_type==2 & housework_bkt==3
replace earn_type_hw=7 if hh_earn_type==3 & housework_bkt==1
replace earn_type_hw=8 if hh_earn_type==3 & housework_bkt==2
replace earn_type_hw=9 if hh_earn_type==3 & housework_bkt==3

label define earn_type_hw 1 "Dual: Equal" 2 "Dual: Woman" 3 "Dual: Man" 4 "Male BW: Equal" 5 "Male BW: Woman" 6 "Male BW: Man" 7 "Female BW: Equal" 8 "Female BW: Woman" 9 "Female BW: Man"
label values earn_type_hw earn_type_hw

gen division_bucket=5
replace division_bucket = 1 if hh_earn_type== 1 & housework_bkt== 1 // dual, dual
replace division_bucket = 2 if hh_earn_type== 2 & housework_bkt== 2 // male bw, female hw
replace division_bucket = 3 if hh_earn_type== 3 & housework_bkt== 3 // female bw, male hw
replace division_bucket = 4 if hh_earn_type== 1 & housework_bkt== 2 // dual, female hw

label define division_bucket 1 "Dual" 2 "Male BW" 3 "Female BW" 4 "Necessity" 5 "All Other"
label values division_bucket division_bucket

// this doesn't capture OVERWORK
sum weekly_hrs_head if ft_pt_head==2, detail
sum weekly_hrs_wife if ft_pt_wife==2, detail

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

// alternate earnings measures
*Convert to 1000s
gen earnings_1000s = couple_earnings / 1000

*log
gen earnings_total = couple_earnings + 1 
gen earnings_ln = ln(earnings_total)
* browse TAXABLE_HEAD_WIFE_ earnings_total earnings_ln

// gen earnings_ln2 = ln(TAXABLE_HEAD_WIFE_)
// replace earnings_ln2 = 0 if TAXABLE_HEAD_WIFE_ <=0

*square
gen earnings_sq = TAXABLE_HEAD_WIFE_ * TAXABLE_HEAD_WIFE_

* groups
gen earnings_bucket=.
replace earnings_bucket = 0 if TAXABLE_HEAD_WIFE_ <=0
replace earnings_bucket = 1 if TAXABLE_HEAD_WIFE_ > 0 		& TAXABLE_HEAD_WIFE_ <=10000
replace earnings_bucket = 2 if TAXABLE_HEAD_WIFE_ > 10000 	& TAXABLE_HEAD_WIFE_ <=20000
replace earnings_bucket = 3 if TAXABLE_HEAD_WIFE_ > 20000 	& TAXABLE_HEAD_WIFE_ <=30000
replace earnings_bucket = 4 if TAXABLE_HEAD_WIFE_ > 30000 	& TAXABLE_HEAD_WIFE_ <=40000
replace earnings_bucket = 5 if TAXABLE_HEAD_WIFE_ > 40000 	& TAXABLE_HEAD_WIFE_ <=50000
replace earnings_bucket = 6 if TAXABLE_HEAD_WIFE_ > 50000 	& TAXABLE_HEAD_WIFE_ <=60000
replace earnings_bucket = 7 if TAXABLE_HEAD_WIFE_ > 60000 	& TAXABLE_HEAD_WIFE_ <=70000
replace earnings_bucket = 8 if TAXABLE_HEAD_WIFE_ > 70000 	& TAXABLE_HEAD_WIFE_ <=80000
replace earnings_bucket = 9 if TAXABLE_HEAD_WIFE_ > 80000 	& TAXABLE_HEAD_WIFE_ <=90000
replace earnings_bucket = 10 if TAXABLE_HEAD_WIFE_ > 90000 	& TAXABLE_HEAD_WIFE_ <=100000
replace earnings_bucket = 11 if TAXABLE_HEAD_WIFE_ > 100000 & TAXABLE_HEAD_WIFE_ <=150000
replace earnings_bucket = 12 if TAXABLE_HEAD_WIFE_ > 150000 & TAXABLE_HEAD_WIFE_ !=.

label define earnings_bucket 0 "0" 1 "0-10000" 2 "10000-20000" 3 "20000-30000" 4 "30000-40000" 5 "40000-50000" 6 "50000-60000" 7 "60000-70000" ///
8 "70000-80000" 9 "80000-90000" 10 "90000-100000" 11 "100000-150000" 12 "150000+"
label values earnings_bucket earnings_bucket

*Spline
mkspline knot1 0 knot2 20 knot3 = earnings_1000s


// want to create time-invariant indicator of hh type in first year of marriage (but need to make sure it's year both spouses in hh) - some started in of year gah. use DUR? or rank years and use first rank? (actually is that a better duration?)
browse id survey_yr rel_start_all dur hh_earn_type_bkd
bysort id (survey_yr): egen yr_rank=rank(survey_yr)
gen hh_earn_type_mar = hh_earn_type_bkd if yr_rank==1
bysort id (hh_earn_type_mar): replace hh_earn_type_mar=hh_earn_type_mar[1]
label values hh_earn_type_mar earn_type_bkd

browse id survey_yr rel_start_all yr_rank dur hh_earn_type_bkd hh_earn_type_mar

// okay rolling change in female earn pct - absolute or relative?! absolute for now...
sort id survey_yr
gen female_earn_pct_chg = (female_earn_pct-female_earn_pct[_n-1]) if id==id[_n-1]
browse id survey_yr rel_start_all female_earn_pct female_earn_pct_chg

// alt cohab
gen ever_cohab=0
replace ever_cohab=1 if cohab_with_wife==1 | cohab_with_other==1

// missing value inspect
inspect age_mar_wife // 0
inspect age_mar_head // 0
inspect race_head // 2
inspect same_race // 0
inspect either_enrolled // 0
inspect REGION_ // 0
inspect cohab_with_wife // 0
inspect cohab_with_other // 0 
inspect pre_marital_birth // 0

// indicators of paid leave
gen paid_leave_state=0
replace paid_leave_state=1 if inlist(STATE_,6,34,36,44)

gen time_leave=.
replace time_leave=0 if STATE_==6 & survey_yr < 2004
replace time_leave=0 if STATE_==34 & survey_yr < 2009
replace time_leave=0 if STATE_==36 & survey_yr < 2014
replace time_leave=0 if STATE_==44 & survey_yr < 2018
replace time_leave=1 if STATE_==6 & survey_yr >= 2004
replace time_leave=1 if STATE_==34 & survey_yr >= 2009
replace time_leave=1 if STATE_==36 & survey_yr >= 2014
replace time_leave=1 if STATE_==44 & survey_yr >= 2018

// minimum wage
gen min_wage=0
replace min_wage=1 if inlist(STATE_,2,4,5,6,8,9,10,11,12,15,17,23,24,25,26,27,29,30,31,34,35,36,39,41,44,46,50,53,54)

keep if cohort==3
keep if inlist(IN_UNIT,1,2)


********************************************************************************
**# Bookmark #1
* Merge onto policy data
********************************************************************************
/*
statemin: minimum wage - 2017, I updated up until 2020
masssociallib_est: attitudes - 2014
policysociallib_est: social policy - 2014
policyeconlib_est: economic policy - 2014
unemployment: unemployment rate - 2017, I updated up until 2020
state_cpi_bfh_est: state CPI - 2010
fed min: "T:\Research Projects\State data\data_keep\fed_min.dta"
new policy file: "T:\Research Projects\State data\data_keep\final_measures.dta"
*/

rename STATE_ state_fips
rename survey_yr year
merge m:1 state_fips year using "T:\Research Projects\State data\data_keep\cspp_data_1985_2019.dta", keepusing(statemin masssociallib_est policysociallib_est policyeconlib_est unemployment state_cpi_bfh_est)

drop if _merge==2
drop _merge

merge m:1 year using "T:\Research Projects\State data\data_keep\fed_min.dta"
drop if _merge==2
drop _merge

merge m:1 state_fips year using "T:\Research Projects\State data\data_keep\final_measures.dta"
drop if _merge==2
drop _merge

// I need to remember - not all variables have data past 2010 - should I just extend forward. I could definitely add in the min wage and unemployment
browse year state_fips state_cpi_bfh_est


// also want to test some binary variables
/*
gen above_fed_min=0
replace above_fed_min=1 if statemin>fed_min & statemin!=.
replace above_fed_min=. if statemin==.
*/

gen state_cpi = (state_cpi_bfh_est*100) + 100

gen above_fed_cpi=0
replace above_fed_cpi=1 if state_cpi>fed_cpi & state_cpi!=.
replace above_fed_cpi=. if state_cpi==.

gen social_policy=0
replace social_policy=1 if policysociallib_est>0 & policysociallib_est!=.

xtile social_policy_gp = policysociallib_est, nq(5)
tabstat policysociallib_est, by(social_policy_gp)
// pctile social_policy_score = policysociallib_est, nq(5) genp(social_policy_gp)

xtile liberal_attitudes_gp = masssociallib_est, nq(5)
tabstat masssociallib_est, by(liberal_attitudes_gp)

**# Analysis starts

********************************************************************************
********************************************************************************
********************************************************************************
* Overall trends
********************************************************************************
********************************************************************************
********************************************************************************

logit dissolve_lag i.dur i.couple_educ_gp, or

logit dissolve_lag i.dur i.couple_educ_gp##i.state_fips, or nocons // prob gonna be a lot of collinearity / inability to estimate with small states?
outreg2 using "$results/state_test.xls", sideway stats(coef pval) label dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

forvalues s=1/56{
	capture logistic dissolve_lag i.dur i.couple_educ_gp if state_fips==`s'
	capture estimates store m`s'
} 

estimates dir
estimates table *, keep(i.couple_educ_gp) eform b p

estout * using "$results/state_test.xls", replace keep(1.couple_educ_gp) eform cells(b p)

// estout *, eform cells(b(keep(i.couple_educ_gp)) p(keep(i.couple_educ_gp)))

/* test
logit dissolve_lag i.dur i.couple_educ_gp if STATE_==1, or
logit dissolve_lag i.dur i.couple_educ_gp if STATE_==2, or // won't estimate
logit dissolve_lag i.dur i.couple_educ_gp if STATE_==3, or // no obs
logit dissolve_lag i.dur i.couple_educ_gp if STATE_==4, or // will estimate
logit dissolve_lag i.dur i.couple_educ_gp if STATE_==5, or // also will estimate
*/


********************************************************************************
**# * Models that match primary divorce paper
* Just looking for state variation atm
********************************************************************************

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth"

////////// No College \\\\\\\\\\\/
*1. Total earnings
logit dissolve_lag i.dur earnings_1000s `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or
margins, dydx(earnings_1000s)

*2. Categorical indicator of Paid work
logit dissolve_lag i.dur i.hh_earn_type earnings_1000s  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or
margins, dydx(hh_earn_type)

*3. Employment: no interaction
logit dissolve_lag i.dur i.ft_head i.ft_wife earnings_1000s  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or
margins, dydx(ft_head)
margins, dydx(ft_wife)

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth"
forvalues s=1/56{
	capture logistic dissolve_lag i.dur earnings_1000s `controls' if couple_educ_gp==0 & state_fips==`s'
	capture margins, dydx(earnings_1000s) post
	capture estimates store no_a`s'

	capture logistic dissolve_lag i.dur i.hh_earn_type earnings_1000s `controls' if couple_educ_gp==0 & state_fips==`s'
	capture margins, dydx(hh_earn_type) post
	capture estimates store no_b`s'
	
	capture logistic dissolve_lag i.dur i.ft_head i.ft_wife earnings_1000s `controls' if couple_educ_gp==0 & state_fips==`s'
	capture margins, dydx(ft_head ft_wife) post
	capture estimates store no_c`s'
	
} 

estimates dir
estimates table *, b p
estout no_* using "$results/state_no_college.xls", replace cells(b p)

////////// College \\\\\\\\\\\/

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth"
forvalues s=1/56{
	capture logistic dissolve_lag i.dur earnings_1000s `controls' if couple_educ_gp==1 & state_fips==`s'
	capture margins, dydx(earnings_1000s) post
	capture estimates store coll_a`s'

	capture logistic dissolve_lag i.dur i.hh_earn_type earnings_1000s `controls' if couple_educ_gp==1 & state_fips==`s'
	capture margins, dydx(hh_earn_type) post
	capture estimates store coll_b`s'
	
	capture logistic dissolve_lag i.dur i.ft_head i.ft_wife earnings_1000s `controls' if couple_educ_gp==1 & state_fips==`s'
	capture margins, dydx(ft_head ft_wife) post
	capture estimates store coll_c`s'
	
} 

estout coll_* using "$results/state_college.xls", replace cells(b p)

********************************************************************************
********************************************************************************
********************************************************************************
**# For ASA Paper
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
* Just policy variables -> do they predict dissolution?
********************************************************************************
/*
min_above_fed: binary yes / no
rent_afford: higher = more people pay 35% of income for rent
unemployment: continuous
gender_lfp_gap_nocoll: ratio of women to men in lf
gender_lfp_gap_coll: ratio of women to men in lf
paid_leave: binary yes / no
cc_subsidies: higher = more eligible kids served
senate_dems: higher = more dems; .88 correlation with house
*/

log using "$logdir/policy_dissolution.log", replace

forvalues g=0/1{
	melogit dissolve_lag i.dur i.min_above_fed if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(min_above_fed)
	qui melogit dissolve_lag i.dur rent_afford if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(rent_afford)
	qui melogit dissolve_lag i.dur unemployment if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(unemployment)
	qui melogit dissolve_lag i.dur gender_lfp_gap_nocoll if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(gender_lfp_gap_nocoll)
	qui melogit dissolve_lag i.dur i.paid_leave if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(paid_leave)
	qui melogit dissolve_lag i.dur cc_subsidies if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(cc_subsidies)
	qui melogit dissolve_lag i.dur senate_dems if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(senate_dems)
}

log close

********************************************************************************
* Interactions: Employment variables
********************************************************************************
log using "$logdir/policy_interactions.log", replace

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3"

/* No College */

** Minimum wage
melogit dissolve_lag i.dur i.min_above_fed i.ft_head i.ft_wife i.min_above_fed#i.ft_wife i.min_above_fed#i.ft_head `controls' if couple_educ_gp==0 || state_fips:, or
// margins min_above_fed#ft_head
// margins min_above_fed#ft_wife
// margins, dydx(ft_head ft_wife) over(min_above_fed) // this isn't quite matching the above. which is right?!
margins, dydx(ft_head ft_wife) at(min_above_fed=(0 1))
// margins, dydx(ft_head#min_above_fed)

**Rent affordability
melogit dissolve_lag i.dur c.rent_afford i.ft_head i.ft_wife c.rent_afford#i.ft_wife c.rent_afford#i.ft_head `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(ft_head ft_wife) at(rent_afford=(0.25(.05)0.45))

**Unemployment
melogit dissolve_lag i.dur c.unemployment i.ft_head i.ft_wife c.unemployment#i.ft_wife c.unemployment#i.ft_head `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(ft_head ft_wife) at(unemployment=(3(2)11))

**Gender LFP gap
melogit dissolve_lag i.dur c.gender_lfp_gap_nocoll i.ft_head i.ft_wife c.gender_lfp_gap_nocoll#i.ft_wife c.gender_lfp_gap_nocoll#i.ft_head `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(ft_head ft_wife) at(gender_lfp_gap_nocoll=(0.60(.05)0.85))

**Paid Leave
melogit dissolve_lag i.dur i.paid_leave i.ft_head i.ft_wife i.paid_leave#i.ft_wife i.paid_leave#i.ft_head `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(ft_head ft_wife) at(paid_leave=(0 1))

**Childcare subsidies
melogit dissolve_lag i.dur c.cc_subsidies i.ft_head i.ft_wife c.cc_subsidies#i.ft_wife c.cc_subsidies#i.ft_head `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(ft_head ft_wife) at(cc_subsidies=(0.05(.10)0.45))

**% democrats in senate
melogit dissolve_lag i.dur c.senate_dems i.ft_head i.ft_wife c.senate_dems#i.ft_wife c.senate_dems#i.ft_head `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(ft_head ft_wife) at(senate_dems=(0(.10)0.8))


/* College */

** Minimum wage
melogit dissolve_lag i.dur i.min_above_fed i.ft_head i.ft_wife i.min_above_fed#i.ft_wife i.min_above_fed#i.ft_head `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(ft_head ft_wife) at(min_above_fed=(0 1))

**Rent affordability
melogit dissolve_lag i.dur c.rent_afford i.ft_head i.ft_wife c.rent_afford#i.ft_wife c.rent_afford#i.ft_head `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(ft_head ft_wife) at(rent_afford=(0.25(.05)0.45))

**Unemployment
melogit dissolve_lag i.dur c.unemployment i.ft_head i.ft_wife c.unemployment#i.ft_wife c.unemployment#i.ft_head `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(ft_head ft_wife) at(unemployment=(3(2)11))

**Gender LFP gap
melogit dissolve_lag i.dur c.gender_lfp_gap_nocoll i.ft_head i.ft_wife c.gender_lfp_gap_nocoll#i.ft_wife c.gender_lfp_gap_nocoll#i.ft_head `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(ft_head ft_wife) at(gender_lfp_gap_nocoll=(0.60(.05)0.85))

**Paid Leave
melogit dissolve_lag i.dur i.paid_leave i.ft_head i.ft_wife i.paid_leave#i.ft_wife i.paid_leave#i.ft_head `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(ft_head ft_wife) at(paid_leave=(0 1))

**Childcare subsidies
melogit dissolve_lag i.dur c.cc_subsidies i.ft_head i.ft_wife c.cc_subsidies#i.ft_wife c.cc_subsidies#i.ft_head `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(ft_head ft_wife) at(cc_subsidies=(0.05(.10)0.45))

**% democrats in senate
melogit dissolve_lag i.dur c.senate_dems i.ft_head i.ft_wife c.senate_dems#i.ft_wife c.senate_dems#i.ft_head `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(ft_head ft_wife) at(senate_dems=(0(.10)0.8))

log close

********************************************************************************
* Interactions: Earnings
********************************************************************************
log using "$logdir/policy_interactions_earnings.log", replace

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

/* No College */

** Minimum wage
melogit dissolve_lag i.dur i.min_above_fed c.knot1 c.knot2 c.knot3 i.min_above_fed#c.knot2 i.min_above_fed#c.knot3 `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(knot2 knot3) at(min_above_fed=(0 1))

**Rent affordability
melogit dissolve_lag i.dur c.rent_afford c.knot2 c.knot3 c.rent_afford#c.knot2 c.rent_afford#c.knot3 `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(knot2 knot3) at(rent_afford=(0.25(.05)0.45))

**Unemployment
melogit dissolve_lag i.dur c.unemployment c.knot2 c.knot3 c.unemployment#c.knot2 c.unemployment#c.knot3 `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(knot2 knot3) at(unemployment=(3(2)11))

**Gender LFP gap
melogit dissolve_lag i.dur c.gender_lfp_gap_nocoll c.knot2 c.knot3 c.gender_lfp_gap_nocoll#c.knot2 c.gender_lfp_gap_nocoll#c.knot3 `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(knot2 knot3) at(gender_lfp_gap_nocoll=(0.60(.05)0.85))

**Paid Leave
melogit dissolve_lag i.dur i.paid_leave c.knot2 c.knot3 i.paid_leave#c.knot2 i.paid_leave#c.knot3 `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(knot2 knot3) at(paid_leave=(0 1))

**Childcare subsidies
melogit dissolve_lag i.dur c.cc_subsidies c.knot2 c.knot3 c.cc_subsidies#c.knot2 c.cc_subsidies#c.knot3  `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(knot2 knot3) at(cc_subsidies=(0.05(.10)0.45))

**% democrats in senate
melogit dissolve_lag i.dur c.senate_dems c.knot2 c.knot3 c.senate_dems#c.knot2 c.senate_dems#c.knot3 `controls' if couple_educ_gp==0 || state_fips:, or
margins, dydx(knot2 knot3) at(senate_dems=(0(.10)0.8))

/* College */

** Minimum wage
melogit dissolve_lag i.dur i.min_above_fed c.knot1 c.knot2 c.knot3 i.min_above_fed#c.knot2 i.min_above_fed#c.knot3 `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(knot2 knot3) at(min_above_fed=(0 1))

**Rent affordability
melogit dissolve_lag i.dur c.rent_afford c.knot2 c.knot3 c.rent_afford#c.knot2 c.rent_afford#c.knot3 `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(knot2 knot3) at(rent_afford=(0.25(.05)0.45))

**Unemployment
melogit dissolve_lag i.dur c.unemployment c.knot2 c.knot3 c.unemployment#c.knot2 c.unemployment#c.knot3 `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(knot2 knot3) at(unemployment=(3(2)11))

**Gender LFP gap
melogit dissolve_lag i.dur c.gender_lfp_gap_nocoll c.knot2 c.knot3 c.gender_lfp_gap_nocoll#c.knot2 c.gender_lfp_gap_nocoll#c.knot3 `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(knot2 knot3) at(gender_lfp_gap_nocoll=(0.60(.05)0.85))

**Paid Leave
melogit dissolve_lag i.dur i.paid_leave c.knot2 c.knot3 i.paid_leave#c.knot2 i.paid_leave#c.knot3 `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(knot2 knot3) at(paid_leave=(0 1))

**Childcare subsidies
melogit dissolve_lag i.dur c.cc_subsidies c.knot2 c.knot3 c.cc_subsidies#c.knot2 c.cc_subsidies#c.knot3  `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(knot2 knot3) at(cc_subsidies=(0.05(.10)0.45))

**% democrats in senate
melogit dissolve_lag i.dur c.senate_dems c.knot2 c.knot3 c.senate_dems#c.knot2 c.senate_dems#c.knot3 `controls' if couple_educ_gp==1 || state_fips:, or
margins, dydx(knot2 knot3) at(senate_dems=(0(.10)0.8))

log close

********************************************************************************
********************************************************************************
********************************************************************************
**# Preliminary analysis
********************************************************************************
********************************************************************************
********************************************************************************

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth"
//// state variables
* Min wage
melogit dissolve_lag i.dur i.above_fed_min if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state.xls", sideway stats(coef pval) label ctitle(Wage No) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

logit dissolve_lag i.dur i.above_fed_min if couple_educ_gp==0, or // okay these are essentially the same
melogit dissolve_lag i.dur i.above_fed_min if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state.xls", sideway stats(coef pval) label ctitle(Wage Coll) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

* Cost of Living
//melogit dissolve_lag i.dur state_cpi_bfh_est if couple_educ_gp==0 || state_fips:, or
//melogit dissolve_lag i.dur state_cpi_bfh_est if couple_educ_gp==1 || state_fips:, or

melogit dissolve_lag i.dur i.above_fed_cpi if couple_educ_gp==0 || state_fips:, or // missing some data past 2010
outreg2 using "$results/psid_dissolution_state.xls", sideway stats(coef pval) label ctitle(CPI No) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur i.above_fed_cpi  if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state.xls", sideway stats(coef pval) label ctitle(CPI Coll) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

* Social Policy
melogit dissolve_lag i.dur policysociallib_est if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state.xls", sideway stats(coef pval) label ctitle(Soc-Policy No) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur policysociallib_est if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state.xls", sideway stats(coef pval) label ctitle(Soc-Policy Coll) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//melogit dissolve_lag i.dur i.social_policy if couple_educ_gp==0 || state_fips:, or
//melogit dissolve_lag i.dur i.social_policy if couple_educ_gp==1 || state_fips:, or
//melogit dissolve_lag i.dur i.social_policy_gp if couple_educ_gp==0 || state_fips:, or
//melogit dissolve_lag i.dur i.social_policy_gp if couple_educ_gp==1 || state_fips:, or

* Economic Policy
melogit dissolve_lag i.dur policyeconlib_est if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state.xls", sideway stats(coef pval) label ctitle(Econ-Policy No) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur policyeconlib_est if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state.xls", sideway stats(coef pval) label ctitle(Econ-Policy Coll) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

* Attitudes
melogit dissolve_lag i.dur masssociallib_est if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state.xls", sideway stats(coef pval) label ctitle(Lib Attitudes No) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur masssociallib_est if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state.xls", sideway stats(coef pval) label ctitle(Lib Attitudes Coll) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur i.liberal_attitudes_gp if couple_educ_gp==0 || state_fips:, or
melogit dissolve_lag i.dur i.liberal_attitudes_gp if couple_educ_gp==1 || state_fips:, or

////////// No College \\\\\\\\\\\/
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

** Total earnings
melogit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##i.above_fed_min `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Earnings 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

// logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##i.above_fed_min age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==0, or
margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) above_fed_min =(0 1))
marginsplot

melogit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##i.above_fed_cpi `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Earnings 2) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) above_fed_cpi =(0 1))
//marginsplot

melogit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.policysociallib_est `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Earnings 3) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.policysociallib_est age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==0, or
//margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) policysociallib_est =(-2(1)2))
//marginsplot

melogit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.policyeconlib_est `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Earnings 4) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.policyeconlib_est age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==0, or
//margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) policyeconlib_est =(-2(1)2))
//marginsplot

melogit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.masssociallib_est `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Earnings 5) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.masssociallib_est age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==0, or
//margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) masssociallib_est =(-1(1)2))
//marginsplot

**Paid work
melogit dissolve_lag i.dur i.hh_earn_type##i.above_fed_min TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Paid 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur i.hh_earn_type##i.above_fed_min TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==0 & hh_earn_type<4, or
//margins hh_earn_type#above_fed_min
// marginsplot

melogit dissolve_lag i.dur i.hh_earn_type##i.above_fed_cpi TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Paid 2) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur i.hh_earn_type##c.policysociallib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Paid 3) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur i.hh_earn_type##c.policysociallib_est TAXABLE_HEAD_WIFE_  age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==0 & hh_earn_type<4, or
//margins hh_earn_type, at(policysociallib_est =(-2(1)2))
//marginsplot

melogit dissolve_lag i.dur i.hh_earn_type##c.policyeconlib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Paid 4) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur i.hh_earn_type##c.policyeconlib_est TAXABLE_HEAD_WIFE_  age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==0 & hh_earn_type<4, or
//margins hh_earn_type, at(policyeconlib_est =(-2(1)2))
//marginsplot


melogit dissolve_lag i.dur i.hh_earn_type##c.masssociallib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Paid 5) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//margins hh_earn_type#above_fed_min
//marginsplot

**Unpaid work
melogit dissolve_lag i.dur i.housework_bkt##i.above_fed_min TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Unpaid 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

// logit dissolve_lag i.dur i.housework_bkt##i.above_fed_min TAXABLE_HEAD_WIFE_  age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==0 & housework_bkt<4, or
//margins housework_bkt#above_fed_min
//marginsplot

melogit dissolve_lag i.dur i.housework_bkt##i.above_fed_cpi TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Unpaid 2) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur i.housework_bkt##c.policysociallib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Unpaid 3) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

// logit dissolve_lag i.dur i.housework_bkt##c.policysociallib_est TAXABLE_HEAD_WIFE_  age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==0 & housework_bkt<4, or
//margins housework_bkt, at(policysociallib_est =(-2(1)2))
//marginsplot

melogit dissolve_lag i.dur i.housework_bkt##c.policyeconlib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Unpaid 4) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

// logit dissolve_lag i.dur i.housework_bkt##c.policyeconlib_est TAXABLE_HEAD_WIFE_  age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==0 & housework_bkt<4, or
//margins housework_bkt, at(policyeconlib_est =(-2(1)2))
//marginsplot


melogit dissolve_lag i.dur i.housework_bkt##c.masssociallib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==0 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_nocoll.xls", sideway stats(coef pval) label ctitle(Unpaid 5) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append


////////// College \\\\\\\\\\\/
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

** Total earnings
melogit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##i.above_fed_min `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Earnings 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

//margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) above_fed_min =(0 1))
//marginsplot

melogit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##i.above_fed_cpi `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Earnings 2) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) above_fed_cpi =(0 1))
//marginsplot

melogit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.policysociallib_est `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Earnings 3) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.policysociallib_est age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==1, or
//margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) policysociallib_est =(-2(1)2))
//marginsplot

melogit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.policyeconlib_est `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Earnings 4) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.policyeconlib_est age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==1, or
//margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) policyeconlib_est =(-2(1)2))
//marginsplot

melogit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.masssociallib_est `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Earnings 5) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) masssociallib_est =(-1(1)2))
//marginsplot

**Paid work
melogit dissolve_lag i.dur i.hh_earn_type##i.above_fed_min TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Paid 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur i.hh_earn_type##i.above_fed_min TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==1 & hh_earn_type<4, or
//margins hh_earn_type#above_fed_min
// marginsplot

melogit dissolve_lag i.dur i.hh_earn_type##i.above_fed_cpi TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Paid 2) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur i.hh_earn_type##c.policysociallib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Paid 3) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur i.hh_earn_type##c.policysociallib_est TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==1 & hh_earn_type<4, or
//margins hh_earn_type, at(policysociallib_est =(-2(1)2))
// marginsplot

melogit dissolve_lag i.dur i.hh_earn_type##c.policyeconlib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Paid 4) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur i.hh_earn_type##c.policyeconlib_est TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==1 & hh_earn_type<4, or
//margins hh_earn_type, at(policyeconlib_est =(-2(1)2))
// marginsplot


melogit dissolve_lag i.dur i.hh_earn_type##c.masssociallib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Paid 5) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

//logit dissolve_lag i.dur i.hh_earn_type##c.masssociallib_est TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==1 & hh_earn_type<4, or
//margins hh_earn_type, at(masssociallib_est =(-1(1)2))
// marginsplot

**Unpaid work
melogit dissolve_lag i.dur i.housework_bkt##i.above_fed_min TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Unpaid 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur i.housework_bkt##i.above_fed_cpi TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Unpaid 2) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur i.housework_bkt##c.policysociallib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Unpaid 3) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur i.housework_bkt##c.policyeconlib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Unpaid 4) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

melogit dissolve_lag i.dur i.housework_bkt##c.masssociallib_est TAXABLE_HEAD_WIFE_  `controls' if couple_educ_gp==1 || state_fips:, or
outreg2 using "$results/psid_dissolution_state_college.xls", sideway stats(coef pval) label ctitle(Unpaid 5) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

// paid leave
logit dissolve_lag i.dur i.hh_earn_type##i.paid_leave_state TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==0 & hh_earn_type<4, or
margins hh_earn_type#paid_leave_state
 marginsplot
 
logit dissolve_lag i.dur i.hh_earn_type##i.paid_leave_state TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==1 & hh_earn_type<4, or
margins hh_earn_type#paid_leave_state
 marginsplot
 
 logit dissolve_lag i.dur i.housework_bkt##i.paid_leave_state TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==1 & hh_earn_type<4, or
margins housework_bkt#paid_leave_state
 marginsplot
 
logit dissolve_lag i.dur i.hh_earn_type##i.time_leave TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth if couple_educ_gp==1 & hh_earn_type<4, or
margins hh_earn_type#time_leave
marginsplot

********************************************************************************
* Where do they reside?
********************************************************************************
gen college_pop = 1 if couple_educ_gp==1
gen no_college_pop = 1 if couple_educ_gp==0

tabstat policysociallib_est, by(state_fips)
tabstat policyeconlib_est, by(state_fips)
tabstat masssociallib_est, by(state_fips)

preserve
collapse (mean) policysociallib_est policyeconlib_est masssociallib_est (sum) college_pop no_college_pop, by(state_fips)
restore

tab social_policy
tab couple_educ_gp social_policy, row

tabstat policysociallib_est, by(couple_educ_gp)
// Neither College | -.1055554
// At Least One Col |   .129121

tabstat policysociallib_est if dissolve_lag==1, by(couple_educ_gp)
// Neither College | -.1897416
// At Least One Col | -.0548838


/********************************************************************************
********************************************************************************
********************************************************************************
* Models - old
********************************************************************************
********************************************************************************
********************************************************************************
// // outreg2 using "$results/psid_marriage_dissolution.xls", sideway stats(coef pval) label ctitle(Earnings No) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

** Minimum wage
// total earnings
logit dissolve_lag i.dur TAXABLE_HEAD_WIFE_ if couple_educ_gp==0, or
logit dissolve_lag i.dur statemin if couple_educ_gp==0, or // not sig on own
logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.statemin if couple_educ_gp==0, or // interaction is
margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) statemin =(4(2)10))
marginsplot

logit dissolve_lag i.dur TAXABLE_HEAD_WIFE_ if couple_educ_gp==1, or
logit dissolve_lag i.dur statemin if couple_educ_gp==1, or // not sig on own
logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.statemin if couple_educ_gp==1, or // not sig
margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) statemin =(4(2)10))
marginsplot

logit dissolve_lag i.dur TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or

// paid work
logit dissolve_lag i.dur i.hh_earn_type if couple_educ_gp==0, or
logit dissolve_lag i.dur i.hh_earn_type##c.statemin if couple_educ_gp==0, or // nothing sig still
margins hh_earn_type, at(statemin =(4(2)10))
marginsplot

logit dissolve_lag i.dur i.hh_earn_type##c.statemin TAXABLE_HEAD_WIFE_ if couple_educ_gp==0, or // state min on own is marginally positively associated with divorce (so among dual earners - the ref group?)
margins hh_earn_type, at(statemin =(4(2)10)) // this is interesting, but nothing sig
marginsplot

logit dissolve_lag i.dur i.hh_earn_type##c.statemin TAXABLE_HEAD_WIFE_ if couple_educ_gp==1, or // nothing sig
margins hh_earn_type, at(statemin =(4(2)10))
marginsplot

//Unpaid work
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ if couple_educ_gp==0, or
logit dissolve_lag i.dur i.housework_bkt##c.statemin TAXABLE_HEAD_WIFE_ if couple_educ_gp==0 & housework_bkt!=4, or // male primary sig in interaction
margins housework_bkt, at(statemin =(4(2)10))
marginsplot

logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ if couple_educ_gp==1, or
logit dissolve_lag i.dur i.housework_bkt##c.statemin TAXABLE_HEAD_WIFE_ if couple_educ_gp==1 & housework_bkt!=4, or // nothing sig
margins housework_bkt, at(statemin =(4(2)10))
marginsplot

** Unemployment
// total earnings
logit dissolve_lag i.dur TAXABLE_HEAD_WIFE_ if couple_educ_gp==0, or
logit dissolve_lag i.dur unemployment if couple_educ_gp==0, or // is positive
logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.unemployment if couple_educ_gp==0, or // interaction not sig, but main effects are marginally
margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) unemployment =(3(2)9)) // okay so both independently shape divorce
marginsplot

logit dissolve_lag i.dur TAXABLE_HEAD_WIFE_ if couple_educ_gp==1, or
logit dissolve_lag i.dur unemployment if couple_educ_gp==1, or // no association
logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.unemployment if couple_educ_gp==1, or // interaction is sig, and so is main effect for total earnings
margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) unemployment =(3(2)9)) // income seems to matter, then, when unemployment is LOW
marginsplot

//Paid work
logit dissolve_lag i.dur i.hh_earn_type##c.unemployment TAXABLE_HEAD_WIFE_ if couple_educ_gp==0, or // main effect sig
margins hh_earn_type, at(unemployment =(3(2)9))
marginsplot

** Attitudes
// total earnings
logit dissolve_lag i.dur masssociallib_est if couple_educ_gp==0, or // no association
logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.masssociallib_est if couple_educ_gp==0, or // here, interaction sig (negative) and main effect = positive = so when more conservative, income does not matter, when liberal, income lowers divorce (or, when liberal, no income raises risk of divorce?)
margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) masssociallib_est =(-1(1)2))
marginsplot

logit dissolve_lag i.dur masssociallib_est if couple_educ_gp==1, or // not sig but directionally negative
logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.masssociallib_est if couple_educ_gp==1, or // nothing sig
margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) masssociallib_est =(-1(1)2))
marginsplot

//Paid work
logit dissolve_lag i.dur i.hh_earn_type##c.masssociallib_est TAXABLE_HEAD_WIFE_ if couple_educ_gp==0, or  // nothing sig
margins hh_earn_type, at(masssociallib_est =(-1(1)2)) 
marginsplot

logit dissolve_lag i.dur i.hh_earn_type##c.masssociallib_est TAXABLE_HEAD_WIFE_ if couple_educ_gp==1, or  // female BW main effect - so when more conservative, female BW is bad?
margins hh_earn_type, at(masssociallib_est =(-1(1)2)) 
marginsplot

//Unpaid work
logit dissolve_lag i.dur i.housework_bkt##c.masssociallib_est TAXABLE_HEAD_WIFE_ if couple_educ_gp==0 & housework_bkt!=4, or  // nothing sig
margins housework_bkt, at(masssociallib_est =(-1(1)2)) 
marginsplot

logit dissolve_lag i.dur i.housework_bkt##c.masssociallib_est TAXABLE_HEAD_WIFE_ if couple_educ_gp==1 & housework_bkt!=4, or // nothing sig
margins housework_bkt, at(masssociallib_est =(-1(1)2)) 
marginsplot

** Social policy
policysociallib_est

// total earnings
logit dissolve_lag i.dur policysociallib_est if couple_educ_gp==0, or // no association
logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.policysociallib_est if couple_educ_gp==0, or // main effect of income is negative
margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) policysociallib_est =(-2(1)2))
marginsplot

logit dissolve_lag i.dur policysociallib_est if couple_educ_gp==1, or // negative
logit dissolve_lag i.dur c.TAXABLE_HEAD_WIFE_##c.policysociallib_est if couple_educ_gp==1, or // interaction sig
margins, at(TAXABLE_HEAD_WIFE_ =(0(10000)100000) policysociallib_est =(-2(1)2)) // income more of a buffer in socially conservative places?
marginsplot

//Paid work
logit dissolve_lag i.dur i.hh_earn_type##c.policysociallib_est TAXABLE_HEAD_WIFE_ if couple_educ_gp==0, or  // main effect negative (so at dual earning?) and female BW interaction positive
margins hh_earn_type, at(policysociallib_est =(-2(1)2)) // so female BW bad when policy is liberal - so it IS necessity?!
marginsplot

logit dissolve_lag i.dur i.hh_earn_type##c.policysociallib_est TAXABLE_HEAD_WIFE_ if couple_educ_gp==1, or  // female BW main effect - so when more conservative, female BW is bad?
margins hh_earn_type, at(policysociallib_est =(-2(1)2)) 
marginsplot

//Unpaid work
logit dissolve_lag i.dur i.housework_bkt##c.policysociallib_est TAXABLE_HEAD_WIFE_ if couple_educ_gp==0 & housework_bkt!=4, or  // male primary main effect
margins housework_bkt, at(policysociallib_est =(-2(1)2)) 
marginsplot

logit dissolve_lag i.dur i.housework_bkt##c.policysociallib_est TAXABLE_HEAD_WIFE_ if couple_educ_gp==1 & housework_bkt!=4, or // nothing sig
margins housework_bkt, at(policysociallib_est =(-2(1)2)) 
marginsplot
*/