setwd('C:\\Users\\ka294056\\Desktop\\Predict Ad Clicks')

# # load libraries
library(data.table)
library(h2o)
library(xgboost)
library(lubridate)

# # function to engineer features
engineer_features = function(data, test = FALSE, train = NULL, label_encode = TRUE) {
	cat('==> Replacing counts in place of siteid, offerid, category, merchant\n')
	# # get counts for below columns # #
	id_cols = c('siteid', 'offerid', 'category', 'merchant')
	cols1 <- c('siteid','offerid','category','merchant')
	for(x in seq(id_cols))
	{
		data[, eval(id_cols[x]) := .N, by = eval(id_cols[x])]
	}
	cat('Done <==\n')

	# # merge dups
	cat('==> Process browserid\n')
	data[, browserid := as.character(browserid)]
	data[browserid %in% c('Firefox', 'Mozilla Firefox', 'Mozilla'), browserid := 'Mozilla']
	data[browserid %in% c('Edge', 'IE', 'InternetExplorer', 'Internet Explorer'), browserid := 'IE']
	data[browserid %in% c('Google Chrome', 'Chrome'), browserid := 'Chrome']
	data[is.na(browserid), browserid := 'Missing']
	data[, browserid := as.factor(browserid)]
	cat('Done <==\n')

	# # missing in devid
	cat('==> Process devid\n')
	data[, devid := as.character(devid)]
	data[is.na(devid), devid := 'dev_missing']
	data[, devid := as.factor(devid)]
	cat('Done <==\n')

	# # get counts for below columns
	cat('==> Getting counts for countrycode, browserid, devid\n')
	cat_cols = c('countrycode', 'browserid', 'devid')
	cat_cols_create = c('countrycode_ct', 'browserid_ct', 'devid_ct')
	for(x in seq(cat_cols))
	{
		data[, eval(cat_cols_create[x]) := .N, by = eval(cat_cols[x])]
	}
	cat('Done <==\n')

	# # handle datetime
	cat('==> Handle datetime\n')
	data[, datetime := as.POSIXct(datetime, format = "%Y-%m-%d %H:%M:%S")]
	data[, weekday := as.integer(as.factor(weekdays(datetime))) - 1]
	data[, hour := hour(datetime)]
	data[, minute := minute(datetime)]
	data[, month := month(datetime)]
	data[, week_of_month := as.integer(ifelse(ceiling(mday(datetime) / 7) == 5, 4, ceiling(mday(datetime) / 7)))]
	data[, weekend_flag := as.integer(ifelse(weekday %in% c('Saturday', 'Sunday'), 1, 0))]

	data[, datetime := NULL]
	cat('Done <==\n')

	# # label encoding
	if(label_encode) {
		data[, countrycode := as.numeric(countrycode) - 1]
		data[, browserid := as.numeric(browserid) - 1]
		data[, devid := as.numeric(devid) - 1]
	}

	return(data)
}

# # read input data
if(!all(c('processed_test.csv', 'processed_train.csv') %in% list.files('input-data'))) {
	train = fread('input-data//train.csv', na.strings = c(" ", "", NA), stringsAsFactors = TRUE)
	test = fread('input-data//test.csv', na.strings = c(" ", "", NA), stringsAsFactors = TRUE)
	sample_submission = fread('input-data//sample_submission.csv', na.strings = c(" ", "", NA), stringsAsFactors = TRUE)

	# # engineer features
	train = engineer_features(copy(train))
	test = engineer_features(copy(test))

	write.csv(train, 'input-data//processed_train.csv', row.names = FALSE)
	write.csv(test, 'input-data//processed_test.csv', row.names = FALSE)
} else {
	train = fread('input-data//processed_train.csv', na.strings = c(' ', '', NA), stringsAsFactors = TRUE)
	test = fread('input-data//processed_test.csv', na.strings = c(' ', '', NA), stringsAsFactors = TRUE)
	sample_submission = fread('input-data//sample_submission.csv', na.strings = c(" ", "", NA), stringsAsFactors = TRUE)
}

# # basic eda
	# # check class
	sapply(train, class)
	sapply(test, class)

	# # check missing
	sapply(train, function(x) (sum(is.na(x))/length(x)))
	sapply(test, function(x) (sum(is.na(x))/length(x)))

# # down sample
down_sample = function(target, perc = 0.25) {
	zero_index = which(target == 0)
	one_index = which(target == 1)
	index = c(sample(zero_index, round(length(zero_index) * perc), replace = FALSE), one_index)
	return(sample(index))
}
down_sample_index = down_sample(train[, click])
train = train[down_sample_index, ]

# # ML Model # #
index = dataSplit(train[, click], split_ratio = c(0.75))
X = train[index$train, !c('click', 'ID'), with = FALSE]
X_test = train[-index$train, !c('click', 'ID'), with = FALSE]
Y = train[index$train, click]
Y_test = train[-index$train, click]

# # label encoding
X[, countrycode := as.numeric(countrycode) - 1]
X[, browserid := as.numeric(browserid) - 1]
X[, devid := as.numeric(devid) - 1]

X_test[, countrycode := as.numeric(countrycode) - 1]
X_test[, browserid := as.numeric(browserid) - 1]
X_test[, devid := as.numeric(devid) - 1]

test[, countrycode := as.numeric(countrycode) - 1]
test[, browserid := as.numeric(browserid) - 1]
test[, devid := as.numeric(devid) - 1]


# # h2o model
h2o.init(nthreads = -1, max_mem_size = '6G')
h2o_train = as.h2o(cbind(X, click = Y))
h2o_test = as.h2o(cbind(X_test, click = Y_test))
h2o_f_test = as.h2o(test)

x = colnames(X)
y = 'click'

rf_fit = h2o.randomForest(x = x, y = y, training_frame = h2o_train, 
							ntrees = 500, validation_frame = h2o_test, seed = 294056)



dtrain = xgb.DMatrix(data = as.matrix(X), label = Y)
dtest = xgb.DMatrix(data = as.matrix(X_test), label = Y_test)
dtest_f = xgb.DMatrix(data = as.matrix(test[, !c('ID'), with = FALSE]))

watchlist = list(train = dtrain, test = dtest)
xgb_fit = xgb.train(data = dtrain, max_depth = 4, eta = 0.1, 
						nround = 50, watchlist = watchlist, nthreads = 2,
						objective = "binary:logistic", eval_metric = 'auc')
xgb_fit2 = xgb.train(data = dtrain, max_depth = 4, eta = 0.1, 
						nround = 50, watchlist = watchlist, 
						objective = "binary:logistic", booster = 'gblinear',
						eval_metric = 'auc', nthreads = 2)

xgb_pred = predict(xgb_fit, dtest_f)

f_sub = data.table(ID = test[, ID], click = xgb_pred)
f_sub = f_sub[match(sample_submission[, ID], f_sub[, ID]), ]
write.csv(f_sub, 'xgb_submission_1.csv', row.names = FALSE)