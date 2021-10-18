.data     #TODO: rewrite macros 
	newline: .asciiz 	"\n"
	tab: .asciiz		"\t"
	op_input_buffer: .space  2
	
.macro endl
	li $v0, 4
	la $a0, newline
	syscall
.end_macro

.macro print (%str)
	.data	
		str_:	.asciiz	%str
	.text
		li $v0, 4
		la $a0, str_
		syscall
.end_macro
.text

main:
	print("\n\n\n NEW RUN:\n\n")
	jal get_user_input  		# return v0, a0, v1 (op1, op, op2)
	 
	la $s0, ($v0)
	la $t0, ($a0)
	la $s3, ($v1)	
	
	#get sign of op1          #TODO: consider branch for division of 0s
	la $a0, ($s0)
	jal get_sign			#return v0 - sign bit
	la $t1, ($v0)
	
	#get sign of op2
	la $a0, ($s3)
	jal get_sign			#return v0 - sign bit
	la $t2, ($v0)
	
	li  $s4, 0                  # SIGN = 0 
	bne $t1, $t2, negative      # if sign bits are different then SIGN = 1
	la $s4, ($v0)
		
	#get abs()
	la $a0, ($s0)
	jal get_abs           #return a0 = abs(x)
	la $s5, ($a0)
	
	la $a0, ($s3)
	jal get_abs           #return a0 = abs(x)
	la $s6, ($a0)        
	
	addi $sp, $sp, -16
	sw   $s5, 12($sp)	#op1
	sw   $s6, 8($sp)	#op2
	sw   $t0, 4($sp)	#operator
	sw   $s4, 0($sp)     # SIGN
	
	#load paramaters
	la $a0, ($s5)       # op1
	la $a1, ($s6)       # op2 
	
	#clear registers
	li $s0, 0
	li $s1, 0
	li $s3, 0
	li $s5, 0
	li $s6, 0
	
	#call operations
	beq $t0, 0, goto_mul       # if 0 then multiply 
	beq $t0, 1, goto_div       # else if 1 divide
	
goto_mul: 
	
	jal _mul
	
	
goto_div:
	
	jal _div
	
	# ...
	
	
	
	
	li $v0, 10
	syscall
	
	
####################################################################################################################################	
get_user_input:
	#returns op1 in $v0, 
		#op2 in $v1,
		#op  in $a0 (3 mult, 4 div)
	
	print("Operand 1:\t")
	li $v0, 5		#get op1
	syscall
	move $t0, $v0		#store op1 in $t0
	
	get_operand:
		print("Operator:\t")
	
		li $v0, 8		#get op character
		la $a0, op_input_buffer
		li $a1, 2
		syscall		
		endl		
	
		la  $t3, op_input_buffer	#temporarily get start address for character input
		lb  $t3, 0($t3)			#get ASCII code for character entered
	
		#branching
		beq $t3, 0x2A, code_mul       #42 ascii
		beq $t3, 0x2F, code_div       #47 ascii
	
		#print bad character string
		print("ONLY '*', AND '/' ARE ALLOWED\n")
		j get_operand       # retry
	
	code_mul:
		li $t1, 0
		j valid_operand
	code_div:
		li $t1, 1
		j valid_operand
	
	valid_operand:
	
		print("Operand 2:\t")
		li $v0, 5		#get op2
		syscall
		move $t2, $v0		#store op2 in $t0

		#store return values
		la $v0, ($t0)		#store op1
		la $a0, ($t1)		#store op
		la $v1, ($t2)		#store op2
	
		#clear used registers
		li $t0, 0
		li $t1, 0
		li $t2, 0
		li $t3, 0
	
		jr $ra	
#end input

####################################################################################################################################
get_sign:

	andi $v0, $a0, 0x80000000	#clear all bits except for sign bit - aka 10000000000000000000000000000000
	srl  $v0, $v0, 31	

	jr $ra 
#end get_sign
###################################################################################################################################
get_abs:

	sra $t0,$a0,31   
	xor $a0,$a0,$t0   
	sub $a0,$a0,$t0
	li  $t0, 0
	
	jr $ra
#end get_abs
####################################################################################################################################
negative:
	
	li $v0, 1
	
	jr $ra
#end negative
###################################################################################################################################
_mul:
	li $s3, 0        # lw product
   	li $s4, 0        # hw product
   	beq $a0, $0, done
    	beq $a1, $0, done
    	li $s2, 0        # extend multiplicand to 64 bits

	loop:
    		andi $t0, $a1, 1    # get LSB of multiplier
   		beq $t0, $0, next   # skip if even
    		addu $s3, $s3, $a0  # lw(product) += lw(multiplicand)
    		sltu $t0, $s3, $a0  # catch carry-out(0 or 1)
    		addu $s4, $s4, $t0  # hw(product) += carry
    		addu $s4, $s4, $a1  # hw(product) += hw(multiplicand)
	next:
    
    		# shift multiplicand left
    		srl $t0, $a0, 31    # copy bit from lw to hw
    		sll $a0, $a0, 1
    		sll $a1, $a1, 1
    		addu $a1, $a1, $t0

    		srl $s0, $a0, 1     # shift multiplier right
    		bne $a0, $0, loop

	done:
    		jr $ra
	
###################################################################################################################################
_div:
