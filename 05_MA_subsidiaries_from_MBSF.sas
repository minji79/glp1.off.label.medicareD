/************************************************************************************
| Project name : Identify MA subsidiaries (n = 45,939)
| Task Purpose : 
|      1. Identify MA subsidiaries (n = 16,334, 23.63%)
|      2. 
| Final dataset : 
|	input.glp1users_beneid_17to20_ma
************************************************************************************/

proc print data=mbsf20.mbsf_abcd_summary_2020 (obs=20);
	var BENE_ID ptc_plan_type_cd_01--ptc_plan_type_cd_12; 
    title "mbsf_abcd_summary_2020";      
run; 

/************************************************************************************
	1.    Identify MA subsidiaries (n = 16,334, 23.63%)
************************************************************************************/

%macro yearly(year=, refer=);

proc sql;
	create table ma_&year as
 	select distinct a.*, b.ptc_plan_type_cd_01 as ma_&year, &year as ma_yr
	from input.glp1users_beneid_17to20 as a
 	left join &refer as b
  	on a.BENE_ID = b.BENE_ID;
quit;

%mend yearly;
%yearly(year=2020, refer=mbsf20.mbsf_abcd_summary_2020);
%yearly(year=2019, refer=mbsf19.mbsf_abcd_summary_2019);
%yearly(year=2018, refer=mbsf18.mbsf_abcd_summary_2018);
%yearly(year=2017, refer=mbsf17.mbsf_abcd_summary_2017);
%yearly(year=2016, refer=mbsf16.mbsf_abcd_summary_2016);

data ma; set ma_2020 ma_2019 ma_2018 ma_2017 ma_2016; run;

data input.glp1users_beneid_17to20_ma; 
	set ma;
 	if ma_2020 = 1 | ma_2019 = 1 | ma_2018 = 1 | ma_2017 = 1 | ma_2016 = 1 then ma_16to20 = 1;
  	else ma_16to20 = 0;
run;

/* check MA status in the year of the first GLP1 fill */
data input.glp1users_beneid_17to20_ma; 
	set input.glp1users_beneid_17to20_ma;
 	where year(index_date) = ma_yr;
  	if ma_16to20 = 1 then ma = 1;
  	else ma = 0;
run;

proc print data=input.glp1users_beneid_17to20_ma (obs=20); run;
proc freq data=input.glp1users_beneid_17to20_ma;  table ma_16to20; run;
