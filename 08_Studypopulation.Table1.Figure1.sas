/************************************************************************************
| Project name : Identify off label use of GLP1 following several definitions
| Task Purpose : 
|      0. the first GLP1 fill from 2018 - 2020 (n = 69,115)
|      1. Exclude MA (n = 52,781)
|      2. Identify possible off-label prescriptions (n = 1757, 3.33%)
|      3. Demographics 
|      4. Clinical characteristics - Comorbidities
|      5. UM | coverage | Plan characteristics
|      5. GLP-1 use
|      6. Cost calculation 
| Final dataset : 
|       input.studypop
************************************************************************************/

/************************************************************************************
	0.    the first GLP1 fill from 2018 - 2020 (n = 69,115)
************************************************************************************/

* 1. Add offlabel indicators (df4 & df5);
/**************************************************
* new table: input.studypop
* original: input.glp1users_pde_17to20 + input.offlabel_v05
* description: 
*       Add offlabel indicators (df4 & df5)
**************************************************/

proc sql;
   create table input.studypop as
   select distinct a.*, b.offlabel_df1, b.offlabel_df2, b.offlabel_df3, b.offlabel_df4, b.offlabel_df5
   from input.glp1users_pde_17to20 as a left join input.offlabel_v05 as b
   on a.BENE_ID = b.BENE_ID;
quit; /* 69115 obs */ 

/************************************************************************************
	1.    Exclude MA (n = 52,781)
************************************************************************************/

* 1. merge with MA file;
/**************************************************
* new table: input.studypop
* original: input.glp1users_beneid_17to20_ma
**************************************************/
proc sql;
   create table input.studypop as
   select distinct a.*, b.ma_16to20
   from input.studypop as a left join input.glp1users_beneid_17to20_ma as b
   on a.BENE_ID = b.BENE_ID;
quit; /* 69115 obs */ 

* 2. remove MA;
data input.studypop; set input.studypop; if ma_16to20 =0; run;


/************************************************************************************
	2.    Identify possible off-label prescriptions 
************************************************************************************/

* 1. Definition 1 : Have no previous diabetic medication fill (non-GLP1) at first GLP-1 fill date (n = 6571, 12.45%);
proc freq data=input.studypop; table offlabel_df1; run;

* 2. Definition 2 : Have no recorded diagnosis of diabetes 1 year prior to first fill (n = 17137, 32.47%);
proc freq data=input.studypop; table offlabel_df2; run;

* 3. Definition 3 : Have no prior recorded diagnosis of diabetes within 5 years prior to the first fill (n = 17137, 32.47%);
proc freq data=input.studypop; table offlabel_df3; run;

* 4. Definition 4 : Both (1) AND (2)   (n = 3122, 5.92%);
proc freq data=input.studypop; table offlabel_df4; run;

* 5. Definition 5 : Had (3) and no diagnosis or (non-GLP1) diabetic fill after first GLP-1 fill (n = 1757, 3.33%);
proc freq data=input.studypop; table offlabel_df5; run;

/************************************************************************************
	3.    Demographics 
************************************************************************************/

* 1. merge with demo file;
/**************************************************
* new table: input.studypop
* original: input.glp1users_pde_17to20_demo
* description: 
*       Add Demographics 
**************************************************/

proc sql;
   create table input.studypop as
   select distinct a.*, b.age_at_index, b.BENE_RACE_CD, b.region
   from input.studypop as a left join input.glp1users_pde_17to20_demo as b
   on a.BENE_ID = b.BENE_ID;
quit; /* 52781 obs */ 

* 2. age;
proc ttest data=input.studypop;
   class offlabel_df5;
   var age_at_index;
   title "Age";
run;

* 3. sex;
proc freq data=input.studypop;
  table GNDR_CD*offlabel_df5 / norow nopercent nocum chisq;
  title "Female == 2";
run;

* 4. race;
proc freq data=input.studypop;
  table BENE_RACE_CD*offlabel_df5 / norow nopercent nocum chisq;
  title "Race (white == 1)";
run;

* 5. region;
proc freq data=input.studypop;
  table region*offlabel_df5 / norow nopercent nocum chisq;
  title "Region";
run;

/************************************************************************************
	4.    Clinical characteristics - Comorbidities
************************************************************************************/

* 1. merge with comorbidities file;
/**************************************************
* new table: input.studypop
* original: input.glp1users_beneid_17to20_cc
* description: 
*       Add Demographics 
**************************************************/

proc sql;
   create table input.studypop as
   select distinct a.*, b.obesity, b.htn, b.acute_mi, b.hf, b.stroke, b.alzh
   from input.studypop as a left join input.glp1users_beneid_17to20_cc as b
   on a.BENE_ID = b.BENE_ID;
quit; /* 52781 obs */ 

* 2. obesity;
proc freq data=input.studypop;
  table obesity*offlabel_df5 / norow nopercent nocum chisq;
  title "obesity";
run;

* 3. htn;
proc freq data=input.studypop;
  table htn*offlabel_df5 / norow nopercent nocum chisq;
  title "htn";
run;

* 4. acute_mi;
proc freq data=input.studypop;
  table acute_mi*offlabel_df5 / norow nopercent nocum chisq;
  title "acute_mi";
run;

* 5. hf;
proc freq data=input.studypop;
  table hf*offlabel_df5 / norow nopercent nocum chisq;
  title "hf";
run;

* 6. stroke;
proc freq data=input.studypop;
  table stroke*offlabel_df5 / norow nopercent nocum chisq;
  title "stroke";
run;

* 7. alzh;
proc freq data=input.studypop;
  table alzh*offlabel_df5 / norow nopercent nocum chisq;
  title "alzh";
run;


/************************************************************************************
	5.    UM | coverage | Plan characteristics
************************************************************************************/

* 1. merge with UM file;
/**************************************************
* new table: input.studypop
* original: input.glp1users_beneid_17to20_um
**************************************************/
proc sql;
   create table input.studypop as
   select distinct a.*, b.TIER_ID, b.PRIOR_AUTHORIZATION_YN, b.STEP, b.QUANTITY_LIMIT_YN, b.any_restict
   from input.studypop as a left join input.glp1users_beneid_17to20_um as b
   on a.BENE_ID = b.BENE_ID;
quit; /* 52781 obs */ 

/* PRIOR_AUTHORIZATION_YN */
proc freq data=input.studypop;
  table PRIOR_AUTHORIZATION_YN*offlabel_df5 / norow nopercent nocum chisq;
  title "PRIOR_AUTHORIZATION_YN";
run;

/* STEP */
proc freq data=input.studypop;
  table STEP*offlabel_df5 / norow nopercent nocum chisq;
  title "STEP";
run;

/* QUANTITY_LIMIT_YN */
proc freq data=input.studypop;
  table QUANTITY_LIMIT_YN*offlabel_df5 / norow nopercent nocum chisq;
  title "QUANTITY_LIMIT";
run;

* 3. merge with coverage file;
/**************************************************
* new table: input.studypop
* original: input.glp1users_pde_17to20_coverage
**************************************************/
proc sql;
   create table input.studypop as
   select distinct a.*, b.not_found_flag
   from input.studypop as a left join input.glp1users_pde_17to20_coverage as b
   on a.BENE_ID = b.BENE_ID;
quit; /* 69115 obs */ 

/* NA fill */
data input.studypop; set input.studypop; if missing(not_found_flag) then not_found_flag = 0; run;

/* coverage */
proc freq data=input.studypop;
  table not_found_flag*offlabel_df5 / norow nopercent nocum chisq;
  title "not_found_flag ==0 then coverage";
run;

/************************************************************************************
	6.    GLP-1 use
************************************************************************************/

* 1. GLP1 brand;
proc freq data=input.studypop;
  table BN*offlabel_df5 / norow nopercent nocum chisq;
  title "GLP-1 Brand";
run;

* 2. Ozempic Strength;
data studypop_ozempic;
  set input.studypop;
  if BN in ('OZEMPIC');
run;  /* 52781 obs */

proc freq data=studypop_ozempic;
  table STR*offlabel_df5 / norow nopercent nocum chisq;
  title "Ozempic Strength";
run;

* 3. Days Supply;
proc ttest data=input.studypop;
   class offlabel_df5;
   var DAYS_SUPLY_NUM;
   title "Days Supply";
run;

* off lebal use % by year;
data year; set input.studypop; year = year(SRVC_DT); run;

proc freq data=year;
  where year = 2018;
  table year*offlabel_df5 / norow nopercent nocum chisq;
  title "Offlabel Use %";
run;

/************************************************************************************
	6.    Cost calculation 
************************************************************************************/

* 1. OOP;
proc ttest data=input.studypop;
   class offlabel_df5;
   var PTNT_PAY_AMT;
   title "OOP Costs";
run;

* 2. TOT_RX_CST_AMT ;
proc ttest data=input.studypop;
   class offlabel_df5;
   var TOT_RX_CST_AMT ;
   title "TOT_RX_CST_AMT";
run;

