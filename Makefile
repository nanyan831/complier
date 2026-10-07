CC := gcc
CLANG := clang
RISCV_AS := riscv64-unknown-elf-as
RISCV_LD := riscv64-unknown-elf-ld
QEMU := qemu-riscv64
BUILD := build

.PHONY: all stages c ir riscv test clean

all: stages c ir riscv

$(BUILD):
	mkdir -p $(BUILD)

stages: | $(BUILD)
	$(CC) -E -I src src/factorial.c -o $(BUILD)/factorial.i
	$(CLANG) -S -emit-llvm -O0 -Xclang -disable-O0-optnone -I src src/factorial.c -o $(BUILD)/factorial_clang_O0.ll
	$(CLANG) -S -emit-llvm -O2 -I src src/factorial.c -o $(BUILD)/factorial_clang_O2.ll
	$(CLANG) -S -emit-llvm -g -O0 -Xclang -disable-O0-optnone -I src src/factorial.c -o $(BUILD)/factorial_clang_g_O0.ll
	$(CLANG) --target=riscv64-unknown-elf -S -O0 -I src src/factorial.c -o $(BUILD)/factorial_clang_riscv64_O0.s
	$(CC) -S -O0 -I src src/factorial.c -o $(BUILD)/factorial_gcc_O0.s
	$(CC) -c -O0 -I src src/factorial.c -o $(BUILD)/factorial.o

c: | $(BUILD)
	$(CC) -O0 src/factorial.c src/sysy_runtime.c -o $(BUILD)/factorial_c

ir: | $(BUILD)
	$(CLANG) ir/factorial_manual.ll src/sysy_runtime.c -o $(BUILD)/factorial_ir

riscv: | $(BUILD)
	$(RISCV_AS) -march=rv64gc -mabi=lp64 -mno-relax asm/factorial_riscv64.s -o $(BUILD)/factorial_riscv64.o
	$(RISCV_AS) -march=rv64gc -mabi=lp64 -mno-relax asm/sysy_runtime_riscv64.s -o $(BUILD)/sysy_runtime_riscv64.o
	$(RISCV_LD) --no-relax $(BUILD)/factorial_riscv64.o $(BUILD)/sysy_runtime_riscv64.o -o $(BUILD)/factorial_riscv64

test: all
	@for n in 0 1 5 7; do \
		c_out=$$(printf '%s\n' "$$n" | $(BUILD)/factorial_c); \
		ir_out=$$(printf '%s\n' "$$n" | $(BUILD)/factorial_ir); \
		rv_out=$$(printf '%s\n' "$$n" | $(QEMU) $(BUILD)/factorial_riscv64); \
		printf 'input=%s C=%s LLVM-IR=%s RISC-V=%s\n' "$$n" "$$c_out" "$$ir_out" "$$rv_out"; \
		test "$$c_out" = "$$ir_out" && test "$$ir_out" = "$$rv_out"; \
	done

clean:
	rm -rf $(BUILD)
