# loaded train and test
# Subsetted User_ID and Product_ID
# Divided train data into
# 	- local_train
# 	- local_test
# Built following models on local_train and evaluated on local_test
# 	- gbm_1
# 	- gbm_2
# 	- deep_learning_1
# 	- deep_learning_2
# 	- deep_learning_3
# Finally ensembled all 5 models to get best output
# 	- (0.3 * deep_learning_1) + (0.15 * deep_learning_2) + (0.25 * deep_learning_3) + (0.1 * gbm_1) + (0.2 * gbm_2)

# Packages used:
# 	- h2o (for modelling tasks)
# 	- data.table (for data munging tasks)

# # path
setwd('C:\\Users\\ka294056\\Desktop\\Analytics Vidhya\\Black Friday (Practice Problem)')

# # load libraries
library(h2o)
library(data.table)

# # load functions
source('https://raw.githubusercontent.com/kartheekpnsn/machine-learning-codes/master/R/functions.R')
source('https://raw.githubusercontent.com/kartheekpnsn/machine-learning-codes/master/R/xgb_tune.R')

# # read files
train = fread("input-data\\train.csv")
test = fread("input-data\\test.csv")

# # check data
dim(train)
dim(test)
train
test

# # format data
format_data = function(data, test = FALSE) {
	#Converting all columns to factors
	if(test) {
		selCols = names(data)
		data = data[, (selCols) := lapply(.SD, as.factor), .SDcols = selCols]
	} else {
		selCols = names(data)[1:11]
		data = data[, (selCols) := lapply(.SD, as.factor), .SDcols = selCols]
	}
	return(data)
}

train = format_data(copy(train))
test = format_data(copy(test), test = FALSE)

independent_cols = c('User_ID', 'Product_ID')
dependent_col = c('Purchase')

# train = train[, c(independent_cols, dependent_col), with = F]
# test = test[, independent_cols, with = F]

# # ML Model # #
# X = train[, independent_cols, with = F]
# Y = train[[dependent_col]]
# index = dataSplit(Y, regression = T)
# X_train = X[index, ]
# Y_train = Y[index]
# X_test = X[-index, ]
# Y_test = Y[-index]
# xgb_fit = xgb_train(X = X_train, Y = Y_train, X_test = X_test, Y_test = Y_test, regression = TRUE,
# 						hyper_params = list(nrounds = 500, eta = 0.05), cv = FALSE)

# # H2O: ML Model # #
	h2o.init(nthreads = -1, max_mem_size = '8G')
	
	index = dataSplit(train[[dependent_col]], regression = T)

	# Converting to H2o Data frame & splitting
	h2o_train = as.h2o(train[index, c(independent_cols, dependent_col), with = FALSE])
	h2o_test = as.h2o(train[-index, c(independent_cols, dependent_col), with = FALSE])
	h2o_ftest = as.h2o(test[, independent_cols, with = FALSE])

	# GBM - Model: 1
	gbmF_model_1 = h2o.gbm(x = independent_cols, y = dependent_col,
								training_frame = h2o_train ,
								validation_frame = h2o_test ,
								max_depth = 3,
								distribution = "gaussian",
								ntrees = 500,
								learn_rate = 0.05,
								nbins_cats = 5891
					)

	# GBM - Model: 2
	gbmF_model_2 = h2o.gbm(x = independent_cols, y = dependent_col,
								training_frame = h2o_train ,
								validation_frame = h2o_test ,
								max_depth = 3,
								distribution = "gaussian",
								ntrees = 430,
								learn_rate = 0.04,
								nbins_cats = 5891)

	# Deep learning - Model: 1
	dl_model_1 = h2o.deeplearning(x = independent_cols,	y = dependent_col,
										training_frame = h2o_train ,
										validation_frame = h2o_test ,
										activation = "Rectifier",
										hidden = 6,
										epochs = 60,
										adaptive_rate = F)

	dl_model_2 = h2o.deeplearning(x = independent_cols,	y = dependent_col,
										training_frame = h2o_train ,
										validation_frame = h2o_test ,
										activation = "Rectifier",
										hidden = 60,
										epochs = 40,
										adaptive_rate = F)


	dl_model_3 = h2o.deeplearning(x = independent_cols,	y = dependent_col,
										training_frame = h2o_train ,
										validation_frame = h2o_test ,
										activation = "Rectifier",
										hidden = 6,
										epochs = 120,
										adaptive_rate = F)

# # Model Validation
	print('==> GBM Model 1')
	h2o.performance(gbmF_model_1, valid = FALSE)
	h2o.performance(gbmF_model_1, valid = TRUE)
	print('<==')

	print('==> GBM Model 2')
	h2o.performance(gbmF_model_2, valid = FALSE)
	h2o.performance(gbmF_model_2, valid = TRUE)
	print('<==')

	print('==> Deep learning Model 1')
	h2o.performance(dl_model_1, valid = FALSE)
	h2o.performance(dl_model_1, valid = TRUE)
	print('<==')

	print('==> Deep learning Model 2')
	h2o.performance(dl_model_2, valid = FALSE)
	h2o.performance(dl_model_2, valid = TRUE)
	print('<==')

	print('==> Deep learning Model 3')
	h2o.performance(dl_model_3, valid = FALSE)
	h2o.performance(dl_model_3, valid = TRUE)
	print('<==')

	print('==> Ensemble Model')
	gbm1_test = h2o.predict(gbmF_model_1, h2o_test)$predict
	gbm2_test = h2o.predict(gbmF_model_2, h2o_test)$predict
	dl1_test = h2o.predict(dl_model_1, h2o_test)$predict
	dl2_test = h2o.predict(dl_model_2, h2o_test)$predict
	dl3_test = h2o.predict(dl_model_3, h2o_test)$predict

	gbm1_test = ifelse(gbm1_test < 0, 0, gbm1_test)
	gbm2_test = ifelse(gbm2_test < 0, 0, gbm2_test)
	dl1_test = ifelse(dl1_test < 0, 0, dl1_test)
	dl2_test = ifelse(dl2_test < 0, 0, dl2_test)
	dl3_test = ifelse(dl3_test < 0, 0, dl3_test)

	# ensemble = (0.44 * dl1_test) + (0.23 * gbm1_test) + (0.33 * gbm2_test)
	ensemble = (0.3 * dl1_test) + (0.15 * dl2_test) + (0.25 * dl3_test) + (0.1 * gbm1_test) + (0.2 * gbm2_test)
	performance_measure(predicted = ensemble, actual = train[-index, dependent_col], regression = TRUE)


# # Final Submission
	# Making the predictions
	gbm1_ftest = h2o.predict(gbmF_model_1, h2o_ftest)$predict
	gbm2_ftest = h2o.predict(gbmF_model_2, h2o_ftest)$predict
	dl1_ftest = h2o.predict(dl_model_1, h2o_ftest)$predict
	dl2_ftest = h2o.predict(dl_model_2, h2o_ftest)$predict
	dl3_ftest = h2o.predict(dl_model_3, h2o_ftest)$predict

	gbm1_ftest = ifelse(gbm1_ftest < 0, 0, gbm1_ftest)
	gbm2_ftest = ifelse(gbm2_ftest < 0, 0, gbm2_ftest)
	dl1_ftest = ifelse(dl1_ftest < 0, 0, dl1_ftest)
	dl2_ftest = ifelse(dl2_ftest < 0, 0, dl2_ftest)
	dl3_ftest = ifelse(dl3_ftest < 0, 0, dl3_ftest)

	# # Used ensemble of 2 GBM, 3 DL
	# RMSE: 2462.42958
	# ensemble = as.numeric(as.vector((0.44 * dl1_ftest) + (0.23 * gbm1_ftest) + (0.33 * gbm2_ftest)))
	ensemble = as.numeric(as.vector((0.3 * dl1_ftest) + (0.15 * dl2_ftest) + (0.25 * dl3_ftest) + (0.1 * gbm1_ftest) + (0.2 * gbm2_ftest)))
	write.csv(cbind(test[, .(User_ID, Product_ID)], Purchase = ensemble), 'submission\\av_submission_1.csv', row.names = FALSE)
