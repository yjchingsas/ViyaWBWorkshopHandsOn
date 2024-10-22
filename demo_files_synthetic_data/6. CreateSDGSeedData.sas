*******************************************************************************;
* system options for debugging purposes                                      **;
*******************************************************************************;
* options source source2 mprint mlogic symbolgen;
* options nosource nosource2 nomprint nomlogic nosymbolgen;
ods noproctitle;

**************************************************;
**                                              **;
**     6a. CREATE SEED DATA FOR THE TABULARGAN  **;
**                                              **;
**************************************************;


*******************************************************************************;
* Assign Macro Variables for libname, input file, and output data            **;
*******************************************************************************;
%let WBDataLib = LCLD;             * libref for workbench data               **;
%let WBTempLib = work;             * libref for temporary data               **;
%let Training  = LCLoanTrain;      * training and validation data            **;
%let Seed      = LCLoanSeed;       * seed data for tabularGAN                **;


*******************************************************************************;
**           CONFIRM YOU HAVE ALREADY REMOVED HOLD OUT DATA                  **;
*******************************************************************************;
** examine the distribution for each variable and cross check w/the target   **;
** remove extreme outliers that might impact the synthetic data generation   **;
** create a centroid table to fend off negative values in the synthetic data **;
*******************************************************************************;
*----------------------------------------------------------------------------**;
* the following variables look fine:                                         **;                             
* CreditPolicy  Purpose   Installment  InterestRate                          **; 
* CreditLineAge FICOScore DebtIncRatio Inquiries6mnths                       **;
* Check back on Inquiries6Mnths- 6 slight outliers but 3 each wrt Default    **;
* Total Records removed = 289                                                **;
*------------------------------------------------------------------------------*

*******************************************************************************;
**   identify missing values                                                 **;
*******************************************************************************;
proc means data = &WBDatalib..&Training. NMiss min max mean N;
run;

*******************************************************************************;
**   examine distributions to identify extreme outliers                      **;
**   adjust the endpoints based on the min/max for each variable             **;
*******************************************************************************;
%let classVar=Default;
%let clAgeHistEndpoints=   0   to 18000   by 300;
%let dtiHistEndpoints=     0   to 30      by 2.5;
%let delinqHistEndpoints=  0   to 14      by 1;
%let ficoHistEndpoints=    600 to 850     by 25;
%let inqEndpoints=         0   to 34      by 1;
%let instHistEndpoints=    0   to 1000    by 50;
%let intHistEndpoints=     0   to .25     by .05;
%let nlogHistEndpoints=    7   to 15      by .5;
%let revbalHistEndpoints=  0   to 1300000 by 1500;
%let revutilHistEndpoints= 0   to 120     by 5;
%uni(&WBDataLib..&Training.,&classVar.);

*******************************************************************************;
**  remove extreme outliers - sythetic data is generated for all values up   **;
**  to and including these points.  if the value isn't reasonable, remove it **;
**  adjust the endpoints based on the min/max for each variable              **;
**  NOTE: 289 records removed, it isn't a direct count, multiple vars < 0    **;
*******************************************************************************;
data &WBDatalib..&Seed.;                         
  set &WBDatalib..&Training.;                         * begin with 8621 records;
    if PublicRecord in ('0','1','2');                 *     impacts   7 records; 
    if Delinquencies2Yrs <= 5;                        *     impacts   6 records; 
    if 9.18000 <= LogAnnualInc < 12.60000;            *     impacts 106 records; 
    if RevBalance <= 150000;                          *     impacts  88 records; 
    if RevUtilization <= 99;                          *     impacts  75 records;
    if Inquiries6mnths <=15;                          *     impacts  20 records;
run;

*******************************************************************************;
**  split the data based on target to allow for oversampling                 **;
*******************************************************************************;
data &WBDatalib..&Seed._1;    * 1317 records 16% ;
  set &WBDatalib..&Seed.; 
  if default = '1'; 
run;

data &WBDatalib..&Seed._0;    * 7035 records 84% ;
  set &WBDatalib..&Seed.; 
  if default = '0'; 
run;

proc means data =&WBdatalib..&seed. min max;
run;


