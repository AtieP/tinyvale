# Tinyvale
A tiny stivale/stivale2 bootloader

# What is Tinyvale?
Tinyvale is a tiny stivale and stivale2 bootloader written in pure x86 assembly language. Right now it is not very complete and lacks a lot of functionality and compliance, but it can boot a minimal 32 bit stivale kernel just fine.

# Running
Simply create an ELF file named "elf" in this project's root folder and run `make` and `make run`. To test the bootloader run `make stivale_32`