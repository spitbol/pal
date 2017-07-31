package main

import (
	"flag"
	"fmt"
)

// itrace traces instructions, strace traces statements, otrace traces osint calls
var itrace, otrace, strace bool
var ifileName string

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
    fmt.Println("argument file",ifileName)
    itrace = true
	_ = ifileName
	_ = startup()
}
