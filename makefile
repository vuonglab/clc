TARGET = clc

$(TARGET): clc.o evaluator.o
	gcc clc.o evaluator.o -o $(TARGET)

clc.o: clc.c
	gcc -c $< -o $@

evaluator.o: evaluator.c
	gcc -c $< -o $@

clean:
	rm -f *.o *.a $(TARGET)

test:
	./tests.sh
