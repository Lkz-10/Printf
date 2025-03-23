all: build
	./printf

build: printf.o
	gcc -o printf -no-pie main.cpp printf.o

printf.o: printf.s
	nasm -f elf64 -l printf.lst printf.s

clean:
	rm -rf *.o printf
