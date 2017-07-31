package main

import (
	"flag"
	"fmt"
)

// itrace traces instructions, strace traces statements, otrace traces osint calls
var itrace, otrace, strace bool
var ifileName string

var instCount = 0      // number of instructions executed
var stmtCount = 0      // number of statements executed (stmt opcode)
var instLimit = 100000 // maximum number of instructions
var stmtLimit = 1000   // maximum number of statements

func main() {
	flag.BoolVar(&itrace, "it", false, "intstruction trace")
	flag.BoolVar(&otrace, "ot", false, "osint call trace")
	flag.BoolVar(&strace, "st", false, "statement trace")
	flag.Parse()
	if flag.NArg() == 0 {
		fmt.Println("argument file required")
		return
	}
	ifileName = flag.Arg(0)
	if itrace || strace {
		otrace = true
	}
	_ = ifileName
	_ = startup()
}
