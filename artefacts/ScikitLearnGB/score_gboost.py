import joblib
import numpy as np
import pandas as pd
import settings

pkl_file_name = "scikit_pipeline_gb.pkl"

def score_method(Customer_Value, Age, Home_Flag, Homeval,
       Inc, Pr, Activity_Status, AvgSale3Yr, AvgSaleLife,
       AvgSale3Yr_DP, LastProdAmt, CntPur3Yr, CntPurLife,
       CntPur3Yr_DP, CntPurLife_DP, CntTotPromo, MnthsLastPur,
       Cnt1Yr_DP, CustTenure):
    "Output: P_Status0, P_Status1"

    ## Load pickled pipeline
    try:
        dm_model
    except NameError:
        dm_model = joblib.load(settings.pickle_path+'/'+pkl_file_name)

    # Create single row dataframe
    bank = pd.DataFrame([[Customer_Value, Age, Home_Flag, Homeval,
       Inc, Pr, Activity_Status, AvgSale3Yr, AvgSaleLife,
       AvgSale3Yr_DP, LastProdAmt, CntPur3Yr, CntPurLife,
       CntPur3Yr_DP, CntPurLife_DP, CntTotPromo, MnthsLastPur,
       Cnt1Yr_DP, CustTenure]],
             columns=['Customer_Value', 'Age', 'Home_Flag', 'Homeval',
       'Inc', 'Pr', 'Activity_Status', 'AvgSale3Yr', 'AvgSaleLife',
       'AvgSale3Yr_DP', 'LastProdAmt', 'CntPur3Yr', 'CntPurLife',
       'CntPur3Yr_DP', 'CntPurLife_DP', 'CntTotPromo', 'MnthsLastPur',
       'Cnt1Yr_DP', 'CustTenure'])
    
    # Selecting only numeric columns
    numeric_cols = ['Age', 'Home_Flag', 'Homeval',
       'Inc', 'Pr', 'AvgSale3Yr', 'AvgSaleLife',
       'AvgSale3Yr_DP', 'LastProdAmt', 'CntPur3Yr', 'CntPurLife',
       'CntPur3Yr_DP', 'CntPurLife_DP', 'CntTotPromo', 'MnthsLastPur',
       'Cnt1Yr_DP', 'CustTenure']
    # Select categorical columns excluding 'Customer_Value' and 'Activity_Status'
    categorical_cols = ['Customer_Value','Activity_Status']

    # Calculate mean of numeric columns
    mean_values = bank[numeric_cols].mean()

    # Fill missing values in numeric columns with their respective means
    bank[numeric_cols] = bank[numeric_cols].fillna(mean_values)

    # Mapping for 'Activity_Status' and 'Customer_Value'
    label_encoding = {
        'Activity_Status': {'High': 0, 'Average': 1, 'Low': 2},
        'Customer_Value': {'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4}
    }

    # Apply mapping
    for col, mapping in label_encoding.items():
        bank[col] = bank[col].map(mapping).astype("int64")

    ## Generate predictions
    rec_pred_prob = dm_model.predict_proba(bank)

    return float(rec_pred_prob[0][0]), float(rec_pred_prob[0][1])
