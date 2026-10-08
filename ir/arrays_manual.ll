@bias = global [2 x [3 x i32]] [[3 x i32] [i32 1, i32 2, i32 0], [3 x i32] [i32 3, i32 0, i32 0]], align 4

declare i32 @getint()
declare void @putint(i32)
declare void @putch(i32)

; Flatten the fixed triply nested loop while retaining typed GEP strides.
define i32 @weighted_sum(ptr %volume, ptr %weights) {
entry:
  br label %cond
cond:
  %n = phi i32 [0, %entry], [%next, %body]
  %sum = phi i32 [0, %entry], [%new_sum, %body]
  %more = icmp slt i32 %n, 12
  br i1 %more, label %body, label %exit
body:
  %k = sdiv i32 %n, 6
  %within = srem i32 %n, 6
  %i = sdiv i32 %within, 3
  %j = srem i32 %within, 3
  %cell = getelementptr [2 x [3 x i32]], ptr %volume, i32 %k, i32 %i, i32 %j
  %weight_cell = getelementptr [3 x i32], ptr %weights, i32 %i, i32 %j
  %value = load i32, ptr %cell, align 4
  %weight = load i32, ptr %weight_cell, align 4
  %next = add nsw i32 %n, 1
  %product = mul nsw i32 %value, %next
  %partial = add nsw i32 %sum, %product
  %new_sum = add nsw i32 %partial, %weight
  br label %cond
exit:
  ret i32 %sum
}

define i32 @main() {
entry:
  %volume = alloca [2 x [2 x [3 x i32]]], align 4
  br label %cond
cond:
  %n = phi i32 [0, %entry], [%next, %body]
  %more = icmp slt i32 %n, 12
  br i1 %more, label %body, label %exit
body:
  %k = sdiv i32 %n, 6
  %within = srem i32 %n, 6
  %i = sdiv i32 %within, 3
  %j = srem i32 %within, 3
  %cell = getelementptr [2 x [2 x [3 x i32]]], ptr %volume, i32 0, i32 %k, i32 %i, i32 %j
  %value = call i32 @getint()
  store i32 %value, ptr %cell, align 4
  %next = add nsw i32 %n, 1
  br label %cond
exit:
  %result = call i32 @weighted_sum(ptr %volume, ptr @bias)
  call void @putint(i32 %result)
  call void @putch(i32 32)
  %last_cell = getelementptr [2 x [2 x [3 x i32]]], ptr %volume, i32 0, i32 1, i32 1, i32 2
  %last = load i32, ptr %last_cell, align 4
  call void @putint(i32 %last)
  call void @putch(i32 10)
  ret i32 0
}
