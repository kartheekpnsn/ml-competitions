setwd('F:\\Kartheek\\Data\\ml-competitions\\IndiaHacks 2017 Machine Learning\\Predict the Segment - Hotstar')

source('https://raw.githubusercontent.com/kartheekpnsn/machine-learning-codes/master/R/functions.R')
source('https://raw.githubusercontent.com/kartheekpnsn/machine-learning-codes/master/R/xgb_tune.R')

# # # load the required libraries # # #
	library(data.table)
	library(stringr)
	library(jsonlite)
	library(h2o)

# # # Features # # #
	# ID		- 	unique identifier variable
	# titles	- 	titles of the shows watched by the user and watch_time on different titles 
	# 				in the format “title:watch_time” separated by comma
	# 				e.g. “JOLLY LLB:23, Ishqbaaz:40”. watch_time is in seconds
	# genres	- 	same format as titles
	# cities	- 	same format as titles
	# tod		- 	total watch time of the user spreaded across different time of days (24 hours format) 
	# 				in the format “time_of_day:watch_time” separated by comma, e.g. “1:454, “17”:5444”
	# dow		- 	total watch time of the user spreaded across different days of week (7 days format) 
	# 				in the format “day_of_week:watch_time” separated by comma, e.g. “1:454, “6”:5444”
	# segment	- 	target variable. 
	# 				consider them as interest segments.
	# 				For modeling, encode pos = 1, neg = 0


# # # Convert JSON to Data.Table # # #
	jsonToDT = function(json_data, test = FALSE) {
		dt = data.table(ID = unlist(names(json_data)))
		dt[, genres := unlist(lapply(json_data, '[', 1))]
		dt[, titles := unlist(lapply(json_data, '[', 2))]
		if(! test) {
			dt[, cities := unlist(lapply(json_data, '[', 3))]
			dt[, segment := unlist(lapply(json_data, '[', 4))]
			dt[, dow := unlist(lapply(json_data, '[', 5))]
			dt[, tod := unlist(lapply(json_data, '[', 6))]
			dt[, segment := factor(as.numeric(segment != 'neg'))]
		} else {
			dt[, cities := unlist(lapply(json_data, '[', 4))]
			dt[, tod := unlist(lapply(json_data, '[', 3))]
			dt[, dow := unlist(lapply(json_data, '[', 5))]
		}
		return(dt)
	}

# # # load the data set # # #
	train_json = fromJSON("train_data.json")
	test_json = fromJSON("test_data.json")
	o_train_raw = jsonToDT(train_json)
	o_test_raw = jsonToDT(test_json, test = TRUE)

# # # Feature Engineering # # #
	engineerFeatures = function(data, more = FALSE, test = FALSE) {
		sports = c('athletics', 'badminton', 'boxing', 'cricket', 'football', 
			'formula1', 'hockey', 'kabaddi', 'volleyball', 'tennis', 
			'swimming', 'tabletennis', 'indiavssa', 'sport', 'formulae', 'na') 
		data[, genres := tolower(genres)]
		data[, genres := gsub('\\s', '', genres)]
		data[, g1 := gsub(':[0-9][0-9]*', '', genres)]
		data[, g2 := gsub('[a-z][a-z]*[0-9]*:', '', genres)]
		data[, d2 := gsub('[0-9]:', '', dow)]
		data[, d1 := gsub(':[0-9]+', '', dow)]
		data[, t2 := gsub('[0-9]+:', '', tod)]
		data[, t1 := gsub(':[0-9]+', '', tod)]
		id = data[, ID]
		subset_data = data[, .(ID, g1, g2)]
		subset_data2 = data[, .(ID, d1, d2)]
		subset_data3 = data[, .(ID, t1, t2)]

		setkey(subset_data, ID)
		subset_data = subset_data[, .(g1 = unlist(strsplit(g1, ',')), g2 = unlist(strsplit(g2, ','))), by = ID]
		subset_data = dcast(subset_data, ID ~ g1, value.var = 'g2')
		subset_data = subset_data[ID %in% id, ]
		subset_data = cbind(subset_data[, .(ID)], 
		subset_data[, lapply(.SD, function(x) as.integer(x)/(60 * 60)), .SDcols = setdiff(colnames(subset_data), 'ID')])
		subset_data[is.na(subset_data)] = 0

		setkey(subset_data2, ID)
		subset_data2 = subset_data2[, .(d1 = unlist(strsplit(d1, ',')), d2 = unlist(strsplit(d2, ','))), by = ID]
		subset_data2 = dcast(subset_data2, ID ~ d1, value.var = 'd2')
		subset_data2 = subset_data2[ID %in% id, ]
		subset_data2 = cbind(subset_data2[, .(ID)], 
		subset_data2[, lapply(.SD, function(x) as.integer(x)/(60 * 60)), .SDcols = setdiff(colnames(subset_data2), 'ID')])
		subset_data2[is.na(subset_data2)] = 0
		colnames(subset_data2)[2:ncol(subset_data2)] = paste0('d_', colnames(subset_data2)[2:ncol(subset_data2)])
		subset_data2[, weekdays := d_1 + d_2 + d_3 + d_4 + d_5]
		subset_data2[, weekends := d_6 + d_7]
		subset_data2[, weekend_more := as.numeric(weekdays < weekends)]

		setkey(subset_data3, ID)
		subset_data3 = subset_data3[, .(t1 = unlist(strsplit(t1, ',')), t2 = unlist(strsplit(t2, ','))), by = ID]
		subset_data3 = dcast(subset_data3, ID ~ t1, value.var = 't2')
		subset_data3 = subset_data3[ID %in% id, ]
		subset_data3 = cbind(subset_data3[, .(ID)], 
		subset_data3[, lapply(.SD, function(x) as.integer(x)/(60 * 60)), .SDcols = setdiff(colnames(subset_data3), 'ID')])
		subset_data3[is.na(subset_data3)] = 0
		colnames(subset_data3)[2:ncol(subset_data3)] = paste0('h_', colnames(subset_data3)[2:ncol(subset_data3)])
		cols = colnames(subset_data3)[2:ncol(subset_data3)]
		subset_data3[, early_morning_5_7 := h_5 + h_6 + h_7]
		subset_data3[, morning_8_11 := h_8 + h_9 + h_10 + h_11]
		subset_data3[, afternoon_12_15 := h_12 + h_13 + h_14 + h_15]
		subset_data3[, evening_16_19 := h_16 + h_17 + h_18 + h_19]
		subset_data3[, night_20_23 := h_20 + h_21 + h_22 + h_23]
		subset_data3[, mid_night_0_4 := h_0 + h_1 + h_2 + h_3 + h_4]
		if(!more) {
			subset_data3 = subset(subset_data3, select = setdiff(colnames(subset_data3), cols))
		}
		setkey(subset_data, ID)
		setkey(subset_data2, ID)
		setkey(subset_data3, ID)

		subset_data = merge(subset_data, subset_data2)
		subset_data = merge(subset_data, subset_data3)
		subset_data[, total_watch_time := data$g2]
		subset_data[, total_watch_time := lapply(strsplit(total_watch_time, ','), 
			function(x) sum(as.numeric(x))/(60 * 60))]

		subset_data[, title_count := data$titles]
		subset_data[, title_count := lapply(title_count, function(x) str_count(string = x, pattern = ":"))]

		subset_data[, genres_count := data$genres]
		subset_data[, genres_count := lapply(genres_count, function(x) str_count(string = x, pattern = ":"))]

		subset_data[, cities_count := data$cities]
		subset_data[, cities_count := lapply(cities_count, function(x) str_count(string = x, pattern = ":"))]

		subset_data[, dow_count := data$dow]
		subset_data[, dow_count := lapply(dow_count, function(x) str_count(string = x, pattern = ":"))]

		subset_data[, tod_count := data$tod]
		subset_data[, tod_count := lapply(tod_count, function(x) str_count(string = x, pattern = ":"))]

		pd = names(subset_data)[sapply(subset_data, is.list)]
		subset_data[, (pd) := lapply(.SD, unlist), .SDcols = pd]
		subset_data = subset_data[match(data[,ID], ID)]
		subset_data[, sports := rowSums(subset(subset_data, select = sports))]
		# subset_data = subset(subset_data, select = setdiff(colnames(subset_data), sports))
		subset_data = subset_data[, !sports, with = FALSE]

		if(!test) {
			setkey(subset_data, ID)
			setkey(data, ID)
			subset_data = merge(subset_data, data[, .(ID, segment)])
		}
		return(subset_data)
	}

	o_train = engineerFeatures(o_train_raw)
	o_test = engineerFeatures(o_test_raw, test = TRUE)

	o_train = o_train[ID %in% o_train_raw[, ID]]
	o_test = o_test[ID %in% o_test_raw[, ID]]

# # ML Model # #
	X = subset(o_train, select = setdiff(colnames(o_train), c('segment', 'ID')))
	Y = o_train$segment
	xgb_fit = xgb_train(X, Y, cv = FALSE, eval_metric = 'auc', hyper_params = list(nrounds = 161, eta = 0.05))
	test_id = o_test$ID
	pred = xgb_predict(xgb_fit$fit, o_test[, !c('ID'), with = F])
	submission = data.table(ID = test_id, segment = pred)
	write.csv(submission, 'my-submission.csv', row.names = F)
