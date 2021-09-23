 .data    
    prompt1:    .asciiz      "Enter the first number: "
    prompt2:    .asciiz      "Enter the second number: "
    menu:      .asciiz      "Enter the number associated with the operation you want performed: 1 => add, 2 => subtract or 3 => multiply: "
    resultText:    .asciiz      "Your final result is: "
 .text
.globl main
main:
    #The following block of code is to pre-load the integer values representing the various instructions into registers for storage
    li $t3, 1    #This is to load the immediate value of 1 into the temporary register $t3
    li $t4, 2    #This is to load the immediate value of 2 into the temporary register $t4
    li $t5, 3    #This is to load the immediate value of 3 into the temporary register $t5
 #asking the user to provide the first number
    li $v0, 4     #command for printing a string
    la $a0, prompt1 #loading the string to print into the argument to enable printing
    syscall      #executing the command
    
    #the next block of code is for reading the first number provided by the user
    li $v0, 5    #command for reading an integer
    syscall      #executing the command for reading an integer
    move $t0, $v0     #moving the number read from the user input into the temporary register $t0
    
    #asking the user to provide the second number
    li $v0, 4    #command for printing a string
    la $a0, prompt2    #loading the string into the argument to enable printing
    syscall      #executing the command
    
    #reading the second number to be provided to the user
    li $v0, 5    #command to read the number  provided by the user
    syscall      #executing the command for reading an integer
    move $t1, $v0    #moving the number read from the user input into the temporary register $t1

    li $v0, 4    #command for printing a string
    la $a0, menu    #loading the string into the argument to enable printing
    syscall      #executing the command

    #the next block of code is to read the number provided by the user
    li $v0, 5    #command for reading an integer
    syscall      #executing the command
    move $t2, $v0    #this command is to move the integer provided into the temporary register $t2

    beq $t2,$t3,addProcess    #Branch to 'addProcess' if $t2 = $t3
    beq $t2,$t4,subtractProcess #Branch to 'subtractProcess' if $t2 = $t4
    beq $t2,$t5,multiplyProcess #Branch to 'multiplyProcess' if $t2 = $t5

 addProcess:
    add $t6,$t0,$t1    #this adds the values stored in $t0 and $t1 and assigns them to the     temporary register $t6
    
    #The following line of code is to print the results of the computation above
    li $v0,4    #this is the command for printing a string
    la $a0,resultText    #this loads the string to print into the argument $a0 for printing
    syscall      #executes the command
    
    #the following line of code prints out the result of the addition computation
    li $v0,1
    la $a0, ($t6)
    syscall
    
    li $v0,10 #This is to terminate the program
    syscall

 subtractProcess:
    sub $t6,$t0,$t1 #this adds the values stored in $t0 and $t1 and assigns them to the temporary register $t6
    li $v0,4    #this is the command for printing a string
    la $a0,resultText    #this loads the string to print into the argument $a0 for printing
    syscall      #executes the command
    
    #the following line of code prints out the result of the addition computation
    li $v0,1
    la $a0, ($t6)
    syscall
    
    li $v0,10 #This is to terminate the program
    syscall

 multiplyProcess:
    mul $t6,$t0,$t1 #this adds the values stored in $t0 and $t1 and assigns them to the temporary register $t6
    li $v0,4    #this is the command for printing a string
    la $a0,resultText    #this loads the string to print into the argument $a0 for printing
    syscall      #executes the command
    
    #the following line of code prints out the result of the addition computation
    li $v0,1
    la $a0, ($t6)
    syscall
    
    li $v0,10 #This is to terminate the program
    syscall
    # test commit

