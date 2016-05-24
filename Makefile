PACKAGE   := rc3
VERSION   := 1.7.4
RELDATE   := 2016-05-23

PREFIX    := /usr/local
MANPREFIX := $(PREFIX)/share/man

CC        ?= gcc
CFLAGS    += -Wall
CPPFLAGS  += -I$(PREFIX)/include -DPACKAGE=\"$(PACKAGE)\" -DVERSION=\"$(VERSION)\" -DRELDATE=\"$(RELDATE)\"
LDFLAGS   += -L$(PREFIX)/lib
YACC      ?= byacc

include config.mk

SRC := $(ADDON_SRC) builtins.c except.c $(EDIT_SRC) exec.c $(EXECVE_SRC) fn.c footobar.c getopt.c glob.c glom.c hash.c heredoc.c input.c lex.c list.c main.c match.c nalloc.c open.c parse.c print.c redir.c sigmsgs.c signal.c status.c $(SYSTEM_SRC) tree.c utils.c var.c wait.c walk.c which.c

DEP := $(SRC:%.c=.deps/%.d)
OBJ := $(SRC:%.c=%.o)
LIB := $(EDIT_LIB)

BIN := rc3 history mksignal mkstatval tripping

all: rc3

.PHONY: clean install

-include $(DEP)

%.o: %.c
	@mkdir -p .deps/
	$(CC) $(CFLAGS) $(CPPFLAGS) -MMD -MP -MF .deps/$*.d -c -o $@ $<

rc3: $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $(OBJ) $(LIB)

%: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $<

builtins.o fn.o hash.o signal.o status.o: sigmsgs.c

sigmsgs.c: mksignal
	./mksignal

status.o: statval.h

statval.h: mkstatval
	./mkstatval >statval.h

lex.o: parse.c

parse.c: parse.y
	$(YACC) -b parse -d parse.y
	mv parse.tab.c parse.c
	mv parse.tab.h parse.h

check: trip

trip: rc3 tripping
	./rc3 -p < trip.rc

install:
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp rc3 $(DESTDIR)$(PREFIX)/bin/
	chmod 755 $(DESTDIR)$(PREFIX)/bin/rc3
	mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	sed "s!VERSION!$(VERSION)!g; s!RELDATE!$(RELDATE)!g" rc3.1 > $(DESTDIR)$(MANPREFIX)/man1/rc3.1
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/rc3.1

clean:
	rm -f $(OBJ) $(BIN)

