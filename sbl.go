package main

import (
	"flag"
	"fmt"
)

const (
	r0 = iota
	r1
	r2
	wa
	wb
	wc
	xl
	xr
	xs
	ia
	ra
	cp
)
const (
	xt = xs
)

var regName = map[int]string{
	r0: "r0",
	r1: "r1",
	r2: "r2",
	wa: "wa",
	wb: "wb",
	wc: "wc",
	xl: "xl",
	xr: "xr",
	xs: "xs",
	ia: "ia",
	ra: "ra",
	cp: "cp",
}

/*
const (
	atn = iota
	chp
	cos
	etx
	lnf
	sin
	sqr
	tan
)
*/
/*	operation encoded in four parts:
	_w	gives width in bits
	_m	gives mask to extract value
	operand encod
*/
const (
	op_w  = 8
	dst_w = 4
	src_w = 4
	off_w = 16
	op_m  = 1<<op_w - 1
	dst_m = 1<<dst_w - 1
	src_m = 1<<src_w - 1
	off_m = 1<<off_w - 1
	op_   = 0
	dst_  = op_ + op_w
	src_  = dst_ + dst_w
	off_  = src_ + src_w
)

const (
	stackLength = 1000
)

var opName = map[int]string{
	add:     "add",
	adi:     "adi",
	adr:     "adr",
	anb:     "anb",
	aov:     "aov",
	bct:     "bct",
	beq:     "beq",
	bev:     "bev",
	bge:     "bge",
	bgt:     "bgt",
	bhi:     "bhi",
	ble:     "ble",
	blo:     "blo",
	blt:     "blt",
	bne:     "bne",
	bnz:     "bnz",
	bod:     "bod",
	bri:     "bri",
	brn:     "brn",
	bsw:     "bsw",
	bze:     "bze",
	call:    "call",
	chk:     "chk",
	cmc:     "cmc",
	cne:     "cne",
	cvd:     "cvd",
	cvm:     "cvm",
	dca:     "dca",
	dcv:     "dcv",
	dvi:     "dvi",
	dvr:     "dvr",
	erb:     "erb",
	err:     "err",
	exi:     "exi",
	flc:     "flc",
	ica:     "ica",
	icp:     "icp",
	icv:     "icv",
	ieq:     "ieq",
	ige:     "ige",
	igt:     "igt",
	ile:     "ile",
	ilt:     "ilt",
	ine:     "ine",
	ino:     "ino",
	iov:     "iov",
	itr:     "itr",
	jsrerr:  "jsrerr",
	lcp:     "lcp",
	lcw:     "lcw",
	ldi:     "ldi",
	ldr:     "ldr",
	lei:     "lei",
	load:    "load",
	loadcfp: "loadcfp",
	loadi:   "loadi",
	lsh:     "lsh",
	mfi:     "mfi",
	mli:     "mli",
	mlr:     "mlr",
	mov:     "mov",
	move:    "move",
	mvc:     "mvc",
	mvw:     "mvw",
	mwb:     "mwb",
	ngi:     "ngi",
	ngr:     "ngr",
	nzb:     "nzb",
	orb:     "orb",
	plc:     "plc",
	pop:     "pop",
	popr:    "popr",
	ppm:     "ppm",
	prc:     "prc",
	psc:     "psc",
	push:    "push",
	pushi:   "pushi",
	pushr:   "pushr",
	realop:  "realop",
	req:     "req",
	rge:     "rge",
	rgt:     "rgt",
	rle:     "rle",
	rlt:     "rlt",
	rmi:     "rmi",
	rne:     "rne",
	rno:     "rno",
	rov:     "rov",
	rsh:     "rsh",
	rti:     "rti",
	sbi:     "sbi",
	sbr:     "sbr",
	scp:     "scp",
	store:   "store",
	sub:     "sub",
	sys:     "sys",
	trc:     "trc",
	xob:     "xob",
	zrb:     "zrb",
}
var (
	ip       int
	mem      [100000]int
	reg      [16]int
	stackEnd int
	memLast  int // index of last allocated memory word
	long1, long2 int64
	//	var int1,int2 int32
	int1, int2 int32
	prcstack [32]int
	inst, dst, src, off int
	overflow bool
	op int
	//	var f1, f2 float32
	d1 float64
// itrace traces instructions, strace traces statements, otrace traces osint calls
itrace, otrace, strace bool
ifileName string

instCount = 0      // number of instructions executed
stmtCount = 0      // number of statements executed (stmt opcode)
instLimit = 100000000 // maximum number of instructions
stmtLimit = 100000000   // maximum number of statements
stmtTrace = false
instTrace = false
maxOffset = 0
)

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

	fmt.Println()
	fmt.Println("Minimal instructions executed",stmtCount)
	fmt.Println("Machine instructions executed",instCount)
    fmt.Println("Maximum offset",maxOffset)
}
