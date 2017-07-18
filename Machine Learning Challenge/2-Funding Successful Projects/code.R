path = 'F:\\Kartheek\\Data\\ml-competitions\\ML - Funding Successful Projects'

setwd(path)

# # read input files # # 
data = fread('input-data\\train.csv', stringsAsFactors = TRUE)
ftest = fread('input-data\\test.csv', stringsAsFactors = TRUE)

# # load functions # #
source('https://raw.githubusercontent.com/kartheekpnsn/machine-learning-codes/master/R/functions.R')

# # get document term matrix from text # #
text_dtm = function(keywords, project_id) {
	library(tm)
	library(SnowballC) # for stemming
	library(text2vec) # for DTM

	print("==> replacing '-' with space")
	keywords = gsub('-', ' ', as.character(keywords))
	print("==> removing stop words")
	keywords = removeWords(keywords, stopwords("english"))
	print("==> removing numbers")
	keywords = removeNumbers(keywords)
	print("==> removing double space")
	keywords = gsub('\\s+', ' ', keywords)
	# print("==> Stemming words")
	# text_data[, keywords = wordStem(keywords)]
	print("==> Splitting keywords")
	keywords = strsplit(keywords, ' ')
	print("==> Dropping words with length <= 2")
	keywords = lapply(keywords, function(x) x[nchar(x) > 2])
	print("==> Creating DTM")
	vec_train = itoken(keywords, tokenizer = word_tokenizer, ids = project_id)
	vocab = create_vocabulary(vec_train)
	pruned_vocab = prune_vocabulary(vocab, term_count_min = 150) # words occuring 150 or more times
	vocab1 = vocab_vectorizer(pruned_vocab)
	dtm_text = create_dtm(vec_train, vocab1)
	print("Done <==")

	print("==> Returning output as dtm_train and dtm_test")
	dtm_text1 = as.data.table(as.matrix(dtm_text))
	dtm_train = dtm_text1[1:108129]
	dtm_test = dtm_text1[108130:171594]
	print("Done <==")
	return(list(dtm_test = dtm_test, dtm_train = dtm_train))
}


# # word count and text length (flag = 1) # #
text_word_counts = function(vector, flag = 1) {
	library(tm)
	vector = gsub('-', ' ', vector)
	vector = tolower(removePunctuation(as.character(vector)))
	if(flag == 1) {
		cat("\t ==> Getting Number of characters in the text\n")
		vector_lc = nchar(vector)
		cat("\t Done <==\n")
		return(vector_lc)
	} else if(flag == 2) {
		cat('\t ==> Get Number of words in the text\n')
		vector = removeWords(vector, stopwords("english")) 
		vector = removeNumbers(vector)
		# vector = stemDocument(vector)
		vector = gsub('\\s+', ' ', vector)
		vector_wc  = unlist(lapply(strsplit(vector, '\\s'), function(x) length(unique(x))))
		cat("\t Done <==\n")
		return(vector_wc)
	} else {
		cat('\t ==> Get Number of duplicate words in the text\n')
		vector = removeWords(vector, stopwords("english")) 
		vector = removeNumbers(vector)
		# vector = stemDocument(vector)
		vector = gsub('\\s+', ' ', vector)
		vector_wc  = unlist(lapply(strsplit(vector, '\\s'), function(x) length(unique(x))))
		vector_dup = (str_count(vector, "\\w+") - vector_wc)
		cat("\t Done <==\n")
		return(vector_dup)
	}
}


# # engineer features # #
engineerFeatures = function(data, log_apply = TRUE, test = FALSE) {
	library(text2vec)
	library(stringr)
	data[, disable_communication := factor(as.numeric(disable_communication) - 1)]
	
	# # process time stamps # #
	print("==> Processing dates")
	unix_timestamps = c('deadline','state_changed_at','created_at','launched_at')
	data[, c(unix_timestamps) := lapply(.SD, function(x) structure(x, class=c('POSIXct'))),
												 .SDcols = unix_timestamps]
	print("Done <==")

	# # country currency processing # #
	print("==> Processing Country and Currency")
	data[, country := as.character(country)]
	data[country %in% c('IE', 'NL', 'DE'), country := 'IE']
	data[, country := as.factor(country)]
	setnames(data, 'country', 'country_name')
	data[, amount_usd := ifelse(currency == 'SEK', 0.1149 * goal, 
							ifelse(currency == 'AUD', 0.761 * goal,
							ifelse(currency == 'CAD', 0.7544 * goal,
							ifelse(currency == 'DKK', 0.1509 * goal,
							ifelse(currency == 'EUR', 1.1222 * goal,
							ifelse(currency == 'GBP', 1.2746 * goal,
							ifelse(currency == 'NOK', 0.1180 * goal,
							ifelse(currency == 'NZD', 0.7220 * goal, goal))))))))]
	print("Done <==")

	# # date values # #
	print("==> Getting days out from dates")
	data[, launch_time_days := as.numeric(difftime(launched_at, created_at, units = 'days'))]
	data[, status_change_days := as.numeric(difftime(state_changed_at, launched_at, units = 'days'))]
	data[, time_given_days := as.numeric(difftime(deadline, launched_at, units = 'days'))]
	data[, time_to_change_days := as.numeric(difftime(state_changed_at, deadline, units = 'days'))]
	print("Done <==")

	if(log_apply) {
		print("==> Applying log on days and goal amounts")
		data[, launch_time_days_log := log1p(launch_time_days)]
		data[, status_change_days_log := log1p(status_change_days)]
		data[, time_given_days_log := log1p(time_given_days)]
		data[, time_to_change_days_log := log1p(time_to_change_days)]
		data[, goal_log := log1p(goal)]
		data[, amount_usd_log := log1p(amount_usd)]
		print("Done <==")
	}

	# # extract month of the project # #
	print("==> Extracting month of the projects")
	month_cols = c('launched_at', 'created_at', 'state_changed_at')
	month_cols_create = c('launch_month', 'create_month', 'sc_month')
	data[, c(month_cols_create) := lapply(.SD, function(x) { factor(format(x, '%b')) }), .SDcols = month_cols]
	print("Done <==")


	# # clean and extract keywords, description word count (wc), letter count (lc) # #
	print("==> Getting Word count and Character count")
	len_cols = c('name_lc', 'desc_lc', 'keywords_lc')
	count_cols = c('name_wc', 'desc_wc', 'keywords_wc')
	count_dup_cols = c('name_dups', 'desc_dups', 'keywords_dups')
	cols = c('name', 'desc', 'keywords')
	
	data[, c(len_cols) := lapply(.SD, function(x) text_word_counts(x, flag = 1)), .SDcols = cols]
	data[, c(count_cols) := lapply(.SD, function(x) text_word_counts(x, flag = 2)), .SDcols = cols]
	data[, c(count_dup_cols) := lapply(.SD, function(x) text_word_counts(x, flag = 3)), .SDcols = cols]
	print("Done <==")

	# 1 if state_changed_at < deadline
	# 2 if state_changed_at is on same day as deadline
	# 3 if state_changed_at is > deadline
	print("==> Some more features")
	data[, s_change_before_deadline := factor(ifelse(state_changed_at < deadline, 1, 
										ifelse(round(as.numeric(state_changed_at - deadline)) == 0, 2, 0)))]
	print("Done <==")

	# # drop dates # #
	print("==> Dropping columns")
	data[, launched_at := NULL]
	data[, state_changed_at := NULL]
	data[, created_at := NULL]
	data[, deadline := NULL]
	if(!test){
		data = subset(data, select = c(setdiff(colnames(data), 'final_status'), 'final_status'))
	} 

	# # drop columns # #
	data[, backers_count := NULL]
	data[, project_id := NULL]
	data[, name := NULL]
	data[, desc := NULL]
	data[, keywords := NULL]
	print("Done <==")

	print("==> Returning output")
	print("Done <==")
	return(data)
}

ftest_id = ftest[, project_id]
text_data = text_dtm(keywords = c(as.character(data$keywords), as.character(ftest$keywords)),
						project_id = c(data$project_id, ftest$project_id))
data = engineerFeatures(copy(data), log_apply = TRUE)
ftest = engineerFeatures(copy(ftest), test = TRUE, log_apply = TRUE)
data = cbind(data, text_data$dtm_train)
ftest = cbind(ftest, text_data$dtm_test)

# # ML Model # #
	drop_cols = c('final_status', 'country', 'currency', "launch_month", 'next')
				# "create_month", "sc_month", "s_change_before_deadline", "disable_communication")
	X = data[, !drop_cols, with = FALSE]
	Y = data$final_status
	imp = importantFeatures(X, Y)
	XX = copy(X)
	# XX = X[, !imp$anova[significant == F, feature], with = F]
	index = dataSplit(Y, split_ratio = 0.7)
	xgb_fit = xgb_train(X = XX[index$train, ] , Y = Y[index$train], 
							X_test = XX[-index$train, ], Y_test = Y[-index$train], 
							hyper_params = list(nrounds = 141, eta = 0.05), cv = TRUE, eval_metric = 'error')
	xgb_pred = xgb_predict(xgb_fit$fit, XX[-index$train])
	performance_measure(predicted = xgb_pred, actual = Y[-index$train], optimal_threshold = F)
	xgb_pred = xgb_predict(xgb_fit$fit, ftest[, !drop_cols, with = FALSE])
	write.csv(data.table(project_id = ftest_id, final_status = round(xgb_pred)), 'xgb_submission_3.csv', row.names = F)

	library(h2o)
	h2o.init(nthreads = -1, max_mem_size = '8G')
	drop_cols = c('country', 'currency', "launch_month", 'next')
	h2o_train = as.h2o(data[index$train, !drop_cols, with = FALSE])
	h2o_test = as.h2o(data[-index$train, !drop_cols, with = FALSE])
	h2o_ftest = as.h2o(ftest)

	x = colnames(X)
	y = 'final_status'
	rf_fit = h2o.randomForest(x = x, y = y, training_frame = h2o_train, ntrees = 500, validation_frame = h2o_test, seed = 294056)
	h2o_pred = as.numeric(as.vector(h2o.predict(rf_fit, h2o_ftest)$predict))
	write.csv(data.table(project_id = ftest_id, final_status = round(h2o_pred)), 'rf_h2o_submission.csv', row.names = F)
