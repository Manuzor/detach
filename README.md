detach
======

Tiny Win32 executable written in [zig](https://ziglang.org/) that starts the given command line as a detached process. Somehow, in all these years, cmd `start` and pwsh `Start-Process` did not manage to add an option for this. So I made my own.