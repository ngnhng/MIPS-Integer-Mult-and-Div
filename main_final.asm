# HO CHI MINH CITY UNIVERSITY OF TECHNOLOGY

# COMPUTER ARCHITECTURE 211 ASSIGNMENT
# IMPLEMENTATION OF 32-BIT INTEGER MULTIPLICATION AND DIVISION IN MIPS
# by NGUYEN NHAT NGUYEN - HUYNH TUAN KIET - LY THANH HUNG


.data  # put .word data first to avoid boundary issues when using lw, sw
	
	newline: .asciiz 	"\n"
	input_buffer: .space  2
	
# AVOID BOILERPLATE CODE BY DEFINING MACROS FOR REPETITIVE TASKS
.macro endl
	li $v0, 4
	la $a0, newline
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

# avoid passing v0
.macro print_int32 (%x)   
	li  $v0, 1
	add $a0, $zero, %x
	syscall
.end_macro

.macro print_hex (%x)
	li  $v0, 34
	add $a0, $zero, %x
	syscall
.end_macro

.macro print_bin (%x)
	li  $v0, 35
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
	
	srl $t1, $s0, 31      # store sign of op1
	srl $t2, $s3, 31      # store sign of op2
	
	# save signs to stack
	addi $sp, $sp, -8
	sw   $t1, 4($sp)	
	sw   $t2, 0($sp)
	
	# clear temp after saving
	li $t1, 0
	li $t2, 0      
	
	#get abs()
	abs $s5, $s0
	abs $s6, $s3        
	
	#load paramaters
	la $a0, ($s5)       # op1
	la $a1, ($s6)       # op2 
	
	
	#call operations
	beq $t0, 0, goto_mul       # if 0 then multiply 
	beq $t0, 1, goto_div       # else if 1 divide
	
goto_mul: 
	
	jal _mul             # return a1 (lo) and a2(hi)
	
	lw $s1, 4($sp)      # load and free stack
	lw $s2, 0($sp)
	addi $sp, $sp, 8
	
	la $a0, ($s1)
	la $a3, ($s2)		     
	jal negate           
	
	jal print_mul_result
	
	j main_exit
	
goto_div:
	
	jal _div             # return a1 (quotient) and a2(remainder)	
	
	lw $s1, 4($sp)      # load and free stack
	lw $s2, 0($sp)
	addi $sp, $sp, 8
	
	la $a0, ($s1)
	la $a3, ($s2)		 
	jal negate       # negate according to saved signs
	
	jal print_div_result
	
main_exit:	
	li $v0, 10
	syscall
	
####################################################################################################################################	
get_user_input:
	
	print_string("Operand 1:\t")
	li $v0, 5		#get op1
	syscall
	add $t0, $zero, $v0		#store op1 in $t0
	
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
		print_string("Please enter '*' or '/'\n")
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
		beq $v0, 0, div_by_0
		move $t2, $v0		#store op2 in $t0

		#store return values
		la $v0, ($t0)		#store op1
		la $a0, ($t1)		#store op
		la $v1, ($t2)		#store op2
	
		#clear temp registers
		li $t0, 0
		li $t1, 0
		li $t2, 0
		li $t3, 0
	
		jr $ra	
	div_by_0:
		print_string("\nDividing by Zero is undefined.\n")
		print_string("Please enter another divisor!\n\n")
		j valid_oper8
		 
####################################################################################################################################
get_sign:

	andi $v0, $a0, 0x80000000	# GET MSB
	srl  $v0, $v0, 31	

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
		# check even/oddness of MULTIPLIER
		andi $t0, $a1, 1      # get LSB
		beq $t0, 0, mul_cont  # if EVEN then branch
		
		# ELSE
		addu $s0, $s0, $a0    # PROD = PROD + MULTIPLICAND
		
		# test whether if PROD can be stored in a 32-bit register
		sltu $t0, $s0, $a0    # catch carry bit ( occurs when s0 = 0xFFFFFFFF + a0 = s0 + a0, hence s0 < a0)
		addu $s1, $s1, $t0    # push carry to upper of PRODUCT
		addu $s1, $s1, $s2    # also add upper MULTIPLICAND
		
		mul_cont:
			# shift left MULTIPLICAND
			andi $t0, $a0, 0x80000000    # get MSB
			srl $t0, $t0, 31
			sll $a0, $a0, 1	    # shift left l?er
			sll $s2, $s2, 1          # shift left upper
			addu $s2, $s2, $t0       # push MSB of lower to upper
			
			#shift right MULTIPLIER
			srl $a1, $a1, 1
			beq $a1, $zero, mul_exit    # if MULTIPLIER == 0 then break
			j mul_loop
			
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
        
       beq $a1, $zero, div_by_0 
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
	  # 4 cases : 0-1, 1-0, 1-1 and 0-0 ; the negation varies with each cases
	sub $t0, $a0, $a3
	beq $t0, 0, both    # 1-1 and 0-0
	
	beq $a0, 1, rem_neg  # 1-0
	
	subu $a1, $zero, $a1  # 0-1
	
	j negate_exit
	
rem_neg:
	subu $a1, $zero, $a1
	subu $a2, $zero, $a2
	
	j negate_exit
	
both: 
	add $t1, $a0, $a3 
	beq $t1, 0, negate_exit    # 0-0	
	subu $a2, $zero, $a2
	
negate_exit:	
	
	jr $ra
###################################################################################################################################
print_mul_result:

	la $t0, ($a1)
	la $t1, ($a2)
	
	print_string("Choose display mode (D/H/B): ")
	li $v0, 8		#get op character
	la $a0, input_buffer
	li $a1, 2            # one for char and one for \0
	syscall		
	endl
	la $t2, input_buffer # load buffer		
	lb $t2, 0($t2)       # get the ascii code
	
	#branching
	beq $t2, 0x44, decm
	beq $t2, 0x48, hexm
	beq $t2, 0x42, binm
	
	decm:                      # return nothing
		print_string("lo: ")
		print_int32($t0)
		endl
		print_string("hi: ")
		print_int32($t1)
		
		jr $ra
	hexm:
		print_string("lo: ")
		print_hex($t0)
		endl
		print_string("hi: ")
		print_hex($t1)
		
		jr $ra
	binm:
		print_string("lo: ")
		print_bin($t0)
		endl
		print_string("hi: ")
		print_bin($t1)
		
		jr $ra
	
	
###################################################################################################################################
print_div_result:
	
	la $t0, ($a1)
	la $t1, ($a2)
	
	print_string("Choose display mode (D/H/B): ")
	li $v0, 8		#get op character
	la $a0, input_buffer
	li $a1, 2            # one for char and one for \0
	syscall		
	endl
	la $t2, input_buffer # load buffer		
	lb $t2, 0($t2)       # get the ascii code
	
	#branching
	beq $t2, 0x44, dec
	beq $t2, 0x48, hex
	beq $t2, 0x42, bin
	
	dec:                      # return nothing
		print_string("Quotient: ")
		print_int32($t0)
		endl
		print_string("Remainder: ")
		print_int32($t1)
		
		jr $ra
	hex:
		print_string("Quotient: ")
		print_hex($t0)
		endl
		print_string("Remainder: ")
		print_hex($t1)
		
		jr $ra
	bin:
		print_string("Quotient: ")
		print_bin($t0)
		endl
		print_string("Remainder: ")
		print_bin($t1)
		
		jr $ra
###################################################################################################################################
