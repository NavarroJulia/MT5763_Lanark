
FILENAME REFFILE '/home/u62665966/sasuser.v94/Bootstrapping Group/seals.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=SEALS2.IMPORT;
	GETNAMES=YES;
RUN;

/* X - covariate : testosterone level
   Y - response : lengths          
  
From notes:

   To produce an efficient bootstrap in SAS, we want to create all our bootstrap samples
   first, and then run the analyses over these (as opposed to resample, analyse, resample, 
   analyse…). 
*/
  
  
  
  
  
/*    */
/* Compute the statistic of interest for the original data */
/* Resample B times from the data to form B bootstrap samples. */
/* Compute the statistic on each bootstrap sample. This creates the bootstrap distribution, which approximates the sampling distribution of the statistic. */
/* Use the approximate sampling distribution to obtain bootstrap estimates such as standard errors, confidence intervals, and evidence for or against the null hypothesis.   */
/*    */
  
  
 /* Bootstrapping for regression parameters */

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
Confidence Limit	Intercept    	X
lower 2.5          -33.22214	 0.37492
upper 97.5         -9.82988	     0.44761   */
  
  
  
  
  
  
/* Set names (change when put in macro) */

title "Bootstrap Distribution of Regression Estimates";
title2 "Case Resampling";
%let NumSamples = 5000;       * number of bootstrap resamples;
%let IntEst = -21.52601	;     * exact estimates of the intercept;
%let XEst   =    0.41127;     * exact estimates of X - testosterone;
 
/* Generate our samples: (reps = number of samples wanted) */
proc surveyselect data=SEALS2.IMPORT2 NOPRINT seed=314
     out=BootCases(rename=(Replicate=SampleID))
     method=urs              /* resample with replacement */
     samprate=1              /* each bootstrap sample has N observations */
     reps=&NumSamples;       /* generate NumSamples bootstrap resamples */
run;

/*View the whole data set:*/
proc print data=BootCases (obs=200);
run;


/* Compute the statistic for EACH bootstrap sample */
/* eg we have size(Num_samples) parameter estimations (PE):*/
proc reg data=BootCases outest=PEBoot noprint;
   by SampleID;
   freq NumberHits;
   model Y = X;
run;quit;

proc print data=PEboot (obs=100);
run;

/*    Visualize bootstrap distribution : 
      Histograms for each of the parameters */

title 'Distribution of Bootstrap parameters: Intercept';
  proc sgplot data=PEboot;
  histogram intercept;
  refline &IntEst / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("-21.52601");
run;

title 'Distribution of Bootstrap parameters: X (testosterone)';
  proc sgplot data=PEboot;
  histogram X;
   refline &XEst / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("0.41127");
run;

  
proc stdize data=PEBoot vardef=N pctlpts=2.5 97.5  PctlMtd=ORD_STAT outstat=Pctls;
   var Intercept X;
run;

/*            Intercept          X
 LOCATION	 -21.60776753	0.4115022263 */

/* give the CI : */
proc report data=Pctls nowd;
  where _type_ =: 'P';
  label _type_ = 'Confidence Limit';
  columns ('Bootstrap Confidence Intervals (B=&NumSamples)' _ALL_);
run; 
  
  
/*  

95% CI for parameters:

Bootstrap:

Confidence Limit	Intercept    	X
P2_5000	          -34.19822	     0.3890163
P97_5000	      -14.58739	     0.4507608


Compared to:
         
Confidence Limit	Intercept    	X
P2_5000	          -33.22214	     0.37492
P97_5000	      -9.82988	     0.44761  

*/
  
  
/*  Now need to convert this into macro format and figure out how to determine the
    speed up.....  */
  
  
  
  
  
  
  
  
  
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*This is a small SAS program to perform nonparametric bootstraps for a regression
/*It is not efficient nor general*/
/*Inputs: 																								*/
/*	- NumberOfLoops: the number of bootstrap iterations
/*	- Dataset: A SAS dataset containing the response and covariate										*/
/*	- XVariable: The covariate for our regression model (gen. continuous numeric)						*/
/*	- YVariable: The response variable for our regression model (gen. continuous numeric)				*/
/*Outputs:																								*/
/*	- ResultHolder: A SAS dataset with NumberOfLoops rows and two columns, RandomIntercept & RandomSlope*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

  
  
  
                          /* Code given */

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
%mend;

options nonotes;

/*Run the macro, note this take comparatively longer than the code above (5000 loops)!!!*/
%regBoot(NumberOfLoops= 5000, DataSet=SEALS2.IMPORT, XVariable=testosterone, YVariable=lengths);



/*View the whole data set: negative intercept, positive slope*/
proc print data=resultholder (obs=100);
run;
proc plot data=seals2.import;
   plot lengths*testosterone;
   title 'Lengths against testosterone';
run;

 