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

OSINT=./osint

vpath %.c $(OSINT)

ifeq	($(DEBUG),0)
CFLAGS= -D m64 -m64 -static 
else
CFLAGS= -D m64 -g -m64
endif

# Assembler info -- Intel 32-bit syntax
ifeq	($(DEBUG),0)
ASMFLAGS = -f $(ELF) -d m64
else
ASMFLAGS = -g -f $(ELF) -d m64
endif

# Tools for processing Minimal source file.
BASEBOL =   ./bin/spitbol

# Headers for Minimal source translation:
VHDRS=	x64.hdr 

# Other C objects:
# Objects for SPITBOL's HOST function:
HOBJS=
LOBJS=


spitbol: s.go

# link spitbol with dynamic linking
spitbol-dynamic: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) $(LIBS) -lm -ospitbol 

# Assembly language dependencies:
err.o: err.s
s.o: s.s

err.o: err.s


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


# make osint objects
cobjs:	$(COBJS)

# C language header dependencies:
$(COBJS): $(HDRS)
$(MOBJS): $(HDRS)
$(SYSOBJS): $(HDRS)
main.o: $(OSINT)/save.h
sysgc.o: $(OSINT)/save.h
sysxi.o: $(OSINT)/save.h
dlfcn.o: dlfcn.h

# install binaries from ./bin as the system spitbol compilers
install:
	sudo cp ./bin/spitbol /usr/local/bin
clean:
	rm -f $(OBJS) *.o *.lst *.map *.err s.lex s.tmp s.s err.s s.S s.t ./spitbol

z:
	nm -n s.o >s.nm
	spitbol map-$(WS).sbl <s.nm >s.dic
	spitbol z.sbl <ad >ae

sclean:
# clean up after sanity-check
	make clean
	rm tbol*
