# HACKEREARTH: IndiaHacks 2017 - Machine Learning/Predict the Road Sign Here
- **Competition** : [here](https://www.hackerearth.com/challenge/competitive/machine-learning-indiahacks-2017/machine-learning/predict-the-road-sign-1/)

- **Leaderboard** : [here](https://www.hackerearth.com/challenge/competitive/machine-learning-indiahacks-2017/leaderboard/)

- **Data**        : [Download](https://he-s3.s3.amazonaws.com/media/hackathon/hackerearth/predict-the-road-sign/4b699168-4-here_dataset.zip)

```
Opened At : May 30, 12:00 AM IST
Closed At : Jul 03, 12:00 AM IST
Rank      : 136
```

## Problem Statement
> Building digital maps is challenging, and maintaining it up to date in an ever-changing world is even more challenging. Various machine learning techniques helps us to detect road signs and changes in real world, and process it to update maps. The problem presented here is related to a step after detecting a sign on a road. This step has to now identify each road geometry on which this sign is applicable. While sounds like a simple problem, signs in junctions makes this more challenging. For example, given a sign detected on a road from a 4-camera setting on vehicle, the closest sighting of the sign may be in the right facing camera, with a sharp sign angle with respect to the direction of the car on which cameras set is mounted. Next step for updating map using this sign is to identify the exact road on which this sign is to be placed or applied. On a + junction, when a sign is detected on the right camera, its hard now to tell if this sign is for the straight road, or for the right-side road, unless you consider parameters like sign bounding box aspect ratio. For example, a sign detected from Front camera will have a natural aspect ratio of the sign when it is actually facing front of the car, however when same sign is detected on a right-side camera with a sharp angle from front, sign bounding box gets skewed, giving a hint that although its detected in right, it’s still facing the front of the car. Dataset provided here has details on camera sign was detected, Angle of sign with respect to front in degrees, Sign's reported bounding box aspect ratio (width/height), Sign Width and Height, and the target feature Sign Facing, which is where the sign is actually facing. Goal here is to predict where the sign is actually facing with respect to the vehicle, given above set of inputs.

## Data Information
> There are files given: train, test and submission. Your submission file must adhere to format specified in the given submission file. Following is the description of variables given:

|Variable|Description|
|--------|:----------|
|ID|a unique identifier for each record in dataset|
|DetectedCamera|imagine a car, which is fitted with 4 cameras on top, one each facing front, right, rear and left. Each cameras clicks pictures on every few meters as car moves. DetectedCamera value tells you on which camera image a road sign was observed/found, by an image detection software|
|AngleOfSign|values are in degrees ranging from 0 to 360 in clockwise direction from the front of car, indicates the angle from the front of the car to the direction in which the sign is detected|
|SignWidth|width of the sign bounding box in the image in pixels|
|SignHeight|height of the sign bounding box in the image in pixels|
|SignAspectRatio|this is the width/height ratio of the sign bounding box, derived from SignWidth/SignHeight. Can provide an indication that sign is facing camera or not. A sign facing the driver, detected on an image captured from almost 80 degrees from front (on right camera), will have a bounding box that is skewed from its original aspect ratio. If its facing the right camera, it will have nearly original aspect ratio of the sign.|
|SignFacing|Target)	For the above inputs, where the sign is actually facing is captured here, from manually reviewed sign facing records|

## Evaluation Metric
> Submissions will be evaluated based on multilogloss score. However, the leaderboard score will be shown as: LB score = (100 - multilogloss score).
>> In case your logloss score exceeds 100, you will get 0 score.
