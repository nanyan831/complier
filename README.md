# 编译原理预备实验：了解编译器

本仓库用于协作完成课程预备工作“了解编译器、LLVM IR 编程及汇编编程”。实验统一采用阶乘程序，目标汇编选择 RISC-V。

## 当前完成情况

- [x] 设计包含变量、赋值、循环、判断、算术运算和函数调用的 SysY/C 示例。
- [x] 使用 GCC/Clang 观察预处理、LLVM IR、汇编、目标文件和链接阶段。
- [x] 手写与源程序等价的 SSA 形式 LLVM IR，并连接运行时验证。
- [x] 手写 RV64 阶乘主程序和最小 SysY 兼容运行时。
- [x] 使用 RISC-V GNU 工具链汇编、链接，并通过 QEMU 验证。
- [x] 比较 `-g`、`-O0`、`-O2` 和不同目标架构的输出。
- [x] 使用 0、1、5、7 四组输入进行一致性测试。
- [x] 完成详细 LaTeX 实验报告初稿。
- [ ] 填写两位组员的姓名、学号、班级和真实分工。
- [ ] 两位组员共同审阅报告，补充需要的实验截图。
- [ ] 使用 XeLaTeX/Overleaf 生成最终 PDF。

## 仓库内容

```text
src/                         SysY/C 示例和宿主机运行时
ir/factorial_manual.ll       手写 LLVM IR
asm/factorial_riscv64.s      手写 RISC-V 主程序
asm/sysy_runtime_riscv64.s   手写 RISC-V 运行时
report/prework_report.tex    实验报告源文件
Makefile                     构建和测试入口
```

`build/`、PDF、LaTeX 临时文件以及课程原始 PPT/DOC 都不会提交。所有生成结果都应从仓库内源码重新产生。

## 环境要求

需要以下命令可用：

```text
gcc
clang
riscv64-unknown-elf-as
riscv64-unknown-elf-ld
qemu-riscv64
```

本实验验证时使用 GCC 13.3.0、Clang 18.1.3、GNU Binutils 2.42 和 QEMU 8.2.2。

## 构建和测试

在仓库根目录执行：

```bash
make all
make test
```

`make all` 会生成编译各阶段文件、C 可执行程序、LLVM IR 可执行程序和 RISC-V 可执行程序。`make test` 会分别运行三种实现并比较输出。预期结果为：

```text
input=0 C=1 LLVM-IR=1 RISC-V=1
input=1 C=1 LLVM-IR=1 RISC-V=1
input=5 C=120 LLVM-IR=120 RISC-V=120
input=7 C=5040 LLVM-IR=5040 RISC-V=5040
```

只构建某一部分时可以使用：

```bash
make stages   # 预处理、IR、宿主机汇编、目标文件和自动生成的 RISC-V 汇编
make c        # C 版本
make ir       # 手写 LLVM IR 版本
make riscv    # 手写 RISC-V 版本
make clean    # 删除 build 目录
```

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
11. 实验结果、问题处理、结论和参考文献。
12. 每一个实验步骤与 PPT 作业要求的对应关系。

协作修改报告时，请基于实际执行结果书写，不要添加没有运行或无法复现的截图与结论。最终提交前必须把报告首页和“小组分工”中的占位内容改成真实信息。

## 协作约定

- 源码、报告和构建脚本通过 Git 提交；生成的 `build/` 与 PDF 不提交。
- 每次修改 LLVM IR 或 RISC-V 汇编后运行 `make test`。
- 提交信息应说明修改对象，例如 `完善 RISC-V 运行时说明`。
- 合并协作者修改前，确认三种实现的四组测试仍然一致。
