/* Import file: */
FILENAME REFFILE '/home/u62665966/sasuser.v94/Bootstrapping Group/seals.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=SEALS2.IMPORT;
	GETNAMES=YES;
RUN;




/* 

                            Task 2: Bootstrap (SAS)

• Create a faster equivalent of the bootstrapping macro regBoot.sas. It only needs to work for one
covariate. (done)
• Use the seals data (seals.csv) to perform a regression of testosterone level (in µg/l) on length (in
cm). This is a fictional dataset of male hormone levels in seals of different lengths.
• State and visualise the 95% confidence intervals for the estimates of each parameter (intercept and
slope). Provide a histogram for the distribution of each bootstrapped parameter. (done)

• Compare regBoot.sas to your modified version to determine the speed-up. 
• Compare the boostrapped parameter estimates and their 95% confidence intervals to those obtained
using the built-in SAS procedure.

                             Deliverables
                             
• Show your code and visualised results.
• Discuss and interpret your comparative analysis.

 */






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
proc reg data=BootCases outest=PEBoot NOPRINT;
   by SampleID;
   freq NumberHits;
   model Y = X;
run;quit;

/*  Gives location and confidence intervals etc  */
proc stdize data=PEBoot vardef=N pctlpts=2.5 97.5  PctlMtd=ORD_STAT outstat=Pctls;
   var Intercept X;
run;

/* Create changing macro variables - location of parameters and their CIs. */
/* Use CALL SYMPUT in a DATA step to assign the values to macro variables (used code from */
/*    stackoverflow with minor edits) */
data _null_;
    set Pctls;
    call symput('variable_a_'||left(_n_), left(Intercept));
    call symput('variable_b_'||left(_n_), left(X));
run;

/*  The macro variables we will be using (note we do not use all): */

/* location of intercept: */
%put &=variable_a_1;

/* location of X: */
%put &=variable_b_1;

/* lower CI of Intercept: */
%put &=variable_a_9;

/* upper CI of Intercept: */
%put &=variable_a_10;

/* lower CI of X: */
%put &=variable_b_9;

/* upper CI of X: */
%put &=variable_b_10;


/* -------------------------------------------------------------------------------------- */

/*    Visualize bootstrap distribution : 
      Histograms for each of the parameters */
     
/* Note that here we use the macro variable to indicate location of parameter estimate and
   the CIs of the parameters!!! */

title 'Distribution of Bootstrap parameters: Intercept';
  proc sgplot data=PEboot;
  histogram intercept;
  refline &variable_a_1 / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("Location (=&variable_a_1)");
/*  plot the confidence interval for intercept:  */
  refline &variable_a_9 / axis=x lineattrs=(thickness=2 color=red pattern=solid) label = ("2.5% (=&variable_a_9)");
  refline &variable_a_10 / axis=x lineattrs=(thickness=2 color=red pattern=solid) label = ("97.5% (=&variable_a_10)");
  run;

title 'Distribution of Bootstrap parameters: X (Testosterone)';
  proc sgplot data=PEboot;
  histogram X;
  refline &variable_b_1 / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("Location (=&variable_b_1)");
/*  plot the confidence interval for X:  */  
  refline &variable_b_9 / axis=x lineattrs=(thickness=2 color=red pattern=solid) label = ("2.5% (=&variable_b_9)");
  refline &variable_b_10 / axis=x lineattrs=(thickness=2 color=red pattern=solid) label = ("97.5% (=&variable_b_10)");
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
  

/* Start timer */
%let _timer_start = %sysfunc(datetime());  
  
%regressionBoot(100000, SEALS2.Import);
  
/* Stop timer */
data _null_;
  dur = datetime() - &_timer_start;
  put 30*'-' / ' TOTAL DURATION:' dur time13.2 / 30*'-';
run; 
 
/*  for 5000 sample:  TOTAL DURATION:   0:00:00.66 */
 
 
/* 
   • Compare regBoot.sas to your modified version to determine the speed-up. (Done)
   
   • Compare the boostrapped parameter estimates and their 95% confidence intervals to those obtained
     using the built-in SAS procedure.  
*/
  
  
  
/*  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$  */
  
                      /*  Compare with code previously given:  */
  


%macro regBoot(NumberOfLoops, DataSet, XVariable, YVariable);

/*Number of rows in my dataset*/
 	data _null_;
  	set &DataSet NOBS=size;
  	call symput("NROW",size);
 	stop;
 	run;

/*loop over the number of randomisations required*/
%do i=1 %to &NumberOfLoops;

/*Sample my data with replacement*/
	proc surveyselect data=&DataSet out=bootData seed=-3014 method=urs noprint sampsize=&NROW;
	run;

/*Conduct a regression on this randomised dataset and get parameter estimates*/
	proc reg data=bootData outest=ParameterEstimates  noprint;
	Model &YVariable=&XVariable;
	run;
	quit;

/*Extract just the columns for slope and intercept for storage*/
	data Temp;
	set ParameterEstimates;
	keep Intercept &XVariable;
	run;

/*Create a new results dataset if the first iteration, append for following iterations*/
	data ResultHolder;
		%if &i=1 %then %do;
			set Temp;
		%end;
		%else %do;
			set ResultHolder Temp;
		%end;
	run;
	%end;
/*Rename the results something nice*/
data ResultHolder;
set ResultHolder;
rename Intercept=RandomIntercept &XVariable=RandomSlope;
run;
%mend regBoot;

options nonotes;


/*Run the macro, note this take comparatively longer than the the newer code!!!*/

/* Start timer */
%let _timer_start = %sysfunc(datetime());  
  
%regBoot(NumberOfLoops= 500, DataSet=SEALS2.IMPORT, XVariable=testosterone, YVariable=lengths);

/* Stop timer */
data _null_;
  dur = datetime() - &_timer_start;
  put 30*'-' / ' TOTAL DURATION:' dur time13.2 / 30*'-';
run;

/* for 500 samples: TOTAL DURATION:   0:00:08.80 */
 
  
  
  
  
  
  
  
            /* Investigate using built-in SAS procedure: */

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


%let Intlwr = -33.22214	;     * lwr CI of Intercept;
%let Intupr = -9.82988;       * upr CI of Intercept;

%let Xlwr = 0.37492	;      * lwr CI of X;
%let Xupr = 0.44761;       * upr CI of X;



/* Let us add these on top the histograms: */

title 'Distribution of Bootstrap parameters: Intercept';
  proc sgplot data=PEboot;
  histogram intercept;
  refline &variable_a_1 / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("Location (=&variable_a_1)");
/*  plot the confidence interval for intercept:  */
  refline &variable_a_9 / axis=x lineattrs=(thickness=2 color=red pattern=solid) label = ("2.5% (=&variable_a_9)");
  refline &variable_a_10 / axis=x lineattrs=(thickness=2 color=red pattern=solid) label = ("97.5% (=&variable_a_10)");
  
  refline &Intlwr / axis=x lineattrs=(thickness=2.5 color=blue pattern=solid) label = ("2.5% (=&Intlwr)");
  refline &Intupr / axis=x lineattrs=(thickness=2.5 color=blue pattern=solid) label = ("97.5% (=&Intupr)");
  
run;

title 'Distribution of Bootstrap parameters: X (Testosterone)';
  proc sgplot data=PEboot;
  histogram X;
  refline &variable_b_1 / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("Location (=&variable_b_1)");
/*  plot the confidence interval for X:  */  
  refline &variable_b_9 / axis=x lineattrs=(thickness=2 color=red pattern=solid) label = ("2.5% (=&variable_b_9)");
  refline &variable_b_10 / axis=x lineattrs=(thickness=2 color=red pattern=solid) label = ("97.5% (=&variable_b_10)");

  refline &Xlwr / axis=x lineattrs=(thickness=2.5 color=blue pattern=solid) label = ("2.5% (=&Xlwr)");
  refline &Xupr / axis=x lineattrs=(thickness=2.5 color=blue pattern=solid) label = ("97.5% (=&Xupr)");
  
run;  
  
  
  
  
  
  
  
  
  
  
  
  