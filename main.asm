.data     #TODO: rewrite macros 
	newline: .asciiz 	"\n"
	tab: .asciiz		"\t"
	op_input_buffer: .space  2
	
.macro endl
	
	li $v0, 4
	la $a0, newline
	syscall
.end_macro

.macro ptab
	
	li $v0, 4
	la $a0, tab
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

.macro print_int32 (%x)   # avoid using v0 as input
	li  $v0, 1
	add $a0, $zero, %x
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
	abs $s5, $s0
	abs $s6, $s3        
	
	addi $sp, $sp, -16
	sw   $s5, 12($sp)	#op1
	sw   $s6, 8($sp)	#op2
	sw   $t0, 4($sp)	#operator
	sw   $s4, 0($sp)     # SIGN
	
	#load paramaters
	la $a0, ($s5)       # op1
	la $a1, ($s6)       # op2 
	
	#call operations
	beq $t0, 0, goto_mul       # if 0 then multiply 
	beq $t0, 1, goto_div       # else if 1 divide
	
goto_mul: 
	
	jal _mul             #return a1 (lo) and a2(hi)
	la $a0, ($s4)     #SIGN
	jal negate      # negate if SIGN = 1
	
	print_int32($a1)    
	ptab
	print_int32($a2)
	
	j main_exit
	
goto_div:
	
	jal _div
	
	print_int32($a1)    
	ptab
	print_int32($a2)
		
	j main_exit
	
main_exit:

	print("\n")
	li $v0, 10
	syscall
	
	
####################################################################################################################################	
get_user_input:
	#returns op1 in $v0, 
		#op2 in $v1,
		#op  in $a0 
	
	print("Operand 1:\t")
	li $v0, 5		#get op1
	syscall
	move $t0, $v0		#store op1 in $t0
	
	get_oper8:
	
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
		j get_oper8       # retry
	
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
####################################################################################################################################
negative:
	
	li $v0, 1
	
	jr $ra
#end negative
####################################################################################################################################
_mul:  
	#dealing with unsigned int32
	li $s0, 0        # lw product
   	li $s1, 0        # hw product
   	
   	beq $a0, $zero, mul_exit
    	beq $a1, $zero, mul_exit
    	li $s2, 0        # extend multiplicand to 64 bits

	mul_loop:
	
    		andi $t0, $a1, 1    # get LSB of multiplier
   		beq $t0, $0, next   # skip if even
   		# use addu to avoid exceptions
    		addu $s0, $s0, $a0  # lw(product) += lw(multiplicand)
    		sltu $t0, $s0, $a0  # catch carry-out(0 or 1)    (s0 < a0)
    		
    		addu $s1, $s1, $t0  # hw(product) += carry     
    		addu $s1, $s1, $s2  # hw(product) += hw(multiplicand)
    		
	next:
    		
    		srl $t0, $a0, 31    # copy bit from lw to hw
    		sll $a0, $a0, 1     # shift multiplicand left
    		sll $s2, $s2, 1
    		addu $s2, $s2, $t0

    		srl $a1, $a1, 1     # shift multiplier right
    		bne $a1, $zero, mul_loop

	mul_exit:
		la $a1, ($s0)	#lo
		la $a2, ($s1) #hi
		
		jr $ra
    	
###################################################################################################################################
_div:

	la $s0, ($a0)   # remainder = dividend
	la $s1, ($a1)	  # divisor
	li $s2, 0       # counter
	
	sll $s0, $s0, 1   # initial REM shift left 
	
	div_loop:
	
		bge $s2, 16, div_exit   
		srl $t0, $s0, 16       # left half of REM
		sub $t0, $t0, $s1      # REM = REM - divisor
		
		bge $t0, 0, p          # if REM >=0 then branch
		sll $s0, $s0, 1        # 
		
		j cont
		
	p:
		sll $s0, $s0, 16
		srl $s0, $s0, 16
		
		
		sll $t0, $t0, 16
		addu $s0, $s0, $t0
		
		sll $s0, $s0, 1        # shift left REM
		addi $s0, $s0, 1       # set LSB to 1 
		
	cont:
	
		addi $s2, $s2, 1
		j div_loop
		
	div_exit:
		
		andi $a1, $s0, 0x0000FFFF   # quotient
		andi $a2, $s0, 0xFFFF0000   # remainder
		srl $a2, $a2, 17
		
		jr $ra
###################################################################################################################################
negate:

	bne $a0, 1, negate_exit
	subu $a1, $zero, $a1
	subu $a2, $zero, $a2
	negate_exit:	
	
		jr $ra
###################################################################################################################################
