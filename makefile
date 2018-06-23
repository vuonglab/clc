TARGET = clc

$(TARGET): clc.o evaluator.o
	gcc clc.o evaluator.o -o $(TARGET)

%.o: %.c
	gcc -c $< -o $@

clean:
	rm -f *.o *.a $(TARGET)

test:
	./tests.sh
