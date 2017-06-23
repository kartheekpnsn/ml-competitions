# HACKEREARTH: Machine Learning Challenge #2 - Funding Successful Projects
- **Competition** : [here](https://www.hackerearth.com/challenge/competitive/machine-learning-challenge-2/machine-learning/funding-successful-projects/)

- **Leaderboard** : [here](https://www.hackerearth.com/challenge/competitive/machine-learning-challenge-2/leaderboard/)

- **Data**        : [Download](https://he-s3.s3.amazonaws.com/media/hackathon/machine-learning-challenge-2/funding-successful-projects/3149def2-5-datafiles.zip)

```
Opened At : Jun 15, 12:00 AM IST
Closed At : Jun 30, 12:00 AM IST
Rank      : 67
```

## Problem Statement
> Kickstarter is a community of more than 10 million people comprising of creative, tech enthusiasts who help in bringing creative project to life. Till now, more than $3 billion dollars have been contributed by the members in fuelling creative projects. The projects can be literally anything – a device, a game, an app, a film etc. Kickstarter works on all or nothing basis i.e if a project doesn’t meet it goal, the project owner gets nothing. For example: if a projects’s goal is $500. Even if it gets funded till $499, the project won’t be a success. Recently, kickstarter released its public data repository to allow researchers and enthusiasts like us to help them solve a problem. Will a project get fully funded ? In this challenge, you have to predict if a project will get successfully funded or not.

## Data Information
> There are three files given to download: train.csv, test.csv and sample_submission.csv The train data consists of sample projects from the May 2009 to May 2015. The test data consists of projects from June 2015 to March 2017.

|Variable|Description|
|--------|:----------|
|project_id|unique id of project|
|name|name of the project|
|desc|description of project|
|goal|the goal (amount) required for the project|
|keywords|keywords which describe project|
|disable|communication	whether the project authors has disabled communication option with people donating to the project|
|country|country of project author|
|currency|currency in which goal (amount) is required|
|deadline|till this date the goal must be achieved (in unix timeformat)|
|state_changed_at|at this time the project status changed. Status could be successful, failed, suspended, cancelled etc. (in unix timeformat)|
|created_at|at this time the project was posted on the website(in unix timeformat)|
|launched_at|at this time the project went live on the website(in unix timeformat)|
|backers_count|no. of people who backed the project|
|final_status|whether the project got successfully funded (target variable – 1,0)|

## Evaluation Metric
> Submission will be evaluated based on Accuracy metric.
