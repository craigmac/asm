.include "linux.s"
.include "record-def.s"

.section .data

# Constant data of the records we want to write. Each text data item is padded
# to the proper length with null (i.e. 0) bytes.

# .rept is used to pad each item. .rept tells the assembler to repeat the
# section between .rept and .endr the number of times specified. This is used
# in this program to add extra null characters at the end of each field to fill
# it up.
record1:
    .ascii "Frederick\0"
    .rept 31 # Padding to 40 bytes, rept directive repeats 31 times the 
    # instructions between rept and .endr
    .byte 0
    .endr

    .ascii "Bartlett\0"
    .rept 31
    .byte 0
    .endr

    .ascii "4242 S Prairie\nTulsa, OK 55555\0"
    .rept 209
    .byte 0
    .endr

    .long 45

record2:
    .ascii "Marilyn\0"
    .rept 32
    .byte 0
    .endr

    .ascii "Taylor\0"
    .rept 33
    .byte 0
    .endr

    .ascii "2224 S Johnson St\nChicago, IL 12345\0"
    .rept 203
    .byte 0
    .endr

    .long 29

record3:
    .ascii "Derrick\0"
    .rept 32
    .byte 0
    .endr

    .ascii "McIntire\0"
    .rept 31
    .byte 0
    .endr

    .ascii "500 W Oakland\nSan Diego, CA 54321\0"
    .rept 206 # padding to 240 bytes
    .byte 0
    .endr

    .long 36

# This is the name of the file we will write to
file_name:
    .ascii "test.dat\0"

    .equ ST_FILE_DESCRIPTOR, -4
    .globl _start
    _start:
        # copy the stack pointer to %ebp
        movl %esp, %ebp
        # allocate space to hold the FD
        subl $4, %esp

        # Open the file
        movl $SYS_OPEN, %eax
        movl $file_name, %ebx
        movl $0101, %ecx # This means create if not existing and open for writing
        movl $0666, %edx
        int $LINUX_SYSCALL

        # Store the FD away
        movl %eax, ST_FILE_DESCRIPTOR(%ebp)
        # Write the first record
        pushl ST_FILE_DESCRIPTOR(%ebp)
        pushl $record1
        call write_record
        addl $8, %esp

        # Write the second record
        pushl ST_FILE_DESCRIPTOR(%ebp)
        pushl $record2
        call write_record
        addl $8, %esp

        # Write the third record
        pushl ST_FILE_DESCRIPTOR(%ebp)
        pushl $record3
        call write_record
        addl $8, %esp

        # Close the FD
        movl $SYS_CLOSE, %eax
        movl ST_FILE_DESCRIPTOR(%ebp), %ebx
        int $LINUX_SYSCALL

        # Exit the program
        movl $SYS_EXIT, %eax
        movl $0, %ebx
        int $LINUX_SYSCALL
