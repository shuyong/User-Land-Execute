# JUST FOR FUN
* * *
# User-Land-Execute
User Land Execute Program on Linux / Android

# 项目的缘起
如何在 Linux Program (glibc space) 中调用 Android library (bionic space) ？这是很多人考虑过的问题，也提出过很多解决方案。[libhybris](https://github.com/libhybris/libhybris)项目是最成功的一个，已经可以应用到商业产品中。但是，该项目也有该项目的问题。未知的 CRASH，难以定位，难以理解，难以解决。

那还有没有另外一种解决方案？Yes, you find here !

[libhybris](https://github.com/libhybris/libhybris)项目，是将 Android library (bionic base) 装载到 Linux Program (glibc space) 中，通过移植过的 android dlopen / dlsym 函数获得 bionic base 的函数指针，对特殊的函数，还需要进行封装，然后让 glibc base 的程序可以通过函数指针调用到 bionic base 的函数。glibc base 的函数和 bionic base 的函数在同一个线程里执行。

新的解决方案与之不一样。同样需要用 android dlopen / dlsym 函数获得 bionic space 的函数指针。但程序运行时有两个线程，分别运行 glibc base 和 bionic base 的函数。这两个线程分别称为 glibc space 和 bionic space。glibc space 所获得的 bionic space 的函数指针，调用时需要将这个函数指针投送回 bionic space 中执行。这个方案需要在同一个进程空间里装载不同 base 的代码库，所以需要 User Land Execute 技术。

# User Land Execute
就是不通过 execve 系统调用，而是在程序的用户空间(user space)直接装载和执行一个程序。也就是在用户空间中装载和解析 ELF 格式的程序，然后直接跳转到新的程序入口上。

以前这些工作在 OS 空间中完成。现在在用户空间中完成。这可以让程序更灵活地扩充功能。

## 现有的方案
类似的技术，已经有人研究了不少，积累了宝贵的经验。可以见后面的参考项目列表。

但是这些项目，都是针对 x86 平台编程，有太多的汇编代码无法移植。我一看汇编代码就头痛，而要看 x86 * arm * 32bit * 64bit - 4种汇编，那就是头痛^4。而且这些项目解析 ELF 结构格式的代码也不规范，无法在 32bit / 64bit 环境中兼容。

所以这些项目只能做为参考，让人明白其中的技术原理。但不可以直接使用，让人偷懒。

## 新的方案一
正如[[Linux二进制分析](https://www.epubit.com/book/detail/24950)]一书提到的，采用 Position Independent Executable (PIE) 技术编译的程序可以用 dlopen / dlsym 方式装载和执行。而 Android v4.x 以后，所有底层的 C / C++ 的程序和库都采用了"-pie" & "-fPIE"参数进行编译。似乎是让人有偷懒的可能。

经过测试，Fedora 中的 glibc v2.28 所带的 dlopen / dlsym 的函数可以装载 PIE 程序。但是 ubuntu 所带的 glibc 版本似乎关闭了这个功能。而且 musl-libc 里的 dlopen / dlsym 的函数没有这个功能。最后，最关键的问题就是：glibc 所带的 dlopen / dlsym 函数不可以装载 bionic base 的程序和库。这是因为 dlopen / dlsym 函数是基于当前已解析的符号表(symbol table)，用自己的装载器(loader)装载程序和库的。它们不会检查和使用程序 ELF 头所指示的 loader。也是啊，平时都是一个空间里的兄弟聚在一起干活，谁会费事去写这段无用又费时的代码呢。而 bionic base 的装载器和 glibc base 的不一样(linker vs. ld.so)，这就造成了符号表冲突。

现实还是不能让人偷懒:-(。

## 新的方案二
但是，事情总是有转机。正如[[UNIX 系统技术内幕](https://baike.baidu.com/item/UNIX%20%E9%AB%98%E7%BA%A7%E6%95%99%E7%A8%8B--%E7%B3%BB%E7%BB%9F%E6%8A%80%E6%9C%AF%E5%86%85%E5%B9%95)]一书提到的，大意是：memory-mapped file I/O - mmap 技术，是 SUN 公司在 OS 上发明的两大开创性技术之一。它完全改变了 OS 开发的模式，使得 OS 里大多数代码和用户空间代码一样。其中，程序的装载和解析就使用了 mmap 技术。

偷懒似乎又有了可能。Linux 装载和解析 ELF 文件的代码在"linux/fs/binfmt_elf.c"里。果然是很规范！都是通过调用内部系统调用 API 完成任务，大多可以翻译成用户空间的 API。关键技术还是在 mmap 的应用。

装载和解析 ELF 文件的代码完全是在 mmap 映射后的内存里操作。最后一步跳转到程序入口点的代码，是唯一一处使用到汇编代码的地方。而这汇编代码，在 loader 中已经封装得很好了。本项目采用的就是 musl-libc loader 所封装的跳转宏指令。

两大关键技术点都有人做好了。终于有了偷懒的可能:-)。

# 学到的知识
对于什么是程序空间，什么是 C runtime library，有了新的理解。

从用户空间的程序看，32bit/64bit 的线性虚拟地址，其实就是 32bit/48bit 大小的虚无世界。其中有几个孤岛，就是 OS 这个上帝为了给程序运行，通过 mmap 技术映射出来的实地。程序运行只能在这些孤岛之间来回调用跳转。代码不够用了，调用 dlopen / dlsym 函数扩充功能，最后是调用 mmap 增加代码段(.text)。内存不够用了，调用 mmap 扩充堆(heap)。程序访问超出了 mmap 映射的地址，就陷入虚空中，OS 就给你一个 segment fault ！

从 OS 角度看，用有限的物理内存，在 32bit/48bit 大小的虚无世界中，十个瓶子两个盖，到处应付着，用 mmap 技术提供可用的线性虚拟地址。一个用户程序空间就是一个独立进程空间。各个进程空间之间尽可能复用一些地址段，下面映射同一段内存，有同样的内容。也就是代码段和数据段是复用的，除非发生写入事件，这时用 Copy On Write (COW) 技术把同一段地址给不同进程映射不同的内存，保存不同的内容。所以大多数情况下，同一个 library 的代码段(.text)在不同的程序进程空间中是同一段地址。而用 (PIE) 技术编译的程序也具有 library 的特性。这些是在调用 mmap 函数时，loader 让 OS 所做的选择。

解析 ELF 文件头，其实就是用 mmap 技术对可用地址段进行增增减减，然后在上面进行涂涂改改。代码段(.text)和已初始化数据段(.data)，磁盘文件大小和内存中的大小是一一对应的，直接就在内存上面修改。反正文件是以"Read Only"模式打开，修改内容写不回去。未初始化段(.rss)和堆(heap)，则用 mmap 技术继续开辟新的可用空间。这些工作在用户空间中完全可以进行。通过 execve 系统调用执行的程序，OS 会把当前进程空间的旧的程序的已映射的地址段清理干净，然后给新的程序重新映射地址段。而用 User Land Execute 技术装载和执行的程序，新旧程序的代码同时映射到一个进程空间的不同地址里，相互间都可以访问到。

一个程序里只能有一个 main 入口函数，这是 toolchain 的限制。loader 看到的和要重定位的，只是一个个唯一的函数地址。在一个进程空间中用 User Land Execute 装载程序，已经由 OS 做了选择，将代码装载到同一个进程空间中不同的地址段里。也就是不同程序的 main 入口函数也就有了不同的地址。各个程序的函数在同一个进程空间里同时存在，也就有了相互调用的可能。

OS 和用户空间的程序共享了 mmap 技术，也就是共享了操控堆(heap)的权限。但是 OS 还是牢牢把控着操控栈(stack)的权限。用户空间的程序只能使用栈(stack)，而不能主动切换栈(stack)。谁能操控栈(stack)，谁才是真正的 OS！

# 适用平台
规范的 C 语言编程，规范的 C 语言头文件，规范的 ELF 结构解析，自然就有很好的兼容性。

## Linux Version
本项目的核心功能来自 binfmt_elf.c。自 Linux v2.16 后，binfmt_elf.c 文件已经没有大的功能变化，数据结构也没有大的变化。经过简单测试，本项目理论上可以适应 Linux v3.x 及以后版本。

测试所用的版本，挑选了几个下面软件平台的 Linux Kernel，都是 Linux v3.x 及以后版本：
* Fedora / CentOS
* Ubuntu / Debian
* Android (ARM / Intel)

## Hardware Platform
* ARM 32bit / 64bit, QualComm smartphone.
* Intel 32bit / 64bit.

## Toolchain
* gcc
* llvm / clang

| TC\OS | Linux | Alpine | Android |
|:-----:|:-----:|:------:|:-------:|
| gcc   | YES   | YES    | YES     |
| clang | YES   | YES    | YES     |

## C Runtime Library

| C\S       | glibc | musl-libc | bionic |
|:---------:|:-----:|:---------:|:------:|
| glibc     | YES   | YES       | YES    |
| musl-libc | YES   | YES       | YES    |
| bionic    | YES   | YES       | YES    |

* 注1：只能是 32bit to 32bit / 64bit to 64bit 程序之间可以相互装载执行。
* 注2：32bit/64bit 程序之间不能相互装载，这是因为 ELF 32bit/64bit 的结构宽度不一样，用同一套代码不能同时解析 32bit/64bit 程序。

# License
本项目的核心代码移植自 Linux v4.15 - linux/fs/binfmt_elf.c。所以本项目及其衍生项目的License，自然要跟随 Linux，采用 GPL 2.0。

# 参考项目
1. [Learning Linux Binary Analysis](https://www.amazon.com/dp/1782167102/ref=rdr_ext_tmb)
1. [Bitlackeys Research](http://bitlackeys.org/)
1. [elfmaster](https://github.com/elfmaster/)
1. [Modern Userland Exec](http://www.stratigery.com/userlandexec.html)
1. [Position-independent code](https://en.wikipedia.org/wiki/Position-independent_code)
1. [UNIX Internals: The New Frontiers](http://www.gettem.org/UNIX-Internals-The-New-Frontiers-Vahalia.pdf)
