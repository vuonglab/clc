TARGET = clc
CC = cc
PREFIX = /usr/local

$(TARGET): clc.o evaluator.o
	$(CC) clc.o evaluator.o -o $(TARGET)

%.o: %.c evaluation_result.h
	$(CC) -c -O2 $< -o $@

clean:
	rm -f *.o *.a $(TARGET)

test: $(TARGET)
	./tests.sh

install: $(TARGET)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp $(TARGET) $(DESTDIR)$(PREFIX)/bin/$(TARGET)

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(TARGET)
