# PURPOSE: Shows how to call C's printf function

# dynamically-link this into an executable with:
#
# $> as printf-test.s -o printf-test.o
# $> ld printf-test.o -o printf-test -lc -dynamic-linker /lib/ld-linux-x86-64.so.2

.section .data
# This string is the format string. It's the first parameter and printf uses it
# to find out how many params it was given and what kind they are.
firststring:
    .ascii "Hello! %s is a %s who loves the number %d\n\0"
name:
    .ascii "Jonathan\0"
personstring:
    .ascii "person\0"

# This could have been an .equ but here we use a real memory location just to
# show it works
numberloved:
    .long 3
    .section .text
    .globl _start
_start:
    # params passed in the reverse order listed in C function prototype
    pushl numberloved # This is the %d
    pushl $personstring # Second %s
    pushl $name # First %s
    pushl $firststring # the format string
    call printf
    pushl $0
    call exit
