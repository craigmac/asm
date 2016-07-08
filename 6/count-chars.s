# PURPOSE: Count characters until a null byte is reached. Basically, the 
# assembler equivalent of C funtion strlen().
# 
# INPUT: The address of the character string.
#
# OUTPUT: Returns the number of characters counted in %eax.
#
# PROCESS:
#   Registers used:
#       %ecx - character count
#       %al - current character
#       %edx - current character address

.type count_chars, @function
.globl count_chars

# This is where our one parameter is on the stack
.equ ST_STRING_START_ADDRESS, 8

count_chars:
    pushl %ebp
    movl %esp, %ebp  # store stack pointer

    # Counter starts at zero
    movl $0, %ecx
    # Starting address of data
    movl ST_STRING_START_ADDRESS(%ebp), %edx

count_loop_begin:
    # Grab the current character
    movb (%edx), %al
    # Is it null?
    cmpb $0, %al
    # quit if it is
    je count_loop_end
    incl %ecx
    incl %edx  # increment counter and pointer
    jmp count_loop_begin  # unconditional jump back

count_loop_end:
    # move count into register and return it
    movl %ecx, %eax
    popl %ebp
    ret
