#=========================================================================
# 2D String Finder 
#=========================================================================
# Finds the matching words from dictionary in the 2D grid
# 
# Inf2C Computer Systems
# 
# Siavash Katebzadeh
# 8 Oct 2019
# 
#
#=========================================================================
# DATA SEGMENT
#=========================================================================
.data
#-------------------------------------------------------------------------
# Constant strings
#-------------------------------------------------------------------------

grid_file_name:         .asciiz  "2dgrid.txt"
dictionary_file_name:   .asciiz  "dictionary.txt"
newline:                .asciiz  "\n"
space:                  .asciiz  " "        
#-------------------------------------------------------------------------
# Global variables in memory
#-------------------------------------------------------------------------
# 
grid:                   .space 1057     # Maximun size of 2D grid_file + NULL (((32 + 1) * 32) + 1)
.align 4                                # The next field will be aligned
dictionary:             .space 11001    # Maximum number of words in dictionary *
                                        # ( maximum size of each word + \n) + NULL
# You can add your data here!
.align 4 
dictionary_idx:                  .space  4000 #store starting adresses of words in dict
.align 4 
dict_num_words:                  .space 4
.align 4 
total_grid_length:               .space 4
.align 4 
num_cols:                        .space 4
.align 4 
num_rows:                        .space 4

#=========================================================================
# TEXT SEGMENT  
#=========================================================================
.text

#-------------------------------------------------------------------------
# MAIN code block
#-------------------------------------------------------------------------

.globl main                     # Declare main label to be globally visible.
                                # Needed for correct operation with MARS
main:
#-------------------------------------------------------------------------
# Reading file block. DO NOT MODIFY THIS BLOCK
#-------------------------------------------------------------------------

# opening file for reading

        li   $v0, 13                    # system call for open file
        la   $a0, grid_file_name        # grid file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # open a file
        
        move $s0, $v0                   # save the file descriptor 

        # reading from file just opened

        move $t0, $0                    # idx = 0

READ_LOOP:                              # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # grid[idx] = c_input
        la   $a1, grid($t0)             # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(grid_file);
        blez $v0, END_LOOP              # if(feof(grid_file)) { break }
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP 
END_LOOP:
        sb   $0,  grid($t0)            # grid[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(grid_file)


        # opening file for reading

        li   $v0, 13                    # system call for open file
        la   $a0, dictionary_file_name  # input file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # fopen(dictionary_file, "r")
        
        move $s0, $v0                   # save the file descriptor 

        # reading from  file just opened

        move $t0, $0                    # idx = 0

READ_LOOP2:                             # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # dictionary[idx] = c_input
        la   $a1, dictionary($t0)       # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(dictionary_file);
        blez $v0, END_LOOP2             # if(feof(dictionary_file)) { break }
        lb   $t1, dictionary($t0)                             
        beq  $t1, $0,  END_LOOP2        # if(c_input == '\0')
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP2
END_LOOP2:
        sb   $0,  dictionary($t0)       # dictionary[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(dictionary_file)
#------------------------------------------------------------------
# End of reading file block.
#------------------------------------------------------------------
# COUNTLEN (GET TOTAL GRID COL COUNT)
la $s0, grid
la $s2, num_cols
li $s3, 0 #index
lb $s4, newline
Loopi:
add $t8, $s0, $s3 # index + base address
lb $t3, 0($t8)
beq $t3, $s4,EndOfCount #if char==newline -> leave
addi $s3,$s3, 1 #i++
j Loopi
EndOfCount:
sw $s3, 0($s2) #store number of columns

# GET TOTAL GRID LENGTH
la $s0, grid
li $s1, 0 #counter
lb $s4, newline
la $s2, total_grid_length #store counter here
whileL:
add $t3, $s0, $s1 #grid + counter 
lb $t5, 0($t3)
beqz $t5, endo
addi $s1,$s1,1
j whileL
endo:
sw $s1, 0($s2)

# GET TOTAL ROW COUNT
la $s0, grid
la $s2, num_rows #here the row count will be stored
lw $s3, total_grid_length #limit
li $s1, 0 #counter
li $s5, 0 #index
lb $t4, newline
forLoop:
beq $s5, $s3, final #exit for loop
add $t5, $s0, $s5 #grid+i
lb $t6, 0($t5) #grid[i]
addi $s5,$s5, 1 #index++
bne $t6, $t4, forLoop
addi $s1,$s1, 1 #counter++
j forLoop
final:
addi $s1, $s1,1
sw $s1, 0($s2)

##__________________________________________________________-

# MAIN FUNCTION
la $t0, dictionary 
la $t1, grid 
la $s2, dictionary_idx #base address - indicies array
la $s3, dict_num_words #number of words in a dictionary will be stored here
lb $s4, newline
li $s5, 0 #dict_idx=0 
li $s6, 0 #start_idx=0
li $s7, 0 #idx=0 
 #c_input - $s1
 
do_while:
add $s0, $t0, $s7 # dictionary[idx];
lb $s1, 0($s0) #c_input=dictionary[idx];
beq $s1, $zero, finito #break 
bne  $s1, $s4, skipp #if char is not equal to the newline, skip the if condition

ifnewline:
sw $s6, 0($s2) #dictionary_idx[dict_idx] = start_idx // store start_idx value in the array of indexes
addi $s5, $s5, 4 # dict_idx++ 
addi $s2, $s2, 4 #move in the dictionary_idx array
addi $s6, $s7, 1 #  start_idx = idx + 1 

skipp:
addi $s7, $s7, 1 #idx++
j do_while 

finito:
# dict_num_words = dict_idx
sw $s5, 0($s3) #store dict_num_words 

jal strfind_funct

j main_end

# PRINT WORD
Print:
  addi $sp, $sp, -32
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $s7, 28($sp)
    lb $s4, newline 
   
move $s0, $a3 #beginning address of the word
LoopInPrint:
lb $s1, 0($s0) #load the correct character to $t1
beq $s1, $zero, EndOfPrint #if the char is '\0' - end of word
beq $s1, $s4, EndOfPrint #if the char is a newline - end of word

#print the character
li $v0, 11
lb $a0, 0($s0) #load the correct character to $a0
syscall
addi $s0,$s0, 1 #move one byte further in the dictionary
j LoopInPrint

EndOfPrint:
# restore stack
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    addi $sp, $sp, 32
jr $ra

# _____________________________________________

#CONTAIN
# Make this function stack neutral:
contain_funct:
addi $sp, $sp, -32
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $s7, 28($sp)
    lb $s4, newline
    
move $s2, $s7 #grid + offset
move $s3, $s5 # *word

ContainLoop: 
lb $t2, 0($s2) #load char from dict
lb $t3, 0($s3) #load char from grids

bne $t2, $t3, NotEqual
beq $t2, $s4, NotEqual
addi $s2,$s2, 1 #increase address in string
addi $s3,$s3, 1 #increase address in word
j ContainLoop

NotEqual:
beq $t3, $s4, Return1 #if the last char in dict is a newline 
move $v0, $0 #return 0 if not newline
# restore stack
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    addi $sp, $sp, 32
jr $ra

Return1:
li $v0, 1 #return 1 if last is a newline
# restore stack
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    addi $sp, $sp, 32
jr $ra

#CONTAIN DIAGONAL
# Make this function stack neutral:
contain_funct_diagonal:
addi $sp, $sp, -32
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $s7, 28($sp)
    lb $s4, newline
    
move $s2, $s7
move $s3, $s5

ContainLoopD: 
lb $t2, 0($s2) #load char from dict
lb $t3, 0($s3) #load char from grids

bne $t2, $t3, NotEqualD
beq $t2, $s4, NotEqualD
lw $s7, num_cols
addi $s2,$s2, 2 #increase address in string
add $s2,$s2, $s7 #increase address in string
addi $s3,$s3, 1 #increase address in word
j ContainLoopD


NotEqualD:
beq $t3, $s4, Return1D #if the last char in dict is a newline 
move $v0, $0 #return 0 if not newline
# restore stack
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    addi $sp, $sp, 32
jr $ra

Return1D:
li $v0, 1 #return 1 if last is a newline
# restore stack
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    addi $sp, $sp, 32
jr $ra

#CONTAIN VERTICAL
# Make this function stack neutral:
contain_funct_vertical:
addi $sp, $sp, -32
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $s7, 28($sp)
    lb $s4, newline
    
move $s2, $s7
move $s3, $s5

ContainLoopV: 
lb $t2, 0($s2) #load char from dict
lb $t3, 0($s3) #load char from grids

bne $t2, $t3, NotEqualV
beq $t2, $s4, NotEqualV
lw $t7, num_cols
addi $s2,$s2, 1 #increase address in string
add $s2,$s2, $t7 #increase address in string
addi $s3,$s3, 1 #increase address in word
j ContainLoopV

NotEqualV:
beq $t3, $s4, Return1V #if the last char in dict is a newline 
move $v0, $0 #return 0 if not newline
# restore stack
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    addi $sp, $sp, 32
jr $ra

Return1V:
li $v0, 1 #return 1 if last is a newline
# restore stack
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    addi $sp, $sp, 32
jr $ra

# STRING FIND
strfind_funct:
# Make this function stack neutral:
    addi $sp, $sp, -32
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $s6, 24($sp)
    sw   $s7, 28($sp)
    
li $s0, 0 #flag =0
li $s1, 0 #idx=0
li $s3, 0 #row=0
li $s4, 0 #col=0
# $s5 - word address, *word to contain function
# s6 - offset
# s7 - grid + offset

FL1:
lw $t0, num_rows
beq $s3, $t0,condition

FL2:
lw $t0, num_cols
beq $s4, $t0,end2 

mul $t5, $s3, $t0
add $s6, $t5, $s4 #offset
 


FL3:
lw $t0, dict_num_words
beq $s1, $t0,end3
la $t1, dictionary
la $t2, dictionary_idx
sll $t3,$s1, 2
add $t2, $t3, $t2
lw $t4, 0($t2)
add $s5, $t4, $t1 #word

# preparing for contains
horizontal:
la $t3, grid
add $s7, $t3, $s6 #grid + offset
jal contain_funct
bnez $v0, Print_horizontal

vertical:
la $t0, grid
add $s7, $t0, $s6 #grid + offset
jal contain_funct_vertical
bnez $v0, Print_vertical
 
diagonal:
la $t0, grid
add $s7, $t0, $s6 #grid + offset
jal contain_funct_diagonal
bnez $v0, Print_diagonal
end_print:
addi $s1,$s1, 1 #idx++
j FL3

end3:
li $s1, 0 #idx=0
addi $s4,$s4, 1 #col++
j FL2

end2:
lw $t0, num_rows
add $s3, $s3, 1 #row++
beq $s3, $t0, condition
li $s4, 0 #col=0 
li $s1, 0 #idx=0
j FL1


# restore stack
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $s6, 24($sp)
    lw   $s7, 28($sp)
    addi $sp, $sp, 32
j main_end

Print_horizontal:
li $s0, 1 #int flag=1
#print row
li $v0, 1
move $a0, $s3
syscall
#print comma
li $v0, 11
li $a0, 44
syscall
#print column
li $v0, 1
sub $a0, $s4,$s3
syscall
#print space
li $v0, 4
la $a0, space
syscall
#print H
li $v0, 11
la $a0, 72
syscall
#print space
li $v0, 4
la $a0, space
syscall
#print word
move $a3, $s5
jal Print
#print newline
li $v0, 4
la $a0, newline
syscall
j vertical

Print_vertical:
li $s0, 1 #int flag=1
#print row
li $v0, 1
move $a0, $s3
syscall
#print comma
li $v0, 11
li $a0, 44
syscall
#print column
li $v0, 1
sub $a0, $s4,$s3
syscall
#print space
li $v0, 4
la $a0, space
syscall
#print V
li $v0, 11
la $a0, 86
syscall
#print space
li $v0, 4
la $a0, space
syscall
#print word
move $a3, $s5
jal Print
#print newline
li $v0, 4
la $a0, newline
syscall
j diagonal

Print_diagonal:
li $s0, 1 #int flag=1
#print row
li $v0, 1
move $a0, $s3
syscall
#print comma
li $v0, 11
li $a0, 44
syscall
#print column
li $v0, 1
sub $a0, $s4,$s3
syscall
#print space
li $v0, 4
la $a0, space
syscall
#print D
li $v0, 11
la $a0, 68
syscall
#print space
li $v0, 4
la $a0, space
syscall
#print word
move $a3, $s5
jal Print
#print newline
li $v0, 4
la $a0, newline
syscall
j end_print

condition:
bnez $s0, main_end
li  $v0, 1 #print -1 if flag was not changed
li $a0, -1
syscall
li $v0, 4 #print newline
la $a0, newline
syscall

endOfFunct:
jal main_end

#------------------------------------------------------------------
# Exit, DO NOT MODIFY THIS BLOCK
#------------------------------------------------------------------
main_end:      
        li   $v0, 10          # exit()
        syscall

#----------------------------------------------------------------
# END OF CODE
#----------------------------------------------------------------
