CC := gcc
CLANG := clang
RISCV_AS := riscv64-unknown-elf-as
RISCV_LD := riscv64-unknown-elf-ld
RISCV_READELF := riscv64-unknown-elf-readelf
RISCV_NM := riscv64-unknown-elf-nm
QEMU := qemu-riscv64
PYTHON := python3
RISCV_CC ?= riscv64-linux-gnu-gcc
RISCV_AR ?= riscv64-linux-gnu-ar
RISCV_SYSROOT ?=
RISCV_FLAGS := -march=rv64gc -mabi=lp64d
ifneq ($(RISCV_SYSROOT),)
RISCV_FLAGS += --sysroot=$(RISCV_SYSROOT)
endif
BUILD := build

.PHONY: all stages c ir riscv test analysis sysy sysy-host sysy-riscv sysy-inspect test-sysy test-sysy-host test-sysy-riscv features-host features-riscv test-features clean

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

analysis: | $(BUILD)
	$(CC) -E -I src src/features.c -o $(BUILD)/features.i
	$(CLANG) -fsyntax-only -I src -Xclang -dump-tokens src/features.c 2> $(BUILD)/features.tokens.txt
	$(CLANG) -fsyntax-only -I src -Xclang -ast-dump src/features.c > $(BUILD)/features.ast.txt
	$(CLANG) --analyze -I src -Xclang -analyzer-checker=debug.DumpCFG src/features.c -o $(BUILD)/features.plist 2> $(BUILD)/features.cfg.txt
	$(CLANG) -S -emit-llvm -O0 -I src src/features.c -o $(BUILD)/features_clang_O0.ll
	$(CLANG) -S -emit-llvm -O2 -I src src/features.c -o $(BUILD)/features_clang_O2.ll
	$(CLANG) --target=riscv64-unknown-elf -S -O0 -I src src/features.c -o $(BUILD)/features_clang_riscv64_O0.s
	$(CC) -S -O0 -I src src/features.c -o $(BUILD)/features_gcc_O0.s
	$(CC) -c -O0 -I src src/features.c -o $(BUILD)/features.o

c: | $(BUILD)
	$(CC) -O0 src/factorial.c src/sysy_runtime.c -o $(BUILD)/factorial_c

ir: | $(BUILD)
	$(CLANG) ir/factorial_manual.ll src/sysy_runtime.c -o $(BUILD)/factorial_ir

riscv: | $(BUILD)
	$(RISCV_AS) -march=rv64gc -mabi=lp64 -mno-relax asm/factorial_riscv64.s -o $(BUILD)/factorial_riscv64.o
	$(RISCV_AS) -march=rv64gc -mabi=lp64 -mno-relax asm/sysy_runtime_riscv64.s -o $(BUILD)/sysy_runtime_riscv64.o
	$(RISCV_LD) --no-relax $(BUILD)/factorial_riscv64.o $(BUILD)/sysy_runtime_riscv64.o -o $(BUILD)/factorial_riscv64

test: all
	$(PYTHON) tests/check_factorial.py baseline --build $(BUILD) --qemu $(QEMU)

$(BUILD)/sysy:
	mkdir -p $(BUILD)/sysy

sysy: sysy-host sysy-riscv

sysy-host: | $(BUILD)/sysy
	$(CC) -O0 src/factorial.c lib/libsysy_x86.a -o $(BUILD)/sysy/factorial_c_host
	$(CLANG) ir/factorial_manual.ll lib/libsysy_x86.a -o $(BUILD)/sysy/factorial_ir_host

sysy-riscv: | $(BUILD)/sysy
	$(RISCV_CC) $(RISCV_FLAGS) -O0 -c lib/sylib.c -o $(BUILD)/sysy/sylib_riscv_linux.o
	$(RISCV_AR) rcs $(BUILD)/sysy/libsysy_riscv_linux.a $(BUILD)/sysy/sylib_riscv_linux.o
	$(RISCV_CC) $(RISCV_FLAGS) -static -O0 src/factorial.c $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/factorial_c_riscv
	$(CLANG) --target=riscv64-linux-gnu -march=rv64gc -mabi=lp64d -c ir/factorial_manual.ll -o $(BUILD)/sysy/factorial_ir_riscv.o
	$(RISCV_CC) $(RISCV_FLAGS) -static $(BUILD)/sysy/factorial_ir_riscv.o $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/factorial_ir_riscv
	$(RISCV_CC) $(RISCV_FLAGS) -static asm/factorial_riscv64.s $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/factorial_asm_riscv

sysy-inspect: | $(BUILD)/sysy
	sha256sum -c lib/SHA256SUMS
	$(RISCV_READELF) -h -A lib/libsysy_riscv.a > $(BUILD)/sysy/archive-elf.txt
	$(RISCV_NM) -g lib/libsysy_riscv.a > $(BUILD)/sysy/archive-symbols.txt

test-sysy: sysy
	$(PYTHON) tests/check_factorial.py sysy --build $(BUILD) --qemu $(QEMU)

test-sysy-host: sysy-host
	$(PYTHON) tests/check_factorial.py sysy-host --build $(BUILD) --qemu $(QEMU)

test-sysy-riscv: sysy-riscv
	$(PYTHON) tests/check_factorial.py sysy-riscv --build $(BUILD) --qemu $(QEMU)

features-host: | $(BUILD)/sysy
	$(CC) -O0 src/features.c lib/libsysy_x86.a -o $(BUILD)/sysy/features_c_host
	$(CLANG) ir/features_manual.ll lib/libsysy_x86.a -o $(BUILD)/sysy/features_ir_host

features-riscv: sysy-riscv
	$(RISCV_CC) $(RISCV_FLAGS) -static -O0 src/features.c $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/features_c_riscv
	$(CLANG) --target=riscv64-linux-gnu -march=rv64gc -mabi=lp64d -c ir/features_manual.ll -o $(BUILD)/sysy/features_ir_riscv.o
	$(RISCV_CC) $(RISCV_FLAGS) -static $(BUILD)/sysy/features_ir_riscv.o $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/features_ir_riscv
	$(RISCV_CC) $(RISCV_FLAGS) -static asm/features_riscv64.s $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/features_asm_riscv

test-features: features-host features-riscv
	$(PYTHON) tests/check_features.py --build $(BUILD) --qemu $(QEMU)

clean:
	rm -rf $(BUILD)
