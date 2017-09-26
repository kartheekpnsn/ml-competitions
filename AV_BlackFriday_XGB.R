# # path
setwd('C:\\Users\\ka294056\\Desktop\\Analytics Vidhya\\Black Friday (Practice Problem)')

# # load libraries
library(xgboost)
library(data.table)
library(dummies)
library(scales)
library(caret)

# # load functions
source('https://raw.githubusercontent.com/kartheekpnsn/machine-learning-codes/master/R/functions.R')
source('https://raw.githubusercontent.com/kartheekpnsn/machine-learning-codes/master/R/xgb_tune.R')

# # read files
train = fread("input-data//train.csv")
test = fread("input-data//test.csv")

engineerFeatures = function(data, test = FALSE, train = NULL) {
	if(!test) {
		data = data[!Product_Category_1 %in% c(19, 20)] # as they are not present in test data
	}
	data = dummy.data.frame(data, names = c("City_Category"), sep = "_")
	setDT(data)

	# # modify age
	data[Age == '0-17', Age := '15']
	data[Age == '18-25', Age := '21']
	data[Age == '26-35', Age := '30']
	data[Age == '36-45', Age := '40']
	data[Age == '46-50', Age := '48']
	data[Age == '51-55', Age := '53']
	data[Age == '55+', Age := '60']
	data[, Age := as.integer(Age)]

	# # stay in current city years
	data[Stay_In_Current_City_Years == '4+', Stay_In_Current_City_Years := '4']
	data[, Stay_In_Current_City_Years := as.integer(Stay_In_Current_City_Years)]

	# # gender
	data[, Gender := ifelse(Gender == 'F', 1, 0)]

	# # summary features
	if(!test) {
		data[, user_count := .N, User_ID]
		data[, product_mean := mean(Purchase), Product_ID]
		data[, user_high := ifelse(Purchase > product_mean, 1, 0)]
		data[, user_high := mean(user_high), User_ID]
	} else {
		train[, user_count := .N, User_ID]
		train[, product_mean := mean(Purchase, na.rm = TRUE), Product_ID]
		train[, user_high := ifelse(Purchase > product_mean, 1, 0)]
		train[, user_high := mean(user_high), User_ID]
		data = merge(data, unique(train[, .(User_ID, user_count)]), by = 'User_ID', all.x = TRUE)
		data = merge(data, unique(train[, .(Product_ID, product_mean)]), by = 'Product_ID', all.x = TRUE)
		data = merge(data, unique(train[, .(User_ID, user_high)]), by = 'User_ID', all.x = TRUE)
		
		data[is.na(user_count), user_count := 0]
		data[is.na(product_mean), product_mean := mean(train[, Purchase], na.rm = TRUE)]
		data[is.na(user_high), user_high := 0]
	}
	return(data)
}


X_train = engineerFeatures(copy(train), test = FALSE, train = NULL)
X_test = engineerFeatures(copy(test), test = TRUE, train = copy(train))

# # prepare submission
submission = X_test[, .(User_ID, Product_ID)]

# # divide into X and Y
Y = X_train[, Purchase]
X_train = X_train[, !c('Purchase', 'Product_ID'), with = FALSE]
X_test = X_test[, names(X_train), with = FALSE]

# # fit model
xgb_fit = xgboost(data = as.matrix(X_train), label = Y,
					objective = 'reg:linear', nrounds = 500, max_depth = 10, eta = 0.1,
					colsample_bytree = 0.5, seed = 235, metric = 'rmse', importance = 1,
					missing = 'NA', print_every_n = 20)

xgb_pred = predict(xgb_fit, as.matrix(X_test), outputmargin = TRUE, missing = 'NA')

# # write the submission
submission[, Purchase := xgb_pred]
submission[Purchase > 23961, Purchase := 23961] # train max purchase value
submission[Purchase < 185, Purchase := 185] # train min purchase value
submission[, Purchase := squish(Purchase, round(quantile(Purchase, c(0.005, 0.995))))] # squish the extremes

# RMSE:	2453.79795
write.csv(submission, "submission//xgb_submission.csv", row.names = FALSE)