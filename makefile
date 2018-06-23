TARGET = clc
CC = cc
PREFIX = /usr/local

$(TARGET): clc.o evaluator.o
	$(CC) clc.o evaluator.o -o $(TARGET)

%.o: %.c
	$(CC) -c $< -o $@

clean:
	rm -f *.o *.a $(TARGET)

test:
	./tests.sh

install: $(TARGET)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp $(TARGET) $(DESTDIR)$(PREFIX)/bin/$(TARGET)

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(TARGET)
