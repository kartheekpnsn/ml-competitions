# HACKEREARTH: IndiaHacks: Machine Learning - Will Bill solve it?
- **Competition** : [here](https://www.hackerearth.com/challenge/competitive/machine-learning-india-hacks-2016/machine-learning/will-bill-solve-it/)

- **Leaderboard** : [here](https://www.hackerearth.com/challenge/competitive/machine-learning-india-hacks-2016/leaderboard/)

- **Data**        : [Download](https://s3-ap-southeast-1.amazonaws.com/he-public-data/will_bill_solve_it.tar.gz)

```
Opened At : Jan 15, 2016, 06:00 PM IST
Closed At : Jan 25, 2016, 11:00 PM IST
Duration  : 10 days 5h
Rank      : 136
```

## Problem Statement
> HackerEarth is a community of programmers. Thousands of hackers solve problems on HackerEarth everyday to improve their programming skills or win prizes. These hackers can be beginners who are new to programming, or experts who know the solution in a blink. There is a pattern to everything, and this problem is about finding those patterns and problem solving behaviours of the users. Finding these patterns will be of immense help to the problem solvers, as it will allow to suggest relevant problems to solve and offer solution when they seem to be stuck. The opportunities are diverse and you are entitled with the task to predict them. You are given following data of the submissions, problems, and users. Your aim is to predict whether a user will be able to solve a problem or not.

## Data Information
> There are 3 training data files.
>> **submissions.csv**: This is the file containing data of user submissions.

|Variable|Description|
| ------------- |:-------------|
|user_id|the id of the user who made a submission|
|problem_id|the id of the problem that was attempted|
|solved_status|indicates whether the submission was correct (SO : Solved or Correct solution, AT : Attempted or Incorrect Solution )|
|result|result of the code execution, (PAC: Partially Accepted, AC : Accepted, TLE : Time limit exceeded, CE : Compilation Error, RE : Runtime Error, WA : Wrong Answer)|
|language_used|the lang used by user to code the solution|
|execution_time|the execution time of the solution|

**NOTE** : The submissions are chronologically sorted. The difference between solved_status and result is that the value of solved_status depends on what the value of result is. A solution which has the result as AC should have the solved_status as SO, in rest of the cases, solved_status should be AT which means the user attempted the problem but was not finally AC. In special cases such as when the submissions have result as PAC, solved_status can be either of SO or AT depending on the type of problem. For the scope of this ML challenge, you should consider only SO, AC as the ideal/positive solution. If you find any other discrepancies in the data, consider it as noise.

>> **problems.csv**: This is the file containing data of problems.

|Variable|Description|
| ------------- |:-------------|
|user_id|the id of the user who made a submission|
|problem_id|the id of the problem that was attempted|
|solved_status|indicates whether the submission was correct (SO : Solved or Correct solution, AT : Attempted or Incorrect Solution )|
|result|result of the code execution, (PAC: Partially Accepted, AC : Accepted, TLE : Time limit exceeded, CE : Compilation Error, RE : Runtime Error, WA : Wrong Answer)|
|language_used|the lang used by user to code the solution|
|execution_time|the execution time of the solution|

>> **users.csv**: This is the file containing data of the users.
|Variable|Description|
| ------------- |:-------------|
|user_id|the user id|
|skills|all his skills separated by the delimiter '|
|solved_count|number of problems solved by the user|
|attempts|total number of incorrect submissions done by the user|
|user_type|type of user (S - Student, W - Working, NA - No Information Available)|

## Evaluation Metric
 
> Submissions will be evaluated based on accuracy. Score is calculated with the following formula:
>> score = (Number of correct predictions) / Total records
> Your submission will be evaluated only for 50% of the test data while the contest is running. Once the contest is over, your submission will be evaluated against the entire test data and your final score and rank will be updated in the leaderboard.
