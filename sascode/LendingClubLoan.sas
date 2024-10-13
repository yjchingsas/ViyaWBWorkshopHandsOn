****************************************************************************************;
**                                                                                    **;
**         WORKBENCH WORKSHOP: Building AI Using SAS and Python                       **;
**                                                                                    **;
****************************************************************************************;
**                                                                                    **;
**  Lending Club is a peer-to-peer Lending company based in the US. They connect      **;
**  people looking to invest money with people who want to borrow money. When         **;
**  investors invest their money through Lending Club, this money is passed on        **;
**  to borrowers, and when borrowers pay back their loans, the capital plus the       **;
**  interest passes back to the investors. It is a win for everyone because the       **;
**  borrowers usually get lower loan rates and the investors receive higher returns.  **;
**                                                                                    **;
**  Our goal today is to develop a model that predicts whether the borrower will      **;
**  pay back the loan. We have historical data that contains one row per borrower.    **;
**  Our target variable is DEFAULT (0/1). Default represents whether the borrower     **;
**  defaulted(1) on the loan or paid(0) it back in full.                              **;
**                                                                                    **;
**  We will step though a standard model development process:                         **;
**      STEP 1: LOAD the input file                                                   **;
**      STEP 2: EXPLORE the data                                                      **;    
**      STEP 3: PARTITION the data                                                    **;
**      STEP 4: TRAIN a model                                                         **;
**      STEP 5: EVALUATE the results                                                  **;
**      STEP 6: SCORE the hold out sample                                             **;
**                                                                                    **;
****************************************************************************************;

*****************************************************;
**  system options                                 **;
*****************************************************;
* options source source2 mprint mlogic symbolgen;
* options nosource nosource2 nomprint nomlogic nosymbolgen;
ods graphics on;

*****************************************************;
**  assign librefs and identify the format library **;
*****************************************************;
libname Lend '/workspaces/myfolder/ViyaWBWorkshopHandsOn/sasdata';
run;
libname LendFMT '/workspaces/myfolder/ViyaWBWorkshopHandsOn/formats';
run;
options FMTSEARCH=(LendFMT);

*************************************************;
**                                             **;
**   STEP 1: LOAD THE INPUT DATA               **;
**                                             **;
*************************************************;
********************************************************************************;
** Assign Macro Variables for the libref, input csv file, and SAS data set    **;
********************************************************************************;
%let WBDataLib  = Lend;                * libref for workbench data             *;
%let inputData  = LCLoanData;          * input table                           *;
%let inputFile  = %str('/workspaces/myfolder/ViyaWBWorkshopHandsOn/inputData/lendingClubLoanData.csv');


********************************************************************************;
** Pull the .csv file into a SAS data set                                     **;
********************************************************************************;
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
            CreditLineAge     = "Length of Credit Line in Days"
            DebtIncRatio      = "Debt to Income Ratio"
            Default           = "Loan has not been Repaid"
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
**   STEP 2: EXPLORE THE DATA                  **;
**                                             **;
*************************************************;

************************************************************************;
** Review the proc CONTENTS, proc MEAN, and print 10 observations     **;
************************************************************************;
ods proctitle;
proc contents data = &WBDataLib..&inputData.;
  ods exclude enginehost;
run;

title "Summary Statistics of Lending Club Loan Data";
proc means data = &WBDataLib..&inputData. n nmiss mean min max std;
  ods exclude sortinfo;
run;

title "First 10 Rows of Lending Club Loan Data";
proc print data=&WBDataLib..&inputData.(obs=10);
run; 
title;

************************************************************************;
** Create user defined formats to improve the readability of output   **;
************************************************************************;
proc format library=LendFMT; 
  value posneg
			 low - -.000000001 = 'Negative Number'
				   	           0 = '0'
      0.000000001 - high = 'Positive Number'
  		;
  value agegroup
      low-14  = 'Children'
        14-24 = 'Youth'
        25-44 = 'Young Adult'
        45-64 = 'Middle Aged Adults'
      65-high = 'Seniors'
      ;
  value clage
			          low - -.000000001 = 'Negative Number'
				   	                    0 = '0'
       0.000000001-364.9999999999 = 'Less than a year'
              365-1824.9999999999 = '1-5 years'   
             1825-3649.9999999999 = '6-10 years'  
             3650-7299.9999999999 = '11-20 years' 
            7300-10949.9999999999 = '21-30 years'  
           10950-14599.9999999999 = '31-40 years' 
           14600-18249.9999999999 = '41-50 years' 
                       18250-high = 'Greater than 50 years' 
      ;
  value debtinc
		  low - -.000000001 = 'Negative Number'
				   	          0 = '0'
               .01-5.50 = '1 to 5%' 
             5.51-10.50 = '6 to 10%' 
            10.51-15.50 = '11 to 15%'
            15.51-20.50 = '16 to 20%'
            20.51-25.50 = '21 to 25%'
            25.51-30.50 = '25 to 30%'
                  other = 'Greater than 30%'
      ;
  value delinq
		  low - -.000000001 = 'Negative Number'
				   	          0 = '0'
                      1 = '1'  
                      2 = '2' 
                    3-5 = '3 to 5'
                   6-10 = '6 to 10'
                  11-15 = '11 to 15'
                  15-20 = '15 to 20'
                20-high = 'Greater than 20'
      ;
  value fico
      350-579 = 'Poor (350-579)' 
      580-669 = 'Fair (580-669)' 
      670-739 = 'Good (670-739)' 
      740-799 = 'Very Good (740-799)'
      800-850 = 'Exceptional (800-850)'
      other = 'other'
      ;
  value inquiries
		  low - -.000000001 = 'Negative Number'
				   	          0 = '0'
                      1 = '1'       
                    2-5 = '2-5'  
                   6-10 = '6-10'  
                  11-15 = '11-15'
                  16-20 = '16-20'
                  21-25 = '21-25'
                  26-30 = '26-30'
                  31-35 = '31-35'
                36-high = 'Greater than 35'
       ;
  value install
		  low - -.000000001 = 'Negative Number'
				   	          0 = '0'
            .01-100.99  = '$0 to $100'   
            101-200.99  = '$101 to $200'  
            201-300.99  = '$201 to $300' 
            301-400.99  = '$301 to $400'   
            401-500.99  = '$401 to $500'  
            501-600.99  = '$501 to $600' 
            601-700.99  = '$601 to $700' 
            701-800.99  = '$701 to $800'  
            801-900.99  = '$801 to $900' 
            901-1001.99 = '$901 to $1000' 
                  other = 'Greater than $1000'
         ;
  value interest
		  low - -.000000001 = 'Negative Number'
				   	          0 = '0%'
            .0001-.0449 = '1-4%'
             .045-.0549 = '5%'
             .055-.0649 = '6%'
             .065-.0749 = '7%'
             .075-.0849 = '8%'
             .085-.0949 = '9%'
             .095-.1049 = '10%'
             .105-.1149 = '12%'
             .115-.1249 = '12%'
             .125-.1349 = '13%'
             .135-.1449 = '14%'
             .145-.1549 = '15%'
             .155-.1649 = '16%'
             .165-.1749 = '17%'
             .175-.1849 = '18%'
             .185-.1949 = '19%'
             .195-.2049 = '20%'
             .205-.2149 = '21%'
             .215-.2249 = '22%'
                  other = 'Greater than 22%'
        ;
  value nloginc
		  low - -.000000001 = 'Negative Number'
	        0-6.999999999 = 'Less than 7'
          7-7.999999999 = '7'  
          8-8.999999999 = '8' 
          9-9.999999999 = '9'
        10-10.999999999 = '10'  
        11-11.999999999 = '11' 
        12-12.999999999 = '12'
        13-13.999999999 = '13'  
        14-14.999999999 = '14' 
                15-high = 'Greater than 15'
         ;
  value revbal
		  low - -.000000001 = 'Negative Number'
				   	          0 = '0'
          .01-499.99999 = '$0 to $499'   
          500-999.99999 = '$500 to $999'  
        1000-4999.99999 = '$1000 to $4999' 
        5000-9999.99999 = '$5000 to $9999'   
      10000-19999.99999 = '$10,000 to $20,000' 
      20000-29999.99999 = '$20,000 to $30,000'
      30000-39999.99999 = '$30,000 to $40,000'
      40000-49999.99999 = '$40,000 to $50,000'
             50000-high = 'Greater than $50,000'
       ;
  value revutil
		        low - -.000000001 = 'Negative Number'
				        	          0 = '0'
            0.000000000001-10 = 'under 10%'  
       10.0000000000001-20.50 = '10 to 20%'  
       20.5000000000001-30.50 = '20 to 30%'
       30.5000000000001-40.50 = '30 to 40%'
       40.5000000000001-50.50 = '40 to 50%'
       50.5000000000001-60.50 = '50 to 60%'
       60.5000000000001-70.50 = '60 to 70%'
       70.5000000000001-80.50 = '70 to 80%'
       80.5000000000001-90.50 = '80 to 90%'
       90.5000000000001-100   = '90 to 100%'
      100.0000000000001-high  = 'Greater than 100%'
      ;
run;

************************************************************************;
** Review the distribution of each field in tabular format            **;
************************************************************************;
proc freq data = &WBDataLib..&inputData.;
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

************************************************************************;
** Graph the distribution of the target variable                      **;
************************************************************************;
proc freq data=&WBDataLib..&inputData. noprint;
    tables default / out=defaultFREQ;
run;

proc sgplot data=defaultFREQ;
    hbar default / response=Count stat=percent
                   tip=(default count)
                   tiplabel=(auto 'Percent of Borrowers')
                   fillattrs=(color=darkblue transparency=.4)
                   dataskin=pressed;
    yaxis label='Default';
    xaxis label='Percent of Borrowers';
    title 'Distribution of Default';
run;

************************************************************************;
** Investigate the relationship between FICOScore and Default         **;
************************************************************************;
proc sort data=&WBDataLib..&inputData.;
    by default;
run;

ods noproctitle;
title "What is the relationship between FICO Score and Default?";
footnote italic 'NOTE: The distribution of borrowers who default is to the left of those who repay their loans.';
proc univariate data=&WBDataLib..&inputData.;
    class default;
    var FICOscore;  
    histogram FICOscore / overlay vaxislabel='Percent of Borrowers' endpoints= 600 to 850 by 25; 
    ods exclude Moments BasicMeasures ExtremeObs Quantiles TestsForLocation; 
run;
title;
footnote;

************************************************************************;
** Graph the distribution of Race and Gender                          **;
************************************************************************;
proc freq data=&WBDataLib..&inputData. noprint;
    by default;
    tables race*gender / out=raceFREQ;
run;

footnote italic 'NOTE: Is each group within Gender/Race fairly represented?';
proc sgplot data=raceFREQ;
   vbar gender / response=Count stat=percent
                 group=race
                 groupdisplay=stack
                 grouporder=descending
                 tip=(gender race count)
                 tiplabel=(auto auto 'Percent of Borrowers')
                 dataskin=pressed;
    yaxis label='Percent of Borrowers';
    xaxis label='Gender';
    keylegend / sortorder=ascending;
    title 'Gender Distribution across Race';
run;
footnote;

***************************************************************************;
** Investigate the relationship between Debt to Income Ratio and Default **;
***************************************************************************;
Title 'Debt to Income Ratio across Default';
footnote italic 'NOTE: There is a higher proportion of Default borrowers with Debt to Income above 16%';
proc sgpanel data=&WBDataLib..&inputData.;
    format debtincratio debtinc.;
    panelby default;
    histogram debtincratio / nbins=6
                             fillattrs=(color=darkred transparency=.3)
                             dataskin=pressed;
run;
footnote;
title;

*************************************************;
**                                             **;
**   STEP 3: PARTITION THE DATA                **;
**                                             **;
*************************************************;


****************************************************************************;
** create a 60/30/10 split, save the hold out data in a separate data set **;
****************************************************************************;
proc partition data=&WBDataLib..&inputData partind samppct=60 samppct2=30;
	by Default;
	output out=lendPART;
	ods exclude OutputCasTables STRAFreq;
run;

title 'Partitioned Lending Club Data';
proc freq data=lendPART;
table _PartIND_;
run;
title;

data lendTEST(drop=_partind_);
   set lendPART(where=(_partind_=0));
run;

data lendPART;
   set lendPART(where=(_partind_ in (1,2)));
run;

ods noproctitle;
title 'Training Data';
proc freq data=lendPART;
  table default;
run;

title 'Hold Out Sample';
proc freq data=lendTEST;
table default;
run;
title;


*************************************************;
**                                             **;
**   STEP 4: TRAIN THE MODEL                   **;
**                                             **;
*************************************************;

****************************************************************************;
** RANDOM FOREST                                                          **;
****************************************************************************;
title 'Random Forest trained on partitioned data';
ods output FitStatistics=forestFitStatistics;  
proc forest data=LendPART ntrees=100 seed=42;
    target Default / level=nominal;
    partition role=_partind_(train='1' validate='2');
    input  CreditPolicy PublicRecord Purpose / level=nominal;
    input  CreditLineAge  DebtIncRatio    Delinquencies2Yrs FICOScore  
           InterestRate   LogAnnualInc    Inquiries6Mnths   Installment
           RevBalance     RevUtilization     / level=interval;
    savestate rstore=forestAstore;
    ods exclude outputCasTables;
run;
title;

****************************************************************************;
** RANDOM FOREST: Save the Analytic Store                                 **;
****************************************************************************;
proc astore;
    download rstore=forestAstore store="/workspaces/myfolder/ViyaWBWorkshopHandsOn/astores/WB_forest.sasast";
run;



****************************************************************************;
** GRADIENT BOOST MODEL                                                   **;
****************************************************************************;
title 'Gradient Boost trained on partitioned data';
ods output FitStatistics=gboostFitStatistics;  
proc gradboost data=LendPART ntrees=100 seed=42;
    target Default / level=nominal;
    partition role=_partind_(train='1' validate='2');
    input  CreditPolicy PublicRecord Purpose / level=nominal;
    input  CreditLineAge  DebtIncRatio    Delinquencies2Yrs FICOScore  
           InterestRate   LogAnnualInc    Inquiries6Mnths   Installment
           RevBalance     RevUtilization     / level=interval;
    savestate rstore=gboostAstore;
    ods exclude outputCasTables;
run;
title;

****************************************************************************;
** GBOOST: Save the Analytic Store                                        **;
****************************************************************************;
proc astore;
    download rstore=gboostAstore store="/workspaces/myfolder/ViyaWBWorkshopHandsOn/astores/WB_gboost.sasast";
run;


*************************************************;
**                                             **;
**   STEP 5: EVALUATE THE MODELS               **;
**                                             **;
*************************************************;

****************************************************************************;
** RANDOM FOREST: Fit Statistics                                          **;
****************************************************************************;
data forestTRAINfitstats;
  set FORESTfitstatistics;
  length Misclass LogLoss ASE 8.;
  format Misclass LogLoss ASE 6.3;
  length Role $10.;
  Role = 'Training';
  label Misclass = 'Misclassification Rate'
        LogLoss = 'Log Loss'
        ASE = 'Average Square Error';
  Misclass = MiscTrain;
  LogLoss = LogLossTrain;
  ASE = ASETrain;
  drop ASEOob ASETrain ASEValid
       LogLossOob LogLossTrain LogLossValid  
       MiscOob MiscTrain MiscValid ;      
run;

data forestVALIDfitstats;
  set FORESTfitstatistics;
  length Misclass LogLoss ASE 8.;
  format Misclass LogLoss ASE 6.3;
  length Role $10.;
  Role = 'Validation';
  label Misclass = 'Misclassification Rate'
        LogLoss = 'Log Loss'
        ASE = 'Average Square Error';
  Misclass = MiscValid;
  LogLoss = LogLossValid;
  ASE = ASEValid;
  drop ASEOob ASETrain ASEValid
       LogLossOob LogLossTrain LogLossValid  
       MiscOob MiscTrain MiscValid ;      
run;

data forestEVAL;
  set forestTRAINfitstats forestVALIDfitstats;
run;

proc sgplot data=forestEVAL;
   styleattrs backcolor=lightgrey;
   series x=Trees y=Misclass / 
          group=Role
          smoothconnect
          
          dataskin=sheen;
   yaxis label='Misclassification Rate';
   xaxis label='Number of Trees';
   title 'RANDOM FOREST: Misclassification Rate';
run;

proc sgplot data=forestEVAL;
   styleattrs backcolor=lightgrey;
   series x=Trees y=LogLoss / 
          group=Role
          smoothconnect
          dataskin=sheen;
   yaxis label='Log Loss Rate';
   xaxis label='Number of Trees';
   title 'RANDOM FOREST: Log Loss Rate';
run;

proc sgplot data=forestEVAL;
   styleattrs backcolor=lightgrey;
   series x=Trees y=ASE / 
          group=Role
          smoothconnect
          dataskin=sheen;
   yaxis label='Average Square Error';
   xaxis label='Number of Trees';
   title 'RANDOM FOREST: Average Square Error';
run;


****************************************************************************;
** GRADIENT BOOST: Fit Statistics                                         **;
****************************************************************************;
data gboostTRAINfitstats;
  set GBOOSTfitstatistics;
  length Misclass LogLoss ASE 8.;
  format Misclass LogLoss ASE 6.3;
  length Role $10.;
  Role = 'Training';
  label Misclass = 'Misclassification Rate'
        LogLoss = 'Log Loss'
        ASE = 'Average Square Error';
  Misclass = MiscTrain;
  LogLoss = LogLossTrain;
  ASE = ASETrain;
  drop ASETrain ASEValid
       LogLossTrain LogLossValid  
       MiscTrain MiscValid ;      
run;

data gboostVALIDfitstats;
  set GBOOSTfitstatistics;
  length Misclass LogLoss ASE 8.;
  format Misclass LogLoss ASE 6.3;
  length Role $10.;
  Role = 'Validation';
  label Misclass = 'Misclassification Rate'
        LogLoss = 'Log Loss'
        ASE = 'Average Square Error';
  Misclass = MiscValid;
  LogLoss = LogLossValid;
  ASE = ASEValid;
  drop ASETrain ASEValid
       LogLossTrain LogLossValid  
       MiscTrain MiscValid ;      
run;

data gboostEVAL;
  set gboostTRAINfitstats gboostVALIDfitstats;
run;

proc sgplot data=gboostEVAL;
   styleattrs backcolor=lightgrey;
   series x=Trees y=Misclass / 
          group=Role
          smoothconnect
          
          dataskin=sheen;
   yaxis label='Misclassification Rate';
   xaxis label='Number of Trees';
   title 'GRADIENT BOOST: Misclassification Rate';
run;

proc sgplot data=gboostEVAL;
   styleattrs backcolor=lightgrey;
   series x=Trees y=LogLoss / 
          group=Role
          smoothconnect
          dataskin=sheen;
   yaxis label='Log Loss Rate';
   xaxis label='Number of Trees';
   title 'GRADIENT BOOST: Log Loss Rate';
run;

proc sgplot data=gboostEVAL;
   styleattrs backcolor=lightgrey;
   series x=Trees y=ASE / 
          group=Role
          smoothconnect
          dataskin=sheen;
   yaxis label='Average Square Error';
   xaxis label='Number of Trees';
   title 'GRADIENT BOOST: Average Square Error';
run;


*************************************************;
**                                             **;
**   STEP 6: SCORE THE HOLD OUT SAMPLE         **;
**                                             **;
*************************************************;

****************************************************************************;
** FOREST: use the ASTORE to score the hold out data                      **;
****************************************************************************;
title 'RANDOM FOREST: ASTORE Metadata';
proc astore;
    describe rstore=forestAstore;
    score data=lendTEST rstore=forestAstore
          out=forestPREDICTED copyvars=(default);
run;
title;

****************************************************************************;
** FOREST: Generate a frequency table for actual vs. predicted classes    **;
****************************************************************************;
proc freq data=forestPREDICTED noprint;
    tables default*I_Default / out=missclassFOREST;
run;

data missclassFOREST;
    set missclassFOREST;
    label = put(count, 8.);
run;

****************************************************************************;
** FOREST: Create a Confusion Matrix                                      **;
****************************************************************************;
proc sgplot data=missclassFOREST;
    heatmap x=I_Default y=default / 
        colorresponse=count 
        colormodel=(lightgrey mediumgrey darkgoldenrod) 
        discretex discretey;
    text x=I_Default y=default text=label / position=center;
    xaxis label="Predicted Class" values=(0 1);
    yaxis label="Actual Class" values=(0 1);
    title "RANDOM FOREST: Misclassification Table";
run;


****************************************************************************;
** GBOOST: use the ASTORE to score the hold out data                      **;
****************************************************************************;
title 'GRADIENT BOOST: ASTORE Metadata';
proc astore;
    describe rstore=gboostAstore;
    score data=lendTEST rstore=gboostAstore
          out=gboostPREDICTED copyvars=(default);
run;
title;

****************************************************************************;
** GBOOST: Generate a frequency table for actual vs. predicted classes    **;
****************************************************************************;
proc freq data=gboostPREDICTED noprint;
    tables default*I_Default / out=missclassGBOOST;
run;

data missclassGBOOST;
    set missclassGBOOST;
    label = put(count, 8.);
run;

****************************************************************************;
** GBOOST: Create a Confusion Matrix                                      **;
****************************************************************************;
proc sgplot data=missclassGBOOST;
    heatmap x=I_Default y=default / 
        colorresponse=count 
        colormodel=(lightgrey mediumgrey darkgoldenrod) 
        discretex discretey;
    text x=I_Default y=default text=label / position=center;
    xaxis label="Predicted Class" values=(0 1);
    yaxis label="Actual Class" values=(0 1);
    title "GRADIENT BOOST: Misclassification Table";
run;
