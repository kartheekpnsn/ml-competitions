# HACKEREARTH: #6 - Predict the damange to the building
- **Competition** : [here](https://www.hackerearth.com/challenge/competitive/machine-learning-challenge-6-1/machine-learning/predict-the-energy-used-612632a9-3f496e7f/)

- **Leaderboard** : [here](https://www.hackerearth.com/challenge/competitive/machine-learning-challenge-6-1/leaderboard/)

- **Data**        : [Download](https://he-s3.s3.amazonaws.com/media/hackathon/machine-learning-challenge-6-1/predict-the-energy-used-612632a9-3f496e7f/a490e594-6-Dataset.zip)

```
Opened At : Jun 16, 2018, 09:00 PM IST
Closed At : Aug 15, 2018, 11:55 PM IST
Rank      : XX
```

## Problem Statement
> Determining the degree of damage that is done to buildings post an earthquake can help identify safe and unsafe buildings, thus avoiding death and injuries resulting from aftershocks.  Leveraging the power of machine learning is one viable option that can potentially prevent massive loss of lives while simultaneously making rescue efforts easy and efficient. In this challenge we provide you with the before and after details of nearly one million buildings after an earthquake. The damage to a building is categorized in five grades. Each grade depicts the extent of damage done to a building post an earthquake. Given building details, your task is to build a model that can predict the extent of damage that has been done to a building after an earthquake.

## Data Description:
> You’re give four files: train.csv, test.csv, Building_Ownership_Use.csv and Building_Structure.csv.


#### Details of the files are as follows: 

#### train.csv : 

|Varaible| Descrition|
|--------|-----------|
|area_assesed|Indicates the nature of the damage assessment in terms of the areas of the building that were assessed|
|building_id|A unique ID that identifies every individual building|
|damage_grade|Damage grade assigned to the building after assessment (Target Variable)|
|district_id|District where the building is located|
|has_geotechnical_risk|Indicates if building has geotechnical risks|
|has_geotechnical_risk_fault_crack|Indicates if building has geotechnical risks related to fault cracking|
|has_geotechnical_risk_flood|Indicates if building has geotechnical risks related to flood|
|has_geotechnical_risk_land_settlement|Indicates if building has geotechnical risks related to land settlement|
|has_geotechnical_risk_landslide|Indicates if building has geotechnical risks related to landslide|
|has_geotechnical_risk_liquefaction|Indicates if building has geotechnical risks related to liquefaction|
|has_geotechnical_risk_other|Indicates if building has any other  geotechnical risks|
|has_geotechnical_risk_rock_fall|Indicates if building has geotechnical risks related to rock fall|
|has_repair_started|Indicates if the repair work had started|
|vdcmun_id|Municipality where the building is located|

#### test.csv

Contains the same variables as the train.csv except the 'damage_grade' which is the target variable/ varaible to be predicted.

#### Building_Ownership_Use.csv: 

|Varaible|Description|
|--------|-----------|
|building_id|A unique ID that identifies every individual building|
|district_id|District where the building is located|
|vdcmun_id|Municipality where the building is located|
|ward_id|Ward Number in which the building is located|
|legal_ownership_status|Legal ownership status of the land in which the building was built|
|count_families|Number of families in the building|
|has_secondary_use|indicates if the building is used for any secondary purpose|
|has_secondary_use_agriculture|indicates if the building is secondarily used for agricultural purpose|
|has_secondary_use_hotel|indicates if the building is secondarily used as hotel|
|has_secondary_use_rental|indicates if the building is secondarily used for rental purpose|
|has_secondary_use_institution|indicates if the building is secondarily used for institutional purpose|
|has_secondary_use_school|indicates if the building is secondarily used as school|
|has_secondary_use_industry|indicates if the building is secondarily used for industrial purpose|
|has_secondary_use_health_post|indicates if the building is secondarily used as health post|
|has_secondary_use_gov_office|indicates if the building is secondarily used as government office|
|has_secondary_use_use_police|indicates if the building is secondarily used as police station|
|has_secondary_use_other|indicates if the building is secondarily used for other purpose|


#### Building_Structure.csv

|Variable|Description|
|--------|-----------|
|building_id|A unique ID that identifies every individual building|
|district_id|District where the building is located|
|vdcmun_id|Municipality where the building is located|
|ward_id|Ward Number in which the building is located|
|count_floors_pre_eq|Number of floors that the building had before the earthquake|
|count_floors_post_eq|Number of floors that the building had after the earthquake|
|age_building|Age of the building (in years)|
|plinth_area_sq_ft|Plinth area of the building (in square feet)|
|height_ft_pre_eq|Height of the building before the earthquake (in feet)|
|height_ft_post_eq|Height of the building after the earthquake (in feet)|
|land_surface_condition|Surface condition of the land in which the building is built	|
|foundation_type|Type of foundation used in the building|
|roof_type|Type of roof used in the building|
|ground_floor_type|Ground floor type|
|other_floor_type|Type of construction used in other floors (except ground floor and roof)|
|position|Position of the building|
|plan_configuration|Building plan configuration|
|has_superstructure_adobe_mud|indicates if the superstructure of the building is made of Adobe/Mud|
|has_superstructure_mud_mortar_stone|indicates if the superstructure of the building is made of Mud Mortar - Stone|
|has_superstructure_stone_flag| indicates if the superstructure of the building is made of Stone|
|has_superstructure_mud_mortar_brick|indicates if the superstructure of the building is made of Cement Mortar - Stone|
|has_superstructure_cement_mortar_brick|indicates if the superstructure of the building is made of Mud Mortar - Brick|
|has_superstructure_timber|indicates if the superstructure of the building is made of Timber|
|has_superstructure_bamboo|indicates if the superstructure of the building is made of Bamboo|
|has_superstructure_rc_non_engineered|indicates if the superstructure of the building is made of RC (Non Engineered)|
|has_superstructure_rc_engineered|indicates if the superstructure of the building is made of RC (Engineered)|
|has_superstructure_other| indicates if the superstructure of the building is made of any other material|
|condition_post_eq|Actual contition of the building after the earthquake|

## Evaluation Metric
> The submissions will be evaluated based on F1 Score with ‘weighted’ average.
