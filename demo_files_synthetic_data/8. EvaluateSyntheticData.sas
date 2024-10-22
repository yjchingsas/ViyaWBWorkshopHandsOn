**************************************************;
**                                              **;
**  8a. EVALUATE THE SYNTHETIC DATA             **;
**                                              **;
**      Distribution Analysis                   **;
**                                              **;
**************************************************;
************************************************************************;
* system options for debugging purposes                                *;
************************************************************************;
* options source source2 mprint mlogic symbolgen;
* options nosource nosource2 nomprint nomlogic nosymbolgen;* for debugging purposes *;
OPTIONS FMTSEARCH=(myfolder);

************************************************************************;
** Post Processing                                                    **;
**   combine the seed data and the synthetic data                     **;
**   create comparison charts                                         **;
************************************************************************;

******************************************************************************************;
* Macro Variables for input, output data and files                                       *;
******************************************************************************************;
%let WBDataLib = LCLD;                    * libref for workbench data                    *;
%let WBTempLib = WORK;                    * libref for temporary tables                  *;
%let trainData = LCLoanData;              * original training data                       *;
%let synData   = LCLoanSynthetic_OS;      * generated synthetic data                     *;
%let synTrainSub = LCLD_OSSynSub;         * synthetic data where records with negative values were removed         *;
%let synTrainAll = LCLD_OSSynAll;         * all synthetic records are kept and negative values replaced w the mean *;

************************************************************************;
**  create a data set that combines the original training data        **:
**  with the newly created synthetic data.  assess the distributions  **;
**  of both. use variable names vs. labels due to visability issues   **;
************************************************************************;
data &WBTempLib..compare;
  set &WBDataLib..&trainData. (in=Training) &WBDataLib..&synData. (in=Synthetic);
  if synthetic then source = 'Synthetic';
  if training then source='Training';
  label CreditLineAge =' '
        CreditPolicy = ' '
        DebtIncRatio =' '
        Delinquencies2Yrs =' '
        Default = ' '
        FICOScore = ' '
        Inquiries6Mnths =' '
        InterestRate =' '
        Installment =' '
        LogAnnualInc =' ' 
        PublicRecord =' '
        Purpose =' '        
        RevBalance =' '
        RevUtilization =' '        
      ;
run;

*************************************************;
**   review the proc CONTENTS                  **;
**              proc MEANS                     **;
**              10 observations                **; 
*************************************************;
%let inputStats = min max mean std n nmiss;
%contMeansPrint10(&WBTempLib..compare, &inputStats.);

************************************************************************;
**   assign endpoints based on the mix/max values                     **;
************************************************************************;
**   review var distributions by the target                           **;
************************************************************************;
%let classVar=source;
%let clAgeHistEndpoints=    -4500 to 20000 by 500;
%let dtiHistEndpoints=        -14 to 40 by 4;
%let delinqHistEndpoints=       0 to 14      by 1;
%let ficoHistEndpoints=       550 to 900 by 25;
%let inqEndpoints=              0 to 35      by 5;
%let instHistEndpoints=      -200 to 1400 by 100;
%let intHistEndpoints=          0 to .30 by .02;
%let nlogHistEndpoints=       6.0 to 16 by .5;
%let revbalHistEndpoints=  -65000 to 1208000 by 1000;
%let revutilHistEndpoints=    -65 to 165 by 25;
%uni(&wbtemplib..compare, &classVar.);


************************************************************************;
**   remove records with infeasible values                            **;
************************************************************************;
data &WBDataLib..&synTrainsub.;
  set &WBDataLib..&synData.;
  if CreditLineAge     >= 0;
  if CreditPolicy      >= 0;
  if DebtIncRatio      >= 0;
  if Delinquencies2Yrs >= 0;
  if FICOScore         >= 0;
  if Inquiries6Mnths   >= 0;
  if Installment       >= 0;
  if InterestRate      >= 0;
  if LogAnnualInc      >= 0;
  if RevBalance        >= 0;
  if RevUtilization    >= 0;
run; 


*************************************************;
**                                             **;
**        8b. CORRELATION ANALYSIS             **;
**                                             **;
*************************************************;

/********************************************************** */
/* Post Processing                                          */
/*   combine the seed data and the synthetic data           */
/*   create comparison charts                               */
/************************************************************/

******************************************************************************************;
* Macro Variables for input, output data and files                                       *;
******************************************************************************************;
%let WBDataLib = LCLD;                    * libref for workbench data                   **;
%let WBTempLib = WORK;                    * libref for temporary tables                 **;
%let trainData = LCLoanData;              * original training data                      **;
%let synData   = LCLoanSynthetic_OS;      * generated synthetic data                    **;
%let trainCorr = LCLD_TrainCorr;          * synthetic data correlation info             **;
%let synCorr   = LCLD_SynCorr;            * training data correlation info              **;
%let comboCorr = LCLD_ComboCorr;          * combo of training/syn data correlation info **;
                                                                  * interval variables  **;
%let intVars      = InterestRate  Installment LogAnnualInc   DebtIncRatio                                   
                    CreditLineAge RevBalance  RevUtilization FICOScore;                 **;
                                                                  * nominal variables   **;                      
%let nomVars      = CreditPolicy  Purpose PublicRecord Default  
                    Delinquencies2yrs Inquiries6mnths;                                  **;

proc correlation data=&WBDataLib..&trainData nomiss outp=&WBDataLib..&trainCorr._1;
   var &Intvars;
run;
proc correlation data=&WBDataLib..&synData. nomiss outp=&WBDataLib..&synCorr._1;
   var &Intvars;
run;

data &WBDataLib..&trainCorr.;
  set &WBDataLib..&trainCorr._1;
  if _N_>3;
    drop _TYPE_;
run;

data &WBDataLib..&synCorr.;
  set &WBDataLib..&synCorr._1;
  if _N_>3;
    drop _TYPE_;
run;

********************************************************************;
**  prepare the original training data for display on a heat map  **;
********************************************************************;
data &WBDataLib..&trainCorr._plot;
  keep x y r;
  set &WBDataLib..&trainCorr.;
  array v{*} _numeric_;
  x = _NAME_;
  do i = dim(v) to 1 by -1;
    y = vname(v(i));
    r = v(i);
    /* creates a lower triangular matrix */
    if (i<_n_) then
      r=.;
    output;
  end;
run;


********************************************************************;
**  prepare the synthetic data for display on a heat map          **;
********************************************************************;
data &WBDataLib..&synCorr._plot;
  keep x y r;
  set &WBDataLib..&synCorr.;
  array v{*} _numeric_;
  x = _NAME_;
  do i = dim(v) to 1 by -1;
    y = vname(v(i));
    r = v(i);
    /* creates a lower triangular matrix */
    if (i<_n_) then
      r=.;
    output;
  end;
run;

proc template;
  define statgraph corrHeatmap;
  dynamic _Title;
  begingraph;
  entrytitle _Title;
  rangeattrmap name='map';
  ********************************************************************;
  **  select a series of colors that represent a "diverging" range  **;
  **  of values: stronger on the ends, weaker in the middle.        **;
  **  get ideas from http://colorbrewer.org                         **;
  ********************************************************************;
  range -1 - 1 / rangecolormodel=(cxdeebf7 cx9ecae1 cx3182bd);
      endrangeattrmap;
      rangeattrvar var=r attrvar=r attrmap='map';
      layout overlay /
      xaxisopts=(display=(line ticks tickvalues))
      yaxisopts=(display=(line ticks tickvalues));
      heatmapparm x = x y = y colorresponse = r /
          xbinaxis=false ybinaxis=false
          name = "heatmap" display=all;
          continuouslegend "heatmap" /
          orient = vertical location = outside title="Pearson Correlation";
          endlayout;
    endgraph;
  end;
run;

proc sgrender data=&WBDataLib..&trainCorr._plot template=corrHeatmap;
    dynamic _title="Corr matrix for real data";
run;

proc sgrender data=&WBDataLib..&synCorr._plot template=corrHeatmap;
    dynamic _title="Corr matrix for synthetic data";
run;

data &WBDataLib..&comboCorr._plot;
  length Synthetic_data_flag varchar(*);
  set &WBDataLib..&trainCorr._plot(in=a) &WBDataLib..&synCorr._plot(in=b);
  If b then Synthetic_data_flag="Generated Data"; else Synthetic_data_flag="Original Data";
run;