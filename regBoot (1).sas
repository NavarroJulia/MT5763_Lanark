/* Import file: */
FILENAME REFFILE '/home/u62665966/sasuser.v94/Bootstrapping Group/seals.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=SEALS2.IMPORT;
	GETNAMES=YES;
RUN;

/* Notes:

   X - covariate : testosterone level
   Y - response : lengths          
  
   From notes:

   To produce an efficient bootstrap in SAS, we want to create all our bootstrap samples
   first, and then run the analyses over these (as opposed to resample, analyse, resample, 
   analyse…). 
*/
 
  
  /*  ------------------------------------------------------------------------  */

 
  
                  /* Bootstrapping for regression parameters */



/* Investigate prior to using bootstrapping: */

data SEALS2.IMPORT2 (keep = X Y);
  set SEALS2.IMPORT(rename=(lengths=Y testosterone=X));  
  *rename lengths and testosterone as y and x (x is explanatory var and y is predicted var);
run;
 
/* without bootstrapping the parameter values are: */
proc reg data=SEALS2.IMPORT2;
   model Y = X / CLB;  *gives the 95% confidence limits for parameters;
run;quit; 
  
/*  

See the 95% CI of the parameters:
Confidence Limit	Intercept   | 	X
lower 2.5          -33.22214	|  0.37492
upper 97.5         -9.82988	    |  0.44761  

*/
  
  
/*  --------------------------------------------------------------------------------------------  */ 
  
  
                     /* Macro for bootstrapping of parameters: */
  
%macro regressionBoot(NumSamples, DataSet);


title "Bootstrap Distribution of Regression Estimates";
title2 "Case Resampling";
%let Samples = &NumSamples;   * number of bootstrap resamples; 
%let IntEst = -21.52601	;     * exact estimates of the intercept;
%let XEst   =    0.41127;     * exact estimates of X - testosterone;
 
/* Generate our samples: (reps = number of samples wanted) */
proc surveyselect data=SEALS2.IMPORT2 NOPRINT seed=314
     out=BootCases(rename=(Replicate=SampleID))
     method=urs              /* resample with replacement */
     samprate=1              /* each bootstrap sample has N observations */
     reps=&NumSamples;       /* generate NumSamples bootstrap resamples */
run;


/* Compute the statistic for EACH bootstrap sample */
/* eg we have size(Num_samples) parameter estimations (PE):*/
proc reg data=BootCases outest=PEBoot noprint;
   by SampleID;
   freq NumberHits;
   model Y = X;
run;quit;

/*  Gives location and confidence intervals etc  */
proc stdize data=PEBoot vardef=N pctlpts=2.5 97.5  PctlMtd=ORD_STAT outstat=Pctls;
   var Intercept X;
run;

/* Create data set with of lwr and upr limits of parameters */
DATA Values; 
SET Pctls;
KEEP Intercept X ;
where _type_ =: 'P';
label _type_ = 'Confidence Limit'; 
rename Intercept = CI_Intercept ;
rename X = CI_X;
RUN;


/* Extraxt the lower, upper limits of the parameters into columns each (repeated 
   in each column for plotting purposes) */
  
/* use CALL SYMPUT in a DATA step to assign the values to macro variables (used code from
   stackoverflow with minor edits) */
data _null_;
    set Values;
    call symput('variable_a_'||left(_n_), left(CI_Intercept));
    call symput('variable_b_'||left(_n_), left(CI_X));
run;

* check the macro variables values;

/* lower CI of Intercept: */
%put &=variable_a_1;

/* upper CI of Intercept: */
%put &=variable_a_2;

/* lower CI of X: */
%put &=variable_b_1;

/* upper CI of X: */
%put &=variable_b_2;

/* -------------------------------------------------------------------------------------- */

/*    Visualize bootstrap distribution : 
      Histograms for each of the parameters */

title 'Distribution of Bootstrap parameters: Intercept';
  proc sgplot data=PEboot;
  histogram intercept;
  refline &IntEst / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("-21.52601 (no bootstrap)");
/*  plot the confidence interval for intercept;  */
  refline &variable_a_1 / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("2.5% (=&variable_a_1)");
  refline &variable_a_2 / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("97.5% (=&variable_a_2)");
  run;

title 'Distribution of Bootstrap parameters: X (testosterone)';
  proc sgplot data=PEboot;
  histogram X;
   refline &XEst / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("0.41127 (no bootstrap)");
  refline &variable_b_1 / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("2.5% (=&variable_b_1)");
  refline &variable_b_2 / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("97.5% (=&variable_b_2)");
run;

/* -------------------------------------------------------------------------------------- */

/* select the CI (gives a table of the CI for parameters) need this in macro output */
title 'Distribution of Bootstrap parameters: Intercept and X';
proc report data=Pctls nowd;
  where _type_ =: 'P';
  label _type_ = 'Confidence Limit';
  columns ('Bootstrap Confidence Intervals' _ALL_);
run; 

%mend regressionBoot;

options nonotes;
  
  
  
%regressionBoot(9000, SEALS2.Import);
  
  
  
  