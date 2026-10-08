CC := gcc
CLANG := clang
AR := ar
RISCV_READELF := riscv64-linux-gnu-readelf
RISCV_NM := riscv64-linux-gnu-nm
RISCV_OBJDUMP := riscv64-linux-gnu-objdump
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

.PHONY: all stages test analysis sysy sysy-host sysy-riscv sysy-inspect test-sysy test-sysy-host test-sysy-riscv features-host features-riscv test-features clean
.PHONY: options test-options test-compiler advanced test-advanced test-parallel verify

all: stages sysy

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
	$(CLANG) -S -emit-llvm -g -O0 -I src src/features.c -o $(BUILD)/features_clang_g_O0.ll
	$(CLANG) -S -emit-llvm -O2 -I src src/features.c -o $(BUILD)/features_clang_O2.ll
	$(CLANG) --target=riscv64-unknown-elf -S -O0 -I src src/features.c -o $(BUILD)/features_clang_riscv64_O0.s
	$(CC) -S -O0 -I src src/features.c -o $(BUILD)/features_gcc_O0.s
	$(CC) -c -O0 -I src src/features.c -o $(BUILD)/features.o

test: verify

$(BUILD)/sysy:
	mkdir -p $(BUILD)/sysy

sysy: sysy-host sysy-riscv

$(BUILD)/sysy/libsysy_host.a: lib/sylib.c lib/sylib.h | $(BUILD)/sysy
	$(CC) -O0 -c lib/sylib.c -o $(BUILD)/sysy/sylib_host.o
	$(AR) rcs $@ $(BUILD)/sysy/sylib_host.o

sysy-host: $(BUILD)/sysy/libsysy_host.a
	$(CC) -O0 src/factorial.c $(BUILD)/sysy/libsysy_host.a -o $(BUILD)/sysy/factorial_c_host
	$(CLANG) ir/factorial_manual.ll $(BUILD)/sysy/libsysy_host.a -o $(BUILD)/sysy/factorial_ir_host

sysy-riscv: | $(BUILD)/sysy
	$(RISCV_CC) $(RISCV_FLAGS) -O0 -c lib/sylib.c -o $(BUILD)/sysy/sylib_riscv_linux.o
	$(RISCV_AR) rcs $(BUILD)/sysy/libsysy_riscv_linux.a $(BUILD)/sysy/sylib_riscv_linux.o
	$(RISCV_CC) $(RISCV_FLAGS) -static -O0 src/factorial.c $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/factorial_c_riscv
	$(CLANG) --target=riscv64-linux-gnu -march=rv64gc -mabi=lp64d -c ir/factorial_manual.ll -o $(BUILD)/sysy/factorial_ir_riscv.o
	$(RISCV_CC) $(RISCV_FLAGS) -static $(BUILD)/sysy/factorial_ir_riscv.o $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/factorial_ir_riscv
	$(RISCV_CC) $(RISCV_FLAGS) -c asm/factorial_riscv64.s -o $(BUILD)/sysy/factorial_asm_riscv.o
	$(RISCV_CC) $(RISCV_FLAGS) -static $(BUILD)/sysy/factorial_asm_riscv.o $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/factorial_asm_riscv

sysy-inspect: sysy-riscv
	sha256sum -c lib/SHA256SUMS
	$(RISCV_READELF) -h -A $(BUILD)/sysy/libsysy_riscv_linux.a > $(BUILD)/sysy/archive-elf.txt
	$(RISCV_NM) -g $(BUILD)/sysy/libsysy_riscv_linux.a > $(BUILD)/sysy/archive-symbols.txt

test-sysy: sysy
	$(PYTHON) tests/check_factorial.py sysy --build $(BUILD) --qemu $(QEMU)

test-sysy-host: sysy-host
	$(PYTHON) tests/check_factorial.py sysy-host --build $(BUILD) --qemu $(QEMU)

test-sysy-riscv: sysy-riscv
	$(PYTHON) tests/check_factorial.py sysy-riscv --build $(BUILD) --qemu $(QEMU)

features-host: $(BUILD)/sysy/libsysy_host.a
	$(CC) -O0 src/features.c $(BUILD)/sysy/libsysy_host.a -o $(BUILD)/sysy/features_c_host
	$(CLANG) ir/features_manual.ll $(BUILD)/sysy/libsysy_host.a -o $(BUILD)/sysy/features_ir_host

features-riscv: sysy-riscv
	$(RISCV_CC) $(RISCV_FLAGS) -static -O0 src/features.c $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/features_c_riscv
	$(CLANG) --target=riscv64-linux-gnu -march=rv64gc -mabi=lp64d -c ir/features_manual.ll -o $(BUILD)/sysy/features_ir_riscv.o
	$(RISCV_CC) $(RISCV_FLAGS) -static $(BUILD)/sysy/features_ir_riscv.o $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/features_ir_riscv
	$(RISCV_CC) $(RISCV_FLAGS) -static asm/features_riscv64.s $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/features_asm_riscv

test-features: features-host features-riscv
	$(PYTHON) tests/check_features.py --build $(BUILD) --qemu $(QEMU)

options: sysy-riscv $(BUILD)/sysy/libsysy_host.a
	$(CLANG) -O2 src/features.c $(BUILD)/sysy/libsysy_host.a -o $(BUILD)/sysy/features_c_host_O2
	$(CLANG) -g -O0 src/features.c $(BUILD)/sysy/libsysy_host.a -o $(BUILD)/sysy/features_c_host_g
	$(CLANG) -O2 ir/features_manual.ll $(BUILD)/sysy/libsysy_host.a -o $(BUILD)/sysy/features_ir_host_O2
	$(RISCV_CC) $(RISCV_FLAGS) -static -O2 src/features.c $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/features_c_riscv_O2
	$(CLANG) --target=riscv64-linux-gnu -march=rv64gc -mabi=lp64d -O2 -c ir/features_manual.ll -o $(BUILD)/sysy/features_ir_riscv_O2.o
	$(RISCV_CC) $(RISCV_FLAGS) -static $(BUILD)/sysy/features_ir_riscv_O2.o $(BUILD)/sysy/libsysy_riscv_linux.a -o $(BUILD)/sysy/features_ir_riscv_O2

test-options: options
	$(PYTHON) tests/check_features.py --suite options --build $(BUILD) --qemu $(QEMU)

test-compiler: stages sysy analysis options
	$(PYTHON) tests/check_compiler.py --build $(BUILD) --cc $(CC) --clang $(CLANG) --riscv-objdump $(RISCV_OBJDUMP) --riscv-readelf $(RISCV_READELF)

ADVANCED := arrays floating
ADVANCED_ROUTES := sy_host ir_host sy_riscv ir_riscv asm_riscv sy_host_O2
advanced: sysy-riscv $(foreach sample,$(ADVANCED),$(foreach route,$(ADVANCED_ROUTES),$(BUILD)/sysy/$(sample)_$(route))) $(foreach sample,$(ADVANCED),$(BUILD)/$(sample)_clang_O0.ll $(BUILD)/$(sample)_clang_O2.ll)

$(BUILD)/sysy/%_sy_host: src/%.sy src/sysy_runtime.h $(BUILD)/sysy/libsysy_host.a | $(BUILD)/sysy
	$(CLANG) -O0 -ffp-contract=off -include src/sysy_runtime.h -x c $< -x none $(BUILD)/sysy/libsysy_host.a -o $@

$(BUILD)/sysy/%_sy_host_O2: src/%.sy src/sysy_runtime.h $(BUILD)/sysy/libsysy_host.a | $(BUILD)/sysy
	$(CLANG) -O2 -ffp-contract=off -include src/sysy_runtime.h -x c $< -x none $(BUILD)/sysy/libsysy_host.a -o $@

$(BUILD)/sysy/%_ir_host: ir/%_manual.ll $(BUILD)/sysy/libsysy_host.a | $(BUILD)/sysy
	$(CLANG) $< $(BUILD)/sysy/libsysy_host.a -o $@

$(BUILD)/sysy/%_sy_riscv: src/%.sy src/sysy_runtime.h sysy-riscv
	$(RISCV_CC) $(RISCV_FLAGS) -O0 -ffp-contract=off -static -include src/sysy_runtime.h -x c $< -x none $(BUILD)/sysy/libsysy_riscv_linux.a -o $@

$(BUILD)/sysy/%_ir_riscv: ir/%_manual.ll sysy-riscv
	$(CLANG) --target=riscv64-linux-gnu -march=rv64gc -mabi=lp64d -c $< -o $@.o
	$(RISCV_CC) $(RISCV_FLAGS) -static $@.o $(BUILD)/sysy/libsysy_riscv_linux.a -o $@

$(BUILD)/sysy/%_asm_riscv: asm/%_riscv64.s sysy-riscv
	$(RISCV_CC) $(RISCV_FLAGS) -static $< $(BUILD)/sysy/libsysy_riscv_linux.a -o $@

$(BUILD)/%_clang_O0.ll: src/%.sy src/sysy_runtime.h | $(BUILD)
	$(CLANG) -O0 -ffp-contract=off -S -emit-llvm -include src/sysy_runtime.h -x c $< -o $@

$(BUILD)/%_clang_O2.ll: src/%.sy src/sysy_runtime.h | $(BUILD)
	$(CLANG) -O2 -ffp-contract=off -S -emit-llvm -include src/sysy_runtime.h -x c $< -o $@

test-advanced: advanced
	$(PYTHON) tests/check_advanced.py --build $(BUILD) --qemu $(QEMU)

test-parallel: | $(BUILD)
	$(PYTHON) tests/check_parallel.py --build $(BUILD) --cc $(CC)

verify: test-sysy test-features test-options test-compiler sysy-inspect test-advanced test-parallel

clean:
	rm -rf $(BUILD)
