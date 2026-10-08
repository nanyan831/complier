# Lab1：实验代码与报告撰写建议

目标架构为 RISC-V。本目录对应《预备工作 - 了解你的编译器》PPT 的实验，不是完整的 SysY 编译器。

实验统一放在 `lab1` 分支。协作时使用该分支，不再向 `main` 添加实验内容。这里只保留完整实验代码、必要依赖、构建测试脚本和报告撰写建议，不放旧报告或生成的二进制、PDF、日志。

## 文件与运行

```text
src/          SysY 示例、C 编译入口和运行库接口声明
ir/           四个示例的手写 LLVM IR
asm/          四个示例的手写 RISC-V 程序
experiments/  预处理、语法语义诊断、自动并行化的实验输入
lib/          所给运行库源码、头文件与 SHA-256 校验值
tests/        结果验证脚本
Makefile      构建和验证入口
README.md     要求核查、复现方法与报告撰写建议
```

`.gitignore`、`.gitattributes` 是必要配置。`build/` 是本地生成物，不属于交付源码。`src/factorial.c`、`src/features.c` 仅引入接口头和对应 `.sy`，供 C 编译阶段观察使用，算法只维护一份。

依赖 GCC、Clang、Python 3、strace、GCC OpenMP 运行时 libgomp、QEMU 用户态 `qemu-riscv64`、宿主 binutils，以及带目标 libc 的 RISC-V Linux 工具链（`riscv64-linux-gnu-{gcc,ar,readelf,nm,objdump}`）。不再需要裸机工具链或原始预编译运行库。工具链正常安装后，在仓库根目录执行：

```bash
make verify
```

本机交叉 Linux 工具链使用用户目录，执行：

```bash
TOOLCHAIN="$HOME/.local/share/complier-riscv-toolchain/root"
export PATH="$TOOLCHAIN/usr/bin:$PATH"
export LD_LIBRARY_PATH="$TOOLCHAIN/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
make verify RISCV_SYSROOT="$TOOLCHAIN"
```

协作者正常安装工具链后不需要本机路径。验证环境为 GCC 13.3、Clang 18.1.3、binutils 2.42、QEMU 8.2.2；交叉 Linux 工具链使用 GCC 13.3、glibc 2.39。诊断及反汇编检查依赖工具输出格式，换版本后需要分析失败原因，不能直接删除断言。

## 要求核查

依据 PPT 第 2 页，示例应覆盖数值运算、赋值、条件分支、循环、函数及其他进阶特性。

按最新确认，仅完成本 PPT 的预备工作，不扩展到后续编译器任务。PPT 的“其他进阶特性”用一维/二维/三维数组、数组传参、浮点运算和类型转换示例落实；不声称穷尽全部 SysY 特性。总体文档中的通用编译器、张量类型及自有优化器不列为本次待完成项目，也不冒称已经实现。

| 要求 | 当前状态 | 证据或缺口 |
| --- | --- | --- |
| 简单 C/C++ 示例的预处理、编译、汇编、链接 | 已实现并运行；个人分析待写 | `make stages`、`make test-compiler`，阶乘中间产物与链接前后检查 |
| 编译器内部更细阶段 | 已获取产物并完成部分检查 | token、AST、CFG、语法和语义诊断；取得产物不等于已写出逐步解释 |
| 整数、声明及初始化、赋值、条件、循环、函数、作用域和注释 | 所选示例已覆盖并测试 | `src/features.sy` 及阶乘程序，包含 break/continue、算术、关系和逻辑运算 |
| 等价手写 LLVM IR 和 RISC-V | 四个示例已实现并测试 | factorial、features、arrays、floating；正确性结论限于约定输入域 |
| 进阶：一维数组 | 已有整数数组示例 | 源码、手写 IR 的 GEP、手写汇编元素访问及测试 |
| 进阶示例：二维、三维数组 | 已实现并测试 | `arrays.sy`、手写 IR/汇编；数组形参、部分初始化补零、行优先寻址；24 组输入乘 6 条路线 |
| 进阶示例：浮点常量、变量、存储和运算 | 已实现并测试 | `floating.sy`、手写 IR/汇编；浮点二维数组、函数传参、比较、四则运算、整数转换；30 组输入乘 6 条路线 |
| 链接所给 SysY 运行库 | 已完成；用户已确认源码重建方案可用 | 宿主机、RISC-V 均从未修改的所给源码构建对应静态库，所有示例链接该库运行 |
| 修改程序观察变化 | 已做所选对照 | 宏 MODE=0/1、诊断 CASE=0..5；不声称做过所有可能的程序变化 |
| 调试、优化选项探索 | 已做所选对照 | 检查 -g、O0/O2 产物和运行；未做 GDB 单步、O1/O3 或性能计时 |
| 自动并行化探索 | 已在宿主 x86-64 完成 | 无 OpenMP pragma；GCC 生成 GOMP_parallel；strace 确认 3 个工作线程；串行与并行结果一致，不冒充 RISC-V 并行实验 |
| 两人各自完成流程、IR/汇编分工和备案 | 未核实 | 自动测试不能代替两人的真实独立实验记录 |
| 完整论文结构、个人报告及 PDF 提交 | 未完成，按当前要求暂缓 | 此文件只是撰写建议，不是报告或可提交 PDF |

PPT 程序实验已有代码与运行验证；正式报告/PDF 按要求暂缓，两人独立实验及备案需自行落实。不把本实验等同于实现通用 SysY 编译器。

## 实测结果和边界

本次完整执行 `make verify` 成功，结果如下：

| 测试 | 结果 | 范围 |
| --- | --- | --- |
| sysy | 75/75 | 阶乘 15 组输入、五种实现，均链接所给源码重建的运行库 |
| features | 65/65 | 13 组输入、五种实现 |
| options | 65/65 | 同样 13 组输入、五个调试/优化版本 |
| compiler | 50/50 | 宏、阶段、诊断、重定位和调试信息等检查 |
| advanced | 324/324 | 数组 24 组、浮点 30 组，各六条路线 |
| parallel | 46/46 | 三个版本的结果、编译器并行化产物及实际线程创建检查 |

sysy、features、options、advanced 合计 529 次程序结果检查。compiler 的 50 项和 parallel 的 46 项另计，后者包含 15 次串行/并行结果比较及跟踪运行。清理删除的是简化运行库的重复基线和同一源程序的重复构建，不减少输入用例或实验特性。两份原始运行库源码文件 SHA-256 校验均通过。生成证据位于 `build/test-results/`，包含输入、stdout、stderr 和 results.tsv/results.json；编译器与并行化实验还有 commands.json、checks.json 等。

- 阶乘结论限于 `0 <= n <= 12`。手写 RV64 阶乘使用 64 位运算，不能据此声称其溢出行为等同于 C/IR 的 32 位整数。
- 多特征程序最多读取三个整数；第二或第三个输入为 -99 时提前结束，范围外值贡献 1，只有 1..19 进入算术函数。负数输入测试没有检验负数参与除法、取余的行为。
- IR 中显式表达了短路控制流，但测试没有右侧副作用或陷阱，不能声称专门验证了短路副作用语义。
- `.sy` 的直接执行对照是用 `clang -x c` 编译 C 兼容示例，不是专用 SysY 编译器验证。
- 多维数组测试包含 12 个单独位置的单位输入、零、连续数及固定种子随机数；值在 -1000..1000 内，避免有符号溢出。
- 浮点按 binary32 逐步舍入建立独立期望值，用十六进制输入输出准确比较结果位模式及向零截断整数；使用 `-ffp-contract=off`，不宣称验证 NaN、无穷大或超范围转换。
- 自动并行化依赖宿主 libgomp 和允许 strace 的 Linux 环境；没有性能计时，不声称加速比。
- 未验证全部输入、非法输入、EOF、整数溢出、所有运行库接口；有限测试不等于普遍正确性证明。

## 报告逐步撰写建议

每步按“要求 → 操作和命令 → 输出片段 → 原因解释 → 结论与限制”组织。以下为操作线索，不是代写好的报告。

### 1. 环境与分工

记录 GCC、Clang、QEMU 和交叉工具链版本，说明宿主 x86-64 与目标 RV64 不同。写真实姓名、学号、IR/汇编分工及两人分别完成编译流程的记录。对应 PPT 合作要求，不能用同一次运行记录代替两人独立完成。

### 2. 源程序与输入域

对照 `src/factorial.sy`、`src/features.sy` 解释循环、终止标记、范围筛选和 transform 函数。逐项标记语言特性在代码中的位置。手算输入 `2 3 4` 得 41，`2 -99` 得 16，`-99 2 3` 得 23。对应示例设计要求；同时列出未覆盖的进阶特性。

### 3. 预处理

执行 `make stages`、`make test-compiler`。C 入口引入 `.sy` 源码及接口头，对照 `build/factorial.i` 解释 include 展开；比较 `experiments/preprocess.c` 与 compiler 证据中的 `preprocess-0.i`、`preprocess-1.i`。说明宏展开、条件编译、头文件保护、注释消失、字符串内的注释样式文字保留。两个模式分别输出 14 和 10。对应“预处理器做了什么”。

### 4. 词法、语法、语义与控制流

执行 `make analysis`。在 `build/features.tokens.txt` 找一条表达式的 token，在 `features.ast.txt` 找函数、嵌套作用域和变量引用，在 `features.cfg.txt` 找循环、break、continue。对照 `experiments/diagnostics.c` 的 CASE=1..5 与 stderr，分别解释非法表达式、未声明名字、错误参数个数、常量赋值、作用域越界；有效 CASE=0 输出 52。对应编译器内部阶段观察，不得写成自己实现分析器。

### 5. 自动生成的 IR

比较 `build/factorial_clang_O0.ll`、`build/features_clang_O0.ll` 与源代码，解释 alloca/load/store、比较、分支和调用。把 while 对应到条件、循环体、回边及出口基本块。对应“研究各阶段输出与源程序关系”。

### 6. 手写 LLVM IR

解释 `ir/factorial_manual.ll` 的循环 phi，以及 `ir/features_manual.ll` 的数组 GEP、短路基本块、合流 phi 和提前退出。每个 phi 都指出值来自哪条前驱边。执行 `make test-sysy`、`make test-features`，引用手写 IR 路线的真实输出与退出码。对应手写等价 IR 要求，不能称为已实现 mem2reg。

### 7. 汇编器与链接器

比较自动生成汇编与源程序。查看 compiler 证据的 `host-object.stdout`、`host-linked.stdout`、`host-dynamic-relocations.stdout`、`host-plt.stdout`，说明未解析函数引用、重定位和链接后地址的变化。RISC-V 对照 `riscv-object.stdout`、`riscv-linked.stdout`、`riscv-linked-relocations.stdout`。说明汇编生成可重定位目标文件、链接解决符号依赖；不要把某个静态程序无重定位推广到动态链接程序。

### 8. 手写 RISC-V

以 `asm/features_riscv64.s` 为例：main 分配 64 字节栈帧、保存 ra/s0/s1；s0 为索引、s1 为累加值；数组元素地址由 sp 加索引左移两位得到。说明 a0 的参数与返回值用途、call/ret、divw/remw、条件分支、寄存器恢复和 16 字节栈对齐。逐块对照 IR，再列 QEMU 验证结果。对应手写汇编要求；本次选择 RISC-V，不需额外 ARM 才满足架构选择。

### 9. SysY 运行库

执行 `make sysy-inspect`，校验所给源码并查看重建的 RISC-V 库的 ELF、ABI 和符号。说明 putint 不输出换行、计时信息写 stderr，测试为何按字节比较 stdout。构建命令见 Makefile：宿主机使用 GCC 和 ar，RISC-V 使用 Linux 交叉工具链及 rv64gc/lp64d；所有静态库生成到 build/sysy。报告写“从所给运行库源码构建并链接”，不写“直接链接原始预编译库”。对应运行库连接要求及链接依赖分析。

### 10. 调试、优化与修改程序

执行 `make test-options`、`make test-compiler`。比较 O0、-g O0、O2 的 IR，并结合 `ir-observations.json` 定位 alloca、phi 和调试位置的变化。C 入口引用 `.sy`，调试信息应映射到实际算法所在的 features.sy。解释优化前后为何仍须验证结果，计数不能证明性能提升。宏和诊断输入是程序变化对照。对应 PPT 鼓励探索。

### 11. 多维数组进阶示例

执行 `make test-advanced`。`src/arrays.sy` 使用二维 bias 和三维 volume，通过数组参数传入 weighted_sum。说明 `{{1,2},{3}}` 其余元素自动为零；三维元素字节偏移为 `4*(6*k+3*i+j)`。手写 IR 保留有类型的 GEP，循环手工展平成 n=0..11，再用除法和余数还原 k/i/j；汇编直接用连续地址和 n%6 访问权重。说明展平是在固定维度下人工表达等价算法，不是实现循环优化器。

期望校验式为 `sum((n+1)*input[n]) + 12`，并额外输出最后一个元素；全零输入输出 `12 0`，输入 0..11 输出 `584 11`。每个单位输入可定位一处寻址错误。解释数组实参传递地址，而不是复制整个数组。对应 PPT 的进阶特性和手写等价程序。

### 12. 浮点进阶示例

对照 `src/floating.sy`、`ir/floating_manual.ll`、`asm/floating_riscv64.s`。说明 float 常量、二维数组存储、fmul/fdiv/fadd/fsub、fcmp、sitofp/fptosi；RISC-V 对应 flw/fsw、浮点运算、flt.s、fcvt.s.w、`fcvt.w.s ... rtz`。混合参数中 x/y 用 fa0/fa1，scale 用 a0；float 返回值用 fa0。输入 `3 0x1p+1 0x1p+0` 得 1.25 和截断后的 1。

记录实际发现的问题：最初源码将 x 乘无后缀 1.5，按 C 编译时引入 double 运算，部分随机例子与单精度 IR 相差一个最低有效位；改为显式声明 const float 常量后通过。解释为何测试不能只比较常见整数浮点值，且不应放宽容差来掩盖语义差异。这里使用精确位模式比较，不伪造精度一致。

### 13. 自动并行化

执行 `make test-parallel`，源码为 `experiments/parallel.c`。它没有 OpenMP pragma，循环的不同迭代写 output 的不同元素。脚本比较 O0、O2 串行、O2 加 `-ftree-parallelize-loops=4` 三种构建，关闭向量化以区分两个概念。[GCC 13.3 文档](https://gcc.gnu.org/onlinedocs/gcc-13.3.0/gcc/Optimize-Options.html#index-ftree-parallelize-loops) 说明该选项用于将可独立执行的迭代分给线程。

证据位于 `build/test-results/parallel/`：parloops.txt 有成功分析记录，parallel-transform.stdout 显示 transform 调用 GOMP_parallel；parallel.strace 有三个成功的线程创建调用，serial.strace 没有。失败的 clone3 探测不计线程数。五个种子、三个版本的结果分别与 Python 独立计算值相比较。说明这是宿主平台的 GCC 探索，不是手写 OpenMP，也不是 RISC-V 自动并行化或加速比实验。

### 14. 验证、限制与个人报告

从结果文件中选择正常输入、边界、提前退出、数组寻址和浮点舍入各一例，给出独立期望值。引用上表汇总，不把多种实现的重复测试计成新增作业任务。明确未做全语言编译器、非法输入处理、性能测量，保持“完成/部分完成/未完成/未核实”的区别。

按 PPT 写题目、摘要、关键词、引言、工作和结果、结论及参考文献，最后附步骤与要求对应表。两人共同定框架，再各写独立实验和分工部分，分别提交 PDF。当前仅保留建议，不生成报告、不声称 PDF 已完成；正式撰写时再核对模板与参考资料。

## 运行库来源

`lib/sylib.c`、`lib/sylib.h` 来自用户提供的 `lib.tar.gz`，内容未修改，使用 `sha256sum -c lib/SHA256SUMS` 校验。源码重建方案已由用户确认可用，仓库不保留原预编译库和失败路线。`lib/sylib.h` 含计时全局变量定义，主程序用 `src/sysy_runtime.h` 的薄声明避免重复定义；该头文件没有运行库实现。
