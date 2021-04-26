AS = nasm
ASFLAGS = -f bin

all:
	$(AS) $(ASFLAGS) src/boot.asm -o tinyvale -I src/

run:
	qemu-system-x86_64 tinyvale -debugcon stdio -no-reboot -no-shutdown -d int

stivale_32:
	nasm -f elf32 tests/stivale32.asm -o tests/stivale32.o
	ld -Ttests/linker.ld -nostdlib -m elf_i386 tests/stivale32.o -o elf
	$(MAKE) all
	$(MAKE) run

clean:
	rm -f tinyvale tests/*.o elf
