# ISO
![LICENSE](https://img.shields.io/badge/LICENSE-MIT-green.svg) ![VERSION](https://img.shields.io/badge/VERSION-0-blue)

ISO (Intermediate Script Object) is a stack oriented instruction format intended for embedded applications.

The first version is written in Lua for prototyping purposes. It will be ported to C once the specifications have been finalized.
## Hello World
```asm
TAG "msg_start"    REM "Stores current stack pointer"
ARR "Hello World!" REM "Pushes data to stack"
TAG "msg_end"
VAR "msg_start"    REM "Recall stack pointer and push to stack"
VAR "msg_end"
INT 0x12           REM "Print interrupt"
```
You can find more examples under [examples](examples).

## TODO
- Implement remaining instructions
- Implement call stack
- Documentation
- Rewrite in C
## License
This software is free to use. You can modify it and redistribute it under the terms of the MIT license. Check [LICENSE](LICENSE) for further details.
