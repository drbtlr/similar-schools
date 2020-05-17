---
title: "Identifying Similar Schools"
author: "Aaron Butler"
date: "April 7, 2020"
output: 
  html_document:
    theme: simplex
    css: ../includes/styles.css
    highlight: NULL
    keep_md: true
    toc: true
    toc_depth: 3
    toc_float: true
    number_sections: false
---

# Guide to Creating Comparison School Groups

*Applying unsupervised machine learning methods to publicly available data to gain insights into schools and districts across a state. Programmed in R.*



<div class="navbar navbar-default navbar-fixed-top" id="logo">
<div class="container">
<img src="https://opensdp.github.io/assets/images/OpenSDP-Banner_crimson.jpg" style="display: block; margin: 0 auto; height: 115px;">
</div>
</div>

## Getting Started

### Objective

In this guide, you will be able to apply two unsupervised machine learning methods--specifically, Principal Component Analysis (PCA) and K-Means Clustering--to publicly available state report card data to identify schools that that are similar to each other in terms of student enrollment, faculty and staff characteristics, programs, spending and funding, and other school indicators.

### Purpose and Overview of Analyses

School leaders often use peer groups for comparative analyses and benchmarking. Identifying appropriate peer schools with similar settings and student bodies can be a challenging and time consuming process. The purpose of this guide is to present a data-driven approach to identifying school peer groups. We use PCA and K-Means Clustering algorithms together to identify groups of like-schools and provide an example of how this information can be used to benchmark school proficiency scores.   

### Using this Guide

This guide utilizes publicly available data from the [Kentucky school report card](https://openhouse.education.ky.gov/SRC) for the 2018/19 school year. Schools and districts in Kentucky can use this code to analyze data from earlier report cards from the Kentucky Department of Education. Additionally, code from this guide can be adapted to analyze data found on other state or district report cards.

Once you have identified analyses that you want to try to replicate or modify, click the "Download" buttons to download R code and sample data. You can make changes to the charts using the code and sample data, or modify the code to work with your own data. If you are familiar with GitHub, you can click "Go to Repository" and clone the entire repository to your own computer. 

Go to the [Participate page](https://opensdp.github.io/participate/) to read about more ways to engage with the OpenSDP community or reach out for assistance in adapting this code for your specific context.

### Installing and Loading R Packages

To complete this tutorial, you will need R, R Studio, and the following R packages installed on your machine: 

- `tidyverse`: For convenient data and output manipulation
- `broom`: To extract model details in a tidy data frame 
- `factoextra`: To visualize PCA results easily
- `simputation`: To impute missing data

To install packages, such as `broom`, run the following command in the R console:

`install.packages("broom")`

In addition, this guide will draw from OpenSDP-written functions defined in the `functions.R` document, which is located in the `R` folder of this guide's GitHub repository. Please make sure to have downloaded the entire GitHub repository to run this code.

After you installed your R packages and downloaded this guide's GitHub repository, run the chunk of code below to load them onto your computer.


```r
# Load packages
library(tidyverse)
library(broom)
library(factoextra)
library(simputation)

# Read in some R functions that are convenience wrappers
source("../R/functions.R")
```

### About the Data

This guide utilizes publicly available data from the [Kentucky School Report Card](https://openhouse.education.ky.gov/SRC) for the 2018/19 school year. All data is at the school-level with the exception of financial information (`dist_seek_funding`, `dist_building_funding`), which is at the district level. Assessment and accountability data (`prof_dist_rd`, `prof_dist_ma`) are only used in the supplemental analysis at the end of the guide. We chose to exclude assessment and accountability data from the PCA and K-Means Clustering analyses because we wanted to focus the analyses on school characteristics and resources. Individuals can add assessment and accountability data to their model as long as the features are numeric--i.e., school performance levels must be re-coded as a numeric variable. The code we used to process the report card data files is stored in the `R` folder as `clean-src-data.R`.    

Below is a list of variables and descriptions used in the analyses:

| Variable Name             | Variable Description                                |
|:-----------               |:------------------                                  |
| `state_sch_id`            | School ID number                                    |
| `sch_name`                | School name                                         |
| `level`                   | Indicator of school level ("ES", "MS", "HS")        |
| `stn_membership`          | Number of students enrolled                         |
| `stn_white_pct`           | Percent of white students enrolled                  |
| `stn_male_pct`            | Percent of male students enrolled                   |
| `stn_attendance_pct`      | Student attendance rate                             |
| `stn_chronic_absence_pct` | Percent of chronic absent students enrolled         |
| `stn_safety_pct`          | Percent of students enrolled with behavior event    |
| `stn_ell_pct`             | Percent of English Language Learners enrolled       |
| `stn_frpl_pct`            | Percent of economic disadvantage students enrolled  |
| `stn_gifted_pct`          | Percent of gifted students enrolled                 |
| `stn_homeless_pct`        | Percent of homeless students enrolled               |
| `stn_iep_pct`             | Percent of special education students enrolled      |
| `stn_migrant_pct`         | Percent of migrant students enrolled                |
| `tchr_experience_avg`     | Average number of years experience by teachers      |
| `tchr_new_pct`            | Percent of new teachers                             |
| `tchr_ma_plus_pct`        | Percent of teachers with advance degree (masters +) |
| `tchr_national_board_pct` | Percent of National Board Certified teachers        |
| `tchr_turnover_pct`       | Teacher turnover rate                               |
| `tchr_waivers_pct`        | Percent of teachers with certification waivers      |
| `tell_students`           | Average rating on Tell Survey (Student Conduct)     |
| `tell_community`          | Average rating on Tell Survey (Community Engagement)|
| `tell_leadership`         | Average rating on Tell Survey (School Leadership)   |
| `dist_seek_funding`       | Per-pupil state funding amount for district         |
| `dist_building_funding`   | Total building funds for district                   |
| `title1_status`           | Indicator of Title 1 status                         |
| `stuent_teacher_ratio`    | Student-to-teacher ratio                            |
| `prof_dist_rd`            | Percent of students scoring Proficient in reading   |
| `prof_dist_ma`            | Percent of students scoring Proficient in math      |

#### Loading the Dataset


```
Observations: 725
Variables: 30
$ state_sch_id            <chr> "001001016", "001001020", "002005060", "002...
$ sch_name                <chr> "Adair County Elementary School", "Adair Co...
$ level                   <chr> "ES", "ES", "ES", "ES", "ES", "ES", "ES", "...
$ stn_membership          <dbl> 624, 538, 707, 909, 374, 417, 530, 418, 237...
$ stn_white_pct           <dbl> 0.8910256, 0.8791822, 0.9108911, 0.9130913,...
$ stn_male_pct            <dbl> 0.5064103, 0.5501859, 0.4809052, 0.5258526,...
$ stn_attendance_pct      <dbl> 0.950, 0.940, 0.952, 0.943, 0.968, 0.951, 0...
$ stn_chronic_absence_pct <dbl> 0.13782051, 0.20446097, 0.13437058, 0.16941...
$ stn_safety_pct          <dbl> 0.060897436, 0.022304833, 0.154172560, 0.09...
$ stn_ell_pct             <dbl> 0.027243590, 0.037174721, 0.009900990, 0.02...
$ stn_frpl_pct            <dbl> 0.75160256, 0.76951673, 0.66336634, 0.70187...
$ stn_gifted_pct          <dbl> 0.10416667, 0.10594796, 0.02404526, 0.05500...
$ stn_homeless_pct        <dbl> 0.001602564, 0.020446097, 0.029702970, 0.01...
$ stn_iep_pct             <dbl> 0.12820513, 0.23977695, 0.15417256, 0.23322...
$ stn_migrant_pct         <dbl> 0.019230769, 0.037174721, 0.002828854, 0.00...
$ tchr_experience_avg     <dbl> 13.3, 15.9, 11.9, 12.0, 15.9, 14.2, 11.4, 1...
$ tchr_new_pct            <dbl> 9.1, 2.7, 5.9, 1.9, 5.3, 0.0, 4.0, 0.0, 0.0...
$ tchr_ma_plus_pct        <dbl> 0.727, 0.946, 0.647, 0.808, 0.921, 0.904, 0...
$ tchr_national_board_pct <dbl> 0.09090909, 0.16216216, 0.20588235, 0.05769...
$ tchr_turnover_pct       <dbl> 0.24242424, 0.16216216, 0.02941176, 0.07692...
$ tchr_waivers_pct        <dbl> 0.00000000, 0.00000000, 0.02941176, 0.03846...
$ tell_students           <dbl> 0.893, 0.803, 0.883, 0.938, 0.933, 0.886, 0...
$ tell_community          <dbl> 0.892, 0.887, 0.877, 0.819, 0.997, 0.946, 0...
$ tell_leadership         <dbl> 0.949, 0.784, 0.836, 0.884, 0.946, 0.912, 0...
$ dist_seek_funding       <dbl> 5249, 5249, 5071, 5071, 1857, 3901, 3901, 3...
$ dist_building_funding   <dbl> 993715, 993715, 2258788, 2258788, 242847, 3...
$ title1_status           <dbl> 3, 3, 3, 3, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3...
$ student_teacher_ratio   <dbl> 0.06666667, 0.06250000, 0.05882353, 0.07142...
$ prof_rd                 <dbl> 52.1, NA, 58.4, 44.3, 89.7, 53.1, 56.5, 43....
$ prof_ma                 <dbl> 51.4, NA, 52.0, 44.3, 87.7, 45.0, 55.1, 38....
```

### Giving Feedback on this Guide
 
This guide is an open-source document hosted on GitHub and generated using R Markdown. We welcome feedback, corrections, additions, and updates. Please visit the OpenSDP [participate repository](https://opensdp.github.io/participate/) to read our contributor guidelines.

## Analyses

### Data Transformation with PCA

**Purpose:** This analysis examines the structure of the dataset and illustrates how PCA can be used to reduce the number of variables in a dataset, while losing as little information as possible.

**Required Analysis File Variables:**

- `state_sch_id`
- `stn_membership`
- `stn_white_pct`
- `stn_male_pct`
- `stn_attendance_pct`
- `stn_chronic_absence_pct`
- `stn_safety_pct`
- `stn_ell_pct`
- `stn_frpl_pct`
- `stn_gifted_pct`
- `stn_homeless_pct`
- `stn_iep_pct`
- `stn_migrant_pct`
- `tchr_experience_avg`
- `tchr_new_pct`
- `tchr_ma_plus_pct`
- `tchr_national_board_pct`
- `tchr_turnover_pct`
- `tchr_waivers_pct`
- `tell_students`
- `tell_community`
- `tell_leadership`
- `dist_seek_funding`
- `dist_building_funding`
- `title1_status`
- `stuent_teacher_ratio` 

**A Note on Missing Data**

Determining how to address missing data is an important decision for many data analysts. Depending on the amount of missing data and whether data is missing completely at random, missing at random, and missing not at random, different strategies can be applied to a PCA on an incomplete data set. Additionally, PCA algorithms in R often differ in how they treat missing data in their default settings. For example, the `prcomp` function excludes data with missing data by default (see `?prcomp` for additional information). In this analysis, we apply a simple imputation method using the R package `simputation` as an example of how to estimate missing data using a model-based approach. We encourage you to read more on the topics of missing data with PCA and different approaching to imputing missing data. 

We listed a few helpful resources on PCA and missing data at the end of this guide. 

**Ask Yourself**

- What information do I want to include in the model? 
- Are there reasons to exclude any variables (e.g., political concerns)?
- Which school factors are contributing the most to the model? What can we learn from this?


```r
# // Step 1: Identify which variables are missing
src_data %>% 
  select(-starts_with("prof")) %>% 
  gather(variable, value) %>% 
  group_by(variable) %>% 
  summarise(missing = calc_pct_missing(value)) %>% 
  arrange(-missing)
```

```
# A tibble: 28 x 2
   variable                missing
   <chr>                     <dbl>
 1 tell_community          0.0207 
 2 tell_leadership         0.0207 
 3 tell_students           0.0207 
 4 tchr_turnover_pct       0.00690
 5 tchr_national_board_pct 0.00138
 6 dist_building_funding   0      
 7 dist_seek_funding       0      
 8 level                   0      
 9 sch_name                0      
10 state_sch_id            0      
# ... with 18 more rows
```

```r
# // Step 2: Impute missing values

# We selected three school features, as an example, to estimate the missing data.
# We likely would have taken a different approach if more schools had missing data.
src_data_complete <- src_data %>%
  impute_lm(tell_community ~ stn_membership + stn_white_pct + stn_frpl_pct) %>% 
  impute_lm(tell_leadership ~ stn_membership + stn_white_pct + stn_frpl_pct) %>% 
  impute_lm(tell_students ~ stn_membership + stn_white_pct + stn_frpl_pct) %>% 
  impute_lm(tchr_turnover_pct ~ stn_membership + stn_white_pct + stn_frpl_pct) %>%
  impute_lm(tchr_national_board_pct ~ stn_membership + stn_white_pct + stn_frpl_pct)

# Check -> Good!
src_data_complete %>% 
  select(-starts_with("prof")) %>% 
  gather(variable, value) %>% 
  group_by(variable) %>% 
  summarise(missing = calc_pct_missing(value)) %>% 
  arrange(-missing)
```

```
# A tibble: 28 x 2
   variable                missing
   <chr>                     <dbl>
 1 dist_building_funding         0
 2 dist_seek_funding             0
 3 level                         0
 4 sch_name                      0
 5 state_sch_id                  0
 6 stn_attendance_pct            0
 7 stn_chronic_absence_pct       0
 8 stn_ell_pct                   0
 9 stn_frpl_pct                  0
10 stn_gifted_pct                0
# ... with 18 more rows
```


```r
# // Step 3: Select numeric columns and cast to matrix
src_matrix <- src_data_complete %>%
  select(-starts_with("prof")) %>% 
  select_if(is.numeric) %>% 
  as.matrix()

# // Step 4: Execuite the PCA algorithm
src_pca <- prcomp(src_matrix, 
                  # It's important that you center and scale your data.
                  # The centering defualt is TRUE. I'm being explicit for demonstration.
                  center = TRUE,
                  # Switch to TRUE to scale data
                  scale = TRUE)
```

It can be informative to see which factors are contributing the most in the model. If you see variables that contribute very little to **both** principal components 1 or 2, try repeating the PCA (Steps 3 and 4) without those feature. We observed three variables that were contributing little to model (`stn_migrant_pct`, `stn_gifted_pct`, `student_teacher_ratio`) and decided to drop them from the model as an example of what to do in this situation. 

**Note:** we recommend that you provide a rational for any decision you make to exclude variables from your analysis. Failure to do so may come across to the public that you are manipulating the model. See resources on PCA at the end of this guide for additional information on this topic. 


```r
# // Step 5: Plot

# Plot variables contributing to principal component 1
fviz_pca_contrib(src_pca, choice = "var", axes = 1)
```

<img src="../figure/E_pca-plot-1.png" style="display: block; margin: auto;" />

```r
# Plot variables contributing to principal component 1
fviz_pca_contrib(src_pca, choice = "var", axes = 2)
```

<img src="../figure/E_pca-plot-2.png" style="display: block; margin: auto;" />

```r
# // Step 6: Drop variables contributing little to model and repeate PCA

# List variables we want to drop
drop_vars <- c("stn_migrant_pct", "stn_gifted_pct", "student_teacher_ratio")

# Repeate PCA (condensed code)
src_pca_revised <- src_data_complete %>%
  select(-starts_with("prof")) %>% 
  select_if(is.numeric) %>% 
  # drop vars here
  select(-drop_vars) %>% 
  as.matrix() %>% 
  prcomp(center = TRUE, scale = TRUE)
```

### Using K-Means Clustering to Identify Comparison Schools

**Purpose:** Using information from the PCA, this analysis shows how K-Means Clustering algorithms can be used to form groups form groups of comparable schools.

**Required Analysis File Variables:**

- Analysis uses data from the PCA

**Ask Yourself**

- What is a reasonable number of comparison schools?
- Do my comparison school groups make sense?


```r
# // Step 1: Extract principal components 1 and 2
pca_coords <- augment(src_pca_revised) %>% 
  select(.rownames, .fittedPC1, .fittedPC2) %>% 
  mutate(.fittedPC1 = .fittedPC1 * -1)
```


```r
# // Step 2: Set seed for reproducability
set.seed(2468)

# // Step 3: Apply k-means algorthm
src_km <- kmeans(pca_coords %>% select(-.rownames),
                 # Set to the number of groups you want.
                 centers = 30)

# // Step 4: Examine the number of schools in each group 
src_km$size
```

```
 [1] 50 24 30 16 26 29 38 17 17 31 27 31 14 14 25 22 32 36 32 21 24 17 19 14 32
[26] 12 33 12  9 21
```


```r
# // Step 5: Write a CSV with schools groups

# Add clusters to original dataset
sch_clusters <- src_data %>% 
  # Add clusters
  mutate(cluster = factor(src_km$cluster)) %>% 
  # Add PCAs
  mutate(pc1 = pca_coords$.fittedPC1,
         pc2 = pca_coords$.fittedPC2)

# Write file
# Uncomment line below to overwrite file provided in this guide.
# write_csv(sch_clusters, "../data/sch_clusters.csv")
```

Lastly, examine your group using descriptive statistics and different visualizations (see below as an example). Ask yourself if the groupings make sense. If they do, try rerunning your K-Means algorithm to form new school groupsings. Don't be surprised if it takes you a few tries to get school groups that are appropriate in size and makeup. It's an iterative process.

**Other advice.** Conduct a follow-up analysis using prior year data. If you see that your school groups differ in meaningful ways from those in your original analysis, consider aggregating your data across years and use this information in your analysis. Using multiple years of data has the advantage of evening out periodic swings in the data.


```r
# // Step 6: Plot
ggplot(sch_clusters, 
       aes(pc1, pc2, color=cluster)) +
  geom_point(show.legend = FALSE) +
  theme_bw() +
  theme(panel.grid = element_blank(),
        axis.ticks = element_blank(),
        plot.title.position = "plot") +
  labs(x = "PC1", y = "PC2",
       title = "School groups by first and second principal components",
       subtitle = "Number of groups: 30")
```

<img src="../figure/E_unnamed-chunk-1-1.png" style="display: block; margin: auto;" />

### Application: Benchmarking School Performance

**Purpose:** This analyses examines proficiency rates in reading among schools within a comparison groups. It is an example application of a dataset containing a list of comparison schools.

**Required Analysis File Variables:**

- Analysis uses data from PCA and K-Means analyses

**Ask Yourself**

- How do similar schools perform on state assessments?
- What might explain the variation in proficiency rates for schools sharing similar characteristics?
- How can I use this information to gauge future performance?


```r
# \\ Step 1: Read csv file of clustered dataset, naming it "src_clusters"
# Note: You can continue to use the dataset from Step 5 of the K-Mean analysis. It's
# the same dataset. We load a new dataset for illustrative purposes. 
sch_clusters <- read_csv("../data/sch_clusters.csv")
```


```r
# \\ Step 2: Plot

# Set school of interest
my_school <- "034165052"

# Plot
sch_clusters %>%
  # Flag school of note
  mutate(flag = ifelse(state_sch_id == my_school, 1, 0)) %>%
  # Restrict to cluster containing school of note
  filter(cluster == 3) %>%
  # Shorten school names
  mutate(sch_name = str_replace(sch_name, "Elementary School", "ES"),
         sch_name = str_replace(sch_name, "Elementary", "ES"),
         sch_name = str_replace(sch_name, "School", "ES"),
         sch_name = str_replace(sch_name, "Traditional", "ES")) %>% 
  ggplot(aes(reorder(sch_name, prof_rd), prof_rd)) +
  geom_col(aes(fill = factor(flag))) +
  geom_text(aes(label = paste0(prof_rd, "%")), nudge_y = 5) +
  scale_fill_brewer() +
  coord_flip() +
  theme_minimal() + 
  theme(panel.grid = element_blank(),
        axis.text.x = element_blank(),
        legend.position = "none",
        plot.title.position = "plot") +
  labs(x = "", y = "",
       title = "Rosa Parks Elementary School is performing at the top of its peer group",
       subtitle = "Percent of students scoring proficient in reading, 2018/19", 
       caption = "Data: KY School Report Card")
```

<img src="../figure/E_supp-plot-1.png" style="display: block; margin: auto;" />


## Resources

Below are a few helpful resources on PCA, K-Means clustering, and missing data imputation.

- PCA/K-Means resource: [An Introduction to Statistical Learning](http://faculty.marshall.usc.edu/gareth-james/ISL/)
- Data imputation: Andrew Gelman's chapter on [Missing-data Imputation in R](http://www.stat.columbia.edu/~gelman/arm/missing.pdf)
- PCA with missing data: [Paper](http://pbil.univ-lyon1.fr/members/dray/files/articles/dray2015a.pdf) reviews methods which accommodate PCA to missing data
- Other R packages for PCA 
 - `FactoMineR`: For dimension reduction methods such as PCA  
 - `factoextra`: To visualize PCA results easily
 - `FactoShiny`: Shiny app for PCA
- Inspiration for this project comes from [Albuquerque Public Schools](https://www.aps.edu/sapr). These guys do great work!


---

##### *This guide was originally created by [Aaron Butler](https://www.aaronjbutler.com/) in partnership with the Strategic Data Project.*
