# Notes on x86 (32-bit) assembly (using "Programming from the Ground Up" book)

IMPORTANT NOTE: These instructions are for 32 bit Linux. Unix flavours (BSDs, Mac)
have system call differences so programs might compile and link, but not give you 
the results you want! Either you write portable code with macros and ifdefs to
define syscalls, etc. on each target platform, or you just write for one specific
platform, which is what we do here: Linux x86-32 bit.

Below instruction are all in 32 bit assembly so if we trying to compile code on
a 64 bit machine it will complain, specify 32 bit in compiling and linking:
```
$> as --32 file.s -o file.o
$> ld -m elf_i386 -s file.o -o file
```

# Chaper 2

# Example Linux x86 32bit program

```
#PURPOSE: Simple program that exits and returns a status code to kernel.

#INPUT: none

#OUTPUT: returns a status code of 1, which typically means something failed.

#VARIABLES: %eax holds the sys call number
#           %ebx holds the return status number
.section .data

.section .text
.globl _start
_start:
movl $1, %eax 
# linux kernel cmd num for exiting a program
# movl source,destination. In this case we specify $1 to mean literally
# the value 1, if we put 1 it reads that as an address and anything could
# happen. $1 means use immediate mode addressing, 1 would mean use direct mode
# addressing.
movl $1, %ebx # return status number, 1
int $0x08 # Call interrupt to run exit command we put in eax register
```

Assemble and link it on Linux to run it with:
```
$> as exit.s -o exit.o
$> ld exit.o -o exit
$> ./exit
$> echo $?
1
$> 
```

# Chapter 3
## Assembly program outline
Always include:
* The purpose of the code
* An overview of the processing involved
* Anything strange your program does and why it does it
All of this should go in a comment section like this:
    #PURPOSE: blah blah blah
    #         blah blah blah

    #OUTPUT: foo bar baz
    #        bar foo baz

    #VARIABLES:
    #        %eax holds sys call num
    #        %ebx holds return status num

At the top of the file.

Anything with a period, like ```.section .data``` is not translated into
machine instruction. These are called **assembler directives** or 
**pseudo-operations** because they are not cpu-run (sort-of like C preprocessor)
statements.

### symbols
```
.section .text
.globl _start
```
The .text section is where the instructions are put. _start is a **symbol**,
meaning it will be replaced by something else either during assembly or linking.
Symbols are usually just used to mark locations of things so you do not have 
to remember the memory address. 

.globl means assembler should not discard this symbol after assembly because it
is needed by the linker. The linker needs a _start symbol, this is what it 
looks for as a program start point. 

```
_start:
```

This is a **label**. This tells the assembler to make the symbol of _start be
the value of the wherever the next instruction that comes after this label, 
lives. 

### General purpose registers
There are several general purpose registers in a 32 bit system. The 'e' stands
for 'extended' and we can further address portions of each register by using
syntax: %eax is the full 4 bytes/32 bits, %ax is the 16 bit portion of it, 
and %ah is the high order byte of ax and %al is the lower order byte of %ax.

* %eax (32 bit/4 bytes/2 words), %ax(16 bit/2 bytes/a word): %ah(8bit/1 byte), %al(8bit/1byte)
* %ebx
* %ecx
* %edx
* %edi
* %esi

### Special purpose registers
* %ebp
* %esp
* %eip - access through special functions
* %eflags - access through special functions

## Find Max number Program

```
#PURPOSE: Finds the max number from a list of numbers. 
# 
#LOGIC:
#   1. Check the current list element in %eax to see if it is 0 (our end num).
#   2. If 0, exit.
#   3. Increase the current position (%edi).
#   4. Load the next value in the list into the current value register (%eax).
#   5. Compare the current value (%eax) with the current highest value (%ebx).
#   6. If current value greater, replace %ebx with %eax.
#   7. Repeat.
#
#VARIABLES:
# data_items will be the address where nums start, last is a 0 and we stop there
# %edi will hold current position in the list.
# %ebx will hold the current highest value in the list.
# %eax will hold the current element being examined.

.section .data
data_items: # our numbers
# a .long is 4 bytes (32 bit), so here the assembler reserves a total of
# 14 .longs (56 bytes), one after another in memory starting at memory
# location of first one (mem address of 3)
# There is a bug here, even though we are using long numbers, we are storing
# the result in %ebx which is the exit status code, and anything above 255 
# in there might give strange results because that is the largest allowed exit
# status
 .long 3,67,34,222,45,75,54,34,44,33,22,11,66,0

.section .text
.globl _start

_start:
movl $0, %edi                   # move 0 into index reg
movl data_items(,%edi,4), %eax  # load first byte of data 
movl %eax, %ebx                 # since this is first item, it is the biggest

start_loop:
    cmpl $0, %eax               # check if we hit end, the num 0 in our list
    je loop_exit
    incl %edi                   # load next value
    movl data_items(,%edi,4), %eax # load next byte of data into eax
    cmpl %ebx, %eax             # compare new value with largest value
    jle start_loop              # re-loop if curr value not bigger
    movl %eax, %ebx             # curr value bigger, save it
    jmp start_loop              # restart loop

loop_exit:
    # %ebx is the status code for the exit system call, and it currently holds
    # the maximum number from our list of numbers
    movl $1, %eax               # 1 is the exit() syscall
    int $0x80                   # interrupt our program and run syscall
```

### jump instructions and flow control
Jumps work by checking the %eflags register (aka the status register) to see
the result of a comparison (e.g., a previous cmpl instruction)

* je - jump if values were equal
* jg - jump if second value greater
* jge - jump if second value greater or equal
* jl - jump if second value less
* jle - jump if second value less or equal
* jmp - unconditional jump, just jump, no comparison needed.

## Addressing Modes
General form of memory addressing references is:
```ADDRESS_OR_OFFSET(%BASE_OR_OFFSET,%INDEX,MULTIPLIER)```
All the fields are optional.
ADDRESS_OR_OFFSET and MULTIPLER must both be constants, and the other 2 must
be registers. Any left out are substituted with 0 in the equation.

```
FINAL_ADDRESS = ADDRESS_OR_OFFSET + %BASE_OR_OFFSET + MULTIPLIER * %INDEX
```

### indexed addressing mode

```
movl string_start(,%ecx,1), %eax
```
If %ecx contained 2 here we would be storing the third byte (remember 0 indexed)
into eax.

### indirect addressing mode
Loads a value from the address indicated by a register. If eax held an address
we could move the value at that address (dereferencing a pointer in C equivalent)
by doing:

```
movl (%eax), %ebx
```

### base pointer addressing mode
Similar to indirect but adds a constant value to the address in the register. 
Basically like incrementing a pointer in C and then dereferencing it. 

```
movl 4(%eax), %ebx
```

This would copy the value 4 bytes into eax, into the ebx

### Immediate mode

Simplest, used to load values directly into the register. It uses the 
'$' prefix to denote not the interpret it as an address.

```
movl $12, %eax
```

Move value 12 into eax. '$' means immediate mode (i.e., it is not an address 
or symbol).

Every mode except for Immediate Mode can be used for both source or destination
operands in any instruction. Obviously you can not use immediate mode to 
store a value in, so immediate mode can not be used as destination operand.

# Chapter 4. All About Functions

## The stack
Each cpu program that runs uses a region of memory called the stack that enable
functions to work properly. Think of a stack of papers on a desk. Top one being
most recent. Stack is at very top addresses of memory. ```pushl``` pushes 
either a register or memory value onto the top of the stack. The top is actually 
the bottom of the stacks memory: in memory the stack starts at the top of
memory and grows downward for architecture reasons. So when we say top of the 
stack, we actually mean it is at the bottom of the stacks memory. ```popl``` 
removes the top value from the stack and places into a register of 
memory location of your choosing.

The more we push to the stack, the further it will keep growing down in memory.
The stack register, %esp, always contains a pointer to the current top of the
stack address.

* Every pushl, %esp gets subtracted by 4 so it points to the new top of the
stack
* popl will add 4 to %esp to represent the stack shrinking (it grows downward).
* To access the value on the top of the stack without popping it off do:
```movl (%esp), %eax```
Which uses indirect reference (dereferencing a pointer) to grab the value
* To access the value right below the top of the stack (second newest) do:
```mov1 4(%esp), %eax```

### The call instruction
Before executing a function, a program pushes all of the parameters for the 
function onto the stack in the reverse order that they are documented. The
function then just grabs them from there. 

* ```call``` instruction does two things: 1. pushl address of next instruction,
which will be the return address, to the stack. 2. modifies %eip to point to the
start of the function.

So the stack would look like this:
Param n
...
Param 2
Param 1
Return address (%esp)

# Chapter 5. Dealing with Files

## Unix File Concept

File Descriptors:
The OS gives you a number when opening files usings system file open commands,
called a file descriptor which is the handle to the file.

### open()
On Linux, syscall number 5 is the open() syscall. We pass it a filename, and
the permissions as parameters.

%eax holds the syscall number, %ebx will be the address of the first character
of the filename. Permission set should be stored in %edx. When you then call
syscall 5 you get a file descriptor in %eax. 

### read()
read() is syscall 3, you give it a file descriptor, the address of a buffer for
storing the data that is read in %ecx, and the size of the buffer in %edx.
read() will return either the num of chars read from the file or an error code.

### write()
syscall number 4. Requires same params as read(), except that the buffer should
already be filled with the data to write. Gives back num of bytes written in
%eax or an error code.

### closing files
After done, we use syscall number 6, close(). The only param is the file descr.
placed in %ebx.

## Buffers and .bss
A continouse block of bytes used for bulk data xfer. Used to store temp data
while doing operations. 

Buffers are set fixed size by the programmer. So we set a buffer size and then
pass that location start and the size of it to an operation like read() to store
the read contents to the buffer. 

To create a buffer, you can either reserve static storage or do it dynamically.
So far we have only done static using .long and .byte directives. Chapter 9
covers dynamic storage.

Downsides of static allocated buffer: for a .byte directive of 500 bytes we 
would ahve to type 500 numbers, all for just storing nothing. Also, static will
increase size of executable by 500 bytes this way, even if we read only 5 bytes.

The solution: the .bss section: the .bss section can reserve storage but can not
initialize it. Allocating here will not take up executable storage. Here you 
can not set an initial value, which is fine for buffers because we just need 
space and do not care about the values of those bytes, we are just overwriting
them.

Example to read 500 bytes:
.section .bss
.lcomm my_buffer, 500

movl $my_buffer, %ecx
movl 500, %edx
movl 3, %eax
int $0x80

# Chapter 6. Reading and Writing Simple Records

Dealing with structured data files, text files here, with fixed length records
about people:

Firstname - 40 bytes
Lastname - 40 bytes
Address - 240 bytes
Age - 4 bytes

## .rept, .endr, .ascii directives

.rept 31 will repeat the instructions between .rept and .endr, 31 times.

This would add 31 null bytes to our record data to make a 40 byte fixed size:
record1:
    .ascii "Frederick\0"
    .rept 31
    .byte 0
    .endr

# Chapter 8. Sharing Functions with Code Libraries

How to link into the C library if we call printf and exit C functions from asm
code:

.section .data

hellworld:
    .ascii "hello world\n\0"
    .section .text
    .globl _start
_start:
    pushl $helloworld
    call printf
    pushl $0
    call exit

Now to compile and link it:
```
$> as hello.s -o hello.o
$> ld -dynamic-linker /lib/ld-linux-x86-64.so.2 -o hello hello.o -lc
```
## Dynamic linking and using C libraries in assembly code

The option "-dynamic-linker" allows our program to be linked to libraries. This
builds the executable so that before executing, the operating system will load
the program /lib/ld-linux.so.2 to load in external libraries and link them with
the program. This program is known as a dynamic linker.

The "-lc" options says to link to the C library, named libc.so on Unix systems.
The linker adds "lib" and ".so" the the end of the "-l" options to create the
library anme "libc.so". This library contains printf and exit functions that we
used.

## How shared libraries work

If the code contains all the functions needed at compile time, it is called a 
statically-linked executable. When you use a shared library your program is then
dynamically-linked which means not all the code needed to run the program is
in the executable itself, unlike static-linked, but in external libraries.

On linux, shared libraries usually found in /lib, /lib64, /usr/lib64, /usr/lib.

If we run the ldd program, it will show what the executable depends on for 
shared libraries, if it has none it will report "not a dynamic executable".

```
$> ldd ./hello
libc.so.6 => /lib64/libc.so.6
/lib64/ld-linux-x86-64.so.2
```

The .6 and .2 are the version numbers. Here, the shared libraries are in /lib64.
These libraries have to be loaded before the program can be run. 

## BUild our own Shared Library

If we want to build a shared library (.so file, shared object file), using our
chapter 6 read and write functions we would do:

```
$> as write-record.s -o write-record.o
$> as read-record.s -o read-record.o
$> ld -shared write-record.o read-record.o -o librecord.so
```

This takes our two .o object files compiled from our asm files and links them
together into one .so shared object file for use in dynamicall linked 
executables.

Now if we wanted to build an dynamically linked executable using that .so:
```
$> as myprog.s -o myprog.o
$> ld -L . -dynamic-linker /lib/ld-linux-x86-64.so.2 -o myprog -lrecord myprog.o
```

This creates the executable "myprog" and dynamically links to /lib/ld-linux... 
and to librecord.so (-lrecord). It finds librecord by looking in current 
directory ("-L . "). By default if looks in system lib dirs like /lib64 and 
/usr/lib64. We only have to say "-lrecord" because the linker adds "lib" and
".so" to it, to make "librecord.so", the same way it works with "libc.so" when 
we just write "-lc" as an option during the linking.

In order for this program to run we would have to add the pwd to the 
LD_LIBRARY_PATH environment variable, because by default it does not look there.

```
$> export LD_LIBRARY_PATH=LD_LIBRARY_PATH:.
```
Which appends the current working directory to the path the OS looks for shared
libraries objects (.so).

# Chapter 9. Intermediate Memory Topics






