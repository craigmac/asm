# Dealing with files in x86-32bit Linux Assembly
# compile with:
# $> as chapter5.s -o toupper.o
# $> ld toupper.o -o toupper
# Now you can run it on a file by doing:
# $> ./toupper lowercasefile.txt uppercasefile.txt
# To convert lowercasefile.txt into the all uppercase in uppercasefile.txt

# PURPOSE: Converts an input file to an output file with all letters converted
#       to uppercase.
#
# PROCESS: 
#       1. Open the input file
#       2. Open the output file
#       3. While we are not at EOF in input file:
#           a. read part of file into our memory buffer
#           b. go through each byte of memory:
#               if byte is lower-case letter, convert it to uppercase
#           c. write the memory buffer to output file

.section .data

######### CONSTANTS #################
# syscall numbers for easy reference
.equ SYS_OPEN, 5
.equ SYS_WRITE, 4
.equ SYS_READ, 3
.equ SYS_CLOSE, 6
.equ SYS_EXIT, 1

# options for open() found in /usr/include/asm/fcntl.h usually
.equ O_RDONLY, 0
.equ O_CREAT_WRONLY_TRUNC, 03101

# file descriptors
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

# syscall interrupt
.equ LINUX_SYSCALL, 0x80

# EOF - return value of read which means we hit end of file
.equ END_OF_FILE, 0
.equ NUMBER_ARGUMENTS, 2

######### BUFFERS ###################
.section .bss
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE

######## TEXT SECTION ##############
.section .text
# easier stack positions for arg access
.equ ST_SIZE_RESERVE, 8
.equ ST_FD_IN, -4
.equ ST_FD_OUT, -8
.equ ST_ARGC, 0 # number of arguments
.equ ST_ARGV_0, 4 # name of program
.equ ST_ARGV_1, 8 # input file name
.equ ST_ARGV_2, 12 # output file name

.globl _start
_start:
    # Init program, save stack pointer
    movl %esp, %ebp
    # allocate space for our file descriptors on the stack
    subl $ST_SIZE_RESERVE, %esp

open_files:
open_fd_in:
    # open input file
    # open syscall
    movl $SYS_OPEN, %eax
    # input filename into %ebx
    movl ST_ARGV_1(%ebp), %ebx
    # read-only flag
    movl $O_RDONLY, %ecx
    # file perms, does not matter this time for reading
    movl $0666, %edx
    # call linux
    int $LINUX_SYSCALL

store_fd_in:
    # save the given file descriptor
    movl %eax, ST_FD_IN(%ebp)

open_fd_out:
    # open output file
    # open the file
    movl $SYS_OPEN, %eax
    # output filename into %ebx
    movl ST_ARGV_2(%ebp), %ebx
    # flags for writing to the file
    movl $O_CREAT_WRONLY_TRUNC, %ecx
    # mode for new file if it's created
    movl $0666, %edx
    # call linux
    int $LINUX_SYSCALL

store_fd_out:
    # store the file descriptor here
    movl %eax, ST_FD_OUT(%ebp)

########## MAIN LOOP ################
read_loop_begin:
    # Read in a block from the input file (from sysargv)
    movl $SYS_READ, %eax
    # get the input FD
    movl ST_FD_IN(%ebp), %ebx
    # the location to read into
    movl $BUFFER_DATA, %ecx
    # the size of the buffer, 500 bytes
    movl $BUFFER_SIZE, %edx
    # size of buffer read is returned into %eax
    int $LINUX_SYSCALL

    # Exit if we reached the end, check for EOF
    cmpl $END_OF_FILE, %eax
    # if found or error code, go to end
    jle end_loop

continue_read_loop:
    # convert block to upper case
    pushl $BUFFER_DATA
    pushl %eax # size of buffer
    call convert_to_upper
    popl %eax  # get the size back after function done
    addl $4, %esp  # restore stack pointer
    # Write the block out to the output file
    # size of the buffer
    movl %eax, %edx
    movl $SYS_WRITE, %eax
    # file to use
    movl ST_FD_OUT(%ebp), %ebx
    # location of the buffer
    movl $BUFFER_DATA, %ecx
    int $LINUX_SYSCALL
    # continue the loop unconditionally
    jmp read_loop_begin

end_loop:
    # Close the files, don't bother checking error checking on these.
    movl $SYS_CLOSE, %eax
    movl ST_FD_OUT(%ebp), %ebx
    int $LINUX_SYSCALL

    movl $SYS_CLOSE, %eax
    movl ST_FD_IN(%ebp), %ebx
    int $LINUX_SYSCALL

    # exit
    movl $SYS_EXIT, %eax
    movl $0, %ebx
    int $LINUX_SYSCALL

###### convert_to_upper() function #########################
# lower boundary of our search
.equ LOWERCASE_A, 'a'
# upper boundary of our search
.equ LOWERCASE_Z, 'z'
# conversion between upper and lower case
.equ UPPER_CONVERSION, 'A' - 'a'

# Stack stuff
.equ ST_BUFFER_LEN, 8 # length of buffer
.equ ST_BUFFER, 12 # actual buffer

convert_to_upper:
    pushl %ebp
    movl %esp, %ebp

    # set up vars
    movl ST_BUFFER(%ebp), %eax
    movl ST_BUFFER_LEN(%ebp), %ebx
    movl $0, %edi

    # if a buffer with zero len was given to us, just leave
    cmpl $0, %ebx
    je end_convert_loop

convert_loop:
    # get current byte
    movb (%eax,%edi,1), %cl

    # go to next byte unless it is between 'a' and 'z'
    cmpb $LOWERCASE_A, %cl
    jl next_byte
    cmpb $LOWERCASE_Z, %cl
    jg next_byte

    # otherwise convert the byte to uppercase
    addb $UPPER_CONVERSION, %cl
    # and store it back
    movb %cl, (%eax,%edi,1)

next_byte:
    incl %edi # next byte, increase instruction pointer
    cmpl %edi, %ebx # continue unless we reached the end
    jne convert_loop

end_convert_loop:
    # no return value, just leave
    movl %ebp, %esp
    popl %ebp
    ret
