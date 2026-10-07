declare i32 @getint()
declare void @putint(i32)

define i32 @main() {
entry:
  %n = call i32 @getint()
  br label %cond

cond:
  %i = phi i32 [ 2, %entry ], [ %next, %body ]
  %f = phi i32 [ 1, %entry ], [ %prod, %body ]
  %cmp = icmp sle i32 %i, %n
  br i1 %cmp, label %body, label %exit

body:
  %prod = mul nsw i32 %f, %i
  %next = add nsw i32 %i, 1
  br label %cond

exit:
  call void @putint(i32 %f)
  ret i32 0
}
