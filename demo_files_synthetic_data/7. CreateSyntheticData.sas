**************************************************;
**                                              **;
**  7. CREATE SYNTHETIC DATA USING TABULARGAN   **;
**     Oversample the event 60/40               **;
**                                              **;
**************************************************;

*****************************************************************************;
* Assign Macro Variables for libname, input file, and output data          **;
*****************************************************************************;
options notes nosource nosource2 nomprint nomlogic nosymbolgen;
ods noproctitle;   
%let WBDataLib    = LCLD;                      * libref for workbench data **;
%let inputData    = LCLoanSeed_0;              * partitioned input table   **;
%let inputData1   = LCLoanSeed_1;              * partitioned input table   **;
%let centroids    = LCLoanCentroids;           * centroid table            **;
%let synData      = LCLoanSynthetic;           * synthetic data            **;
                                               * interval variables        **;
%let intVars      = InterestRate  Installment LogAnnualInc   DebtIncRatio                                   
                    CreditLineAge RevBalance  RevUtilization FICOScore;    
                                               * nominal variables         **;                      
%let nomVars      = CreditPolicy  Purpose PublicRecord Default  
                    Delinquencies2yrs Inquiries6mnths  Age Race Gender;  


*****************************************************************************; 
**   Create synthetic data using the NON-EVENT records                     **; 
*****************************************************************************; 
proc tabulargan        data=&WBDataLib..&inputdata. seed=123 numSamples=600000 useGPU;
      input            &intVars.  /level=interval;
      input            &nomVars.  /level=nominal;
      gmm              alpha=1 maxClusters=10 seed=42 VB(maxVbIter=30);
      aeoptimization   ADAM LearningRate=0.0001 numEpochs=100;
      ganoptimization  ADAM(beta1=0.55 beta2=0.95)  numEpochs=100;
      train            embeddingDim=22 miniBatchSize=50 useOrigLevelFreq;
      savestate        rstore=&WBDataLib..&synData.astore;
      output           out=&WBDataLib..&synData._0;
 run;

*****************************************************************************; 
**   Create synthetic data using the EVENT records                         **; 
*****************************************************************************; 
proc tabulargan        data=&WBDataLib..&inputdata1. seed=123 numSamples=400000 useGPU;
      input            &intVars.  /level=interval;
      input            &nomVars.  /level=nominal;
      gmm              alpha=1 maxClusters=10 seed=42 VB(maxVbIter=30);
      aeoptimization   ADAM LearningRate=0.0001 numEpochs=100;
      ganoptimization  ADAM(beta1=0.55 beta2=0.95)  numEpochs=100;
      train            embeddingDim=22 miniBatchSize=50 useOrigLevelFreq;
      savestate        rstore=&WBDataLib..&synData.astore;
      output           out=&WBDataLib..&synData._1;
 run;

*****************************************************************************; 
**   Combine the synthetic non-event and event records into a single table **; 
*****************************************************************************; 
data &WBDataLib..&syndata._OS;
    set &WBDataLib..&synData._0 &WBDataLib..&synData._1;
run;
