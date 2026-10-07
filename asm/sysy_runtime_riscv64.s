    .option norelax

    .section .bss
    .align 3
inbuf:
    .skip 32
outbuf:
    .skip 32

    .section .text
    .globl _start
    .globl getint
    .globl putint

_start:
    call main
    li a7, 93          # exit
    ecall

getint:
    # read(0, inbuf, 31)
    li a0, 0
    la a1, inbuf
    li a2, 31
    li a7, 63
    ecall

    mv t6, a0          # bytes read
    la t0, inbuf
    li t1, 0           # index
    li a0, 0           # parsed value

.Lparse:
    bge t1, t6, .Lgetint_done
    lb t2, 0(t0)
    li t3, 48
    blt t2, t3, .Lgetint_done
    li t3, 57
    bgt t2, t3, .Lgetint_done

    li t3, 10
    mul a0, a0, t3
    addi t2, t2, -48
    add a0, a0, t2

    addi t0, t0, 1
    addi t1, t1, 1
    j .Lparse

.Lgetint_done:
    ret

putint:
    la t0, outbuf
    addi t0, t0, 31
    li t1, 10
    addi t0, t0, -1
    sb t1, 0(t0)

    mv t2, a0
    li t3, 10

.Ldigits:
    remu t4, t2, t3
    divu t2, t2, t3
    addi t4, t4, 48
    addi t0, t0, -1
    sb t4, 0(t0)
    bnez t2, .Ldigits

    # write(1, first_digit, len)
    li a0, 1
    mv a1, t0
    la t5, outbuf
    addi t5, t5, 31
    sub a2, t5, t0
    li a7, 64
    ecall
    ret
