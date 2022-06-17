********************************************************************************
* Getting PSID sample for union dissolution
* create_sample.do
* Kim McErlean
********************************************************************************


********************************************************************************
* First reshape the data to be long, I think this will be less overwhelming / 
* easier to see which variables tracked consistently and how
********************************************************************************

use "$PSID\PSID_full_renamed.dta", clear
rename X1968_PERSON_NUM_1968 main_per_id

egen family_intvw_num=rowmin(FAMILY_INTERVIEW_NUM*) // not working because inconsistent years
browse family_intvw_num FAMILY_INTERVIEW_NUM*

gen unique_id = (family_intvw_num*1000) + main_per_id
browse unique_id family_intvw_num main_per_id

gen id=_n

local reshape_vars "RELEASE_ INTERVIEW_NUM_ RELEASE_NUM2_ FAMILY_INTERVIEW_NUM_ TOTAL_HOURS_HEAD_ TOTAL_HOURS_WIFE_ LABOR_INCOME_HEAD_ LABOR_INCOME_WIFE_ TOTAL_FAMILY_INCOME_ FAMILY_COMPOSITION_ AGE_REF_ AGE_SPOUSE_ SEX_HEAD_ AGE_YOUNG_CHILD_ RESPONDENT_WHO_ RACE_1_HEAD_ EMPLOY_STATUS_HEAD_ MARITAL_STATUS_HEAD_ WIDOW_LENGTH_HEAD_ WAGES_HEAD_ FATHER_EDUC_HEAD_ WAGE_RATE_HEAD_ WAGE_RATE_WIFE_ REGION_ NUM_CHILDREN_ CORE_WEIGHT_ RELATION_ AGE_ MARITAL_PAIRS_ MOVED_ YRS_EDUCATION_ TYPE_OF_INCOME_ TOTAL_MONEY_INCOME_ ANNUAL_WORK_HRS_ COMPOSITION_CHANGE_ NEW_REF_ SEQ_NUMBER_ RESPONDENT_ FAMILY_ID_SO_ HRLY_RATE_HEAD_ RELIGION_HEAD_ NEW_SPOUSE_ FATHER_EDUC_WIFE_ MOTHER_EDUC_WIFE_ MOTHER_EDUC_HEAD_ COLLEGE_HEAD_ COLLEGE_WIFE_ TYPE_TAXABLE_INCOME_ OFUM_TAXABLE_INCOME_ SALARY_TYPE_HEAD_ FIRST_MARRIAGE_YR_WIFE_ RELIGION_WIFE_ WORK_MONEY_WIFE_ EMPLOY_STATUS_WIFE_ SALARY_TYPE_WIFE_ HRLY_RATE_WIFE_ RESEPONDENT_WIFE_ WORK_MONEY_HEAD_ MARITAL_STATUS_REF_ EVER_MARRIED_HEAD_ EMPLOYMENT_ STUDENT_ COUPLE_STATUS_REF_ BIRTH_YR_ RELATION_TO_HEAD_ NUM_MARRIED_HEAD_ FIRST_MARRIAGE_YR_HEAD_ FIRST_MARRIAGE_END_HEAD_ FIRST_WIDOW_YR_HEAD_ FIRST_DIVORCE_YR_HEAD_ FIRST_SEPARATED_YR_HEAD_ LAST_MARRIAGE_YR_HEAD_ LAST_WIDOW_YR_HEAD_ LAST_DIVORCE_YR_HEAD_ LAST_SEPARATED_YR_HEAD_ FAMILY_STRUCTURE_HEAD_ RACE_2_HEAD_ NUM_MARRIED_WIFE_ FIRST_MARRIAGE_END_WIFE_ FIRST_WIDOW_YR_WIFE_ FIRST_DIVORCE_YR_WIFE_ FIRST_SEPARATED_YR_WIFE_ LAST_MARRIAGE_YR_WIFE_ LAST_WIDOW_YR_WIFE_ LAST_DIVORCE_YR_WIFE_ LAST_SEPARATED_YR_WIFE_ FAMILY_STRUCTURE_WIFE_ RACE_1_WIFE_ RACE_2_WIFE_ STATE_ BIRTHS_REF_ BIRTH_SPOUSE_ BIRTHS_BOTH_ OFUM_LABOR_INCOME_ RELEASE_NUM_ SALARY_HEAD_ SALARY_WIFE_ EMPLOY_STATUS1_HEAD_ EMPLOY_STATUS2_HEAD_ EMPLOY_STATUS3_HEAD_ EMPLOY_STATUS1_WIFE_ EMPLOY_STATUS2_WIFE_ EMPLOY_STATUS3_WIFE_ RACE_3_WIFE_ RACE_3_HEAD_ RACE_4_HEAD_ COR_IMM_WT_ ETHNIC_WIFE_ ETHNIC_HEAD_ CROSS_SECTION_FAM_WT_ LONG_WT_ CROSS_SECTION_WT_ EARNINGS_2YRLAG_ AMOUNTEARN_1_HEAD_ TOTAL_WEEKS_HEAD_ TOTAL_HOURS2_HEAD_ AMOUNTEARN_1_WIFE_ TOTAL_WEEK_WIFE_ TOTAL_HOURS2_WIFE_ HOURS_WK_HEAD_ NUM_JOBS_ BACHELOR_YR_ ENROLLED_ SEX_WIFE_ BACHELOR_YR_WIFE_ ENROLLED_WIFE_ BACHELOR_YR_HEAD_ ENROLLED_HEAD_ WAGES_WIFE_ METRO_ COLLEGE_ CURRENTLY_WORK_HEAD_ CURRENTLY_WORK_WIFE_"

reshape long `reshape_vars', i(id) j(survey_yr)

save "$data_tmp\PSID_full_long.dta", replace

********************************************************************************
* Sample
********************************************************************************

browse id main_per_id RELATION FIRST_MARRIAGE_YR_START MARITAL_PAIRS