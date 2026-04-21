CC := gcc
CFLAGS := -std=c99 -Wall -Wextra -O2 -I$(PWD)/src
SRC := src/help_tree.c

.PHONY: all basic deep hidden clean

all: basic deep hidden

basic: examples/basic.c $(SRC)
	$(CC) $(CFLAGS) -o examples/basic examples/basic.c $(SRC)

deep: examples/deep.c $(SRC)
	$(CC) $(CFLAGS) -o examples/deep examples/deep.c $(SRC)

hidden: examples/hidden.c $(SRC)
	$(CC) $(CFLAGS) -o examples/hidden examples/hidden.c $(SRC)

clean:
	rm -f examples/basic examples/deep examples/hidden
