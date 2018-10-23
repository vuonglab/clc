# What is clc?

clc is an elementary arithmetic calculator for the command line. It adds, subtracts, multiplies and divides decimal numerals.

# Why clc?

Since clc is written in C and supports just basic math operations, it has an installation size of only 18 KiB. To eliminate the need to type quotation marks or backslashes when entering expressions on many *nix shells, clc accepts the letter x as the multiplication sign and allows square brackets to be used in place of parentheses.

Other, more powerful console calculators exist (see 
[here](https://fossbytes.com/how-to-use-calculator-in-linux-command-line/),
[here](https://wiki.archlinux.org/index.php/List_of_applications/Science#Calculator), and
[here](https://askubuntu.com/questions/378661/any-command-line-calculator-for-ubuntu)), but they are considerably bigger, ranging from 114 KiB ([concalc](http://extcalc-linux.sourceforge.net/concalcdescr.html)) to 101 MiB ([octave](https://www.gnu.org/software/octave/)). They feature arbitrary precision, built-in scripting language, differential and integral calculus, radix conversion, symbolic calculation, and various mathemetical functions.

# Precision

If clc is compiled on the x86 architecture and the compiler supports 80-bit extended precision, clc will output 16 to 19 significant digits. On platforms that support even higher precision, clc should still produce answers with 16-19 digits. In all other scenarios, answers will have 13 to 15 significant digits.

# Building clc

clc can be compiled to run on 32-bit and 64-bit systems running Linux, macOS, BSD variants, and Windows.

## Building clc on Linux, macOS, and BSD

To build clc:

```
$ make
```

After building clc, it is recommended to run tests on it:

```
$ make test
```

To install clc in /usr/local/bin:

```
$ make install
```

To install in a different directory, simply copy the built clc file to that folder.

## Building clc on Windows

To build clc:

```
C:\clc> nmake
```

To run tests:

```
C:\clc> nmake test
```

To install, just copy the clc.exe file to a folder of your choice.

# Running clc

To calculate 1+1, type:

```
$ clc 1+1
```

To see program usage, type:

```
$ clc --help
```

# Build with

Most make tool and any C99-compliant compiler should be able to build clc.

clc has been built and tested on the following systems:

* Arch Linux 4.18.5-arch1-1-ARCH: [GNU C Compiler 8.2.1 20180831](https://gcc.gnu.org/) and [GNU Make 4.2.1](https://www.gnu.org/software/make/)
* Arch Linux 4.14.67-1-ARCH: (g)cc 8.2.0 and GNU Make 4.2.1 on Raspberry Pi 2B (February 2015 model)

* FreeBSD 11.1-RELEASE-p13: clang 4.0.0 and make 20170510
* NetBSD 7.1.2: (g)cc 4.8.5 and make version unknown
* OpenBSD 6.3: clang 5.0.1 and make version unknown

* Debian 9.5: (g)cc 6.3.0 20170516 and GNU Make 4.1
* Ubuntu 18.04: (g)cc 7.3.0 and GNU Make 4.1
* Fedora release 28: (g)cc 8.0.1 20180324 and GNU Make 4.2.1

* macOS 10.13.6: clang 1000.10.44.2 and GNU Make 3.81

* Windows 7 Starter: Microsoft C compiler version 19.15.26730 and NMAKE 14.15.26730.0 in Visual Studio Community 2017

# Issues

## Incorrect answer running on Windows Subsystem for Linux

On Windows Subsystem for Linux (WSL), clc gets compiled for extended precision. However, the hardware floating-point unit (FPU), which clc uses to do its calculations, is set to double precision instead of extended precision by WSL. As a result, clc may produce incorrect answers. This is a [known issue with WSL](https://github.com/Microsoft/WSL/issues/830) and it affects other programs.

There are two workarounds:

1. Modify clc.c to set the FPU to use extended precision when clc starts up (recommended):
    ```
    #include <fpu_control.h>
    ...
    int main(int argc, char **argv)
    {
        fpu_control_t cw;
        _FPU_GETCW(cw);
        cw |= 0x300; // select extended precision
        _FPU_SETCW(cw);
        ...
    ```

2. Modify the function `get_floating_point_type` in clc.c to always return DOUBLE.

# Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on the process for adding features and fixing bugs. It also lists the planned features.

# Versioning

This project uses [semantic versioning](http://semver.org/). For the versions available, see the [tags on this repository](https://github.com/vuonglab/clc/tags). 

# Authors

* **Phu Vuong** - *Initial work* - [VuongLab](https://github.com/VuongLab)

See also the list of [contributors](https://github.com/vuonglab/clc/contributors) who participated in this project.

# License

This project is licensed under the [MIT License](http://opensource.org/licenses/MIT).

# Acknowledgments

The expression parser in clc is based on the one described in [Part II: Expression Parsing](https://compilers.iecc.com/crenshaw/tutor2.txt) in [Let's Build a Compiler, by Jack Crenshaw](https://compilers.iecc.com/crenshaw/).
