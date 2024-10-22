**************************************************************************;
**  system options for debugging purposes                               **;
**************************************************************************;
* options source source2 mprint mlogic symbolgen;
* options nosource nosource2 nomprint nomlogic nosymbolgen;

*************************************************;
**                                             **;
**        1a. LOAD THE INPUT DATA              **;
**                                             **;
*************************************************;
libname LCLD '/workspaces/myfolder/data/LendingClubLoan';
run;

************************************************************************;
* Assign Macro Variables for libname, input file, and output data      *;
************************************************************************;
%let WBDataLib     = LCLD;         * libref for workbench data         *;
%let WBTempLib     = work;         * libref for temporary data         *;
%let inputData     = LCLoanData;   * input table                       *;
%let inputFile     = %str('/workspaces/myfolder/data/inputData/lendingClubLoanData.csv');
%let partData      = LCLoanPart;   * partitioned data set              *;
%let trainValidate = LCLoanTrain;  * training and validation data      *;
%let holdOut       = LCLoanTest;   * hold out test sample              *;
%let stratvar      = default;      * stratified variable (usually the target) *;

data &WBDataLib..&inputData.;
  %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
  infile &inputFile. delimiter = ',' MISSOVER DSD firstobs=2 ;
      format CreditPolicy Default PublicRecord $1.;
      format Gender $6.;
      format Race $10.;
      format Purpose $20. ;
      format Age 
             InterestRate 
             Installment 
             LogAnnualInc
             DebtIncRatio 
             FICOScore 
             CreditLineAge 
             RevBalance 
             RevUtilization 
             Inquiries6Mnths 
             Delinquencies2Yrs best32.
             ;
      input
            CreditPolicy $  
            Purpose $ 
            InterestRate 
            Installment 
            LogAnnualInc
            DebtIncRatio 
            FICOScore 
            CreditLineAge 
            RevBalance
            RevUtilization
            Inquiries6Mnths 
            Delinquencies2Yrs 
            PublicRecord $
            Default $
            Age
            Race $
            Gender $
      ;
     Label
            Age               = "Age"
            CreditPolicy      = "Meets Lending Club Credit Underwriting Policy (0/1)"
            CreditLineAge     = "Length of Credit Line in Age"
            DebtIncRatio      = "Debt to Income Ratio"
            Default           = "Loan has not been fully repaid"
            Delinquencies2Yrs = "Credit Delinquencies in the last 2 Years"
            FICOScore         = "FICO Credit Score"
            Gender            = "Gender"
            Inquiries6Mnths   = "Credit Inquiries in the last 6 Months"
            InterestRate      = "Interest Rate"
            Installment       = "Monthly Installment"
            LogAnnualInc      = "Natural Log of Self Reported Annual Income"
            PublicRecord      = "Public Record"
            Purpose           = "Purpose of the Loan"
            Race              = "Race"
            RevBalance        = "Revolving Balance"
            RevUtilization    = "Revolving Utilitization"           
      ;  
  if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

*************************************************;
**                                             **;
**       1b. EXPLORE THE INPUT DATA            **;
**                                             **;
*************************************************;
ods graphics on;
ods trace on;

*************************************************;
**   review the proc CONTENTS                  **;
**              proc MEANS                     **;
**              10 observations                **; 
*************************************************;
%let inputStats = n nmiss mean min max std;
%contMeansPrint10(&WBDataLib..&inputData.,&inputStats.);

*************************************************;
**   review the proc FREQ                      **;
**   contains the values in each variable      **; 
**   user-defined fomats have been applied     **;
**   identify the user-defined format library  **;  
*************************************************;
OPTIONS FMTSEARCH=(jklFMT);
proc freq data = &wbdatalib..&inputData;
  tables CreditLineAge CreditPolicy DebtIncRatio Default Delinquencies2Yrs FICOscore 
         Inquiries6Mnths Installment InterestRate LogAnnualInc PublicRecord Purpose
         RevBalance RevUtilization Age Race Gender
         / nocum
          ;
  format Age               ageGroup.
         CreditLineAge     clage.
         DebtincRatio      debtinc.
         Delinquencies2Yrs delinq.
         FICOscore         fico.
         Inquiries6Mnths   inquiries.
         Installment       install.
         InterestRate      interest.
         LogAnnualInc      nloginc.         
         RevBalance        revbal.
         RevUtilization    revutil.
        ;
  run;

*************************************************;
**   define endpoints for proc UNIVARIATE      **; 
**   review var distributions by the target    **;
*************************************************;
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

%uni(&WBDataLib..&inputData.,&classVar.);

