# IoTAutomake 
IoTAutomake是一个自动化编译工具，旨在为IoT安全研究人员提供快捷的交叉编译支持。该项目可以在已有交叉编译工具链的前提下，自动编译常用的调试工具，目前支持：
- busybox：1.30.0
- strace：5.10
- ltrace：0.7.3
- gdbserver：8.0.1

<!-- PROJECT SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
<!-- PROJECT LOGO -->
<br />

## 主要功能：
- 自动化构建交叉编译流程：在已有交叉编译工具链的前提下，通过预定义的Makefile实现源码下载、解压、补丁以及编译striped、statically linked的二进制程序
- 灵活配置：可以根据需要自定义源码包版本、补丁、修改编译参数

项目结构：
```bash
├── Makefile                # 核心Makefile文件        
├── README.md               # 项目说明
├── patches                 # 补丁文件
│   ├── README.md           # 补丁列表及说明
│   ├── busybox-patch-01
│   └── gdb-patch-01
├── prebuilds               # 编译好的二进制程序：按照file命令展示的架构存放
│   └── ELF_32-LSB-MIPS-MIPS32_rel2_version_1
└── src                     # 源代码目录
```

## 使用说明
1. 编译所有支持的工具
根据已有的交叉编译工具链，传入指定的HOST环境变量
```bash
HOST=mipsel-unknown-linux-uclibc make all
```

2. 编译指定的工具
也可以单独编译指定工具：
```bash
HOST=mipsel-unknown-linux-uclibc make gdbserver
HOST=mipsel-unknown-linux-uclibc make strace
HOST=mipsel-unknown-linux-uclibc make ltrace
HOST=mipsel-unknown-linux-uclibc make busybox
```

3. 清理源码包
清理源码包（不会清理prebuilds目录中已经编译好的二进制程序）
```bash
make clean
```

4. 补丁支持
如果需要应用补丁，可以将补丁文件存放在patches/目录中，并确保命令为*-patch-*，补丁说明在patches/READMD.md中。
欢迎使用者提出针对更多架构、更多指定代码版本的需求到 Issue 或 Pull Request 来改进 IoTAutomake。任何贡献，无论大小，都将帮助改进该项目。

## 许可证说明
本项目遵循 MIT 许可证，详情请参阅 [LICENSE.txt](LICENSE.txt)