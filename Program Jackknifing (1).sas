/*Import data/ read in file:*/
FILENAME REFFILE '/home/u62665966/sasuser.v94/Jack Knifing/seals.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=SEALS.IMPORT;
	GETNAMES=YES;
RUN;

/*View the whole data set:*/
proc print data=seals.import (obs=100);
run;


/* 
Write and implement code (modifying code already given to you in the lecture notes e.g. the
two sample randomisation test), to obtain a jackknife estimate for the standard error of the 
mean for seal body length, using the seals data set (seals.csv)
*/

/*Keep only the lengths column:*/
DATA seals.import_lengths; 
SET seals.import;
Keep Lengths;
RUN;

/* View: */
proc print data=seals.import_lengths (obs=100);
run;

DATA seals.import_lengths; 
SET seals.import_lengths;
RENAME lengths=Original_Lengths;
RENAME original_lengths=Jackknife_0;
RUN;

/*Combining column wise not row wise (as new columns)*/
DATA TestSettingCombining;
SET seals.import_lengths seals.import_lengths seals.import_lengths; 
RUN;



/* Create 100 new identical columns named Jackknife_i (i = 1 to 100) */
data seals.import_Jack_100copies (drop=j);
  set seals.import_lengths;
  array Jackknife_[100];        *creates 100 new columns;
  do j = 1 to 100;
 Jackknife_[j] = Jackknife_0;  *100 data columns with same data;
 end;
run;

/* Remove the diagonal entires of Jackknife_i (i = 1 to 100)*/
data seals.import_Jack_Diag (drop=i);
set seals.import_Jack_100copies;
array Jackknife Jackknife_1 -- Jackknife_100; 
do i=1 to dim(jackknife);
    if _n_ = i then jackknife[i] = 0;
end;
run;


/* take transpose */
PROC TRANSPOSE DATA=seals.import_Jack_Diag OUT=seals.import_Jack_Transpose;
VAR Jackknife_0-Jackknife_100;
RUN;

/* row wise mean: */
data seals.import_Jack_Mean (drop = col101);
  set seals.import_Jack_Transpose;
  Means = mean(of Col1 - Col101);
run;

/* Calculate standard error using this: */
DATA seals.import_Jack_OnlyMean; 
SET seals.import_Jack_Mean;
KEEP Means;
RUN;



/* Calculate (theta_i - mean)^2 */
data seals.import_Jack_Square;
set seals.import_Jack_OnlyMean;
Means1 = 110.71628445; *Means(obs=1);
Diff = Means-Means1; *where to store the differences;
Square = Diff**2;
run;

/* Calculate the sum of the squares */
proc means data=seals.import_Jack_Square sum;
    variable Square;
run;
/* =122.8845513 */

/* */
data seals.import_Jack_SE;
set seals.import_Jack_Square;
Sum = 122.8845513;
SE = sqrt((99/100)*Sum);
run;
/* SE ~ 11.029764539 */

/* convert to macor that prints first obs!! */








































