TARGET = clc

$(TARGET): clc.o evaluator.o
	gcc $^ -o $@

clc.o: clc.c
	gcc -c $< -o $@

evaluator.o: evaluator.c
	gcc -c $< -o $@

clean:
	rm -f *.o *.a $(TARGET)

test:
	./tests.sh
