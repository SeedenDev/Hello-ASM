as --64 main.s -o main.o
gcc -o main main.o -nostdlib -static -masm=intel
