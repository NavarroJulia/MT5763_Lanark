
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
  
  
  
/* Below is code but not in macro, below that is the macro called regressionBoot  */
  
  
  /*  ------------------------------------------------------------------------  */

  
  
/*    */
/* Compute the statistic of interest for the original data */
/* Resample B times from the data to form B bootstrap samples. */
/* Compute the statistic on each bootstrap sample. This creates the bootstrap distribution, which approximates the sampling distribution of the statistic. */
/* Use the approximate sampling distribution to obtain bootstrap estimates such as standard errors, confidence intervals, and evidence for or against the null hypothesis.   */
/*    */
  
  
  
  
  
  
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
%let Samples = &NumSamples;       * number of bootstrap resamples; 
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


/* Create data set with CI and other values (merge with PEBoot for histograms) */
DATA Values; 
SET Pctls;
KEEP Intercept X _type_;
where _type_ =: 'P';
label _type_ = 'Confidence Limit'; 
rename Intercept = CI_Intercept ;
rename X = CI_X;
RUN;



/* Goal: extraxt the lower, upper limits of the parameters into columns each (repeated 
   in each column for plotting purposes) */


%let Samples = &NumSamples;      


/* DATA Values2;  */
/* SET Values; */
/* keep CI_Intercept */
/* RUN; */
/*  */
/* PROC TRANSPOSE DATA=values2 OUT=values2_1 (drop = _label_ _name_); */
/* VAR CI_Intercept;         */
/* RUN;  */
/*  */
/* Merge PEBoot with Values: */
/* DATA PEBoot2; */
/* SET  PEBoot Values2_1;  */
/* RUN; */






/*    Visualize bootstrap distribution : 
      Histograms for each of the parameters */

title 'Distribution of Bootstrap parameters: Intercept';
  proc sgplot data=PEboot;
  histogram intercept;
  refline &IntEst / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("-21.52601 (no bootstrap)");
/*   refline &IntEst / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("2.5%"); */
/*   refline &IntEst / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("97.5%"); */
run;

title 'Distribution of Bootstrap parameters: X (testosterone)';
  proc sgplot data=PEboot;
  histogram X;
   refline &XEst / axis=x lineattrs=(thickness=3 color=red pattern=dash) label = ("0.41127 (no bootstrap)");
run;


/* select the CI (gives a table of the CI) need this in macro output */
title 'Distribution of Bootstrap parameters: Intercept and X';
proc report data=Pctls nowd;
  where _type_ =: 'P';
  label _type_ = 'Confidence Limit';
  columns ('Bootstrap Confidence Intervals' _ALL_);
run; 

%mend regressionBoot;

options nonotes;
  
  
  
  
%regressionBoot(9000, SEALS2.Import);
  
  
  
  