    .section .text
    .globl blend
    .globl main
blend:
    li t0, 0x3fc00000
    fmv.w.x ft0, t0
    fmul.s ft0, fa0, ft0
    li t0, 0x40000000
    fmv.w.x ft1, t0
    fdiv.s ft1, fa1, ft1
    fadd.s ft0, ft0, ft1
    fmv.w.x ft1, zero
    flt.s t0, ft0, ft1
    beqz t0, .Lpositive
    fneg.s ft0, ft0
    fcvt.s.w ft1, a0
    fadd.s fa0, ft0, ft1
    ret
.Lpositive:
    li t0, 0x3e800000
    fmv.w.x ft1, t0
    fsub.s fa0, ft0, ft1
    ret

main:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    call getint
    mv s0, a0
    call getfloat
    fsw fa0, 16(sp)
    call getfloat
    fmv.s fa1, fa0
    flw fa0, 16(sp)
    mv a0, s0
    call blend
    # values[0][1], values[1][0], values[1][1] in row-major storage.
    fsw fa0, 4(sp)
    li t0, 0x3f000000
    sw t0, 0(sp)
    li t0, 0xbf800000
    sw t0, 8(sp)
    li t0, 0x40000000
    sw t0, 12(sp)
    flw ft0, 8(sp)
    flw ft1, 12(sp)
    fmul.s ft0, ft0, ft1
    flw ft1, 4(sp)
    fadd.s fa0, ft1, ft0
    # SysY float-to-int conversion truncates toward zero, not nearest.
    fcvt.w.s s0, fa0, rtz
    call putfloat
    li a0, 32
    call putch
    mv a0, s0
    call putint
    li a0, 10
    call putch
    li a0, 0
    ld s0, 48(sp)
    ld ra, 56(sp)
    addi sp, sp, 64
    ret
