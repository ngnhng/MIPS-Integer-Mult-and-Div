# HO CHI MINH UNIVERSITY OF TECHNOLOGY

# COMPUTER ARCHITECTURE 211 ASSIGNMENT
# IMPLEMENTATION OF 32-BIT INTEGER MULTIPLICATION AND DIVISION IN MIPS
# by NGUYEN NHAT NGUYEN - HUYNH TUAN KIET - LY THANH HUNG


.data  # put .word data first to avoid boundary issues
	
	newline: .asciiz 	"\n"
	tab: .asciiz		"\t"
	input_buffer: .space  2
	
# AVOID BOILERPLATE CODE BY DEFINING MACROS FOR REPETITIVE TASKS
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

.macro print_string (%str)

	.data	
		str_:	.asciiz	%str
	.text
		li $v0, 4
		la $a0, str_
		syscall
.end_macro

.macro print_int32 (%x)   # avoid passing v0

	li  $v0, 1
	add $a0, $zero, %x
	syscall
	
.end_macro

.text

main:
	print_string("\n\n\n NEW RUN:\n\n")
	jal get_user_input  		# return v0, a0, v1 (op1, op, op2)
	 
	la $s0, ($v0)
	la $t0, ($a0)
	la $s3, ($v1)	
	
	#get sign of op1          #TODO: consider branch for division of 0
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
	
	jal _mul             # return a1 (lo) and a2(hi)
	la $a0, ($s4)        # get SIGN
	jal negate           # negate if SIGN = 1
	
	print_int32($a1)    
	ptab
	print_int32($a2)
	
	j main_exit
	
goto_div:
	
	jal _div             # return a1 (quotient) and a2(remainder)
	
	print_int32($a1)    
	ptab
	print_int32($a2)
		
	j main_exit
	
main_exit:

	li $v0, 10
	syscall
	
	
####################################################################################################################################	
get_user_input:
	
	print_string("Operand 1:\t")
	li $v0, 5		#get op1
	syscall
	move $t0, $v0		#store op1 in $t0
	
	get_oper8:
	
		print_string("Operator ('*' or '/'):\t")
	
		li $v0, 8		#get op character
		la $a0, input_buffer
		li $a1, 2            # one for char and one for \0
		syscall		
		endl
		la $t3, input_buffer # load buffer		
		lb $t3, 0($t3)       # get the ascii code
	
		#branching
		beq $t3, 0x2A, code_mul       #42 ascii
		beq $t3, 0x2F, code_div       #47 ascii
	
		#print bad character string
		print_string("ONLY '*', AND '/' ARE ALLOWED\n")
		j get_oper8       # retry
	
	code_mul:
		li $t1, 0
		j valid_oper8
	code_div:
		li $t1, 1
		j valid_oper8
	
	valid_oper8:
	
		print_string("Operand 2:\t")
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

####################################################################################################################################
get_sign:

	andi $v0, $a0, 0x80000000	# GET MSB
	srl  $v0, $v0, 31	

	jr $ra 

####################################################################################################################################
negative:
	
	li $v0, 1
	
	jr $ra

####################################################################################################################################
_mul:  
	# THE PRODUCT AND MULTIPLICAND MAY OVERFLOW DUE TO SHIFTING LEFT
	# Solution:
		# USE TWO 32-BIT REGISTERS FOR HI AND LO, SIMILAR TO THE BASE MULT, MULTU INSTRUCTIONS.
		# DEFINE A SUBROUTINE TO DISPLAY THE RESULT FROM BOTH HI AND LO REGS COMBINED.
		
   	# if 0 occurs then quick exit
   	beq $a0, $zero, mul_exit     # MULTIPLICAND
    	beq $a1, $zero, mul_exit     # MULTIPLIER
    	
    	li $s0, 0        # lo reg of PRODUCT
   	li $s1, 0        # hi reg of PRODUCT
    	li $s2, 0        # multiplicand expansion

	mul_loop:
	
    		andi $t0, $a1, 1    # get LSB of MULTIPLIER
   		beq $t0, $0, next   # IF t0 is even then branch
   		
   		# ELSE
   		# use addu to avoid exceptions
    		addu $s0, $s0, $a0  # PRODUCT_lo += MULTIPLICAND_lo
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
	# || REMAINDER | QUOTIENT ||  --> || REMAINDER_upper | REMAINDER_lower||
       # Remainder and Quotient constitute two halves of a 64-bit register
       # Solution:
       	# USE TWO 32-BIT REGISTERS
       	# DEFINE A METHOD FOR SHIFTING BETWEEN TWO REGS
         
	la $s0, ($a0)   # REMAINDER_lower = DIVIDEND
	la $s1, ($a1)	  # DIVISOR
	li $s2, 0       # COUNTER
	li $s3, 0	  # REMAINDER_upper extension
	
	# initial - REMAINDER shift left
	
	andi $t0, $s0, 0x80000000     # get MSB of REMAINDER_lower
	srl $t0, $t0, 31              # t0 is temporary REMAINDER_upper
	sll $s3, $s3, 1               # shift left upper if needed
	addu $s3, $s3, $t0            # s3 is the actual REMAINDER_upper 
	sll $s0, $s0, 1               # complete the initial shift left
	
	div_loop:
	
		bge $s2, 32, div_exit  # loop 32 times for 32-bit division
		
		la $t0, ($s3)          # t0 = REMAINDER_upper  -> RESTORE REMAINDER_upper
		sub $t0, $t0, $s1      # REMAINDER_upper = REMAINDER_upper - DIVISOR
		
		# IF REMAINDER_upper >=0 then branch
		bge $t0, 0, sll_rem   
		
		# ELSE
		# boilerplate code but idc
		andi $t0, $s0, 0x80000000     #get MSB 
		srl $t0, $t0, 31
		sll $s3, $s3, 1               # shift left upper if needed
		addu $s3, $s3, $t0            
		sll $s0, $s0, 1
		
		j cont
		
	sll_rem:
	
		la $s3, ($t0)
		
		# boilerplate code but idc
		andi $t0, $s0, 0x80000000     #get MSB 
		srl $t0, $t0, 31
		sll $s3, $s3, 1               # shift left upper if needed
		addu $s3, $s3, $t0            
		sll $s0, $s0, 1
		
		addi $s0, $s0, 1      	 # set LSB of lower to 1 
		
	cont:
	
		addi $s2, $s2, 1
		j div_loop
		
	div_exit:
		
		la $a1, ($s0)   # quotient
		la $a2, ($s3)   # remainder
		srl $a2, $a2, 1  # final shift right
		
		jr $ra
###################################################################################################################################
negate:

	bne $a0, 1, negate_exit
	subu $a1, $zero, $a1
	subu $a2, $zero, $a2
	negate_exit:	
	
		jr $ra
###################################################################################################################################
