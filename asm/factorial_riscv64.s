    .section .text
    .globl main

main:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    sd s1, 8(sp)

    call getint
    mv s0, a0          # n
    li t0, 2           # i
    li s1, 1           # f

.Lcond:
    bgt t0, s0, .Lexit
    mul s1, s1, t0
    addi t0, t0, 1
    j .Lcond

.Lexit:
    mv a0, s1
    call putint

    li a0, 0
    ld s1, 8(sp)
    ld s0, 16(sp)
    ld ra, 24(sp)
    addi sp, sp, 32
    ret
