    .section .text
    .globl transform
    .globl main

transform:
    addiw t0, a0, 3
    slliw t0, t0, 1
    li t1, 2
    divw t1, a0, t1
    subw t0, t0, t1
    li t1, 2
    remw t1, a0, t1
    bnez t1, .Lodd
    addiw a0, t0, 7
    ret
.Lodd:
    addiw a0, t0, -5
    ret

main:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    sd s1, 40(sp)
    li s0, 0
    li s1, 0

.Lcond:
    li t0, 3
    bge s0, t0, .Lexit
    call getint
    slli t0, s0, 2
    add t0, sp, t0
    sw a0, 0(t0)
    lw a0, 0(t0)
    blez a0, .Lfallback
    li t0, 20
    bge a0, t0, .Lfallback
    call transform
    addw s1, s1, a0
    j .Lnext

.Lfallback:
    addiw s1, s1, 1

.Lnext:
    addiw s0, s0, 1
    j .Lcond

.Lexit:
    mv a0, s1
    call putint
    li a0, 0
    ld s1, 40(sp)
    ld s0, 48(sp)
    ld ra, 56(sp)
    addi sp, sp, 64
    ret
