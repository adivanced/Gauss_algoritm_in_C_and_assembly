main: main.o func.o
	gcc main.o func.o -o main

main.o: main.c read.h
	gcc main.c -c

func.o: func.asm
	nasm -f elf64 func.asm -o func.o