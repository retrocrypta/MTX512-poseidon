CC=gcc
LD=gcc

CFLAGS=-I../832a/ -Wall
LIBS=-lncurses

ifeq ($(DETECTED_OS),MSYS)
CFLAGS=-I../832a/ -I/ucrt64/include/ncursesw/ -DDEMIST_MSYS
LIBS=-lws2_32 -lncursesw
endif

all: 832ocd

832ocd: 832ocd.c 832ocd_connection.c frontend.c script.c \
	../832a/832defs.c ../832a/832util.c ../832a/section.c ../832a/symbol.c ../832a/codebuffer.c ../832a/mapfile.c ../832a/posix.c
	$(CC) $(CFLAGS) -o $@ $+ $(LIBS) 

clean:
	-rm	832ocd

