# file:     clean-src-data.R
# author:   Aaron Butler
# date:     1-Mar-2020
# purpose:  Process Kentucky School Report Card files

# NOTES
# - Files downloaded 1-Mar-2020 from https://openhouse.education.ky.gov/Home/SRCData
# - School year 2018/19
# - Use *state_sch_id* to merge files
# - Vars ending in *_total* refer to counts

# load packages
library(tidyverse)
library(readxl)
library(janitor)

# Process files separately ----

# school info  
sch_info <- read_excel("data/DISTRICT_SCHOOL_LIST.xlsx", sheet=2) %>% 
  clean_names() %>% 
  filter(sch_type=="A1") %>% 
  mutate(title1_status = case_when(
    title1_status=="Not a Title I School" ~ 1,
    title1_status=="Title I Eligible - No Program" ~ 2,
    title1_status=="Title I Eligible - Schoolwide School" ~ 3,
    title1_status=="Title I Eligible - Targeted Assistance School" ~ 4
  )) %>%
  select(sch_year, cntyno, cntyname, dist_number, dist_name, 
         sch_number, sch_name, sch_cd, state_sch_id, 
         coop, low_grade, high_grade, title1_status, latitude, longitude)

# school level
sch_level <- readxl::read_excel("data/ACCOUNTABILITY_PROFILE.xlsx", sheet=2) %>% 
  clean_names() %>% 
  filter(!is.na(state_sch_id)) %>% 
  select(state_sch_id, level)

# race
stn_race <- read_excel("data/STUDENT_DEMOGRAPHIC_RACE_GENDER.xlsx", sheet=2) %>% 
  clean_names() %>%
  mutate_at(c("white_total", "male_total", "membership_total"), as.numeric) %>% 
  mutate(stn_white_pct = white_total / membership_total,
         stn_male_pct = male_total / membership_total) %>% 
  select(state_sch_id, stn_membership=membership_total, contains("_pct"))

# ell
stn_ell <- read_excel("data/ENGLISH_LEARNERS.xlsx", sheet=2) %>% 
  clean_names() %>% 
  select(state_sch_id, stn_ell_total=allelstudents_cnt)

# frpl
stn_frpl <- read_excel("data/FREE_AND_REDUCED_LUNCH.xlsx", sheet=2) %>% 
  clean_names() %>% 
  select(state_sch_id, stn_frpl_total=total_cnt)

# special edu
stn_iep <- read_excel("data/SPECIAL_EDUCATION.xlsx", sheet=2) %>% 
  clean_names() %>% 
  filter(demoabbrev=="TST") %>% 
  select(state_sch_id, stn_iep_total=totalstudents)

# gifted
stn_gifted <- read_excel("data/GIFTED_AND_TALENTED.xlsx", sheet=2) %>% 
  clean_names() %>% 
  filter(demo=="TST") %>% 
  select(state_sch_id, stn_gifted_total=gt_cnt)

# homeless
stn_homeless <- read_excel("data/HOMELESS.xlsx", sheet=2) %>% 
  clean_names() %>% 
  select(state_sch_id, stn_homeless_total=total)

# migrant
stn_migrant <- read_excel("data/MIGRANT.xlsx", sheet=2) %>% 
  clean_names() %>% 
  select(state_sch_id, stn_migrant_total=total)

# attendance
attendance_rate <- read_excel("data/SAAR_ATTENDENCE_RATE.xlsx", sheet=2) %>% 
  clean_names() %>% 
  select(state_sch_id, stn_attendance_rate=attendancerate)

# chronic absence
chronic_absence <- read_excel("data/CHRONIC_ABSENTEEISM.xlsx", sheet=2) %>% 
  clean_names() %>% 
  filter(demo_abbrev=="TST") %>% 
  select(state_sch_id, stn_chronic_absence_total=chronic_absentee_cnt)

# safe schools
safe_schools <- read_excel("data/SAFE_SCHOOLS.xlsx", sheet=2) %>% 
  clean_names() %>% 
  filter(table=="Behavior Events",
         category=="Total") %>% 
  select(state_sch_id, stn_safety_total=total_students)

# teacher FTE - NO SCHOOL CODE
# tchr_fte <- read_excel("data/FULLTIME_EQUIVALENT_TEACHER.xlsx", sheet=2) %>% 
#   clean_names() %>% 
#   select(state_sch_id, tchr_fte=ftecertifiedstaff)

# national board certified
tchr_national_board <- read_excel("data/NATIONAL_BOARD_CERTIFICATION.xlsx", sheet=2) %>% 
  clean_names() %>% 
  select(state_sch_id, tchr_national_board_total=total)

# first-year teachers
tchr_first_year <- read_excel("data/NEW_TEACHER_COUNT.xlsx", sheet=2) %>% 
  clean_names() %>% 
  mutate(newpct = as.numeric(newpct)) %>%
  mutate(newpct = ifelse(is.na(newpct), 0, newpct)) %>% 
  select(state_sch_id, tchr_total=teachers, tchr_new_pct=newpct)

# teacher experience
tchr_experience <- read_excel("data/SCHOOL_EXPERIENCE.xlsx", sheet=2) %>% 
  clean_names() %>% 
  select(state_sch_id, tchr_experience_avg=avgexperienceyears)

# teacher qualifications
tchr_quals <- read_excel("data/TEACHER_QUALIFICATIONS.xlsx", sheet=2) %>%
  clean_names() %>%
  select(state_sch_id, qualification, pct_qualification) %>% 
  mutate(pct_qualification = str_remove(pct_qualification, "%"),
         pct_qualification = as.numeric(pct_qualification)) %>%
  drop_na(state_sch_id) %>%
  mutate(flag = ifelse(qualification=="Associate Degree" | qualification=="Bachelors", 0, 1)) %>% 
  group_by(state_sch_id, flag) %>% 
  summarise(tchr_ma_plus_pct = sum(pct_qualification) / 100) %>% 
  filter(flag==1) %>% 
  select(-flag)

# teacher turnover
tchr_turnover <- read_excel("data/TEACHER_TURNOVER.xlsx", sheet=2) %>% 
  clean_names() %>% 
  select(state_sch_id, tchr_turnover_total=tch_turnover_cnt)

# emergency certs
tchr_waivers <- read_excel("data/EMERGENCY_AND_PROVISIONAL_CERTIFICATIONS.xlsx") %>% 
  clean_names() %>% 
  select(state_sch_id, tchr_waivers_total=totwaivers)

# student-teacher ratio
stn_tchr_ratio <- read_excel("data/STUDENT_TEACHER_RATIO.xlsx", sheet=2) %>% 
  clean_names() %>% 
  select(state_sch_id, stn_tchr_ratio=stdnt_tch_ratio) %>% 
  mutate(to_sep=stn_tchr_ratio) %>% 
  separate(col=to_sep, into=c("stn", "tchr"), sep=":", convert=TRUE) %>% 
  mutate(student_teacher_ratio = tchr / stn) %>% 
  select(-stn, -tchr, -stn_tchr_ratio)

# tell data
tell <- read_excel("data/TELL_EQUITY.xlsx", sheet=2) %>% 
  clean_names() %>% 
  select(state_sch_id, tell_measure=equity_measure, tell_value=eq_value) %>% 
  drop_na(state_sch_id) %>%
  mutate(tell_measure = case_when(
    tell_measure=="Managing Student Conduct Composite" ~ "tell_students",
    tell_measure=="Community Support & Involvement Composite" ~ "tell_community",
    tell_measure=="School Leadership Composite" ~ "tell_leadership"
  )) %>% 
  mutate(tell_value = as.numeric(tell_value)) %>% 
  pivot_wider(names_from = tell_measure,
              values_from = tell_value)

# seek per-pupil funds
seek_funds <- read_excel("data/FY2018 2019 SEEK Final Summary Per Pupil.xlsx", skip=3) %>% 
  clean_names() %>%
  filter(district != "State Totals:") %>% 
  separate(district, c("dist_number", "name")) %>% 
  select(dist_number, dist_seek_funding=total_final_seek)

# building funds
building_funds <- read_excel("data/FY2018 2019 SEEK Final Building Fund.xlsx", skip=3) %>% 
  clean_names() %>% 
  filter(district != "State Totals:") %>% 
  separate(district, c("dist_number", "name")) %>% 
  select(dist_number, dist_building_funding=total_building_funds)

# Merge files ----

# left join on *state_sch_id*
src_merged <- sch_info %>%
  left_join(sch_level) %>% 
  left_join(attendance_rate) %>% 
  left_join(chronic_absence) %>% 
  left_join(safe_schools) %>% 
  left_join(stn_ell) %>% 
  left_join(stn_race) %>% 
  left_join(stn_frpl) %>% 
  left_join(stn_gifted) %>% 
  left_join(stn_homeless) %>% 
  left_join(stn_iep) %>% 
  left_join(stn_migrant) %>% 
  left_join(stn_tchr_ratio) %>% 
  left_join(tchr_experience) %>% 
  left_join(tchr_first_year) %>% 
  left_join(tchr_quals) %>%
  left_join(tchr_national_board) %>% 
  left_join(tchr_turnover) %>% 
  left_join(tchr_waivers) %>% 
  left_join(tell) %>% 
  left_join(seek_funds) %>% 
  left_join(building_funds)

# Creat complete file ----

# complete file containing all school info
src_data <- src_merged %>% 
  mutate(level = ifelse(is.na(level), "PreK", level)) %>% 
  mutate_at(vars(c(contains("total"), contains("year"), contains("rate"), tchr_total)), as.numeric) %>% 
  mutate(stn_attendance_pct = stn_attendance_rate/100,
         stn_chronic_absence_pct = stn_chronic_absence_total / stn_membership,
         stn_safety_pct = stn_safety_total / stn_membership,
         stn_ell_pct = stn_ell_total / stn_membership,
         stn_frpl_pct = stn_frpl_total / stn_membership,
         stn_gifted_pct = stn_gifted_total / stn_membership,
         stn_homeless_pct = stn_homeless_total / stn_membership,
         stn_iep_pct = stn_iep_total / stn_membership,
         stn_migrant_pct = stn_migrant_total / stn_membership,
         tchr_national_board_pct = tchr_national_board_total / tchr_total,
         tchr_turnover_pct = tchr_turnover_total / tchr_total,
         tchr_waivers_pct = tchr_waivers_total / tchr_total,
         tell_students = tell_students / 100,
         tell_community = tell_community / 100,
         tell_leadership = tell_leadership / 100) %>% 
  select(-contains("total"), -stn_attendance_rate) %>% 
  select(sch_year, cntyno, cntyname, dist_number, dist_name,
         sch_number, sch_name, sch_cd, state_sch_id, coop, 
         low_grade, high_grade, level, latitude, longitude,
         starts_with("stn_"), starts_with("tchr_"), 
         starts_with("tell_"), starts_with("dist_"), everything())

# write file
write_csv(src_data, "data/src_data.csv")

#
#
#

# Create trunc file for OpenSDP ----

# NOTES
# - Dropped non-essential school info
# - Only Elem schools
# - Add achievement data for supp analysis

# drop non-essential vars
df <- src_data %>% 
  select(-sch_year, -cntyno, -cntyname, -dist_number, -dist_name,
         -sch_number, -sch_cd, -coop, -low_grade, -high_grade,
         -latitude, -longitude) %>% 
  select(state_sch_id, sch_name, level, starts_with("stn_"), starts_with("tchr_"), 
         starts_with("tell_"), starts_with("dist_"), everything())

# only elem schools
df_es <- df %>% filter(level=="ES")

# clean proficiency data
ky_prof <- read_excel("data/ACCOUNTABILITY_PROFICIENCY_LEVEL.xlsx", sheet=2) %>% 
  clean_names() %>% 
  filter(level=="ES",
         subject %in% c("MA", "RD"),
         demographic=="TST") %>%
  drop_na(state_sch_id) %>% 
  select(state_sch_id, subject, prof_dist=proficient_distinguished) %>% 
  pivot_wider(names_from = subject,
              values_from = prof_dist,
              names_prefix = "prof_") %>% 
  rename_all(tolower)

# clean growth data 
# ky_growth <- read_excel("data/GROWTH.xlsx", sheet=2) %>% 
#   clean_names() %>% 
#   filter(level=="ES",
#          demographic=="TST") %>% 
#   drop_na(state_sch_id) %>% 
#   select(state_sch_id, growth_rd=rd_rate, growth_ma=ma_rate)

# merge
df_merged <- df_es %>% 
  left_join(ky_prof) #%>% 
# left_join(ky_growth)

# write analysis file
write_csv(df_merged, "data/ky_report_card_data.csv")