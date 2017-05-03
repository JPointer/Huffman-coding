.data
	array2Size:	.word
	fileName: 	.space 100
	fileName2: 	.space 100 
	fileOutName: 	.asciiz 	"/home/piotr/Pulpit/Studia/ARKO/textOut.bin"
	buffer: 	.space 10 	#buffer to read
	msg: 		.asciiz 	"Code file-0 Decode file-1 :"
	msg1: 		.asciiz 	"Write a name of file:"
	text:   	.align 2
			.space 10000 	#in this space we are keeping text from file
	codedText: 	.align 2
		   	.space 10000
	array:  	.align 2
			.space 1024 	#freq
	array2: 	.align 2
			.space 256	# table of letters 
	arrayStatistic: .align 2
			.space 5000 	#to build a code for each letters
	arrayCodeAddress: .align 2
			.space 1024 	# 256 letters * 4(word-for address) 
	headerOfFile: 	.align 2
			.space 2000 	# how many letters - letter - code lenght - code ...
	textLenght: 	.word
.text 
main:
	li $v0, 4
	la $a0, msg
	syscall
		
	li $v0, 5
	syscall
		
	move $t3, $v0
			
	li $v0, 4
	la $a0, msg1
	syscall
		
	li $v0, 8
	la $a0, fileName
	li $a1, 100
	syscall
		
	addi $t0, $zero, '\n'
	move $t1, $a0
readLoop:
	lb $t2, ($t1)
	beq $t2, $t0, swap
	beqz $t2, openFileToCode
	addi $t1, $t1, 1
	j readLoop
swap:
	sb $zero, ($t1)
	bnez $t3, decode
						
openFileToCode:
					# Open (for reading) a file that does not exist
	li   $v0, 13       		# system call for open file	
	la   $a0, fileName    		# output file name	
	li   $a1, 0        		# Open for reading (flags are 0: read, 1: write)
	li   $a2, 0       		# mode is ignored
	syscall            		# open a file (file descriptor returned in $v0)
	move $s0, $v0      		# save the file descriptor 
		
	move $a0, $s0      		# file descriptor 
	la   $a1, buffer   		# address of buffer from which to read
	li   $a2,  10   		# hardcoded buffer length

	addi $t4, $zero, 0 		#counter of text area 	
loopForReadText:
	li   $v0, 14       		# system call for reading from file
	syscall            		# read from file
		
	beqz $v0, endLoopForReadText
	move $t0, $a1
		
loopForReadBuffer:
	lbu $t1, ($t0)
	sb $t1, text($t4) 
	mul  $t1, $t1, 4 
	lw $t2, array($t1)
	addi $t2, $t2, 1
	sw $t2, array($t1)
			
	addi $t0, $t0, 1
	addi  $t4, $t4, 1
	sub $t2, $t0, $a1
	bge $t2, $v0, loopForReadText
		
	j loopForReadBuffer
	
endLoopForReadText:	
	sw $t4, textLenght 
	la $t0, array
	la $t1, array2
	addi $t2, $zero, 0
	move $t9, $sp 			#remember stack begin
	
	move $t4, $t0
loopToFindLetters: 			#letters which exist
	lw $t3, ($t0)
	bnez $t3, writeToArrays2andCreateLeave
	addi $t0, $t0, 4
			
	sub $t5, $t0, $t4
	bge $t5, 1024, beforeCreateTree
	j loopToFindLetters
writeToArrays2andCreateLeave:
		
	sb $t3, -4($sp) 		#write a freg to leave
	sw $t2, -8($sp) 
	sw $zero, -12($sp)
	sw $zero, -16($sp)
	addi $sp, $sp, -16
	sub $t5, $t0, $t4 
	div $t5, $t5, 4			# $t5-letter to array2
	sb $t5, ($t1)
	addi $t1, $t1, 1
	addi $t0, $t0, 4
	sub $t5, $t0, $t4
	bge $t5, 1024, beforeCreateTree
	j loopToFindLetters
beforeCreateTree:
	la $s6, array2
	subu $t1, $t1, $s6
	sw $t1, array2Size($zero)
createTree:
					#counter of nodes - $t6 and stack address before first laeve $t9	
	move $t6, $t9
	addi $t7, $zero, 0 		# first min freq
	addi $s0, $zero, 0 		# first min address
	addi $t8, $zero, 0 		# second min freq
	addi $s1, $zero, 0 		# second min address
		
loopToFindFirstMin:
	beq $t6, $sp, findSecondMin
	lw $t0, -4($t6) 		# temp freq
	lw $t1, -8($t6) 		# 0-1
	move $t2, $t6   		# temp address
	bnez $t1, incrementLoopToFindFirstMin
	bnez $t7, compereMinAndTemp
	move $t7, $t0
	move $s0, $t2
	addi $t6, $t6, -16
	j loopToFindFirstMin
			
incrementLoopToFindFirstMin:
	addi $t6, $t6, -16
	j loopToFindFirstMin
		
compereMinAndTemp:
	bge $t0, $t7, incrementLoopToFindFirstMin 
	move $t7, $t0
	move $s0, $t2
	addi $t6, $t6, -16
	j loopToFindFirstMin			
findSecondMin:
	lw $t3, -8($s0)
	addi $t3, $t3, 1
	sw $t3, -8($s0)
	move $t6, $t9
			
loopToFindSecMin:
	beq $t6, $sp, createNode
	lw $t0, -4($t6) 		# temp freq
	lw $t1, -8($t6) 		# 0-1
	move $t2, $t6   		# temp address
	bnez $t1, incrementLoopToFindSecMin
	bnez $t8, compereMinAndTemp2
	move $t8, $t0
	move $s1, $t2
	addi $t6, $t6, -16
	j loopToFindSecMin
incrementLoopToFindSecMin:
	addi $t6, $t6, -16
	j loopToFindSecMin
		
compereMinAndTemp2:
	bge $t0, $t8, incrementLoopToFindSecMin 
	move $t8, $t0
	move $s1, $t2
	addi $t6, $t6, -16
	j loopToFindSecMin
						
createNode:
	beqz $t8, justRootLeft	
			
	lw $t3, -8($s1)
	addi $t3, $t3, 1
	sw $t3, -8($s1)
			
	add $t7, $t7, $t8
	sw $t7, -4($sp)
	sw $zero, -8($sp)
	sw $s0, -12($sp)
	sw $s1, -16($sp)
	addi $sp, $sp, -16
	j createTree
			
justRootLeft:
	move $t8, $s0 			# this is a adress of root
	
statistic: 				# $t9-begin of leaves $t8-root
	addi $s0, $zero, '0' 		# to save to arrayStatistic
	addi $s1, $zero, '1' 		# to save to arrayStatistic
	addi $s2, $zero, '2' 
	addi $t2, $zero, 0 		# counter
		
	subu $sp, $sp, 16
	sw $zero, 12($sp) 		# zer to signal 
	sw $t2, 8($sp) 			#write index in arrayStatistic
	sw $t8, 4($sp) 			# root
	sw $t2, 0($sp) 			#write index in arrayStatistic
	sb $s2, arrayStatistic($t2) 	#save 2 to arrayStatistic
	addi $t2, $t2, 1
		
	lw $t3,-12($t8) 		# left son of root
		
loopPutToStack:
	beqz $t3, continue1
				
	lw $s3, 0($sp) 			# take prev index 
	addi $sp, $sp, -8
	sw $t3, 4($sp) 			# save left to stack
	sw $t2, 0($sp) 			# save index on stack
				
loopToPrevCode: 			#write prev code
	lb $s4, arrayStatistic($s3)
	beq $s4, '2', endOfPrevCode
	sb $s4, arrayStatistic($t2)
	addi $s3, $s3, 1
	addi $t2, $t2, 1
	j loopToPrevCode
					
endOfPrevCode:											
	sb $s0, arrayStatistic($t2) 	#save 0 to arrayStatistic
	addi $t2, $t2, 1
	sb $s2, arrayStatistic($t2) 	#save 2 to arrayStatistic
	addi $t2, $t2, 1
				
	move $t4, $t3
	lw $t5,-12($t3) 		# next left
	move $t3, $t5
	j loopPutToStack
continue1:
				
					#write letter freq and code
	subu $t5,$t9, $t4
	div $t5, $t5, 16
				
	lbu $s7, array2($t5) 		#important that a letter is in $s7
				
	li $v0, 11 			# write letter
	move $a0, $s7
	syscall
				
	li $v0, 11
	li $a0, '-'
	syscall
				
	lw $t6, -4($t4) 		# write a freq
	li $v0, 1
	move $a0, $t6
	syscall
				
	li $v0, 11
	li $a0, '-'
	syscall
				
	lw $s3, 0($sp) 			# take index
					#we have got a letter in $s7 and we want to remember adress $s3 in arrayCodeAddress
	mul $s7, $s7, 4
	sw $s3, arrayCodeAddress($s7)
				
	addi $s5, $zero, 0
loopToWriteCode: 			#write code
	lb $s4, arrayStatistic($s3)
	beq $s4, '2', endOfCode
					
	li $v0, 11 
	move $a0, $s4
	syscall
					
	addi $s3, $s3, 1
	addi $s5, $s5, 1
	j loopToWriteCode
endOfCode:
	li $v0, 11
	li $a0, '\n'
	syscall
						
	addi $sp, $sp, 8
	lw $t4, 4($sp) 			# parent
	lw $s3, 0($sp) 			#load index of parent		

	beqz $t4, codeFile
								
	lw $t5, -16($t4) 		# right son
	sw $t5, 4($sp) 			# save right son to parent place on stack	
	sw $t2, 0($sp) 			#save index of right son
				
					#we have parent index in $s3 
				
loopToWriteParentCode:  		#write code of parent
	lb $s4, arrayStatistic($s3)
	beq $s4, '2', endOfParentCode
	sb $s4, arrayStatistic($t2)
	addi $s3, $s3, 1
	addi $t2, $t2, 1
	j loopToWriteParentCode
endOfParentCode:
	sb $s1, arrayStatistic($t2) 	#save 1 to arrayStatistic
	addi $t2, $t2, 1	
	sb $s2, arrayStatistic($t2) 	#save 2 to arrayStatistic
	addi $t2, $t2, 1
				
	move $t4, $t5 			# we need this line to beq in continue1
	lw $t3, -12($t5)
				
	j loopPutToStack
codeFile:
	addi $t0, $zero, 0 		#number of letters important because first to write in file

		 
	lw $s5, array2Size($t0)
	addi $t0, $zero, 0 		#number of letters important because first to write in file
		 
	addi $t1, $zero, 0 		#counter for headerOfFile
	sb $s5, headerOfFile($t1)
	addi $t1, $t1, 1
			
	addi $t2, $zero, 0 		#counter for letters
loopToAddLetterAndCode: 		#we want to add to header letters and code of each one 
			
	lbu $t3, array2($t2) 		# load letter
	addi $t2, $t2, 1 
	bgt $t2, $s5 endOfCreatingHeader 
				
	sb $t3, headerOfFile($t1) 	# store letter
	addi $t1, $t1, 1	 	# we left one empty byte for lenght of code	 
	addi $t6, $t1, 1 		#counter for store code

	mul $t3, $t3, 4
	lw $t4, arrayCodeAddress($t3) 	#take an index of code 
	addi $t7, $zero, 0 		#counter of code
				
					#t0 - we are going to write in it a bits of code
	addi $t0, $zero, 0	 
	addi $s0, $zero, 0 		#s0 - couter of bits
				
loopWriteLetterCode: 			#take code of a letter
	lb $t5, arrayStatistic($t4)
	addi $t4, $t4, 1
	beq $t5, '2', fillLastByte
	beq $s0, 7, addByte
	addi $s0, $s0, 1 
	addi $t7, $t7, 1
					
	sll $t0, $t0, 1
	beq $t5, '0', loopWriteLetterCode
	addi $t0, $t0, 1
	j loopWriteLetterCode
addByte:
	sll $t0, $t0, 1
	beq $t5, '0', storeByte
	addi $t0, $t0, 1
storeByte:
	sb $t0, headerOfFile($t6)
	addi $t0, $zero, 0
	addi $t6, $t6, 1
	addi $s0, $zero, 0
	addi $t7, $t7, 1
	j loopWriteLetterCode
				
fillLastByte:
	beqz $s0, fillCodeLenght 
	addi $s7, $zero, 8
	sub $s7, $s7, $s0
loopForSLL:
	beqz $s7, fillLastByteContinue
	sll $t0, $t0, 1
	addi $s7, $s7, -1
	j loopForSLL
fillLastByteContinue:
	beqz $s0, fillCodeLenght
	sb $t0, headerOfFile($t6)
	addi $t6, $t6, 1
fillCodeLenght:
	sb $t7, headerOfFile($t1)
	move $t1, $t6
	j loopToAddLetterAndCode
		
endOfCreatingHeader:		
			
					#Open (for writing) a file that does not exist
	li   $v0, 13       		# system call for open file
	la   $a0, fileOutName     	# output file name
	li   $a1, 1        		# Open for writing (flags are 0: read, 1: write)
	li   $a2, 0        		# mode is ignored
	syscall            		# open a file (file descriptor returned in $v0)
	move $s6, $v0      		# save the file descriptor 
			
					#Write to file header
	li   $v0, 15       		# system call for write to file
	move $a0, $s6     	 	# file descriptor 
	la   $a1, headerOfFile   	# address of buffer from which to write
	move   $a2, $t1       		# hardcoded buffer length
	syscall            		# write to file
			
	addi $t1, $zero, 0
	addi $t0, $zero, 0 		# Bajt
	addi $s0, $zero, 0 		#counter for codedText
	addi $s1, $zero, 0 		#counter for Bajt
	lw $s4, textLenght
loopToText:				# for whole text
	lbu $t2, text($t1)
	addi $t1, $t1, 1
	bgt $t1, $s4, writeLastByte
	mul $t2, $t2, 4
	lw $t3, arrayCodeAddress($t2) 	#take an index 
	move $t6, $t3
	la $t5, arrayStatistic
	add $t5, $t5, $t3	
				
loopForCodeOfLetter:			# for code of letter
	lb $t4, arrayStatistic($t3)
	beq $t4, '2', loopToText
	addi $t3, $t3, 1
	beq $s1, 7, bajtToCodedText
					
	sll $t0, $t0, 1
	addi $s1, $s1, 1
	beq $t4, '0', loopForCodeOfLetter
	addi $t0, $t0, 1  
	j loopForCodeOfLetter
				
bajtToCodedText:
	sll $t0, $t0, 1
	addi $s1, $zero, 0
	beq $t4, '0', storeBajt
	addi $t0, $t0, 1
storeBajt:
	sb $t0, codedText($s0)
	addi $s0, $s0, 1
	addi $t0, $zero, 0
	j loopForCodeOfLetter
writeLastByte:
	beqz $s1, writeCodedTextToFile
	addi $s7, $zero, 8
	sub $s7, $s7, $s1
loopForSLL2:
	beqz $s7, writeLastByteContinue
	sll $t0, $t0, 1
	addi $s7, $s7, -1
	j loopForSLL2
writeLastByteContinue:
	sb $t0, codedText($s0)
	addi $s0, $s0, 1
				
writeCodedTextToFile:				
	li   $v0, 15      	 	# system call for write to file
	move $a0, $s6      		# file descriptor 
	la $a1, codedText  		# address of buffer from which to write
	move   $a2, $s0    		# hardcoded buffer length
	syscall            		# write to file			
			
					#Close the file
	li   $v0, 16       		# system call for close file
	move $a0, $s6      		# file descriptor to close
	syscall            		# close file
	j exit
				 	
decode:
					# Open (for reading) a file that does not exist
	li   $v0, 13      	 	# system call for open file	
	la   $a0, fileName    		# output file name	
	li   $a1, 0        		# Open for reading (flags are 0: read, 1: write)
	li   $a2, 0        		# mode is ignored
	syscall            		# open a file (file descriptor returned in $v0)
	move $s0, $v0      		# save the file descriptor 
		
	move $a0, $s0      		# file descriptor 
	la   $a1, buffer   		# address of buffer from which to read
	li   $a2,  10    		# hardcoded buffer length

	addi $t4, $zero, 0 		#counter of codedText	
	
loopToReadFromFile2:
	li   $v0, 14       		# system call for reading from file
	syscall            		# read from file
		
	beqz $v0, changeText 		# endLoop17- decode text which we have already read
	move $t0, $a1
		
loopToReadFromBuffer2:
	lbu $t1, ($t0)
	sb $t1, codedText($t4) 
				
	addi $t0, $t0, 1
	addi  $t4, $t4, 1
	sub $t2, $t0, $a1
	bge $t2, $v0, loopToReadFromFile2
		
	j loopToReadFromBuffer2
changeText:
	addi $s0, $zero, '0'
	addi $s1, $zero, '1'
	addi $t0, $zero, 0 		#counter for codedText number of bajts
	addi $t2, $zero, 0 		#counter for text
	addi $t5, $zero, 128 		# mask
	addi $s2, $zero, 0 		#counter of read letters
		
	lbu $s4, codedText($t0) 	#remember number of letters
	addi $t0, $t0,1
	sb $s4, text($t2)
	addi $t2, $t2, 1
loopForChangingHeader:
	beq $s2, $s4, loopForChangingText
		
	lbu $t1, codedText($t0) 	#read letter
	addi $t0, $t0,1
	addi $s2, $s2, 1
	sb $t1, text($t2) 		#store letter
	addi $t2, $t2, 1
		
	lbu $s3, codedText($t0) 	#read code lenght
	addi $t0, $t0,1
	sb $s3, text($t2) 		#store code lenght
	addi $t2, $t2, 1
	addi $s5, $zero, 0 		#counter from 0 to code lenght
	j readBits1
			
loopForSpreadCode:
	beq $s5, $s3, loopForChangingHeader #in $s3 we've got letter code lenght
	beq $t3, 8, readBits1
	addi $t3, $t3, 1
	addi $s5, $s5, 1
			
	and $t6, $t5, $t1
	sll $t1, $t1, 1
	beqz $t6, storeZero1
	sb $s1, text($t2)
	addi $t2, $t2, 1
	j loopForSpreadCode
storeZero1:  
	sb $s0, text($t2)
	addi $t2, $t2, 1
	j loopForSpreadCode
						
readBits1:
	addi $t3, $zero, 0 		#couter of bits	
	lbu $t1, codedText($t0) 	#read first bajt of code
	addi $t0, $t0,1
	j loopForSpreadCode
				
loopForChangingText:
	beq $t0, $t4, decodeHeader
	lbu $t1, codedText($t0)
	addi $t0, $t0, 1
	addi $t3, $zero, 0 		#couter of bits
readBits:
	beq $t3, 8, loopForChangingText
	and $t6, $t5, $t1
	sll $t1, $t1, 1
	beqz $t6, storeZero
	sb $s1, text($t2)
	addi $t2, $t2, 1
	addi $t3, $t3, 1
	j readBits
storeZero:  
	sb $s0, text($t2)
	addi $t2, $t2, 1
	addi $t3, $t3, 1
	j readBits
			
		 		
decodeHeader:
	addi $t0, $zero, 0 		#counter for reading text
	addi $t3, $zero, 0 		#counter for array2 in which we want keep letters 
	la $t4, array2  		# $t4-address of begining array2  
		
	lbu $t1, text($t0) 		#now in $t1 we have got counter of letters
	addi $t0, $t0, 1
		
	subu $sp, $sp, 12 		#place for root
	move $t9, $sp  			#remember root address 
		
loopForDecodingLetters2: 		#this loop is for decoding letters
	beqz $t1, endBuildTree
	addi $t1, $t1, -1
			
	lbu $t2, text($t0) 		# $t2-letter
	addi $t0, $t0, 1
	sb $t2, array2($t3)
	add $t5, $t4, $t3 		#$t5 address of letter
	addi $t3, $t3, 1
			
	lbu $t2, text($t0) 		# $t2- lenght of a code
	addi $t0, $t0, 1
		
	move $t7, $t9 			# $t7 is a temp node (root at begin)
loopForReadingCode: 			#this loop is for reading code 
	beqz $t2, loopForDecodingLetters2
	addi $t2, $t2, -1
				
	lbu $t6, text($t0) 
	addi $t0, $t0, 1
				
	beq $t6, '1', checkRight
					#check left (not null)
	lw $t8, 4($t7)
	beqz $t8, createNewLeftNode
	move $t7, $t8	
	j loopForReadingCode
checkRight:
	lw $t8, 8($t7)
	beqz $t8, createNewRightNode
	move $t7, $t8	
	j loopForReadingCode
createNewLeftNode:
	subu $sp, $sp, 12
	sw $sp, 4($t7)
	move $t7, $sp	
	bnez $t2, loopForReadingCode
					#we need to add address of letter to node
	sw $t5, 0($t7)
	j loopForDecodingLetters2
createNewRightNode:
	subu $sp, $sp, 12
	sw $sp, 8($t7)
	move $t7, $sp	
	bnez $t2, loopForReadingCode
					#we need to add address of letter to node
	sw $t5, 0($t7)
	j loopForDecodingLetters2
				
endBuildTree: 				#start decoding here in $t9 we have root
	move $t7, $t9
	addi $t5, $zero, 0 		# second counter for 
		 
loopDecodingText:
	lbu $t1, text($t0)
	beqz $t1, endOfDecoding
	addi $t0, $t0, 1
			
	beq $t1, '1', goRight
					#go to left
	lw $t2, 4($t7)
	beqz $t2, readLetterL
	move $t7, $t2
	j loopDecodingText	
goRight:
	lw $t2, 8($t7)
	beqz $t2, readLetterR
					
	move $t7, $t2
	j loopDecodingText
readLetterL:
	lw $t3, 0($t7)	
	lbu $t4, ($t3)
	sb $t4, text($t5)
	addi $t5, $t5, 1
			
	lw $t7, 4($t9)
	j loopDecodingText
readLetterR:
	lw $t3, 0($t7)
	lbu $t4, 0($t3)
	sb $t4, text($t5)
	addi $t5, $t5, 1
			
	lw $t7, 8($t9)	
	j loopDecodingText
endOfDecoding:
		
	li $v0, 4
	la $a0, msg1
	syscall
		
	li $v0, 8
	la $a0, fileName2
	li $a1, 100
	syscall
		
	addi $t0, $zero, '\n'
	move $t1, $a0
readLoop1:
	lbu $t2, ($t1)
	beq $t2, $t0, swap1
	addi $t1, $t1, 1
	j readLoop1
swap1:
	sb $zero, ($t1)
	bnez $t3, writeToFileDecodedText
		
writeToFileDecodedText:	
					#Open (for writing) a file that does not exist
	li   $v0, 13       		# system call for open file
	la   $a0, fileName2     	# output file name
	li   $a1, 1        		# Open for writing (flags are 0: read, 1: write)
	li   $a2, 0        		# mode is ignored
	syscall            		# open a file (file descriptor returned in $v0)
	move $s6, $v0      		# save the file descriptor 
		
					#Write to file header
	li   $v0, 15       		# system call for write to file
	move $a0, $s6      		# file descriptor 
	la   $a1, text   		# address of buffer from which to write
	move   $a2, $t5     		# hardcoded buffer length
	syscall            		# write to file					
					#Close the file 
	li   $v0, 16       		# system call for close file
	move $a0, $s6      		# file descriptor to close
	syscall            		# close file

exit:
	li $v0, 10
	syscall 
