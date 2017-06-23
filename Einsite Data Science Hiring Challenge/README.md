# HACKEREARTH: Einsite Data Science Hiring Challenge - The Cab Service
- **Competition** : [here](https://www.hackerearth.com/challenge/hiring/einsite-data-science-hiring-challenge/)

- **Leaderboard** : [here](https://www.hackerearth.com/challenge/hiring/einsite-data-science-hiring-challenge/leaderboard/)

- **Data**        : [Download](https://s3-ap-southeast-1.amazonaws.com/he-public-data/cabbie_datafa2fec8.zip)

```
Opened At : MAY 12, 2017, 11:00 PM IST
Closed At : MAY 29, 2017, 11:00 PM IST
Duration  : 17 DAYS
Rank      : 77
```

## Problem Statement
> Cabbie Travels, a cab service company of a major city wants to leverage machine learning to improve its business. Precisely, the company wants to understand the trip fares so that they can come up with necessary marketing offers to gain more customers. The provided dataset contains information on trips taken by cabbie cabs in last couple of years. In this challenge, you will help this company to predict the trip fare amount.

## Data Information
> There are files given: train, test and submission. Your submission file must adhere to format specified in the given submission file. This train data set comprises of information captured between January 2015 to April 2016. The test data set consists of trip information from May 2016 to June 2016. Following is the description of variables given:

|Variable|Description|
| ------------- |:-------------|
|Variable|Description|
|Vendor_ID|Technology service vendor associated with cab company|
|New_User|If a new user is taking the ride|
|toll_price|toll tax amount|
|tip_amount|tip given to driver (if any)|
|tax|applicable		tax
|pickup_timestamp|time at which the ride started|
|dropoff_timestamp|time at which ride ended|
|passenger_count|number of passenger during the ride|
|pickup_longitude|pickup location longitude data|
|pickup_latitude|pickup location latitude data|
|rate_category|category assigned to different rates at which a customer is charged|
|store_and_fwd|if driver stored the data offline and later forwarded|
|dropoff_longitude|drop off longitude data|
|dropoff_latitude|drop off latitude data|
|payment_type|payment mode(CRD = Credit Card, CSH - Cash, DIS - dispute, NOC - No Charge, UNK - Unknown)|
|surcharge|surchage applicable on the trip|
|fare_amount|trip fare (to be predicted)|

## Evaluation Metric
> The formula used to evaluate your submission is: **(100 - MAE)**.

>> *If your MAE exceeds 100, you will get 1 as score (which is lowest).*

> **Public - Private leaderboard:** 40:60 split.
