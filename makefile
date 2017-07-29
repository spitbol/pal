# SPITBOL makefile using musl-gcc

ws?=64

debug?=0
EXECUTABLE=spitbol

os?=unix

OS=$(os)
WS=$(ws)
DEBUG=$(debug)

CC=musl-gcc
ELF=elf$(WS)

# SPITBOL Version:
MIN=   s

# Minimal source directory.
MINPATH=./



# Tools for processing Minimal source file.
BASEBOL =   ./bin/spitbol


tbol: s.go


# SPITBOL Minimal source
go.sbl:	s.lex go.sbl
	$(BASEBOL) -x -u i32 go.sbl

s.go:	s.lex $(VHDRS) asm.sbl 

	$(BASEBOL) -x -u $(WS) asm.sbl

s.lex: $(MINPATH)s.min s.cnd lex.sbl
	 $(BASEBOL) -x -u $(WS) lex.sbl

s.err: s.s

err.s: s.cnd err.sbl s.s
	   $(BASEBOL) -x -1=s.err -2=err.s err.sbl


# install binaries from ./bin as the system spitbol compilers
install:
	sudo cp ./bin/spitbol /usr/local/bin
clean:

sclean:
# clean up after sanity-check
	make clean
	rm tbol*
