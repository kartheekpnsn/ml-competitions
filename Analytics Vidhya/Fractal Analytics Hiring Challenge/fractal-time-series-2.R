datasplit = function(Y) {
	index = 1:length(Y)
    index = sample(index, round(length(Y) * 0.75))
    return(index)
}

rmse = c()
fpred = data.table()
for(eachItem in unique(m1_data$Item_ID)) {
	subset_data = m1_data[Item_ID == eachItem, !c('Item_ID'), with = FALSE]
	constant_cols = names(unlist(apply(subset_data, 2, function(x) which(length(unique(x)) == 1))))
	constant_cols = setdiff(constant_cols, 'Price')
	subset_data = subset_data[, !constant_cols, with = FALSE]
	subset_test = m1_test[Item_ID == eachItem]

	index = datasplit(subset_data$Price)
	train = subset_data[index, ]
	test = subset_data[-index, ]

	library(ranger)
	rf_fit = ranger(Price ~ ., data = train)
	# rmse = c(rmse, performance_measure(predicted = predict(rf_fit, test)$predictions, actual = test$Price, regression = T, metric = 'rmse'))
	fpred = rbind(fpred, cbind(subset_test, data.table(Price = predict(rf_fit, subset_test)$predictions)))
}

rmse = c()
fpred2 = data.table()
for(eachItem in unique(m2_data$Item_ID)) {
	subset_data = m2_data[Item_ID == eachItem, !c('Item_ID'), with = FALSE]
	constant_cols = names(unlist(apply(subset_data, 2, function(x) which(length(unique(x)) == 1))))
	constant_cols = setdiff(constant_cols, 'Number_Of_Sales')
	subset_data = subset_data[, !constant_cols, with = FALSE]
	subset_test = m2_test[Item_ID == eachItem]

	index = datasplit(subset_data$Number_Of_Sales)
	train = subset_data[index, ]
	test = subset_data[-index, ]

	library(ranger)
	rf_fit = ranger(Number_Of_Sales ~ ., data = train)
	# rmse = c(rmse, performance_measure(predicted = predict(rf_fit, test)$predictions, actual = test$Number_Of_Sales, regression = T, metric = 'rmse'))
	fpred2 = rbind(fpred2, cbind(subset_test, data.table(Number_Of_Sales = predict(rf_fit, subset_test)$predictions)))
}

fpred[, ID := test_id]
fpred2[, ID := test_id2]

setorder(fpred, ID)
setorder(fpred2, ID)

fsub = cbind(fpred2[, .(ID, Number_Of_Sales)], fpred[, .(Price)])
write.csv(fsub, 'submissions/submission-2.csv', row.names = F)