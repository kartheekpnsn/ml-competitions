# # set path
setwd('F:\\Kartheek\\Data\\ml-competitions\\Analytics Vidhya\\practice-problem-loan-prediction-iii')

# Variable			 -  	Description
# Loan_ID			 -  	Unique Loan ID
# Gender			 -  	Male/ Female
# Married			 -  	Applicant married (Y/N)
# Dependents		 -  	Number of dependents
# Education			 -  	Applicant Education (Graduate/ Under Graduate)
# Self_Employed		 -  	Self employed (Y/N)
# ApplicantIncome	 -  	Applicant income annual
# CoapplicantIncome	 -  	Coapplicant income annual
# LoanAmount		 -  	Loan amount in thousands
# Loan_Amount_Term	 -  	Term of loan in months
# Credit_History	 -  	credit history meets guidelines
# Property_Area		 -  	Urban/ Semi Urban/ Rural
# Loan_Status		 -  	Loan approved (Y/N)


# # libraries
library(data.table)
library(ggplot2)
library(gridExtra)
library(MlBayesOpt)
library(e1071)
library(xgboost)
library(ranger)
library(rpart)
library(rpart.plot)
library(GGally)

# # functions
# source('https://raw.githubusercontent.com/kartheekpnsn/machine-learning-codes/master/R/functions.R')
# source('https://raw.githubusercontent.com/kartheekpnsn/machine-learning-codes/master/R/xgb_tune.R')

# # set seed
set.seed(294056)

# # load data
data = fread('input-data//train_u6lujuX_CVtuZ9i.csv', stringsAsFactors = TRUE)
ftest = fread('input-data//test_Y3wMUE5_7gLdaTN.csv', stringsAsFactors = TRUE)
sample_submission = fread('input-data//Sample_Submission_ZAuTl8O_FK3zQHh.csv')

# # dependent column name
dependent = 'Loan_Status'
setnames(data, dependent, 'target')
data[, target := as.factor(as.numeric(target) - 1)]
colnames(data) = clean_names(colnames(data))
colnames(ftest) = clean_names(colnames(ftest))

# # split into independent and dependent variables
X = data[, !c('target', 'Loan_ID'), with = FALSE]
test_id = ftest[, Loan_ID]
ftest = ftest[, !c('Loan_ID'), with = FALSE]
Y = data[, target]

# # summarize the data
summarize(X)
summarize(ftest)
check_factors(X, ftest)

calc_emi = function(LoanAmount, Loan_Amount_Term) {
	R = 0.09/12
	numerator = (LoanAmount) * R * ((1 + R) ^ (Loan_Amount_Term))
	denominator = (((1 + R) ^ (Loan_Amount_Term)) - 1)
	numerator/denominator
}

# # process the data and engineer features
data_preprocess = function(data, outliers = TRUE, log = TRUE) {
	data[, Married := as.character(Married)]
	data[, Gender := as.character(Gender)]
	data[, Dependents := as.character(Dependents)]
	data[, Self_Employed := as.character(Self_Employed)]

	# treat categorical blanks and missing
	data[Married == '', Married := data[, mode(Married)]]
	data[Gender == '', Gender := data[, mode(Gender)]]
	data[Dependents == '', Dependents := data[, mode(Dependents)]]
	data[Self_Employed == '', Self_Employed := data[, mode(Self_Employed)]]
	data[Dependents == '3+', Dependents := 3]
	data[, Married := as.factor(Married)]
	data[, Gender := as.factor(Gender)]
	data[, Dependents := as.numeric(Dependents)]
	data[, Self_Employed := as.factor(Self_Employed)]

	# treat numerics
	data[, Loan_Amount_Term := Loan_Amount_Term / 12]
	data[is.na(Credit_History), Credit_History := 1]
	data[, Credit_History := as.factor(Credit_History)]
	loan_amount_term = data[, Loan_Amount_Term]
	data[, Loan_Amount_Term := NULL]
	if(outliers) {
		data = remove_outliers(data)
	}
	data[, Loan_Amount_Term := loan_amount_term]
	data[is.na(LoanAmount), LoanAmount := data[, mean(LoanAmount, na.rm = TRUE)]]
	data[is.na(Loan_Amount_Term), Loan_Amount_Term := data[, median(Loan_Amount_Term, na.rm = TRUE)]]

	# # basic engineering
		# total income
		data[, TotalIncome := ApplicantIncome + CoapplicantIncome]
		data = data[, !c('ApplicantIncome', 'CoapplicantIncome'), with = FALSE]
		# % of the persons income as loan
		data[, percent_income := (LoanAmount * 1000) / TotalIncome]
		data[, can_pay_flag := factor(ifelse(percent_income > Loan_Amount_Term, 0, 1))]
		# emi
		data[, emi := calc_emi(LoanAmount * 1000, Loan_Amount_Term * 12)]
		# EMI/TotalIncome = greater the EMI/Income ratio lesser will be the chances of the person to get a loan approved from bank.
		data[, emi_income_ratio := emi/(TotalIncome/12)]
		data[, emi := NULL]

	# engineer - log features
		log_cols = c('TotalIncome', 'Loan_Amount_Term', 'LoanAmount')
		if(log) {
			data[, (paste0(log_cols, '_log')) := lapply(.SD, function(x) log(x + 1)), .SDcols = log_cols]
		}
	return(data)
}
X = data_preprocess(copy(X), outliers = TRUE)
ftest = data_preprocess(copy(ftest), outliers = TRUE)

scale = FALSE
if(scale) {
	scale_data = rbind(X, ftest)
	scale_data[, flag := c(rep(1, nrow(X)), rep(0, nrow(ftest)))]
	scale_cols = c('TotalIncome', 'Loan_Amount_Term', 'LoanAmount')
	scale_data[, (paste0(scale_cols, '_scaled')) := 
						lapply(.SD, function(x) min_max_norm(x, new_min = 0, new_max = 1)), 
						.SDcols = scale_cols]
	X = scale_data[flag == 1, !c('flag'), with = FALSE]
	ftest = scale_data[flag == 0, !c('flag'), with = FALSE]
}

# # EDA
imp_matrix = importantFeatures(X, Y)
# plot_data(X, Y, scatter_cols = 'none')
print(imp_matrix)

# # drop cols
drop_cols = c()
X = X[, !drop_cols, with = FALSE]
ftest = ftest[, !drop_cols, with = FALSE]

# # data splitting
index = dataSplit(Y, split_ratio = c(0.7), regression = FALSE, seed = 294045)
train = X[index$train, ]
test = X[-index$train, ]
test_Y = Y[-index$train]
train_Y = Y[index$train]

# # model functions
# 1) glm
glm_data = cbind(train, target = train_Y)
glm_fit = glm(factor(target) ~ ., data = glm_data, family = 'binomial')
glm_pred = predict(glm_fit, newdata = test, type = 'response')
cutoff = getCutoff(probabilities = glm_pred, original = test_Y, how = 'accuracy')
performance_measure(predicted = glm_pred, actual = test_Y, threshold = cutoff, how = 'accuracy', regression = FALSE)
glm_fpred = predict(glm_fit, newdata = ftest, type = 'response')
glm_sub = data.table(Loan_ID = test_id, Loan_Status = ifelse(glm_fpred >= cutoff, 'Y', 'N'))
write.csv(glm_sub, 'submissions//glm_sub3.csv', row.names = F)

# RPART
dt_cols = c('Credit_History', 'emi_income_ratio', 'percent_income')
dt_data = cbind(train[, dt_cols, with = FALSE], target = train_Y)
dt_fit = rpart(factor(target) ~ ., data = dt_data, control = rpart.control(cp = 0.05, minsplit = 50))
dt_pred = predict(dt_fit, newdata = test, type = 'prob')
cutoff = getCutoff(probabilities = dt_pred[, 2] + runif(nrow(test))/100, original = test_Y, how = 'accuracy')
performance_measure(predicted = dt_pred[, 2], actual = test_Y, threshold = cutoff, how = 'accuracy', regression = FALSE)
dt_fpred = predict(dt_fit, newdata = ftest, type = 'prob')
dt_sub = data.table(Loan_ID = test_id, Loan_Status = ifelse(dt_fpred[, 2] >= cutoff, 'Y', 'N'))
write.csv(dt_sub, 'submissions//dt_sub.csv', row.names = F)


# Xgboost
xgb_cols = c(imp_matrix$chisq$feature[imp_matrix$chisq$significant == T], 'emi_income_ratio', 'percent_income')
xgb_dtrain = cbind(train[, xgb_cols, with = FALSE], target = train_Y)
xgb_dtest = cbind(test[, xgb_cols, with = FALSE], target = test_Y)

res1 <- xgb_opt(train_data = xgb_dtrain,
	train_label = as.factor(xgb_dtrain$target),
	test_data = xgb_dtest,
	test_label = as.factor(xgb_dtest$target),
	objectfun = "binary:logistic",
	evalmetric = "error"
)

xgb_dtrain = train[, xgb_cols, with = FALSE]
xgb_dtest = test[, xgb_cols, with = FALSE]
xgb_ftest = ftest[, xgb_cols, with = FALSE]


# xgb_fit = grid_search_tuning(X = xgb_dtrain, Y = as.numeric(as.character(train_Y)), X_test = xgb_dtest, Y_test = as.numeric(as.character(test_Y)))
xgb_fit = xgb_train(X = xgb_dtrain, Y = train_Y, X_test = xgb_dtest, Y_test = test_Y, 
						hyper_params = list(eta = 0.5417, max_depth = 6, nrounds = 110, subsample = 0.42, colsample_bytree = 0.97),
						eval_metric = 'error', cv = FALSE)
xgb_pred = xgb_predict(xgb_fit$fit, newdata = xgb_dtest)
cutoff = getCutoff(probabilities = xgb_pred, original = test_Y, how = 'accuracy')
performance_measure(predicted = xgb_pred, actual = test_Y, threshold = cutoff, how = 'accuracy', regression = FALSE)
xgb_fpred = xgb_predict(xgb_fit$fit, newdata = xgb_ftest)
xgb_sub = data.table(Loan_ID = test_id, Loan_Status = ifelse(xgb_fpred >= cutoff, 'Y', 'N'))
write.csv(xgb_sub, 'submissions//xgb_sub.csv', row.names = F)


# 2) random forest
rf_data = cbind(train[, xgb_cols, with = F], target = train_Y)
rf_test_data = cbind(test, target = test_Y)
mod <- rf_opt(
	train_data = rf_data,
	train_label = as.factor(rf_data$target),
	test_data = rf_test_data,
	test_label = as.factor(rf_test_data$target),
	mtry_range = c(1L, 4L)
)
rf_fit = ranger(factor(target) ~ ., data = rf_data, probability = TRUE, mtry = 4, min.node.size = 16)
rf_pred = predict(rf_fit, test)$predictions
cutoff = getCutoff(probabilities = rf_pred[, 2], original = test_Y, how = 'accuracy')
performance_measure(predicted = rf_pred[, 2], actual = test_Y, threshold = cutoff, how = 'accuracy', regression = FALSE)
rf_fpred = predict(rf_fit, ftest)$predictions
rf_sub = data.table(Loan_ID = test_id, Loan_Status = ifelse(rf_fpred[, 2] >= cutoff, 'Y', 'N'))
write.csv(rf_sub, 'submissions//rf_sub3.csv', row.names = F)

# 3) SVM
svm_data = cbind(train, target = train_Y)
svm_test_data = cbind(test, target = test_Y)
svm_fit = svm(factor(target) ~ ., data = svm_data, probability = TRUE, scale = TRUE)
svm_pred = predict(svm_fit, test, decision.values = TRUE)
svm_pred = min_max_norm(attr(svm_pred, 'decision.values'), 0, 1)
cutoff = getCutoff(probabilities = svm_pred[, 1], original = test_Y, how = 'accuracy')
performance_measure(predicted = svm_pred[, 1], actual = test_Y, threshold = cutoff, how = 'accuracy', regression = FALSE)
svm_fpred = predict(svm_fit, ftest, decision.values = TRUE)
svm_fpred = min_max_norm(attr(svm_fpred, 'decision.values'), 0, 1)
svm_sub = data.table(Loan_ID = test_id, Loan_Status = ifelse(svm_fpred[, 1] >= cutoff, 'Y', 'N'))
write.csv(svm_sub, 'submissions//svm_sub1.csv', row.names = F)