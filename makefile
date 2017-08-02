tbol:
	./bin/spitbol asm.sbl
	./bin/spitbol lex.sbl
	go build

clean:
	rm s.lex s.go
