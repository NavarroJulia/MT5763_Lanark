/*  */
/* Please create a library called SEALS and add the path to this folder (where code is).
   And add csv file in the folderwhere code is located (under server files & folder, under
   sasuser.v94)
 */

FILENAME REFFILE '/home/u62665966/sasuser.v94/Jack Knifing/seals.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=SEALS.IMPORT;
	GETNAMES=YES;
RUN;


/*                         Main flow of the code (run in order):

                           ----PART 1:----
Perform Jackknife method in SAS and obtain the SE for the mean
 - run code from lines 42 - 131,
 - SE for the mean is on line 135 - 137

                           ----PART 2:----
Calculating the SE for the mean without the jackknife method
 - run code from lines 149 - 175,
 - SE is on lines 180 - 182
 
                           ----PART 3:----
Compare the means: lines 197 - 198 

-> show data is linear: lines 211 - 214

*/



/*-----------------------------------------------------------------------------------------*/
/*-------------------------------------PART 1:---------------------------------------------*/
/*-----------------------------------------------------------------------------------------*/


DATA seals.import_lengths; 
SET seals.import;
Keep Lengths;                *keep lengths column, drop the other one (not needed);
RUN;



DATA seals.import_lengths; 
SET seals.import_lengths;
RENAME lengths=Jackknife_0;      *rename original data as Jackknife_0 (did this
                                           because the loops below will be easier to 
                                           implement);
RUN;


data seals.import_Jack_100copies (drop=j);
set seals.import_lengths;
array Jackknife_[100];          *define array;
  do j = 1 to 100;              *create columns using loop;
  Jackknife_[j] = Jackknife_0;  *100 data columns with same (original) data;
  end;                          *we have 101 total columns (Jackknife_0, Jackknife_1 - 
                                 Jackknife_100);
run;


data seals.import_Jack_Diag (drop=i);
set seals.import_Jack_100copies;
array Jackknife Jackknife_1 -- Jackknife_100;   *apply loop over all columns;
    do i=1 to dim(jackknife);
    if _n_ = i then jackknife[i] = 0;           *if row = column replace entry by 0;
    end;                                        *creates 0s across diagonals;
run;


                  /* take transpose */

PROC TRANSPOSE DATA=seals.import_Jack_Diag OUT=seals.import_Jack_Transpose;
VAR Jackknife_0-Jackknife_100;          *transpose the data to take mean (row-wise);
RUN;                                    *columns name go from COL1 to COL100;


                  /* calculate row wise mean: */

data seals.import_Jack_Mean ;
  set seals.import_Jack_Transpose;
  Rename _NAME_ = Sample;            *rename column as sample (nicer name);
  Means = mean(of Col1 - Col100);    *calculate the mean over all columns (row-wise);
run;


                  /* Calculate standard error using this: */

DATA seals.import_Jack_OnlyMean; 
SET seals.import_Jack_Mean;
KEEP Means;                     *only use the means column - need this for SE;
RUN;



                   /* Calculate Standard Error for Mean: */
              
              
data seals.import_Jack_Square;
set seals.import_Jack_OnlyMean;
Means1 = 110.71628445; *manually take the first observation's mean
                       (where we did not remove any observations, i.e., Jackknife_0);
Diff = Means-Means1;   *store the differences in new column, Diff;
Square = Diff**2;      *square the differences and store in new column, Square;
run;


proc means data=seals.import_Jack_Square sum;
    variable Square;   *calculate the sums of the column, Square;
run;
                 /* Sum(Square) = 122.8845513 */

 
data seals.import_Jack_SE;
set seals.import_Jack_Square;
Sum = 122.8845513;         *we manually take the sum;
SE = sqrt((99/100)*Sum);   *calculate the rest of the formula, where n=100, store in SE;
run;
                  /* SE ~ 11.029764539 */


DATA seals.import_Jack_SE; 
SET seals.import_Jack_SE;
KEEP SE;                      *keep only the SE column;
rename SE = Standard_Error;   *rename appropriately;
RUN;

                  /*Look at the SE:*/
                 
proc print data=seals.import_Jack_SE (obs=1); *keep the first observation (note that all 
                                               are the same in the column);
run;

                  /* = 11.0298 */

/*-----------------------------------------------------------------------------------------*/
/*-------------------------------------PART 2:---------------------------------------------*/
/*-----------------------------------------------------------------------------------------*/


                       /* Calculate analytical standard error */


data seals.import_Jack_AnalyticalSE;
set seals.import_Jack_Diag;
keep Jackknife_0;                      *keep the original lengths;   
run;

data seals.import_Jack_AnalyticalSE;
set seals.import_Jack_AnalyticalSE;
MeanJack_0 = 110.71628445;             *manually write the mean;
Diff = Jackknife_0 - MeanJack_0;       *find the difference, store in Diff;
Square = Diff**2;                      *square it and store in Square;
run;


               /* find the sum manually: */

proc means data=seals.import_Jack_AnalyticalSE sum;
    variable Square;   *calculate the sums of the column, Square;
run;
               /* Sum(Square) = 3035.96 */


data seals.import_Jack_AnalyticalSE;
set seals.import_Jack_AnalyticalSE;
Sum = 3035.96; 
Standard_error = sqrt((1/100)*Sum);  
keep Standard_Error;       
run;


               /*Look at the SE:*/

proc print data=seals.import_Jack_AnalyticalSE (obs=1); *keep the first observation (note that all 
                                                         are the same in the column);
run;

        /* Standard Error is 5.50995 which is smaller than for the Jackknife 
           sample (= 11.029764539)*/



/*-----------------------------------------------------------------------------------------*/
/*-------------------------------------PART 3:---------------------------------------------*/
/*-----------------------------------------------------------------------------------------*/


/* Compare the mean of the original data to the average using Jackknifing */

/* 
   Mean from sample = 110.71628445
   Mean using Jackknifing = 109.6201 (see code below for calculation)
*/

proc sql;
    select avg(Means) as Mean_Jackknife
    from seals.import_Jack_OnlyMean;
quit;


/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

                  /* Relationship appears linear: */

proc plot data=SEALS.IMPORT;
   plot lengths*testosterone;
   title 'Lengths against testosterone';
run;


/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */


















