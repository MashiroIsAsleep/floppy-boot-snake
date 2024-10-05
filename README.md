Floppy disk boot sector snake game based on x86 NASM assembly.

Incase you dont know what is a boot sector game: here is a short explaination from copilot:
A floppy disk boot sector game is a small game that is stored in the boot sector of a floppy disk. When the computer boots from the floppy disk, it loads and runs the game directly. These games are typically written in Assembly language and are very small in size due to the limited space available in the boot sector (usually 512 bytes).
# Installation
## 1. With libraries in terminal
Make sure you installed NASM and qemu via
```bash
pip install NASM
pip install qemu
```

Compile the .asm code into a .bin file. 
```bash
nasm boot_game.asm -f bin -o boot_game.bin
```

Make a disk image of the corresponding size
```bash
dd if=/dev/zero of=boot_game.img bs=512 count=1
dd if=boot_game.bin of=boot_game.img conv=notrunc
```

Compile and run the code via qemu
```bash
qemu-system-x86_64 -drive file=boot_game.img,format=raw,if=floppy
```
## 2. With dosbox
Pretty much what you have to do is either compile the .asm file or pad the disk image into a 1.44mb image with zeroes. Attach the folder to dosbox as a floppy disk, and it should run.