package main

import (
	"bufio"
	"bytes"
	"fmt"
	//	"io"
	"os"
	"time"
)

const (
	maxreclen = 1024
)

type fcblk struct { // file control block
	file    *os.File
	output  bool
	name    string
	open    bool
	illegal bool
	eof     bool
	reclen  int
	reader  *bufio.Reader
	writer  *bufio.Writer
}

// scblk1 and scblk2 are memory indices of work areas used to return strings
// to the interpreter in the form of an scblk.

var (
	scblk0    int // null string
	scblk1    int
	scblk2    int
	fcblkid   int
	fcblks    map[int]*fcblk
	fcb0      *fcblk // fcblk for stdin
	fcb1      *fcblk // fcblk for stdout
	fcb2      *fcblk // fcblk for stderr
	fcbn      int
	timeStart time.Time
)

func sysax() int {
	// Will need to mimic the swcoup function if want to use spitbol as unix filter
	return 0
}

func sysbs() int {
	panic("sysbs not implemented.")
}

func sysbx() int {
	timeStart = time.Now()
	return 0
	panic("sysbx not implemented.")
}

func syscm() int {
	// syscm needed only if .ccmc conditional option selected
	panic("syscm not implemented.")
}

func sysdc() int {
	// SPITBOL now open open source, so no need to check expiry of trial version.
	return 0
}

func sysdm() int {
	// No core dump for now.
	return 0
}

func sysdt() int {
	t := time.Now()
	// TODO: Need to initialize scblk1 and scblk2 to blocks im mem[]
	s := t.Format(time.RFC822)
	reg[xl] = minString(scblk0, maxreclen, s)
	return 0
}

func sysea() int {
	//	fmt.Printf("sysea wa %v wb %v wc %v xr %v %v\n",
	//		reg[wa], reg[wb], reg[wc], reg[xr], reg[xl])
	// no action for now
	_ = printscb(xl, 0)
	return 0
}

func sysef() int {
	// sysef is eject file. sysen is endfile
	return 0
}

func sysej() int {
	// close open files
	for _, fcb := range fcblks {
		if fcb.open {
			fcb.file.Close()
			fcb.open = false
		}
	}
	// need to find way to terminate program
	// return 999 to indicate end of job
	return 999
}

func setscblk(b int, str string) {
	for i := 0; i < len(str); i++ {
		mem[int(b)+2+i] = int(str[i])
	}
	mem[b+1] = int(len(str))
}

func sysem() int {
	if otrace {
		fmt.Println("sysem ", reg[wa])
	}
	if int(reg[wa]) > len(error_messages) { // return null string if error number out of range
		reg[xr] = int(scblk0)
		return 0
	}
	message, ok := error_messages[reg[wa]]
	if ok {
		reg[xr] = minString(scblk1, maxreclen, message)
	} else {
		mem[scblk1+1] = 0 // return null string
		reg[xr] = scblk1
	}
	return 0
}

func sysen() int {
	fcb := fcblks[int(reg[wa])]
	if fcb == nil {
		return 1
	}
	if !fcb.open {
		return 3
	}
	fcb.open = false
	if fcb.file.Close() != nil {
		return 2
	}
	delete(fcblks, int(reg[wa]))
	return 0
}

func sysep() int {
	os.Stdout.WriteString("\n")
	return 0
}

func sysex() int {
	// call to external function not supported
	return 1
}

func sysfc() int {
	/* cases

	   1. both null
	   case of both null should not occur, so return error 1 if it does.

	   2. filearg1 null, filearg3 non-null.
	   No action needed.


	   3: filearg1 non-null, filearg2 null.
	   We are just adding new variable assocation. Must check that same mode, returning error
	   if not. Must have been provided a fcb, and return it.

	   4. both non-null
	   See if channel in use, returning error if so. Then initialize channel.
	*/
	//var scblk1,scblk2 []int

	fcbn := int(reg[wa])
	reg[wa] = 0
	// pop any stacked arguments, since we ignore them (for now).
	reg[xs] += reg[wc]

	// if second argument is null, then call is just to check third argument in
	// case it is needed. We don't need it for this implementation.
	scblk1 := mem[reg[xl]:]
	scblk2 := mem[reg[xl]:]
	len1 := int(scblk1[1])
	len2 := int(scblk2[1])
	switch {

	case len1 == 0 && len2 == 0:
		return 1

	case len1 == 0 && len2 > 0:
		reg[wa] = 0
		reg[xl] = 0
		reg[wc] = 0
		return 0

	case len1 > 0 && len2 == 0:
		// error if no fcb available
		if fcbn == 0 {
			return 1
		}
		fcb := fcblks[fcbn]
		if fcb == nil {
			return 1
		}
		if fcb.output && reg[wb] == 0 || !fcb.output && reg[wb] != 0 {
			fcb.illegal = true // sysio call will signal error
		}
		return 0

	case len1 > 0 && len2 > 0:

		fcb := new(fcblk)
		fcb.output = reg[wb] > 0
		fcb.name = goString(scblk2)
		fcblkid++
		fcblks[fcblkid] = fcb
		reg[xl] = int(fcblkid) // return private fcblk index
		reg[wa] = 0
		reg[wc] = 0
		return 0
	}
	return 0
}

func sysgc() int {
	// no action needed
	return 0
}

func syshs() int {
	return 1
}

func sysid() int {
	reg[xr] = minString(scblk0, maxreclen, " dave")
	reg[xl] = minString(scblk1, maxreclen, "shields")
	return 0
}

func sysif() int {
	// TODO: support include files.
	return 1
}

func sysil() int {
	reg[wa] = maxreclen
	reg[wc] = 1 // text file
	return 0
}

func sysin() int {
	panic("sysin not implemented.")
}

func sysio() int {
	var err error
	var file *os.File
	if reg[wa] == 0 {
		return 1
	}
	fcb := fcblks[int(reg[wa])]
	if fcb == nil {
		return 1
	}

	if !fcb.open {
		if fcb.output {
			file, err = os.Create(fcb.name)
			if err != nil {
				return 1
			}
			fcb.reader = bufio.NewReader(file)
		} else {
			file, err = os.Open(fcb.name)
			if err != nil {
				return 1
			}
			//			fcb.writer = bufio.NewWriter(file)
		}
		fcb.file = file
	}
	reg[xl] = reg[wa]
	reg[wc] = maxreclen
	if fcb.file == nil { // fail if unable to create/open file
		return 1
	}
	return 0
}

func sysld() int {
	return 1
}

func sysmm() int {
	old := int(memLast)
	new := old
	if new >= len(mem)-1 {
		// no memory available for expansion
		reg[xr] = 0
	} else {
		new = old + 1000
		if new >= len(mem)-1 {
			new = len(mem) - 1
		}
		reg[xr] = int(new - old)
		memLast = int(new)
	}
	return 0
}

func sysmx() int {
	// return default
	reg[wa] = 0
	return 0
}

func sysou() int {
	var fcb *fcblk
	if reg[wa] == 0 {
		fcb = fcb2
	} else if reg[wa] == 1 {
		fcb = fcb1
	} else {
		fcb = fcblks[int(reg[wa])]
		if fcb == nil {
			return 2
		}
	}
	return writeLine(fcb, reg[xr])
}

func syspi() int {
	return writeLine(fcb2, reg[xr])
}

func syspl() int {
	return 0
}

func syspp() int {
	reg[wa] = 100
	reg[wb] = 60
	reg[wc] = 0
	return 0
}

func syspr() int {
	if reg[wa] == 0 { // if null line
		os.Stdout.WriteString("\n")
		return 0
	}
	printscb(xr, reg[wa])
	return 0
	//	return writeLine(fcb1, reg[xr])

}

var sysrds int
var ifile *os.File
var scanner *bufio.Scanner

func sysrd() int {
	var err error
	sysrds++
	scblk := mem[reg[xr]:]
	if otrace {
		fmt.Println("sysrd xr", reg[xr])
	}
	/*
		scblk[1] = 0
		reg[wc] = 0
		return 1
	*/
	switch sysrds {
	case 1:
		// here to open the input file and return its name
		ifile, err = os.Open(ifileName)
		if err != nil {
			fmt.Printf("cannot open %v\n", ifileName)
			return 999
		}
		scanner = bufio.NewScanner(ifile)
		_ = minString(reg[xr], reg[wc], ifileName)
		return 1
	default:
		// read next line from ifile, quit on EOF
		scanned := scanner.Scan()
		if scanned {
			line := scanner.Text()
			_ = minString(reg[xr], reg[wc], line)
			reg[wc] = int(len(line))
			printscb(xr, reg[wc])
			return 0
		}
		if err := scanner.Err(); err != nil {
			fmt.Println(os.Stderr, "reading input:", err)
			scblk[1] = 0
			reg[wc] = 0
		}
		// here at eof, indicate no END statement present, and quite
		fmt.Println("No end statement found in input file")
		return 999
	}
	return 999
}

func sysri() int {
	n := readLine(fcb0, reg[xr], mem[reg[xr]+1])
	return n
}

func sysrw() int {
	return 2
}

func sysst() int {
	return 5
}

func systm() int {
	d := time.Since(timeStart)
	reg[ia] = int(d.Nanoseconds() / 1000000)
	return 0
}

func systt() int {
	// No trace for now
	return 0
	panic("systt not implemented.")
}

func sysul() int {
	return 0
}

func sysxi() int {
	return 1
}

func syscall(ea int) int {

	switch ea {

	case sysax_:
		return sysax()

	case sysbs_:
		return sysbs()

	case sysbx_:
		return sysbx()

	case syscm_:
		return syscm()

	case sysdc_:
		return sysdc()

	case sysdm_:
		return sysdm()

	case sysdt_:
		return sysdt()

	case sysea_:
		return sysea()

	case sysef_:
		return sysef()

	case sysej_:
		return sysej()

	case sysem_:
		return sysem()

	case sysen_:
		return sysen()

	case sysep_:
		return sysep()

	case sysex_:
		return sysex()

	case sysfc_:
		return sysfc()

	case sysgc_:
		return sysgc()

	case syshs_:
		return syshs()

	case sysid_:
		return sysid()

	case sysif_:
		return sysif()

	case sysil_:
		return sysil()

	case sysin_:
		return sysin()

	case sysio_:
		return sysio()

	case sysld_:
		return sysld()

	case sysmm_:
		return sysmm()

	case sysmx_:
		return sysmx()

	case sysou_:
		return sysou()

	case syspi_:
		return syspi()

	case syspl_:
		return syspl()

	case syspp_:
		return syspp()

	case syspr_:
		return syspr()

	case sysrd_:
		return sysrd()

	case sysri_:
		return sysri()

	case sysrw_:
		return sysrw()

	case sysst_:
		return sysst()

	case systm_:
		return systm()

	case systt_:
		return systt()

	case sysul_:
		return sysul()

	case sysxi_:
		return sysxi()

	}
	panic("undefined system call")
}

func init() {
	fcb0 = new(fcblk)
	fcb0.name = "dev/stdin"
	fcb0.file = os.Stdin
	fcb0.open = true
	fcb0.reader = bufio.NewReader(fcb0.file)

	fcb1 = new(fcblk)
	fcb1.name = "dev/stdout"
	fcb1.file = os.Stdout
	fcb1.open = true
	fcb1.writer = bufio.NewWriter(fcb1.file)

	fcb2 = new(fcblk)
	fcb2.name = "dev/stderr"
	fcb2.file = os.Stderr
	fcb2.open = true
	fcb2.writer = bufio.NewWriter(fcb0.file)
}

func goString(scblk []int) string {
	if scblk[1] == 0 {
		return ""
	}
	n := int(scblk[1])
	b := make([]byte, n)
	for i := 0; i < n; i++ {
		b[i] = byte(scblk[2+i])
	}
	return string(b)
}

// return scblk from go byte array
func minBytes(b []byte) []int {
	var s []int
	s = make([]int, len(b)+2)
	s[1] = int(len(b))
	for i := 1; i < len(b); i++ {
		s[i+1] = int(b[i])
	}
	return s
}

// make scblk from go string
func minString(scblkid int, max int, g string) int {
	s := mem[scblkid:]
	n := len(g)
	if n > int(max) {
		n = maxreclen
	}
	s[1] = int(n)
	for i := 0; i < n; i++ {
		s[i+2] = int(g[i])
	}
	return scblkid
}
func check(e error) {
	if e != nil {
		panic(e)
	}
}
func writeLine(fcb *fcblk, start int) int {
	scb := int(start)
	n := int(mem[scb+1])

	for i := 0; i < n; i++ {
		_, err := fcb.writer.WriteRune(rune(mem[scb+2+i]))
		if err != nil {
			return 1
		}
	}
	return writeNewLine(fcb, true)
}

func writeNewLine(fcb *fcblk, flush bool) int {
	_, err := fcb.writer.WriteString("\n")
	if err != nil {
		return 1
	}
	if flush {
		err := fcb.writer.Flush()
		if err != nil {
			return 1
		}
	}
	return 0
}

func readLine(fcb *fcblk, scb int, max int) int {

	if fcb.eof { // don't go past EOF, just resignal it.
		return 1
	}
	n := int(max) // maximum length to read
	// read line, then break line into runes, then copy runes to minimal
	line, err := fcb.reader.ReadBytes('\n')
	if err != nil {
		fcb.eof = true
		return 1
	}
	runes := bytes.Runes(line)
	if len(runes) < n {
		n = len(runes)
	}
	mem[scb+1] = int(n)
	for i := 0; i < n; i++ {
		mem[int(scb)+2+i] = int(runes[i])
	}
	return 0
}

var sysName = map[int]string{
	sysax_: "sysax",
	sysbs_: "sysbs",
	sysbx_: "sysbx",
	syscm_: "syscm",
	sysdc_: "sysdc",
	sysdm_: "sysdm",
	sysdt_: "sysdt",
	sysea_: "sysea",
	sysef_: "sysef",
	sysej_: "sysej",
	sysem_: "sysem",
	sysen_: "sysen",
	sysep_: "sysep",
	sysex_: "sysex",
	sysfc_: "sysfc",
	sysgc_: "sysgc",
	syshs_: "syshs",
	sysid_: "sysid",
	sysif_: "sysif",
	sysil_: "sysil",
	sysin_: "sysin",
	sysio_: "sysio",
	sysld_: "sysld",
	sysmm_: "sysmm",
	sysmx_: "sysmx",
	sysou_: "sysou",
	syspi_: "syspi",
	syspl_: "syspl",
	syspp_: "syspp",
	syspr_: "syspr",
	sysrd_: "sysrd",
	sysri_: "sysri",
	sysrw_: "sysrw",
	sysst_: "sysst",
	systt_: "systt",
	systm_: "systm",
	sysul_: "sysul",
	sysxi_: "sysxi",
}

func printscb(regno int, actual int) int {
	scblk := mem[reg[regno]:]
	n := int(scblk[1])
	if int(actual) > 0 && n > int(actual) {
		n = int(actual)
	}
	buf := make([]byte, n)
	for i := 0; i < n; i++ {
		buf[i] = byte(scblk[i+2])
		//		buf[i] = scb[i+2]
	}
	n, err := os.Stdout.Write(buf)
	if err != nil {
		fmt.Println("stdout error writing")
		return 999
	}
	n, err = os.Stdout.WriteString("\n")
	if err != nil {
		fmt.Println("stdout error writing")
		return 999
	}
	return 0
}
