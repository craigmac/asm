# Uses C library printf and exit calls to shorten hello world program

# To build you would do:
# $> as helloworld-lib.s -o helloworld-lib.o
# $> ld -dynamic-linker /lib/ld-linux.so.2 -o helloworld-lib hellworld-lib.o -lc

.section .data

helloworld:
    .ascii "hello world\n\0"

    .section .text
    .globl _start
_start:
    pushl $helloworld
    call printf

    pushl $0
    call exit
