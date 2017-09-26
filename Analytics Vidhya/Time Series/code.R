# # set path
setwd('F:\\Kartheek\\Data\\ml-competitions\\Analytics Vidhya\\Time Series (Practice Problem)')
# setwd('/home/ec2-user/kartheek/ML_3')

# # load libraries
library(data.table)
library(ggplot2)
library(lubridate)

# # load files
train = fread('input-data//Train_SU63ISt.csv')
test = fread('input-data//Test_0qrQsBZ.csv')

# # load functions
source('https://raw.githubusercontent.com/kartheekpnsn/machine-learning-codes/master/R/functions.R')
source('https://raw.githubusercontent.com/kartheekpnsn/machine-learning-codes/master/R/xgb_tune.R')

# # check basics
print(dim(train))
print(train)
print(dim(test))
print(test)

# # engineer features
engineer_features = function(data, test = FALSE, train = NULL) {
	cat('==> 1) Sorting dates\n')
	# # sort by dates
	datetime = strptime(data[, Datetime], '%d-%m-%Y %H:%M')
	order_datetime = order(datetime)
	data = data[order_datetime, ]
	datetime = datetime[order_datetime]
	cat('Done <==\n')

	cat('==> 2) Feature engineering\n')
	# # features
	data[, Year := as.numeric(format(datetime, '%Y'))]
	data[, Hour := as.numeric(format(datetime, "%H"))]
	data[, WeekDay := as.numeric(factor(weekdays(datetime)))]
	data[, day := as.numeric(format(datetime, '%d'))]
	data[, month := as.numeric(format(datetime, '%m'))]
	data[, week_of_month := as.numeric(ifelse(ceiling(mday(datetime) / 7) == 5, 4, ceiling(mday(datetime) / 7)))]
	data[, weekend_flag := as.numeric(ifelse(WeekDay %in% c('Saturday', 'Sunday'), 1, 0))]
	if(!test) {
		data[, DayCount := as.numeric(difftime(datetime, min(datetime), units = c('days')))]
	} else {
		datetime_train = strptime(train[, Datetime], '%d-%m-%Y %H:%M')
		order_datetime_train = order(datetime)
		datetime_train = datetime_train[order_datetime_train]
		data[, DayCount := as.numeric(difftime(datetime, min(datetime_train), units = c('days')))]
	}
	data[, week_of_year := ifelse(months(datetime) == "December", 
		as.numeric(format(datetime-4, "%U"))+1, 
		as.numeric(format(datetime+3, "%U")))]
	cat('Done <==\n')

	if(!test) {
		data = data[, c(setdiff(colnames(data), 'Count'), 'Count'), with = FALSE]
	}

	return(data)
}

# # engineer features
test = engineer_features(data = copy(test), test = TRUE, train = copy(train))
train = engineer_features(data = copy(train))

# # plot and check the trend
p1 = ggplot() + 
		geom_line(data = train, aes(x = ID, y = Count, color = 'original-value')) +
		geom_line(data = train, aes(x = ID, y = rep(mean(Count), nrow(train)), color = 'mean-value'))


# # useless columns
drop_cols = c('Datetime', 'ID', 'week_of_year', 'month', 'day')

# # machine learning models
# 1) XGBOOST
xgb_fit = xgb_train(X = train[, !c('Count', drop_cols), with = FALSE], 
						Y = train[, Count], cv = TRUE, regression = TRUE,
						hyper_params = list(eta = 0.02, nrounds = 1000, max_depth = 8,
							colsample_bytree = 0.8, subsample = 0.9, min_child_weight = 8))

# 2) Linear Regression - for 2nd half
lm_data = train[16000:nrow(train), ]
lm_data = drop_const_cols(lm_data)
index = dataSplit(lm_data[, Count], regression = TRUE)
lm_fit = lm(Count ~ ., data = lm_data[index, !drop_cols, with = FALSE])
performance_measure(predicted = predict(lm_fit, lm_data[-index, ]), actual = lm_data[-index, Count], regression = TRUE)


# # predict on test set
xgb_pred = xgb_predict(xgb_fit$fit, test[, !drop_cols, with = FALSE])
test[, Count := xgb_pred]
setorder(test, ID)

# # plot to check the predicted trend
# # plot and check the trend
p2 = ggplot() + 
		geom_line(data = test, aes(x = ID, y = Count, color = 'original-value')) +
		geom_line(data = test, aes(x = ID, y = rep(mean(Count), nrow(test)), color = 'mean-value'))

# # submission
write.csv(test[, .(ID, Count)], 'submissions//xgb_lm_submission.csv', row.names = FALSE)