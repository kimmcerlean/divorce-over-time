********************************************************************************
* Getting PSID sample for union dissolution
* create_comparison_sample.do
* Kim McErlean
********************************************************************************

* Instead of just keeping those with relationship start 20000 - keeping those later, to try to validate other findings (e.g. Killewald, Schwartz and GP). Since just marriage, can also do prior to 1983?

use "$data_tmp\PSID_full_long.dta", clear // created in other step 1

********************************************************************************
* First clean up to get a sense of WHO is even eligible
********************************************************************************

browse survey_yr id main_per_id SEQ_NUMBER_ RELATION_ FIRST_MARRIAGE_YR_START MARITAL_PAIRS_

// drop if survey_yr <1983 // first time you could identify cohab

gen relationship=0
replace relationship=1 if inrange(MARITAL_PAIRS_,1,4)

browse survey_yr id main_per_id SEQ_NUMBER_ relationship RELATION_ FIRST_MARRIAGE_YR_START 

bysort id (SEQ_NUMBER_): egen in_sample=max(SEQ_NUMBER_)

drop if in_sample==0 // people with NO DATA in any year
drop if SEQ_NUMBER_==0 // won't have data because not in that year -- like SIPP, how do I know if last year is because divorced or last year in sample? right now individual level file, so fine - this is JUST last year in sample at the moment

browse survey_yr id main_per_id relationship RELATION_ FIRST_MARRIAGE_YR_START FIRST_MARRIAGE_YR_HEAD_ FIRST_MARRIAGE_YR_END RECENT_MARRIAGE_YR_START 

browse id survey_yr relationship MARITAL_STATUS_HEAD_
gen relationship_yr = survey_yr if relationship==1
sort id survey_yr
gen enter_rel=0
replace enter_rel=1 if relationship==1 & relationship[_n-1]==0 & id==id[_n-1]
replace enter_rel=1 if relationship_yr==1968 // since can't transition, but call this "relationship 1"

gen exit_rel=0
sort id survey_yr
replace exit_rel=1 if relationship==1 & relationship[_n+1]==0 & id==id[_n+1]
// replace exit_rel=1 if relationship==0 & relationship[_n-1]==1 & id==id[_n-1]

browse id survey_yr relationship enter_rel MARITAL_STATUS_HEAD_ exit_rel

gen relationship_start = survey_yr if enter_rel==1
bysort id: egen marrno=rank(relationship_start)
browse id survey_yr MARITAL_STATUS_HEAD_ enter_rel relationship_start FIRST_MARRIAGE_YR_START marrno

gen rel1_start=.
replace rel1_start = FIRST_MARRIAGE_YR_START if FIRST_MARRIAGE_YR_START <=2019
replace rel1_start=relationship_start if marrno==1 & FIRST_MARRIAGE_YR_START==9999
bysort id (rel1_start): replace rel1_start=rel1_start[1]
gen rel2_start=.
replace rel2_start = RECENT_MARRIAGE_YR_START if RECENT_MARRIAGE_YR_START <=2019
replace rel2_start=relationship_start if marrno==2 & RECENT_MARRIAGE_YR_START ==9999
bysort id (rel2_start): replace rel2_start=rel2_start[1]
gen rel3_start=.
replace rel3_start=relationship_start if marrno==3
bysort id (rel3_start): replace rel3_start=rel3_start[1]

sort id survey_yr
browse id survey_yr MARITAL_STATUS_HEAD_ enter_rel relationship_start rel1_start FIRST_MARRIAGE_YR_START rel2_start marrno

gen relationship_end = survey_yr if exit_rel==1
bysort id: egen exitno=rank(relationship_end)
browse id survey_yr MARITAL_STATUS_HEAD_ enter_rel relationship_start exitno

gen rel1_end=.
replace rel1_end=relationship_end if exitno==1
bysort id (rel1_end): replace rel1_end=rel1_end[1]
gen rel2_end=.
replace rel2_end=relationship_end if exitno==2
bysort id (rel2_end): replace rel2_end=rel2_end[1]
gen rel3_end=.
replace rel3_end=relationship_end if exitno==3
bysort id (rel3_end): replace rel3_end=rel3_end[1]

browse id survey_yr relationship enter_rel marrno rel1_start rel1_end rel2_start rel2_end

gen rel_start_all=.
replace rel_start_all = rel1_start if survey_yr>=rel1_start & survey_yr <=rel1_end
replace rel_start_all = rel2_start if survey_yr>=rel2_start & survey_yr <=rel2_end
replace rel_start_all = rel3_start if survey_yr>=rel3_start & survey_yr <=rel3_end

gen rel_end_all=.
replace rel_end_all = rel1_end if survey_yr>=rel1_start & survey_yr <=rel1_end
replace rel_end_all = rel2_end if survey_yr>=rel2_start & survey_yr <=rel2_end
replace rel_end_all = rel3_end if survey_yr>=rel3_start & survey_yr <=rel3_end

browse id survey_yr relationship marrno  rel_start_all rel_end_all rel1_start rel1_end rel2_start rel2_end

gen relationship_order=.

forvalues r=1/3{
	replace relationship_order=`r' if survey_yr>=rel`r'_start & survey_yr <=rel`r'_end
}


browse id survey_yr relationship relationship_order rel_start_all rel_end_all rel1_start rel1_end rel2_start rel2_end

bysort id: egen last_survey_yr = max(survey_yr)

sort id survey_yr
browse id survey_yr relationship marrno  rel_start_all rel_end_all exit_rel

gen dissolve=0
replace dissolve=1 if exit_rel==1 & inlist(MARITAL_STATUS_HEAD_[_n+1],2,4,5) & id == id[_n+1]

sort id survey_yr
browse id survey_yr relationship MARITAL_STATUS_HEAD_ dissolve exit_rel rel_start_all rel_end_all

********************************************************************************
* Restrict to anyone in a relationship
********************************************************************************
gen total_relationship=relationship
replace total_relationship=1 if dissolve==1
keep if total_relationship==1 
browse id survey_yr relationship rel_start_all rel_end_all dissolve SEQ_NUMBER_ MARITAL_PAIRS_

// trying to identify if married or cohabiting. .. need relation_?
egen year_family=concat(survey_yr FAMILY_INTERVIEW_NUM_), punct(_)
keep if inlist(RELATION_,1,2,10,20,22)

bysort survey_yr FAMILY_INTERVIEW_NUM_ (RELATION_): egen either_cohab=max(RELATION_)

sort survey_yr FAMILY_INTERVIEW_NUM_ id

// drop if NUM_MARRIED==98

browse relationship dissolve MARITAL_STATUS_REF_ MARITAL_STATUS_HEAD_ COUPLE_STATUS_REF_ // marital status_head_ = MARRIED OR COHAB IWTH NO DISTINGUISH, marital_status_ref = official - so if DIVROCED, put as cohab?

browse id survey_yr relationship dissolve MARITAL_STATUS_REF_

gen relationship_type=0
replace relationship_type=1 if NUM_MARRIED==0
replace relationship_type=2 if NUM_MARRIED>=1
replace relationship_type=1 if either_cohab==22
replace relationship_type=1 if inrange(MARITAL_STATUS_REF_,2,9)
sort id survey_yr

label define relationship_type 1 "Cohab" 2 "Married"
label values relationship_type relationship_type

tab MARITAL_STATUS_REF_ relationship_type
tab relationship_type RELATION_

// drop if relationship_type==1
tab RELATION_ // okay pretty equal numbers.

sort id survey_yr
gen dur = survey_yr - rel_start_all
browse id survey_yr relationship_type rel_start_all rel_end_all dissolve dur
browse id survey_yr relationship_type rel_start_all rel_end_all dissolve dur if FAMILY_INTERVIEW_NUM_ == 7439

gen reltype1 = relationship_type if survey_yr>=rel1_start & survey_yr <=rel1_end
bysort id (reltype1): replace reltype1=reltype1[1]
gen reltype2 = relationship_type if survey_yr>=rel2_start & survey_yr <=rel2_end
bysort id (reltype2): replace reltype2=reltype2[1]
gen reltype3 = relationship_type if survey_yr>=rel3_start & survey_yr <=rel3_end
bysort id (reltype3): replace reltype3=reltype3[1]
label values reltype* relationship_type

sort id survey_yr
browse id survey_yr relationship_type rel_start_all rel_end_all reltype*

egen num_unions=rownonmiss(reltype1 reltype2 reltype3)
egen num_marriages=anycount(reltype1 reltype2 reltype3), values(2)
egen num_cohab=anycount(reltype1 reltype2 reltype3), values(1)

browse id survey_yr relationship_type reltype* num_unions num_marriages num_cohab

gen marriage_order=.

forvalues r=1/3{
	replace marriage_order=`r' if survey_yr>=rel`r'_start & survey_yr <=rel`r'_end & relationship_type==2 // gah it's labelling as 2 if two in order, not one.
}

gen marriage_order_real = marriage_order
replace marriage_order_real = num_marriages if marriage_order > num_marriages & marriage_order!=. & num_marriages!=. // think this isn't perfect if three relationships, but sufficient for now

browse id survey_yr relationship_type relationship_order marriage_order marriage_order_real rel_start_all rel_end_all num_unions num_marriages num_cohab 

save "$data_tmp\PSID_all_unions.dta", replace

********************************************************************************
* Recodes
********************************************************************************
// first need to figure out how to keep only one respondent per HH. really doesn't matter gender of who I keep, because all variables are denoted by head / wife, NOT respondent.
bysort survey_yr FAMILY_INTERVIEW_NUM_ : egen per_id = rank(id)
browse survey_yr FAMILY_INTERVIEW_NUM_  id per_id

browse survey_yr FAMILY_INTERVIEW_NUM_ per_id id if inlist(id,12,13)

keep if per_id==1

unique id, by(rel_start_all) // can I get this to match S&H?
unique id if dissolve==1, by(rel_start_all)
 
// education
browse survey_yr id  EDUC1_WIFE_ EDUC_WIFE_ EDUC1_HEAD_ EDUC_HEAD_
// educ1 until 1990, but educ started 1975, okay but then a gap until 1991? wife not asked 1969-1971 - might be able to fill in if she is in sample either 1968 or 1972? (match to the id)
// codes are also different between the two, use educ1 until 1990, then educ 1991 post

recode EDUC1_WIFE_ (1/3=1)(4/5=2)(6=3)(7/8=4)(9=.)(0=1), gen(educ_wife_early)
recode EDUC1_HEAD_ (1/3=1)(4/5=2)(6=3)(7/8=4)(9=.)(0=1), gen(educ_head_early)
recode EDUC_WIFE_ (0/11=1) (12=2) (13/15=3) (16/17=4) (99=.), gen(educ_wife_1975)
recode EDUC_HEAD_ (0/11=1) (12=2) (13/15=3) (16/17=4) (99=.), gen(educ_head_1975)

label define educ 1 "LTHS" 2 "HS" 3 "Some College" 4 "College"
label values educ_wife_early educ_head_early educ_wife_1975 educ_head_1975 educ

gen educ_wife=.
replace educ_wife=educ_wife_early if inrange(survey_yr,1968,1990)
replace educ_wife=educ_wife_1975 if inrange(survey_yr,1991,2019)

gen educ_head=.
replace educ_head=educ_head_early if inrange(survey_yr,1968,1990)
replace educ_head=educ_head_1975 if inrange(survey_yr,1991,2019)

label values educ_wife educ_head educ

	// trying to fill in missing wife years when possible
	browse id survey_yr educ_wife if inlist(id,3,12,25,117)
	bysort id (educ_wife): replace educ_wife=educ_wife[1] if educ_wife==.


gen college_complete_wife=0
replace college_complete_wife=1 if educ_wife==4
gen college_complete_head=0
replace college_complete_head=1 if educ_head==4

gen couple_educ_gp=0
replace couple_educ_gp=1 if (college_complete_wife==1 | college_complete_head==1)

label define couple_educ 0 "Neither College" 1 "At Least One College"
label values couple_educ_gp couple_educ

gen educ_type=.
replace educ_type=1 if educ_head > educ_wife
replace educ_type=2 if educ_head < educ_wife
replace educ_type=3 if educ_head == educ_wife

label define educ_type 1 "Hyper" 2 "Hypo" 3 "Homo"
label values educ_type educ_type


// income / structure
browse id survey_yr FAMILY_INTERVIEW_NUM_ TAXABLE_HEAD_WIFE_ TOTAL_FAMILY_INCOME_ LABOR_INCOME_HEAD_ WAGES_HEAD_  LABOR_INCOME_WIFE_ WAGES_WIFE_ 

	// to use: WAGES_HEAD_ WAGES_WIFE_ -- wife not asked until 1993? okay labor income??
	// wages and labor income asked for head whole time. labor income wife 1968-1993, wages for wife, 1993 onwards

gen earnings_wife=.
replace earnings_wife = LABOR_INCOME_WIFE_ if inrange(survey_yr,1968,1993)
replace earnings_wife = WAGES_WIFE_ if inrange(survey_yr,1994,2019)

gen earnings_head=.
replace earnings_head = LABOR_INCOME_HEAD_ if inrange(survey_yr,1968,1993)
replace earnings_head = WAGES_HEAD_ if inrange(survey_yr,1994,2019)

egen couple_earnings = rowtotal(earnings_wife earnings_head)

browse id survey_yr earnings_wife earnings_head couple_earnings
	
gen female_earn_pct = earnings_wife/(couple_earnings)

gen hh_earn_type_bkd=.
replace hh_earn_type_bkd=1 if female_earn_pct >=.4000 & female_earn_pct <=.6000
replace hh_earn_type_bkd=2 if female_earn_pct < .4000 & female_earn_pct > 0
replace hh_earn_type_bkd=3 if female_earn_pct ==0
replace hh_earn_type_bkd=4 if female_earn_pct > .6000 & female_earn_pct <=1
replace hh_earn_type_bkd=5 if earnings_head==0 & earnings_wife==0

label define earn_type_bkd 1 "Dual Earner" 2 "Male Primary" 3 "Male Sole" 4 "Female BW" 5 "No Earners"
label values hh_earn_type_bkd earn_type_bkd

sort id survey_yr
gen hh_earn_type_lag=.
replace hh_earn_type_lag=hh_earn_type_bkd[_n-1] if id==id[_n-1]
label values hh_earn_type_lag earn_type_bkd

gen female_earn_pct_lag=.
replace female_earn_pct_lag=female_earn_pct[_n-1] if id==id[_n-1]

browse id survey_yr earnings_head earnings_wife hh_earn_type_bkd hh_earn_type_lag
	
// restrict to working age (18-55) - at time of marriage or all? check what others do - Killewald said ages 18-55 - others have different restrictions, table this part for now
/*
browse id survey_yr AGE_ AGE_REF_ AGE_SPOUSE_ RELATION_
keep if (AGE_REF_>=18 & AGE_REF_<=55) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=55)
*/

// employment
browse id survey_yr EMPLOY_STATUS_HEAD_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS_WIFE_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_
// not numbered until 1994; 1-3 arose in 1994. codes match
// wife not asked until 1976?

gen employ_head=0
replace employ_head=1 if EMPLOY_STATUS_HEAD_==1
gen employ1_head=0
replace employ1_head=1 if EMPLOY_STATUS1_HEAD_==1
gen employ2_head=0
replace employ2_head=1 if EMPLOY_STATUS2_HEAD_==1
gen employ3_head=0
replace employ3_head=1 if EMPLOY_STATUS3_HEAD_==1
egen employed_head=rowtotal(employ_head employ1_head employ2_head employ3_head)

gen employ_wife=0
replace employ_wife=1 if EMPLOY_STATUS_WIFE_==1
gen employ1_wife=0
replace employ1_wife=1 if EMPLOY_STATUS1_WIFE_==1
gen employ2_wife=0
replace employ2_wife=1 if EMPLOY_STATUS2_WIFE_==1
gen employ3_wife=0
replace employ3_wife=1 if EMPLOY_STATUS3_WIFE_==1
egen employed_wife=rowtotal(employ_wife employ1_wife employ2_wife employ3_wife)

browse id survey_yr employed_head employed_wife employ_head employ1_head employ_wife employ1_wife

// problem is this employment is NOW not last year. I want last year? use if wages = employ=yes, then no? (or hours)
gen employed_ly_head=0
replace employed_ly_head=1 if earnings_head > 0 & earnings_head!=.

gen employed_ly_wife=0
replace employed_ly_wife=1 if earnings_wife > 0 & earnings_wife!=.

browse id survey_yr employed_ly_head employed_ly_wife WEEKLY_HRS_HEAD_ WEEKLY_HRS1_HEAD_ WEEKLY_HRS_WIFE_ WEEKLY_HRS1_WIFE_ earnings_head earnings_wife
// weekly_hrs not asked until 1994, was something asked PRIOR? i think I maybe didn't pull in GAH, use weekly_hrs1 prior to 1994 / 2001 is last yr
// okay wife bucketed 1968, real all other years? (1 or 2=PT; 3/8-FT)

gen ft_pt_head_pre=0
replace ft_pt_head_pre=1 if employed_ly_head==1 & WEEKLY_HRS1_HEAD_ >0 & WEEKLY_HRS1_HEAD_<=35
replace ft_pt_head_pre=2 if employed_ly_head==1 & WEEKLY_HRS1_HEAD_>35 & WEEKLY_HRS1_HEAD_!=.

gen ft_pt_head_post=0
replace ft_pt_head_post=1 if employed_ly_head==1 & WEEKLY_HRS_HEAD_ >0 & WEEKLY_HRS_HEAD_<=35
replace ft_pt_head_post=2 if employed_ly_head==1 & WEEKLY_HRS_HEAD_>35 & WEEKLY_HRS_HEAD_!=.

gen ft_pt_wife_pre=0
replace ft_pt_wife_pre=1 if employed_ly_wife==1 & WEEKLY_HRS1_WIFE_ >0 & WEEKLY_HRS1_WIFE_<=35 & survey_yr!=1968
replace ft_pt_wife_pre=2 if employed_ly_wife==1 & WEEKLY_HRS1_WIFE_>35 & WEEKLY_HRS1_WIFE_!=. & survey_yr!=1968
replace ft_pt_wife_pre=1 if employed_ly_wife==1 & inlist(WEEKLY_HRS1_WIFE_,1,2) & survey_yr==1968
replace ft_pt_wife_pre=2 if employed_ly_wife==1 & inrange(WEEKLY_HRS1_WIFE_,3,8) & survey_yr==1968

gen ft_pt_wife_post=0
replace ft_pt_wife_post=1 if employed_ly_wife==1 & WEEKLY_HRS_WIFE_ >0 & WEEKLY_HRS_WIFE_<=35
replace ft_pt_wife_post=2 if employed_ly_wife==1 & WEEKLY_HRS_WIFE_>35 & WEEKLY_HRS_WIFE_!=.

label define ft_pt 0 "Not Employed" 1 "PT" 2 "FT"
label values ft_pt_head_pre ft_pt_head_post ft_pt_wife_pre ft_pt_wife_post ft_pt

gen ft_pt_head=.
replace ft_pt_head = ft_pt_head_pre if inrange(survey_yr,1968,1993)
replace ft_pt_head = ft_pt_head_post if inrange(survey_yr,1994,2019)

gen ft_pt_wife=.
replace ft_pt_wife = ft_pt_wife_pre if inrange(survey_yr,1968,1993)
replace ft_pt_wife = ft_pt_wife_post if inrange(survey_yr,1994,2019)

label values ft_pt_head ft_pt_wife ft_pt

gen ft_head=0
replace ft_head=1 if ft_pt_head==2

gen ft_wife=0
replace ft_wife=1 if ft_pt_wife==2

// adding other controls right now, using same as SIPP analysis
gen either_enrolled=0
replace either_enrolled = 1 if ENROLLED_WIFE_==1 | ENROLLED_HEAD_==1

//race
drop if RACE_1_WIFE_==9 | RACE_1_HEAD_==9

browse id survey_yr RACE_1_WIFE_ RACE_2_WIFE_ RACE_3_WIFE_ RACE_1_HEAD_ RACE_2_HEAD_ RACE_3_HEAD_ RACE_4_HEAD_
// wait race of wife not asked until 1985?! that's wild. also need to see if codes changed in between. try to fill in historical for wife if in survey in 1985 and prior.
/*
1968-1984: 1=White; 2=Negro; 3=PR or Mexican; 7=Other
1985-1989: 1=White; 2=Black; 3=Am Indian 4=Asian 7=Other; 8 =more than 2
1990-2003: 1=White; 2=Black; 3=Am India; 4=Asian; 5=Latino; 6=Other; 7=Other
2005-2019: 1=White; 2=Black; 3=Am India; 4=Asian; 5=Native Hawaiian/Pac Is; 7=Other
*/


gen race_1_head_rec=.
replace race_1_head_rec=1 if RACE_1_HEAD_==1
replace race_1_head_rec=2 if RACE_1_HEAD_==2
replace race_1_head_rec=3 if (inrange(survey_yr,1985,2019) & RACE_1_HEAD_==3)
replace race_1_head_rec=4 if (inrange(survey_yr,1985,2019) & RACE_1_HEAD_==4)
replace race_1_head_rec=5 if (inrange(survey_yr,1968,1984) & RACE_1_HEAD_==3) | (inrange(survey_yr,1990,2003) & RACE_1_HEAD_==5)
replace race_1_head_rec=6 if RACE_1_HEAD_==7 | (inrange(survey_yr,1990,2003) & RACE_1_HEAD_==6) | (inrange(survey_yr,2005,2019) & RACE_1_HEAD_==5) | (inrange(survey_yr,1985,1989) & RACE_1_HEAD_==8)

gen race_2_head_rec=.
replace race_2_head_rec=1 if RACE_2_HEAD_==1
replace race_2_head_rec=2 if RACE_2_HEAD_==2
replace race_2_head_rec=3 if (inrange(survey_yr,1985,2019) & RACE_2_HEAD_==3)
replace race_2_head_rec=4 if (inrange(survey_yr,1985,2019) & RACE_2_HEAD_==4)
replace race_2_head_rec=5 if (inrange(survey_yr,1968,1984) & RACE_2_HEAD_==3) | (inrange(survey_yr,1990,2003) & RACE_2_HEAD_==5)
replace race_2_head_rec=6 if RACE_2_HEAD_==7 | (inrange(survey_yr,1990,2003) & RACE_2_HEAD_==6) | (inrange(survey_yr,2005,2019) & RACE_2_HEAD_==5) | (inrange(survey_yr,1985,1989) & RACE_2_HEAD_==8)

gen race_3_head_rec=.
replace race_3_head_rec=1 if RACE_3_HEAD_==1
replace race_3_head_rec=2 if RACE_3_HEAD_==2
replace race_3_head_rec=3 if (inrange(survey_yr,1985,2019) & RACE_3_HEAD_==3)
replace race_3_head_rec=4 if (inrange(survey_yr,1985,2019) & RACE_3_HEAD_==4)
replace race_3_head_rec=5 if (inrange(survey_yr,1968,1984) & RACE_3_HEAD_==3) | (inrange(survey_yr,1990,2003) & RACE_3_HEAD_==5)
replace race_3_head_rec=6 if RACE_3_HEAD_==7 | (inrange(survey_yr,1990,2003) & RACE_3_HEAD_==6) | (inrange(survey_yr,2005,2019) & RACE_3_HEAD_==5) | (inrange(survey_yr,1985,1989) & RACE_3_HEAD_==8)

gen race_4_head_rec=.
replace race_4_head_rec=1 if RACE_4_HEAD_==1
replace race_4_head_rec=2 if RACE_4_HEAD_==2
replace race_4_head_rec=3 if (inrange(survey_yr,1985,2019) & RACE_4_HEAD_==3)
replace race_4_head_rec=4 if (inrange(survey_yr,1985,2019) & RACE_4_HEAD_==4)
replace race_4_head_rec=5 if (inrange(survey_yr,1968,1984) & RACE_4_HEAD_==3) | (inrange(survey_yr,1990,2003) & RACE_4_HEAD_==5)
replace race_4_head_rec=6 if RACE_4_HEAD_==7 | (inrange(survey_yr,1990,2003) & RACE_4_HEAD_==6) | (inrange(survey_yr,2005,2019) & RACE_4_HEAD_==5) | (inrange(survey_yr,1985,1989) & RACE_4_HEAD_==8)

gen race_1_wife_rec=.
replace race_1_wife_rec=1 if RACE_1_WIFE_==1
replace race_1_wife_rec=2 if RACE_1_WIFE_==2
replace race_1_wife_rec=3 if (inrange(survey_yr,1985,2019) & RACE_1_WIFE_==3)
replace race_1_wife_rec=4 if (inrange(survey_yr,1985,2019) & RACE_1_WIFE_==4)
replace race_1_wife_rec=5 if (inrange(survey_yr,1968,1984) & RACE_1_WIFE_==3) | (inrange(survey_yr,1990,2003) & RACE_1_WIFE_==5)
replace race_1_wife_rec=6 if RACE_1_WIFE_==7 | (inrange(survey_yr,1990,2003) & RACE_1_WIFE_==6) | (inrange(survey_yr,2005,2019) & RACE_1_WIFE_==5) | (inrange(survey_yr,1985,1989) & RACE_1_WIFE_==8)

gen race_2_wife_rec=.
replace race_2_wife_rec=1 if RACE_2_WIFE_==1
replace race_2_wife_rec=2 if RACE_2_WIFE_==2
replace race_2_wife_rec=3 if (inrange(survey_yr,1985,2019) & RACE_2_WIFE_==3)
replace race_2_wife_rec=4 if (inrange(survey_yr,1985,2019) & RACE_2_WIFE_==4)
replace race_2_wife_rec=5 if (inrange(survey_yr,1968,1984) & RACE_2_WIFE_==3) | (inrange(survey_yr,1990,2003) & RACE_2_WIFE_==5)
replace race_2_wife_rec=6 if RACE_2_WIFE_==7 | (inrange(survey_yr,1990,2003) & RACE_2_WIFE_==6) | (inrange(survey_yr,2005,2019) & RACE_2_WIFE_==5) | (inrange(survey_yr,1985,1989) & RACE_2_WIFE_==8)

gen race_3_wife_rec=.
replace race_3_wife_rec=1 if RACE_3_WIFE_==1
replace race_3_wife_rec=2 if RACE_3_WIFE_==2
replace race_3_wife_rec=3 if (inrange(survey_yr,1985,2019) & RACE_3_WIFE_==3)
replace race_3_wife_rec=4 if (inrange(survey_yr,1985,2019) & RACE_3_WIFE_==4)
replace race_3_wife_rec=5 if (inrange(survey_yr,1968,1984) & RACE_3_WIFE_==3) | (inrange(survey_yr,1990,2003) & RACE_3_WIFE_==5)
replace race_3_wife_rec=6 if RACE_3_WIFE_==7 | (inrange(survey_yr,1990,2003) & RACE_3_WIFE_==6) | (inrange(survey_yr,2005,2019) & RACE_3_WIFE_==5) | (inrange(survey_yr,1985,1989) & RACE_3_WIFE_==8)

gen race_wife=race_1_wife_rec
replace race_wife=7 if race_2_wife_rec!=.

gen race_head=race_1_head_rec
replace race_head=7 if race_2_head_rec!=.

label define race 1 "White" 2 "Black" 3 "Indian" 4 "Asian" 5 "Latino" 6 "Other" 7 "Multi-racial"
label values race_wife race_head race

// wife - not asked until 1985, need to figure out
	browse id survey_yr race_wife if inlist(id,3,12,16)
	bysort id (race_wife): replace race_wife=race_wife[1] if race_wife==.

// need to figure out ethnicity

gen same_race=0
replace same_race=1 if race_head==race_wife & race_head!=.

gen children=0
replace children=1 if NUM_CHILDREN_>=1

gen metro=(METRO_==1) // a lot of missing, don't use for now, control for STATE_ for now

/* religion is new, but think I need to add given historical research. coding changes between 1984 and 1985, then again between 1994 and 1995 Need to recode, so tabling for now, not important for these purposes anyway
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
*/

// also age at relationship start
browse id survey_yr rel_start_all FIRST_MARRIAGE_YR_START BIRTH_YR_ AGE_REF_ AGE_SPOUSE_
gen yr_born_head = survey_yr - AGE_REF_
gen yr_born_wife = survey_yr-AGE_SPOUSE_

gen age_mar_head = rel_start_all -  yr_born_head
gen age_mar_wife = rel_start_all -  yr_born_wife

browse id survey_yr yr_born_head yr_born_wife rel_start_all age_mar_head age_mar_wife AGE_REF_ AGE_SPOUSE_

save "$data_keep\PSID_union_validation_sample.dta", replace

keep if relationship_type==2
save "$data_keep\PSID_marriage_validation_sample.dta", replace