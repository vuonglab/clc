SRCS = clc.c evaluator.c
DEPS = evaluation_result.h 
TARGET = clc

CC = cc
OPTS = -O2
LIBS =

INSTALLDIR = /usr/local

OBJS = $(SRCS:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) -o $(TARGET) $(OBJS) $(LIBS)

%.o: %.c $(DEPS)
	$(CC) $(OPTS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

test: $(TARGET)
	./tests.sh

install: $(TARGET)
	mkdir -p $(DESTDIR)$(INSTALLDIR)/bin
	cp $(TARGET) $(DESTDIR)$(INSTALLDIR)/bin/$(TARGET)

uninstall:
	rm -f $(DESTDIR)$(INSTALLDIR)/bin/$(TARGET)
