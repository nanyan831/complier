    .section .data
    .align 2
bias:
    .word 1, 2, 0, 3, 0, 0

    .section .text
    .globl weighted_sum
    .globl main
weighted_sum:
    li t0, 0
    li t1, 0
.Lsum_cond:
    li t2, 12
    bge t0, t2, .Lsum_exit
    slli t2, t0, 2
    add t2, a0, t2
    lw t3, 0(t2)
    addiw t4, t0, 1
    mulw t3, t3, t4
    addw t1, t1, t3
    li t2, 6
    remw t2, t0, t2
    slli t2, t2, 2
    add t2, a1, t2
    lw t3, 0(t2)
    addw t1, t1, t3
    mv t0, t4
    j .Lsum_cond
.Lsum_exit:
    mv a0, t1
    ret

main:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    li s0, 0
.Lread_cond:
    li t0, 12
    bge s0, t0, .Lread_exit
    call getint
    slli t0, s0, 2
    add t0, sp, t0
    sw a0, 0(t0)
    addiw s0, s0, 1
    j .Lread_cond
.Lread_exit:
    mv a0, sp
    la a1, bias
    call weighted_sum
    call putint
    li a0, 32
    call putch
    lw a0, 44(sp)
    call putint
    li a0, 10
    call putch
    li a0, 0
    ld s0, 64(sp)
    ld ra, 72(sp)
    addi sp, sp, 80
    ret
