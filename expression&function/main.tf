# ## An expressin is somthing  terraform evaulates to produce a value 
# #String Inpterpolation 
# "10.0.${count.index + 1}.0/24"
# #Terraform replaces:

# ${count.index + 1}
# count.index = 0

# #becomes:
# 10.0.1.0/24

# #and:
# count.index = 1

# #becomes:
# 10.0.2.0/24

# #Arthimetic Expression 
