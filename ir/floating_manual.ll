declare i32 @getint()
declare float @getfloat()
declare void @putint(i32)
declare void @putfloat(float)
declare void @putch(i32)

define float @blend(float %x, float %y, i32 %scale) {
entry:
  %a = fmul float %x, 1.500000e+00
  %b = fdiv float %y, 2.000000e+00
  %shifted = fadd float %a, %b
  %negative = fcmp olt float %shifted, 0.000000e+00
  br i1 %negative, label %neg, label %pos
neg:
  %absolute = fneg float %shifted
  %scale_f = sitofp i32 %scale to float
  %neg_value = fadd float %absolute, %scale_f
  br label %done
pos:
  %pos_value = fsub float %shifted, 2.500000e-01
  br label %done
done:
  %value = phi float [%neg_value, %neg], [%pos_value, %pos]
  ret float %value
}

define i32 @main() {
entry:
  %values = alloca [2 x [2 x float]], align 4
  store [2 x [2 x float]] [[2 x float] [float 5.000000e-01, float 0.000000e+00], [2 x float] [float -1.000000e+00, float 2.000000e+00]], ptr %values, align 4
  %scale = call i32 @getint()
  %x = call float @getfloat()
  %y = call float @getfloat()
  %changed = call float @blend(float %x, float %y, i32 %scale)
  %slot = getelementptr [2 x [2 x float]], ptr %values, i32 0, i32 0, i32 1
  store float %changed, ptr %slot, align 4
  %left_slot = getelementptr [2 x [2 x float]], ptr %values, i32 0, i32 1, i32 0
  %right_slot = getelementptr [2 x [2 x float]], ptr %values, i32 0, i32 1, i32 1
  %value = load float, ptr %slot, align 4
  %left = load float, ptr %left_slot, align 4
  %right = load float, ptr %right_slot, align 4
  %product = fmul float %left, %right
  %result = fadd float %value, %product
  %truncated = fptosi float %result to i32
  call void @putfloat(float %result)
  call void @putch(i32 32)
  call void @putint(i32 %truncated)
  call void @putch(i32 10)
  ret i32 0
}
