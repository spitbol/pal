# SPITBOL makefile using musl-gcc
#	/bin/spitbol -x -u i32 go.sbl

#s.go:	s.lex $(VHDRS) asm.sbl 



tbol:
	./bin/spitbol asm.sbl
	./bin/spitbol lex.sbl

clean:

sclean:
# clean up after sanity-check
	rm s.lex s.go
