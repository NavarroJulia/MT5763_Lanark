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

FILENAME REFFILE '/home/u62665966/sasuser.v94/Bootstrapping Group/seals.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=SEALS2.IMPORT;
	GETNAMES=YES;
RUN;
/* X - covariate : testosterone level
   Y - response : lengths          */
  
/*  From notes:

   To produce an efficient bootstrap in SAS, we want to create all our bootstrap samples
   first, and then run the analyses over these (as opposed to resample, analyse, resample, 
   analyse…). */
  
  
  
/*    */
/* Compute the statistic of interest for the original data */
/* Resample B times from the data to form B bootstrap samples. */
/* Compute the statistic on each bootstrap sample. This creates the bootstrap distribution, which approximates the sampling distribution of the statistic. */
/* Use the approximate sampling distribution to obtain bootstrap estimates such as standard errors, confidence intervals, and evidence for or against the null hypothesis.   */
/*    */
  
  
  
  /* regression bootstrap: case resampling */
data SEALS2.IMPORT2(keep=x y);
   set SEALS2.IMPORT(rename=(lengths=Y testosterone=X));  /* rename to make roles easier to understand */
run;
 
/* 1. compute the statistics on the original data */
proc reg data=SEALS2.IMPORT2;
   model Y = X / CLB covb;                          /* original estimates */
run; quit;
/*  covariance est table shows positive relationship. 

Also see the 95% CI of the parameters:
  Intercept : -33.22214	-9.82988
           X:   0.37492  0.44761  */
  
  

title "Bootstrap Distribution of Regression Estimates";
title2 "Case Resampling";
%let NumSamples = 50;       /* number of bootstrap resamples */
%let IntEst = -21.52601	;     /* original estimates for later visualization */
%let XEst   =    0.41127;
 
/* 2. Generate many bootstrap samples by using PROC SURVEYSELECT */
proc surveyselect data=SEALS2.IMPORT2 NOPRINT seed=314
     out=BootCases(rename=(Replicate=SampleID))
     method=urs              /* resample with replacement */
     samprate=1              /* each bootstrap sample has N observations */
     /* OUTHITS                 use OUTHITS option to suppress the frequency var */
     reps=&NumSamples;       /* generate NumSamples bootstrap resamples */
run;

/*View the whole data set:*/
proc print data=BootCases (obs=200);
run;


/* 3. Compute the statistic for each bootstrap sample */
/* eg we have size(Num_samples) parameter estimations:*/
proc reg data=BootCases outest=PEBoot noprint;
   by SampleID;
   freq NumberHits;
   model Y = X;
run;quit;

/* 4. Visualize bootstrap distribution */
proc sgplot data=PEBoot;
   label Intercept = "Estimate of Intercept" X = "Estimate of Coefficient of X";
   scatter x=Intercept y=X / markerattrs=(Symbol=CircleFilled) transparency=0.7;
   /* Optional: draw reference lines at estimates for original data */
   refline &IntEst / axis=x lineattrs=(color=blue);
   refline &XEst / axis=y lineattrs=(color=blue);
   xaxis grid; yaxis grid;
run;
  
proc stdize data=PEBoot vardef=N pctlpts=2.5 97.5  PctlMtd=ORD_STAT outstat=Pctls;
   var Intercept X;
run;

proc report data=Pctls nowd;
  where _type_ =: 'P';
  label _type_ = 'Confidence Limit';
  columns ('Bootstrap Confidence Intervals (B=&NumSamples)' _ALL_);
run; 
  
  
/*  

Bootstrap:

Confidence Limit	Intercept    	X
P2_5000	          -34.19822	     0.3890163
P97_5000	      -14.58739	     0.4507608


Compared to:
         
Confidence Limit	Intercept    	X
P2_5000	          -33.22214	     0.37492
P97_5000	      -9.82988	     0.44761  

*/
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
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
/*Run the macro*/
%regBoot(NumberOfLoops= 100, DataSet=SEALS2.IMPORT, XVariable=testosterone, YVariable=lengths);





/*View the whole data set: negative intercept, positive slope*/
proc print data=resultholder (obs=100);
run;
proc plot data=seals2.import;
   plot lengths*testosterone;
   title 'Lengths against testosterone';
run;

 