def print_n(num, start, n, n_start):
	if n==0:
		return;

	for i in range(start, n_start):
		print i
		print_n(num, i, n-1, n_start)



print_n(5, 0, 2,2)




# def jumps(arr):
# 	boolarr = [0 for x in arr]
# 	boolarr[0] =1
# 	boolreach = 0

# 	for i in range(len(arr)):
# 		if boolreach >= i:
# 			boolreach += arr[i]
# 			if boolreach >= len(arr)-1:
# 				return True
# 		else:
# 			return False




# arr = [1,2,0,3,1,2,0,1,2]
# arr2 = [0,4,0,0,0,1]



# print jumps(arr)
# print jumps(arr2)


# def helper(num):
# 	r = num%3
# 	d = num/3

# 	if r==0:
# 		return d,d,d
# 	if r==1:
# 		return d,d,d+1
# 	if r==2:
# 		return d,d+1,d+1


# def findcompares(num):
# 	arr = [0 for x in range(num+1)]

# 	arr[0] = 0; arr[1] = 0; arr[2] =1; arr[3] = 1;

# 	for i in range(4,num+1):
# 		thevals = helper(i)
# 		arr[i] = max(arr[thevals[0]], arr[thevals[1]], arr[thevals[2]])+1

# 	return arr[num]


# print findcompares(81)