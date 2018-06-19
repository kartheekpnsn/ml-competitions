flag = True
error = False
tree_index = 2

NMOT_MIN = 0
MLW_MIN = 0
GANGI_MIN = 0
NMOT_MAX = 99999
MLW_MAX = 99999
GANGI_MAX = 99999

f = open('../../data/decision trees/v3/rf_depth6/tree_structure_' + str(tree_index) + '.csv', 'w')
f.write('MLW_MIN,MLW_MAX,NMOT_MIN,NMOT_MAX,GANGI_MIN,GANGI_MAX,TARGET\n')
f.close()

while flag:
	f = open('../../data/decision trees/v3/rf_depth6/tree_structure_' + str(tree_index) + '.csv', 'a')
	variable = input('Enter variable name (g or n or m): ')
	if variable in ['g', 'n', 'm']:
		symbol = input('Enter symbol (g or l or e): ')
		if symbol in ['g', 'ge', 'l', 'le', 'e']:
			pass
		else:
			symbol = None
		value = int(input('Enter the value: '))
	elif variable == 'k':
		pass
	else:
		variable = None
	# MAIN CODE #
	if variable == 'g':
		if symbol == 'l':
			GANGI_MAX = value
		elif symbol == 'g':
			GANGI_MIN = value
		elif symbol == 'e':
			GANGI_MIN = value
			GANGI_MAX = value
		else:
			print('Error: Symbol entered as => ' + symbol + " and Variable entered as => " + variable)
			error = True
	elif variable == 'n':
		if symbol == 'l':
			NMOT_MAX = value
		elif symbol == 'g':
			NMOT_MIN = value
		elif symbol == 'e':
			NMOT_MIN = value
			NMOT_MAX = value
		else:
			print('Error: Symbol entered as => ' + symbol + " and Variable entered as => " + variable)
			error = True
	elif variable == 'm':
		if symbol == 'l':
			MLW_MAX = value
		elif symbol == 'g':
			MLW_MIN = value
		elif symbol == 'e':
			MLW_MAX = value
			MLW_MIN = value
		else:
			print('Error: Symbol entered as => ' + symbol + " and Variable entered as => " + variable)
			error = True
	elif variable == 'k':
		target = int(input('Enter the target class (0 or 1 or 2 or 3): '))
		if target in [0, 1, 2, 3]:
			pass
		else:
			target = None
		output_list = [MLW_MIN, MLW_MAX, NMOT_MIN, NMOT_MAX, GANGI_MIN, GANGI_MAX, target]
		print(output_list)
		print('===========================')
		write_output = ",".join([str(MLW_MIN), str(MLW_MAX), str(NMOT_MIN), str(NMOT_MAX), str(GANGI_MIN), str(GANGI_MAX), str(target)]) + "\n"
		f.write(write_output)
		f.close()
		NMOT_MIN = 0
		MLW_MIN = 0
		GANGI_MIN = 0
		NMOT_MAX = 99999
		MLW_MAX = 99999
		GANGI_MAX = 99999
		print('==== STARTING NEXT BRANCH ====')
	else:
		print('Error: Entered variable as: ' + variable)
		if f:
			f.close()
		error = True

	if error:
		if f:
			f.close()
		flag = False
		print('====== ERROR =======')
		flag = False
		if f:
			f.close()
