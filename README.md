TBOL
=========

Tbol is a variant of SPITBOL designed to provide a way to port SPITBOL to a new
operating environment without having to produce machine code for the processor at hand.

This is done by generating code for an abstract machine with a RISK-like architecture
with, for the most part, the same opcodes as are used on the abstract target machine
defined by Minimal.

The runtime for TBOL is written in the Go language. Since Go is available on a wide
variety of machines, TBOL provides a way to port SPITBOL to these machines with
minimal effort. 
