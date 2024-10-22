
******************************************************;
**                                                  **;
** Define macros to produce descriptive statistics  **;
**                                                  **;
******************************************************;
** activate system options for debugging purposes   **;
******************************************************;
* options notes source source2 mprint mlogic symbolgen;

******************************************************;
**  proc CONTENTS/MEANS with specified statistics   **;
******************************************************;
%macro ContMeansPrint10(inputData,inputStats);
  proc contents data = &inputData;
    ods exclude enginehost;
  run;
  proc means data = &inputData &inputStats;
    ods exclude sortinfo;
    run;
  proc print data=&inputData(obs=10);
  run; 
%mend ContMeansPrint10;

******************************************************;
**  proc FREQ with USER DEFINED FORMATS applied     **;
******************************************************;
%macro freqUserDefined(inputData);
  proc freq data = &inputData;
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
%mend freqUserDefined;

********************************************************;
**  proc FREQ with POSITIVE/NEGATIVE FORMATS applied  **;
********************************************************;
%macro freqPosNeg(inputData);
  proc freq data = &inputData;
  tables CreditLineAge     CreditPolicy   DebtIncRatio 
         Delinquencies2Yrs InterestRate   FICOSCore        
         Inquiries6Mnths   Installment    Purpose
         RevUtilization    LogAnnualInc   RevBalance   
         PublicRecord      Default         
         / nocum
        ;
  format CreditLineAge 
         DebtincRatio 
         Delinquencies2Yrs 
         FICOscore
         Inquiries6Mnths 
         Installment 
         InterestRate 
         LogAnnualInc          
         RevBalance 
         RevUtilization     posneg.
        ;
  run;
%mend freqPosNeg;

********************************************************;
**  proc FREQ without the AGE/GENDER/RACE variables   **;
********************************************************;
%macro freqNoAGR(inputData);
  proc freq data = &inputData;
  tables CreditLineAge     CreditPolicy   DebtIncRatio 
         Delinquencies2Yrs InterestRate   FICOSCore        
         Inquiries6Mnths   Installment    Purpose
         RevUtilization    LogAnnualInc   RevBalance   
         PublicRecord      Default         
         / nocum
        ;
  format CreditLineAge clage.
         DebtincRatio debtinc.
         Delinquencies2Yrs delinq.
         FICOscore fico.
         Inquiries6Mnths inquiries.
         Installment install.
         InterestRate interest.
         LogAnnualInc nlog.         
         RevBalance revbal.
         RevUtilization revutil.
        ;
  run;
%mend freqNoAGR;


************************************************************;
**    proc UNIVARIATE with CUSTOM ENDPOINTS defined       **;
************************************************************;
%macro uni(inputData,classVar);
  
  **********************************************************;
  ** SORT the data using the class var                    **;
  **********************************************************;
  proc sort data=&inputData;
    by &classVar;
  run;

  **********************************************************;
  **     endpoints assigned based on mix/max values       **;
  **********************************************************;
  proc univariate data=&inputData;
    class &classVar;
    var CreditLineAge DebtIncRatio Delinquencies2Yrs FICOscore  Inquiries6Mnths  
        Installment   InterestRate LogAnnualInc      RevBalance RevUtilization  
        ;
    histogram CreditLineAge     / overlay endpoints= &clAgeHistEndPoints.;
    histogram DebtIncRatio      / overlay endpoints= &dtiHistEndpoints.;     
    histogram Delinquencies2Yrs / overlay endpoints= &delinqHistEndpoints.;      
    histogram FICOscore         / overlay endpoints= &ficoHistEndpoints.;     
    histogram Inquiries6Mnths   / overlay endpoints= &inqEndpoints.;       
    histogram Installment       / overlay endpoints= &instHistEndpoints.;    
    histogram InterestRate      / overlay endpoints= &intHistEndpoints.;       
    histogram LogAnnualInc      / overlay endpoints= &nlogHistEndpoints.;     
    histogram RevBalance        / overlay endpoints= &revbalHistEndpoints.; 
    histogram RevUtilization    / overlay endpoints= &revutilHistEndpoints.;     
    ods exclude Moments BasicMeasures ExtremeObs Quantiles TestsForLocation; 
    run;

%mend uni;



