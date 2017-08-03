
=========

TBOL is a variant of SPITBOL designed to provide a way to port SPITBOL to a new
operating environment without having to produce machine code for the processor at hand.


This is done by generating code for MAM (Minimal Abstract Machine),
an abstract machine with a RISC-like architecture.

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

```
 wa wb wc xl xr xs ia ra cp
```

as well as three work registers:

```
	r0 r1 r2
```

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
```

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

Testing has shown that at least simple loops and some of the SPITBOL
primitives such as DUPL are working, as is the garbage collector.

SPITBOL includes a mark-sweep, compacting garbage collector with "sediments," by which
is meant that long-lived values are detected and, once moved to the lower part of memory,
are not subject to further garbage collection. The garbage collector consists or 750 lines
of Minimal code, of which 250 lines are comments.


## Using Go as an assembler

The file S.GO contains Go source code defining the constants and variables representing the
code for the MAM machine.

File S.GO contains, in order, the following definitions and declarations:

-   _const_ declaration of the opcodes.
-   _const_ declaration of the configuration parameters; 
-   _const_ with  definitions of symbolic variables define using EQU instructions;
-    _program_, an array of ints containing the initial memory content;
-    _const_, declaration giving the values of the symbolic variable values
and the offsets of program labels;
-    _const_, declaration mapping names of OSINT procedures to integer values;
-    _errorMessages_, a map from error numbers to error message text;
-    _prcNames_, a map from line numbers to the name of the Minimal procedure
         defined at that line number in the Minimal source; and
-    _stmtText_, a map from line numbers to the text of the associated Minimal instruction.

The file contains about 36,500 lines.

Compiling this file is both a stress-test for how Go handles initializers and a demonstration
of the use of Go as an assembler.

That the Go compiler is able to compile the file is an impressive feat,
and we here wish to thank the Gophers who made this possible by all their hard work.


## GO.INIT

The repository contains the file GO.INIT, a copy of S.GO, included so you an get
a sense of just how good GO is an handling initializers.

## Back to the Past with Rob Pike

The success using Go as an assembler brought to mind another encounter, by a now
prominent Gopher, with an actual assembler that didn't go so well.

Here's the story, from those long ago days when most programmers actually knew assembly language.

I first met Rob Pike over 35 years ago, soon after he had joined Bell Labs.

SETL (SET Language), a language based on the theory of finite sets,  was created by
Prof. Jack Schwartz of the Courant Institute of Mathematical Sciences (CIMS)
of New York University.

SETL was implemented using LITTLE, a low-level language also created by Jack.
My main role in the SETL project was the implementation of LITTLE and porting
it to new machines so we could port SETL.

Doug McIlroy, head of the department at Bell Labs that created Unix, was a friend of Jack. 
Doug thought the folks at BTL might be interested in SETL, and so asked Rob to work with
me to port LITTLE, and hence SETL, to the Dec VAX using BTL's Unix 32V.

Though the first two implementations of LITTLE (CDC 6600, IBM/360) generated object files, LITTLE
was then ported by generating source assembly-like code for an abstract machine
close to the target architecture.  This approach was based on that used by Macro SPITBOL.

I cut a tape and went off to BTL, explained to Rob how the system worked, and Rob took it from
there.

The port was not easy, to say the least, as Rob did battle with the Unix assembler, `as`.
It seems likely that SETL in T32 was the largest file thrown at `as` until that time, and
Rob broke the assembler many times over, having to fix it every time.

Rob did eventually finish the port, and produced a wonderful report about his experiences.
(I think I have a copy somewhere and will publish it if I can find it. It's a fun read.)

So Rob tamed the assembler that was needed back then, and --  several decades later -- helped create a language
so well designed and implemented that it can be used as an assembler.

Job Well Done.

