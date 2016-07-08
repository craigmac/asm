# Author: Craig MacEachern
# 
# Purpose: 
# Demo of writing a function in x86 32bit assembly on FreeBSD. Should
# also work fine on most Linux variants as the system calls are the same. This
# program creates a function to computer the result of calling:
# 2^3 + 5^2
# It uses recursion. To see the output, after running you can call the 
# returned value by doing 'echo $?' in your terminal (on Bash at least).
# The answer should be: 33
#
# Notes/Explanation:
# --STACK--
# The stack lives at the very top of memory addresses and 'grows' downward, 
# towards program memory. The 'top' of the stack is actually the bottom of
# the stack's memory. If stack addresses started at e.g. 10, and we had 
# values at 9 and 8 the top of the stack is at address 8. 'popl' in this case
# would take the value at address 8, and 'pushl' would put a value into stack
# address 7, the new top. %esp is the 'stack pointer' which points to the 
# current top of the stack. Everytime you popl off the stack, 4 is added to 
# %esp to point to the new top of stack. The reverse is true with pushl, 4 is
# subtracted. 
#
# If we want to access the value at the top of the stack without popl it off we
# can do:
# movl (%esp), %eax  which uses indirect addressing mode (), like C's dereferencing
# If we just did:
# movl %esp, %eax # then %eax would just hold the pointer and we'd have to do
# We can get the second newest value off the stack doing:
# movl 4(%esp), %eax # because each pointer on the stack is 4 bytes 
#
# --CALLING A FUNCTION--
# We push the function params onto the stack in reverse order they are documented.
# The 'call' instruction does two things for us automatically:
# 1. pushl the address of the next instruction, the return address onto the stack.
# 2. Modify %eip (instruction pointer) to point to the start of the function we
# are 'call'ing.
#
# *IMPORTANT* We get the function parameters by grabbing them from the stack, and
# we get the return address from the stack as well.
# 
# Example stack when we 'call' a fn:
# Address               Value
# 10                    Parameter 3
# 9                     Parameter 2
# 8                     Parameter 1
# 7 (top of stack)      Return address (%esp) 
#
# Now in the fn, the fn itself will do the following automatically:
# Address               Value
# 10                    Param 3
# 9                     Param 2
# 8                     Param 1
# 7                     Return address
# 6                     Old %ebp -- (%esp) and (%ebp)
#
# 1. The first thing a fn does when entering is to save the current base pointer
# register %ebp by pushing it to top of stack (popl). The %ebp is a special
# register used for accessing fn parms and local vars easily. Next, it copies
# the stack pointer %esp to %ebp base pointer using movl %esp, %ebp.
# Because we did this it is now easy to access fn params as fixed indexes from
# %ebp. For example to get the first param we could just go 4(%ebp). Even if
# we push more things on the stack, with %ebp now set to where it is, we can
# still access those params easily. 
#
# Now stack looks like this for a function just called with 3 parameters:
# Address               Value
# 10                    Param 3 <-- 16(%ebp)
# 9                     Param 2 <-- 12(%ebp)
# 8                     Param 1 <-- 8(%ebp)
# 7                     Return address <-- 4(%ebp)
# 6                     Old %ebp <-- (current %esp) and (%ebp)
#
# 2. Now the fn copies the current stack pointer to base pointer:
# movl %esp, %ebp
# Now %ebp will always be pointing to where the stack pointer was at the 
# start of the fn, aka a constant reference to the stack frame.
#
# *IMPORTANT* The stack 'frame' emcompasses all the params, local vars, and 
# return address. 
#
# 3. Next, the fn reserves space on the stack for any local vars we need. 
# This is done by moving the stack pointer out of the way by how many vars we
# need total. Let's say we need two words (8 bytes on 32 bit) of memory to run
# a fn. We simply move %esp down 8 bytes:
# subl $8, %esp # $8 means literal 8, not a variable or address '8', this is 
# called 'immediate mode addressing' in assembly.
# 
# Stack now:
# Value
# Param 3 <-- 16(%ebp)
# Param 2 <-- 12(%ebp)
# Param 1 <-- 8(%ebp)
# Ret address <-- 4(%ebp)
# Old %ebp <-- (%ebp)
# Local var 1 <-- -4(%ebp)
# Local var 2 <-- -8(%ebp) or (%esp)
#
# --FUNCTION RETURN--
# When returning a fn does 3 things:
# 1. stores return value in %eax register.
# 2. Resets stack to before it was called (gets rid of current stack frame)
# 3. Returns control to whereever it was called from. The 'ret' instruction
# does this for us, what it does is pop the value at the top of the stack and
# sets the instruction pointer %eip to that value, so step 2 must be done first!
#
# Returning example:
# movl %ebp, %esp # resets the stack pointer to what it was at fn start
# popl %ebp # removes base pointer address to esp moves up to point at ret address
# ret # now this will pop off top of stack which is currently pointing 
# at ret address in the stack 
#
# Control is now back to the calling code due to 'ret' setting %eip to calling
# location. Now we need to pop off all of the params pushed to the stack for the
# fn call in the first place to get the stack pointer back to where it was, it
# can be done simple by doing (on 32bit), 4*num of params, added to %esp:
# addl 4*3(%esp)
# We do this is we don't need the parameter values anymore, which you almost always 
# don't. 


.section .text
    .globl _start

_start: 
    pushl $3 # second arg
    pushl $2 # first arg
    call power # call our fn
    addl $8, %esp # move stack pointer back before args pushed, 4 * 2 args
    pushl %eax # save first ret value to stack before calling again
    pushl $2 # arg 2
    pushl $5 # arg 1
    call power
    addl $8, %esp
    popl %ebx # second answer in %eax. We saved first onto the stack, so now
              # we can just pop it out into %ebx
    addl %eax, %ebx # add original call return value to second call return value
    movl $1, %eax # we are going to call sys exit (%ebx is returned with this call)
    int $0x80 # sys exit system call. returns value from %ebx register.

    # -- POWER FUNCTION --
    .type power, @function
    power:
        # do standard stack setup stuff for frame and return address
        pushl %ebp # save old base pointer
        movl %esp, %ebp # make stack pointer base pointer
        subl $4, %esp # make room for 4 bytes, local storage

        movl 8(%ebp), %ebx # get first arg
        movl 4(%ebp), %ecx # get second arg

        movl %ebx, -4(%ebp) # stores current result in space we made

    power_loop_start:
        cmpl $1, %ecx # if power is 1, we are done recuring (base case)
        je end_power # jump if equal flag set in flags register from previous operation (cmpl)
        movl -4(%ebp), %eax # get current result
        imull %ebx, %eax # multiply current result by base number 
        movl %eax, -4(%ebp) # store current result
        decl %ecx # decrease the power
        jmp power_loop_start # unconditionally jump to restart process

    end_power:
        movl -4(%ebp), %eax # put return value in eax where it is expected
        movl %ebp, %esp     # standard restoring pointers: stack and base both
        popl %ebp
        ret

.section .data
# none, everything stored in registers
