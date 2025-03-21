all: build
	./printf

build: printf.o
	ld -s -o printf printf.o

printf.o: printf.s
	nasm -f elf64 -l printf.lst printf.s

clean:
	rm -rf *.o printf
