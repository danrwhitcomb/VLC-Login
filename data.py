#! /bin/python

import sys

dataArray = [None] * 20
bitMatches = [0] * 9
falsePositives = 0
falseNegatives = 0
w = '001110111'

data = open(sys.argv[1], 'r')
byte = data.readline()

matches = 0

index = 0

while byte != "":
	byte = byte.rstrip()
	dataArray[index] = byte
	index += 1
	byte = data.readline()

for i in dataArray:
	if w == i:
		matches += 1
	#matches += 1 if w == i
	for j in range(len(i)):
		if i[j] == w[j]:
			bitMatches[j] = bitMatches[j] + 1 
		if w[j] == '1' and i[j] == '0':
			falseNegatives += 1 
		if w[j] == '0' and i[j] == '1':
			falsePositives += 1


total = 0
for i in bitMatches:
	total += i

average = total / (len(bitMatches) * 1.0)


print("Match ratio: " + str(matches) + "/" + str(index))
print("Match percent: " + str((matches / (index * 1.0)) * 100) + "%")
print("")
print("Bit accuracy: " + str((average/index) * 100) + "%")
print("Bit Matches: " + str(bitMatches))

total = 0
for k in bitMatches:
	avg = (k / (index * 1.0)) * 100
	print(str(avg) + "%,")



print("")

print("False positives: " + str(falsePositives) + " (" + str(((falsePositives / (index * 9.0)) * 100)) + "%)") 
print("False negatives: " + str(falseNegatives) + " (" + str(((falseNegatives / (index * 9.0)) * 100)) + "%)")

data.close()