
#=========================================================================
# 1D String Finder 
#=========================================================================
# Finds the [first] matching word from dictionary in the grid
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

grid_file_name:         .asciiz  "1dgrid.txt"
dictionary_file_name:   .asciiz  "dictionary.txt"
newline:                .asciiz  "\n"
space:                  .asciiz  " "
        
#-------------------------------------------------------------------------
# Global variables in memory
#-------------------------------------------------------------------------
# 
.align 4 
grid:                   .space 33       # Maximun size of 1D grid_file + NULL
.align 4                                # The next field will be aligned
dictionary:             .space 11001    # Maximum number of words in dictionary *
                                        # ( maximum size of each word + \n) + NULL
# You can add your data here!
.align 4 
dictionary_idx:                  .space  4000 #store starting adresses of words in dict
.align 4
dict_num_words:                  .space 4
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
        lb   $t1, grid($t0)          
        addi $v0, $0, 10                # newline \n
        beq  $t1, $v0, END_LOOP         # if(c_input == '\n')
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
bne  $s1, $s4, skipp #if char is not equal to the newline, ship the if condition

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



# PRINT
# Make this function stack neutral:
  
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

# CONTAIN
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
    
move $s2, $s7 #*string, grid
move $s3, $s6  #*word, dictionary

ContainLoop: 
lb $t2, 0($s2) #load char from dict
lb $t3, 0($s3) #load char from grids

bne $t2, $t3, NotEqual
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



# STRFIND
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
    
la $t0, dictionary 
la $t1, grid 
la $s2, dictionary_idx #base address - indicies array
lw $s3, dict_num_words #number of words in a dictionary will be stored here
lb $s4, newline
    
li $s0, 0 #idx=0
li $s1, 0 #grid_idx=0 
li $s5, 0 #int flag=0  
# $s6 - *word address
# $t6 - *grid base + grid idx value
# $t2 - idx offset
# $s7 - grid + grid idx address

whileLoop:
la $t1, grid
add $s7, $t1, $s1 #grid base + grid idx address
lb $t7, 0($s7) #load grid base + grid idx value
beq $t7, $zero, condition #if EOF, go to condition

forLoop:
beq $s0, $s3, end_for_loop
sll $t2, $s0, 2 #mult. index by 4 to convert it to offset
add $t4, $s2, $t2 #dictionary_idx + idx = &dictionary_idx[idx]
lw $t4, 0($t4) #load the index
la $t0, dictionary
add $s6, $t4, $t0 #dictionary + dictionary_idx[idx] = word, *word is equal to $a1
move $a0, $s7 #grid+grid idx
move $a1, $s6 #word
jal contain_funct #contain_funct should take $a0 and $a1 as arguments and return $v0
bnez $v0, success
addi $s0,$s0, 1 #idx++
j forLoop

end_for_loop:
addi $s1, $s1, 1 #grid_idx++
li $s0, 0 #idx=0 RESET
j whileLoop
  
success:
#print grid_idx
li $v0, 1
move $a0, $s1
syscall

#print space
li $v0, 4
la $a0, space
syscall

#print word
move $a3, $s6
jal Print
li $s5, 1 #int flag=1

#print newline
li $v0, 4
la $a0, newline
syscall
addi $s0,$s0, 1 #idx++
j forLoop

condition:
bnez $s5, endOfFunct
li  $v0, 1 #print -1 if flag was not changed
li $a0, -1
syscall
li $v0, 4 #print newline
la $a0, newline
syscall

endOfFunct:
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
