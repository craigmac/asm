#PURPOSE: Find max number from a list of numbers.
#
#LOGIC:
#   1. Check the current list element in %eax to see if it is 0 (our last num).
#   2. If 0, exit.
#   3. Increase the current position (%edi)
#   4. Load the next value in the list into the current value register (%eax).
#   5. Compare the current value (%eax) with the current highest value (%ebx).
#   6. If current value greater, replace %ebx with %eax.
#   7. Repeat.
#
.section .data
data_items:
 .long 3,67,34,222,45,75,43,24,44,33,22,11,66,0

.section .text
.globl _start

_start:
movl $0, %edi
movl data_items(,%edi,4), %eax  # load first byte of data
movl %eax, %ebx                 # since this is first time, it is the biggest

start_loop:
    cmpl $0, %eax
    je loop_exit
    incl %edi
    movl data_items(,%edi,4), %eax # movl address_or_offset(%base_or_offset,%index,multipler), %location
    cmpl %ebx, %eax
    jle start_loop
    movl %eax, %ebx
    jmp start_loop

loop_exit:
    # %ebx is the status code for the exit() syscall, and current holds the 
    # max num from our list of nums. use echo $? to see it.
    movl $1, %eax
    int $0x80
