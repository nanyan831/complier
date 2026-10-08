# 实验提供的 SysY 运行库

这四个文件原样提取自用户提供的 `lib.tar.gz`，未修改源码、头文件或二进制内容。不据文件名推断其官方来源；压缩包没有提供许可证或构建说明。

原压缩包 SHA-256：

```text
d6fd112ecb6d318e4cb2ea377aa0770cb8b9736c3d024fde4a9300ac2058a0ac
```

从仓库根目录执行 `sha256sum -c lib/SHA256SUMS` 检查提取文件的一致性。

| 文件 | 本实验中的用途 |
| --- | --- |
| `sylib.c`、`sylib.h` | 分析接口；为 RISC-V Linux 重新编译运行库 |
| `libsysy_x86.a` | 直接链接 C 与手写 LLVM IR，验证包内预编译库 |
| `libsysy_riscv.a` | 检查 ELF、ABI 和依赖，保留原库链接失败的可复现对象 |

未引入压缩包里的 AArch64 库和共享库，因为本实验不使用它们。重新生成的 RISC-V Linux 静态库位于 `build/sysy/libsysy_riscv_linux.a`，不得将其称为原包内的 `libsysy_riscv.a`。

## 接口与兼容性

- `putint` 只输出整数，不附加换行；析构函数 `after_main` 将 `TOTAL` 信息写入标准错误。这与自写最小运行时的输出协议不同。
- 包内 RISC-V 对象标记为双精度浮点 ABI；配套代码使用 `-march=rv64gc -mabi=lp64d`。指令集/ABI 一致仍不代表 C 标准库环境一致。
- 原 RISC-V 库引用 `_impure_ptr`，结合 [Newlib 重入说明](https://sourceware.org/newlib/libc.html) 可推断其依赖 Newlib；还依赖 `printf`、`scanf`、`gettimeofday` 等外部函数。裸机工具链实测缺少启动文件和库；换用 Linux/glibc 工具链后仍报 `_impure_ptr` 未定义。因此实际成功路线是从源码重建，而非原 RISC-V 库直接链接。
- `sylib.h` 含有计时全局变量的定义。主程序继续使用 `src/sysy_runtime.h` 中仅有的 `getint/putint` 声明，与本实验调用的接口一致；提供的完整头文件仅由 `sylib.c` 引入，避免多翻译单元重复定义。这里没有链接自写运行时实现。
- 本实验仅验证有效整数输入下的 `getint/putint` 和正常程序启动、退出流程。不验证数组、浮点或计时接口的全部行为；也不对无效输入和 EOF 作保证。
