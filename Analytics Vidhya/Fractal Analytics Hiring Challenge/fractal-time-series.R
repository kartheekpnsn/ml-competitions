path = 'C:\\Users\\ka294056\\Desktop\\Fractal Analytics Hiring Challenge'

setwd(path)

data = fread('input-data//train.csv')
test = fread('input-data//test.csv')
sample_submission = fread('submissions/sample-submission.csv')

# # some pre-processing # #
data = data[Item_ID %in% intersect(data[, Item_ID], test[, Item_ID])]
test_id = test[, ID]

# # check cols with NA # #
apply(data, 2, function(x) any(is.na(x))) # Category_2 has NA
apply(test, 2, function(x) any(is.na(x))) # Category_2 has NA
d1 = data[, .(total_count = .N), Item_ID]
d2 = data[is.na(Category_2), .(NA_Count = .N) ,Item_ID]
setkey(d1, Item_ID); setkey(d2, Item_ID)
d = merge(d1, d2, all.x = TRUE)
d[is.na(NA_Count), NA_Count := 0]
d[, diff := total_count - NA_Count]
d[, missing := ifelse(diff == 0, 'total', ifelse(diff == total_count, 'none', 'partial'))]
d[, .N, missing] # we can see that it is either total missing or none missing
data[Item_ID %in% d[missing == 'total', Item_ID], .(unique(Category_1) == 0, unique(Category_3) == 0), Item_ID]
data[Item_ID %in% d[missing == 'total', Item_ID], .(length(unique(Category_1)), length(unique(Category_3))), Item_ID]
# # here we can see that the missing value in Category_2 has mostly 0 in Category_1 and Category_3 and also single unique values

# # mode function # #
mode = function(vector) {
	return(unique(vector)[which.max(table(vector))])
}

# # method - 1 # #
# drop Category_2
# # method - 2 # #
# impute Category_2 - mode value


# # engineer - features # #
engineer_features = function(data, method = 1, test = FALSE, train = NULL) {
	print('===>> Starting with Feature Engineering')
	data[, Datetime := as.Date(Datetime)]
	print('==> Creating Year, Month, Day, Week Day, Week of Month, Weekend flag, Week of Year, Day of Year')
	data[, Year := as.numeric(format(Datetime, '%Y'))]
	data[, month := as.numeric(format(Datetime, '%m'))]
	data[, day := as.numeric(format(Datetime, '%d'))]
	data[, week_day := factor(weekdays(Datetime))]
	data[, week_of_month := ifelse(ceiling(mday(Datetime) / 7) == 5, 4, ceiling(mday(Datetime) / 7))]
	data[, weekend_flag := ifelse(week_day %in% c('Saturday', 'Sunday'), 1, 0)]
	data[, week_of_year := ifelse(months(Datetime) == "December", 
		as.numeric(format(Datetime - 4, "%U")) + 1, 
		as.numeric(format(Datetime + 3, "%U")))]
	data[, day_of_year := as.numeric(strftime(Datetime, '%j'))]

	print('==> Engineering number of transactions')
	data[, ntrans_per_item := .N, Item_ID]
	data[, ntrans_per_date := .N, Datetime]
	print('Done <==')

	print('==> Creating day count')
	if(!test) {
		data[, start_date := min(Datetime), Item_ID]
		data[, day_count := as.numeric(difftime(Datetime, start_date, unit = 'day'))]
	} else {
		if(is.null(train)) {
			stop('Training data to be provided')
		}
		train[, Datetime := as.Date(Datetime)]
		train[, start_date := min(Datetime), Item_ID]
		data = merge(train[, .(start_date = unique(start_date)), Item_ID], data, by = 'Item_ID')
		data[, day_count := as.numeric(difftime(Datetime, start_date, unit = 'day'))]
	}
	print('Done <==')
	print('==> Handling Missing Values')
	if(method == 1) {
		data[, Category_2 := NULL]
		print('	==> Dropped Category_2')
		print('	Done <==')
	} else {
		data[is.na(Category_2), Category_2 := mode(Category_2)]
		print('	==> Imputed Category_2 with mode')
		print('	Done <==')
	}
	print('Done <==')

	print('==> Dropping Columns')
	# data[, ID := NULL]
	data[, Datetime := NULL]
	data[, start_date := NULL]
	print('Done <==')

	print('Done with Feature Engineering <<===')
	return(data)
}


# # model - 1 # #
m1_cols = c('ID', 'Item_ID', 'Datetime', 'Category_3', 'Category_2', 'Category_1', 'Price')
m1_data = subset(data, select = setdiff(m1_cols, 'ID'))
m1_test = subset(test, select = setdiff(m1_cols, 'Price'))

m1_test = engineer_features(copy(m1_test), test = TRUE, train = copy(m1_data))
test_id = m1_test[, ID]
m1_test[, ID := NULL]
m1_data = engineer_features(copy(m1_data))
m1_data = subset(m1_data, select = c(colnames(m1_test), 'Price'))


X = subset(m1_data, select = setdiff(colnames(m1_data), 'Price'))
Y = m1_data$Price
xgb_fit = xgb_train(X, Y, regression = TRUE, cv = FALSE, hyper_params = list(nrounds = 1000, eta = 0.1))
	
# # model - 2 # #
m2_cols = c('ID', 'Item_ID', 'Datetime', 'Category_3', 'Category_2', 'Category_1', 'Number_Of_Sales')
m2_data = subset(data, select = setdiff(m2_cols, 'ID'))
m2_test = subset(test, select = setdiff(m2_cols, 'Number_Of_Sales'))

m2_test = engineer_features(copy(m2_test), test = TRUE, train = copy(m2_data))
test_id2 = m2_test[, ID]
m2_test[, ID := NULL]
m2_data = engineer_features(copy(m2_data))
m2_data = subset(m2_data, select = c(colnames(m2_test), 'Number_Of_Sales'))

X = subset(m2_data, select = setdiff(colnames(m2_data), 'Number_Of_Sales'))
Y = m2_data$Number_Of_Sales
xgb_fit2 = xgb_train(X, Y, regression = TRUE, cv = FALSE, hyper_params = list(nrounds = 1000, eta = 0.1))

p1 = xgb_predict(xgb_fit$fit, m1_test)
p2 = xgb_predict(xgb_fit2$fit, m2_test)

f_sub1 = data.table(ID = test_id, Price = p1)
f_sub2 = data.table(ID = test_id2, Number_Of_Sales = p2)
f_sub = merge(f_sub1, f_sub2, by = 'ID')
f_sub[, .(ID, Number_Of_Sales, Price)]