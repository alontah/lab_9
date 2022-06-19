all: lab9

lab9: skeleton.o
	ld -m elf_i386 skeleton.o -o lab9

skeleton.o: skeleton.s
	nasm -f elf skeleton.s -o skeleton.o

clean:
	rm *.o lab9
