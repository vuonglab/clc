TARGET = clc
CC = cc

$(TARGET): clc.o evaluator.o
	$(CC) clc.o evaluator.o -o $(TARGET)

%.o: %.c
	$(CC) -c $< -o $@

clean:
	rm -f *.o *.a $(TARGET)

test:
	./tests.sh
