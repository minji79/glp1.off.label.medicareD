/************************************************************************************
| Project name : Identify off label use of GLP1 following several definitions
| Task Purpose : 
|      1. Definition 1 : Have no previous diabetic medication fill (non-GLP1) at first GLP-1 fill date (n = 7737, 11.19%)
|      2. Definition 2 : Have no recorded diagnosis of diabetes 1 year prior to first fill (n = 30694, 44.41%)
|      3. Definition 3 : Have no prior recorded diagnosis of diabetes within 5 years prior to the first fill (n = 30694, 44.41%)
|      4. Definition 4 : Both (1) AND (2)   (n = 4148, 6.00%)
|      5. Definition 5 : Had (3) and no diagnosis or (non-GLP1) diabetic fill within 1 year following the first GLP-1 fill (n = 2491, 3.60%)
| Final dataset : 
|       input.offlabel_v05
|       input.glp1users_all_medhis_16to20
|       input.glp1users_medhis_16to20
************************************************************************************/


/************************************************************************************
	1.    Definition 1 : Have no previous diabetic medication fill (non-GLP1) at first GLP-1 fill date (n = 7737, 11.19%)
************************************************************************************/

* 1. indicate the first GLP-1 fill date (index_date);
/**************************************************
* new table: input.glp1users_beneid_17to20
* original table: input.glp1users_beneid_17to20
* description: BENE_ID for 69,115 + add the first GLP-1 fill date
**************************************************/

proc sql;
   create table index_date as
   select BENE_ID, SRVC_DT as index_date
   from input.glp1users_pde_17to20
   group by BENE_ID;
quit;

proc sql;
   create table input.glp1users_beneid_17to20 as
   select distinct a.*, b.index_date 
   from input.glp1users_beneid_17to20 as a left join index_date as b
   on a.BENE_ID = b.BENE_ID;
quit; /* 69115 obs */ 


* 2. medication history for all glp1 users;
/**************************************************
* new table: input.glp1users_all_medhis_16to20
* original table: pde
* description: 
**************************************************/

%macro yearly(data=, refer=);

proc sql;
    create table &data as
    select distinct a.*, b.SRVC_DT, b.GNN
    from input.glp1users_beneid_17to20 as a 
    left join &refer as b
    on a.BENE_ID = b.BENE_ID;
    
quit;

%mend yearly;
%yearly(data=medhistory_2020, refer=pde20.pde_file_2020);  /* 4099396 obs */
%yearly(data=medhistory_2019, refer=pde19.pde_file_2019);  /* 3768132 obs */
%yearly(data=medhistory_2018, refer=pde18.pde_file_2018);  /* 3385536 obs */
%yearly(data=medhistory_2017, refer=pde17.pde_file_2017);  /* 3048838 obs */
%yearly(data=medhistory_2016, refer=pde16.pde_file_2016);  /* 2725088 obs */


/* stack all dataset */
data input.glp1users_all_medhis_16to20;
  set medhistory_2016 medhistory_2017 medhistory_2018 medhistory_2019 medhistory_2020;
run; /* 17026990 obs */


* 3. GNN list up diabetic medications based on 2024 ;
/**************************************************
* new table: input.glp1users_medhis_16to20
* original table: pde
* description: diabetic medications history
**************************************************/

/****************  modelcule | GNN ***************
metformin | metformin
insulin | insulin
dpp4i | sitagliptin, Linagliptin, Saxagliptin, Alogliptin
sglt2 | empagliflozin, dapagliflozin, canagliflozin, ertugliflozin, Bexagliflozin, Sotagliflozin
sulfonylureas | Glipizide, Glimepiride, Glyburide, Gliclazide
thiazolidinediones | Pioglitazone, 
meglitinide | nateglinide, repaglinide
others | acarbose, bromocriptine, miglitol
**************************************************/

data input.glp1users_medhis_16to20;
  set input.glp1users_all_medhis_16to20;
  
  where find(lowcase(GNN), 'metformin') > 0
     or find(lowcase(GNN), 'insulin') > 0

    /* dpp4i */
     or find(lowcase(GNN), 'sitagliptin') > 0
     or find(lowcase(GNN), 'linagliptin') > 0
     or find(lowcase(GNN), 'saxagliptin') > 0
     or find(lowcase(GNN), 'alogliptin') > 0

    /* sglt2 */
     or find(lowcase(GNN), 'empagliflozin') > 0
     or find(lowcase(GNN), 'canagliflozin') > 0
     or find(lowcase(GNN), 'dapagliflozin') > 0
     or find(lowcase(GNN), 'ertugliflozin') > 0
     or find(lowcase(GNN), 'bexagliflozin') > 0
     or find(lowcase(GNN), 'sotagliflozin') > 0

    /* sulfonylureas */
     or find(lowcase(GNN), 'glipizide') > 0
     or find(lowcase(GNN), 'glimepiride') > 0
     or find(lowcase(GNN), 'glyburide') > 0
     or find(lowcase(GNN), 'gliclazide') > 0

    /* thiazolidinediones */
     or find(lowcase(GNN), 'pioglitazone') > 0
     or find(lowcase(GNN), 'rosiglitazone') > 0

    /* meglitinide */
     or find(lowcase(GNN), 'repaglinide') > 0
     or find(lowcase(GNN), 'nateglinide') > 0
     
    /* others */
     or find(lowcase(GNN), 'acarbose') > 0
     or find(lowcase(GNN), 'bromocriptine') > 0
     or find(lowcase(GNN), 'miglitol') > 0;
   
run;   /* 2938909 obs */

* 4. index_date - 365 < SRVC_DT < index_date;
/**************************************************
* new table: input.offlabel_v01
* original table: input.glp1users_medhis_16to20
* description: 
**************************************************/

proc sql;
   create table offlabel_df1 as
   select distinct BENE_ID
   from input.glp1users_medhis_16to20
   where SRVC_DT > index_date - 365 and SRVC_DT < index_date;
quit; /* 62994 */

* 5. offlabel_df1 inndicator;
data offlabel_df1;
  set offlabel_df1;
  offlabel_df1 = 0;
run;

proc sql;
   create table input.offlabel_v01 as
   select distinct a.*, b.offlabel_df1
   from input.glp1users_beneid_17to20 as a left join offlabel_df1 as b
   on a.BENE_ID=b.BENE_ID;
quit;

data input.offlabel_v01;
  set input.offlabel_v01;
  if missing(offlabel_df1) then offlabel_df1 =1;
run;

proc freq data=input.offlabel_v01; table offlabel_df1; title "offlabel_df1"; run;


/************************************************************************************
	2.    Definition 2 : Have no recorded diagnosis of diabetes 1 year prior to first fill (n = 30694, 44.41%)
************************************************************************************/

* 1. offlabel_df2 inndicator;
/**************************************************
* new table: input.offlabel_v02
* original table: input.offlabel_v01
* description: 
**************************************************/

%macro yearly(year=);

data glp1_newusers_&year;
    set input.glp1users_pde_17to20;
    where rx_year = &year;
run;   

proc sql;
  create table offlabel_&year as
  select distinct a.BENE_ID,

    (b1.diabetes_tm) as diabetes_tm,
    (b2.diabetes_2nd_tm) as diabetes_2nd_tm,
    (b3.diabetes_ever) as diabetes_ever,
    (b4.diabetes_cc) as diabetes_cc

  from glp1_newusers_&year as a

  left join input.DM_TM b1 on a.BENE_ID = b1.BENE_ID and b1.diabetes_tm_yr in (&year, &year-1)
  left join input.DM_TM b2 on a.BENE_ID = b2.BENE_ID and b2.diabetes_2nd_tm_yr in (&year, &year-1)
  left join input.DM_diabetes_ever b3 on a.BENE_ID = b3.BENE_ID and b3.diabetes_ever_yr in (&year, &year-1)
  left join input.DM_diabetes_cc b4 on a.BENE_ID = b4.BENE_ID and b4.diabetes_cc_yr in (&year, &year-1);

quit;

/* diabetes_tm=1 | diabetes_2nd_tm = 1 | diabetes_ever=1 | diabetes_cc=1 -> have diabetes dignosis 1 year prior to Rx */
data offlabel_&year;
  set offlabel_&year;
  if diabetes_tm=1 | diabetes_2nd_tm =1 | diabetes_ever=1 | diabetes_cc=1 then offlabel_df2 = 0;
  else offlabel_df2 = 1;
run;

%mend yearly;

%yearly(year=2020);
%yearly(year=2019);
%yearly(year=2018);
%yearly(year=2017);

data offlabel_df2; set offlabel_2020 offlabel_2019 offlabel_2018 offlabel_2017; run;

/* merge with study population */
proc sql;
   create table input.offlabel_v02 as
   select distinct a.*, b.offlabel_df2
   from input.offlabel_v01 as a left join offlabel_df2 as b
   on a.BENE_ID=b.BENE_ID;
quit;

proc freq data=input.offlabel_v02; table offlabel_df2; run;

/************************************************************************************
	3.    Definition 3 : Have no prior recorded diagnosis of diabetes within 5 years prior to the first fill (n = 30694, 44.41%)
************************************************************************************/

* 1. offlabel_df3 inndicator;
/**************************************************
* new table: input.offlabel_v03
* original table: input.offlabel_v02
* description: 
**************************************************/


%macro yearly(year=);

data glp1_newusers_&year;
    set input.glp1users_pde_17to20;
    where rx_year = &year;
run;   

proc sql;
  create table offlabel_&year as
  select distinct a.BENE_ID,

    (b1.diabetes_tm) as diabetes_tm,
    (b2.diabetes_2nd_tm) as diabetes_2nd_tm,
    (b3.diabetes_ever) as diabetes_ever,
    (b4.diabetes_cc) as diabetes_cc

  from glp1_newusers_&year as a

  left join input.DM_TM b1 on a.BENE_ID = b1.BENE_ID and b1.diabetes_tm_yr in (&year, &year-5)
  left join input.DM_TM b2 on a.BENE_ID = b2.BENE_ID and b2.diabetes_2nd_tm_yr in (&year, &year-5)
  left join input.DM_diabetes_ever b3 on a.BENE_ID = b3.BENE_ID and b3.diabetes_ever_yr in (&year, &year-5)
  left join input.DM_diabetes_cc b4 on a.BENE_ID = b4.BENE_ID and b4.diabetes_cc_yr in (&year, &year-5);

quit;

/* diabetes_tm=1 | diabetes_2nd_tm = 1 | diabetes_ever=1 | diabetes_cc=1 -> have diabetes dignosis 1 year prior to Rx */
data offlabel_&year;
  set offlabel_&year;
  if diabetes_tm=1 | diabetes_2nd_tm =1 | diabetes_ever=1 | diabetes_cc=1 then offlabel_df3 = 0;
  else offlabel_df3 = 1;
run;

%mend yearly;

%yearly(year=2020);
%yearly(year=2019);
%yearly(year=2018);
%yearly(year=2017);

data offlabel_df3; set offlabel_2020 offlabel_2019 offlabel_2018 offlabel_2017; run;
proc print data=offlabel_df3 (obs=20); run;

/* merge with study population */
proc sql;
   create table input.offlabel_v03 as
   select distinct a.*, b.offlabel_df3
   from input.offlabel_v02 as a left join offlabel_df3 as b
   on a.BENE_ID=b.BENE_ID;
quit;

proc freq data=input.offlabel_v03; table offlabel_df3; run;


/************************************************************************************
	4.    Definition 4 : Both (1) AND (2)   (n = 4148, 6.00%)
************************************************************************************/

* 1. offlabel_df3 inndicator;
/**************************************************
* new table: input.offlabel_v03
* original table: input.offlabel_v02
* description: 
**************************************************/

data input.offlabel_v04;
  set input.offlabel_v03;
  if offlabel_df1 = 1 and offlabel_df2 = 1 then offlabel_df4 = 1;
  else offlabel_df4 = 0;
run;

proc freq data=input.offlabel_v04; table offlabel_df4; title "offlabel_df4"; run;



/************************************************************************************
	5.    Definition 5 : Had (3) and no diagnosis or (non-GLP1) diabetic fill after first GLP-1 fill (n = 2491, 3.60%)
************************************************************************************/
/**************************************************
* new table: input.offlabel_v04
* original table: input.glp1users_medhis_16to20
* description: 
**************************************************/

/* 1. diabetic fill after first GLP-1 fill */
proc sql;
   create table post_dm_med as
   select distinct BENE_ID
   from input.glp1users_medhis_16to20
   where index_date < SRVC_DT and SRVC_DT <= index_date + 365;
quit;

data post_dm_med; set post_dm_med; post_dm_med = 1; run;


/* 2. diabetes dignosis after first GLP-1 fill */
%macro yearly(year=);

data glp1_newusers_&year;
    set input.glp1users_pde_17to20;
    where rx_year = &year;
run;   

proc sql;
  create table post_dm_dig_&year as
  select distinct a.BENE_ID,

    (b1.diabetes_tm) as diabetes_tm,
    (b2.diabetes_2nd_tm) as diabetes_2nd_tm,
    (b3.diabetes_ever) as diabetes_ever,
    (b4.diabetes_cc) as diabetes_cc

  from glp1_newusers_&year as a

  left join input.DM_TM b1 on a.BENE_ID = b1.BENE_ID and b1.diabetes_tm_yr in (&year, %eval(&year+1))
  left join input.DM_TM b2 on a.BENE_ID = b2.BENE_ID and b2.diabetes_2nd_tm_yr in (&year, %eval(&year+1))
  left join input.DM_diabetes_ever b3 on a.BENE_ID = b3.BENE_ID and b3.diabetes_ever_yr in (&year, %eval(&year+1))
  left join input.DM_diabetes_cc b4 on a.BENE_ID = b4.BENE_ID and b4.diabetes_cc_yr in (&year, %eval(&year+1));

quit;

/* diabetes_tm=1 | diabetes_ever=1 | diabetes_cc=1 -> have diabetes dignosis 1 year prior to Rx */
data post_dm_dig_&year;
  set post_dm_dig_&year;
  if diabetes_tm=1 | diabetes_2nd_tm = 1 | diabetes_ever=1 | diabetes_cc=1 then post_dm_dig = 1;
  else post_dm_dig = 0;
run;

%mend yearly;

%yearly(year=2020);
%yearly(year=2019);
%yearly(year=2018);
%yearly(year=2017);

data post_dm_dig; set post_dm_dig_2020 post_dm_dig_2019 post_dm_dig_2018 post_dm_dig_2017; run;


/* 3. merge post_dm_med + post_dm_dig */
proc sql;
  create table offlabel_df5 as
  select distinct a.BENE_ID,

    (b1.post_dm_med) as post_dm_med,
    (b2.post_dm_dig) as post_dm_dig

  from input.glp1users_beneid_17to20 as a

  left join post_dm_med b1 on a.BENE_ID = b1.BENE_ID
  left join post_dm_dig b2 on a.BENE_ID = b2.BENE_ID ;

quit;

data offlabel_df5; 
	set offlabel_df5;
 	if post_dm_med = 1 | post_dm_dig = 1 then post_dm = 1;
  	else post_dm = 0;
run;

/* 4. merge post_dm_med + post_dm_dig */
proc sql;
   create table input.offlabel_v05 as
   select distinct a.*, b.post_dm
   from input.offlabel_v04 as a left join offlabel_df5 as b
   on a.BENE_ID=b.BENE_ID;
quit;

data input.offlabel_v05;
  set input.offlabel_v05;
  if post_dm = 0 and offlabel_df4 =1 then offlabel_df5 =1;
run;
data input.offlabel_v05; set input.offlabel_v05; if missing(offlabel_df5) then offlabel_df5 =0; run;

proc print data=input.offlabel_v05 (obs=20); run;

proc freq data=input.offlabel_v05; table post_dm; title "offlabel_df5"; run;
proc freq data=input.offlabel_v05; table offlabel_df5; title "offlabel_df5"; run;

* 3. delete dataset;
proc delete data =input.offlabel_v01; run;
proc delete data =input.offlabel_v02; run;
proc delete data =input.offlabel_v03; run;
proc delete data =input.offlabel_v04; run;
