
=========

TBOL is a variant of SPITBOL designed to provide a way to port SPITBOL to a new
operating environment without having to produce machine code for the processor at hand.


This is done by generating code for MAM (Minimal Abstract Machine),
an abstract machine with a RISK-like architecture.

Runtime support for SPITBOL is provided by OSINT (Operating System INTerface).
The standard OSINT used to port SPITBOL is written in C, and contains just over
11,000 lines.

The runtime for TBOL is written entirely in Go.  Since Go is available on a wide
variety of machines, TBOL thus provides a way to port SPITBOL to 
anywhere where Go is available, which, thanks to the work of Gophers
worldwide, is today almost everywhere these days.


## Abstract Machine

MAM is word addressable with a word size of 32. There is no byte addressing.
The initial implementation supports the ASCII character set. This will be followed
by a version using Unicode.


MAM has the following registers defined by Minimal::

 wa wb wc xl xr xs ia ra cp

as well as three work registers:

	r0 r1 r2

Register r0 is always zero.

MAM has as its opcodes those defined by Minimal as well as a few others
added to assist in debugging and performance analysis.

An instruction has four components:

* _opcode_ is the operation code, encoded in eight bits.
* _src_ is the source register, encoded in four bits.
* _dst_ is the destination register, encoded in four bits.
* _off_ is an offset, encoded in 16 bits.


## Translating Minimal to Go

The translation of the Minimal source to machine code for MAM is done as follows:

The program LEX.SBL is used to tokenize the file S.MIN, which as the code
for SPITBOL written in Minimal, reading S.MIN and producing the file S.LEX.

The program ASM.SBL is used to translate S.LEX to S.GO,
which defines the initial state of the abstract machine.

The file SBL.GO is the main program.

The file INTERP.GO is an interpreter which interprets the initial image defined by
S.GO to translate and execute SPITBOL programs.

The file SYS.GO contains the runtime (OSINT).

To try the system, do

```
    $ cd $GOPATH
    $ go get github.com/spitbol/tbol
    $ cd $GOPATH/src/github.com/spitbol/tbol
``

The translation is done with the commands:

```
    $ sbl lex.sbl
    $ sbl asm.sbl
    $ go build
```

This produces a statically linked program TBOL.

A simple test can be done with

```
    $ ./tbol hi.sbl
```

## Status

As of this writing in early August 2017 only a very small part of OSINT has been implemented,
just enough to run programs and write to standard output.

Simple programs have shown that a least simple loops and some of the SPITBOL
primitives such as DUPL are working, as is the garbage collector.

SPITBOL includes a mark-sweep, compacting garbage collector with "sediments," by which
is meant that long-lived values are detected and, once moved to the lower part of memory,
are not subject to further garbage collection. The garbage collector consists or 750 lines
of Minimal code, of which 250 lines are comments.


## Using Go as an assembler


This is sample output from translating the Minimal code for SPITBOL to the declarations
and variables needed to effect interpreation of the abstract target machine MAM.

Compiling the file is both a stress-test for how Go handles initializers and a demonstration
of the use of Go as an assembler.

File S.GO contains, in order, the following definitions and declarations:

*   _const_ declaration of the opcodes.
*   _const_ declaration of the configuration parameters CFP_*;
*    definitions of symbolic variables define using EQU instructions;
*    _program_, an array of ints containing the initial memory content;
*    _const_, declaration giving the values of the symbolic variable values
and the offsets of program labels;
*    _const_, declaration mapping names of OSINT procedures to integer values;
*    _error_messages_, a map from error numbers to error message text;
*    _prc_names_, a map from line numbers to the name of the Minimal procedure
         defined at that line number in the Minimal source; and
*    _stmt_text_, a map from line numbers to the text of the associated Minimal instruction.

The file S.GO contains about 36,500 lines.

That the Go compiler is able to compile the file is an impressive feat
and we here wish to thank the Gophers who made this possible by all their hard work.


## GO.WOW

The repository contains the file GO.WOW, a copy of S.GO, included so you an get
a sense of just how good GO is an handling initializers.

## Back to the Past with Rob Pike

I first met Rob Pike over 35 years ago. Rob had just joined Bell Labs after getting
his M.S. in Physics from Caltech (I had gotten a BS.S. in math about fifteen years earlier),
and competing in the 1980 Olympics as a member of the Canadian archery team. (1)

Doug McIlroy was a friend of Jack Shwartz of the Courant Institute of Mathematical Sciences
(CIMS) at New York University. I had then been working for a decade on the imlementation of SETL (SET Language), a programming languaged with finite sets as the fundamental datatype.

I had spend most of my time on the SETL project implementing and porting  LITTLE,
a lower-level language created by Jack with the partial-world field as the basic datatype.
(Our work was done on the CDC 66000, which had 60-bit words, was word-addressable,
and only one megabyte of main memory, so partial-word operations were important.)

A few years earlier, I had spent a couple of weeks in Leeds, England, workkng with Anthony (Tony)
McCann ofiii Leeds Universitry. Tony and Robert B. K. Dewar were the co-authors of Macro SPITBOL.
After that visit I decided to see if LITTLE could more easily be ported by generating code
in the same way as SPITBOL, first by using T10 to port LITTLE to the DEC-10, and then T32
to port LITTLE to the VAX 11/780.

Doug thought the folks at BTL might be interested in SETL, and so asked Rob to work with
me to port LITTLE (and hence SETL) to the VAX using BTL's Unix 32V.

I cut a tape and went off to BTL, explained how the system worked, and Rob took it from
there.

The port was not easy, to say the least, as Rob did battle with the Unix assembler, as.
It seems likely that SETL in T32 was the largest file thrown at as until that time, and
Rob broke it many times over.

Rob did eventually finish the port, and produced a wonderful report about his experiences.
(I think I have a copy somehwhere and will publish it if I can locate it, as it is a very fun read.)

A couple of years later Rob invited to visit him at Bell Labs to see his "BLIT" terminal.
I thought it a clear technical breakthrough in showing what was possible with a display
terminal. It was far ahead of its time, and it's a shame Bell was never able to bring it to market.

I was so impressed I arranged a demo at CIMS, so Rob could show it folks from CIMS,
Columbia, and Rpckefeller University.

Though Go in impressive, I still consider the BLIT to be his greatest accomplishment.


(1) I later remembered there were no Olympic Games in 1980,
though it took me a while to realize that Rob was spoofing me.
