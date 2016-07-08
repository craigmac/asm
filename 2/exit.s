#PURPOSE: Simple program that exits and returns a status code back to the
#       Linux kernel. We will send 1 back, which usually means error code, 0
#       means everything went ok. Just using 1 to make sure our program worked.
#

#INPUT: none
#

#OUTPUT: returns a status code. This can be viewed by typing:
#       $> echo $?
#       at the bash prompt after running the program. 
#
#

#VARIABLES: 
#       %eax holds the system call number
#       %ebx holds the return status
#
.section .data

.section .text
.globl _start
_start:
movl $1, %eax   # linux kernel cmd num for exiting a program
movl $1, %ebx    # return status num we will be using. Using 1 which means error 
int $0x80       # call interrupt to run exit command we put in eax register
                # it checks there I guess for the number

