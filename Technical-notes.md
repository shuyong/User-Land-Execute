# 实现的技术要点

要实现 User Land Execute，其实并不难。
* 初步的 ELF 文件头的解析，由 binfmt_elf.c 文件中的 load_elf_binary 函数完成了。
* 动态装载的 ELF 文件头的解析与重定位，由 loader 程序完成了。
* 调用重定位后的程序的入口点，由 loader 程序完成了。

脏活累活都由别人完成了:-)。移植开发人员只需要理解：
* OS 与用户空间的参数传递是通过 ELF Auxiliary Vectors 完成。
  - Linux ELF Auxiliary Vectors 的格式和宽度。
  - 在各平台上使用哪些条目。
* ELF Auxiliary Vectors 是保存在栈(stack)上的。
* 参数传递只使用了栈指针(Stack Pointer - SP)寄存器。没有使用其它任何一个通用寄存器。
* 用户程序的入口 _start 函数，所做的第一件事情就是将 SP 赋给第一个通用寄存器，再做其它初始化事情。
* 在第一个 C 语言函数，第一个参数，汇编代码上就是第一个通用寄存器，就是前面保存下来的 SP 的值，指向 ELF Auxiliary Vectors。
* 这样 C 语言级别的代码就可以处理这个 auxv 了。最后在 C 语言用户级别的入口 main 函数，就可以看到从中提取出来的 argc / argv 参数了。

剩下的就是自己的脏活累活了:-(。

# 参考文档
1. [About ELF Auxiliary Vectors](http://articles.manugarg.com/aboutelfauxiliaryvectors)
1. [getauxval() and the auxiliary vector](https://lwn.net/Articles/519085/)
1. [Optimized libraries for Linux on Power](https://developer.ibm.com/tutorials/optimized-libraries-for-linux-on-power/)
1. [ELF FILE – CHAPTER 3: DYNAMIC LINKER AND SOURCE CODE PROTECTION](https://hydrasky.com/malware-analysis/elf-file-chapter-3-dynamic-linker-and-source-code-protection/)
1. Android bionic loader: linker
1. musl-libc loader: ldso
