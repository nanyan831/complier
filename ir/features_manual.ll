declare i32 @getint()
declare void @putint(i32)

define i32 @transform(i32 %x) {
entry:
  %a = add nsw i32 %x, 3
  %b = mul nsw i32 %a, 2
  %half = sdiv i32 %x, 2
  %base = sub nsw i32 %b, %half
  %rem = srem i32 %x, 2
  %even = icmp eq i32 %rem, 0
  br i1 %even, label %even_path, label %odd_path

even_path:
  %even_result = add nsw i32 %base, 7
  br label %done

odd_path:
  %odd_result = sub nsw i32 %base, 5
  br label %done

done:
  %result = phi i32 [ %even_result, %even_path ], [ %odd_result, %odd_path ]
  ret i32 %result
}

define i32 @main() {
entry:
  %data = alloca [3 x i32], align 4
  br label %cond

cond:
  %i = phi i32 [ 0, %entry ], [ %next, %join ]
  %sum = phi i32 [ 0, %entry ], [ %new_sum, %join ]
  %continue = icmp slt i32 %i, 3
  br i1 %continue, label %body, label %exit

body:
  %input = call i32 @getint()
  %slot = getelementptr inbounds [3 x i32], ptr %data, i32 0, i32 %i
  store i32 %input, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  %positive = icmp sgt i32 %value, 0
  br i1 %positive, label %upper_check, label %fallback

upper_check:
  %small = icmp slt i32 %value, 20
  br i1 %small, label %accepted, label %fallback

accepted:
  %changed = call i32 @transform(i32 %value)
  %accepted_sum = add nsw i32 %sum, %changed
  br label %join

fallback:
  %fallback_sum = add nsw i32 %sum, 1
  br label %join

join:
  %new_sum = phi i32 [ %accepted_sum, %accepted ], [ %fallback_sum, %fallback ]
  %next = add nsw i32 %i, 1
  br label %cond

exit:
  call void @putint(i32 %sum)
  ret i32 0
}
