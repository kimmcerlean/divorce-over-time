********************************************************************************
* Marriage dissolution models
* marriage_analysis.do
* Kim McErlean
********************************************************************************

use "$data_keep\PSID_marriage_recoded_sample.dta", clear // created in 1a - no longer using my original order

gen cohort=.
replace cohort=1 if inrange(rel_start_all,1969,1979)
replace cohort=2 if inrange(rel_start_all,1980,1989)
replace cohort=3 if inrange(rel_start_all,1990,2010)
replace cohort=4 if inrange(rel_start_all,2011,2019)

tab cohort dissolve, row

gen cohort_alt=.
replace cohort_alt=1 if inrange(rel_start_all,1969,1979)
replace cohort_alt=2 if inrange(rel_start_all,1980,1989)
replace cohort_alt=3 if inrange(rel_start_all,1990,1999)
replace cohort_alt=4 if inrange(rel_start_all,2000,2014)

label define cohort 1 "pre-1980s" 2 "1980s" 3 "1990s" 4 "2000s"
label value cohort_alt cohort

tab cohort_alt dissolve, row

// keep if cohort==3, need to just use filters so I don't have to keep using and updating the data
// need to decide - ALL MARRIAGES or just first? - killewald restricts to just first, so does cooke. My validation is MUCH BETTER against those with first marraiges only...
keep if marriage_order_real==1
keep if (AGE_REF_>=18 & AGE_REF_<=55) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=55)

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

// control variables: age of marriage (both), race (head + same race), religion (head), region? (head), cohab_with_wife, cohab_with_other, pre_marital_birth, post_marital_birth
// both pre and post marital birth should NOT be in model because they are essentially inverse. do I want to add if they have a child together as new flag?
// taking out religion for now because not asked in 1968 / 1968
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
* For PAA
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
** No College
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_type if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==3 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_earn_pct if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_earn_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_earn_type if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(6 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_earn_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(6 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.ft_head i.ft_wife if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // employment
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(7 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.ft_head i.ft_wife TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // employment
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(7 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hours_diff_bkt if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // dissimilarity - paid hoUrs
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(8 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hours_diff_bkt TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // dissimilarity - paid hoUrs
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(8 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hw_diff_bkt if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // dissimilarity - UNpaid hoUrs
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(9 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hw_diff_bkt TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // dissimilarity - UNpaid hoUrs
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(9 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hours_type_hw if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // combo
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(10 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hours_type_hw TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // dcombo
outreg2 using "$results/psid_marriage_dissolution_nocoll_paa.xls", sideway stats(coef pval) label ctitle(10 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==3 & couple_educ_gp==0, or // housework - bucketed
margins housework_bkt

* margins for charts
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous paid hours - discrete time
margins, at(female_hours_pct=(0 (.1) 1 ))

logit dissolve_lag i.dur female_earn_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous earnings
margins, at(female_earn_pct=(0 (.1) 1 ))

logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous housework
margins, at(wife_housework_pct=(0 (.1) 1 ))

** College
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous paid hours - discrete time
margins, at(female_hours_pct=(0 (.1) 1 ))


logit dissolve_lag i.dur i.hh_hours_type if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==3 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_earn_pct if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_earn_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_earn_type if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(6 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_earn_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(6 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"
logit dissolve_lag i.dur ib3.hh_earn_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // earnings - bucketed
margins hh_earn_type

logit dissolve_lag i.dur i.ft_head i.ft_wife if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // employment
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(7 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.ft_head i.ft_wife TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // employment
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(7 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hours_diff_bkt if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // dissimilarity - paid hoUrs
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(8 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hours_diff_bkt TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // dissimilarity - paid hoUrs
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(8 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hw_diff_bkt if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // dissimilarity - UNpaid hoUrs
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(9 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hw_diff_bkt TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // dissimilarity - UNpaid hoUrs
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(9 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hours_type_hw if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // combo
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(10 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hours_type_hw TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // dcombo
outreg2 using "$results/psid_marriage_dissolution_college_paa.xls", sideway stats(coef pval) label ctitle(10 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

* margins for charts
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous paid hours - discrete time
margins, at(female_hours_pct=(0 (.1) 1 ))

logit dissolve_lag i.dur female_earn_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous earnings
margins, at(female_earn_pct=(0 (.1) 1 ))

logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous housework
margins, at(wife_housework_pct=(0 (.1) 1 ))


** Overall
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth i.couple_educ_gp"

logit dissolve_lag i.dur female_hours_pct if inlist(IN_UNIT,1,2) & cohort==3, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_type if inlist(IN_UNIT,1,2) & cohort==3, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct if inlist(IN_UNIT,1,2) & cohort==3, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt if inlist(IN_UNIT,1,2) & cohort==3, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==3, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_earn_pct if inlist(IN_UNIT,1,2) & cohort==3, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_earn_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_earn_type if inlist(IN_UNIT,1,2) & cohort==3, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(6 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_earn_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(6 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.ft_head i.ft_wife if inlist(IN_UNIT,1,2) & cohort==3, or // employment
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(7 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.ft_head i.ft_wife TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3, or // employment
outreg2 using "$results/psid_marriage_dissolution_total_paa.xls", sideway stats(coef pval) label ctitle(7 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append


********************************************************************************
* Exploration
********************************************************************************
/*
logit dissolve_lag i.dur i.hours_type_hw if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4), or // dual as ref
logit dissolve_lag i.dur ib5.hours_type_hw if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4), or // male BW / female HM as ref

logit dissolve_lag i.dur i.hours_type_hw if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or // dual as ref
logit dissolve_lag i.dur i.hours_type_hw if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or // dual as ref

logit dissolve_lag i.dur i.earn_type_hw if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or // dual as ref
margins earn_type_hw
marginsplot
logit dissolve_lag i.dur i.earn_type_hw if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or // dual as ref
margins earn_type_hw
marginsplot

logit dissolve_lag i.dur i.hours_diff_bkt if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or // dual as ref
logit dissolve_lag i.dur i.hours_diff_bkt if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or // dual as ref
*/

********************************************************************************
* No College
********************************************************************************
** Cohort A (1990-1999)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_type if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort_alt==3 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_earn_pct if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_earn_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_earn_type if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(6 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_earn_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(6 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.ft_head i.ft_wife if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or // employment
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(7 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.ft_head i.ft_wife TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==0, or // employment
outreg2 using "$results/psid_marriage_dissolution_nocoll_A.xls", sideway stats(coef pval) label ctitle(7 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

** Cohort B (2000-2014)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_type if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort_alt==4 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_earn_pct if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_earn_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_earn_type if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(6 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_earn_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(6 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.ft_head i.ft_wife if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or // employment
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(7 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.ft_head i.ft_wife TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==0, or // employment
outreg2 using "$results/psid_marriage_dissolution_nocoll_B.xls", sideway stats(coef pval) label ctitle(7 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

** Cohort C (1990-2014)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_type if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & inlist(cohort_alt,3,4) & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_earn_pct if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_earn_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_earn_type if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(6 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_earn_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(6 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.ft_head i.ft_wife if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or // employment
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(7 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.ft_head i.ft_wife TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==0, or // employment
outreg2 using "$results/psid_marriage_dissolution_nocoll_C.xls", sideway stats(coef pval) label ctitle(7 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

********************************************************************************
* College
********************************************************************************
** Cohort A (1990-1999)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_type if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort_alt==3 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_earn_pct if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_earn_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_earn_type if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(6 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_earn_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(6 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.ft_head i.ft_wife if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or // employment
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(7 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.ft_head i.ft_wife TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==3 & couple_educ_gp==1, or // employment
outreg2 using "$results/psid_marriage_dissolution_college_A.xls", sideway stats(coef pval) label ctitle(7 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

** Cohort B (2000-2014)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_type if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort_alt==4 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_earn_pct if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_earn_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_earn_type if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(6 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_earn_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(6 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.ft_head i.ft_wife if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or // employment
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(7 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.ft_head i.ft_wife TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort_alt==4 & couple_educ_gp==1, or // employment
outreg2 using "$results/psid_marriage_dissolution_college_B.xls", sideway stats(coef pval) label ctitle(7 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

** Cohort C (1990-2014)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_type if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & inlist(cohort_alt,3,4) & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_earn_pct if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_earn_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or //  continuous earnings
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_earn_type if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(6 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_earn_type TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or // earnings - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(6 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.ft_head i.ft_wife if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or // employment
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(7 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.ft_head i.ft_wife TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or // employment
outreg2 using "$results/psid_marriage_dissolution_college_C.xls", sideway stats(coef pval) label ctitle(7 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append



logit dissolve_lag i.dur ib3.bw_type if inlist(IN_UNIT,1,2) & inlist(cohort_alt,3,4) & couple_educ_gp==1, or
logit dissolve_lag i.dur ib3.bw_type if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or
logit dissolve_lag i.dur i.dual_hw if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or


********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
* Over historical time models
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
/*
********************************************************************************
* Overall models
********************************************************************************
** Cohort 1 (1970s)
logit dissolve_lag i.dur female_hours_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_overall_1970s.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2) & cohort==1, or //  continuous paid hours - with controls
outreg2 using "$results/psid_marriage_dissolution_overall_1970s.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_3070 i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1970s.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_3070 i.couple_educ_gp TAXABLE_HEAD_WIFE_ `controls'  if inlist(IN_UNIT,1,2) & cohort==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1970s.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_overall_1970s.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ `controls'  if inlist(IN_UNIT,1,2) & cohort==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_overall_1970s.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1970s.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt i.couple_educ_gp TAXABLE_HEAD_WIFE_ `controls'  if inlist(IN_UNIT,1,2) & cohort==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1970s.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==1, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_overall_1970s.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ i.couple_educ_gp `controls' if inlist(IN_UNIT,1,2) & cohort==1, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_overall_1970s.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

** Cohort 2 (1980s)
logit dissolve_lag i.dur female_hours_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_overall_1980s.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth if inlist(IN_UNIT,1,2) & cohort==2, or //  continuous paid hours - with controls
outreg2 using "$results/psid_marriage_dissolution_overall_1980s.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_3070 i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1980s.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_3070 i.couple_educ_gp TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth if inlist(IN_UNIT,1,2) & cohort==2, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1980s.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_overall_1980s.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth if inlist(IN_UNIT,1,2) & cohort==2, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_overall_1980s.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1980s.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt i.couple_educ_gp TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth if inlist(IN_UNIT,1,2) & cohort==2, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1980s.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==2, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_overall_1980s.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ i.couple_educ_gp age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth if inlist(IN_UNIT,1,2) & cohort==2, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_overall_1980s.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

** Cohort 3 (1990s)
logit dissolve_lag i.dur female_hours_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_overall_1990s.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth if inlist(IN_UNIT,1,2) & cohort==3, or //  continuous paid hours - with controls
outreg2 using "$results/psid_marriage_dissolution_overall_1990s.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_3070 i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1990s.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_3070 i.couple_educ_gp TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth if inlist(IN_UNIT,1,2) & cohort==3, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1990s.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_overall_1990s.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct i.couple_educ_gp TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth if inlist(IN_UNIT,1,2) & cohort==3, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_overall_1990s.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.housework_bkt i.couple_educ_gp TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1990s.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt i.couple_educ_gp TAXABLE_HEAD_WIFE_ age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth if inlist(IN_UNIT,1,2) & cohort==3, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_overall_1990s.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_overall_1990s.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ i.couple_educ_gp age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth if inlist(IN_UNIT,1,2) & cohort==3, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_overall_1990s.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append


********************************************************************************
* No College
********************************************************************************
** Cohort 1 (1970s)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_1970s.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_1970s.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1970s.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1970s.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_1970s.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_1970s.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) appen

logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1970s.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==1 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1970s.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==0, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_nocoll_1970s.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==0, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_nocoll_1970s.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

** Cohort 2 (1980s)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_1980s.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==2 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_1980s.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1980s.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==2 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1980s.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_1980s.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_1980s.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) appen

logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1980s.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2)  & cohort==2 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1980s.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==0, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_nocoll_1980s.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==0, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_nocoll_1980s.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

** Cohort 3 (1990s)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_1990.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ `controls'  if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_nocoll_1990.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1990.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==3 & couple_educ_gp==0, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1990.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_1990.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2)  & cohort==3 & couple_educ_gp==0, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_nocoll_1990.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) appen

logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1990.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==3 & couple_educ_gp==0, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_nocoll_1990.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_nocoll_1990.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_nocoll_1990.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

// for future comparison: employment
logit dissolve_lag i.dur i.ft_head if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // men's
logit dissolve_lag i.dur i.ft_head TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // men's
logit dissolve_lag i.dur i.ft_wife if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // women's
logit dissolve_lag i.dur i.ft_wife TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // women's
logit dissolve_lag i.dur i.ft_head i.ft_wife if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // both
logit dissolve_lag i.dur i.ft_head i.ft_wife TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or // both

logit dissolve_lag i.dur i.ft_head if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // men's
logit dissolve_lag i.dur i.ft_head TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // men's
logit dissolve_lag i.dur i.ft_wife if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // women's
logit dissolve_lag i.dur i.ft_wife TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // women's
logit dissolve_lag i.dur i.ft_head i.ft_wife if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // both
logit dissolve_lag i.dur i.ft_head i.ft_wife TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // both

********************************************************************************
* College
********************************************************************************
** Cohort 1 (1970s)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_1970s.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_1970s.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1970s.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1970s.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_1970s.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_1970s.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) appen

logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1970s.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==1 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1970s.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==1, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_college_1970s.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==1, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_college_1970s.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

** Cohort 2 (1980s)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_1980s.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==2 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_1980s.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1980s.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==2 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1980s.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_1980s.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_1980s.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) appen

logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1980s.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2)  & cohort==2 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1980s.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==1, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_college_1980s.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==1, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_college_1980s.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

** Cohort 3 (1990s)
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"

logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_1990.xls", sideway stats(coef pval) label ctitle(1 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ `controls'  if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous paid hours - discrete time
outreg2 using "$results/psid_marriage_dissolution_college_1990.xls", sideway stats(coef pval) label ctitle(1 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1990.xls", sideway stats(coef pval) label ctitle(2 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==3 & couple_educ_gp==1, or // paid hours - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1990.xls", sideway stats(coef pval) label ctitle(2 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_1990.xls", sideway stats(coef pval) label ctitle(3 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2)  & cohort==3 & couple_educ_gp==1, or //  continuous housework
outreg2 using "$results/psid_marriage_dissolution_college_1990.xls", sideway stats(coef pval) label ctitle(3 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) appen

logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1990.xls", sideway stats(coef pval) label ctitle(4 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==3 & couple_educ_gp==1, or // housework - bucketed
outreg2 using "$results/psid_marriage_dissolution_college_1990.xls", sideway stats(coef pval) label ctitle(4 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_college_1990.xls", sideway stats(coef pval) label ctitle(5 Base) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
logit dissolve_lag i.dur female_hours_pct wife_housework_pct TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // continuous paid and unpaid hours income coefficients to use
outreg2 using "$results/psid_marriage_dissolution_college_1990.xls", sideway stats(coef pval) label ctitle(5 Controls) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

// should not have both births in same model because they are essentially inverse. if anything, pre-marital birth flag, then do they have a child together as another flag (might not be their first); look into this
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth"
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous paid hours - discrete time
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ `controls'  if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or //  continuous paid hours - discrete time

logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or // paid hours - bucketed
logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ `controls' if inlist(IN_UNIT,1,2)  & cohort==3 & couple_educ_gp==1, or // paid hours - bucketed
*/

**Testing time interaction (college)
logit dissolve_lag i.dur c.female_hours_pct##i.cohort TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & couple_educ_gp==1 & cohort <4, or //  continuous paid hours - discrete time
margins, at(cohort=(1 2 3) female_hours_pct=(.1(.2).9))

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth post_marital_birth"

logit dissolve_lag i.dur i.hh_hours_3070##i.cohort TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & couple_educ_gp==1 & cohort <4 & hh_hours_3070<4, or // paid hours - bucketed
margins cohort#hh_hours_3070
marginsplot

**Testing interaction in 1990s with class
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled REGION_ cohab_with_wife cohab_with_other pre_marital_birth post_marital_birth"

logit dissolve_lag i.dur c.female_hours_pct##i.couple_educ_gp TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3, or //  continuous paid hours - discrete time
margins, at(couple_educ_gp=(0 1) female_hours_pct=(.1(.2).9))
marginsplot

logit dissolve_lag i.dur i.hh_hours_3070##i.couple_educ_gp TAXABLE_HEAD_WIFE_  `controls' if inlist(IN_UNIT,1,2) & cohort==3 & hh_hours_3070<4, or // paid hours - bucketed
margins couple_educ_gp#hh_hours_3070
marginsplot


**** Race differences
logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3 & race_wife==1, or //  continuous paid hours - discrete time
logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3 & race_wife==1, or // paid hours - bucketed
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3 & race_wife==1, or //  continuous housework
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3 & race_wife==1, or // housework - bucketed

logit dissolve_lag i.dur female_hours_pct TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3 & race_wife==2, or //  continuous paid hours - discrete time
// for blacks, WITHOUT controls, female hours are actually stabilizing
logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3 & race_wife==2, or // paid hours - bucketed
// AND without controls, male BW = more risk
logit dissolve_lag i.dur wife_housework_pct TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3 & race_wife==2, or //  continuous housework
logit dissolve_lag i.dur i.housework_bkt TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3 & race_wife==2, or // housework - bucketed

logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0 & race_wife==2, or // paid hours - bucketed
logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0 & race_wife==1, or // paid hours - bucketed

logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1 & race_wife==2, or // paid hours - bucketed
logit dissolve_lag i.dur i.hh_hours_3070 TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1 & race_wife==1, or // paid hours - bucketed


********************************************************************************
* Misc
********************************************************************************

tab hh_earn_type_bkd, sum(TAXABLE_HEAD_WIFE_)

// margins for figure
local controls "i.race_head i.same_race i.children i.either_enrolled TAXABLE_HEAD_WIFE_ i.religion_head age_mar_head age_mar_wife"
logit dissolve_lag dur i.hh_earn_type_bkd `controls' if couple_educ_gp==0 & inlist(IN_UNIT,1,2), or
margins hh_earn_type_bkd

logit dissolve_lag dur i.hh_earn_type_bkd `controls' if couple_educ_gp==1 & inlist(IN_UNIT,1,2), or
margins hh_earn_type_bkd

********************************************************************************
*Quick descriptives for proposal
********************************************************************************
// total
tab couple_educ_gp
unique id, by(couple_educ_gp)

tab couple_educ_gp hh_earn_type_bkd, row
tab couple_educ_gp hh_earn_type_mar, row
tabstat female_earn_pct, by(couple_educ_gp)
tab couple_educ_gp ft_head, row
tab couple_educ_gp ft_wife, row
tabstat wife_housework_pct, by(couple_educ_gp)
tabstat TAXABLE_HEAD_WIFE_, by(couple_educ_gp) stat(mean p50)
 
// dissolved
tab couple_educ_gp if dissolve_lag==1
unique id if dissolve_lag==1, by(couple_educ_gp)

tab couple_educ_gp hh_earn_type_bkd if dissolve_lag==1, row
tab couple_educ_gp hh_earn_type_mar if dissolve_lag==1, row
tabstat female_earn_pct if dissolve_lag==1, by(couple_educ_gp)
tab couple_educ_gp ft_head if dissolve_lag==1, row
tab couple_educ_gp ft_wife if dissolve_lag==1, row
tabstat wife_housework_pct if dissolve_lag==1, by(couple_educ_gp)
tabstat TAXABLE_HEAD_WIFE_ if dissolve_lag==1, by(couple_educ_gp) stat(mean p50)

// pie chart
tab couple_educ_gp hh_earn_type_bkd if dissolve_lag==1, row nofreq
tab couple_educ_gp hh_earn_type_bkd if dissolve_lag==0, row nofreq // intact for ref
 
********************************************************************************
*PAA
********************************************************************************
 // all
tab couple_educ_gp if cohort==3
unique id if cohort==3, by(couple_educ_gp) // unique couples
unique id if cohort==3 & dissolve_lag==1, by(couple_educ_gp) // dissolutions

tabstat female_hours_pct  if cohort==3, by(couple_educ_gp)
tab couple_educ_gp hh_hours_type if cohort==3, row
tabstat female_earn_pct  if cohort==3, by(couple_educ_gp)
tab couple_educ_gp hh_earn_type if cohort==3, row
tabstat wife_housework_pct if cohort==3, by(couple_educ_gp)
tab couple_educ_gp housework_bkt if cohort==3, row
tab couple_educ_gp ft_head if cohort==3, row
tab couple_educ_gp ft_wife if cohort==3, row
tabstat TAXABLE_HEAD_WIFE_ if cohort==3, by(couple_educ_gp) stat(mean p50)

// dissolved
tabstat female_hours_pct  if cohort==3 & dissolve_lag==1, by(couple_educ_gp)
tab couple_educ_gp hh_hours_type if cohort==3 & dissolve_lag==1, row
tabstat female_earn_pct  if cohort==3 & dissolve_lag==1, by(couple_educ_gp)
tab couple_educ_gp hh_earn_type if cohort==3 & dissolve_lag==1, row
tabstat wife_housework_pct if cohort==3 & dissolve_lag==1, by(couple_educ_gp)
tab couple_educ_gp housework_bkt if cohort==3 & dissolve_lag==1, row
tab couple_educ_gp ft_head if cohort==3 & dissolve_lag==1, row
tab couple_educ_gp ft_wife if cohort==3 & dissolve_lag==1, row
tabstat TAXABLE_HEAD_WIFE_ if cohort==3 & dissolve_lag==1, by(couple_educ_gp) stat(mean p50)


********************************************************************************
*Updated descriptives for proposal revision
********************************************************************************
 // 1970-1979
tab couple_educ_gp if cohort==1
unique id if cohort==1, by(couple_educ_gp) // unique couples
unique id if cohort==1 & dissolve_lag==1, by(couple_educ_gp) // dissolutions

tabstat female_hours_pct  if cohort==1, by(couple_educ_gp)
tab couple_educ_gp hh_hours_3070 if cohort==1, row
tabstat wife_housework_pct if cohort==1, by(couple_educ_gp)
tab couple_educ_gp housework_bkt if cohort==1, row
tabstat TAXABLE_HEAD_WIFE_ if cohort==1, by(couple_educ_gp) stat(mean p50)

 // 1980-1989
tab couple_educ_gp if cohort==2
unique id if cohort==2, by(couple_educ_gp) // unique couples
unique id if cohort==2 & dissolve_lag==1, by(couple_educ_gp) // dissolutions

tabstat female_hours_pct  if cohort==2, by(couple_educ_gp)
tab couple_educ_gp hh_hours_3070 if cohort==2, row
tabstat wife_housework_pct if cohort==2, by(couple_educ_gp)
tab couple_educ_gp housework_bkt if cohort==2, row
tabstat TAXABLE_HEAD_WIFE_ if cohort==2, by(couple_educ_gp) stat(mean p50)

 // 1990-2010
tab couple_educ_gp if cohort==3
unique id if cohort==3, by(couple_educ_gp) // unique couples
unique id if cohort==3 & dissolve_lag==1, by(couple_educ_gp) // dissolutions

tabstat female_hours_pct  if cohort==3, by(couple_educ_gp)
tab couple_educ_gp hh_hours_3070 if cohort==3, row
tabstat wife_housework_pct if cohort==3, by(couple_educ_gp)
tab couple_educ_gp housework_bkt if cohort==3, row
tabstat TAXABLE_HEAD_WIFE_ if cohort==3, by(couple_educ_gp) stat(mean p50)

/*
********************************************************************************
* Year interactions
********************************************************************************

use "$data_keep\PSID_marriage_recoded_sample.dta", clear // created in 1a - no longer using my original order

gen cohort=.
replace cohort=1 if inrange(rel_start_all,1969,1979)
replace cohort=2 if inrange(rel_start_all,1980,1989)
replace cohort=3 if inrange(rel_start_all,1990,2010)
replace cohort=4 if inrange(rel_start_all,2011,2019)

tab cohort dissolve, row

drop if cohort==4
// need to decide - ALL MARRIAGES or just first? - killewald restricts to just first, so does cooke. My validation is MUCH BETTER against those with first marraiges only...
keep if marriage_order_real==1
keep if (AGE_REF_>=18 & AGE_REF_<=55) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=55)

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

// test spline at 0.5
mkspline ratio1 0.5 ratio2 = female_earn_pct
browse female_earn_pct ratio1 ratio2 

// want to create time-invariant indicator of hh type in first year of marriage (but need to make sure it's year both spouses in hh) - some started in of year gah. use DUR? or rank years and use first rank? (actually is that a better duration?)
browse id survey_yr rel_start_all dur hh_earn_type_bkd
bysort id (survey_yr): egen yr_rank=rank(survey_yr)
gen hh_earn_type_mar = hh_earn_type_bkd if yr_rank==1
bysort id (hh_earn_type_mar): replace hh_earn_type_mar=hh_earn_type_mar[1]
label values hh_earn_type_mar earn_type_bkd

browse id survey_yr rel_start_all yr_rank dur hh_earn_type_bkd hh_earn_type_mar

drop if hours_housework==8 // no earners; skewing, especially for college

// validate
logit dissolve_lag dur i.hh_hours_3070##i.housework_bkt TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3, or
logit dissolve_lag dur i.hours_housework TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3, or
logit dissolve_lag dur ib4.hours_housework TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3, or

logit dissolve_lag dur i.cohort##ib4.hours_housework TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2), or
margins cohort#hours_housework
marginsplot

logit dissolve_lag dur i.cohort##ib4.hours_housework TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & couple_educ_gp==0, or
margins cohort#hours_housework
marginsplot

logit dissolve_lag dur i.cohort##ib4.hours_housework TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & couple_educ_gp==1, or
margins cohort#hours_housework
marginsplot

// want coefficients for each year
logit dissolve_lag dur ib4.hours_housework TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==1, or
logit dissolve_lag dur ib4.hours_housework TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==2, or
logit dissolve_lag dur ib4.hours_housework TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3, or

logit dissolve_lag dur ib4.hours_housework TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==0, or
logit dissolve_lag dur ib4.hours_housework TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==0, or
logit dissolve_lag dur ib4.hours_housework TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or

logit dissolve_lag dur ib4.hours_housework TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==1, or
logit dissolve_lag dur ib4.hours_housework TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==1, or
logit dissolve_lag dur ib4.hours_housework TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or

recode hours_housework (1=3) (2=2) (3=5) (4=1) (5=5) (6=4) (7=5), gen(config)
label define config 1 "Conventional" 2 "Neotraditional" 3 "Egal" 4 "Doing gender" 5 "Gender-atypical"
label values config config

// want coefficients for each year
logit dissolve_lag dur i.config TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==1, or
logit dissolve_lag dur i.config TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==2, or
logit dissolve_lag dur i.config TAXABLE_HEAD_WIFE_ i.couple_educ_gp if inlist(IN_UNIT,1,2) & cohort==3, or

logit dissolve_lag dur i.config TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==0, or
logit dissolve_lag dur i.config TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==0, or
logit dissolve_lag dur i.config TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==0, or

logit dissolve_lag dur i.config TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==1 & couple_educ_gp==1, or
logit dissolve_lag dur i.config TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==2 & couple_educ_gp==1, or
logit dissolve_lag dur i.config TAXABLE_HEAD_WIFE_ if inlist(IN_UNIT,1,2) & cohort==3 & couple_educ_gp==1, or
*/

