AS = nasm
ASFLAGS = -f bin

all:
	$(AS) $(ASFLAGS) src/boot.asm -o tinyvale -I src/

run:
	qemu-system-x86_64 -no-reboot -no-shutdown tinyvale -debugcon stdio

clean:
	rm tinyvale
