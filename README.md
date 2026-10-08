# 编译原理预备实验：了解编译器

本仓库用于协作完成课程预备工作“了解编译器、LLVM IR 编程及汇编编程”。实验统一采用阶乘程序，目标汇编选择 RISC-V。

## 当前完成情况

- [x] 设计包含整型变量、赋值、循环及其条件、加乘运算和库函数调用的 SysY/C 阶乘示例。
- [x] 使用 GCC/Clang 观察预处理、LLVM IR、汇编、目标文件和链接阶段。
- [x] 手写与源程序等价的 SSA 形式 LLVM IR，并连接运行时验证。
- [x] 手写 RV64 阶乘主程序和最小 SysY 兼容运行时。
- [x] 使用 RISC-V GNU 工具链汇编、链接，并通过 QEMU 验证。
- [x] 比较 `-g`、`-O0`、`-O2` 和不同目标架构的输出。
- [x] 自写运行时路线覆盖 0 至 12，三种程序共 39 次检查通过。
- [x] 直接连接提供的 `libsysy_x86.a`，C 和手写 IR 共 30 次检查通过。
- [x] 从提供的 `sylib.c` 重建 RISC-V Linux 运行库，C、手写 IR、手写汇编经 QEMU 共 45 次检查通过。
- [x] 增加涵盖全局常量、整数数组、分支、循环、逻辑与和用户函数的 SysY 示例，并手写等价 LLVM IR 与 RV64 汇编。
- [x] 用 Clang 获取该示例的 token、AST、CFG、未优化及优化后的 LLVM IR，并逐项分析。
- [x] 将两个示例的运行库、编译阶段、失败原因和测试边界写入原报告。新增示例在宿主机与 RISC-V 共 40/40 通过。
- [ ] 原包内 `libsysy_riscv.a` 在当前环境直接链接尚未成功：裸机工具链缺少启动文件和库；Linux 工具链无法解析其 `_impure_ptr` 依赖。源码重建成功不等于该原始二进制链接成功。
- [ ] 按要求由两位组员分别完成编译流程观察，并分别记录个人实验；IR 和汇编分工完成。
- [ ] 填写两位组员的姓名、学号、班级和真实分工。
- [ ] 两位组员共同审阅并分别补充自己的实验记录。
- [ ] 成功编译并检查最终 PDF。最近一次内置编译失败原因为 TeX 资源包未缓存且下载失败，源稿已保留；旧的本地 PDF 不代表当前版本。

当前范围是 PPT 中 5 分的“预备工作 1”。总体要求文档里的词法分析器、语法分析器、SSA 生成、优化和完整编译器属于后续独立模块，不在本次完成项内。实验示例覆盖多个代表性特征，但不是完整 SysY 语言实现。阶乘测试的有效域为 `0 <= n <= 12`；未验证全部运行库 API、非法输入或整数溢出；优化部分为中间产物观察，不是性能基准。

## 仓库内容

```text
src/                         SysY/C 示例和宿主机运行时
ir/                         两个示例的手写 LLVM IR
asm/                        两个示例的手写 RISC-V 程序及最小运行时
lib/                        提供的运行库、来源说明和 SHA-256
tests/                      两个示例的输出、退出状态检查
report/prework_report.tex    实验报告源文件
Makefile                     构建和测试入口
```

`build/`、PDF、LaTeX 临时文件以及课程原始 PPT/DOC 都不会提交。`lib/` 的原始库作为实验输入保留，来源和校验方法见 [运行库说明](lib/README.md)；其余生成物均可重新产生。

## 环境要求

需要以下命令可用：

```text
gcc
clang
riscv64-unknown-elf-as
riscv64-unknown-elf-ld
qemu-riscv64
python3
```

本实验验证时使用 GCC 13.3.0、Clang 18.1.3、GNU Binutils 2.42 和 QEMU 8.2.2。

提供的库的 RISC-V Linux 路线还需要 `riscv64-linux-gnu-gcc`、`riscv64-linux-gnu-ar` 和相应的 libc 开发文件。本次使用交叉 GCC 13.3.0 和目标 glibc 2.39；Ubuntu 对应软件包为 `gcc-riscv64-linux-gnu`、`libc6-dev-riscv64-cross`。仅有 `riscv64-unknown-elf-*` 不足以完成这条路线。

## 构建和测试

在仓库根目录执行：

```bash
make all
make test
```

`make all` 仍生成原来的自写运行时版本及各阶段文件。`make test` 对 0 至 12 的每个输入检查三种实现，并与独立阶乘期望值逐字节比较，要求退出状态为 0。实测汇总：

```text
baseline: 39/39 PASS
```

只构建某一部分时可以使用：

```bash
make stages   # 预处理、IR、宿主机汇编、目标文件和自动生成的 RISC-V 汇编
make analysis # 多特征程序的预处理、token、AST、CFG、IR、汇编、目标文件
make c        # C 版本
make ir       # 手写 LLVM IR 版本
make riscv    # 手写 RISC-V 版本
make clean    # 删除 build 目录
```

### 提供的 SysY 运行库

在工具链已正常安装的环境中执行：

```bash
make sysy-inspect      # 原始文件校验、RISC-V ELF 和符号检查
make test-sysy-host    # C/IR 直接连接包内 x86 库：30 次检查
make test-sysy-riscv   # 从包内源码重建 Linux 库：45 次检查
make test-sysy         # 合并两条路线：75 次检查
```

本机未进行系统级安装，而是将 Ubuntu 工具链软件包解包到用户目录。当前机器可直接使用：

```bash
TOOLCHAIN="$HOME/.local/share/complier-riscv-toolchain/root"
export PATH="$TOOLCHAIN/usr/bin:$PATH"
export LD_LIBRARY_PATH="$TOOLCHAIN/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
make test-sysy RISCV_SYSROOT="$TOOLCHAIN"
```

这段用户目录设置只适用于本机已有的工具链，工具链不在 Git 仓库中。协作者正常安装工具链后，不必使用本机路径。

`make test-sysy` 实测为 `75/75 PASS`：每个程序检查 0 至 12，加上 `" \t5\n"` 和 `"+5\n"` 两种输入。包内 `putint` 不输出换行，因此期望值是 `b"120"` 而非 `b"120\n"`；计时信息只保存在标准错误文件中。原自写解析器不支持这些额外输入格式，其基础测试仍使用直接数字输入。

### 多特征 SysY 示例

`src/features.sy` 同时展示全局整型常量、一维数组、`if/else`、`while`、`&&`、用户定义函数以及加减乘除取余。配套文件为 `src/features.c`、`ir/features_manual.ll` 和 `asm/features_riscv64.s`。这仍是实验示例，不是后续作业要求的 SysY 编译器。

```bash
make analysis       # 生成 build/features.* 阶段文件
make test-features  # 宿主 C/IR 与 RISC-V C/IR/汇编，8 组输入共 40 次检查
```

本机用户目录工具链使用前面三行环境变量及 `make test-features RISCV_SYSROOT="$TOOLCHAIN"`。八组输入覆盖零、负数、上下界、奇偶及循环累计；实测 `features: 40/40 PASS`。所有输入、标准输出和标准错误保存在 `build/test-results/features/`。

| 路线 | 实际使用的运行库 | 结果 |
| --- | --- | --- |
| 宿主机 C、手写 IR | 原包内 `lib/libsysy_x86.a` | 30/30 |
| RISC-V C、手写 IR、手写汇编 | `lib/sylib.c` 重建的 `build/sysy/libsysy_riscv_linux.a` | 45/45 |
| 原 RISC-V 预编译库直接链接 | `lib/libsysy_riscv.a` | 当前环境失败，不计为通过 |

生成的输入、标准输出、标准错误和 `results.tsv` 位于 `build/test-results/<测试路线>/`。文件可用于个人记录和截图，但不提交大量生成日志。脚本设有超时，任一检查失败时返回非零状态，不会被后续通过的测试覆盖。

如果教师明确要求使用原始 RISC-V 预编译库而不允许从所给源码重建，仍需补齐该库匹配的 Newlib 工具链、启动和运行环境。具体链接命令与失败分析在报告“步骤十三”，不要写成此项已直接通过。

## 报告应包含的内容

报告初稿位于 `report/prework_report.tex`，已经按照实验过程写成以下内容：

1. 实验任务、环境、文件组织和小组分工。
2. SysY/C 阶乘程序的设计及覆盖的语言特征。
3. `getint/putint` 运行时的作用。
4. 预处理命令、参数、输出和头文件展开分析。
5. 未优化 LLVM IR 中变量、基本块和循环的对应关系。
6. x86-64 汇编、目标文件、未解析符号和链接过程。
7. 手写 LLVM IR 的控制流及 `phi` 指令分析。
8. 自动生成和手写 RISC-V 汇编的寄存器、栈帧及调用约定。
9. RISC-V 运行时、交叉汇编、链接、ELF 检查和 QEMU 运行。
10. `-g`、`-O0`、`-O2`、目标架构和多输入测试等进阶观察。
11. 新增步骤十三：材料校验、输入输出协议、宿主机直连、RISC-V ABI 与标准库依赖、失败证据、源码重建、QEMU 验证、测试范围。
12. 新增步骤十四：SysY 多特征示例的设计、token、AST、CFG、LLVM IR、RISC-V 汇编及 40 次检查。
13. 实验结果、问题处理、结论和参考文献。
14. 每一个实验步骤与 PPT 作业要求的对应关系，并区分完成、部分完成和未完成。

协作修改报告时，请基于实际执行结果书写，不要添加没有运行或无法复现的截图与结论。最终提交前必须把报告首页和“小组分工”中的占位内容改成真实信息。

## 协作约定

- 源码、报告和构建脚本通过 Git 提交；生成的 `build/` 与 PDF 不提交。
- 每次修改 LLVM IR 或 RISC-V 汇编后运行 `make test`、`make test-sysy` 和 `make test-features`；本机后两者需上述工具链设置。
- 提交信息应说明修改对象，例如 `完善 RISC-V 运行时说明`。
- 合并协作者修改前，确认基础 39 次、提供的库 75 次和多特征示例 40 次检查仍通过。
