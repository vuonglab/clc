TARGET = whatis

$(TARGET): whatis.o evaluator.o
	gcc $^ -o $@

whatis.o: whatis.c
	gcc -c $< -o $@

evaluator.o: evaluator.c
	gcc -c $< -o $@

clean:
	rm -f *.o *.a $(TARGET)

test:
	./tests.sh
