*      spitbol conditional assembly symbols for use by token.spt
*      ---------------------------------------------------------
*
*      this file of conditional symbols will override the conditional
*      definitions contained in the spitbol minimal file.   in addition,
*      lines beginning with ">" are treated as spitbol statements and
*      immediately executed.
*
*      for linux spitbol-x86
*
*      in the spitbol translator, the following conditional
*      assembly symbols are referred to. to incorporate the
*      features referred to, the minimal source should be
*      prefaced by suitable conditional assembly symbol
*      definitions.
*      in all cases it is permissible to default the definitions
*      in which case the additional features will be omitted
*      from the target code.
*
*
*                            conditional options
*                            since .undef not allowed if symbol not
*                            defined, a full comment line indicates
*                            symbol initially not defined.
*
*      .cavt                 define to include vertical tab
*      .ccmc                 define to include syscm function
*      .ceng                 define to include engine features
*      .cepp                 define if entry points have odd parity
*      .cnci                 define to enable sysci routine
*      .cncr                 define to enable syscr routine
*      .cnex                 define to omit exit() code.
*      .cnld                 define to omit load() code.
*      .cnpf                 define to omit profile stuff
*def   .cnra                 define to omit all real arithmetic
*      .cnsr                 define to omit sort, rsort
*      .crpp                 define if return points have odd parity
*      .cs16                 define to initialize stlim to 32767
*      .csn5                 define to pad stmt nos to 5 chars
*      .csn6                 define to pad stmt nos to 6 chars
*      .ctmd                 define if systm unit is decisecond
* disable mixed-case support for debugging later 17 apr 2014
*def   .culc                 define to include &case (lc names)
*      .cusr                 define to have set() use real values
*                             (must also #define setreal 1 in systype.h)
*
{{ttl{27,l i c e n s e -- software license for this program{{{{78
*     copyright 1983-2012 robert b. k. dewar
*     copyright 2012-2015 david shields
*     this file is part of macro spitbol.
*     macro spitbol is free software: you can redistribute it and/or modify
*     it under the terms of the gnu general public license as published by
*     the free software foundation, either version 2 of the license, or
*     (at your option) any later version.
*     macro spitbol is distributed in the hope that it will be useful,
*     but without any warranty; without even the implied warranty of
*     merchantability or fitness for a particular purpose.  see the
*     gnu general public license for more details.
*     you should have received a copy of the gnu general public license
*     along with macro spitbol.  if not, see <http://www.gnu.org/licenses/>.
{{ttl{27,s p i t b o l -- notes to implementors{{{{98
*      m a c r o   s p i t b o l     v e r s i o n   13.01
*      ---------------------------------------------------
*      date of release  -  january 2013
*      macro spitbol is maintained by
*           dr. david shields
*           260 garth rd apt 3h4
*           scarsdale, ny 10583
*      e-mail - thedaveshields at gmail dot com
*      version 3.7 was maintained by
*           mark emmer
*           catspaw, inc.
*           p.o. box 1123
*           salida, colorado 81021
*           u.s.a
*      e-mail - marke at snobol4 dot com
*      versions 2.6 through 3.4 were maintained by
*           dr. a. p. mccann (deceased)
*           department of computer studies
*           university of leeds
*           leeds ls2 9jt
*           england.
*      from 1979 through early 1983 a number of fixes and
*      enhancements were made by steve duff and robert goldberg.
{{ttl{27,s p i t b o l - revision history{{{{130
{{ejc{{{{{131
*      r e v i s i o n   h i s t o r y
*      -------------------------------
*      version 13.01 (january 2013, david shields)
*      this version has the same functionality as the previous release, but with
*      many internal code changes.
*      support for x86-64 has been added, but is not currently working.
*      the description of the minimal language formerly found here as comments
*      is now to be found in the file minimal-reference-manual.html
*      version 3.8 (june 2012, david shields)
*      --------------------------------------
*	       this version is very close to v3.7, with the
*              same functionality.
*              the source is now maintained using git, so going forward
*              the detailed revision history will be recorded in the git
*              commit logs, not in this file.
{{ttl{27,s p i t b o l  -- basic information{{{{153
{{ejc{{{{{154
*      general structure
*      -----------------
*      this program is a translator for a version of the snobol4
*      programming language. language details are contained in
*      the manual macro spitbol by dewar and mccann, technical
*      report 90, university of leeds 1976.
*      the implementation is discussed in dewar and mccann,
*      macro spitbol - a snobol4 compiler, software practice and
*      experience, 7, 95-113, 1977.
*      the language is as implemented by the btl translator
*      (griswold, poage and polonsky, prentice hall, 1971)
*      with the following principal exceptions.
*      1)   redefinition of standard system functions and
*           operators is not permitted.
*      2)   the value function is not provided.
*      3)   access tracing is provided in addition to the
*           other standard trace modes.
*      4)   the keyword stfcount is not provided.
*      5)   the keyword fullscan is not provided and all pattern
*           matching takes place in fullscan mode (i.e. with no
*           heuristics applied).
*      6)   a series of expressions separated by commas may
*           be grouped within parentheses to provide a selection
*           capability. the semantics are that the selection
*           assumes the value of the first expression within it
*           which succeeds as they are evaluated from the left.
*           if no expression succeeds the entire statement fails
*      7)   an explicit pattern matching operator is provided.
*           this is the binary query (see gimpel sigplan oct 74)
*      8)   the assignment operator is introduced as in the
*           gimpel reference.
*      9)   the exit function is provided for generating load
*           modules - cf. gimpels sitbol.
*      the method used in this program is to translate the
*      source code into an internal pseudo-code (see following
*      section). an interpretor is then used to execute this
*      generated pseudo-code. the nature of the snobol4 language
*      is such that the latter task is much more complex than
*      the actual translation phase. accordingly, nearly all the
*      code in the program section is concerned with the actual
*      execution of the snobol4 program.
{{ejc{{{{{209
*      interpretive code format
*      ------------------------
*      the interpretive pseudo-code consists of a series of
*      address pointers. the exact format of the code is
*      described in connection with the cdblk format. the
*      purpose of this section is to give general insight into
*      the interpretive approach involved.
*      the basic form of the code is related to reverse polish.
*      in other words, the operands precede the operators which
*      are zero address operators. there are some exceptions to
*      these rules, notably the unary not operator and the
*      selection construction which clearly require advance
*      knowledge of the operator involved.
*      the operands are moved to the top of the main stack and
*      the operators are applied to the top stack entries. like
*      other versions of spitbol, this processor depends on
*      knowing whether operands are required by name or by value
*      and moves the appropriate object to the stack. thus no
*      name/value checks are included in the operator circuits.
*      the actual pointers in the code point to a block whose
*      first word is the address of the interpretor routine
*      to be executed for the code word.
*      in the case of operators, the pointer is to a word which
*      contains the address of the operator to be executed. in
*      the case of operands such as constants, the pointer is to
*      the operand itself. accordingly, all operands contain
*      a field which points to the routine to load the value of
*      the operand onto the stack. in the case of a variable,
*      there are three such pointers. one to load the value,
*      one to store the value and a third to jump to the label.
*      the handling of failure returns deserves special comment.
*      the location flptr contains the pointer to the location
*      on the main stack which contains the failure return
*      which is in the form of a byte offset in the current
*      code block (cdblk or exblk). when a failure occurs, the
*      stack is popped as indicated by the setting of flptr and
*      control is passed to the appropriate location in the
*      current code block with the stack pointer pointing to the
*      failure offset on the stack and flptr unchanged.
{{ejc{{{{{256
*      internal data representations
*      -----------------------------
*      representation of values
*      a value is represented by a pointer to a block which
*      describes the type and particulars of the data value.
*      in general, a variable is a location containing such a
*      pointer (although in the case of trace associations this
*      is modified, see description of trblk).
*      the following is a list of possible datatypes showing the
*      type of block used to hold the value. the details of
*      each block format are given later.
*      datatype              block type
*      --------              ----------
*      array                 arblk or vcblk
*      code                  cdblk
*      expression            exblk or seblk
*      integer               icblk
*      name                  nmblk
*      pattern               p0blk or p1blk or p2blk
*      real                  rcblk
*      string                scblk
*      table                 tbblk
*      program datatype      pdblk
{{ejc{{{{{295
*      representation of variables
*      ---------------------------
*      during the course of evaluating expressions, it is
*      necessary to generate names of variables (for example
*      on the left side of a binary equals operator). these are
*      not to be confused with objects of datatype name which
*      are in fact values.
*      from a logical point of view, such names could be simply
*      represented by a pointer to the appropriate value cell.
*      however in the case of arrays and program defined
*      datatypes, this would violate the rule that there must be
*      no pointers into the middle of a block in dynamic store.
*      accordingly, a name is always represented by a base and
*      offset. the base points to the start of the block
*      containing the variable value and the offset is the
*      offset within this block in bytes. thus the address
*      of the actual variable is determined by adding the base
*      and offset values.
*      the following are the instances of variables represented
*      in this manner.
*      1)   natural variable base is ptr to vrblk
*                            offset is *vrval
*      2)   table element    base is ptr to teblk
*                            offset is *teval
*      3)   array element    base is ptr to arblk
*                            offset is offset to element
*      4)   vector element   base is ptr to vcblk
*                            offset is offset to element
*      5)   prog def dtp     base is ptr to pdblk
*                            offset is offset to field value
*      in addition there are two cases of objects which are
*      like variables but cannot be handled in this manner.
*      these are called pseudo-variables and are represented
*      with a special base pointer as follows=
*      expression variable   ptr to evblk (see evblk)
*      keyword variable      ptr to kvblk (see kvblk)
*      pseudo-variables are handled as special cases by the
*      access procedure (acess) and the assignment procedure
*      (asign). see these two procedures for details.
{{ejc{{{{{348
*      organization of data area
*      -------------------------
*      the data area is divided into two regions.
*      static area
*      the static area builds up from the bottom and contains
*      data areas which are allocated dynamically but are never
*      deleted or moved around. the macro-program itself
*      uses the static area for the following.
*      1)   all variable blocks (vrblk).
*      2)   the hash table for variable blocks.
*      3)   miscellaneous buffers and work areas (see program
*           initialization section).
*      in addition, the system procedures may use this area for
*      input/output buffers, external functions etc. space in
*      the static region is allocated by calling procedure alost
*      the following global variables define the current
*      location and size of the static area.
*      statb                 address of start of static area
*      state                 address+1 of last word in area.
*      the minimum size of static is given approximately by
*           12 + *e_hnb + *e_sts + space for alphabet string
*           and standard print buffer.
{{ejc{{{{{382
*      dynamic area
*      the dynamic area is built upwards in memory after the
*      static region. data in this area must all be in standard
*      block formats so that it can be processed by the garbage
*      collector (procedure gbcol). gbcol compacts blocks down
*      in this region as required by space exhaustion and can
*      also move all blocks up to allow for expansion of the
*      static region.
*      with the exception of tables and arrays, no spitbol
*      object once built in dynamic memory is ever subsequently
*      modified. observing this rule necessitates a copying
*      action during string and pattern concatenation.
*      garbage collection is fundamental to the allocation of
*      space for values. spitbol uses a very efficient garbage
*      collector which insists that pointers into dynamic store
*      should be identifiable without use of bit tables,
*      marker bits etc. to satisfy this requirement, dynamic
*      memory must not start at too low an address and lengths
*      of arrays, tables, strings, code and expression blocks
*      may not exceed the numerical value of the lowest dynamic
*      address.
*      to avoid either penalizing users with modest
*      requirements or restricting those with greater needs on
*      host systems where dynamic memory is allocated in low
*      addresses, the minimum dynamic address may be specified
*      sufficiently high to permit arbitrarily large spitbol
*      objects to be created (with the possibility in extreme
*      cases of wasting large amounts of memory below the
*      start address). this minimum value is made available
*      in variable mxlen by a system routine, sysmx.
*      alternatively sysmx may indicate that a
*      default may be used in which dynamic is placed
*      at the lowest possible address following static.
*      the following global work cells define the location and
*      length of the dynamic area.
*      dnamb                 start of dynamic area
*      dnamp                 next available location
*      dname                 last available location + 1
*      dnamb is always higher than state since the alost
*      procedure maintains some expansion space above state.
*      *** dnamb must never be permitted to have a value less
*      than that in mxlen ***
*      space in the dynamic region is allocated by the alloc
*      procedure. the dynamic region may be used by system
*      procedures provided that all the rules are obeyed.
*      some of the rules are subtle so it is preferable for
*      osint to manage its own memory needs. spitbol procs
*      obey rules to ensure that no action can cause a garbage
*      collection except at such times as contents of xl, xr
*      and the stack are +clean+ (see comment before utility
*      procedures and in gbcol for more detail). note
*      that calls of alost may cause garbage collection (shift
*      of memory to free space). spitbol procs which call
*      system routines assume that they cannot precipitate
*      collection and this must be respected.
{{ejc{{{{{445
*      register usage
*      --------------
*      (cp)                  code pointer register. used to
*                            hold a pointer to the current
*                            location in the interpretive pseudo
*                            code (i.e. ptr into a cdblk).
*      (xl,xr)               general index registers. usually
*                            used to hold pointers to blocks in
*                            dynamic storage. an important
*                            restriction is that the value in
*                            xl must be collectable for
*                            a garbage collect call. a value
*                            is collectable if it either points
*                            outside the dynamic area, or if it
*                            points to the start of a block in
*                            the dynamic area.
*      (xs)                  stack pointer. used to point to
*                            the stack front. the stack may
*                            build up or down and is used
*                            to stack subroutine return points
*                            and other recursively saved data.
*      (xt)                  an alternative name for xl during
*                            its use in accessing stacked items.
*      (wa,wb,wc)            general work registers. cannot be
*                            used for indexing, but may hold
*                            various types of data.
*      (ia)                  used for all signed integer
*                            arithmetic, both that used by the
*                            translator and that arising from
*                            use of snobol4 arithmetic operators
*      (ra)                  real accumulator. used for all
*                            floating point arithmetic.
{{ejc{{{{{486
*      spitbol conditional assembly symbols
*      ------------------------------------
*      in the spitbol translator, the following conditional
*      assembly symbols are referred to. to incorporate the
*      features referred to, the minimal source should be
*      prefaced by suitable conditional assembly symbol
*      definitions.
*      in all cases it is permissible to default the definitions
*      in which case the additional features will be omitted
*      from the target code.
*      .caex                 define to allow up arrow for expon.
*      .caht                 define to include horizontal tab
*      .casl                 define to include 26 shifted lettrs
*      .cavt                 define to include vertical tab
*      .cbyt                 define for statistics in bytes
*      .ccmc                 define to include syscm function
*      .ccmk                 define to include compare keyword
*      .cepp                 define if entrys have odd parity
*      .cera                 define to include sysea function
*      .cexp                 define if spitbol pops sysex args
*      .cgbc                 define to include sysgc function
*      .cicc                 define to ignore bad control cards
*      .cinc                 define to add -include control card
*      .ciod                 define to not use default delimiter
*                              in processing 3rd arg of input()
*                              and output()
*      .cmth                 define to include math functions
*      .cnbf                 define to omit buffer extension
*      .cnbt                 define to omit batch initialisation
*      .cnci                 define to enable sysci routine
*      .cncr                 define to enable syscr routine
*      .cnex                 define to omit exit() code.
*      .cnld                 define to omit load() code.
*      .cnlf                 define to add file type for load()
*      .cnpf                 define to omit profile stuff
*      .cnra                 define to omit all real arithmetic
*      .cnsc                 define to no numeric-string compare
*      .cnsr                 define to omit sort, rsort
*      .cpol                 define if interface polling desired
*      .crel                 define to include reloc routines
*      .crpp                 define if returns have odd parity
*      .cs16                 define to initialize stlim to 32767
*      .cs32                 define to init stlim to 2147483647
*                            omit to take default of 50000
*      .csax                 define if sysax is to be called
*      .csed                 define to use sediment in gbcol
*      .csfn                 define to track source file names
*      .csln                 define if line number in code block
*      .csou                 define if output, terminal to sysou
*      .ctet                 define to table entry trace wanted
*      .ctmd                 define if systm unit is decisecond
*      .cucf                 define to include cfp_u
*      .cuej                 define to suppress needless ejects
*      .culk                 define to include &l/ucase keywords
*      .culc                 define to include &case (lc names)
*                            if cucl defined, must support
*                            minimal op flc wreg that folds
*                            argument to lower case
*      .cust                 define to include set() code
*                            conditional options
*                            since .undef not allowed if symbol
*                            not defined, a full comment line
*                            indicates symbol initially not
*                            defined.
*      .cbyt                 define for statistics in bytes
*      .ccmc                 define to include syscm function
*      .ccmk                 define to include compare keyword
*      .cepp                 define if entrys have odd parity
*      .cera                 define to include sysea function
*      .cexp                 define if spitbol pops sysex args
*      .cicc                 define to ignore bad control cards
*      .cinc                 define to add -include control card
*                            in processing 3rd arg of input()
*                            and output()
*      .cmth                 define to include math functions
*      .cnci                 define to enable sysci routine
*      .cncr                 define to enable syscr routine
*      .cnex                 define to omit exit() code.
*      .cnlf                 define to add file type to load()
*      .cnpf                 define to omit profile stuff
*      .cnra                 define to omit all real arithmetic
*      .cnsc                 define if no numeric-string compare
*      .cnsr                 define to omit sort, rsort
*      .cpol                 define if interface polling desired
*      .crel                 define to include reloc routines
*      .crpp                 define if returns have odd parity
*      .cs16                 define to initialize stlim to 32767
*      .cs32                 define to init stlim to 2147483647
*      .csed                 define to use sediment in gbcol
*      .csfn                 define to track source file names
*      .csln                 define if line number in code block
*      .csou                 define if output, terminal to sysou
*      .ctmd                 define if systm unit is decisecond
*      force definition of .ccmk if .ccmc is defined
{{ttl{27,s p i t b o l -- procedures section{{{{607
*      this section starts with descriptions of the operating
*      system dependent procedures which are used by the spitbol
*      translator. all such procedures have five letter names
*      beginning with sys. they are listed in alphabetical
*      order.
*      all procedures have a  specification consisting of a
*      model call, preceded by a possibly empty list of register
*      contents giving parameters available to the procedure and
*      followed by a possibly empty list of register contents
*      required on return from the call or which may have had
*      their contents destroyed. only those registers explicitly
*      mentioned in the list after the call may have their
*      values changed.
*      the segment of code providing the external procedures is
*      conveniently referred to as osint (operating system
*      interface). the sysxx procedures it contains provide
*      facilities not usually available as primitives in
*      assembly languages. for particular target machines,
*      implementors may choose for some minimal opcodes which
*      do not have reasonably direct translations, to use calls
*      of additional procedures which they provide in osint.
*      e.g. mwb or trc might be translated as jsr sysmb,
*      jsr systc in some implementations.
*      in the descriptions, reference is made to --blk
*      formats (-- = a pair of letters). see the spitbol
*      definitions section for detailed descriptions of all
*      such block formats except fcblk for which sysfc should
*      be consulted.
*      section 0 contains inp,inr specifications of internal
*      procedures,routines. this gives a single pass translator
*      information making it easy to generate alternative calls
*      in the translation of jsr-s for procedures of different
*      types if this proves necessary.
{{sec{{{{start of procedures section{645
{{ejc{{{{{647
*      sysax -- after execution
{sysax{exp{1,0{{{define external entry point{651
*      if the conditional assembly symbol .csax is defined,
*      this routine is called immediately after execution and
*      before printing of execution statistics or dump output.
*      purpose of call is for implementor to determine and
*      if the call is not required it will be omitted if .csax
*      is undefined. in this case sysax need not be coded.
*      jsr  sysax            call after execution
{{ejc{{{{{663
*      sysbs -- backspace file
{sysbs{exp{1,3{{{define external entry point{668
*      sysbs is used to implement the snobol4 function backspace
*      if the conditional assembly symbol .cbsp is defined.
*      the meaning is system dependent.  in general, backspace
*      repositions the file one record closer to the beginning
*      of file, such that a subsequent read or write will
*      operate on the previous record.
*      (wa)                  ptr to fcblk or zero
*      (xr)                  backspace argument (scblk ptr)
*      jsr  sysbs            call to backspace
*      ppm  loc              return here if file does not exist
*      ppm  loc              return here if backspace not allowed
*      ppm  loc              return here if i/o error
*      (wa,wb)               destroyed
*      the second error return is used for files for which
*      backspace is not permitted. for example, it may be expected
*      files on character devices are in this category.
{{ejc{{{{{688
*      sysbx -- before execution
{sysbx{exp{1,0{{{define external entry point{693
*      called after initial spitbol compilation and before
*      commencing execution in case osint needs
*      to assign files or perform other necessary services.
*      osint may also choose to send a message to online
*      terminal (if any) indicating that execution is starting.
*      jsr  sysbx            call before execution starts
{{ejc{{{{{702
*      sysdc -- date check
{sysdc{exp{1,0{{{define external entry point{796
*      sysdc is called to check that the expiry date for a trial
*      version of spitbol is unexpired.
*      jsr  sysdc            call to check date
*      return only if date is ok
{{ejc{{{{{803
*      sysdm  -- dump core
{sysdm{exp{1,0{{{define external entry point{807
*      sysdm is called by a spitbol program call of dump(n) with
*      n ge 4.  its purpose is to provide a core dump.
*      n could hold an encoding of the start adrs for dump and
*      amount to be dumped e.g.  n = 256*a + s , s = start adrs
*      in kilowords,  a = kilowords to dump
*      (xr)                  parameter n of call dump(n)
*      jsr  sysdm            call to enter routine
{{ejc{{{{{817
*      sysdt -- get current date
{sysdt{exp{1,0{{{define external entry point{821
*      sysdt is used to obtain the current date. the date is
*      returned as a character string in any format appropriate
*      to the operating system in use. it may also contain the
*      current time of day. sysdt is used to implement the
*      snobol4 function date().
*      (xr)                  parameter n of call date(n)
*      jsr  sysdt            call to get date
*      (xl)                  pointer to block containing date
*      the format of the block is like an scblk except that
*      the first word need not be set. the result is copied
*      into spitbol dynamic memory on return.
{{ejc{{{{{837
*      sysea -- inform osint of compilation and runtime errors
{sysea{exp{1,1{{{define external entry point{841
*      provides means for interface to take special actions on
*      errors
*      (wa)                  error code
*      (wb)                  line number
*      (wc)                  column number
*      (xr)                  system stage
*      (xl)                  file name (scblk)
*      jsr  sysea            call to sysea function
*      ppm  loc              suppress printing of error message
*      (xr)                  message to print (scblk) or 0
*      sysea may not return if interface chooses to retain
*      control.  closing files via the fcb chain will be the
*      responsibility of the interface.
*      all registers preserved
{{ejc{{{{{863
*      sysef -- eject file
{sysef{exp{1,3{{{define external entry point{867
*      sysef is used to write a page eject to a named file. it
*      may only be used for files where this concept makes
*      sense. note that sysef is not normally used for the
*      standard output file (see sysep).
*      (wa)                  ptr to fcblk or zero
*      (xr)                  eject argument (scblk ptr)
*      jsr  sysef            call to eject file
*      ppm  loc              return here if file does not exist
*      ppm  loc              return here if inappropriate file
*      ppm  loc              return here if i/o error
{{ejc{{{{{880
*      sysej -- end of job
{sysej{exp{1,0{{{define external entry point{884
*      sysej is called once at the end of execution to
*      terminate the run. the significance of the abend and
*      code values is system dependent. in general, the code
*      value should be made available for testing, and the
*      abend value should cause some post-mortem action such as
*      a dump. note that sysej does not return to its caller.
*      see sysxi for details of fcblk chain
*      (wa)                  value of abend keyword
*      (wb)                  value of code keyword
*      (xl)                  o or ptr to head of fcblk chain
*      jsr  sysej            call to end job
*      the following special values are used as codes in (wb)
*      999  execution suppressed
*      998  standard output file full or unavailable in a sysxi
*           load module. in these cases (wa) contains the number
*           of the statement causing premature termination.
{{ejc{{{{{904
*      sysem -- get error message text
{sysem{exp{1,0{{{define external entry point{908
*      sysem is used to obtain the text of err, erb calls in the
*      source program given the error code number. it is allowed
*      to return a null string if this facility is unavailable.
*      (wa)                  error code number
*      jsr  sysem            call to get text
*      (xr)                  text of message
*      the returned value is a pointer to a block in scblk
*      format except that the first word need not be set. the
*      string is copied into dynamic memory on return.
*      if the null string is returned either because sysem does
*      not provide error message texts or because wa is out of
*      range, spitbol will print the string stored in errtext
*      keyword.
{{ejc{{{{{925
*      sysen -- endfile
{sysen{exp{1,3{{{define external entry point{929
*      sysen is used to implement the snobol4 function endfile.
*      the meaning is system dependent. in general, endfile
*      implies that no further i/o operations will be performed,
*      but does not guarantee this to be the case. the file
*      should be closed after the call, a subsequent read
*      or write may reopen the file at the start or it may be
*      necessary to reopen the file via sysio.
*      (wa)                  ptr to fcblk or zero
*      (xr)                  endfile argument (scblk ptr)
*      jsr  sysen            call to endfile
*      ppm  loc              return here if file does not exist
*      ppm  loc              return here if endfile not allowed
*      ppm  loc              return here if i/o error
*      (wa,wb)               destroyed
*      the second error return is used for files for which
*      endfile is not permitted. for example, it may be expected
*      that the standard input and output files are in this
*      category.
{{ejc{{{{{951
*      sysep -- eject printer page
{sysep{exp{1,0{{{define external entry point{955
*      sysep is called to perform a page eject on the standard
*      printer output file (corresponding to syspr output).
*      jsr  sysep            call to eject printer output
{{ejc{{{{{961
*      sysex -- call external function
{sysex{exp{1,3{{{define external entry point{965
*      sysex is called to pass control to an external function
*      previously loaded with a call to sysld.
*      (xs)                  pointer to arguments on stack
*      (xl)                  pointer to control block (efblk)
*      (wa)                  number of arguments on stack
*      jsr  sysex            call to pass control to function
*      ppm  loc              return here if function call fails
*      ppm  loc              return here if insufficient memory
*      ppm  loc              return here if bad argument type
*      (xr)                  result returned
*      the arguments are stored on the stack with
*      the last argument at 0(xs). on return, xs
*      is popped past the arguments.
*      the form of the arguments as passed is that used in the
*      spitbol translator (see definitions and data structures
*      section). the control block format is also described
*      (under efblk) in this section.
*      there are two ways of returning a result.
*      1)   return a pointer to a block in dynamic storage. this
*           block must be in exactly correct format, including
*           the first word. only functions written with intimate
*           knowledge of the system will return in this way.
*      2)   string, integer and real results may be returned by
*           pointing to a pseudo-block outside dynamic memory.
*           this block is in icblk, rcblk or scblk format except
*           that the first word will be overwritten
*           by a type word on return and so need not
*           be correctly set. such a result is
*           copied into main storage before proceeding.
*           unconverted results may similarly be returned in a
*           pseudo-block which is in correct format including
*           type word recognisable by garbage collector since
*           block is copied into dynamic memory.
{{ejc{{{{{1010
*      sysfc -- file control block routine
{sysfc{exp{1,2{{{define external entry point{1014
*      see also sysio
*      input and output have 3 arguments referred to as shown
*           input(variable name,file arg1,file arg2)
*           output(variable name,file arg1,file arg2)
*      file arg1 may be an integer or string used to identify
*      an i/o channel. it is converted to a string for checking.
*      the exact significance of file arg2
*      is not rigorously prescribed but to improve portability,
*      the scheme described in the spitbol user manual
*      should be adopted when possible. the preferred form is
*      a string _f_,r_r_,c_c_,i_i_,...,z_z_  where
*      _f_ is an optional file name which is placed first.
*       remaining items may be omitted or included in any order.
*      _r_ is maximum record length
*      _c_ is a carriage control character or character string
*      _i_ is some form of channel identification used in the
*         absence of _f_ to associate the variable
*         with a file allocated dynamically by jcl commands at
*         spitbol load time.
*      ,...,z_z_ are additional fields.
*      if , (comma) cannot be used as a delimiter, .ciod
*      should be defined to introduce by conditional assembly
*      another delimiter (see
*        iodel  equ  *
*      early in definitions section).
*      sysfc is called when a variable is input or output
*      associated to check file arg1 and file arg2 and
*      to  report whether an fcblk (file control
*      block) is necessary and if so what size it should be.
*      this makes it possible for spitbol rather than osint to
*      allocate such a block in dynamic memory if required
*      or alternatively in static memory.
*      the significance of an fcblk , if one is requested, is
*      entirely up to the system interface. the only restriction
*      is that if the fcblk should appear to lie in dynamic
*      memory, pointers to it should be proper pointers to
*      the start of a recognisable and garbage collectable
*      block (this condition will be met if sysfc requests
*      spitbol to provide an fcblk).
*      an option is provided for osint to return a pointer in
*      xl to an fcblk which it privately allocated. this ptr
*      will be made available when i/o occurs later.
*      private fcblks may have arbitrary contents and spitbol
*      stores nothing in them.
{{ejc{{{{{1060
*      the requested size for an fcblk in dynamic memory
*      should allow a 2 word overhead for block type and
*      length fields. information subsequently stored in the
*      remaining words may be arbitrary if an xnblk (external
*      non-relocatable block) is requested. if the request is
*      for an xrblk (external relocatable block) the
*      contents of words should be collectable (i.e. any
*      apparent pointers into dynamic should be genuine block
*      pointers). these restrictions do not apply if an fcblk
*      is allocated outside dynamic or is not allocated at all.
*      if an fcblk is requested, its fields will be initialised
*      to zero before entry to sysio with the exception of
*      words 0 and 1 in which the block type and length
*      fields are placed for fcblks in dynamic memory only.
*      for the possible use of sysej and sysxi, if fcblks
*      are used, a chain is built so that they may all be
*      found - see sysxi for details.
*      if both file arg1 and file arg2 are null, calls of sysfc
*      and sysio are omitted.
*      if file arg1 is null (standard input/output file), sysfc
*      is called to check non-null file arg2 but any request
*      for an fcblk will be ignored, since spitbol handles the
*      standard files specially and cannot readily keep fcblk
*      pointers for them.
*      filearg1 is type checked by spitbol so further checking
*      may be unneccessary in many implementations.
*      file arg2 is passed so that sysfc may analyse and
*      check it. however to assist in this, spitbol also passes
*      on the stack the components of this argument with
*      file name, _f_ (otherwise null) extracted and stacked
*      first.
*      the other fields, if any, are extracted as substrings,
*      pointers to them are stacked and a count of all items
*      stacked is placed in wc. if an fcblk was earlier
*      allocated and pointed to via file arg1, sysfc is also
*      passed a pointer to this fcblk.
*      (xl)                  file arg1 scblk ptr (2nd arg)
*      (xr)                  filearg2 (3rd arg) or null
*      -(xs)...-(xs)         scblks for _f_,_r_,_c_,...
*      (wc)                  no. of stacked scblks above
*      (wa)                  existing file arg1 fcblk ptr or 0
*      (wb)                  0/3 for input/output assocn
*      jsr  sysfc            call to check need for fcblk
*      ppm  loc              invalid file argument
*      ppm  loc              fcblk already in use
*      (xs)                  popped (wc) times
*      (wa non zero)         byte size of requested fcblk
*      (wa=0,xl non zero)    private fcblk ptr in xl
*      (wa=xl=0)             no fcblk wanted, no private fcblk
*      (wc)                  0/1/2 request alloc of xrblk/xnblk
*                            /static block for use as fcblk
*      (wb)                  destroyed
{{ejc{{{{{1115
*      sysgc -- inform interface of garbage collections
{sysgc{exp{1,0{{{define external entry point{1119
*      provides means for interface to take special actions
*      prior to and after a garbage collection.
*      possible usages-
*      1. provide visible screen icon of garbage collection
*         in progress
*      2. inform virtual memory manager to ignore page access
*         patterns during garbage collection.  such accesses
*         typically destroy the page working set accumulated
*         by the program.
*      3. inform virtual memory manager that contents of memory
*         freed by garbage collection can be discarded.
*      (xr)                  non-zero if beginning gc
*                            =0 if completing gc
*      (wa)                  dnamb=start of dynamic area
*      (wb)                  dnamp=next available location
*      (wc)                  dname=last available location + 1
*      jsr  sysgc            call to sysgc function
*      all registers preserved
{{ejc{{{{{1143
*      syshs -- give access to host computer features
{syshs{exp{1,8{{{define external entry point{1147
*      provides means for implementing special features
*      on different host computers. the only defined entry is
*      that where all arguments are null in which case syshs
*      returns an scblk containing name of computer,
*      name of operating system and name of site separated by
*      colons. the scblk need not have a correct first field
*      as this is supplied on copying string to dynamic memory.
*      spitbol does no argument checking but does provide a
*      single error return for arguments checked as erroneous
*      by osint. it also provides a single execution error
*      return. if these are inadequate, use may be made of the
*      minimal error section direct as described in minimal
*      documentation, section 10.
*      several non-error returns are provided. the first
*      corresponds to the defined entry or, for implementation
*      defined entries, any string may be returned. the others
*      permit respectively,  return a null result, return with a
*      result to be stacked which is pointed at by xr, and a
*      return causing spitbol statement failure. if a returned
*      result is in dynamic memory it must obey garbage
*      collector rules. the only results copied on return
*      are strings returned via ppm loc3 return.
*      (wa)                  argument 1
*      (xl)                  argument 2
*      (xr)                  argument 3
*      (wb)                  argument 4
*      (wc)                  argument 5
*      jsr  syshs            call to get host information
*      ppm  loc1             erroneous arg
*      ppm  loc2             execution error
*      ppm  loc3             scblk ptr in xl or 0 if unavailable
*      ppm  loc4             return a null result
*      ppm  loc5             return result in xr
*      ppm  loc6             cause statement failure
*      ppm  loc7             return string at xl, length wa
*      ppm  loc8             return copy of result in xr
{{ejc{{{{{1186
*      sysid -- return system identification
{sysid{exp{1,0{{{define external entry point{1190
*      this routine should return strings to head the standard
*      printer output. the first string will be appended to
*      a heading line of the form
*           macro spitbol version v.v
*      supplied by spitbol itself. v.v are digits giving the
*      major version number and generally at least a minor
*      version number relating to osint should be supplied to
*      give say
*           macro spitbol version v.v(m.m)
*      the second string should identify at least the machine
*      and operating system.  preferably it should include
*      the date and time of the run.
*      optionally the strings may include site name of the
*      the implementor and/or machine on which run takes place,
*      unique site or copy number and other information as
*      appropriate without making it so long as to be a
*      nuisance to users.
*      the first words of the scblks pointed at need not be
*      correctly set.
*      jsr  sysid            call for system identification
*      (xr)                  scblk ptr for addition to header
*      (xl)                  scblk ptr for second header
{{ejc{{{{{1215
*      sysif -- switch to new include file
{sysif{exp{1,1{{{define external entry point{1220
*      sysif is used for include file processing, both to inform
*      the interface when a new include file is desired, and
*      when the end of file of an include file has been reached
*      and it is desired to return to reading from the previous
*      nested file.
*      it is the responsibility of sysif to remember the file
*      access path to the present input file before switching to
*      the new include file.
*      (xl)                  ptr to scblk or zero
*      (xr)                  ptr to vacant scblk of length cswin
*                            (xr not used if xl is zero)
*      jsr  sysif            call to change files
*      ppm  loc              unable to open file
*      (xr)                  scblk with full path name of file
*                            (xr not used if input xl is zero)
*      register xl points to an scblk containing the name of the
*      include file to which the interface should switch.  data
*      is fetched from the file upon the next call to sysrd.
*      sysif may have the ability to search multiple libraries
*      for the include file named in (xl).  it is therefore
*      required that the full path name of the file where the
*      file was finally located be returned in (xr).  it is this
*      name that is recorded along with the source statements,
*      and will accompany subsequent error messages.
*      register xl is zero to mark conclusion of use of an
*      include file.
{{ejc{{{{{1253
*      sysil -- get input record length
{sysil{exp{1,0{{{define external entry point{1258
*      sysil is used to get the length of the next input record
*      from a file previously input associated with a sysio
*      call. the length returned is used to establish a buffer
*      for a subsequent sysin call.  sysil also indicates to the
*      caller if this is a binary or text file.
*      (wa)                  ptr to fcblk or zero
*      jsr  sysil            call to get record length
*      (wa)                  length or zero if file closed
*      (wc)                  zero if binary, non-zero if text
*      no harm is done if the value returned is too long since
*      unused space will be reclaimed after the sysin call.
*      note that it is the sysil call (not the sysio call) which
*      causes the file to be opened as required for the first
*      record input from the file.
{{ejc{{{{{1277
*      sysin -- read input record
{sysin{exp{1,3{{{define external entry point{1281
*      sysin is used to read a record from the file which was
*      referenced in a prior call to sysil (i.e. these calls
*      always occur in pairs). the buffer provided is an
*      scblk for a string of length set from the sysil call.
*      if the actual length read is less than this, the length
*      field of the scblk must be modified before returning
*      unless buffer is right padded with zeroes.
*      it is also permissible to take any of the alternative
*      returns after scblk length has been modified.
*      (wa)                  ptr to fcblk or zero
*      (xr)                  pointer to buffer (scblk ptr)
*      jsr  sysin            call to read record
*      ppm  loc              endfile or no i/p file after sysxi
*      ppm  loc              return here if i/o error
*      ppm  loc              return here if record format error
*      (wa,wb,wc)            destroyed
{{ejc{{{{{1300
*      sysio -- input/output file association
{sysio{exp{1,2{{{define external entry point{1304
*      see also sysfc.
*      sysio is called in response to a snobol4 input or output
*      function call except when file arg1 and file arg2
*      are both null.
*      its call always follows immediately after a call
*      of sysfc. if sysfc requested allocation
*      of an fcblk, its address will be in wa.
*      for input files, non-zero values of _r_ should be
*      copied to wc for use in allocating input buffers. if _r_
*      is defaulted or not implemented, wc should be zeroised.
*      once a file has been opened, subsequent input(),output()
*      calls in which the second argument is identical with that
*      in a previous call, merely associate the additional
*      variable name (first argument) to the file and do not
*      result in re-opening the file.
*      in subsequent associated accesses to the file a pointer
*      to any fcblk allocated will be made available.
*      (xl)                  file arg1 scblk ptr (2nd arg)
*      (xr)                  file arg2 scblk ptr (3rd arg)
*      (wa)                  fcblk ptr (0 if none)
*      (wb)                  0 for input, 3 for output
*      jsr  sysio            call to associate file
*      ppm  loc              return here if file does not exist
*      ppm  loc              return if input/output not allowed
*      (xl)                  fcblk pointer (0 if none)
*      (wc)                  0 (for default) or max record lngth
*      (wa,wb)               destroyed
*      the second error return is used if the file named exists
*      but input/output from the file is not allowed. for
*      example, the standard output file may be in this category
*      as regards input association.
{{ejc{{{{{1339
*      sysld -- load external function
{sysld{exp{1,3{{{define external entry point{1343
*      sysld is called in response to the use of the snobol4
*      load function. the named function is loaded (whatever
*      this means), and a pointer is returned. the pointer will
*      be used on subsequent calls to the function (see sysex).
*      (xr)                  pointer to function name (scblk)
*      (xl)                  pointer to library name (scblk)
*      jsr  sysld            call to load function
*      ppm  loc              return here if func does not exist
*      ppm  loc              return here if i/o error
*      ppm  loc              return here if insufficient memory
*      (xr)                  pointer to loaded code
*      the significance of the pointer returned is up to the
*      system interface routine. the only restriction is that
*      if the pointer is within dynamic storage, it must be
*      a proper block pointer.
{{ejc{{{{{1362
*      sysmm -- get more memory
{sysmm{exp{1,0{{{define external entry point{1366
*      sysmm is called in an attempt to allocate more dynamic
*      memory. this memory must be allocated contiguously with
*      the current dynamic data area.
*      the amount allocated is up to the system to decide. any
*      value is acceptable including zero if allocation is
*      impossible.
*      jsr  sysmm            call to get more memory
*      (xr)                  number of additional words obtained
{{ejc{{{{{1378
*      sysmx -- supply mxlen
{sysmx{exp{1,0{{{define external entry point{1382
*      because of the method of garbage collection, no spitbol
*      object is allowed to occupy more bytes of memory than
*      the integer giving the lowest address of dynamic
*      (garbage collectable) memory. mxlen is the name used to
*      refer to this maximum length of an object and for most
*      users of most implementations, provided dynamic memory
*      starts at an address of at least a few thousand words,
*      there is no problem.
*      if the default starting address is less than say 10000 or
*      20000, then a load time option should be provided where a
*      user can request that he be able to create larger
*      objects. this routine informs spitbol of this request if
*      any. the value returned is either an integer
*      representing the desired value of mxlen (and hence the
*      minimum dynamic store address which may result in
*      non-use of some store) or zero if a default is acceptable
*      in which mxlen is set to the lowest address allocated
*      to dynamic store before compilation starts.
*      if a non-zero value is returned, this is used for keyword
*      maxlngth. otherwise the initial low address of dynamic
*      memory is used for this keyword.
*      jsr  sysmx            call to get mxlen
*      (wa)                  either mxlen or 0 for default
{{ejc{{{{{1408
*      sysou -- output record
{sysou{exp{1,2{{{define external entry point{1412
*      sysou is used to write a record to a file previously
*      associated with a sysio call.
*      (wa)                  ptr to fcblk
*                            or 0 for terminal or 1 for output
*      (xr)                  record to be written (scblk)
*      jsr  sysou            call to output record
*      ppm  loc              file full or no file after sysxi
*      ppm  loc              return here if i/o error
*      (wa,wb,wc)            destroyed
*      note that it is the sysou call (not the sysio call) which
*      causes the file to be opened as required for the first
*      record output to the file.
{{ejc{{{{{1434
*      syspi -- print on interactive channel
{syspi{exp{1,1{{{define external entry point{1438
*      if spitbol is run from an online terminal, osint can
*      request that messages such as copies of compilation
*      errors be sent to the terminal (see syspp). if relevant
*      reply was made by syspp then syspi is called to send such
*      messages to the interactive channel.
*      syspi is also used for sending output to the terminal
*      through the special variable name, terminal.
*      (xr)                  ptr to line buffer (scblk)
*      (wa)                  line length
*      jsr  syspi            call to print line
*      ppm  loc              failure return
*      (wa,wb)               destroyed
{{ejc{{{{{1454
*      syspl -- provide interactive control of spitbol
{syspl{exp{1,3{{{define external entry point{1458
*      provides means for interface to take special actions,
*      such as interrupting execution, breakpointing, stepping,
*      and expression evaluation.  these last three options are
*      not presently implemented by the code calling syspl.
*      (wa)                  opcode as follows-
*                            =0 poll to allow osint to interrupt
*                            =1 breakpoint hit
*                            =2 completion of statement stepping
*                            =3 expression evaluation result
*      (wb)                  statement number
*      r_fcb                 o or ptr to head of fcblk chain
*      jsr  syspl            call to syspl function
*      ppm  loc              user interruption
*      ppm  loc              step one statement
*      ppm  loc              evaluate expression
*      ---                   resume execution
*                            (wa) = new polling interval
{{ejc{{{{{1481
*      syspp -- obtain print parameters
{syspp{exp{1,0{{{define external entry point{1485
*      syspp is called once during compilation to obtain
*      parameters required for correct printed output format
*      and to select other options. it may also be called again
*      after sysxi when a load module is resumed. in this
*      case the value returned in wa may be less than or equal
*      to that returned in initial call but may not be
*      greater.
*      the information returned is -
*      1.   line length in chars for standard print file
*      2.   no of lines/page. 0 is preferable for a non-paged
*           device (e.g. online terminal) in which case listing
*           page throws are suppressed and page headers
*           resulting from -title,-stitl lines are kept short.
*      3.   an initial -nolist option to suppress listing unless
*           the program contains an explicit -list.
*      4.   options to suppress listing of compilation and/or
*           execution stats (useful for established programs) -
*           combined with 3. gives possibility of listing
*           file never being opened.
*      5.   option to have copies of errors sent to an
*           interactive channel in addition to standard printer.
*      6.   option to keep page headers short (e.g. if listing
*           to an online terminal).
*      7.   an option to choose extended or compact listing
*           format. in the former a page eject and in the latter
*           a few line feeds precede the printing of each
*           of-- listing, compilation statistics, execution
*           output and execution statistics.
*      8.   an option to suppress execution as though a
*           -noexecute card were supplied.
*      9.   an option to request that name /terminal/  be pre-
*           associated to an online terminal via syspi and sysri
*      10.  an intermediate (standard) listing option requiring
*           that page ejects occur in source listings. redundant
*           if extended option chosen but partially extends
*           compact option.
*      11.  option to suppress sysid identification.
*      jsr  syspp            call to get print parameters
*      (wa)                  print line length in chars
*      (wb)                  number of lines/page
*      (wc)                  bits value ...mlkjihgfedcba where
*                            a = 1 to send error copy to int.ch.
*                            b = 1 means std printer is int. ch.
*                            c = 1 for -nolist option
*                            d = 1 to suppress compiln. stats
*                            e = 1 to suppress execn. stats
*                            f = 1/0 for extnded/compact listing
*                            g = 1 for -noexecute
*                            h = 1 pre-associate /terminal/
*                            i = 1 for standard listing option.
*                            j = 1 suppresses listing header
*                            k = 1 for -print
*                            l = 1 for -noerrors
{{ejc{{{{{1547
*      syspr -- print line on standard output file
{syspr{exp{1,1{{{define external entry point{1551
*      syspr is used to print a single line on the standard
*      output file.
*      (xr)                  pointer to line buffer (scblk)
*      (wa)                  line length
*      jsr  syspr            call to print line
*      ppm  loc              too much o/p or no file after sysxi
*      (wa,wb)               destroyed
*      the buffer pointed to is the length obtained from the
*      syspp call and is filled out with trailing blanks. the
*      value in wa is the actual line length which may be less
*      than the maximum line length possible. there is no space
*      control associated with the line, all lines are printed
*      single spaced. note that null lines (wa=0) are possible
*      in which case a blank line is to be printed.
*      the error exit is used for systems which limit the amount
*      of printed output. if possible, printing should be
*      permitted after this condition has been signalled once to
*      allow for dump and other diagnostic information.
*      assuming this to be possible, spitbol may make more syspr
*      calls. if the error return occurs another time, execution
*      is terminated by a call of sysej with ending code 998.
{{ejc{{{{{1577
*      sysrd -- read record from standard input file
{sysrd{exp{1,1{{{define external entry point{1581
*      sysrd is used to read a record from the standard input
*      file. the buffer provided is an scblk for a string the
*      length of which in characters is given in wc, this
*      corresponding to the maximum length of string which
*      spitbol is prepared to receive. at compile time it
*      corresponds to xxx in the most recent -inxxx card
*      (default 72) and at execution time to the most recent
*      ,r_r_ (record length) in the third arg of an input()
*      statement for the standard input file (default 80).
*      if fewer than (wc) characters are read, the length
*      field of the scblk must be adjusted before returning
*      unless the buffer is right padded with zeroes.
*      it is also permissible to take the alternative return
*      after such an adjustment has been made.
*      spitbol may continue to make calls after an endfile
*      return so this routine should be prepared to make
*      repeated endfile returns.
*      (xr)                  pointer to buffer (scblk ptr)
*      (wc)                  length of buffer in characters
*      jsr  sysrd            call to read line
*      ppm  loc              endfile or no i/p file after sysxi
*                            or input file name change.  if
*                            the former, scblk length is zero.
*                            if input file name change, length
*                            is non-zero. caller should re-issue
*                            sysrd to obtain input record.
*      (wa,wb,wc)            destroyed
{{ejc{{{{{1613
*      sysri -- read record from interactive channel
{sysri{exp{1,1{{{define external entry point{1617
*      reads a record from online terminal for spitbol variable,
*      terminal. if online terminal is unavailable then code the
*      endfile return only.
*      the buffer provided is of length 258 characters. sysri
*      should replace the count in the second word of the scblk
*      by the actual character count unless buffer is right
*      padded with zeroes.
*      it is also permissible to take the alternative
*      return after adjusting the count.
*      the end of file return may be used if this makes
*      sense on the target machine (e.g. if there is an
*      eof character.)
*      (xr)                  ptr to 258 char buffer (scblk ptr)
*      jsr  sysri            call to read line from terminal
*      ppm  loc              end of file return
*      (wa,wb,wc)            may be destroyed
{{ejc{{{{{1636
*      sysrw -- rewind file
{sysrw{exp{1,3{{{define external entry point{1640
*      sysrw is used to rewind a file i.e. reposition the file
*      at the start before the first record. the file should be
*      closed and the next read or write call will open the
*      file at the start.
*      (wa)                  ptr to fcblk or zero
*      (xr)                  rewind arg (scblk ptr)
*      jsr  sysrw            call to rewind file
*      ppm  loc              return here if file does not exist
*      ppm  loc              return here if rewind not allowed
*      ppm  loc              return here if i/o error
{{ejc{{{{{1653
*      sysst -- set file pointer
{sysst{exp{1,0{{{define external entry point{1658
*      sysst is called to change the position of a file
*      pointer. this is accomplished in a system dependent
*      manner, and thus the 2nd and 3rd arguments are passed
*      unconverted.
*      (wa)                  fcblk pointer
*      (wb)                  2nd argument
*      (wc)                  3rd argument
*      jsr  sysst            call to set file pointer
*      ppm  loc              return here if invalid 2nd arg
*      ppm  loc              return here if invalid 3rd arg
*      ppm  loc              return here if file does not exist
*      ppm  loc              return here if set not allowed
*      ppm  loc              return here if i/o error
{{ejc{{{{{1675
*      systm -- get execution time so far
{systm{exp{1,0{{{define external entry point{1680
*      systm is used to obtain the amount of execution time
*      used so far since spitbol was given control. the units
*      are described as microseconds in the spitbol output, but
*      the exact meaning is system dependent. where appropriate,
*      this value should relate to processor rather than clock
*      timing values.
*      if the symbol .ctmd is defined, the units are described
*      as deciseconds (0.1 second).
*      jsr  systm            call to get timer value
*      (ia)                  time so far in micliseconds
*                            (deciseconds if .ctmd defined)
{{ejc{{{{{1694
*      systt -- trace toggle
{systt{exp{1,0{{{define external entry point{1698
*      called by spitbol function trace() with no args to
*      toggle the system trace switch.  this permits tracing of
*      labels in spitbol code to be turned on or off.
*      jsr  systt            call to toggle trace switch
{{ejc{{{{{1705
*      sysul -- unload external function
{sysul{exp{1,0{{{define external entry point{1709
*      sysul is used to unload a function previously
*      loaded with a call to sysld.
*      (xr)                  ptr to control block (efblk)
*      jsr  sysul            call to unload function
*      the function cannot be called following a sysul call
*      until another sysld call is made for the same function.
*      the efblk contains the function code pointer and also a
*      pointer to the vrblk containing the function name (see
*      definitions and data structures section).
{{ejc{{{{{1725
*      sysxi -- exit to produce load module
{sysxi{exp{1,2{{{define external entry point{1729
*      when sysxi is called, xl contains either a string pointer
*      or zero. in the former case, the string gives the
*      character name of a program. the intention is that
*      spitbol execution should be terminated forthwith and
*      the named program loaded and executed. this type of chain
*      execution is very system dependent and implementors may
*      choose to omit it or find it impossible to provide.
*      if (xl) is zero,ia contains one of the following integers
*      -1, -2, -3, -4
*           create if possible a load module containing only the
*           impure area of memory which needs to be loaded with
*           a compatible pure segment for subsequent executions.
*           version numbers to check compatibility should be
*           kept in both segments and checked on loading.
*           to assist with this check, (xr) on entry is a
*           pointer to an scblk containing the spitbol major
*           version number v.v (see sysid).  the file thus
*           created is called a save file.
*      0    if possible, return control to job control
*           command level. the effect if available will be
*           system dependent.
*      +1, +2, +3, +4
*           create if possible a load module from all of
*           memory. it should be possible to load and execute
*           this module directly.
*      in the case of saved load modules, the status of open
*      files is not preserved and implementors may choose to
*      offer means of attaching files before execution of load
*      modules starts or leave it to the user to include
*      suitable input(), output() calls in his program.
*      sysxi should make a note that no i/o channels,
*      including standard files, have files attached so that
*      calls of sysin, sysou, syspr, sysrd should fail unless
*      new associations are made for the load module.
*      at least in the case of the standard output file, it is
*      recommended that either the user be required to attach
*      a file or that a default file is attached, since the
*      problem of error messages generated by the load module
*      is otherwise severe. as a last resort, if spitbol
*      attempts to write to the standard output file and gets a
*      reply indicating that such ouput is unacceptable it stops
*      by using an entry to sysej with ending code 998.
*      as described below, passing of some arguments makes it
*      clear that load module will use a standard output file.
*      if use is made of fcblks for i/o association, spitbol
*      builds a chain so that those in use may be found in sysxi
*      and sysej. the nodes are 4 words long. third word
*      contains link to next node or 0, fourth word contains
*      fcblk pointer.
{{ejc{{{{{1785
*      sysxi (continued)
*      (xl)                  zero or scblk ptr to first argument
*      (xr)                  ptr to v.v scblk
*      (ia)                  signed integer argument
*      (wa)                  scblk ptr to second argument
*      (wb)                  0 or ptr to head of fcblk chain
*      jsr  sysxi            call to exit
*      ppm  loc              requested action not possible
*      ppm  loc              action caused irrecoverable error
*      (wb,wc,ia,xr,xl,cp)   should be preserved over call
*      (wa)                  0 in all cases except sucessful
*                            performance of exit(4) or exit(-4),
*                            in which case 1 should be returned.
*      loading and running the load module or returning from
*      jcl command level causes execution to resume at the point
*      after the error returns which follow the call of sysxi.
*      the value passed as exit argument is used to indicate
*      options required on resumption of load module.
*      +1 or -1 require that on resumption, sysid and syspp be
*      called and a heading printed on the standard output file.
*      +2 or -2 indicate that syspp will be called but not sysid
*      and no heading will be put on standard output file.
*      above options have the obvious implication that a
*      standard o/p file must be provided for the load module.
*      +3, +4, -3 or -4 indicate calls of neither sysid nor
*      syspp and no heading will be placed on standard output
*      file.
*      +4 or -4 indicate that execution is to continue after
*      creation of the save file or load module, although all
*      files will be closed by the sysxi action.  this permits
*      the user to checkpoint long-running programs while
*      continuing execution.
*      no return from sysxi is possible if another program
*      is loaded and entered.
{{ejc{{{{{1825
*      introduce the internal procedures.
{acess{inp{25,r{1,1{{{1829
{acomp{inp{25,n{1,5{{{1830
{alloc{inp{25,e{1,0{{{1831
{alocs{inp{25,e{1,0{{{1836
{alost{inp{25,e{1,0{{{1837
{arith{inp{25,n{1,3{{{1845
{asign{inp{25,r{1,1{{{1847
{asinp{inp{25,r{1,1{{{1848
{blkln{inp{25,e{1,0{{{1849
{cdgcg{inp{25,e{1,0{{{1850
{cdgex{inp{25,r{1,0{{{1851
{cdgnm{inp{25,r{1,0{{{1852
{cdgvl{inp{25,r{1,0{{{1853
{cdwrd{inp{25,e{1,0{{{1854
{cmgen{inp{25,r{1,0{{{1855
{cmpil{inp{25,e{1,0{{{1856
{cncrd{inp{25,e{1,0{{{1857
{copyb{inp{25,n{1,1{{{1858
{dffnc{inp{25,e{1,0{{{1859
{dtach{inp{25,e{1,0{{{1860
{dtype{inp{25,e{1,0{{{1861
{dumpr{inp{25,e{1,0{{{1862
{ermsg{inp{25,e{1,0{{{1867
{ertex{inp{25,e{1,0{{{1868
{evali{inp{25,r{1,4{{{1869
{evalp{inp{25,r{1,1{{{1870
{evals{inp{25,r{1,3{{{1871
{evalx{inp{25,r{1,1{{{1872
{exbld{inp{25,e{1,0{{{1873
{expan{inp{25,e{1,0{{{1874
{expap{inp{25,e{1,1{{{1875
{expdm{inp{25,n{1,0{{{1876
{expop{inp{25,n{1,0{{{1877
{filnm{inp{25,e{1,0{{{1879
{gbcol{inp{25,e{1,0{{{1884
{gbcpf{inp{25,e{1,0{{{1885
{gtarr{inp{25,e{1,2{{{1886
{{ejc{{{{{1887
{gtcod{inp{25,e{1,1{{{1888
{gtexp{inp{25,e{1,1{{{1889
{gtint{inp{25,e{1,1{{{1890
{gtnum{inp{25,e{1,1{{{1891
{gtnvr{inp{25,e{1,1{{{1892
{gtpat{inp{25,e{1,1{{{1893
{gtrea{inp{25,e{1,1{{{1896
{gtsmi{inp{25,n{1,2{{{1898
{gtstg{inp{25,n{1,1{{{1903
{gtvar{inp{25,e{1,1{{{1904
{hashs{inp{25,e{1,0{{{1905
{icbld{inp{25,e{1,0{{{1906
{ident{inp{25,e{1,1{{{1907
{inout{inp{25,e{1,0{{{1908
{insta{inp{25,e{1,0{{{1913
{iofcb{inp{25,n{1,3{{{1914
{ioppf{inp{25,n{1,0{{{1915
{ioput{inp{25,n{1,7{{{1916
{ktrex{inp{25,r{1,0{{{1917
{kwnam{inp{25,n{1,0{{{1918
{lcomp{inp{25,n{1,5{{{1919
{listr{inp{25,e{1,0{{{1920
{listt{inp{25,e{1,0{{{1921
{newfn{inp{25,e{1,0{{{1923
{nexts{inp{25,e{1,0{{{1925
{patin{inp{25,n{1,2{{{1926
{patst{inp{25,n{1,1{{{1927
{pbild{inp{25,e{1,0{{{1928
{pconc{inp{25,e{1,0{{{1929
{pcopy{inp{25,n{1,0{{{1930
{prflr{inp{25,e{1,0{{{1933
{prflu{inp{25,e{1,0{{{1934
{prpar{inp{25,e{1,0{{{1936
{prtch{inp{25,e{1,0{{{1937
{prtic{inp{25,e{1,0{{{1938
{prtis{inp{25,e{1,0{{{1939
{prtin{inp{25,e{1,0{{{1940
{prtmi{inp{25,e{1,0{{{1941
{prtmm{inp{25,e{1,0{{{1942
{prtmx{inp{25,e{1,0{{{1943
{prtnl{inp{25,r{1,0{{{1944
{prtnm{inp{25,r{1,0{{{1945
{prtnv{inp{25,e{1,0{{{1946
{prtpg{inp{25,e{1,0{{{1947
{prtps{inp{25,e{1,0{{{1948
{prtsn{inp{25,e{1,0{{{1949
{prtst{inp{25,r{1,0{{{1950
{{ejc{{{{{1951
{prttr{inp{25,e{1,0{{{1952
{prtvl{inp{25,r{1,0{{{1953
{prtvn{inp{25,e{1,0{{{1954
{rcbld{inp{25,e{1,0{{{1957
{readr{inp{25,e{1,0{{{1959
{relaj{inp{25,e{1,0{{{1961
{relcr{inp{25,e{1,0{{{1962
{reldn{inp{25,e{1,0{{{1963
{reloc{inp{25,e{1,0{{{1964
{relst{inp{25,e{1,0{{{1965
{relws{inp{25,e{1,0{{{1966
{rstrt{inp{25,e{1,0{{{1968
{sbstr{inp{25,e{1,0{{{1972
{scane{inp{25,e{1,0{{{1973
{scngf{inp{25,e{1,0{{{1974
{setvr{inp{25,e{1,0{{{1975
{sorta{inp{25,n{1,1{{{1978
{sortc{inp{25,e{1,1{{{1979
{sortf{inp{25,e{1,0{{{1980
{sorth{inp{25,n{1,0{{{1981
{start{inp{25,e{1,0{{{1983
{stgcc{inp{25,e{1,0{{{1984
{tfind{inp{25,e{1,1{{{1985
{tmake{inp{25,e{1,0{{{1986
{trace{inp{25,n{1,2{{{1987
{trbld{inp{25,e{1,0{{{1988
{trimr{inp{25,e{1,0{{{1989
{trxeq{inp{25,r{1,0{{{1990
{vmake{inp{25,e{1,1{{{1991
{xscan{inp{25,e{1,0{{{1992
{xscni{inp{25,n{1,2{{{1993
*      introduce the internal routines
{arref{inr{{{{{1997
{cfunc{inr{{{{{1998
{exfal{inr{{{{{1999
{exint{inr{{{{{2000
{exits{inr{{{{{2001
{exixr{inr{{{{{2002
{exnam{inr{{{{{2003
{exnul{inr{{{{{2004
{exrea{inr{{{{{2007
{exsid{inr{{{{{2009
{exvnm{inr{{{{{2010
{failp{inr{{{{{2011
{flpop{inr{{{{{2012
{indir{inr{{{{{2013
{match{inr{{{{{2014
{retrn{inr{{{{{2015
{stcov{inr{{{{{2016
{stmgo{inr{{{{{2017
{stopr{inr{{{{{2018
{succp{inr{{{{{2019
{sysab{inr{{{{{2020
{systu{inr{{{{{2021
{{ttl{27,s p i t b o l -- definitions and data structures{{{{2022
*      this section contains all symbol definitions and also
*      pictures of all data structures used in the system.
{{sec{{{{start of definitions section{2026
*      definitions of machine parameters
*      the minimal translator should supply appropriate values
*      for the particular target machine for all the
*      equ  *
*      definitions given at the start of this section.
*      note that even if conditional assembly is used to omit
*      some feature (e.g. real arithmetic) a full set of cfp_-
*      values must be supplied. use dummy values if genuine
*      ones are not needed.
{cfp_a{equ{24,256{{{number of characters in alphabet{2039
{cfp_b{equ{24,8{{{bytes/word addressing factor{2041
{cfp_c{equ{24,8{{{number of characters per word{2043
{cfp_f{equ{24,16{{{offset in bytes to chars in{2045
*                            scblk. see scblk format.
{cfp_i{equ{24,1{{{number of words in integer constant{2048
{cfp_m{equ{24,9223372036854775807{{{max positive integer in one word{2050
{cfp_n{equ{24,64{{{number of bits in one word{2052
*      the following definitions require the supply of either
*      a single parameter if real arithmetic is omitted or
*      three parameters if real arithmetic is included.
{cfp_r{equ{24,1{{{number of words in real constant{2062
{cfp_s{equ{24,9{{{number of sig digs for real output{2064
{cfp_x{equ{24,3{{{max digits in real exponent{2066
{mxdgs{equ{24,cfp_s+cfp_x{{{max digits in real number{2077
*      max space for real (for +0.e+) needs five more places
{nstmx{equ{24,mxdgs+5{{{max space for real{2082
*      the following definition for cfp_u supplies a realistic
*      upper bound on the size of the alphabet.  cfp_u is used
*      to save space in the scane bsw-iff-esw table and to ease
*      translation storage requirements.
{cfp_u{equ{24,128{{{realistic upper bound on alphabet{2092
{{ejc{{{{{2094
*      environment parameters
*      the spitbol program is essentially independent of
*      the definitions of these parameters. however, the
*      efficiency of the system may be affected. consequently,
*      these parameters may require tuning for a given version
*      the values given in comments have been successfully used.
*      e_srs is the number of words to reserve at the end of
*      storage for end of run processing. it should be
*      set as small as possible without causing memory overflow
*      in critical situations (e.g. memory overflow termination)
*      and should thus reserve sufficient space at least for
*      an scblk containing say 30 characters.
{e_srs{equ{24,100{{{30 words{2111
*      e_sts is the number of words grabbed in a chunk when
*      storage is allocated in the static region. the minimum
*      permitted value is 256/cfp_b. larger values will lead
*      to increased efficiency at the cost of wasting memory.
{e_sts{equ{24,1000{{{500 words{2118
*      e_cbs is the size of code block allocated initially and
*      the expansion increment if overflow occurs. if this value
*      is too small or too large, excessive garbage collections
*      will occur during compilation and memory may be lost
*      in the case of a too large value.
{e_cbs{equ{24,500{{{500 words{2126
*      e_hnb is the number of bucket headers in the variable
*      hash table. it should always be odd. larger values will
*      speed up compilation and indirect references at the
*      expense of additional storage for the hash table itself.
{e_hnb{equ{24,257{{{127 bucket headers{2133
*      e_hnw is the maximum number of words of a string
*      name which participate in the string hash algorithm.
*      larger values give a better hash at the expense of taking
*      longer to compute the hash. there is some optimal value.
{e_hnw{equ{24,3{{{6 words{2140
*      e_fsp.  if the amount of free space left after a garbage
*      collection is small compared to the total amount of space
*      in use garbage collector thrashing is likely to occur as
*      this space is used up.  e_fsp is a measure of the
*      minimum percentage of dynamic memory left as free space
*      before the system routine sysmm is called to try to
*      obtain more memory.
{e_fsp{equ{24,15{{{15 percent{2150
*      e_sed.  if the amount of free space left in the sediment
*      after a garbage collection is a significant fraction of
*      the new sediment size, the sediment is marked for
*      collection on the next call to the garbage collector.
{e_sed{equ{24,25{{{25 percent{2158
{{ejc{{{{{2160
*      definitions of codes for letters
{ch_la{equ{24,97{{{letter a{2164
{ch_lb{equ{24,98{{{letter b{2165
{ch_lc{equ{24,99{{{letter c{2166
{ch_ld{equ{24,100{{{letter d{2167
{ch_le{equ{24,101{{{letter e{2168
{ch_lf{equ{24,102{{{letter f{2169
{ch_lg{equ{24,103{{{letter g{2170
{ch_lh{equ{24,104{{{letter h{2171
{ch_li{equ{24,105{{{letter i{2172
{ch_lj{equ{24,106{{{letter j{2173
{ch_lk{equ{24,107{{{letter k{2174
{ch_ll{equ{24,108{{{letter l{2175
{ch_lm{equ{24,109{{{letter m{2176
{ch_ln{equ{24,110{{{letter n{2177
{ch_lo{equ{24,111{{{letter o{2178
{ch_lp{equ{24,112{{{letter p{2179
{ch_lq{equ{24,113{{{letter q{2180
{ch_lr{equ{24,114{{{letter r{2181
{ch_ls{equ{24,115{{{letter s{2182
{ch_lt{equ{24,116{{{letter t{2183
{ch_lu{equ{24,117{{{letter u{2184
{ch_lv{equ{24,118{{{letter v{2185
{ch_lw{equ{24,119{{{letter w{2186
{ch_lx{equ{24,120{{{letter x{2187
{ch_ly{equ{24,121{{{letter y{2188
{ch_l_{equ{24,122{{{letter z{2189
*      definitions of codes for digits
{ch_d0{equ{24,48{{{digit 0{2193
{ch_d1{equ{24,49{{{digit 1{2194
{ch_d2{equ{24,50{{{digit 2{2195
{ch_d3{equ{24,51{{{digit 3{2196
{ch_d4{equ{24,52{{{digit 4{2197
{ch_d5{equ{24,53{{{digit 5{2198
{ch_d6{equ{24,54{{{digit 6{2199
{ch_d7{equ{24,55{{{digit 7{2200
{ch_d8{equ{24,56{{{digit 8{2201
{ch_d9{equ{24,57{{{digit 9{2202
{{ejc{{{{{2203
*      definitions of codes for special characters
*      the names of these characters are related to their
*      original representation in the ebcdic set corresponding
*      to the description in standard snobol4 manuals and texts.
{ch_am{equ{24,38{{{keyword operator (ampersand){2211
{ch_as{equ{24,42{{{multiplication symbol (asterisk){2212
{ch_at{equ{24,64{{{cursor position operator (at){2213
{ch_bb{equ{24,60{{{left array bracket (less than){2214
{ch_bl{equ{24,32{{{blank{2215
{ch_br{equ{24,124{{{alternation operator (vertical bar){2216
{ch_cl{equ{24,58{{{goto symbol (colon){2217
{ch_cm{equ{24,44{{{comma{2218
{ch_dl{equ{24,36{{{indirection operator (dollar){2219
{ch_dt{equ{24,46{{{name operator (dot){2220
{ch_dq{equ{24,34{{{double quote{2221
{ch_eq{equ{24,61{{{equal sign{2222
{ch_ex{equ{24,33{{{exponentiation operator (exclm){2223
{ch_mn{equ{24,45{{{minus sign / hyphen{2224
{ch_nm{equ{24,35{{{number sign{2225
{ch_nt{equ{24,126{{{negation operator (not){2226
{ch_pc{equ{24,94{{{percent{2227
{ch_pl{equ{24,43{{{plus sign{2228
{ch_pp{equ{24,40{{{left parenthesis{2229
{ch_rb{equ{24,62{{{right array bracket (grtr than){2230
{ch_rp{equ{24,41{{{right parenthesis{2231
{ch_qu{equ{24,63{{{interrogation operator (question){2232
{ch_sl{equ{24,47{{{slash{2233
{ch_sm{equ{24,59{{{semicolon{2234
{ch_sq{equ{24,39{{{single quote{2235
{ch_u_{equ{24,95{{{special identifier char (underline){2236
{ch_ob{equ{24,91{{{opening bracket{2237
{ch_cb{equ{24,93{{{closing bracket{2238
{{ejc{{{{{2239
*      remaining chars are optional additions to the standards.
*      tab characters - syntactically equivalent to blank
{ch_ht{equ{24,9{{{horizontal tab{2246
*      up arrow same as exclamation mark for exponentiation
{ch_ey{equ{24,94{{{up arrow{2255
*      upper case or shifted case alphabetic chars
{ch_ua{equ{24,65{{{shifted a{2261
{ch_ub{equ{24,66{{{shifted b{2262
{ch_uc{equ{24,67{{{shifted c{2263
{ch_ud{equ{24,68{{{shifted d{2264
{ch_ue{equ{24,69{{{shifted e{2265
{ch_uf{equ{24,70{{{shifted f{2266
{ch_ug{equ{24,71{{{shifted g{2267
{ch_uh{equ{24,72{{{shifted h{2268
{ch_ui{equ{24,73{{{shifted i{2269
{ch_uj{equ{24,74{{{shifted j{2270
{ch_uk{equ{24,75{{{shifted k{2271
{ch_ul{equ{24,76{{{shifted l{2272
{ch_um{equ{24,77{{{shifted m{2273
{ch_un{equ{24,78{{{shifted n{2274
{ch_uo{equ{24,79{{{shifted o{2275
{ch_up{equ{24,80{{{shifted p{2276
{ch_uq{equ{24,81{{{shifted q{2277
{ch_ur{equ{24,82{{{shifted r{2278
{ch_us{equ{24,83{{{shifted s{2279
{ch_ut{equ{24,84{{{shifted t{2280
{ch_uu{equ{24,85{{{shifted u{2281
{ch_uv{equ{24,86{{{shifted v{2282
{ch_uw{equ{24,87{{{shifted w{2283
{ch_ux{equ{24,88{{{shifted x{2284
{ch_uy{equ{24,89{{{shifted y{2285
{ch_uz{equ{24,90{{{shifted z{2286
*      if a delimiter other than ch_cm must be used in
*      the third argument of input(),output() then .ciod should
*      be defined and a parameter supplied for iodel.
{iodel{equ{24,32{{{{2293
{{ejc{{{{{2297
*      data block formats and definitions
*      the following sections describe the detailed format of
*      all possible data blocks in static and dynamic memory.
*      every block has a name of the form xxblk where xx is a
*      unique two character identifier. the first word of every
*      block must contain a pointer to a program location in the
*      interpretor which is immediately preceded by an address
*      constant containing the value bl_xx where xx is the block
*      identifier. this provides a uniform mechanism for
*      distinguishing between the various block types.
*      in some cases, the contents of the first word is constant
*      for a given block type and merely serves as a pointer
*      to the identifying address constant. however, in other
*      cases there are several possibilities for the first
*      word in which case each of the several program entry
*      points must be preceded by the appropriate constant.
*      in each block, some of the fields are relocatable. this
*      means that they may contain a pointer to another block
*      in the dynamic area. (to be more precise, if they contain
*      a pointer within the dynamic area, then it is a pointer
*      to a block). such fields must be modified by the garbage
*      collector (procedure gbcol) whenever blocks are compacted
*      in the dynamic region. the garbage collector (actually
*      procedure gbcpf) requires that all such relocatable
*      fields in a block must be contiguous.
{{ejc{{{{{2328
*      the description format uses the following scheme.
*      1)   block title and two character identifier
*      2)   description of basic use of block and indication
*           of circumstances under which it is constructed.
*      3)   picture of the block format. in these pictures low
*           memory addresses are at the top of the page. fixed
*           length fields are surrounded by i (letter i). fields
*           which are fixed length but whose length is dependent
*           on a configuration parameter are surrounded by *
*           (asterisk). variable length fields are surrounded
*           by / (slash).
*      4)   definition of symbolic offsets to fields in
*           block and of the size of the block if fixed length
*           or of the size of the fixed length fields if the
*           block is variable length.
*           note that some routines such as gbcpf assume
*           certain offsets are equal. the definitions
*           given here enforce this.  make changes to
*           them only with due care.
*      definitions of common offsets
{offs1{equ{24,1{{{{2356
{offs2{equ{24,2{{{{2357
{offs3{equ{24,3{{{{2358
*      5)   detailed comments on the significance and formats
*           of the various fields.
*      the order is alphabetical by identification code.
{{ejc{{{{{2364
*      definitions of block codes
*      this table provides a unique identification code for
*      each separate block type. the first word of a block in
*      the dynamic area always contains the address of a program
*      entry point. the block code is used as the entry point id
*      the order of these codes dictates the order of the table
*      used by the datatype function (scnmt in the constant sec)
*      block codes for accessible datatypes
*      note that real and buffer types are always included, even
*      if they are conditionally excluded elsewhere.  this main-
*      tains block type codes across all versions of spitbol,
*      providing consistancy for external functions.  but note
*      that the bcblk is out of alphabetic order, placed at the
*      end of the list so as not to change the block type
*      ordering in use in existing external functions.
{bl_ar{equ{24,0{{{arblk     array{2385
{bl_cd{equ{24,bl_ar+1{{{cdblk     code{2386
{bl_ex{equ{24,bl_cd+1{{{exblk     expression{2387
{bl_ic{equ{24,bl_ex+1{{{icblk     integer{2388
{bl_nm{equ{24,bl_ic+1{{{nmblk     name{2389
{bl_p0{equ{24,bl_nm+1{{{p0blk     pattern{2390
{bl_p1{equ{24,bl_p0+1{{{p1blk     pattern{2391
{bl_p2{equ{24,bl_p1+1{{{p2blk     pattern{2392
{bl_rc{equ{24,bl_p2+1{{{rcblk     real{2393
{bl_sc{equ{24,bl_rc+1{{{scblk     string{2394
{bl_se{equ{24,bl_sc+1{{{seblk     expression{2395
{bl_tb{equ{24,bl_se+1{{{tbblk     table{2396
{bl_vc{equ{24,bl_tb+1{{{vcblk     array{2397
{bl_xn{equ{24,bl_vc+1{{{xnblk     external{2398
{bl_xr{equ{24,bl_xn+1{{{xrblk     external{2399
{bl_bc{equ{24,bl_xr+1{{{bcblk     buffer{2400
{bl_pd{equ{24,bl_bc+1{{{pdblk     program defined datatype{2401
{bl__d{equ{24,bl_pd+1{{{number of block codes for data{2403
*      other block codes
{bl_tr{equ{24,bl_pd+1{{{trblk{2407
{bl_bf{equ{24,bl_tr+1{{{bfblk{2408
{bl_cc{equ{24,bl_bf+1{{{ccblk{2409
{bl_cm{equ{24,bl_cc+1{{{cmblk{2410
{bl_ct{equ{24,bl_cm+1{{{ctblk{2411
{bl_df{equ{24,bl_ct+1{{{dfblk{2412
{bl_ef{equ{24,bl_df+1{{{efblk{2413
{bl_ev{equ{24,bl_ef+1{{{evblk{2414
{bl_ff{equ{24,bl_ev+1{{{ffblk{2415
{bl_kv{equ{24,bl_ff+1{{{kvblk{2416
{bl_pf{equ{24,bl_kv+1{{{pfblk{2417
{bl_te{equ{24,bl_pf+1{{{teblk{2418
{bl__i{equ{24,0{{{default identification code{2420
{bl__t{equ{24,bl_tr+1{{{code for data or trace block{2421
{bl___{equ{24,bl_te+1{{{number of block codes{2422
{{ejc{{{{{2423
*      field references
*      references to the fields of data blocks are symbolic
*      (i.e. use the symbolic offsets) with the following
*      exceptions.
*      1)   references to the first word are usually not
*           symbolic since they use the (x) operand format.
*      2)   the code which constructs a block is often not
*           symbolic and should be changed if the corresponding
*           block format is modified.
*      3)   the plc and psc instructions imply an offset
*           corresponding to the definition of cfp_f.
*      4)   there are non-symbolic references (easily changed)
*           in the garbage collector (procedures gbcpf, blkln).
*      5)   the fields idval, fargs appear in several blocks
*           and any changes must be made in parallel to all
*           blocks containing the fields. the actual references
*           to these fields are symbolic with the above
*           listed exceptions.
*      6)   several spots in the code assume that the
*           definitions of the fields vrval, teval, trnxt are
*           the same (these are sections of code which search
*           out along a trblk chain from a variable).
*      7)   references to the fields of an array block in the
*           array reference routine arref are non-symbolic.
*      apart from the exceptions listed, references are symbolic
*      as far as possible and modifying the order or number
*      of fields will not require changes.
{{ejc{{{{{2461
*      common fields for function blocks
*      blocks which represent callable functions have two
*      common fields at the start of the block as follows.
*           +------------------------------------+
*           i                fcode               i
*           +------------------------------------+
*           i                fargs               i
*           +------------------------------------+
*           /                                    /
*           /       rest of function block       /
*           /                                    /
*           +------------------------------------+
{fcode{equ{24,0{{{pointer to code for function{2478
{fargs{equ{24,1{{{number of arguments{2479
*      fcode is a pointer to the location in the interpretor
*      program which processes this type of function call.
*      fargs is the expected number of arguments. the actual
*      number of arguments is adjusted to this amount by
*      deleting extra arguments or supplying trailing nulls
*      for missing ones before transferring though fcode.
*      a value of 999 may be used in this field to indicate a
*      variable number of arguments (see svblk field svnar).
*      the block types which follow this scheme are.
*      ffblk                 field function
*      dfblk                 datatype function
*      pfblk                 program defined function
*      efblk                 external loaded function
{{ejc{{{{{2497
*      identification field
*      id   field
*      certain program accessible objects (those which contain
*      other data values and can be copied) are given a unique
*      identification number (see exsid). this id value is an
*      address integer value which is always stored in word two.
{idval{equ{24,1{{{id value field{2509
*      the blocks containing an idval field are.
*      arblk                 array
*      pdblk                 program defined datatype
*      tbblk                 table
*      vcblk                 vector block (array)
*      note that a zero idval means that the block is only
*      half built and should not be dumped (see dumpr).
{{ejc{{{{{2524
*      array block (arblk)
*      an array block represents an array value other than one
*      with one dimension whose lower bound is one (see vcblk).
*      an arblk is built with a call to the functions convert
*      (s_cnv) or array (s_arr).
*           +------------------------------------+
*           i                artyp               i
*           +------------------------------------+
*           i                idval               i
*           +------------------------------------+
*           i                arlen               i
*           +------------------------------------+
*           i                arofs               i
*           +------------------------------------+
*           i                arndm               i
*           +------------------------------------+
*           *                arlbd               *
*           +------------------------------------+
*           *                ardim               *
*           +------------------------------------+
*           *                                    *
*           * above 2 flds repeated for each dim *
*           *                                    *
*           +------------------------------------+
*           i                arpro               i
*           +------------------------------------+
*           /                                    /
*           /                arvls               /
*           /                                    /
*           +------------------------------------+
{{ejc{{{{{2558
*      array block (continued)
{artyp{equ{24,0{{{pointer to dummy routine b_art{2562
{arlen{equ{24,idval+1{{{length of arblk in bytes{2563
{arofs{equ{24,arlen+1{{{offset in arblk to arpro field{2564
{arndm{equ{24,arofs+1{{{number of dimensions{2565
{arlbd{equ{24,arndm+1{{{low bound (first subscript){2566
{ardim{equ{24,arlbd+cfp_i{{{dimension (first subscript){2567
{arlb2{equ{24,ardim+cfp_i{{{low bound (second subscript){2568
{ardm2{equ{24,arlb2+cfp_i{{{dimension (second subscript){2569
{arpro{equ{24,ardim+cfp_i{{{array prototype (one dimension){2570
{arvls{equ{24,arpro+1{{{start of values (one dimension){2571
{arpr2{equ{24,ardm2+cfp_i{{{array prototype (two dimensions){2572
{arvl2{equ{24,arpr2+1{{{start of values (two dimensions){2573
{arsi_{equ{24,arlbd{{{number of standard fields in block{2574
{ardms{equ{24,arlb2-arlbd{{{size of info for one set of bounds{2575
*      the bounds and dimension fields are signed integer
*      values and each occupy cfp_i words in the arblk.
*      the length of an arblk in bytes may not exceed mxlen.
*      this is required to keep name offsets garbage collectable
*      the actual values are arranged in row-wise order and
*      can contain a data pointer or a pointer to a trblk.
{{ejc{{{{{2661
*      code construction block (ccblk)
*      at any one moment there is at most one ccblk into
*      which the compiler is currently storing code (cdwrd).
*           +------------------------------------+
*           i                cctyp               i
*           +------------------------------------+
*           i                cclen               i
*           +------------------------------------+
*           i                ccsln               i
*           +------------------------------------+
*           i                ccuse               i
*           +------------------------------------+
*           /                                    /
*           /                cccod               /
*           /                                    /
*           +------------------------------------+
{cctyp{equ{24,0{{{pointer to dummy routine b_cct{2684
{cclen{equ{24,cctyp+1{{{length of ccblk in bytes{2685
{ccsln{equ{24,cclen+1{{{source line number{2687
{ccuse{equ{24,ccsln+1{{{offset past last used word (bytes){2688
{cccod{equ{24,ccuse+1{{{start of generated code in block{2692
*      the reason that the ccblk is a separate block type from
*      the usual cdblk is that the garbage collector must
*      only process those fields which have been set (see gbcpf)
{{ejc{{{{{2697
*      code block (cdblk)
*      a code block is built for each statement compiled during
*      the initial compilation or by subsequent calls to code.
*           +------------------------------------+
*           i                cdjmp               i
*           +------------------------------------+
*           i                cdstm               i
*           +------------------------------------+
*           i                cdsln               i
*           +------------------------------------+
*           i                cdlen               i
*           +------------------------------------+
*           i                cdfal               i
*           +------------------------------------+
*           /                                    /
*           /                cdcod               /
*           /                                    /
*           +------------------------------------+
{cdjmp{equ{24,0{{{ptr to routine to execute statement{2722
{cdstm{equ{24,cdjmp+1{{{statement number{2723
{cdsln{equ{24,cdstm+1{{{source line number{2725
{cdlen{equ{24,cdsln+1{{{length of cdblk in bytes{2726
{cdfal{equ{24,cdlen+1{{{failure exit (see below){2727
{cdcod{equ{24,cdfal+1{{{executable pseudo-code{2732
{cdsi_{equ{24,cdcod{{{number of standard fields in cdblk{2733
*      cdstm is the statement number of the current statement.
*      cdjmp, cdfal are set as follows.
*      1)   if the failure exit is the next statement
*           cdjmp = b_cds
*           cdfal = ptr to cdblk for next statement
*      2)   if the failure exit is a simple label name
*           cdjmp = b_cds
*           cdfal is a ptr to the vrtra field of the vrblk
*      3)   if there is no failure exit (-nofail mode)
*           cdjmp = b_cds
*           cdfal = o_unf
*      4)   if the failure exit is complex or direct
*           cdjmp = b_cdc
*           cdfal is the offset to the o_gof word
{{ejc{{{{{2758
*      code block (continued)
*      cdcod is the start of the actual code. first we describe
*      the code generated for an expression. in an expression,
*      elements are fetched by name or by value. for example,
*      the binary equal operator fetches its left argument
*      by name and its right argument by value. these two
*      cases generate quite different code and are described
*      separately. first we consider the code by value case.
*      generation of code by value for expressions elements.
*      expression            pointer to exblk or seblk
*      integer constant      pointer to icblk
*      null constant         pointer to nulls
*      pattern               (resulting from preevaluation)
*                            =o_lpt
*                            pointer to p0blk,p1blk or p2blk
*      real constant         pointer to rcblk
*      string constant       pointer to scblk
*      variable              pointer to vrget field of vrblk
*      addition              value code for left operand
*                            value code for right operand
*                            =o_add
*      affirmation           value code for operand
*                            =o_aff
*      alternation           value code for left operand
*                            value code for right operand
*                            =o_alt
*      array reference       (case of one subscript)
*                            value code for array operand
*                            value code for subscript operand
*                            =o_aov
*                            (case of more than one subscript)
*                            value code for array operand
*                            value code for first subscript
*                            value code for second subscript
*                            ...
*                            value code for last subscript
*                            =o_amv
*                            number of subscripts
{{ejc{{{{{2812
*      code block (continued)
*      assignment            (to natural variable)
*                            value code for right operand
*                            pointer to vrsto field of vrblk
*                            (to any other variable)
*                            name code for left operand
*                            value code for right operand
*                            =o_ass
*      compile error         =o_cer
*      complementation       value code for operand
*                            =o_com
*      concatenation         (case of pred func left operand)
*                            value code for left operand
*                            =o_pop
*                            value code for right operand
*                            (all other cases)
*                            value code for left operand
*                            value code for right operand
*                            =o_cnc
*      cursor assignment     name code for operand
*                            =o_cas
*      division              value code for left operand
*                            value code for right operand
*                            =o_dvd
*      exponentiation        value code for left operand
*                            value code for right operand
*                            =o_exp
*      function call         (case of call to system function)
*                            value code for first argument
*                            value code for second argument
*                            ...
*                            value code for last argument
*                            pointer to svfnc field of svblk
{{ejc{{{{{2859
*      code block (continued)
*      function call         (case of non-system function 1 arg)
*                            value code for argument
*                            =o_fns
*                            pointer to vrblk for function
*                            (non-system function, gt 1 arg)
*                            value code for first argument
*                            value code for second argument
*                            ...
*                            value code for last argument
*                            =o_fnc
*                            number of arguments
*                            pointer to vrblk for function
*      immediate assignment  value code for left operand
*                            name code for right operand
*                            =o_ima
*      indirection           value code for operand
*                            =o_inv
*      interrogation         value code for operand
*                            =o_int
*      keyword reference     name code for operand
*                            =o_kwv
*      multiplication        value code for left operand
*                            value code for right operand
*                            =o_mlt
*      name reference        (natural variable case)
*                            pointer to nmblk for name
*                            (all other cases)
*                            name code for operand
*                            =o_nam
*      negation              =o_nta
*                            cdblk offset of o_ntc word
*                            value code for operand
*                            =o_ntb
*                            =o_ntc
{{ejc{{{{{2906
*      code block (continued)
*      pattern assignment    value code for left operand
*                            name code for right operand
*                            =o_pas
*      pattern match         value code for left operand
*                            value code for right operand
*                            =o_pmv
*      pattern replacement   name code for subject
*                            value code for pattern
*                            =o_pmn
*                            value code for replacement
*                            =o_rpl
*      selection             (for first alternative)
*                            =o_sla
*                            cdblk offset to next o_slc word
*                            value code for first alternative
*                            =o_slb
*                            cdblk offset past alternatives
*                            (for subsequent alternatives)
*                            =o_slc
*                            cdblk offset to next o_slc,o_sld
*                            value code for alternative
*                            =o_slb
*                            offset in cdblk past alternatives
*                            (for last alternative)
*                            =o_sld
*                            value code for last alternative
*      subtraction           value code for left operand
*                            value code for right operand
*                            =o_sub
{{ejc{{{{{2945
*      code block (continued)
*      generation of code by name for expression elements.
*      variable              =o_lvn
*                            pointer to vrblk
*      expression            (case of *natural variable)
*                            =o_lvn
*                            pointer to vrblk
*                            (all other cases)
*                            =o_lex
*                            pointer to exblk
*      array reference       (case of one subscript)
*                            value code for array operand
*                            value code for subscript operand
*                            =o_aon
*                            (case of more than one subscript)
*                            value code for array operand
*                            value code for first subscript
*                            value code for second subscript
*                            ...
*                            value code for last subscript
*                            =o_amn
*                            number of subscripts
*      compile error         =o_cer
*      function call         (same code as for value call)
*                            =o_fne
*      indirection           value code for operand
*                            =o_inn
*      keyword reference     name code for operand
*                            =o_kwn
*      any other operand is an error in a name position
*      note that in this description, =o_xxx refers to the
*      generation of a word containing the address of another
*      word which contains the entry point address o_xxx.
{{ejc{{{{{2993
*      code block (continued)
*      now we consider the overall structure of the code block
*      for a statement with possible goto fields.
*      first comes the code for the statement body.
*      the statement body is an expression to be evaluated
*      by value although the value is not actually required.
*      normal value code is generated for the body of the
*      statement except in the case of a pattern match by
*      value, in which case the following is generated.
*                            value code for left operand
*                            value code for right operand
*                            =o_pms
*      next we have the code for the success goto. there are
*      several cases as follows.
*      1)   no success goto  ptr to cdblk for next statement
*      2)   simple label     ptr to vrtra field of vrblk
*      3)   complex goto     (code by name for goto operand)
*                            =o_goc
*      4)   direct goto      (code by value for goto operand)
*                            =o_god
*      following this we generate code for the failure goto if
*      it is direct or if it is complex, simple failure gotos
*      having been handled by an appropriate setting of the
*      cdfal field of the cdblk. the generated code is one
*      of the following.
*      1)   complex fgoto    =o_fif
*                            =o_gof
*                            name code for goto operand
*                            =o_goc
*      2)   direct fgoto     =o_fif
*                            =o_gof
*                            value code for goto operand
*                            =o_god
*      an optimization occurs if the success and failure gotos
*      are identical and either complex or direct. in this case,
*      no code is generated for the success goto and control
*      is allowed to fall into the failure goto on success.
{{ejc{{{{{3044
*      compiler block (cmblk)
*      a compiler block (cmblk) is built by expan to represent
*      one node of a tree structured expression representation.
*           +------------------------------------+
*           i                cmidn               i
*           +------------------------------------+
*           i                cmlen               i
*           +------------------------------------+
*           i                cmtyp               i
*           +------------------------------------+
*           i                cmopn               i
*           +------------------------------------+
*           /           cmvls or cmrop           /
*           /                                    /
*           /                cmlop               /
*           /                                    /
*           +------------------------------------+
{cmidn{equ{24,0{{{pointer to dummy routine b_cmt{3066
{cmlen{equ{24,cmidn+1{{{length of cmblk in bytes{3067
{cmtyp{equ{24,cmlen+1{{{type (c_xxx, see list below){3068
{cmopn{equ{24,cmtyp+1{{{operand pointer (see below){3069
{cmvls{equ{24,cmopn+1{{{operand value pointers (see below){3070
{cmrop{equ{24,cmvls{{{right (only) operator operand{3071
{cmlop{equ{24,cmvls+1{{{left operator operand{3072
{cmsi_{equ{24,cmvls{{{number of standard fields in cmblk{3073
{cmus_{equ{24,cmsi_+1{{{size of unary operator cmblk{3074
{cmbs_{equ{24,cmsi_+2{{{size of binary operator cmblk{3075
{cmar1{equ{24,cmvls+1{{{array subscript pointers{3076
*      the cmopn and cmvls fields are set as follows
*      array reference       cmopn = ptr to array operand
*                            cmvls = ptrs to subscript operands
*      function call         cmopn = ptr to vrblk for function
*                            cmvls = ptrs to argument operands
*      selection             cmopn = zero
*                            cmvls = ptrs to alternate operands
*      unary operator        cmopn = ptr to operator dvblk
*                            cmrop = ptr to operand
*      binary operator       cmopn = ptr to operator dvblk
*                            cmrop = ptr to right operand
*                            cmlop = ptr to left operand
{{ejc{{{{{3095
*      cmtyp is set to indicate the type of expression element
*      as shown by the following table of definitions.
{c_arr{equ{24,0{{{array reference{3100
{c_fnc{equ{24,c_arr+1{{{function call{3101
{c_def{equ{24,c_fnc+1{{{deferred expression (unary *){3102
{c_ind{equ{24,c_def+1{{{indirection (unary _){3103
{c_key{equ{24,c_ind+1{{{keyword reference (unary ampersand){3104
{c_ubo{equ{24,c_key+1{{{undefined binary operator{3105
{c_uuo{equ{24,c_ubo+1{{{undefined unary operator{3106
{c_uo_{equ{24,c_uuo+1{{{test value (=c_uuo+1=c_ubo+2){3107
{c__nm{equ{24,c_uuo+1{{{number of codes for name operands{3108
*      the remaining types indicate expression elements which
*      can only be evaluated by value (not by name).
{c_bvl{equ{24,c_uuo+1{{{binary op with value operands{3113
{c_uvl{equ{24,c_bvl+1{{{unary operator with value operand{3114
{c_alt{equ{24,c_uvl+1{{{alternation (binary bar){3115
{c_cnc{equ{24,c_alt+1{{{concatenation{3116
{c_cnp{equ{24,c_cnc+1{{{concatenation, not pattern match{3117
{c_unm{equ{24,c_cnp+1{{{unary op with name operand{3118
{c_bvn{equ{24,c_unm+1{{{binary op (operands by value, name){3119
{c_ass{equ{24,c_bvn+1{{{assignment{3120
{c_int{equ{24,c_ass+1{{{interrogation{3121
{c_neg{equ{24,c_int+1{{{negation (unary not){3122
{c_sel{equ{24,c_neg+1{{{selection{3123
{c_pmt{equ{24,c_sel+1{{{pattern match{3124
{c_pr_{equ{24,c_bvn{{{last preevaluable code{3126
{c__nv{equ{24,c_pmt+1{{{number of different cmblk types{3127
{{ejc{{{{{3128
*      character table block (ctblk)
*      a character table block is used to hold logical character
*      tables for use with any,notany,span,break,breakx
*      patterns. each character table can be used to store
*      cfp_n distinct tables as bit columns. a bit column
*      allocated for each argument of more than one character
*      in length to one of the above listed pattern primitives.
*           +------------------------------------+
*           i                cttyp               i
*           +------------------------------------+
*           *                                    *
*           *                                    *
*           *                ctchs               *
*           *                                    *
*           *                                    *
*           +------------------------------------+
{cttyp{equ{24,0{{{pointer to dummy routine b_ctt{3149
{ctchs{equ{24,cttyp+1{{{start of character table words{3150
{ctsi_{equ{24,ctchs+cfp_a{{{number of words in ctblk{3151
*      ctchs is cfp_a words long and consists of a one word
*      bit string value for each possible character in the
*      internal alphabet. each of the cfp_n possible bits in
*      a bitstring is used to form a column of bit indicators.
*      a bit is set on if the character is in the table and off
*      if the character is not present.
{{ejc{{{{{3159
*      datatype function block (dfblk)
*      a datatype function is used to control the construction
*      of a program defined datatype object. a call to the
*      system function data builds a dfblk for the datatype name
*      note that these blocks are built in static because pdblk
*      length is got from dflen field.  if dfblk was in dynamic
*      store this would cause trouble during pass two of garbage
*      collection.  scblk referred to by dfnam field is also put
*      in static so that there are no reloc. fields. this cuts
*      garbage collection task appreciably for pdblks which are
*      likely to be present in large numbers.
*           +------------------------------------+
*           i                fcode               i
*           +------------------------------------+
*           i                fargs               i
*           +------------------------------------+
*           i                dflen               i
*           +------------------------------------+
*           i                dfpdl               i
*           +------------------------------------+
*           i                dfnam               i
*           +------------------------------------+
*           /                                    /
*           /                dffld               /
*           /                                    /
*           +------------------------------------+
{dflen{equ{24,fargs+1{{{length of dfblk in bytes{3191
{dfpdl{equ{24,dflen+1{{{length of corresponding pdblk{3192
{dfnam{equ{24,dfpdl+1{{{pointer to scblk for datatype name{3193
{dffld{equ{24,dfnam+1{{{start of vrblk ptrs for field names{3194
{dfflb{equ{24,dffld-1{{{offset behind dffld for field func{3195
{dfsi_{equ{24,dffld{{{number of standard fields in dfblk{3196
*      the fcode field points to the routine b_dfc
*      fargs (the number of arguments) is the number of fields.
{{ejc{{{{{3201
*      dope vector block (dvblk)
*      a dope vector is assembled for each possible operator in
*      the snobol4 language as part of the constant section.
*           +------------------------------------+
*           i                dvopn               i
*           +------------------------------------+
*           i                dvtyp               i
*           +------------------------------------+
*           i                dvlpr               i
*           +------------------------------------+
*           i                dvrpr               i
*           +------------------------------------+
{dvopn{equ{24,0{{{entry address (ptr to o_xxx){3218
{dvtyp{equ{24,dvopn+1{{{type code (c_xxx, see cmblk){3219
{dvlpr{equ{24,dvtyp+1{{{left precedence (llxxx, see below){3220
{dvrpr{equ{24,dvlpr+1{{{right precedence (rrxxx, see below){3221
{dvus_{equ{24,dvlpr+1{{{size of unary operator dv{3222
{dvbs_{equ{24,dvrpr+1{{{size of binary operator dv{3223
{dvubs{equ{24,dvus_+dvbs_{{{size of unop + binop (see scane){3224
*      the contents of the dvtyp field is copied into the cmtyp
*      field of the cmblk for the operator if it is used.
*      the cmopn field of an operator cmblk points to the dvblk
*      itself, providing the required entry address pointer ptr.
*      for normally undefined operators, the dvopn (and cmopn)
*      fields contain a word offset from r_uba of the function
*      block pointer for the operator (instead of o_xxx ptr).
*      for certain special operators, the dvopn field is not
*      required at all and is assembled as zero.
*      the left precedence is used in comparing an operator to
*      the left of some other operator. it therefore governs the
*      precedence of the operator towards its right operand.
*      the right precedence is used in comparing an operator to
*      the right of some other operator. it therefore governs
*      the precedence of the operator towards its left operand.
*      higher precedence values correspond to a tighter binding
*      capability. thus we have the left precedence lower
*      (higher) than the right precedence for right (left)
*      associative binary operators.
*      the left precedence of unary operators is set to an
*      arbitrary high value. the right value is not required and
*      consequently the dvrpr field is omitted for unary ops.
{{ejc{{{{{3254
*      table of operator precedence values
{rrass{equ{24,10{{{right     equal{3258
{llass{equ{24,00{{{left      equal{3259
{rrpmt{equ{24,20{{{right     question mark{3260
{llpmt{equ{24,30{{{left      question mark{3261
{rramp{equ{24,40{{{right     ampersand{3262
{llamp{equ{24,50{{{left      ampersand{3263
{rralt{equ{24,70{{{right     vertical bar{3264
{llalt{equ{24,60{{{left      vertical bar{3265
{rrcnc{equ{24,90{{{right     blank{3266
{llcnc{equ{24,80{{{left      blank{3267
{rrats{equ{24,110{{{right     at{3268
{llats{equ{24,100{{{left      at{3269
{rrplm{equ{24,120{{{right     plus, minus{3270
{llplm{equ{24,130{{{left      plus, minus{3271
{rrnum{equ{24,140{{{right     number{3272
{llnum{equ{24,150{{{left      number{3273
{rrdvd{equ{24,160{{{right     slash{3274
{lldvd{equ{24,170{{{left      slash{3275
{rrmlt{equ{24,180{{{right     asterisk{3276
{llmlt{equ{24,190{{{left      asterisk{3277
{rrpct{equ{24,200{{{right     percent{3278
{llpct{equ{24,210{{{left      percent{3279
{rrexp{equ{24,230{{{right     exclamation{3280
{llexp{equ{24,220{{{left      exclamation{3281
{rrdld{equ{24,240{{{right     dollar, dot{3282
{lldld{equ{24,250{{{left      dollar, dot{3283
{rrnot{equ{24,270{{{right     not{3284
{llnot{equ{24,260{{{left      not{3285
{lluno{equ{24,999{{{left      all unary operators{3286
*      precedences are the same as in btl snobol4 with the
*      following exceptions.
*      1)   binary question mark is lowered and made left assoc-
*           iative to reflect its new use for pattern matching.
*      2)   alternation and concatenation are made right
*           associative for greater efficiency in pattern
*           construction and matching respectively. this change
*           is transparent to the snobol4 programmer.
*      3)   the equal sign has been added as a low precedence
*           operator which is right associative to reflect its
*           more general usage in this version of snobol4.
{{ejc{{{{{3302
*      external function block (efblk)
*      an external function block is used to control the calling
*      of an external function. it is built by a call to load.
*           +------------------------------------+
*           i                fcode               i
*           +------------------------------------+
*           i                fargs               i
*           +------------------------------------+
*           i                eflen               i
*           +------------------------------------+
*           i                efuse               i
*           +------------------------------------+
*           i                efcod               i
*           +------------------------------------+
*           i                efvar               i
*           +------------------------------------+
*           i                efrsl               i
*           +------------------------------------+
*           /                                    /
*           /                eftar               /
*           /                                    /
*           +------------------------------------+
{eflen{equ{24,fargs+1{{{length of efblk in bytes{3329
{efuse{equ{24,eflen+1{{{use count (for opsyn){3330
{efcod{equ{24,efuse+1{{{ptr to code (from sysld){3331
{efvar{equ{24,efcod+1{{{ptr to associated vrblk{3332
{efrsl{equ{24,efvar+1{{{result type (see below){3333
{eftar{equ{24,efrsl+1{{{argument types (see below){3334
{efsi_{equ{24,eftar{{{number of standard fields in efblk{3335
*      the fcode field points to the routine b_efc.
*      efuse is used to keep track of multiple use when opsyn
*      is employed. the function is automatically unloaded
*      when there are no more references to the function.
*      efrsl and eftar are type codes as follows.
*           0                type is unconverted
*           1                type is string
*           2                type is integer
*           3                type is real
*           4                type is file
{{ejc{{{{{3358
*      expression variable block (evblk)
*      in this version of spitbol, an expression can be used in
*      any position which would normally expect a name (for
*      example on the left side of equals or as the right
*      argument of binary dot). this corresponds to the creation
*      of a pseudo-variable which is represented by a pointer to
*      an expression variable block as follows.
*           +------------------------------------+
*           i                evtyp               i
*           +------------------------------------+
*           i                evexp               i
*           +------------------------------------+
*           i                evvar               i
*           +------------------------------------+
{evtyp{equ{24,0{{{pointer to dummy routine b_evt{3377
{evexp{equ{24,evtyp+1{{{pointer to exblk for expression{3378
{evvar{equ{24,evexp+1{{{pointer to trbev dummy trblk{3379
{evsi_{equ{24,evvar+1{{{size of evblk{3380
*      the name of an expression variable is represented by a
*      base pointer to the evblk and an offset of evvar. this
*      value appears to be trapped by the dummy trbev block.
*      note that there is no need to allow for the case of an
*      expression variable which references an seblk since a
*      variable which is of the form *var is equivalent to var.
{{ejc{{{{{3389
*      expression block (exblk)
*      an expression block is built for each expression
*      referenced in a program or created by eval or convert
*      during execution of a program.
*           +------------------------------------+
*           i                extyp               i
*           +------------------------------------+
*           i                exstm               i
*           +------------------------------------+
*           i                exsln               i
*           +------------------------------------+
*           i                exlen               i
*           +------------------------------------+
*           i                exflc               i
*           +------------------------------------+
*           /                                    /
*           /                excod               /
*           /                                    /
*           +------------------------------------+
{extyp{equ{24,0{{{ptr to routine b_exl to load expr{3415
{exstm{equ{24,cdstm{{{stores stmnt no. during evaluation{3416
{exsln{equ{24,exstm+1{{{stores line no. during evaluation{3418
{exlen{equ{24,exsln+1{{{length of exblk in bytes{3419
{exflc{equ{24,exlen+1{{{failure code (=o_fex){3423
{excod{equ{24,exflc+1{{{pseudo-code for expression{3424
{exsi_{equ{24,excod{{{number of standard fields in exblk{3425
*      there are two cases for excod depending on whether the
*      expression can be evaluated by name (see description
*      of cdblk for details of code for expressions).
*      if the expression can be evaluated by name we have.
*                            (code for expr by name)
*                            =o_rnm
*      if the expression can only be evaluated by value.
*                            (code for expr by value)
*                            =o_rvl
{{ejc{{{{{3440
*      field function block (ffblk)
*      a field function block is used to control the selection
*      of a field from a program defined datatype block.
*      a call to data creates an ffblk for each field.
*           +------------------------------------+
*           i                fcode               i
*           +------------------------------------+
*           i                fargs               i
*           +------------------------------------+
*           i                ffdfp               i
*           +------------------------------------+
*           i                ffnxt               i
*           +------------------------------------+
*           i                ffofs               i
*           +------------------------------------+
{ffdfp{equ{24,fargs+1{{{pointer to associated dfblk{3460
{ffnxt{equ{24,ffdfp+1{{{ptr to next ffblk on chain or zero{3461
{ffofs{equ{24,ffnxt+1{{{offset (bytes) to field in pdblk{3462
{ffsi_{equ{24,ffofs+1{{{size of ffblk in words{3463
*      the fcode field points to the routine b_ffc.
*      fargs always contains one.
*      ffdfp is used to verify that the correct program defined
*      datatype is being accessed by this call.
*      ffdfp is non-reloc. because dfblk is in static
*      ffofs is used to select the appropriate field. note that
*      it is an actual offset (not a field number)
*      ffnxt is used to point to the next ffblk of the same name
*      in the case where there are several fields of the same
*      name for different datatypes. zero marks the end of chain
{{ejc{{{{{3479
*      integer constant block (icblk)
*      an icblk is created for every integer referenced or
*      created by a program. note however that certain internal
*      integer values are stored as addresses (e.g. the length
*      field in a string constant block)
*           +------------------------------------+
*           i                icget               i
*           +------------------------------------+
*           *                icval               *
*           +------------------------------------+
{icget{equ{24,0{{{ptr to routine b_icl to load int{3494
{icval{equ{24,icget+1{{{integer value{3495
{icsi_{equ{24,icval+cfp_i{{{size of icblk{3496
*      the length of the icval field is cfp_i.
{{ejc{{{{{3499
*      keyword variable block (kvblk)
*      a kvblk is used to represent a keyword pseudo-variable.
*      a kvblk is built for each keyword reference (kwnam).
*           +------------------------------------+
*           i                kvtyp               i
*           +------------------------------------+
*           i                kvvar               i
*           +------------------------------------+
*           i                kvnum               i
*           +------------------------------------+
{kvtyp{equ{24,0{{{pointer to dummy routine b_kvt{3514
{kvvar{equ{24,kvtyp+1{{{pointer to dummy block trbkv{3515
{kvnum{equ{24,kvvar+1{{{keyword number{3516
{kvsi_{equ{24,kvnum+1{{{size of kvblk{3517
*      the name of a keyword variable is represented by a
*      base pointer to the kvblk and an offset of kvvar. the
*      value appears to be trapped by the pointer to trbkv.
{{ejc{{{{{3522
*      name block (nmblk)
*      a name block is used wherever a name must be stored as
*      a value following use of the unary dot operator.
*           +------------------------------------+
*           i                nmtyp               i
*           +------------------------------------+
*           i                nmbas               i
*           +------------------------------------+
*           i                nmofs               i
*           +------------------------------------+
{nmtyp{equ{24,0{{{ptr to routine b_nml to load name{3537
{nmbas{equ{24,nmtyp+1{{{base pointer for variable{3538
{nmofs{equ{24,nmbas+1{{{offset for variable{3539
{nmsi_{equ{24,nmofs+1{{{size of nmblk{3540
*      the actual field representing the contents of the name
*      is found nmofs bytes past the address in nmbas.
*      the name is split into base and offset form to avoid
*      creation of a pointer into the middle of a block which
*      could not be handled properly by the garbage collector.
*      a name may be built for any variable (see section on
*      representations of variables) this includes the
*      cases of pseudo-variables.
{{ejc{{{{{3552
*      pattern block, no parameters (p0blk)
*      a p0blk is used to represent pattern nodes which do
*      not require the use of any parameter values.
*           +------------------------------------+
*           i                pcode               i
*           +------------------------------------+
*           i                pthen               i
*           +------------------------------------+
{pcode{equ{24,0{{{ptr to match routine (p_xxx){3565
{pthen{equ{24,pcode+1{{{pointer to subsequent node{3566
{pasi_{equ{24,pthen+1{{{size of p0blk{3567
*      pthen points to the pattern block for the subsequent
*      node to be matched. this is a pointer to the pattern
*      block ndnth if there is no subsequent (end of pattern)
*      pcode is a pointer to the match routine for the node.
{{ejc{{{{{3574
*      pattern block (one parameter)
*      a p1blk is used to represent pattern nodes which
*      require one parameter value.
*           +------------------------------------+
*           i                pcode               i
*           +------------------------------------+
*           i                pthen               i
*           +------------------------------------+
*           i                parm1               i
*           +------------------------------------+
{parm1{equ{24,pthen+1{{{first parameter value{3589
{pbsi_{equ{24,parm1+1{{{size of p1blk in words{3590
*      see p0blk for definitions of pcode, pthen
*      parm1 contains a parameter value used in matching the
*      node. for example, in a len pattern, it is the integer
*      argument to len. the details of the use of the parameter
*      field are included in the description of the individual
*      match routines. parm1 is always an address pointer which
*      is processed by the garbage collector.
{{ejc{{{{{3600
*      pattern block (two parameters)
*      a p2blk is used to represent pattern nodes which
*      require two parameter values.
*           +------------------------------------+
*           i                pcode               i
*           +------------------------------------+
*           i                pthen               i
*           +------------------------------------+
*           i                parm1               i
*           +------------------------------------+
*           i                parm2               i
*           +------------------------------------+
{parm2{equ{24,parm1+1{{{second parameter value{3617
{pcsi_{equ{24,parm2+1{{{size of p2blk in words{3618
*      see p1blk for definitions of pcode, pthen, parm1
*      parm2 is a parameter which performs the same sort of
*      function as parm1 (see description of p1blk).
*      parm2 is a non-relocatable field and is not
*      processed by the garbage collector. accordingly, it may
*      not contain a pointer to a block in dynamic memory.
{{ejc{{{{{3628
*      program-defined datatype block
*      a pdblk represents the data item formed by a call to a
*      datatype function as defined by the system function data.
*           +------------------------------------+
*           i                pdtyp               i
*           +------------------------------------+
*           i                idval               i
*           +------------------------------------+
*           i                pddfp               i
*           +------------------------------------+
*           /                                    /
*           /                pdfld               /
*           /                                    /
*           +------------------------------------+
{pdtyp{equ{24,0{{{ptr to dummy routine b_pdt{3647
{pddfp{equ{24,idval+1{{{ptr to associated dfblk{3648
{pdfld{equ{24,pddfp+1{{{start of field value pointers{3649
{pdfof{equ{24,dffld-pdfld{{{difference in offset to field ptrs{3650
{pdsi_{equ{24,pdfld{{{size of standard fields in pdblk{3651
{pddfs{equ{24,dfsi_-pdsi_{{{difference in dfblk, pdblk sizes{3652
*      the pddfp pointer may be used to determine the datatype
*      and the names of the fields if required. the dfblk also
*      contains the length of the pdblk in bytes (field dfpdl).
*      pddfp is non-reloc. because dfblk is in static
*      pdfld values are stored in order from left to right.
*      they contain values or pointers to trblk chains.
{{ejc{{{{{3661
*      program defined function block (pfblk)
*      a pfblk is created for each call to the define function
*      and a pointer to the pfblk placed in the proper vrblk.
*           +------------------------------------+
*           i                fcode               i
*           +------------------------------------+
*           i                fargs               i
*           +------------------------------------+
*           i                pflen               i
*           +------------------------------------+
*           i                pfvbl               i
*           +------------------------------------+
*           i                pfnlo               i
*           +------------------------------------+
*           i                pfcod               i
*           +------------------------------------+
*           i                pfctr               i
*           +------------------------------------+
*           i                pfrtr               i
*           +------------------------------------+
*           /                                    /
*           /                pfarg               /
*           /                                    /
*           +------------------------------------+
{pflen{equ{24,fargs+1{{{length of pfblk in bytes{3690
{pfvbl{equ{24,pflen+1{{{pointer to vrblk for function name{3691
{pfnlo{equ{24,pfvbl+1{{{number of locals{3692
{pfcod{equ{24,pfnlo+1{{{ptr to vrblk for entry label{3693
{pfctr{equ{24,pfcod+1{{{trblk ptr if call traced else 0{3694
{pfrtr{equ{24,pfctr+1{{{trblk ptr if return traced else 0{3695
{pfarg{equ{24,pfrtr+1{{{vrblk ptrs for arguments and locals{3696
{pfagb{equ{24,pfarg-1{{{offset behind pfarg for arg, local{3697
{pfsi_{equ{24,pfarg{{{number of standard fields in pfblk{3698
*      the fcode field points to the routine b_pfc.
*      pfarg is stored in the following order.
*           arguments (left to right)
*           locals (left to right)
{{ejc{{{{{3708
*      real constant block (rcblk)
*      an rcblk is created for every real referenced or
*      created by a program.
*           +------------------------------------+
*           i                rcget               i
*           +------------------------------------+
*           *                rcval               *
*           +------------------------------------+
{rcget{equ{24,0{{{ptr to routine b_rcl to load real{3721
{rcval{equ{24,rcget+1{{{real value{3722
{rcsi_{equ{24,rcval+cfp_r{{{size of rcblk{3723
*      the length of the rcval field is cfp_r.
{{ejc{{{{{3727
*      string constant block (scblk)
*      an scblk is built for every string referenced or created
*      by a program.
*           +------------------------------------+
*           i                scget               i
*           +------------------------------------+
*           i                sclen               i
*           +------------------------------------+
*           /                                    /
*           /                schar               /
*           /                                    /
*           +------------------------------------+
{scget{equ{24,0{{{ptr to routine b_scl to load string{3744
{sclen{equ{24,scget+1{{{length of string in characters{3745
{schar{equ{24,sclen+1{{{characters of string{3746
{scsi_{equ{24,schar{{{size of standard fields in scblk{3747
*      the characters of the string are stored left justified.
*      the final word is padded on the right with zeros.
*      (i.e. the character whose internal code is zero).
*      the value of sclen may not exceed mxlen. this ensures
*      that character offsets (e.g. the pattern match cursor)
*      can be correctly processed by the garbage collector.
*      note that the offset to the characters of the string
*      is given in bytes by cfp_f and that this value is
*      automatically allowed for in plc, psc.
*      note that for a spitbol scblk, the value of cfp_f
*      is given by cfp_b*schar.
{{ejc{{{{{3762
*      simple expression block (seblk)
*      an seblk is used to represent an expression of the form
*      *(natural variable). all other expressions are exblks.
*           +------------------------------------+
*           i                setyp               i
*           +------------------------------------+
*           i                sevar               i
*           +------------------------------------+
{setyp{equ{24,0{{{ptr to routine b_sel to load expr{3775
{sevar{equ{24,setyp+1{{{ptr to vrblk for variable{3776
{sesi_{equ{24,sevar+1{{{length of seblk in words{3777
{{ejc{{{{{3778
*      standard variable block (svblk)
*      an svblk is assembled in the constant section for each
*      variable which satisfies one of the following conditions.
*      1)   it is the name of a system function
*      2)   it has an initial value
*      3)   it has a keyword association
*      4)   it has a standard i/o association
*      6)   it has a standard label association
*      if vrblks are constructed for any of these variables,
*      then the vrsvp field points to the svblk (see vrblk)
*           +------------------------------------+
*           i                svbit               i
*           +------------------------------------+
*           i                svlen               i
*           +------------------------------------+
*           /                svchs               /
*           +------------------------------------+
*           i                svknm               i
*           +------------------------------------+
*           i                svfnc               i
*           +------------------------------------+
*           i                svnar               i
*           +------------------------------------+
*           i                svlbl               i
*           +------------------------------------+
*           i                svval               i
*           +------------------------------------+
{{ejc{{{{{3811
*      standard variable block (continued)
{svbit{equ{24,0{{{bit string indicating attributes{3815
{svlen{equ{24,1{{{(=sclen) length of name in chars{3816
{svchs{equ{24,2{{{(=schar) characters of name{3817
{svsi_{equ{24,2{{{number of standard fields in svblk{3818
{svpre{equ{24,1{{{set if preevaluation permitted{3819
{svffc{equ{24,svpre+svpre{{{set on if fast call permitted{3820
{svckw{equ{24,svffc+svffc{{{set on if keyword value constant{3821
{svprd{equ{24,svckw+svckw{{{set on if predicate function{3822
{svnbt{equ{24,4{{{number of bits to right of svknm{3823
{svknm{equ{24,svprd+svprd{{{set on if keyword association{3824
{svfnc{equ{24,svknm+svknm{{{set on if system function{3825
{svnar{equ{24,svfnc+svfnc{{{set on if system function{3826
{svlbl{equ{24,svnar+svnar{{{set on if system label{3827
{svval{equ{24,svlbl+svlbl{{{set on if predefined value{3828
*      note that the last five bits correspond in order
*      to the fields which are present (see procedure gtnvr).
*      the following definitions are used in the svblk table
{svfnf{equ{24,svfnc+svnar{{{function with no fast call{3835
{svfnn{equ{24,svfnf+svffc{{{function with fast call, no preeval{3836
{svfnp{equ{24,svfnn+svpre{{{function allowing preevaluation{3837
{svfpr{equ{24,svfnn+svprd{{{predicate function{3838
{svfnk{equ{24,svfnn+svknm{{{no preeval func + keyword{3839
{svkwv{equ{24,svknm+svval{{{keyword + value{3840
{svkwc{equ{24,svckw+svknm{{{keyword with constant value{3841
{svkvc{equ{24,svkwv+svckw{{{constant keyword + value{3842
{svkvl{equ{24,svkvc+svlbl{{{constant keyword + value + label{3843
{svfpk{equ{24,svfnp+svkvc{{{preeval fcn + const keywd + val{3844
*      the svpre bit allows the compiler to preevaluate a call
*      to the associated system function if all the arguments
*      are themselves constants. functions in this category
*      must have no side effects and must never cause failure.
*      the call may generate an error condition.
*      the svffc bit allows the compiler to generate the special
*      fast call after adjusting the number of arguments. only
*      the item and apply functions fall outside this category.
*      the svckw bit is set if the associated keyword value is
*      a constant, thus allowing preevaluation for a value call.
*      the svprd bit is set on for all predicate functions to
*      enable the special concatenation code optimization.
{{ejc{{{{{3861
*      svblk (continued)
*      svknm                 keyword number
*           svknm is present only for a standard keyword assoc.
*           it contains a keyword number as defined by the
*           keyword number table given later on.
*      svfnc                 system function pointer
*           svfnc is present only for a system function assoc.
*           it is a pointer to the actual code for the system
*           function. the generated code for a fast call is a
*           pointer to the svfnc field of the svblk for the
*           function. the vrfnc field of the vrblk points to
*           this same field, in which case, it serves as the
*           fcode field for the function call.
*      svnar                 number of function arguments
*           svnar is present only for a system function assoc.
*           it is the number of arguments required for a call
*           to the system function. the compiler uses this
*           value to adjust the number of arguments in a fast
*           call and in the case of a function called through
*           the vrfnc field of the vrblk, the svnar field
*           serves as the fargs field for o_fnc. a special
*           case occurs if this value is set to 999. this is
*           used to indicate that the function has a variable
*           number of arguments and causes o_fnc to pass control
*           without adjusting the argument count. the only
*           predefined functions using this are apply and item.
*      svlbl                 system label pointer
*           svlbl is present only for a standard label assoc.
*           it is a pointer to a system label routine (l_xxx).
*           the vrlbl field of the corresponding vrblk points to
*           the svlbl field of the svblk.
*      svval                 system value pointer
*           svval is present only for a standard value.
*           it is a pointer to the pattern node (ndxxx) which
*           is the standard initial value of the variable.
*           this value is copied to the vrval field of the vrblk
{{ejc{{{{{3909
*      svblk (continued)
*      keyword number table
*      the following table gives symbolic names for keyword
*      numbers. these values are stored in the svknm field of
*      svblks and in the kvnum field of kvblks. see also
*      procedures asign, acess and kwnam.
*      unprotected keywords with one word integer values
{k_abe{equ{24,0{{{abend{3922
{k_anc{equ{24,k_abe+cfp_b{{{anchor{3923
{k_cod{equ{24,k_anc+cfp_b{{{code{3928
{k_com{equ{24,k_cod+cfp_b{{{compare{3931
{k_dmp{equ{24,k_com+cfp_b{{{dump{3932
{k_erl{equ{24,k_dmp+cfp_b{{{errlimit{3936
{k_ert{equ{24,k_erl+cfp_b{{{errtype{3937
{k_ftr{equ{24,k_ert+cfp_b{{{ftrace{3938
{k_fls{equ{24,k_ftr+cfp_b{{{fullscan{3939
{k_inp{equ{24,k_fls+cfp_b{{{input{3940
{k_mxl{equ{24,k_inp+cfp_b{{{maxlength{3941
{k_oup{equ{24,k_mxl+cfp_b{{{output{3942
{k_pfl{equ{24,k_oup+cfp_b{{{profile{3946
{k_tra{equ{24,k_pfl+cfp_b{{{trace{3947
{k_trm{equ{24,k_tra+cfp_b{{{trim{3949
*      protected keywords with one word integer values
{k_fnc{equ{24,k_trm+cfp_b{{{fnclevel{3953
{k_lst{equ{24,k_fnc+cfp_b{{{lastno{3954
{k_lln{equ{24,k_lst+cfp_b{{{lastline{3956
{k_lin{equ{24,k_lln+cfp_b{{{line{3957
{k_stn{equ{24,k_lin+cfp_b{{{stno{3958
*      keywords with constant pattern values
{k_abo{equ{24,k_stn+cfp_b{{{abort{3965
{k_arb{equ{24,k_abo+pasi_{{{arb{3966
{k_bal{equ{24,k_arb+pasi_{{{bal{3967
{k_fal{equ{24,k_bal+pasi_{{{fail{3968
{k_fen{equ{24,k_fal+pasi_{{{fence{3969
{k_rem{equ{24,k_fen+pasi_{{{rem{3970
{k_suc{equ{24,k_rem+pasi_{{{succeed{3971
{{ejc{{{{{3972
*      keyword number table (continued)
*      special keywords
{k_alp{equ{24,k_suc+1{{{alphabet{3978
{k_rtn{equ{24,k_alp+1{{{rtntype{3979
{k_stc{equ{24,k_rtn+1{{{stcount{3980
{k_etx{equ{24,k_stc+1{{{errtext{3981
{k_fil{equ{24,k_etx+1{{{file{3983
{k_lfl{equ{24,k_fil+1{{{lastfile{3984
{k_stl{equ{24,k_lfl+1{{{stlimit{3985
{k_lcs{equ{24,k_stl+1{{{lcase{3990
{k_ucs{equ{24,k_lcs+1{{{ucase{3991
*      relative offsets of special keywords
{k__al{equ{24,k_alp-k_alp{{{alphabet{3996
{k__rt{equ{24,k_rtn-k_alp{{{rtntype{3997
{k__sc{equ{24,k_stc-k_alp{{{stcount{3998
{k__et{equ{24,k_etx-k_alp{{{errtext{3999
{k__fl{equ{24,k_fil-k_alp{{{file{4001
{k__lf{equ{24,k_lfl-k_alp{{{lastfile{4002
{k__sl{equ{24,k_stl-k_alp{{{stlimit{4004
{k__lc{equ{24,k_lcs-k_alp{{{lcase{4006
{k__uc{equ{24,k_ucs-k_alp{{{ucase{4007
{k__n_{equ{24,k__uc+1{{{number of special cases{4008
*      symbols used in asign and acess procedures
{k_p__{equ{24,k_fnc{{{first protected keyword{4015
{k_v__{equ{24,k_abo{{{first keyword with constant value{4016
{k_s__{equ{24,k_alp{{{first keyword with special acess{4017
{{ejc{{{{{4018
*      format of a table block (tbblk)
*      a table block is used to represent a table value.
*      it is built by a call to the table or convert functions.
*           +------------------------------------+
*           i                tbtyp               i
*           +------------------------------------+
*           i                idval               i
*           +------------------------------------+
*           i                tblen               i
*           +------------------------------------+
*           i                tbinv               i
*           +------------------------------------+
*           /                                    /
*           /                tbbuk               /
*           /                                    /
*           +------------------------------------+
{tbtyp{equ{24,0{{{pointer to dummy routine b_tbt{4039
{tblen{equ{24,offs2{{{length of tbblk in bytes{4040
{tbinv{equ{24,offs3{{{default initial lookup value{4041
{tbbuk{equ{24,tbinv+1{{{start of hash bucket pointers{4042
{tbsi_{equ{24,tbbuk{{{size of standard fields in tbblk{4043
{tbnbk{equ{24,11{{{default no. of buckets{4044
*      the table block is a hash table which points to chains
*      of table element blocks representing the elements
*      in the table which hash into the same bucket.
*      tbbuk entries either point to the first teblk on the
*      chain or they point to the tbblk itself to indicate the
*      end of the chain.
{{ejc{{{{{4053
*      table element block (teblk)
*      a table element is used to represent a single entry in
*      a table (see description of tbblk format for hash table)
*           +------------------------------------+
*           i                tetyp               i
*           +------------------------------------+
*           i                tesub               i
*           +------------------------------------+
*           i                teval               i
*           +------------------------------------+
*           i                tenxt               i
*           +------------------------------------+
{tetyp{equ{24,0{{{pointer to dummy routine b_tet{4070
{tesub{equ{24,tetyp+1{{{subscript value{4071
{teval{equ{24,tesub+1{{{(=vrval) table element value{4072
{tenxt{equ{24,teval+1{{{link to next teblk{4073
*      see s_cnv where relation is assumed with tenxt and tbbuk
{tesi_{equ{24,tenxt+1{{{size of teblk in words{4075
*      tenxt points to the next teblk on the hash chain from the
*      tbbuk chain for this hash index. at the end of the chain,
*      tenxt points back to the start of the tbblk.
*      teval contains a data pointer or a trblk pointer.
*      tesub contains a data pointer.
{{ejc{{{{{4084
*      trap block (trblk)
*      a trap block is used to represent a trace or input or
*      output association in response to a call to the trace
*      input or output system functions. see below for details
*           +------------------------------------+
*           i                tridn               i
*           +------------------------------------+
*           i                trtyp               i
*           +------------------------------------+
*           i  trval or trlbl or trnxt or trkvr  i
*           +------------------------------------+
*           i       trtag or trter or trtrf      i
*           +------------------------------------+
*           i            trfnc or trfpt          i
*           +------------------------------------+
{tridn{equ{24,0{{{pointer to dummy routine b_trt{4104
{trtyp{equ{24,tridn+1{{{trap type code{4105
{trval{equ{24,trtyp+1{{{value of trapped variable (=vrval){4106
{trnxt{equ{24,trval{{{ptr to next trblk on trblk chain{4107
{trlbl{equ{24,trval{{{ptr to actual label (traced label){4108
{trkvr{equ{24,trval{{{vrblk pointer for keyword trace{4109
{trtag{equ{24,trval+1{{{trace tag{4110
{trter{equ{24,trtag{{{ptr to terminal vrblk or null{4111
{trtrf{equ{24,trtag{{{ptr to trblk holding fcblk ptr{4112
{trfnc{equ{24,trtag+1{{{trace function vrblk (zero if none){4113
{trfpt{equ{24,trfnc{{{fcblk ptr for sysio{4114
{trsi_{equ{24,trfnc+1{{{number of words in trblk{4115
{trtin{equ{24,0{{{trace type for input association{4117
{trtac{equ{24,trtin+1{{{trace type for access trace{4118
{trtvl{equ{24,trtac+1{{{trace type for value trace{4119
{trtou{equ{24,trtvl+1{{{trace type for output association{4120
{trtfc{equ{24,trtou+1{{{trace type for fcblk identification{4121
{{ejc{{{{{4122
*      trap block (continued)
*      variable input association
*           the value field of the variable points to a trblk
*           instead of containing the data value. in the case
*           of a natural variable, the vrget and vrsto fields
*           contain =b_vra and =b_vrv to activate the check.
*           trtyp is set to trtin
*           trnxt points to next trblk or trval has variable val
*           trter is a pointer to svblk if association is
*           for input, terminal, else it is null.
*           trtrf points to the trap block which in turn points
*           to an fcblk used for i/o association.
*           trfpt is the fcblk ptr returned by sysio.
*      variable access trace association
*           the value field of the variable points to a trblk
*           instead of containing the data value. in the case
*           of a natural variable, the vrget and vrsto fields
*           contain =b_vra and =b_vrv to activate the check.
*           trtyp is set to trtac
*           trnxt points to next trblk or trval has variable val
*           trtag is the trace tag (0 if none)
*           trfnc is the trace function vrblk ptr (0 if none)
*      variable value trace association
*           the value field of the variable points to a trblk
*           instead of containing the data value. in the case
*           of a natural variable, the vrget and vrsto fields
*           contain =b_vra and =b_vrv to activate the check.
*           trtyp is set to trtvl
*           trnxt points to next trblk or trval has variable val
*           trtag is the trace tag (0 if none)
*           trfnc is the trace function vrblk ptr (0 if none)
{{ejc{{{{{4164
*      trap block (continued)
*      variable output association
*           the value field of the variable points to a trblk
*           instead of containing the data value. in the case
*           of a natural variable, the vrget and vrsto fields
*           contain =b_vra and =b_vrv to activate the check.
*           trtyp is set to trtou
*           trnxt points to next trblk or trval has variable val
*           trter is a pointer to svblk if association is
*           for output, terminal, else it is null.
*           trtrf points to the trap block which in turn points
*           to an fcblk used for i/o association.
*           trfpt is the fcblk ptr returned by sysio.
*      function call trace
*           the pfctr field of the corresponding pfblk is set
*           to point to a trblk.
*           trtyp is set to trtin
*           trnxt is zero
*           trtag is the trace tag (0 if none)
*           trfnc is the trace function vrblk ptr (0 if none)
*      function return trace
*           the pfrtr field of the corresponding pfblk is set
*           to point to a trblk
*           trtyp is set to trtin
*           trnxt is zero
*           trtag is the trace tag (0 if none)
*           trfnc is the trace function vrblk ptr (0 if none)
*      label trace
*           the vrlbl of the vrblk for the label is
*           changed to point to a trblk and the vrtra field is
*           set to b_vrt to activate the check.
*           trtyp is set to trtin
*           trlbl points to the actual label (cdblk) value
*           trtag is the trace tag (0 if none)
*           trfnc is the trace function vrblk ptr (0 if none)
{{ejc{{{{{4212
*      trap block (continued)
*      keyword trace
*           keywords which can be traced possess a unique
*           location which is zero if there is no trace and
*           points to a trblk if there is a trace. the locations
*           are as follows.
*           r_ert            errtype
*           r_fnc            fnclevel
*           r_stc            stcount
*           the format of the trblk is as follows.
*           trtyp is set to trtin
*           trkvr is a pointer to the vrblk for the keyword
*           trtag is the trace tag (0 if none)
*           trfnc is the trace function vrblk ptr (0 if none)
*      input/output file arg1 trap block
*           the value field of the variable points to a trblk
*           instead of containing the data value. in the case of
*           a natural variable, the vrget and vrsto fields
*           contain =b_vra and =b_vrv. this trap block is used
*           to hold a pointer to the fcblk which an
*           implementation may request to hold information
*           about a file.
*           trtyp is set to trtfc
*           trnext points to next trblk or trval is variable val
*           trfnm is 0
*           trfpt is the fcblk pointer.
*      note that when multiple traps are set on a variable
*      the order is in ascending value of trtyp field.
*      input association (if present)
*      access trace (if present)
*      value trace (if present)
*      output association (if present)
*      the actual value of the variable is stored in the trval
*      field of the last trblk on the chain.
*      this implementation does not permit trace or i/o
*      associations to any of the pseudo-variables.
{{ejc{{{{{4262
*      vector block (vcblk)
*      a vcblk is used to represent an array value which has
*      one dimension whose lower bound is one. all other arrays
*      are represented by arblks. a vcblk is created by the
*      system function array (s_arr) when passed an integer arg.
*           +------------------------------------+
*           i                vctyp               i
*           +------------------------------------+
*           i                idval               i
*           +------------------------------------+
*           i                vclen               i
*           +------------------------------------+
*           i                vcvls               i
*           +------------------------------------+
{vctyp{equ{24,0{{{pointer to dummy routine b_vct{4281
{vclen{equ{24,offs2{{{length of vcblk in bytes{4282
{vcvls{equ{24,offs3{{{start of vector values{4283
{vcsi_{equ{24,vcvls{{{size of standard fields in vcblk{4284
{vcvlb{equ{24,vcvls-1{{{offset one word behind vcvls{4285
{vctbd{equ{24,tbsi_-vcsi_{{{difference in sizes - see prtvl{4286
*      vcvls are either data pointers or trblk pointers
*      the dimension can be deduced from vclen.
{{ejc{{{{{4291
*      variable block (vrblk)
*      a variable block is built in the static memory area
*      for every variable referenced or created by a program.
*      the order of fields is assumed in the model vrblk stnvr.
*      note that since these blocks only occur in the static
*      region, it is permissible to point to any word in
*      the block and this is used to provide three distinct
*      access points from the generated code as follows.
*      1)   point to vrget (first word of vrblk) to load the
*           value of the variable onto the main stack.
*      2)   point to vrsto (second word of vrblk) to store the
*           top stack element as the value of the variable.
*      3)   point to vrtra (fourth word of vrblk) to jump to
*           the label associated with the variable name.
*           +------------------------------------+
*           i                vrget               i
*           +------------------------------------+
*           i                vrsto               i
*           +------------------------------------+
*           i                vrval               i
*           +------------------------------------+
*           i                vrtra               i
*           +------------------------------------+
*           i                vrlbl               i
*           +------------------------------------+
*           i                vrfnc               i
*           +------------------------------------+
*           i                vrnxt               i
*           +------------------------------------+
*           i                vrlen               i
*           +------------------------------------+
*           /                                    /
*           /            vrchs = vrsvp           /
*           /                                    /
*           +------------------------------------+
{{ejc{{{{{4334
*      variable block (continued)
{vrget{equ{24,0{{{pointer to routine to load value{4338
{vrsto{equ{24,vrget+1{{{pointer to routine to store value{4339
{vrval{equ{24,vrsto+1{{{variable value{4340
{vrvlo{equ{24,vrval-vrsto{{{offset to value from store field{4341
{vrtra{equ{24,vrval+1{{{pointer to routine to jump to label{4342
{vrlbl{equ{24,vrtra+1{{{pointer to code for label{4343
{vrlbo{equ{24,vrlbl-vrtra{{{offset to label from transfer field{4344
{vrfnc{equ{24,vrlbl+1{{{pointer to function block{4345
{vrnxt{equ{24,vrfnc+1{{{pointer to next vrblk on hash chain{4346
{vrlen{equ{24,vrnxt+1{{{length of name (or zero){4347
{vrchs{equ{24,vrlen+1{{{characters of name (vrlen gt 0){4348
{vrsvp{equ{24,vrlen+1{{{ptr to svblk (vrlen eq 0){4349
{vrsi_{equ{24,vrchs+1{{{number of standard fields in vrblk{4350
{vrsof{equ{24,vrlen-sclen{{{offset to dummy scblk for name{4351
{vrsvo{equ{24,vrsvp-vrsof{{{pseudo-offset to vrsvp field{4352
*      vrget = b_vrl if not input associated or access traced
*      vrget = b_vra if input associated or access traced
*      vrsto = b_vrs if not output associated or value traced
*      vrsto = b_vrv if output associated or value traced
*      vrsto = b_vre if value is protected pattern value
*      vrval points to the appropriate value unless the
*      variable is i/o/trace associated in which case, vrval
*      points to an appropriate trblk (trap block) chain.
*      vrtra = b_vrg if the label is not traced
*      vrtra = b_vrt if the label is traced
*      vrlbl points to a cdblk if there is a label
*      vrlbl points to the svblk svlbl field for a system label
*      vrlbl points to stndl for an undefined label
*      vrlbl points to a trblk if the label is traced
*      vrfnc points to a ffblk for a field function
*      vrfnc points to a dfblk for a datatype function
*      vrfnc points to a pfblk for a program defined function
*      vrfnc points to a efblk for an external loaded function
*      vrfnc points to svfnc (svblk) for a system function
*      vrfnc points to stndf if the function is undefined
*      vrnxt points to the next vrblk on this chain unless
*      this is the end of the chain in which case it is zero.
*      vrlen is the name length for a non-system variable.
*      vrlen is zero for a system variable.
*      vrchs is the name (ljrz) if vrlen is non-zero.
*      vrsvp is a ptr to the svblk if vrlen is zero.
{{ejc{{{{{4388
*      format of a non-relocatable external block (xnblk)
*      an xnblk is a block representing an unknown (external)
*      data value. the block contains no pointers to other
*      relocatable blocks. an xnblk is used by external function
*      processing or possibly for system i/o routines etc.
*      the macro-system itself does not use xnblks.
*      this type of block may be used as a file control block.
*      see sysfc,sysin,sysou,s_inp,s_oup for details.
*           +------------------------------------+
*           i                xntyp               i
*           +------------------------------------+
*           i                xnlen               i
*           +------------------------------------+
*           /                                    /
*           /                xndta               /
*           /                                    /
*           +------------------------------------+
{xntyp{equ{24,0{{{pointer to dummy routine b_xnt{4410
{xnlen{equ{24,xntyp+1{{{length of xnblk in bytes{4411
{xndta{equ{24,xnlen+1{{{data words{4412
{xnsi_{equ{24,xndta{{{size of standard fields in xnblk{4413
*      note that the term non-relocatable refers to the contents
*      and not the block itself. an xnblk can be moved around if
*      it is built in the dynamic memory area.
{{ejc{{{{{4418
*      relocatable external block (xrblk)
*      an xrblk is a block representing an unknown (external)
*      data value. the data area in this block consists only
*      of address values and any addresses pointing into the
*      dynamic memory area must point to the start of other
*      data blocks. see also description of xnblk.
*      this type of block may be used as a file control block.
*      see sysfc,sysin,sysou,s_inp,s_oup for details.
*           +------------------------------------+
*           i                xrtyp               i
*           +------------------------------------+
*           i                xrlen               i
*           +------------------------------------+
*           /                                    /
*           /                xrptr               /
*           /                                    /
*           +------------------------------------+
{xrtyp{equ{24,0{{{pointer to dummy routine b_xrt{4440
{xrlen{equ{24,xrtyp+1{{{length of xrblk in bytes{4441
{xrptr{equ{24,xrlen+1{{{start of address pointers{4442
{xrsi_{equ{24,xrptr{{{size of standard fields in xrblk{4443
{{ejc{{{{{4444
*      s_cnv (convert) function switch constants.  the values
*      are tied to the order of the entries in the svctb table
*      and hence to the branch table in s_cnv.
{cnvst{equ{24,8{{{max standard type code for convert{4450
{cnvrt{equ{24,cnvst+1{{{convert code for reals{4454
{cnvbt{equ{24,cnvrt{{{no buffers - same as real code{4457
{cnvtt{equ{24,cnvbt+1{{{bsw code for convert{4461
*      input image length
{iniln{equ{24,1024{{{default image length for compiler{4465
{inils{equ{24,1024{{{image length if -sequ in effect{4466
{ionmb{equ{24,2{{{name base used for iochn in sysio{4468
{ionmo{equ{24,4{{{name offset used for iochn in sysio{4469
*      minimum value for keyword maxlngth
*      should be larger than iniln
{mnlen{equ{24,1024{{{min value allowed keyword maxlngth{4474
{mxern{equ{24,329{{{err num inadequate startup memory{4475
*      in general, meaningful mnemonics should be used for
*      offsets. however for small integers used often in
*      literals the following general definitions are provided.
{num01{equ{24,1{{{{4481
{num02{equ{24,2{{{{4482
{num03{equ{24,3{{{{4483
{num04{equ{24,4{{{{4484
{num05{equ{24,5{{{{4485
{num06{equ{24,6{{{{4486
{num07{equ{24,7{{{{4487
{num08{equ{24,8{{{{4488
{num09{equ{24,9{{{{4489
{num10{equ{24,10{{{{4490
{num25{equ{24,25{{{{4491
{nm320{equ{24,320{{{{4492
{nm321{equ{24,321{{{{4493
{nini8{equ{24,998{{{{4494
{nini9{equ{24,999{{{{4495
{thsnd{equ{24,1000{{{{4496
{{ejc{{{{{4497
*      numbers of undefined spitbol operators
{opbun{equ{24,5{{{no. of binary undefined ops{4501
{opuun{equ{24,6{{{no of unary undefined ops{4502
*      offsets used in prtsn, prtmi and acess
{prsnf{equ{24,13{{{offset used in prtsn{4506
{prtmf{equ{24,21{{{offset to col 21 (prtmi){4507
{rilen{equ{24,1024{{{buffer length for sysri{4508
*      codes for stages of processing
{stgic{equ{24,0{{{initial compile{4512
{stgxc{equ{24,stgic+1{{{execution compile (code){4513
{stgev{equ{24,stgxc+1{{{expression eval during execution{4514
{stgxt{equ{24,stgev+1{{{execution time{4515
{stgce{equ{24,stgxt+1{{{initial compile after end line{4516
{stgxe{equ{24,stgce+1{{{exec. compile after end line{4517
{stgnd{equ{24,stgce-stgic{{{difference in stage after end{4518
{stgee{equ{24,stgxe+1{{{eval evaluating expression{4519
{stgno{equ{24,stgee+1{{{number of codes{4520
{{ejc{{{{{4521
*      statement number pad count for listr
{stnpd{equ{24,8{{{statement no. pad count{4526
*      syntax type codes
*      these codes are returned from the scane procedure.
*      they are spaced 3 apart for the benefit of expan.
{t_uop{equ{24,0{{{unary operator{4534
{t_lpr{equ{24,t_uop+3{{{left paren{4535
{t_lbr{equ{24,t_lpr+3{{{left bracket{4536
{t_cma{equ{24,t_lbr+3{{{comma{4537
{t_fnc{equ{24,t_cma+3{{{function call{4538
{t_var{equ{24,t_fnc+3{{{variable{4539
{t_con{equ{24,t_var+3{{{constant{4540
{t_bop{equ{24,t_con+3{{{binary operator{4541
{t_rpr{equ{24,t_bop+3{{{right paren{4542
{t_rbr{equ{24,t_rpr+3{{{right bracket{4543
{t_col{equ{24,t_rbr+3{{{colon{4544
{t_smc{equ{24,t_col+3{{{semi-colon{4545
*      the following definitions are used only in the goto field
{t_fgo{equ{24,t_smc+1{{{failure goto{4549
{t_sgo{equ{24,t_fgo+1{{{success goto{4550
*      the above codes are grouped so that codes for elements
*      which can legitimately immediately precede a unary
*      operator come first to facilitate operator syntax check.
{t_uok{equ{24,t_fnc{{{last code ok before unary operator{4556
{{ejc{{{{{4557
*      definitions of values for expan jump table
{t_uo0{equ{24,t_uop+0{{{unary operator, state zero{4561
{t_uo1{equ{24,t_uop+1{{{unary operator, state one{4562
{t_uo2{equ{24,t_uop+2{{{unary operator, state two{4563
{t_lp0{equ{24,t_lpr+0{{{left paren, state zero{4564
{t_lp1{equ{24,t_lpr+1{{{left paren, state one{4565
{t_lp2{equ{24,t_lpr+2{{{left paren, state two{4566
{t_lb0{equ{24,t_lbr+0{{{left bracket, state zero{4567
{t_lb1{equ{24,t_lbr+1{{{left bracket, state one{4568
{t_lb2{equ{24,t_lbr+2{{{left bracket, state two{4569
{t_cm0{equ{24,t_cma+0{{{comma, state zero{4570
{t_cm1{equ{24,t_cma+1{{{comma, state one{4571
{t_cm2{equ{24,t_cma+2{{{comma, state two{4572
{t_fn0{equ{24,t_fnc+0{{{function call, state zero{4573
{t_fn1{equ{24,t_fnc+1{{{function call, state one{4574
{t_fn2{equ{24,t_fnc+2{{{function call, state two{4575
{t_va0{equ{24,t_var+0{{{variable, state zero{4576
{t_va1{equ{24,t_var+1{{{variable, state one{4577
{t_va2{equ{24,t_var+2{{{variable, state two{4578
{t_co0{equ{24,t_con+0{{{constant, state zero{4579
{t_co1{equ{24,t_con+1{{{constant, state one{4580
{t_co2{equ{24,t_con+2{{{constant, state two{4581
{t_bo0{equ{24,t_bop+0{{{binary operator, state zero{4582
{t_bo1{equ{24,t_bop+1{{{binary operator, state one{4583
{t_bo2{equ{24,t_bop+2{{{binary operator, state two{4584
{t_rp0{equ{24,t_rpr+0{{{right paren, state zero{4585
{t_rp1{equ{24,t_rpr+1{{{right paren, state one{4586
{t_rp2{equ{24,t_rpr+2{{{right paren, state two{4587
{t_rb0{equ{24,t_rbr+0{{{right bracket, state zero{4588
{t_rb1{equ{24,t_rbr+1{{{right bracket, state one{4589
{t_rb2{equ{24,t_rbr+2{{{right bracket, state two{4590
{t_cl0{equ{24,t_col+0{{{colon, state zero{4591
{t_cl1{equ{24,t_col+1{{{colon, state one{4592
{t_cl2{equ{24,t_col+2{{{colon, state two{4593
{t_sm0{equ{24,t_smc+0{{{semicolon, state zero{4594
{t_sm1{equ{24,t_smc+1{{{semicolon, state one{4595
{t_sm2{equ{24,t_smc+2{{{semicolon, state two{4596
{t_nes{equ{24,t_sm2+1{{{number of entries in branch table{4598
{{ejc{{{{{4599
*       definition of offsets used in control card processing
{cc_do{equ{24,0{{{-double{4607
{cc_co{equ{24,cc_do+1{{{-compare{4610
{cc_du{equ{24,cc_co+1{{{-dump{4611
{cc_cp{equ{24,cc_du+1{{{-copy{4616
{cc_ej{equ{24,cc_cp+1{{{-eject{4617
{cc_er{equ{24,cc_ej+1{{{-errors{4621
{cc_ex{equ{24,cc_er+1{{{-execute{4622
{cc_fa{equ{24,cc_ex+1{{{-fail{4623
{cc_in{equ{24,cc_fa+1{{{-include{4625
{cc_ln{equ{24,cc_in+1{{{-line{4627
{cc_li{equ{24,cc_ln+1{{{-list{4628
{cc_nr{equ{24,cc_li+1{{{-noerrors{4640
{cc_nx{equ{24,cc_nr+1{{{-noexecute{4641
{cc_nf{equ{24,cc_nx+1{{{-nofail{4642
{cc_nl{equ{24,cc_nf+1{{{-nolist{4643
{cc_no{equ{24,cc_nl+1{{{-noopt{4644
{cc_np{equ{24,cc_no+1{{{-noprint{4645
{cc_op{equ{24,cc_np+1{{{-optimise{4646
{cc_pr{equ{24,cc_op+1{{{-print{4647
{cc_si{equ{24,cc_pr+1{{{-single{4648
{cc_sp{equ{24,cc_si+1{{{-space{4649
{cc_st{equ{24,cc_sp+1{{{-stitl{4650
{cc_ti{equ{24,cc_st+1{{{-title{4651
{cc_tr{equ{24,cc_ti+1{{{-trace{4652
{cc_nc{equ{24,cc_tr+1{{{number of control cards{4653
{ccnoc{equ{24,4{{{no. of chars included in match{4654
{ccofs{equ{24,7{{{offset to start of title/subtitle{4655
{ccinm{equ{24,9{{{max depth of include file nesting{4657
{{ejc{{{{{4659
*      definitions of stack offsets used in cmpil procedure
*      see description at start of cmpil procedure for details
*      of use of these locations on the stack.
{cmstm{equ{24,0{{{tree for statement body{4666
{cmsgo{equ{24,cmstm+1{{{tree for success goto{4667
{cmfgo{equ{24,cmsgo+1{{{tree for fail goto{4668
{cmcgo{equ{24,cmfgo+1{{{conditional goto flag{4669
{cmpcd{equ{24,cmcgo+1{{{previous cdblk pointer{4670
{cmffp{equ{24,cmpcd+1{{{failure fill in flag for previous{4671
{cmffc{equ{24,cmffp+1{{{failure fill in flag for current{4672
{cmsop{equ{24,cmffc+1{{{success fill in offset for previous{4673
{cmsoc{equ{24,cmsop+1{{{success fill in offset for current{4674
{cmlbl{equ{24,cmsoc+1{{{ptr to vrblk for current label{4675
{cmtra{equ{24,cmlbl+1{{{ptr to entry cdblk{4676
{cmnen{equ{24,cmtra+1{{{count of stack entries for cmpil{4678
*      a few constants used by the profiler
{pfpd1{equ{24,8{{{pad positions ...{4683
{pfpd2{equ{24,20{{{... for profile ...{4684
{pfpd3{equ{24,32{{{... printout{4685
{pf_i2{equ{24,cfp_i+cfp_i{{{size of table entry (2 ints){4686
{{ejc{{{{{4689
*      definition of limits and adjustments that are built by
*      relcr for use by the routines that relocate pointers
*      after a save file is reloaded.  see reloc etc. for usage.
*      a block of information is built that is used in
*      relocating pointers.  there are rnsi_ instances
*      of a rssi_ word structure.  each instance corresponds
*      to one of the regions that a pointer might point into.
*      each structure takes the form:
*           +------------------------------------+
*           i    address past end of section     i
*           +------------------------------------+
*           i  adjustment from old to new adrs   i
*           +------------------------------------+
*           i    address of start of section     i
*           +------------------------------------+
*      the instances are ordered thusly:
*           +------------------------------------+
*           i           dynamic storage          i
*           +------------------------------------+
*           i           static storage           i
*           +------------------------------------+
*           i       working section globals      i
*           +------------------------------------+
*           i          constant section          i
*           +------------------------------------+
*           i            code section            i
*           +------------------------------------+
*      symbolic names for these locations as offsets from
*      the first entry are provided here.
*      definitions within a section
{rlend{equ{24,0{{{end{4729
{rladj{equ{24,rlend+1{{{adjustment{4730
{rlstr{equ{24,rladj+1{{{start{4731
{rssi_{equ{24,rlstr+1{{{size of section{4732
{rnsi_{equ{24,5{{{number of structures{4733
*      overall definitions of all structures
{rldye{equ{24,0{{{dynamic region end{4737
{rldya{equ{24,rldye+1{{{dynamic region adjustment{4738
{rldys{equ{24,rldya+1{{{dynamic region start{4739
{rlste{equ{24,rldys+1{{{static region end{4740
{rlsta{equ{24,rlste+1{{{static region adjustment{4741
{rlsts{equ{24,rlsta+1{{{static region start{4742
{rlwke{equ{24,rlsts+1{{{working section globals end{4743
{rlwka{equ{24,rlwke+1{{{working section globals adjustment{4744
{rlwks{equ{24,rlwka+1{{{working section globals start{4745
{rlcne{equ{24,rlwks+1{{{constants section end{4746
{rlcna{equ{24,rlcne+1{{{constants section adjustment{4747
{rlcns{equ{24,rlcna+1{{{constants section start{4748
{rlcde{equ{24,rlcns+1{{{code section end{4749
{rlcda{equ{24,rlcde+1{{{code section adjustment{4750
{rlcds{equ{24,rlcda+1{{{code section start{4751
{rlsi_{equ{24,rlcds+1{{{number of fields in structure{4752
{{ttl{27,s p i t b o l -- constant section{{{{4755
*      this section consists entirely of assembled constants.
*      all label names are five letters. the order is
*      approximately alphabetical, but in some cases (always
*      documented), constants must be placed in some special
*      order which must not be disturbed.
*      it must also be remembered that there is a requirement
*      for no forward references which also disturbs the
*      alphabetical order in some cases.
{{sec{{{{start of constant section{4768
*      start of constant section
{c_aaa{dac{1,0{{{first location of constant section{4772
*      free store percentage (used by alloc)
{alfsp{dac{2,e_fsp{{{free store percentage{4776
*      bit constants for general use
{bits0{dbc{1,0{{{all zero bits{4780
{bits1{dbc{1,1{{{one bit in low order position{4781
{bits2{dbc{1,2{{{bit in position 2{4782
{bits3{dbc{1,4{{{bit in position 3{4783
{bits4{dbc{1,8{{{bit in position 4{4784
{bits5{dbc{1,16{{{bit in position 5{4785
{bits6{dbc{1,32{{{bit in position 6{4786
{bits7{dbc{1,64{{{bit in position 7{4787
{bits8{dbc{1,128{{{bit in position 8{4788
{bits9{dbc{1,256{{{bit in position 9{4789
{bit10{dbc{1,512{{{bit in position 10{4790
{bit11{dbc{1,1024{{{bit in position 11{4791
{bit12{dbc{1,2048{{{bit in position 12{4792
*bitsm  dbc  cfp_m            mask for max integer
{bitsm{dbc{1,0{{{mask for max integer (value filled in at runtime){4794
*      bit constants for svblk (svbit field) tests
{btfnc{dbc{2,svfnc{{{bit to test for function{4798
{btknm{dbc{2,svknm{{{bit to test for keyword number{4799
{btlbl{dbc{2,svlbl{{{bit to test for label{4800
{btffc{dbc{2,svffc{{{bit to test for fast call{4801
{btckw{dbc{2,svckw{{{bit to test for constant keyword{4802
{btkwv{dbc{2,svkwv{{{bits to test for keword with value{4803
{btprd{dbc{2,svprd{{{bit to test for predicate function{4804
{btpre{dbc{2,svpre{{{bit to test for preevaluation{4805
{btval{dbc{2,svval{{{bit to test for value{4806
{{ejc{{{{{4807
*      list of names used for control card processing
{ccnms{dtc{27,/doub/{{{{4815
{{dtc{27,/comp/{{{{4818
{{dtc{27,/dump/{{{{4820
{{dtc{27,/copy/{{{{4822
{{dtc{27,/ejec/{{{{4824
{{dtc{27,/erro/{{{{4825
{{dtc{27,/exec/{{{{4826
{{dtc{27,/fail/{{{{4827
{{dtc{27,/incl/{{{{4829
{{dtc{27,/line/{{{{4832
{{dtc{27,/list/{{{{4834
{{dtc{27,/noer/{{{{4835
{{dtc{27,/noex/{{{{4836
{{dtc{27,/nofa/{{{{4837
{{dtc{27,/noli/{{{{4838
{{dtc{27,/noop/{{{{4839
{{dtc{27,/nopr/{{{{4840
{{dtc{27,/opti/{{{{4841
{{dtc{27,/prin/{{{{4842
{{dtc{27,/sing/{{{{4843
{{dtc{27,/spac/{{{{4844
{{dtc{27,/stit/{{{{4845
{{dtc{27,/titl/{{{{4846
{{dtc{27,/trac/{{{{4847
*      header messages for dumpr procedure (scblk format)
{dmhdk{dac{6,b_scl{{{dump of keyword values{4851
{{dac{1,22{{{{4852
{{dtc{27,/dump of keyword values/{{{{4853
{dmhdv{dac{6,b_scl{{{dump of natural variables{4855
{{dac{1,25{{{{4856
{{dtc{27,/dump of natural variables/{{{{4857
{{ejc{{{{{4858
*      message text for compilation statistics
{encm1{dac{6,b_scl{{{{4862
{{dac{1,19{{{{4864
{{dtc{27,/memory used (bytes)/{{{{4865
{encm2{dac{6,b_scl{{{{4867
{{dac{1,19{{{{4868
{{dtc{27,/memory left (bytes)/{{{{4869
{encm3{dac{6,b_scl{{{{4879
{{dac{1,11{{{{4880
{{dtc{27,/comp errors/{{{{4881
{encm4{dac{6,b_scl{{{{4883
{{dac{1,20{{{{4888
{{dtc{27,/comp time (microsec)/{{{{4889
{encm5{dac{6,b_scl{{{execution suppressed{4892
{{dac{1,20{{{{4893
{{dtc{27,/execution suppressed/{{{{4894
*      string constant for abnormal end
{endab{dac{6,b_scl{{{{4898
{{dac{1,12{{{{4899
{{dtc{27,/abnormal end/{{{{4900
{{ejc{{{{{4901
*      memory overflow during initialisation
{endmo{dac{6,b_scl{{{{4905
{endml{dac{1,15{{{{4906
{{dtc{27,/memory overflow/{{{{4907
*      string constant for message issued by l_end
{endms{dac{6,b_scl{{{{4911
{{dac{1,10{{{{4912
{{dtc{27,/normal end/{{{{4913
*      fail message for stack fail section
{endso{dac{6,b_scl{{{stack overflow in garbage collector{4917
{{dac{1,36{{{{4918
{{dtc{27,/stack overflow in garbage collection/{{{{4919
*      string constant for time up
{endtu{dac{6,b_scl{{{{4923
{{dac{1,15{{{{4924
{{dtc{27,/error - time up/{{{{4925
{{ejc{{{{{4926
*      string constant for error message (error section)
{ermms{dac{6,b_scl{{{error{4930
{{dac{1,5{{{{4931
{{dtc{27,/error/{{{{4932
{ermns{dac{6,b_scl{{{string / -- /{4934
{{dac{1,4{{{{4935
{{dtc{27,/ -- /{{{{4936
*      string constant for page numbering
{lstms{dac{6,b_scl{{{page{4940
{{dac{1,5{{{{4941
{{dtc{27,/page /{{{{4942
*      listing header message
{headr{dac{6,b_scl{{{{4946
{{dac{1,25{{{{4947
{{dtc{27,/macro spitbol version 4.0/{{{{4948
{headv{dac{6,b_scl{{{for exit() version no. check{4950
{{dac{1,5{{{{4951
{{dtc{27,/15.01/{{{{4952
*      free store percentage (used by gbcol)
{gbsdp{dac{2,e_sed{{{sediment percentage{4956
*      integer constants for general use
*      icbld optimisation uses the first three.
{int_r{dac{6,b_icl{{{{4962
{intv0{dic{16,+0{{{0{4963
{inton{dac{6,b_icl{{{{4964
{intv1{dic{16,+1{{{1{4965
{inttw{dac{6,b_icl{{{{4966
{intv2{dic{16,+2{{{2{4967
{intvt{dic{16,+10{{{10{4968
{intvh{dic{16,+100{{{100{4969
{intth{dic{16,+1000{{{1000{4970
*      table used in icbld optimisation
{intab{dac{4,int_r{{{pointer to 0{4974
{{dac{4,inton{{{pointer to 1{4975
{{dac{4,inttw{{{pointer to 2{4976
{{ejc{{{{{4977
*      special pattern nodes. the following pattern nodes
*      consist simply of a pcode pointer, see match routines
*      (p_xxx) for full details of their use and format).
{ndabb{dac{6,p_abb{{{arbno{4983
{ndabd{dac{6,p_abd{{{arbno{4984
{ndarc{dac{6,p_arc{{{arb{4985
{ndexb{dac{6,p_exb{{{expression{4986
{ndfnb{dac{6,p_fnb{{{fence(){4987
{ndfnd{dac{6,p_fnd{{{fence(){4988
{ndexc{dac{6,p_exc{{{expression{4989
{ndimb{dac{6,p_imb{{{immediate assignment{4990
{ndimd{dac{6,p_imd{{{immediate assignment{4991
{ndnth{dac{6,p_nth{{{pattern end (null pattern){4992
{ndpab{dac{6,p_pab{{{pattern assignment{4993
{ndpad{dac{6,p_pad{{{pattern assignment{4994
{nduna{dac{6,p_una{{{anchor point movement{4995
*      keyword constant pattern nodes. the following nodes are
*      used as the values of pattern keywords and the initial
*      values of the corresponding natural variables. all
*      nodes are in p0blk format and the order is tied to the
*      definitions of corresponding k_xxx symbols.
{ndabo{dac{6,p_abo{{{abort{5003
{{dac{4,ndnth{{{{5004
{ndarb{dac{6,p_arb{{{arb{5005
{{dac{4,ndnth{{{{5006
{ndbal{dac{6,p_bal{{{bal{5007
{{dac{4,ndnth{{{{5008
{ndfal{dac{6,p_fal{{{fail{5009
{{dac{4,ndnth{{{{5010
{ndfen{dac{6,p_fen{{{fence{5011
{{dac{4,ndnth{{{{5012
{ndrem{dac{6,p_rem{{{rem{5013
{{dac{4,ndnth{{{{5014
{ndsuc{dac{6,p_suc{{{succeed{5015
{{dac{4,ndnth{{{{5016
*      null string. all null values point to this string. the
*      svchs field contains a blank to provide for easy default
*      processing in trace, stoptr, lpad and rpad.
*      nullw contains 10 blanks which ensures an all blank word
*      but for very exceptional machines.
{nulls{dac{6,b_scl{{{null string value{5024
{{dac{1,0{{{sclen = 0{5025
{nullw{dtc{27,/          /{{{{5026
*      constant strings for lcase and ucase keywords
{lcase{dac{6,b_scl{{{{5032
{{dac{1,26{{{{5033
{{dtc{27,/abcdefghijklmnopqrstuvwxyz/{{{{5034
{ucase{dac{6,b_scl{{{{5036
{{dac{1,26{{{{5037
{{dtc{27,/ABCDEFGHIJKLMNOPQRSTUVWXYZ/{{{{5038
{{ejc{{{{{5040
*      operator dope vectors (see dvblk format)
{opdvc{dac{6,o_cnc{{{concatenation{5044
{{dac{2,c_cnc{{{{5045
{{dac{2,llcnc{{{{5046
{{dac{2,rrcnc{{{{5047
*      opdvs is used when scanning below the top level to
*      insure that the concatenation will not be later
*      mistaken for pattern matching
{opdvp{dac{6,o_cnc{{{concatenation - not pattern match{5053
{{dac{2,c_cnp{{{{5054
{{dac{2,llcnc{{{{5055
{{dac{2,rrcnc{{{{5056
*      note that the order of the remaining entries is tied to
*      the order of the coding in the scane procedure.
{opdvs{dac{6,o_ass{{{assignment{5061
{{dac{2,c_ass{{{{5062
{{dac{2,llass{{{{5063
{{dac{2,rrass{{{{5064
{{dac{1,6{{{unary equal{5066
{{dac{2,c_uuo{{{{5067
{{dac{2,lluno{{{{5068
{{dac{6,o_pmv{{{pattern match{5070
{{dac{2,c_pmt{{{{5071
{{dac{2,llpmt{{{{5072
{{dac{2,rrpmt{{{{5073
{{dac{6,o_int{{{interrogation{5075
{{dac{2,c_uvl{{{{5076
{{dac{2,lluno{{{{5077
{{dac{1,1{{{binary ampersand{5079
{{dac{2,c_ubo{{{{5080
{{dac{2,llamp{{{{5081
{{dac{2,rramp{{{{5082
{{dac{6,o_kwv{{{keyword reference{5084
{{dac{2,c_key{{{{5085
{{dac{2,lluno{{{{5086
{{dac{6,o_alt{{{alternation{5088
{{dac{2,c_alt{{{{5089
{{dac{2,llalt{{{{5090
{{dac{2,rralt{{{{5091
{{ejc{{{{{5092
*      operator dope vectors (continued)
{{dac{1,5{{{unary vertical bar{5096
{{dac{2,c_uuo{{{{5097
{{dac{2,lluno{{{{5098
{{dac{1,0{{{binary at{5100
{{dac{2,c_ubo{{{{5101
{{dac{2,llats{{{{5102
{{dac{2,rrats{{{{5103
{{dac{6,o_cas{{{cursor assignment{5105
{{dac{2,c_unm{{{{5106
{{dac{2,lluno{{{{5107
{{dac{1,2{{{binary number sign{5109
{{dac{2,c_ubo{{{{5110
{{dac{2,llnum{{{{5111
{{dac{2,rrnum{{{{5112
{{dac{1,7{{{unary number sign{5114
{{dac{2,c_uuo{{{{5115
{{dac{2,lluno{{{{5116
{{dac{6,o_dvd{{{division{5118
{{dac{2,c_bvl{{{{5119
{{dac{2,lldvd{{{{5120
{{dac{2,rrdvd{{{{5121
{{dac{1,9{{{unary slash{5123
{{dac{2,c_uuo{{{{5124
{{dac{2,lluno{{{{5125
{{dac{6,o_mlt{{{multiplication{5127
{{dac{2,c_bvl{{{{5128
{{dac{2,llmlt{{{{5129
{{dac{2,rrmlt{{{{5130
{{ejc{{{{{5131
*      operator dope vectors (continued)
{{dac{1,0{{{deferred expression{5135
{{dac{2,c_def{{{{5136
{{dac{2,lluno{{{{5137
{{dac{1,3{{{binary percent{5139
{{dac{2,c_ubo{{{{5140
{{dac{2,llpct{{{{5141
{{dac{2,rrpct{{{{5142
{{dac{1,8{{{unary percent{5144
{{dac{2,c_uuo{{{{5145
{{dac{2,lluno{{{{5146
{{dac{6,o_exp{{{exponentiation{5148
{{dac{2,c_bvl{{{{5149
{{dac{2,llexp{{{{5150
{{dac{2,rrexp{{{{5151
{{dac{1,10{{{unary exclamation{5153
{{dac{2,c_uuo{{{{5154
{{dac{2,lluno{{{{5155
{{dac{6,o_ima{{{immediate assignment{5157
{{dac{2,c_bvn{{{{5158
{{dac{2,lldld{{{{5159
{{dac{2,rrdld{{{{5160
{{dac{6,o_inv{{{indirection{5162
{{dac{2,c_ind{{{{5163
{{dac{2,lluno{{{{5164
{{dac{1,4{{{binary not{5166
{{dac{2,c_ubo{{{{5167
{{dac{2,llnot{{{{5168
{{dac{2,rrnot{{{{5169
{{dac{1,0{{{negation{5171
{{dac{2,c_neg{{{{5172
{{dac{2,lluno{{{{5173
{{ejc{{{{{5174
*      operator dope vectors (continued)
{{dac{6,o_sub{{{subtraction{5178
{{dac{2,c_bvl{{{{5179
{{dac{2,llplm{{{{5180
{{dac{2,rrplm{{{{5181
{{dac{6,o_com{{{complementation{5183
{{dac{2,c_uvl{{{{5184
{{dac{2,lluno{{{{5185
{{dac{6,o_add{{{addition{5187
{{dac{2,c_bvl{{{{5188
{{dac{2,llplm{{{{5189
{{dac{2,rrplm{{{{5190
{{dac{6,o_aff{{{affirmation{5192
{{dac{2,c_uvl{{{{5193
{{dac{2,lluno{{{{5194
{{dac{6,o_pas{{{pattern assignment{5196
{{dac{2,c_bvn{{{{5197
{{dac{2,lldld{{{{5198
{{dac{2,rrdld{{{{5199
{{dac{6,o_nam{{{name reference{5201
{{dac{2,c_unm{{{{5202
{{dac{2,lluno{{{{5203
*      special dvs for goto operators (see procedure scngf)
{opdvd{dac{6,o_god{{{direct goto{5207
{{dac{2,c_uvl{{{{5208
{{dac{2,lluno{{{{5209
{opdvn{dac{6,o_goc{{{complex normal goto{5211
{{dac{2,c_unm{{{{5212
{{dac{2,lluno{{{{5213
{{ejc{{{{{5214
*      operator entry address pointers, used in code
{oamn_{dac{6,o_amn{{{array ref (multi-subs by value){5218
{oamv_{dac{6,o_amv{{{array ref (multi-subs by value){5219
{oaon_{dac{6,o_aon{{{array ref (one sub by name){5220
{oaov_{dac{6,o_aov{{{array ref (one sub by value){5221
{ocer_{dac{6,o_cer{{{compilation error{5222
{ofex_{dac{6,o_fex{{{failure in expression evaluation{5223
{ofif_{dac{6,o_fif{{{failure during goto evaluation{5224
{ofnc_{dac{6,o_fnc{{{function call (more than one arg){5225
{ofne_{dac{6,o_fne{{{function name error{5226
{ofns_{dac{6,o_fns{{{function call (single argument){5227
{ogof_{dac{6,o_gof{{{set goto failure trap{5228
{oinn_{dac{6,o_inn{{{indirection by name{5229
{okwn_{dac{6,o_kwn{{{keyword reference by name{5230
{olex_{dac{6,o_lex{{{load expression by name{5231
{olpt_{dac{6,o_lpt{{{load pattern{5232
{olvn_{dac{6,o_lvn{{{load variable name{5233
{onta_{dac{6,o_nta{{{negation, first entry{5234
{ontb_{dac{6,o_ntb{{{negation, second entry{5235
{ontc_{dac{6,o_ntc{{{negation, third entry{5236
{opmn_{dac{6,o_pmn{{{pattern match by name{5237
{opms_{dac{6,o_pms{{{pattern match (statement){5238
{opop_{dac{6,o_pop{{{pop top stack item{5239
{ornm_{dac{6,o_rnm{{{return name from expression{5240
{orpl_{dac{6,o_rpl{{{pattern replacement{5241
{orvl_{dac{6,o_rvl{{{return value from expression{5242
{osla_{dac{6,o_sla{{{selection, first entry{5243
{oslb_{dac{6,o_slb{{{selection, second entry{5244
{oslc_{dac{6,o_slc{{{selection, third entry{5245
{osld_{dac{6,o_sld{{{selection, fourth entry{5246
{ostp_{dac{6,o_stp{{{stop execution{5247
{ounf_{dac{6,o_unf{{{unexpected failure{5248
{{ejc{{{{{5249
*      table of names of undefined binary operators for opsyn
{opsnb{dac{2,ch_at{{{at{5253
{{dac{2,ch_am{{{ampersand{5254
{{dac{2,ch_nm{{{number{5255
{{dac{2,ch_pc{{{percent{5256
{{dac{2,ch_nt{{{not{5257
*      table of names of undefined unary operators for opsyn
{opnsu{dac{2,ch_br{{{vertical bar{5261
{{dac{2,ch_eq{{{equal{5262
{{dac{2,ch_nm{{{number{5263
{{dac{2,ch_pc{{{percent{5264
{{dac{2,ch_sl{{{slash{5265
{{dac{2,ch_ex{{{exclamation{5266
*      address const containing profile table entry size
{pfi2a{dac{2,pf_i2{{{{5272
*      profiler message strings
{pfms1{dac{6,b_scl{{{{5276
{{dac{1,15{{{{5277
{{dtc{27,/program profile/{{{{5278
{pfms2{dac{6,b_scl{{{{5279
{{dac{1,42{{{{5280
{{dtc{27,/stmt    number of     -- execution time --/{{{{5281
{pfms3{dac{6,b_scl{{{{5282
{{dac{1,47{{{{5283
{{dtc{27,/number  executions  total(msec) per excn(mcsec)/{{{{5284
*      real constants for general use. note that the constants
*      starting at reav1 form a powers of ten table (used in
*      gtnum and gtstg)
{reav0{drc{17,+0.0{{{0.0{5294
{reap1{drc{17,+0.1{{{0.1{5297
{reap5{drc{17,+0.5{{{0.5{5298
{reav1{drc{17,+1.0{{{10**0{5300
{reavt{drc{17,+1.0e+1{{{10**1{5301
{{drc{17,+1.0e+2{{{10**2{5302
{{drc{17,+1.0e+3{{{10**3{5303
{{drc{17,+1.0e+4{{{10**4{5304
{{drc{17,+1.0e+5{{{10**5{5305
{{drc{17,+1.0e+6{{{10**6{5306
{{drc{17,+1.0e+7{{{10**7{5307
{{drc{17,+1.0e+8{{{10**8{5308
{{drc{17,+1.0e+9{{{10**9{5309
{reatt{drc{17,+1.0e+10{{{10**10{5310
{{ejc{{{{{5312
*      string constants (scblk format) for dtype procedure
{scarr{dac{6,b_scl{{{array{5316
{{dac{1,5{{{{5317
{{dtc{27,/array/{{{{5318
{sccod{dac{6,b_scl{{{code{5327
{{dac{1,4{{{{5328
{{dtc{27,/code/{{{{5329
{scexp{dac{6,b_scl{{{expression{5331
{{dac{1,10{{{{5332
{{dtc{27,/expression/{{{{5333
{scext{dac{6,b_scl{{{external{5335
{{dac{1,8{{{{5336
{{dtc{27,/external/{{{{5337
{scint{dac{6,b_scl{{{integer{5339
{{dac{1,7{{{{5340
{{dtc{27,/integer/{{{{5341
{scnam{dac{6,b_scl{{{name{5343
{{dac{1,4{{{{5344
{{dtc{27,/name/{{{{5345
{scnum{dac{6,b_scl{{{numeric{5347
{{dac{1,7{{{{5348
{{dtc{27,/numeric/{{{{5349
{scpat{dac{6,b_scl{{{pattern{5351
{{dac{1,7{{{{5352
{{dtc{27,/pattern/{{{{5353
{screa{dac{6,b_scl{{{real{5357
{{dac{1,4{{{{5358
{{dtc{27,/real/{{{{5359
{scstr{dac{6,b_scl{{{string{5362
{{dac{1,6{{{{5363
{{dtc{27,/string/{{{{5364
{sctab{dac{6,b_scl{{{table{5366
{{dac{1,5{{{{5367
{{dtc{27,/table/{{{{5368
{scfil{dac{6,b_scl{{{file (for extended load arguments){5370
{{dac{1,4{{{{5371
{{dtc{27,/file/{{{{5372
{{ejc{{{{{5374
*      string constants (scblk format) for kvrtn (see retrn)
{scfrt{dac{6,b_scl{{{freturn{5378
{{dac{1,7{{{{5379
{{dtc{27,/freturn/{{{{5380
{scnrt{dac{6,b_scl{{{nreturn{5382
{{dac{1,7{{{{5383
{{dtc{27,/nreturn/{{{{5384
{scrtn{dac{6,b_scl{{{return{5386
{{dac{1,6{{{{5387
{{dtc{27,/return/{{{{5388
*      datatype name table for dtype procedure. the order of
*      these entries is tied to the b_xxx definitions for blocks
*      note that slots for buffer and real data types are filled
*      even if these data types are conditionalized out of the
*      implementation.  this is done so that the block numbering
*      at bl_ar etc. remains constant in all versions.
{scnmt{dac{4,scarr{{{arblk     array{5398
{{dac{4,sccod{{{cdblk     code{5399
{{dac{4,scexp{{{exblk     expression{5400
{{dac{4,scint{{{icblk     integer{5401
{{dac{4,scnam{{{nmblk     name{5402
{{dac{4,scpat{{{p0blk     pattern{5403
{{dac{4,scpat{{{p1blk     pattern{5404
{{dac{4,scpat{{{p2blk     pattern{5405
{{dac{4,screa{{{rcblk     real{5410
{{dac{4,scstr{{{scblk     string{5412
{{dac{4,scexp{{{seblk     expression{5413
{{dac{4,sctab{{{tbblk     table{5414
{{dac{4,scarr{{{vcblk     array{5415
{{dac{4,scext{{{xnblk     external{5416
{{dac{4,scext{{{xrblk     external{5417
{{dac{4,nulls{{{bfblk     no buffer in this version{5419
*      string constant for real zero
{scre0{dac{6,b_scl{{{{5428
{{dac{1,2{{{{5429
{{dtc{27,/0./{{{{5430
{{ejc{{{{{5432
*      used to re-initialise kvstl
{stlim{dic{16,+2147483647{{{default statement limit{5440
*      dummy function block used for undefined functions
{stndf{dac{6,o_fun{{{ptr to undefined function err call{5448
{{dac{1,0{{{dummy fargs count for call circuit{5449
*      dummy code block used for undefined labels
{stndl{dac{6,l_und{{{code ptr points to undefined lbl{5453
*      dummy operator block used for undefined operators
{stndo{dac{6,o_oun{{{ptr to undefined operator err call{5457
{{dac{1,0{{{dummy fargs count for call circuit{5458
*      standard variable block. this block is used to initialize
*      the first seven fields of a newly constructed vrblk.
*      its format is tied to the vrblk definitions (see gtnvr).
{stnvr{dac{6,b_vrl{{{vrget{5464
{{dac{6,b_vrs{{{vrsto{5465
{{dac{4,nulls{{{vrval{5466
{{dac{6,b_vrg{{{vrtra{5467
{{dac{4,stndl{{{vrlbl{5468
{{dac{4,stndf{{{vrfnc{5469
{{dac{1,0{{{vrnxt{5470
{{ejc{{{{{5471
*      messages used in end of run processing (stopr)
{stpm1{dac{6,b_scl{{{in statement{5475
{{dac{1,12{{{{5476
{{dtc{27,/in statement/{{{{5477
{stpm2{dac{6,b_scl{{{{5479
{{dac{1,14{{{{5480
{{dtc{27,/stmts executed/{{{{5481
{stpm3{dac{6,b_scl{{{{5483
{{dac{1,20{{{{5484
{{dtc{27,/execution time msec /{{{{5485
{stpm4{dac{6,b_scl{{{in line{5488
{{dac{1,7{{{{5489
{{dtc{27,/in line/{{{{5490
{stpm5{dac{6,b_scl{{{{5493
{{dac{1,13{{{{5494
{{dtc{27,/regenerations/{{{{5495
{stpm6{dac{6,b_scl{{{in file{5498
{{dac{1,7{{{{5499
{{dtc{27,/in file/{{{{5500
{stpm7{dac{6,b_scl{{{{5503
{{dac{1,15{{{{5504
{{dtc{27,_stmt / microsec_{{{{5505
{stpm8{dac{6,b_scl{{{{5507
{{dac{1,15{{{{5508
{{dtc{27,_stmt / millisec_{{{{5509
{stpm9{dac{6,b_scl{{{{5511
{{dac{1,13{{{{5512
{{dtc{27,_stmt / second_{{{{5513
*      chars for /tu/ ending code
{strtu{dtc{27,/tu/{{{{5517
*      table used by convert function to check datatype name
*      the entries are ordered to correspond to branch table
*      in s_cnv
{svctb{dac{4,scstr{{{string{5523
{{dac{4,scint{{{integer{5524
{{dac{4,scnam{{{name{5525
{{dac{4,scpat{{{pattern{5526
{{dac{4,scarr{{{array{5527
{{dac{4,sctab{{{table{5528
{{dac{4,scexp{{{expression{5529
{{dac{4,sccod{{{code{5530
{{dac{4,scnum{{{numeric{5531
{{dac{4,screa{{{real{5534
{{dac{1,0{{{zero marks end of list{5540
{{ejc{{{{{5541
*      messages (scblk format) used by trace procedures
{tmasb{dac{6,b_scl{{{asterisks for trace statement no{5546
{{dac{1,13{{{{5547
{{dtc{27,/************ /{{{{5548
{tmbeb{dac{6,b_scl{{{blank-equal-blank{5551
{{dac{1,3{{{{5552
{{dtc{27,/ = /{{{{5553
*      dummy trblk for expression variable
{trbev{dac{6,b_trt{{{dummy trblk{5557
*      dummy trblk for keyword variable
{trbkv{dac{6,b_trt{{{dummy trblk{5561
*      dummy code block to return control to trxeq procedure
{trxdr{dac{6,o_txr{{{block points to return routine{5565
{trxdc{dac{4,trxdr{{{pointer to block{5566
{{ejc{{{{{5567
*      standard variable blocks
*      see svblk format for full details of the format. the
*      vrblks are ordered by length and within each length the
*      order is alphabetical by name of the variable.
{v_eqf{dbc{2,svfpr{{{eq{5575
{{dac{1,2{{{{5576
{{dtc{27,/eq/{{{{5577
{{dac{6,s_eqf{{{{5578
{{dac{1,2{{{{5579
{v_gef{dbc{2,svfpr{{{ge{5581
{{dac{1,2{{{{5582
{{dtc{27,/ge/{{{{5583
{{dac{6,s_gef{{{{5584
{{dac{1,2{{{{5585
{v_gtf{dbc{2,svfpr{{{gt{5587
{{dac{1,2{{{{5588
{{dtc{27,/gt/{{{{5589
{{dac{6,s_gtf{{{{5590
{{dac{1,2{{{{5591
{v_lef{dbc{2,svfpr{{{le{5593
{{dac{1,2{{{{5594
{{dtc{27,/le/{{{{5595
{{dac{6,s_lef{{{{5596
{{dac{1,2{{{{5597
{v_lnf{dbc{2,svfnp{{{ln{5600
{{dac{1,2{{{{5601
{{dtc{27,/ln/{{{{5602
{{dac{6,s_lnf{{{{5603
{{dac{1,1{{{{5604
{v_ltf{dbc{2,svfpr{{{lt{5607
{{dac{1,2{{{{5608
{{dtc{27,/lt/{{{{5609
{{dac{6,s_ltf{{{{5610
{{dac{1,2{{{{5611
{v_nef{dbc{2,svfpr{{{ne{5613
{{dac{1,2{{{{5614
{{dtc{27,/ne/{{{{5615
{{dac{6,s_nef{{{{5616
{{dac{1,2{{{{5617
{v_any{dbc{2,svfnp{{{any{5643
{{dac{1,3{{{{5644
{{dtc{27,/any/{{{{5645
{{dac{6,s_any{{{{5646
{{dac{1,1{{{{5647
{v_arb{dbc{2,svkvc{{{arb{5649
{{dac{1,3{{{{5650
{{dtc{27,/arb/{{{{5651
{{dac{2,k_arb{{{{5652
{{dac{4,ndarb{{{{5653
{{ejc{{{{{5654
*      standard variable blocks (continued)
{v_arg{dbc{2,svfnn{{{arg{5658
{{dac{1,3{{{{5659
{{dtc{27,/arg/{{{{5660
{{dac{6,s_arg{{{{5661
{{dac{1,2{{{{5662
{v_bal{dbc{2,svkvc{{{bal{5664
{{dac{1,3{{{{5665
{{dtc{27,/bal/{{{{5666
{{dac{2,k_bal{{{{5667
{{dac{4,ndbal{{{{5668
{v_cos{dbc{2,svfnp{{{cos{5671
{{dac{1,3{{{{5672
{{dtc{27,/cos/{{{{5673
{{dac{6,s_cos{{{{5674
{{dac{1,1{{{{5675
{v_end{dbc{2,svlbl{{{end{5678
{{dac{1,3{{{{5679
{{dtc{27,/end/{{{{5680
{{dac{6,l_end{{{{5681
{v_exp{dbc{2,svfnp{{{exp{5684
{{dac{1,3{{{{5685
{{dtc{27,/exp/{{{{5686
{{dac{6,s_exp{{{{5687
{{dac{1,1{{{{5688
{v_len{dbc{2,svfnp{{{len{5691
{{dac{1,3{{{{5692
{{dtc{27,/len/{{{{5693
{{dac{6,s_len{{{{5694
{{dac{1,1{{{{5695
{v_leq{dbc{2,svfpr{{{leq{5697
{{dac{1,3{{{{5698
{{dtc{27,/leq/{{{{5699
{{dac{6,s_leq{{{{5700
{{dac{1,2{{{{5701
{v_lge{dbc{2,svfpr{{{lge{5703
{{dac{1,3{{{{5704
{{dtc{27,/lge/{{{{5705
{{dac{6,s_lge{{{{5706
{{dac{1,2{{{{5707
{v_lgt{dbc{2,svfpr{{{lgt{5709
{{dac{1,3{{{{5710
{{dtc{27,/lgt/{{{{5711
{{dac{6,s_lgt{{{{5712
{{dac{1,2{{{{5713
{v_lle{dbc{2,svfpr{{{lle{5715
{{dac{1,3{{{{5716
{{dtc{27,/lle/{{{{5717
{{dac{6,s_lle{{{{5718
{{dac{1,2{{{{5719
{{ejc{{{{{5720
*      standard variable blocks (continued)
{v_llt{dbc{2,svfpr{{{llt{5724
{{dac{1,3{{{{5725
{{dtc{27,/llt/{{{{5726
{{dac{6,s_llt{{{{5727
{{dac{1,2{{{{5728
{v_lne{dbc{2,svfpr{{{lne{5730
{{dac{1,3{{{{5731
{{dtc{27,/lne/{{{{5732
{{dac{6,s_lne{{{{5733
{{dac{1,2{{{{5734
{v_pos{dbc{2,svfnp{{{pos{5736
{{dac{1,3{{{{5737
{{dtc{27,/pos/{{{{5738
{{dac{6,s_pos{{{{5739
{{dac{1,1{{{{5740
{v_rem{dbc{2,svkvc{{{rem{5742
{{dac{1,3{{{{5743
{{dtc{27,/rem/{{{{5744
{{dac{2,k_rem{{{{5745
{{dac{4,ndrem{{{{5746
{v_set{dbc{2,svfnn{{{set (renamed to zet for setl4){5749
{{dac{1,3{{{{5750
{{dtc{27,/zet/{{{{5751
{{dac{6,s_set{{{{5752
{{dac{1,3{{{{5753
{v_sin{dbc{2,svfnp{{{sin{5757
{{dac{1,3{{{{5758
{{dtc{27,/sin/{{{{5759
{{dac{6,s_sin{{{{5760
{{dac{1,1{{{{5761
{v_tab{dbc{2,svfnp{{{tab{5764
{{dac{1,3{{{{5765
{{dtc{27,/tab/{{{{5766
{{dac{6,s_tab{{{{5767
{{dac{1,1{{{{5768
{v_tan{dbc{2,svfnp{{{tan{5771
{{dac{1,3{{{{5772
{{dtc{27,/tan/{{{{5773
{{dac{6,s_tan{{{{5774
{{dac{1,1{{{{5775
{v_atn{dbc{2,svfnp{{{atan{5787
{{dac{1,4{{{{5788
{{dtc{27,/atan/{{{{5789
{{dac{6,s_atn{{{{5790
{{dac{1,1{{{{5791
{v_chr{dbc{2,svfnp{{{char{5801
{{dac{1,4{{{{5802
{{dtc{27,/char/{{{{5803
{{dac{6,s_chr{{{{5804
{{dac{1,1{{{{5805
{v_chp{dbc{2,svfnp{{{chop{5809
{{dac{1,4{{{{5810
{{dtc{27,/chop/{{{{5811
{{dac{6,s_chp{{{{5812
{{dac{1,1{{{{5813
{v_cod{dbc{2,svfnk{{{code{5815
{{dac{1,4{{{{5816
{{dtc{27,/code/{{{{5817
{{dac{2,k_cod{{{{5818
{{dac{6,s_cod{{{{5819
{{dac{1,1{{{{5820
{v_cop{dbc{2,svfnn{{{copy{5822
{{dac{1,4{{{{5823
{{dtc{27,/copy/{{{{5824
{{dac{6,s_cop{{{{5825
{{dac{1,1{{{{5826
{{ejc{{{{{5827
*      standard variable blocks (continued)
{v_dat{dbc{2,svfnn{{{data{5831
{{dac{1,4{{{{5832
{{dtc{27,/data/{{{{5833
{{dac{6,s_dat{{{{5834
{{dac{1,1{{{{5835
{v_dte{dbc{2,svfnn{{{date{5837
{{dac{1,4{{{{5838
{{dtc{27,/date/{{{{5839
{{dac{6,s_dte{{{{5840
{{dac{1,1{{{{5841
{v_dmp{dbc{2,svfnk{{{dump{5843
{{dac{1,4{{{{5844
{{dtc{27,/dump/{{{{5845
{{dac{2,k_dmp{{{{5846
{{dac{6,s_dmp{{{{5847
{{dac{1,1{{{{5848
{v_dup{dbc{2,svfnn{{{dupl{5850
{{dac{1,4{{{{5851
{{dtc{27,/dupl/{{{{5852
{{dac{6,s_dup{{{{5853
{{dac{1,2{{{{5854
{v_evl{dbc{2,svfnn{{{eval{5856
{{dac{1,4{{{{5857
{{dtc{27,/eval/{{{{5858
{{dac{6,s_evl{{{{5859
{{dac{1,1{{{{5860
{v_ext{dbc{2,svfnn{{{exit{5864
{{dac{1,4{{{{5865
{{dtc{27,/exit/{{{{5866
{{dac{6,s_ext{{{{5867
{{dac{1,2{{{{5868
{v_fal{dbc{2,svkvc{{{fail{5871
{{dac{1,4{{{{5872
{{dtc{27,/fail/{{{{5873
{{dac{2,k_fal{{{{5874
{{dac{4,ndfal{{{{5875
{v_fil{dbc{2,svknm{{{file{5878
{{dac{1,4{{{{5879
{{dtc{27,/file/{{{{5880
{{dac{2,k_fil{{{{5881
{v_hst{dbc{2,svfnn{{{host{5884
{{dac{1,4{{{{5885
{{dtc{27,/host/{{{{5886
{{dac{6,s_hst{{{{5887
{{dac{1,5{{{{5888
{{ejc{{{{{5889
*      standard variable blocks (continued)
{v_itm{dbc{2,svfnf{{{item{5893
{{dac{1,4{{{{5894
{{dtc{27,/item/{{{{5895
{{dac{6,s_itm{{{{5896
{{dac{1,999{{{{5897
{v_lin{dbc{2,svknm{{{line{5900
{{dac{1,4{{{{5901
{{dtc{27,/line/{{{{5902
{{dac{2,k_lin{{{{5903
{v_lod{dbc{2,svfnn{{{load{5908
{{dac{1,4{{{{5909
{{dtc{27,/load/{{{{5910
{{dac{6,s_lod{{{{5911
{{dac{1,2{{{{5912
{v_lpd{dbc{2,svfnp{{{lpad{5915
{{dac{1,4{{{{5916
{{dtc{27,/lpad/{{{{5917
{{dac{6,s_lpd{{{{5918
{{dac{1,3{{{{5919
{v_rpd{dbc{2,svfnp{{{rpad{5921
{{dac{1,4{{{{5922
{{dtc{27,/rpad/{{{{5923
{{dac{6,s_rpd{{{{5924
{{dac{1,3{{{{5925
{v_rps{dbc{2,svfnp{{{rpos{5927
{{dac{1,4{{{{5928
{{dtc{27,/rpos/{{{{5929
{{dac{6,s_rps{{{{5930
{{dac{1,1{{{{5931
{v_rtb{dbc{2,svfnp{{{rtab{5933
{{dac{1,4{{{{5934
{{dtc{27,/rtab/{{{{5935
{{dac{6,s_rtb{{{{5936
{{dac{1,1{{{{5937
{v_si_{dbc{2,svfnp{{{size{5939
{{dac{1,4{{{{5940
{{dtc{27,/size/{{{{5941
{{dac{6,s_si_{{{{5942
{{dac{1,1{{{{5943
{v_srt{dbc{2,svfnn{{{sort{5948
{{dac{1,4{{{{5949
{{dtc{27,/sort/{{{{5950
{{dac{6,s_srt{{{{5951
{{dac{1,2{{{{5952
{v_spn{dbc{2,svfnp{{{span{5954
{{dac{1,4{{{{5955
{{dtc{27,/span/{{{{5956
{{dac{6,s_spn{{{{5957
{{dac{1,1{{{{5958
{{ejc{{{{{5959
*      standard variable blocks (continued)
{v_sqr{dbc{2,svfnp{{{sqrt{5965
{{dac{1,4{{{{5966
{{dtc{27,/sqrt/{{{{5967
{{dac{6,s_sqr{{{{5968
{{dac{1,1{{{{5969
{v_stn{dbc{2,svknm{{{stno{5971
{{dac{1,4{{{{5972
{{dtc{27,/stno/{{{{5973
{{dac{2,k_stn{{{{5974
{v_tim{dbc{2,svfnn{{{time{5976
{{dac{1,4{{{{5977
{{dtc{27,/time/{{{{5978
{{dac{6,s_tim{{{{5979
{{dac{1,0{{{{5980
{v_trm{dbc{2,svfnk{{{trim{5982
{{dac{1,4{{{{5983
{{dtc{27,/trim/{{{{5984
{{dac{2,k_trm{{{{5985
{{dac{6,s_trm{{{{5986
{{dac{1,1{{{{5987
{v_abe{dbc{2,svknm{{{abend{5989
{{dac{1,5{{{{5990
{{dtc{27,/abend/{{{{5991
{{dac{2,k_abe{{{{5992
{v_abo{dbc{2,svkvl{{{abort{5994
{{dac{1,5{{{{5995
{{dtc{27,/abort/{{{{5996
{{dac{2,k_abo{{{{5997
{{dac{6,l_abo{{{{5998
{{dac{4,ndabo{{{{5999
{v_app{dbc{2,svfnf{{{apply{6001
{{dac{1,5{{{{6002
{{dtc{27,/apply/{{{{6003
{{dac{6,s_app{{{{6004
{{dac{1,999{{{{6005
{v_abn{dbc{2,svfnp{{{arbno{6007
{{dac{1,5{{{{6008
{{dtc{27,/arbno/{{{{6009
{{dac{6,s_abn{{{{6010
{{dac{1,1{{{{6011
{v_arr{dbc{2,svfnn{{{array{6013
{{dac{1,5{{{{6014
{{dtc{27,/array/{{{{6015
{{dac{6,s_arr{{{{6016
{{dac{1,2{{{{6017
{{ejc{{{{{6018
*      standard variable blocks (continued)
{v_brk{dbc{2,svfnp{{{break{6022
{{dac{1,5{{{{6023
{{dtc{27,/break/{{{{6024
{{dac{6,s_brk{{{{6025
{{dac{1,1{{{{6026
{v_clr{dbc{2,svfnn{{{clear{6028
{{dac{1,5{{{{6029
{{dtc{27,/clear/{{{{6030
{{dac{6,s_clr{{{{6031
{{dac{1,1{{{{6032
{v_ejc{dbc{2,svfnn{{{eject{6042
{{dac{1,5{{{{6043
{{dtc{27,/eject/{{{{6044
{{dac{6,s_ejc{{{{6045
{{dac{1,1{{{{6046
{v_fen{dbc{2,svfpk{{{fence{6048
{{dac{1,5{{{{6049
{{dtc{27,/fence/{{{{6050
{{dac{2,k_fen{{{{6051
{{dac{6,s_fnc{{{{6052
{{dac{1,1{{{{6053
{{dac{4,ndfen{{{{6054
{v_fld{dbc{2,svfnn{{{field{6056
{{dac{1,5{{{{6057
{{dtc{27,/field/{{{{6058
{{dac{6,s_fld{{{{6059
{{dac{1,2{{{{6060
{v_idn{dbc{2,svfpr{{{ident{6062
{{dac{1,5{{{{6063
{{dtc{27,/ident/{{{{6064
{{dac{6,s_idn{{{{6065
{{dac{1,2{{{{6066
{v_inp{dbc{2,svfnk{{{input{6068
{{dac{1,5{{{{6069
{{dtc{27,/input/{{{{6070
{{dac{2,k_inp{{{{6071
{{dac{6,s_inp{{{{6072
{{dac{1,3{{{{6073
{v_lcs{dbc{2,svkwc{{{lcase{6076
{{dac{1,5{{{{6077
{{dtc{27,/lcase/{{{{6078
{{dac{2,k_lcs{{{{6079
{v_loc{dbc{2,svfnn{{{local{6082
{{dac{1,5{{{{6083
{{dtc{27,/local/{{{{6084
{{dac{6,s_loc{{{{6085
{{dac{1,2{{{{6086
{{ejc{{{{{6087
*      standard variable blocks (continued)
{v_ops{dbc{2,svfnn{{{opsyn{6091
{{dac{1,5{{{{6092
{{dtc{27,/opsyn/{{{{6093
{{dac{6,s_ops{{{{6094
{{dac{1,3{{{{6095
{v_rmd{dbc{2,svfnp{{{remdr{6097
{{dac{1,5{{{{6098
{{dtc{27,/remdr/{{{{6099
{{dac{6,s_rmd{{{{6100
{{dac{1,2{{{{6101
{v_rsr{dbc{2,svfnn{{{rsort{6105
{{dac{1,5{{{{6106
{{dtc{27,/rsort/{{{{6107
{{dac{6,s_rsr{{{{6108
{{dac{1,2{{{{6109
{v_tbl{dbc{2,svfnn{{{table{6112
{{dac{1,5{{{{6113
{{dtc{27,/table/{{{{6114
{{dac{6,s_tbl{{{{6115
{{dac{1,3{{{{6116
{v_tra{dbc{2,svfnk{{{trace{6118
{{dac{1,5{{{{6119
{{dtc{27,/trace/{{{{6120
{{dac{2,k_tra{{{{6121
{{dac{6,s_tra{{{{6122
{{dac{1,4{{{{6123
{v_ucs{dbc{2,svkwc{{{ucase{6126
{{dac{1,5{{{{6127
{{dtc{27,/ucase/{{{{6128
{{dac{2,k_ucs{{{{6129
{v_anc{dbc{2,svknm{{{anchor{6132
{{dac{1,6{{{{6133
{{dtc{27,/anchor/{{{{6134
{{dac{2,k_anc{{{{6135
{v_bkx{dbc{2,svfnp{{{breakx{6146
{{dac{1,6{{{{6147
{{dtc{27,/breakx/{{{{6148
{{dac{6,s_bkx{{{{6149
{{dac{1,1{{{{6150
{v_def{dbc{2,svfnn{{{define{6161
{{dac{1,6{{{{6162
{{dtc{27,/define/{{{{6163
{{dac{6,s_def{{{{6164
{{dac{1,2{{{{6165
{v_det{dbc{2,svfnn{{{detach{6167
{{dac{1,6{{{{6168
{{dtc{27,/detach/{{{{6169
{{dac{6,s_det{{{{6170
{{dac{1,1{{{{6171
{{ejc{{{{{6172
*      standard variable blocks (continued)
{v_dif{dbc{2,svfpr{{{differ{6176
{{dac{1,6{{{{6177
{{dtc{27,/differ/{{{{6178
{{dac{6,s_dif{{{{6179
{{dac{1,2{{{{6180
{v_ftr{dbc{2,svknm{{{ftrace{6182
{{dac{1,6{{{{6183
{{dtc{27,/ftrace/{{{{6184
{{dac{2,k_ftr{{{{6185
{v_lst{dbc{2,svknm{{{lastno{6196
{{dac{1,6{{{{6197
{{dtc{27,/lastno/{{{{6198
{{dac{2,k_lst{{{{6199
{v_nay{dbc{2,svfnp{{{notany{6201
{{dac{1,6{{{{6202
{{dtc{27,/notany/{{{{6203
{{dac{6,s_nay{{{{6204
{{dac{1,1{{{{6205
{v_oup{dbc{2,svfnk{{{output{6207
{{dac{1,6{{{{6208
{{dtc{27,/output/{{{{6209
{{dac{2,k_oup{{{{6210
{{dac{6,s_oup{{{{6211
{{dac{1,3{{{{6212
{v_ret{dbc{2,svlbl{{{return{6214
{{dac{1,6{{{{6215
{{dtc{27,/return/{{{{6216
{{dac{6,l_rtn{{{{6217
{v_rew{dbc{2,svfnn{{{rewind{6219
{{dac{1,6{{{{6220
{{dtc{27,/rewind/{{{{6221
{{dac{6,s_rew{{{{6222
{{dac{1,1{{{{6223
{v_stt{dbc{2,svfnn{{{stoptr{6225
{{dac{1,6{{{{6226
{{dtc{27,/stoptr/{{{{6227
{{dac{6,s_stt{{{{6228
{{dac{1,2{{{{6229
{{ejc{{{{{6230
*      standard variable blocks (continued)
{v_sub{dbc{2,svfnn{{{substr{6234
{{dac{1,6{{{{6235
{{dtc{27,/substr/{{{{6236
{{dac{6,s_sub{{{{6237
{{dac{1,3{{{{6238
{v_unl{dbc{2,svfnn{{{unload{6240
{{dac{1,6{{{{6241
{{dtc{27,/unload/{{{{6242
{{dac{6,s_unl{{{{6243
{{dac{1,1{{{{6244
{v_col{dbc{2,svfnn{{{collect{6246
{{dac{1,7{{{{6247
{{dtc{27,/collect/{{{{6248
{{dac{6,s_col{{{{6249
{{dac{1,1{{{{6250
{v_com{dbc{2,svknm{{{compare{6253
{{dac{1,7{{{{6254
{{dtc{27,/compare/{{{{6255
{{dac{2,k_com{{{{6256
{v_cnv{dbc{2,svfnn{{{convert{6259
{{dac{1,7{{{{6260
{{dtc{27,/convert/{{{{6261
{{dac{6,s_cnv{{{{6262
{{dac{1,2{{{{6263
{v_enf{dbc{2,svfnn{{{endfile{6265
{{dac{1,7{{{{6266
{{dtc{27,/endfile/{{{{6267
{{dac{6,s_enf{{{{6268
{{dac{1,1{{{{6269
{v_etx{dbc{2,svknm{{{errtext{6271
{{dac{1,7{{{{6272
{{dtc{27,/errtext/{{{{6273
{{dac{2,k_etx{{{{6274
{v_ert{dbc{2,svknm{{{errtype{6276
{{dac{1,7{{{{6277
{{dtc{27,/errtype/{{{{6278
{{dac{2,k_ert{{{{6279
{v_frt{dbc{2,svlbl{{{freturn{6281
{{dac{1,7{{{{6282
{{dtc{27,/freturn/{{{{6283
{{dac{6,l_frt{{{{6284
{v_int{dbc{2,svfpr{{{integer{6286
{{dac{1,7{{{{6287
{{dtc{27,/integer/{{{{6288
{{dac{6,s_int{{{{6289
{{dac{1,1{{{{6290
{v_nrt{dbc{2,svlbl{{{nreturn{6292
{{dac{1,7{{{{6293
{{dtc{27,/nreturn/{{{{6294
{{dac{6,l_nrt{{{{6295
{{ejc{{{{{6296
*      standard variable blocks (continued)
{v_pfl{dbc{2,svknm{{{profile{6303
{{dac{1,7{{{{6304
{{dtc{27,/profile/{{{{6305
{{dac{2,k_pfl{{{{6306
{v_rpl{dbc{2,svfnp{{{replace{6309
{{dac{1,7{{{{6310
{{dtc{27,/replace/{{{{6311
{{dac{6,s_rpl{{{{6312
{{dac{1,3{{{{6313
{v_rvs{dbc{2,svfnp{{{reverse{6315
{{dac{1,7{{{{6316
{{dtc{27,/reverse/{{{{6317
{{dac{6,s_rvs{{{{6318
{{dac{1,1{{{{6319
{v_rtn{dbc{2,svknm{{{rtntype{6321
{{dac{1,7{{{{6322
{{dtc{27,/rtntype/{{{{6323
{{dac{2,k_rtn{{{{6324
{v_stx{dbc{2,svfnn{{{setexit{6326
{{dac{1,7{{{{6327
{{dtc{27,/setexit/{{{{6328
{{dac{6,s_stx{{{{6329
{{dac{1,1{{{{6330
{v_stc{dbc{2,svknm{{{stcount{6332
{{dac{1,7{{{{6333
{{dtc{27,/stcount/{{{{6334
{{dac{2,k_stc{{{{6335
{v_stl{dbc{2,svknm{{{stlimit{6337
{{dac{1,7{{{{6338
{{dtc{27,/stlimit/{{{{6339
{{dac{2,k_stl{{{{6340
{v_suc{dbc{2,svkvc{{{succeed{6342
{{dac{1,7{{{{6343
{{dtc{27,/succeed/{{{{6344
{{dac{2,k_suc{{{{6345
{{dac{4,ndsuc{{{{6346
{v_alp{dbc{2,svkwc{{{alphabet{6348
{{dac{1,8{{{{6349
{{dtc{27,/alphabet/{{{{6350
{{dac{2,k_alp{{{{6351
{v_cnt{dbc{2,svlbl{{{continue{6353
{{dac{1,8{{{{6354
{{dtc{27,/continue/{{{{6355
{{dac{6,l_cnt{{{{6356
{{ejc{{{{{6357
*      standard variable blocks (continued)
{v_dtp{dbc{2,svfnp{{{datatype{6361
{{dac{1,8{{{{6362
{{dtc{27,/datatype/{{{{6363
{{dac{6,s_dtp{{{{6364
{{dac{1,1{{{{6365
{v_erl{dbc{2,svknm{{{errlimit{6367
{{dac{1,8{{{{6368
{{dtc{27,/errlimit/{{{{6369
{{dac{2,k_erl{{{{6370
{v_fnc{dbc{2,svknm{{{fnclevel{6372
{{dac{1,8{{{{6373
{{dtc{27,/fnclevel/{{{{6374
{{dac{2,k_fnc{{{{6375
{v_fls{dbc{2,svknm{{{fullscan{6377
{{dac{1,8{{{{6378
{{dtc{27,/fullscan/{{{{6379
{{dac{2,k_fls{{{{6380
{v_lfl{dbc{2,svknm{{{lastfile{6383
{{dac{1,8{{{{6384
{{dtc{27,/lastfile/{{{{6385
{{dac{2,k_lfl{{{{6386
{v_lln{dbc{2,svknm{{{lastline{6390
{{dac{1,8{{{{6391
{{dtc{27,/lastline/{{{{6392
{{dac{2,k_lln{{{{6393
{v_mxl{dbc{2,svknm{{{maxlngth{6396
{{dac{1,8{{{{6397
{{dtc{27,/maxlngth/{{{{6398
{{dac{2,k_mxl{{{{6399
{v_ter{dbc{1,0{{{terminal{6401
{{dac{1,8{{{{6402
{{dtc{27,/terminal/{{{{6403
{{dac{1,0{{{{6404
{v_bsp{dbc{2,svfnn{{{backspace{6407
{{dac{1,9{{{{6408
{{dtc{27,/backspace/{{{{6409
{{dac{6,s_bsp{{{{6410
{{dac{1,1{{{{6411
{v_pro{dbc{2,svfnn{{{prototype{6414
{{dac{1,9{{{{6415
{{dtc{27,/prototype/{{{{6416
{{dac{6,s_pro{{{{6417
{{dac{1,1{{{{6418
{v_scn{dbc{2,svlbl{{{scontinue{6420
{{dac{1,9{{{{6421
{{dtc{27,/scontinue/{{{{6422
{{dac{6,l_scn{{{{6423
{{dbc{1,0{{{dummy entry to end list{6425
{{dac{1,10{{{length gt 9 (scontinue){6426
{{ejc{{{{{6427
*      list of svblk pointers for keywords to be dumped. the
*      list is in the order which appears on the dump output.
{vdmkw{dac{4,v_anc{{{anchor{6432
{{dac{4,v_cod{{{code{6436
{{dac{1,1{{{compare not printed{6441
{{dac{4,v_dmp{{{dump{6444
{{dac{4,v_erl{{{errlimit{6445
{{dac{4,v_etx{{{errtext{6446
{{dac{4,v_ert{{{errtype{6447
{{dac{4,v_fil{{{file{6449
{{dac{4,v_fnc{{{fnclevel{6451
{{dac{4,v_ftr{{{ftrace{6452
{{dac{4,v_fls{{{fullscan{6453
{{dac{4,v_inp{{{input{6454
{{dac{4,v_lfl{{{lastfile{6456
{{dac{4,v_lln{{{lastline{6459
{{dac{4,v_lst{{{lastno{6461
{{dac{4,v_lin{{{line{6463
{{dac{4,v_mxl{{{maxlength{6465
{{dac{4,v_oup{{{output{6466
{{dac{4,v_pfl{{{profile{6469
{{dac{4,v_rtn{{{rtntype{6471
{{dac{4,v_stc{{{stcount{6472
{{dac{4,v_stl{{{stlimit{6473
{{dac{4,v_stn{{{stno{6474
{{dac{4,v_tra{{{trace{6475
{{dac{4,v_trm{{{trim{6476
{{dac{1,0{{{end of list{6477
*      table used by gtnvr to search svblk lists
{vsrch{dac{1,0{{{dummy entry to get proper indexing{6481
{{dac{4,v_eqf{{{start of 1 char variables (none){6482
{{dac{4,v_eqf{{{start of 2 char variables{6483
{{dac{4,v_any{{{start of 3 char variables{6484
{{dac{4,v_atn{{{start of 4 char variables{6486
{{dac{4,v_abe{{{start of 5 char variables{6494
{{dac{4,v_anc{{{start of 6 char variables{6495
{{dac{4,v_col{{{start of 7 char variables{6496
{{dac{4,v_alp{{{start of 8 char variables{6497
{{dac{4,v_bsp{{{start of 9 char variables{6499
*      last location in constant section
{c_yyy{dac{1,0{{{last location in constant section{6506
{{ttl{27,s p i t b o l -- working storage section{{{{6507
*      the working storage section contains areas which are
*      changed during execution of the program. the value
*      assembled is the initial value before execution starts.
*      all these areas are fixed length areas. variable length
*      data is stored in the static or dynamic regions of the
*      allocated data areas.
*      the values in this area are described either as work
*      areas or as global values. a work area is used in an
*      ephemeral manner and the value is not saved from one
*      entry into a routine to another. a global value is a
*      less temporary location whose value is saved from one
*      call to another.
*      w_aaa marks the start of the working section whilst
*      w_yyy marks its end.  g_aaa marks the division between
*      temporary and global values.
*      global values are further subdivided to facilitate
*      processing by the garbage collector. r_aaa through
*      r_yyy are global values that may point into dynamic
*      storage and hence must be relocated after each garbage
*      collection.  they also serve as root pointers to all
*      allocated data that must be preserved.  pointers between
*      a_aaa and r_aaa may point into code, static storage,
*      or mark the limits of dynamic memory.  these pointers
*      must be adjusted when the working section is saved to a
*      file and subsequently reloaded at a different address.
*      a general part of the approach in this program is not
*      to overlap work areas between procedures even though a
*      small amount of space could be saved. such overlap is
*      considered a source of program errors and decreases the
*      information left behind after a system crash of any kind.
*      the names of these locations are labels with five letter
*      (a-y,_) names. as far as possible the order is kept
*      alphabetical by these names but in some cases there
*      are slight departures caused by other order requirements.
*      unless otherwise documented, the order of work areas
*      does not affect the execution of the spitbol program.
{{sec{{{{start of working storage section{6553
{{ejc{{{{{6554
*      this area is not cleared by initial code
{cmlab{dac{6,b_scl{{{string used to check label legality{6558
{{dac{1,2{{{{6559
{{dtc{27,/  /{{{{6560
*      label to mark start of work area
{w_aaa{dac{1,0{{{{6564
*      work areas for acess procedure
{actrm{dac{1,0{{{trim indicator{6568
*      work areas for alloc procedure
{aldyn{dac{1,0{{{amount of dynamic store{6572
{allia{dic{16,+0{{{dump ia{6573
{allsv{dac{1,0{{{save wb in alloc{6574
*      work areas for alost procedure
{alsta{dac{1,0{{{save wa in alost{6578
*      work areas for array function (s_arr)
{arcdm{dac{1,0{{{count dimensions{6582
{arnel{dic{16,+0{{{count elements{6583
{arptr{dac{1,0{{{offset ptr into arblk{6584
{arsvl{dic{16,+0{{{save integer low bound{6585
{{ejc{{{{{6586
*      work areas for arref routine
{arfsi{dic{16,+0{{{save current evolving subscript{6590
{arfxs{dac{1,0{{{save base stack pointer{6591
*      work areas for b_efc block routine
{befof{dac{1,0{{{save offset ptr into efblk{6595
*      work areas for b_pfc block routine
{bpfpf{dac{1,0{{{save pfblk pointer{6599
{bpfsv{dac{1,0{{{save old function value{6600
{bpfxt{dac{1,0{{{pointer to stacked arguments{6601
*      work area for collect function (s_col)
{clsvi{dic{16,+0{{{save integer argument{6605
*      work areas value for cncrd
{cnscc{dac{1,0{{{pointer to control card string{6609
{cnswc{dac{1,0{{{word count{6610
{cnr_t{dac{1,0{{{pointer to r_ttl or r_stl{6611
*      work areas for convert function (s_cnv)
{cnvtp{dac{1,0{{{save ptr into scvtb{6615
*      work areas for data function (s_dat)
{datdv{dac{1,0{{{save vrblk ptr for datatype name{6619
{datxs{dac{1,0{{{save initial stack pointer{6620
*      work areas for define function (s_def)
{deflb{dac{1,0{{{save vrblk ptr for label{6624
{defna{dac{1,0{{{count function arguments{6625
{defvr{dac{1,0{{{save vrblk ptr for function name{6626
{defxs{dac{1,0{{{save initial stack pointer{6627
*      work areas for dumpr procedure
{dmarg{dac{1,0{{{dump argument{6631
{dmpsa{dac{1,0{{{preserve wa over prtvl call{6632
{dmpsb{dac{1,0{{{preserve wb over syscm call{6634
{dmpsv{dac{1,0{{{general scratch save{6636
{dmvch{dac{1,0{{{chain pointer for variable blocks{6637
{dmpch{dac{1,0{{{save sorted vrblk chain pointer{6638
{dmpkb{dac{1,0{{{dummy kvblk for use in dumpr{6639
{dmpkt{dac{1,0{{{kvvar trblk ptr (must follow dmpkb){6640
{dmpkn{dac{1,0{{{keyword number (must follow dmpkt){6641
*      work area for dtach
{dtcnb{dac{1,0{{{name base{6645
{dtcnm{dac{1,0{{{name ptr{6646
*      work areas for dupl function (s_dup)
{dupsi{dic{16,+0{{{store integer string length{6650
*      work area for endfile (s_enf)
{enfch{dac{1,0{{{for iochn chain head{6654
{{ejc{{{{{6655
*      work areas for ertex
{ertwa{dac{1,0{{{save wa{6659
{ertwb{dac{1,0{{{save wb{6660
*      work areas for evali
{evlin{dac{1,0{{{dummy pattern block pcode{6664
{evlis{dac{1,0{{{then node (must follow evlin){6665
{evliv{dac{1,0{{{value of parm1 (must follow evlis){6666
{evlio{dac{1,0{{{ptr to original node{6667
{evlif{dac{1,0{{{flag for simple/complex argument{6668
*      work area for expan
{expsv{dac{1,0{{{save op dope vector pointer{6672
*      work areas for gbcol procedure
{gbcfl{dac{1,0{{{garbage collector active flag{6676
{gbclm{dac{1,0{{{pointer to last move block (pass 3){6677
{gbcnm{dac{1,0{{{dummy first move block{6678
{gbcns{dac{1,0{{{rest of dummy block (follows gbcnm){6679
{gbcmk{dac{1,0{{{bias when marking entry point{6683
{gbcia{dic{16,+0{{{dump ia{6685
{gbcsd{dac{1,0{{{first address beyond sediment{6686
{gbcsf{dac{1,0{{{free space within sediment{6687
{gbsva{dac{1,0{{{save wa{6689
{gbsvb{dac{1,0{{{save wb{6690
{gbsvc{dac{1,0{{{save wc{6691
*      work areas for gtnvr procedure
{gnvhe{dac{1,0{{{ptr to end of hash chain{6695
{gnvnw{dac{1,0{{{number of words in string name{6696
{gnvsa{dac{1,0{{{save wa{6697
{gnvsb{dac{1,0{{{save wb{6698
{gnvsp{dac{1,0{{{pointer into vsrch table{6699
{gnvst{dac{1,0{{{pointer to chars of string{6700
*      work areas for gtarr
{gtawa{dac{1,0{{{save wa{6704
*      work areas for gtint
{gtina{dac{1,0{{{save wa{6708
{gtinb{dac{1,0{{{save wb{6709
{{ejc{{{{{6710
*      work areas for gtnum procedure
{gtnnf{dac{1,0{{{zero/nonzero for result +/-{6714
{gtnsi{dic{16,+0{{{general integer save{6715
{gtndf{dac{1,0{{{0/1 for dec point so far no/yes{6718
{gtnes{dac{1,0{{{zero/nonzero exponent +/-{6719
{gtnex{dic{16,+0{{{real exponent{6720
{gtnsc{dac{1,0{{{scale (places after point){6721
{gtnsr{drc{17,+0.0{{{general real save{6722
{gtnrd{dac{1,0{{{flag for ok real number{6723
*      work areas for gtpat procedure
{gtpsb{dac{1,0{{{save wb{6728
*      work areas for gtstg procedure
{gtssf{dac{1,0{{{0/1 for result +/-{6732
{gtsvc{dac{1,0{{{save wc{6733
{gtsvb{dac{1,0{{{save wb{6734
{gtses{dac{1,0{{{char + or - for exponent +/-{6739
{gtsrs{drc{17,+0.0{{{general real save{6740
*      work areas for gtvar procedure
{gtvrc{dac{1,0{{{save wc{6746
*      work areas for ioput
{ioptt{dac{1,0{{{type of association{6761
*      work areas for load function
{lodfn{dac{1,0{{{pointer to vrblk for func name{6767
{lodna{dac{1,0{{{count number of arguments{6768
*      mxint is value of maximum positive integer. it is computed at runtime to allow
*      the compilation of spitbol on a machine with smaller word size the the target.
{mxint{dac{1,0{{{{6774
*      work area for profiler
{pfsvw{dac{1,0{{{to save a w-reg{6780
*      work areas for prtnm procedure
{prnsi{dic{16,+0{{{scratch integer loc{6785
*      work areas for prtsn procedure
{prsna{dac{1,0{{{save wa{6789
*      work areas for prtst procedure
{prsva{dac{1,0{{{save wa{6793
{prsvb{dac{1,0{{{save wb{6794
{prsvc{dac{1,0{{{save char counter{6795
*      work area for prtnl
{prtsa{dac{1,0{{{save wa{6799
{prtsb{dac{1,0{{{save wb{6800
*      work area for prtvl
{prvsi{dac{1,0{{{save idval{6804
*      work areas for pattern match routines
{psave{dac{1,0{{{temporary save for current node ptr{6808
{psavc{dac{1,0{{{save cursor in p_spn, p_str{6809
*      work area for relaj routine
{rlals{dac{1,0{{{ptr to list of bounds and adjusts{6814
*      work area for reldn routine
{rldcd{dac{1,0{{{save code adjustment{6818
{rldst{dac{1,0{{{save static adjustment{6819
{rldls{dac{1,0{{{save list pointer{6820
*      work areas for retrn routine
{rtnbp{dac{1,0{{{to save a block pointer{6825
{rtnfv{dac{1,0{{{new function value (result){6826
{rtnsv{dac{1,0{{{old function value (saved value){6827
*      work areas for substr function (s_sub)
{sbssv{dac{1,0{{{save third argument{6831
*      work areas for scan procedure
{scnsa{dac{1,0{{{save wa{6835
{scnsb{dac{1,0{{{save wb{6836
{scnsc{dac{1,0{{{save wc{6837
{scnof{dac{1,0{{{save offset{6838
{{ejc{{{{{6841
*      work area used by sorta, sortc, sortf, sorth
{srtdf{dac{1,0{{{datatype field name{6845
{srtfd{dac{1,0{{{found dfblk address{6846
{srtff{dac{1,0{{{found field name{6847
{srtfo{dac{1,0{{{offset to field name{6848
{srtnr{dac{1,0{{{number of rows{6849
{srtof{dac{1,0{{{offset within row to sort key{6850
{srtrt{dac{1,0{{{root offset{6851
{srts1{dac{1,0{{{save offset 1{6852
{srts2{dac{1,0{{{save offset 2{6853
{srtsc{dac{1,0{{{save wc{6854
{srtsf{dac{1,0{{{sort array first row offset{6855
{srtsn{dac{1,0{{{save n{6856
{srtso{dac{1,0{{{offset to a(0){6857
{srtsr{dac{1,0{{{0, non-zero for sort, rsort{6858
{srtst{dac{1,0{{{stride from one row to next{6859
{srtwc{dac{1,0{{{dump wc{6860
*      work areas for stopr routine
{stpsi{dic{16,+0{{{save value of stcount{6865
{stpti{dic{16,+0{{{save time elapsed{6866
*      work areas for tfind procedure
{tfnsi{dic{16,+0{{{number of headers{6870
*      work areas for xscan procedure
{xscrt{dac{1,0{{{save return code{6874
{xscwb{dac{1,0{{{save register wb{6875
*      start of global values in working section
{g_aaa{dac{1,0{{{{6879
*      global value for alloc procedure
{alfsf{dic{16,+0{{{factor in free store pcntage check{6883
*      global values for cmpil procedure
{cmerc{dac{1,0{{{count of initial compile errors{6887
{cmpln{dac{1,0{{{line number of first line of stmt{6888
{cmpxs{dac{1,0{{{save stack ptr in case of errors{6889
{cmpsn{dac{1,1{{{number of next statement to compile{6890
*      global values for cncrd
{cnsil{dac{1,0{{{save scnil during include process.{6895
{cnind{dac{1,0{{{current include file nest level{6896
{cnspt{dac{1,0{{{save scnpt during include process.{6897
{cnttl{dac{1,0{{{flag for -title, -stitl{6899
*      global flag for suppression of compilation statistics.
{cpsts{dac{1,0{{{suppress comp. stats if non zero{6903
*      global values for control card switches
{cswdb{dac{1,0{{{0/1 for -single/-double{6907
{cswer{dac{1,0{{{0/1 for -errors/-noerrors{6908
{cswex{dac{1,0{{{0/1 for -execute/-noexecute{6909
{cswfl{dac{1,1{{{0/1 for -nofail/-fail{6910
{cswin{dac{2,iniln{{{xxx for -inxxx{6911
{cswls{dac{1,1{{{0/1 for -nolist/-list{6912
{cswno{dac{1,0{{{0/1 for -optimise/-noopt{6913
{cswpr{dac{1,0{{{0/1 for -noprint/-print{6914
*      global location used by patst procedure
{ctmsk{dbc{1,0{{{last bit position used in r_ctp{6918
{curid{dac{1,0{{{current id value{6919
{{ejc{{{{{6920
*      global value for cdwrd procedure
{cwcof{dac{1,0{{{next word offset in current ccblk{6924
*      global locations for dynamic storage pointers
{dnams{dac{1,0{{{size of sediment in baus{6929
*      global area for error processing.
{erich{dac{1,0{{{copy error reports to int.chan if 1{6934
{erlst{dac{1,0{{{for listr when errors go to int.ch.{6935
{errft{dac{1,0{{{fatal error flag{6936
{errsp{dac{1,0{{{error suppression flag{6937
*      global flag for suppression of execution stats
{exsts{dac{1,0{{{suppress exec stats if set{6941
*      global values for exfal and return
{flprt{dac{1,0{{{location of fail offset for return{6945
{flptr{dac{1,0{{{location of failure offset on stack{6946
*      global location to count garbage collections (gbcol)
{gbsed{dic{16,+0{{{factor in sediment pcntage check{6951
{gbcnt{dac{1,0{{{count of garbage collections{6953
*      global value for gtcod and gtexp
{gtcef{dac{1,0{{{save fail ptr in case of error{6957
*      global locations for gtstg procedure
{gtsrn{drc{17,+0.0{{{rounding factor 0.5*10**-cfp_s{6965
{gtssc{drc{17,+0.0{{{scaling value 10**cfp_s{6966
{gtswk{dac{1,0{{{ptr to work area for gtstg{6969
*      global flag for header printing
{headp{dac{1,0{{{header printed flag{6973
*      global values for variable hash table
{hshnb{dic{16,+0{{{number of hash buckets{6977
*      global areas for init
{initr{dac{1,0{{{save terminal flag{6981
{{ejc{{{{{6982
*      global values for keyword values which are stored as one
*      word integers. these values must be assembled in the
*      following order (as dictated by k_xxx definition values).
{kvabe{dac{1,0{{{abend{6988
{kvanc{dac{1,1{{{anchor{6989
{kvcod{dac{1,0{{{code{6993
{kvcom{dac{1,0{{{compare{6995
{kvdmp{dac{1,0{{{dump{6997
{kverl{dac{1,0{{{errlimit{6998
{kvert{dac{1,0{{{errtype{6999
{kvftr{dac{1,0{{{ftrace{7000
{kvfls{dac{1,1{{{fullscan{7001
{kvinp{dac{1,1{{{input{7002
{kvmxl{dac{1,5000{{{maxlength{7003
{kvoup{dac{1,1{{{output{7004
{kvpfl{dac{1,0{{{profile{7007
{kvtra{dac{1,0{{{trace{7009
{kvtrm{dac{1,1{{{trim{7010
{kvfnc{dac{1,0{{{fnclevel{7011
{kvlst{dac{1,0{{{lastno{7012
{kvlln{dac{1,0{{{lastline{7014
{kvlin{dac{1,0{{{line{7015
{kvstn{dac{1,0{{{stno{7017
*      global values for other keywords
{kvalp{dac{1,0{{{alphabet{7021
{kvrtn{dac{4,nulls{{{rtntype (scblk pointer){7022
{kvstl{dic{16,+2147483647{{{stlimit{7028
{kvstc{dic{16,+2147483647{{{stcount (counts down from stlimit){7029
*      global values for listr procedure
{lstid{dac{1,0{{{include depth of current image{7039
{lstlc{dac{1,0{{{count lines on source list page{7041
{lstnp{dac{1,0{{{max number of lines on page{7042
{lstpf{dac{1,1{{{set nonzero if current image listed{7043
{lstpg{dac{1,0{{{current source list page number{7044
{lstpo{dac{1,0{{{offset to   page nnn   message{7045
{lstsn{dac{1,0{{{remember last stmnum listed{7046
*      global maximum size of spitbol objects
{mxlen{dac{1,0{{{initialised by sysmx call{7050
*      global execution control variable
{noxeq{dac{1,0{{{set non-zero to inhibit execution{7054
*      global profiler values locations
{pfdmp{dac{1,0{{{set non-0 if &profile set non-0{7060
{pffnc{dac{1,0{{{set non-0 if funct just entered{7061
{pfstm{dic{16,+0{{{to store starting time of stmt{7062
{pfetm{dic{16,+0{{{to store ending time of stmt{7063
{pfnte{dac{1,0{{{nr of table entries{7064
{pfste{dic{16,+0{{{gets int rep of table entry size{7065
{{ejc{{{{{7068
*      global values used in pattern match routines
{pmdfl{dac{1,0{{{pattern assignment flag{7072
{pmhbs{dac{1,0{{{history stack base pointer{7073
{pmssl{dac{1,0{{{length of subject string in chars{7074
*      global values for interface polling (syspl)
{polcs{dac{1,1{{{poll interval start value{7079
{polct{dac{1,1{{{poll interval counter{7080
*      global flags used for standard file listing options
{prich{dac{1,0{{{printer on interactive channel{7085
{prstd{dac{1,0{{{tested by prtpg{7086
{prsto{dac{1,0{{{standard listing option flag{7087
*      global values for print procedures
{prbuf{dac{1,0{{{ptr to print bfr in static{7091
{precl{dac{1,0{{{extended/compact listing flag{7092
{prlen{dac{1,0{{{length of print buffer in chars{7093
{prlnw{dac{1,0{{{length of print buffer in words{7094
{profs{dac{1,0{{{offset to next location in prbuf{7095
{prtef{dac{1,0{{{endfile flag{7096
{{ejc{{{{{7097
*      global area for readr
{rdcln{dac{1,0{{{current statement line number{7101
{rdnln{dac{1,0{{{next statement line number{7102
*      global amount of memory reserved for end of execution
{rsmem{dac{1,0{{{reserve memory{7106
*      global area for stmgo counters
{stmcs{dac{1,1{{{counter startup value{7110
{stmct{dac{1,1{{{counter active value{7111
*      adjustable global values
*      all the pointers in this section can point to the
*      dynamic or the static region.
*      when a save file is reloaded, these pointers must
*      be adjusted if static or dynamic memory is now
*      at a different address.  see routine reloc for
*      additional information.
*      some values cannot be move here because of adjacency
*      constraints.  they are handled specially by reloc et al.
*      these values are kvrtn,
*      values gtswk, kvalp, and prbuf are reinitialized by
*      procedure insta, and do not need to appear here.
*      values flprt, flptr, gtcef, and stbas point into the
*      stack and are explicitly adjusted by osint's restart
*      procedure.
{a_aaa{dac{1,0{{{start of adjustable values{7133
{cmpss{dac{1,0{{{save subroutine stack ptr{7134
{dnamb{dac{1,0{{{start of dynamic area{7135
{dnamp{dac{1,0{{{next available loc in dynamic area{7136
{dname{dac{1,0{{{end of available dynamic area{7137
{hshtb{dac{1,0{{{pointer to start of vrblk hash tabl{7138
{hshte{dac{1,0{{{pointer past end of vrblk hash tabl{7139
{iniss{dac{1,0{{{save subroutine stack ptr{7140
{pftbl{dac{1,0{{{gets adrs of (imag) table base{7141
{prnmv{dac{1,0{{{vrblk ptr from last name search{7142
{statb{dac{1,0{{{start of static area{7143
{state{dac{1,0{{{end of static area{7144
{stxvr{dac{4,nulls{{{vrblk pointer or null{7145
*      relocatable global values
*      all the pointers in this section can point to blocks in
*      the dynamic storage area and must be relocated by the
*      garbage collector. they are identified by r_xxx names.
{r_aaa{dac{1,0{{{start of relocatable values{7154
{r_arf{dac{1,0{{{array block pointer for arref{7155
{r_ccb{dac{1,0{{{ptr to ccblk being built (cdwrd){7156
{r_cim{dac{1,0{{{ptr to current compiler input str{7157
{r_cmp{dac{1,0{{{copy of r_cim used in cmpil{7158
{r_cni{dac{1,0{{{ptr to next compiler input string{7159
{r_cnt{dac{1,0{{{cdblk pointer for setexit continue{7160
{r_cod{dac{1,0{{{pointer to current cdblk or exblk{7161
{r_ctp{dac{1,0{{{ptr to current ctblk for patst{7162
{r_cts{dac{1,0{{{ptr to last string scanned by patst{7163
{r_ert{dac{1,0{{{trblk pointer for errtype trace{7164
{r_etx{dac{4,nulls{{{pointer to errtext string{7165
{r_exs{dac{1,0{{{= save xl in expdm{7166
{r_fcb{dac{1,0{{{fcblk chain head{7167
{r_fnc{dac{1,0{{{trblk pointer for fnclevel trace{7168
{r_gtc{dac{1,0{{{keep code ptr for gtcod,gtexp{7169
{r_ici{dac{1,0{{{saved r_cim during include process.{7171
{r_ifa{dac{1,0{{{array of file names by incl. depth{7173
{r_ifl{dac{1,0{{{array of line nums by include depth{7174
{r_ifn{dac{1,0{{{last include file name{7176
{r_inc{dac{1,0{{{table of include file names seen{7177
{r_io1{dac{1,0{{{file arg1 for ioput{7179
{r_io2{dac{1,0{{{file arg2 for ioput{7180
{r_iof{dac{1,0{{{fcblk ptr or 0{7181
{r_ion{dac{1,0{{{name base ptr{7182
{r_iop{dac{1,0{{{predecessor block ptr for ioput{7183
{r_iot{dac{1,0{{{trblk ptr for ioput{7184
{r_pms{dac{1,0{{{subject string ptr in pattern match{7189
{r_ra2{dac{1,0{{{replace second argument last time{7190
{r_ra3{dac{1,0{{{replace third argument last time{7191
{r_rpt{dac{1,0{{{ptr to ctblk replace table last usd{7192
{r_scp{dac{1,0{{{save pointer from last scane call{7193
{r_sfc{dac{4,nulls{{{current source file name{7195
{r_sfn{dac{1,0{{{ptr to source file name table{7196
{r_sxl{dac{1,0{{{preserve xl in sortc{7198
{r_sxr{dac{1,0{{{preserve xr in sorta/sortc{7199
{r_stc{dac{1,0{{{trblk pointer for stcount trace{7200
{r_stl{dac{1,0{{{source listing sub-title{7201
{r_sxc{dac{1,0{{{code (cdblk) ptr for setexit trap{7202
{r_ttl{dac{4,nulls{{{source listing title{7203
{r_xsc{dac{1,0{{{string pointer for xscan{7204
{{ejc{{{{{7205
*      the remaining pointers in this list are used to point
*      to function blocks for normally undefined operators.
{r_uba{dac{4,stndo{{{binary at{7210
{r_ubm{dac{4,stndo{{{binary ampersand{7211
{r_ubn{dac{4,stndo{{{binary number sign{7212
{r_ubp{dac{4,stndo{{{binary percent{7213
{r_ubt{dac{4,stndo{{{binary not{7214
{r_uub{dac{4,stndo{{{unary vertical bar{7215
{r_uue{dac{4,stndo{{{unary equal{7216
{r_uun{dac{4,stndo{{{unary number sign{7217
{r_uup{dac{4,stndo{{{unary percent{7218
{r_uus{dac{4,stndo{{{unary slash{7219
{r_uux{dac{4,stndo{{{unary exclamation{7220
{r_yyy{dac{1,0{{{last relocatable location{7221
*      global locations used in scan procedure
{scnbl{dac{1,0{{{set non-zero if scanned past blanks{7225
{scncc{dac{1,0{{{non-zero to scan control card name{7226
{scngo{dac{1,0{{{set non-zero to scan goto field{7227
{scnil{dac{1,0{{{length of current input image{7228
{scnpt{dac{1,0{{{pointer to next location in r_cim{7229
{scnrs{dac{1,0{{{set non-zero to signal rescan{7230
{scnse{dac{1,0{{{start of current element{7231
{scntp{dac{1,0{{{save syntax type from last call{7232
*      global value for indicating stage (see error section)
{stage{dac{1,0{{{initial value = initial compile{7236
{{ejc{{{{{7237
*      global stack pointer
{stbas{dac{1,0{{{pointer past stack base{7241
*      global values for setexit function (s_stx)
{stxoc{dac{1,0{{{code pointer offset{7245
{stxof{dac{1,0{{{failure offset{7246
*      global value for time keeping
{timsx{dic{16,+0{{{time at start of execution{7250
{timup{dac{1,0{{{set when time up occurs{7251
*      global values for xscan and xscni procedures
{xsofs{dac{1,0{{{offset to current location in r_xsc{7255
*      label to mark end of working section
{w_yyy{dac{1,0{{{{7259
{{ttl{27,s p i t b o l -- minimal code{{{{7260
{{sec{{{{start of program section{7261
{s_aaa{ent{2,bl__i{{{mark start of code{7262
{{ttl{27,s p i t b o l -- relocation{{{{7264
*      relocation
*      the following section provides services to osint to
*      relocate portions of the workspace.  it is used when
*      a saved memory image must be restarted at a different
*      location.
*      relaj -- relocate a list of pointers
*      (wa)                  ptr past last pointer of list
*      (wb)                  ptr to first pointer of list
*      (xl)                  list of boundaries and adjustments
*      jsr  relaj            call to process list of pointers
*      (wb)                  destroyed
{relaj{prc{25,e{1,0{{entry point{7280
{{mov{11,-(xs){7,xr{{save xr{7281
{{mov{11,-(xs){8,wa{{save wa{7282
{{mov{3,rlals{7,xl{{save ptr to list of bounds{7283
{{mov{7,xr{8,wb{{ptr to first pointer to process{7284
*      merge here to check if done
{rlaj0{mov{7,xl{3,rlals{{restore xl{7288
{{bne{7,xr{9,(xs){6,rlaj1{proceed if more to do{7289
{{mov{8,wa{10,(xs)+{{restore wa{7290
{{mov{7,xr{10,(xs)+{{restore xr{7291
{{exi{{{{return to caller{7292
*      merge here to process next pointer on list
{rlaj1{mov{8,wa{9,(xr){{load next pointer on list{7296
{{lct{8,wb{18,=rnsi_{{number of sections of adjusters{7297
*      merge here to process next section of stack list
{rlaj2{bgt{8,wa{13,rlend(xl){6,rlaj3{ok if past end of section{7301
{{blt{8,wa{13,rlstr(xl){6,rlaj3{or if before start of section{7302
{{add{8,wa{13,rladj(xl){{within section, add adjustment{7303
{{mov{9,(xr){8,wa{{return updated ptr to memory{7304
{{brn{6,rlaj4{{{done with this pointer{7305
*      here if not within section
{rlaj3{add{7,xl{19,*rssi_{{advance to next section{7309
{{bct{8,wb{6,rlaj2{{jump if more to go{7310
*      here when finished processing one pointer
{rlaj4{ica{7,xr{{{increment to next ptr on list{7314
{{brn{6,rlaj0{{{jump to check  for completion{7315
{{enp{{{{end procedure relaj{7316
{{ejc{{{{{7317
*      relcr -- create relocation info after save file reload
*      (wa)                  original s_aaa code section adr
*      (wb)                  original c_aaa constant section adr
*      (wc)                  original g_aaa working section adr
*      (xr)                  ptr to start of static region
*      (cp)                  ptr to start of dynamic region
*      (xl)                  ptr to area to receive information
*      jsr  relcr            create relocation information
*      (wa,wb,wc,xr)         destroyed
*      a block of information is built at (xl) that is used
*      in relocating pointers.  there are rnsi_ instances
*      of a rssi_ word structure.  each instance corresponds
*      to one of the regions that a pointer might point into.
*      the layout of this structure is shown in the definitions
*      section, together with symbolic definitions of the
*      entries as offsets from xl.
{relcr{prc{25,e{1,0{{entry point{7338
{{add{7,xl{19,*rlsi_{{point past build area{7339
{{mov{11,-(xl){8,wa{{save original code address{7340
{{mov{8,wa{22,=s_aaa{{compute adjustment{7341
{{sub{8,wa{9,(xl){{as new s_aaa minus original s_aaa{7342
{{mov{11,-(xl){8,wa{{save code adjustment{7343
{{mov{8,wa{22,=s_yyy{{end of target code section{7344
{{sub{8,wa{22,=s_aaa{{length of code section{7345
{{add{8,wa{13,num01(xl){{plus original start address{7346
{{mov{11,-(xl){8,wa{{end of original code section{7347
{{mov{11,-(xl){8,wb{{save constant section address{7348
{{mov{8,wb{21,=c_aaa{{start of constants section{7349
{{mov{8,wa{21,=c_yyy{{end of constants section{7350
{{sub{8,wa{8,wb{{length of constants section{7351
{{sub{8,wb{9,(xl){{new c_aaa minus original c_aaa{7352
{{mov{11,-(xl){8,wb{{save constant adjustment{7353
{{add{8,wa{13,num01(xl){{length plus original start adr{7354
{{mov{11,-(xl){8,wa{{save as end of original constants{7355
{{mov{11,-(xl){8,wc{{save working globals address{7356
{{mov{8,wc{20,=g_aaa{{start of working globals section{7357
{{mov{8,wa{20,=w_yyy{{end of working section{7358
{{sub{8,wa{8,wc{{length of working globals{7359
{{sub{8,wc{9,(xl){{new g_aaa minus original g_aaa{7360
{{mov{11,-(xl){8,wc{{save working globals adjustment{7361
{{add{8,wa{13,num01(xl){{length plus original start adr{7362
{{mov{11,-(xl){8,wa{{save as end of working globals{7363
{{mov{8,wb{3,statb{{old start of static region{7364
{{mov{11,-(xl){8,wb{{save{7365
{{sub{7,xr{8,wb{{compute adjustment{7366
{{mov{11,-(xl){7,xr{{save new statb minus old statb{7367
{{mov{11,-(xl){3,state{{old end of static region{7368
{{mov{8,wb{3,dnamb{{old start of dynamic region{7369
{{mov{11,-(xl){8,wb{{save{7370
{{scp{8,wa{{{new start of dynamic{7371
{{sub{8,wa{8,wb{{compute adjustment{7372
{{mov{11,-(xl){8,wa{{save new dnamb minus old dnamb{7373
{{mov{8,wc{3,dnamp{{old end of dynamic region in use{7374
{{mov{11,-(xl){8,wc{{save as end of old dynamic region{7375
{{exi{{{{{7376
{{enp{{{{{7377
{{ejc{{{{{7378
*      reldn -- relocate pointers in the dynamic region
*      (xl)                  list of boundaries and adjustments
*      (xr)                  ptr to first location to process
*      (wc)                  ptr past last location to process
*      jsr  reldn            call to process blocks in dynamic
*      (wa,wb,wc,xr)         destroyed
*      processes all blocks in the dynamic region.  within a
*      block, pointers to the code section, constant section,
*      working globals section, static region, and dynamic
*      region are relocated as needed.
{reldn{prc{25,e{1,0{{entry point{7393
{{mov{3,rldcd{13,rlcda(xl){{save code adjustment{7394
{{mov{3,rldst{13,rlsta(xl){{save static adjustment{7395
{{mov{3,rldls{7,xl{{save list pointer{7396
*      merge here to process the next block in dynamic
{rld01{add{9,(xr){3,rldcd{{adjust block type word{7400
{{mov{7,xl{9,(xr){{load block type word{7401
{{lei{7,xl{{{load entry point id (bl_xx){7402
*      block type switch. note that blocks with no relocatable
*      fields just return to rld05 to continue to next block.
*      note that dfblks do not appear in dynamic, only in static.
*      ccblks and cmblks are not live when a save file is
*      created, and can be skipped.
*      further note:  static blocks other than vrblks discovered
*      while scanning dynamic must be adjusted at this time.
*      see processing of ffblk for example.
{{ejc{{{{{7415
*      reldn (continued)
{{bsw{7,xl{2,bl___{{switch on block type{7419
{{iff{2,bl_ar{6,rld03{{arblk{7456
{{iff{2,bl_cd{6,rld07{{cdblk{7456
{{iff{2,bl_ex{6,rld10{{exblk{7456
{{iff{2,bl_ic{6,rld05{{icblk{7456
{{iff{2,bl_nm{6,rld13{{nmblk{7456
{{iff{2,bl_p0{6,rld13{{p0blk{7456
{{iff{2,bl_p1{6,rld14{{p1blk{7456
{{iff{2,bl_p2{6,rld14{{p2blk{7456
{{iff{2,bl_rc{6,rld05{{rcblk{7456
{{iff{2,bl_sc{6,rld05{{scblk{7456
{{iff{2,bl_se{6,rld13{{seblk{7456
{{iff{2,bl_tb{6,rld17{{tbblk{7456
{{iff{2,bl_vc{6,rld17{{vcblk{7456
{{iff{2,bl_xn{6,rld05{{xnblk{7456
{{iff{2,bl_xr{6,rld20{{xrblk{7456
{{iff{2,bl_bc{6,rld05{{bcblk - dummy to fill out iffs{7456
{{iff{2,bl_pd{6,rld15{{pdblk{7456
{{iff{2,bl_tr{6,rld19{{trblk{7456
{{iff{2,bl_bf{6,rld05{{bfblk{7456
{{iff{2,bl_cc{6,rld05{{ccblk{7456
{{iff{2,bl_cm{6,rld05{{cmblk{7456
{{iff{2,bl_ct{6,rld05{{ctblk{7456
{{iff{2,bl_df{6,rld05{{dfblk{7456
{{iff{2,bl_ef{6,rld08{{efblk{7456
{{iff{2,bl_ev{6,rld09{{evblk{7456
{{iff{2,bl_ff{6,rld11{{ffblk{7456
{{iff{2,bl_kv{6,rld13{{kvblk{7456
{{iff{2,bl_pf{6,rld16{{pfblk{7456
{{iff{2,bl_te{6,rld18{{teblk{7456
{{esw{{{{end of jump table{7456
*      arblk
{rld03{mov{8,wa{13,arlen(xr){{load length{7460
{{mov{8,wb{13,arofs(xr){{set offset to 1st reloc fld (arpro){7461
*      merge here to process pointers in a block
*      (xr)                  ptr to current block
*      (wc)                  ptr past last location to process
*      (wa)                  length (reloc flds + flds at start)
*      (wb)                  offset to first reloc field
{rld04{add{8,wa{7,xr{{point past last reloc field{7470
{{add{8,wb{7,xr{{point to first reloc field{7471
{{mov{7,xl{3,rldls{{point to list of bounds{7472
{{jsr{6,relaj{{{adjust pointers{7473
{{ejc{{{{{7474
*      reldn (continued)
*      merge here to advance to next block
*      (xr)                  ptr to current block
*      (wc)                  ptr past last location to process
{rld05{mov{8,wa{9,(xr){{block type word{7484
{{jsr{6,blkln{{{get length of block{7485
{{add{7,xr{8,wa{{point to next block{7486
{{blt{7,xr{8,wc{6,rld01{continue if more to process{7487
{{mov{7,xl{3,rldls{{restore xl{7488
{{exi{{{{return to caller if done{7489
*      cdblk
{rld07{mov{8,wa{13,cdlen(xr){{load length{7502
{{mov{8,wb{19,*cdfal{{set offset{7503
{{bne{9,(xr){22,=b_cdc{6,rld04{jump back if not complex goto{7504
{{mov{8,wb{19,*cdcod{{do not process cdfal word{7505
{{brn{6,rld04{{{jump back{7506
*      efblk
*      if the efcod word points to an xnblk, the xnblk type
*      word will not be adjusted.  since this is implementation
*      dependent, we will not worry about it.
{rld08{mov{8,wa{19,*efrsl{{set length{7514
{{mov{8,wb{19,*efcod{{and offset{7515
{{brn{6,rld04{{{all set{7516
*      evblk
{rld09{mov{8,wa{19,*offs3{{point past third field{7520
{{mov{8,wb{19,*evexp{{set offset{7521
{{brn{6,rld04{{{all set{7522
*      exblk
{rld10{mov{8,wa{13,exlen(xr){{load length{7526
{{mov{8,wb{19,*exflc{{set offset{7527
{{brn{6,rld04{{{jump back{7528
{{ejc{{{{{7529
*      reldn (continued)
*      ffblk
*      this block contains a ptr to a dfblk in the static rgn.
*      because there are multiple ffblks pointing to the same
*      dfblk (one for each field name), we only process the
*      dfblk when we encounter the ffblk for the first field.
*      the dfblk in turn contains a pointer to an scblk within
*      static.
{rld11{bne{13,ffofs(xr){19,*pdfld{6,rld12{skip dfblk if not first field{7543
{{mov{11,-(xs){7,xr{{save xr{7544
{{mov{7,xr{13,ffdfp(xr){{load old ptr to dfblk{7545
{{add{7,xr{3,rldst{{current location of dfblk{7546
{{add{9,(xr){3,rldcd{{adjust dfblk type word{7547
{{mov{8,wa{13,dflen(xr){{length of dfblk{7548
{{mov{8,wb{19,*dfnam{{offset to dfnam field{7549
{{add{8,wa{7,xr{{point past last reloc field{7550
{{add{8,wb{7,xr{{point to first reloc field{7551
{{mov{7,xl{3,rldls{{point to list of bounds{7552
{{jsr{6,relaj{{{adjust pointers{7553
{{mov{7,xr{13,dfnam(xr){{pointer to static scblk{7554
{{add{9,(xr){3,rldcd{{adjust scblk type word{7555
{{mov{7,xr{10,(xs)+{{restore ffblk pointer{7556
*      ffblk (continued)
*      merge here to set up for adjustment of ptrs in ffblk
{rld12{mov{8,wa{19,*ffofs{{set length{7562
{{mov{8,wb{19,*ffdfp{{set offset{7563
{{brn{6,rld04{{{all set{7564
*      kvblk, nmblk, p0blk, seblk
{rld13{mov{8,wa{19,*offs2{{point past second field{7568
{{mov{8,wb{19,*offs1{{offset is one (only reloc fld is 2){7569
{{brn{6,rld04{{{all set{7570
*      p1blk, p2blk
*      in p2blks, parm2 contains either a bit mask or the
*      name offset of a variable.  it never requires relocation.
{rld14{mov{8,wa{19,*parm2{{length (parm2 is non-relocatable){7577
{{mov{8,wb{19,*pthen{{set offset{7578
{{brn{6,rld04{{{all set{7579
*      pdblk
*      note that the dfblk pointed to by this pdblk was
*      processed when the ffblk was encountered.  because
*      the data function will be called before any records are
*      defined, the ffblk is encountered before any
*      corresponding pdblk.
{rld15{mov{7,xl{13,pddfp(xr){{load ptr to dfblk{7589
{{add{7,xl{3,rldst{{adjust for static relocation{7590
{{mov{8,wa{13,dfpdl(xl){{get pdblk length{7591
{{mov{8,wb{19,*pddfp{{set offset{7592
{{brn{6,rld04{{{all set{7593
{{ejc{{{{{7594
*      reldn (continued)
*      pfblk
{rld16{add{13,pfvbl(xr){3,rldst{{adjust non-contiguous field{7601
{{mov{8,wa{13,pflen(xr){{get pfblk length{7602
{{mov{8,wb{19,*pfcod{{offset to first reloc{7603
{{brn{6,rld04{{{all set{7604
*      tbblk, vcblk
{rld17{mov{8,wa{13,offs2(xr){{load length{7608
{{mov{8,wb{19,*offs3{{set offset{7609
{{brn{6,rld04{{{jump back{7610
*      teblk
{rld18{mov{8,wa{19,*tesi_{{set length{7614
{{mov{8,wb{19,*tesub{{and offset{7615
{{brn{6,rld04{{{all set{7616
*      trblk
{rld19{mov{8,wa{19,*trsi_{{set length{7620
{{mov{8,wb{19,*trval{{and offset{7621
{{brn{6,rld04{{{all set{7622
*      xrblk
{rld20{mov{8,wa{13,xrlen(xr){{load length{7626
{{mov{8,wb{19,*xrptr{{set offset{7627
{{brn{6,rld04{{{jump back{7628
{{enp{{{{end procedure reldn{7629
{{ejc{{{{{7630
*      reloc -- relocate storage after save file reload
*      (xl)                  list of boundaries and adjustments
*      jsr  reloc            relocate all pointers
*      (wa,wb,wc,xr)         destroyed
*      the list of boundaries and adjustments pointed to by
*      register xl is created by a call to relcr, which should
*      be consulted for information on its structure.
{reloc{prc{25,e{1,0{{entry point{7642
{{mov{7,xr{13,rldys(xl){{old start of dynamic{7643
{{mov{8,wc{13,rldye(xl){{old end of dynamic{7644
{{add{7,xr{13,rldya(xl){{create new start of dynamic{7645
{{add{8,wc{13,rldya(xl){{create new end of dynamic{7646
{{jsr{6,reldn{{{relocate pointers in dynamic{7647
{{jsr{6,relws{{{relocate pointers in working sect{7648
{{jsr{6,relst{{{relocate pointers in static{7649
{{exi{{{{return to caller{7650
{{enp{{{{end procedure reloc{7651
{{ejc{{{{{7652
*      relst -- relocate pointers in the static region
*      (xl)                  list of boundaries and adjustments
*      jsr  relst            call to process blocks in static
*      (wa,wb,wc,xr)         destroyed
*      only vrblks on the hash chain and any profile block are
*      processed.  other static blocks (dfblks) are processed
*      during processing of dynamic blocks.
*      global work locations will be processed at this point,
*      so pointers there can be relied upon.
{relst{prc{25,e{1,0{{entry point{7667
{{mov{7,xr{3,pftbl{{profile table{7668
{{bze{7,xr{6,rls01{{branch if no table allocated{7669
{{add{9,(xr){13,rlcda(xl){{adjust block type word{7670
*      here after dealing with profiler
{rls01{mov{8,wc{3,hshtb{{point to start of hash table{7674
{{mov{8,wb{8,wc{{point to first hash bucket{7675
{{mov{8,wa{3,hshte{{point beyond hash table{7676
{{jsr{6,relaj{{{adjust bucket pointers{7677
*      loop through slots in hash table
{rls02{beq{8,wc{3,hshte{6,rls05{done if none left{7681
{{mov{7,xr{8,wc{{else copy slot pointer{7682
{{ica{8,wc{{{bump slot pointer{7683
{{sub{7,xr{19,*vrnxt{{set offset to merge into loop{7684
*      loop through vrblks on one hash chain
{rls03{mov{7,xr{13,vrnxt(xr){{point to next vrblk on chain{7688
{{bze{7,xr{6,rls02{{jump for next bucket if chain end{7689
{{mov{8,wa{19,*vrlen{{offset of first loc past ptr fields{7690
{{mov{8,wb{19,*vrget{{offset of first location in vrblk{7691
{{bnz{13,vrlen(xr){6,rls04{{jump if not system variable{7692
{{mov{8,wa{19,*vrsi_{{offset to include vrsvp field{7693
*      merge here to process fields of vrblk
{rls04{add{8,wa{7,xr{{create end ptr{7697
{{add{8,wb{7,xr{{create start ptr{7698
{{jsr{6,relaj{{{adjust pointers in vrblk{7699
{{brn{6,rls03{{{check for another vrblk on chain{7700
*      here when all vrblks processed
{rls05{exi{{{{return to caller{7704
{{enp{{{{end procedure relst{7705
{{ejc{{{{{7706
*      relws -- relocate pointers in the working section
*      (xl)                  list of boundaries and adjustments
*      jsr  relws            call to process working section
*      (wa,wb,wc,xr)         destroyed
*      pointers between a_aaa and r_yyy are examined and
*      adjusted if necessary.  the pointer kvrtn is also
*      adjusted although it lies outside this range.
*      dname is explicitly adjusted because the limits
*      on dynamic region in stack are to the area actively
*      in use (between dnamb and dnamp), and dname is outside
*      this range.
{relws{prc{25,e{1,0{{entry point{7722
{{mov{8,wb{20,=a_aaa{{point to start of adjustables{7723
{{mov{8,wa{20,=r_yyy{{point to end of adjustables{7724
{{jsr{6,relaj{{{relocate adjustable pointers{7725
{{add{3,dname{13,rldya(xl){{adjust ptr missed by relaj{7726
{{mov{8,wb{20,=kvrtn{{case of kvrtn{7727
{{mov{8,wa{8,wb{{handled specially{7728
{{ica{8,wa{{{one value to adjust{7729
{{jsr{6,relaj{{{adjust kvrtn{7730
{{exi{{{{return to caller{7731
{{enp{{{{end procedure relws{7732
{{ttl{27,s p i t b o l -- initialization{{{{7734
*      initialisation
*      the following section receives control from the system
*      at the start of a run with the registers set as follows.
*      (wa)                  initial stack pointer
*      (xr)                  points to first word of data area
*      (xl)                  points to last word of data area
{start{prc{25,e{1,0{{entry point{7744
{{mov{3,mxint{8,wb{{{7745
{{mov{4,bitsm{8,wb{{{7746
{{zer{8,wb{{{{7747
*z-
{{mov{7,xs{8,wa{{discard return{7749
{{jsr{6,systm{{{initialise timer{7750
*z+
{{sti{3,timsx{{{store time{7753
{{mov{3,statb{7,xr{{start address of static{7754
{{mov{3,rsmem{19,*e_srs{{reserve memory{7806
{{mov{3,stbas{7,xs{{store stack base{7807
{{sss{3,iniss{{{save s-r stack ptr{7808
*      now convert free store percentage to a suitable factor
*      for easy testing in alloc routine.
{{ldi{4,intvh{{{get 100{7813
{{dvi{4,alfsp{{{form 100 / alfsp{7814
{{sti{3,alfsf{{{store the factor{7815
*      now convert free sediment percentage to a suitable factor
*      for easy testing in gbcol routine.
{{ldi{4,intvh{{{get 100{7821
{{dvi{4,gbsdp{{{form 100 / gbsdp{7822
{{sti{3,gbsed{{{store the factor{7823
*      initialize values for real conversion routine
{{lct{8,wb{18,=cfp_s{{load counter for significant digits{7832
{{ldr{4,reav1{{{load 1.0{7833
*      loop to compute 10**(max number significant digits)
{ini03{mlr{4,reavt{{{* 10.0{7837
{{bct{8,wb{6,ini03{{loop till done{7838
{{str{3,gtssc{{{store 10**(max sig digits){7839
{{ldr{4,reap5{{{load 0.5{7840
{{dvr{3,gtssc{{{compute 0.5*10**(max sig digits){7841
{{str{3,gtsrn{{{store as rounding bias{7842
{{zer{8,wc{{{set to read parameters{7845
{{jsr{6,prpar{{{read them{7846
{{ejc{{{{{7847
*      now compute starting address for dynamic store and if
*      necessary request more memory.
{{sub{7,xl{19,*e_srs{{allow for reserve memory{7852
{{mov{8,wa{3,prlen{{get print buffer length{7853
{{add{8,wa{18,=cfp_a{{add no. of chars in alphabet{7854
{{add{8,wa{18,=nstmx{{add chars for gtstg bfr{7855
{{ctb{8,wa{1,8{{convert to bytes, allowing a margin{7856
{{mov{7,xr{3,statb{{point to static base{7857
{{add{7,xr{8,wa{{increment for above buffers{7858
{{add{7,xr{19,*e_hnb{{increment for hash table{7859
{{add{7,xr{19,*e_sts{{bump for initial static block{7860
{{jsr{6,sysmx{{{get mxlen{7861
{{mov{3,kvmxl{8,wa{{provisionally store as maxlngth{7862
{{mov{3,mxlen{8,wa{{and as mxlen{7863
{{bgt{7,xr{8,wa{6,ini06{skip if static hi exceeds mxlen{7864
{{ctb{8,wa{1,1{{round up and make bigger than mxlen{7865
{{mov{7,xr{8,wa{{use it instead{7866
*      here to store values which mark initial division
*      of data area into static and dynamic
{ini06{mov{3,dnamb{7,xr{{dynamic base adrs{7871
{{mov{3,dnamp{7,xr{{dynamic ptr{7872
{{bnz{8,wa{6,ini07{{skip if non-zero mxlen{7873
{{dca{7,xr{{{point a word in front{7874
{{mov{3,kvmxl{7,xr{{use as maxlngth{7875
{{mov{3,mxlen{7,xr{{and as mxlen{7876
{{ejc{{{{{7877
*      loop here if necessary till enough memory obtained
*      so that dname is above dnamb
{ini07{mov{3,dname{7,xl{{store dynamic end address{7882
{{blt{3,dnamb{7,xl{6,ini09{skip if high enough{7883
{{jsr{6,sysmm{{{request more memory{7884
{{wtb{7,xr{{{get as baus (sgd05){7885
{{add{7,xl{7,xr{{bump by amount obtained{7886
{{bnz{7,xr{6,ini07{{try again{7887
{{mov{8,wa{18,=mxern{{insufficient memory for maxlength{7889
{{zer{8,wb{{{no column number info{7890
{{zer{8,wc{{{no line number info{7891
{{mov{7,xr{18,=stgic{{initial compile stage{7892
{{mov{7,xl{21,=nulls{{no file name{7894
{{jsr{6,sysea{{{advise of error{7896
{{ppm{6,ini08{{{cant use error logic yet{7897
{{brn{6,ini08{{{force termination{7898
*      insert text for error 329 in error message table
{{erb{1,329{26,requested maxlngth too large{{{7902
{ini08{mov{7,xr{21,=endmo{{point to failure message{7904
{{mov{8,wa{4,endml{{message length{7905
{{jsr{6,syspr{{{print it (prtst not yet usable){7906
{{ppm{{{{should not fail{7907
{{zer{7,xl{{{no fcb chain yet{7908
{{mov{8,wb{18,=num10{{set special code value{7909
{{jsr{6,sysej{{{pack up (stopr not yet usable){7910
*      initialise structures at start of static region
{ini09{mov{7,xr{3,statb{{point to static again{7914
{{jsr{6,insta{{{initialize static{7915
*      initialize number of hash headers
{{mov{8,wa{18,=e_hnb{{get number of hash headers{7919
{{mti{8,wa{{{convert to integer{7920
{{sti{3,hshnb{{{store for use by gtnvr procedure{7921
{{lct{8,wa{8,wa{{counter for clearing hash table{7922
{{mov{3,hshtb{7,xr{{pointer to hash table{7923
*      loop to clear hash table
{ini11{zer{10,(xr)+{{{blank a word{7927
{{bct{8,wa{6,ini11{{loop{7928
{{mov{3,hshte{7,xr{{end of hash table adrs is kept{7929
{{mov{3,state{7,xr{{store static end address{7930
*      init table to map statement numbers to source file names
{{mov{8,wc{18,=num01{{table will have only one bucket{7935
{{mov{7,xl{21,=nulls{{default table value{7936
{{mov{3,r_sfc{7,xl{{current source file name{7937
{{jsr{6,tmake{{{create table{7938
{{mov{3,r_sfn{7,xr{{save ptr to table{7939
*      initialize table to detect duplicate include file names
{{mov{8,wc{18,=num01{{table will have only one bucket{7945
{{mov{7,xl{21,=nulls{{default table value{7946
{{jsr{6,tmake{{{create table{7947
{{mov{3,r_inc{7,xr{{save ptr to table{7948
*      initialize array to hold names of nested include files
{{mov{8,wa{18,=ccinm{{maximum nesting level{7953
{{mov{7,xl{21,=nulls{{null string default value{7954
{{jsr{6,vmake{{{create array{7955
{{ppm{{{{{7956
{{mov{3,r_ifa{7,xr{{save ptr to array{7957
*      init array to hold line numbers of nested include files
{{mov{8,wa{18,=ccinm{{maximum nesting level{7961
{{mov{7,xl{21,=inton{{integer one default value{7962
{{jsr{6,vmake{{{create array{7963
{{ppm{{{{{7964
{{mov{3,r_ifl{7,xr{{save ptr to array{7965
*z+
*      initialize variable blocks for input and output
{{mov{7,xl{21,=v_inp{{point to string /input/{7972
{{mov{8,wb{18,=trtin{{trblk type for input{7973
{{jsr{6,inout{{{perform input association{7974
{{mov{7,xl{21,=v_oup{{point to string /output/{7975
{{mov{8,wb{18,=trtou{{trblk type for output{7976
{{jsr{6,inout{{{perform output association{7977
{{mov{8,wc{3,initr{{terminal flag{7978
{{bze{8,wc{6,ini13{{skip if no terminal{7979
{{jsr{6,prpar{{{associate terminal{7980
{{ejc{{{{{7981
*      check for expiry date
{ini13{jsr{6,sysdc{{{call date check{7985
{{mov{3,flptr{7,xs{{in case stack overflows in compiler{7986
*      now compile source input code
{{jsr{6,cmpil{{{call compiler{7990
{{mov{3,r_cod{7,xr{{set ptr to first code block{7991
{{mov{3,r_ttl{21,=nulls{{forget title{7992
{{mov{3,r_stl{21,=nulls{{forget sub-title{7993
{{zer{3,r_cim{{{forget compiler input image{7994
{{zer{3,r_ccb{{{forget interim code block{7995
{{zer{3,cnind{{{in case end occurred with include{7997
{{zer{3,lstid{{{listing include depth{7998
{{zer{7,xl{{{clear dud value{8000
{{zer{8,wb{{{dont shift dynamic store up{8001
{{zer{3,dnams{{{collect sediment too{8003
{{jsr{6,gbcol{{{clear garbage left from compile{8004
{{mov{3,dnams{7,xr{{record new sediment size{8005
{{bnz{3,cpsts{6,inix0{{skip if no listing of comp stats{8009
{{jsr{6,prtpg{{{eject page{8010
*      print compile statistics
{{jsr{6,prtmm{{{print memory usage{8014
{{mti{3,cmerc{{{get count of errors as integer{8015
{{mov{7,xr{21,=encm3{{point to /compile errors/{8016
{{jsr{6,prtmi{{{print it{8017
{{mti{3,gbcnt{{{garbage collection count{8018
{{sbi{4,intv1{{{adjust for unavoidable collect{8019
{{mov{7,xr{21,=stpm5{{point to /storage regenerations/{8020
{{jsr{6,prtmi{{{print gbcol count{8021
{{jsr{6,systm{{{get time{8022
{{sbi{3,timsx{{{get compilation time{8023
{{mov{7,xr{21,=encm4{{point to compilation time (msec)/{8024
{{jsr{6,prtmi{{{print message{8025
{{add{3,lstlc{18,=num05{{bump line count{8026
{{bze{3,headp{6,inix0{{no eject if nothing printed{8028
{{jsr{6,prtpg{{{eject printer{8029
{{ejc{{{{{8031
*      prepare now to start execution
*      set default input record length
{inix0{bgt{3,cswin{18,=iniln{6,inix1{skip if not default -in72 used{8037
{{mov{3,cswin{18,=inils{{else use default record length{8038
*      reset timer
{inix1{jsr{6,systm{{{get time again{8042
{{sti{3,timsx{{{store for end run processing{8043
{{zer{3,gbcnt{{{initialise collect count{8044
{{jsr{6,sysbx{{{call before starting execution{8045
{{add{3,noxeq{3,cswex{{add -noexecute flag{8046
{{bnz{3,noxeq{6,inix2{{jump if execution suppressed{8047
*      merge when listing file set for execution.  also
*      merge here when restarting a save file or load module.
{iniy0{mnz{3,headp{{{mark headers out regardless{8057
{{zer{11,-(xs){{{set failure location on stack{8058
{{mov{3,flptr{7,xs{{save ptr to failure offset word{8059
{{mov{7,xr{3,r_cod{{load ptr to entry code block{8060
{{mov{3,stage{18,=stgxt{{set stage for execute time{8061
{{mov{3,polcs{18,=num01{{reset interface polling interval{8063
{{mov{3,polct{18,=num01{{reset interface polling interval{8064
{{mov{3,pfnte{3,cmpsn{{copy stmts compiled count in case{8068
{{mov{3,pfdmp{3,kvpfl{{start profiling if &profile set{8069
{{jsr{6,systm{{{time yet again{8070
{{sti{3,pfstm{{{{8071
{{jsr{6,stgcc{{{compute stmgo countdown counters{8073
{{bri{9,(xr){{{start xeq with first statement{8074
*      here if execution is suppressed
{inix2{zer{8,wa{{{set abend value to zero{8079
{{mov{8,wb{18,=nini9{{set special code value{8087
{{zer{7,xl{{{no fcb chain{8088
{{jsr{6,sysej{{{end of job, exit to system{8089
{{enp{{{{end procedure start{8090
*      here from osint to restart a save file or load module.
{rstrt{prc{25,e{1,0{{entry point{8094
{{mov{7,xs{3,stbas{{discard return{8095
{{zer{7,xl{{{clear xl{8096
{{brn{6,iniy0{{{resume execution{8097
{{enp{{{{end procedure rstrt{8098
{{ttl{27,s p i t b o l -- snobol4 operator routines{{{{8100
*      this section includes all routines which can be accessed
*      directly from the generated code except system functions.
*      all routines in this section start with a label of the
*      form o_xxx where xxx is three letters. the generated code
*      contains a pointer to the appropriate entry label.
*      since the general form of the generated code consists of
*      pointers to blocks whose first word is the address of the
*      actual entry point label (o_xxx).
*      these routines are in alphabetical order by their
*      entry label names (i.e. by the xxx of the o_xxx name)
*      these routines receive control as follows
*      (cp)                  pointer to next code word
*      (xs)                  current stack pointer
{{ejc{{{{{8120
*      binary plus (addition)
{o_add{ent{{{{entry point{8124
*z+
{{jsr{6,arith{{{fetch arithmetic operands{8126
{{err{1,001{26,addition left operand is not numeric{{{8127
{{err{1,002{26,addition right operand is not numeric{{{8128
{{ppm{6,oadd1{{{jump if real operands{8131
*      here to add two integers
{{adi{13,icval(xl){{{add right operand to left{8136
{{ino{6,exint{{{return integer if no overflow{8137
{{erb{1,003{26,addition caused integer overflow{{{8138
*      here to add two reals
{oadd1{adr{13,rcval(xl){{{add right operand to left{8144
{{rno{6,exrea{{{return real if no overflow{8145
{{erb{1,261{26,addition caused real overflow{{{8146
{{ejc{{{{{8148
*      unary plus (affirmation)
{o_aff{ent{{{{entry point{8152
{{mov{7,xr{10,(xs)+{{load operand{8153
{{jsr{6,gtnum{{{convert to numeric{8154
{{err{1,004{26,affirmation operand is not numeric{{{8155
{{mov{11,-(xs){7,xr{{result if converted to numeric{8156
{{lcw{7,xr{{{get next code word{8157
{{bri{9,(xr){{{execute it{8158
{{ejc{{{{{8159
*      binary bar (alternation)
{o_alt{ent{{{{entry point{8163
{{mov{7,xr{10,(xs)+{{load right operand{8164
{{jsr{6,gtpat{{{convert to pattern{8165
{{err{1,005{26,alternation right operand is not pattern{{{8166
*      merge here from special (left alternation) case
{oalt1{mov{8,wb{22,=p_alt{{set pcode for alternative node{8170
{{jsr{6,pbild{{{build alternative node{8171
{{mov{7,xl{7,xr{{save address of alternative node{8172
{{mov{7,xr{10,(xs)+{{load left operand{8173
{{jsr{6,gtpat{{{convert to pattern{8174
{{err{1,006{26,alternation left operand is not pattern{{{8175
{{beq{7,xr{22,=p_alt{6,oalt2{jump if left arg is alternation{8176
{{mov{13,pthen(xl){7,xr{{set left operand as successor{8177
{{mov{11,-(xs){7,xl{{stack result{8178
{{lcw{7,xr{{{get next code word{8179
{{bri{9,(xr){{{execute it{8180
*      come here if left argument is itself an alternation
*      the result is more efficient if we make the replacement
*      (a / b) / c = a / (b / c)
{oalt2{mov{13,pthen(xl){13,parm1(xr){{build the (b / c) node{8188
{{mov{11,-(xs){13,pthen(xr){{set a as new left arg{8189
{{mov{7,xr{7,xl{{set (b / c) as new right arg{8190
{{brn{6,oalt1{{{merge back to build a / (b / c){8191
{{ejc{{{{{8192
*      array reference (multiple subscripts, by name)
{o_amn{ent{{{{entry point{8196
{{lcw{7,xr{{{load number of subscripts{8197
{{mov{8,wb{7,xr{{set flag for by name{8198
{{brn{6,arref{{{jump to array reference routine{8199
{{ejc{{{{{8200
*      array reference (multiple subscripts, by value)
{o_amv{ent{{{{entry point{8204
{{lcw{7,xr{{{load number of subscripts{8205
{{zer{8,wb{{{set flag for by value{8206
{{brn{6,arref{{{jump to array reference routine{8207
{{ejc{{{{{8208
*      array reference (one subscript, by name)
{o_aon{ent{{{{entry point{8212
{{mov{7,xr{9,(xs){{load subscript value{8213
{{mov{7,xl{13,num01(xs){{load array value{8214
{{mov{8,wa{9,(xl){{load first word of array operand{8215
{{beq{8,wa{22,=b_vct{6,oaon2{jump if vector reference{8216
{{beq{8,wa{22,=b_tbt{6,oaon3{jump if table reference{8217
*      here to use central array reference routine
{oaon1{mov{7,xr{18,=num01{{set number of subscripts to one{8221
{{mov{8,wb{7,xr{{set flag for by name{8222
{{brn{6,arref{{{jump to array reference routine{8223
*      here if we have a vector reference
{oaon2{bne{9,(xr){22,=b_icl{6,oaon1{use long routine if not integer{8227
{{ldi{13,icval(xr){{{load integer subscript value{8228
{{mfi{8,wa{6,exfal{{copy as address int, fail if ovflo{8229
{{bze{8,wa{6,exfal{{fail if zero{8230
{{add{8,wa{18,=vcvlb{{compute offset in words{8231
{{wtb{8,wa{{{convert to bytes{8232
{{mov{9,(xs){8,wa{{complete name on stack{8233
{{blt{8,wa{13,vclen(xl){6,oaon4{exit if subscript not too large{8234
{{brn{6,exfal{{{else fail{8235
*      here for table reference
{oaon3{mnz{8,wb{{{set flag for name reference{8239
{{jsr{6,tfind{{{locate/create table element{8240
{{ppm{6,exfal{{{fail if access fails{8241
{{mov{13,num01(xs){7,xl{{store name base on stack{8242
{{mov{9,(xs){8,wa{{store name offset on stack{8243
*      here to exit with result on stack
{oaon4{lcw{7,xr{{{result on stack, get code word{8247
{{bri{9,(xr){{{execute next code word{8248
{{ejc{{{{{8249
*      array reference (one subscript, by value)
{o_aov{ent{{{{entry point{8253
{{mov{7,xr{10,(xs)+{{load subscript value{8254
{{mov{7,xl{10,(xs)+{{load array value{8255
{{mov{8,wa{9,(xl){{load first word of array operand{8256
{{beq{8,wa{22,=b_vct{6,oaov2{jump if vector reference{8257
{{beq{8,wa{22,=b_tbt{6,oaov3{jump if table reference{8258
*      here to use central array reference routine
{oaov1{mov{11,-(xs){7,xl{{restack array value{8262
{{mov{11,-(xs){7,xr{{restack subscript{8263
{{mov{7,xr{18,=num01{{set number of subscripts to one{8264
{{zer{8,wb{{{set flag for value call{8265
{{brn{6,arref{{{jump to array reference routine{8266
*      here if we have a vector reference
{oaov2{bne{9,(xr){22,=b_icl{6,oaov1{use long routine if not integer{8270
{{ldi{13,icval(xr){{{load integer subscript value{8271
{{mfi{8,wa{6,exfal{{move as one word int, fail if ovflo{8272
{{bze{8,wa{6,exfal{{fail if zero{8273
{{add{8,wa{18,=vcvlb{{compute offset in words{8274
{{wtb{8,wa{{{convert to bytes{8275
{{bge{8,wa{13,vclen(xl){6,exfal{fail if subscript too large{8276
{{jsr{6,acess{{{access value{8277
{{ppm{6,exfal{{{fail if access fails{8278
{{mov{11,-(xs){7,xr{{stack result{8279
{{lcw{7,xr{{{get next code word{8280
{{bri{9,(xr){{{execute it{8281
*      here for table reference by value
{oaov3{zer{8,wb{{{set flag for value reference{8285
{{jsr{6,tfind{{{call table search routine{8286
{{ppm{6,exfal{{{fail if access fails{8287
{{mov{11,-(xs){7,xr{{stack result{8288
{{lcw{7,xr{{{get next code word{8289
{{bri{9,(xr){{{execute it{8290
{{ejc{{{{{8291
*      assignment
{o_ass{ent{{{{entry point{8295
*      o_rpl (pattern replacement) merges here
{oass0{mov{8,wb{10,(xs)+{{load value to be assigned{8299
{{mov{8,wa{10,(xs)+{{load name offset{8300
{{mov{7,xl{9,(xs){{load name base{8301
{{mov{9,(xs){8,wb{{store assigned value as result{8302
{{jsr{6,asign{{{perform assignment{8303
{{ppm{6,exfal{{{fail if assignment fails{8304
{{lcw{7,xr{{{result on stack, get code word{8305
{{bri{9,(xr){{{execute next code word{8306
{{ejc{{{{{8307
*      compilation error
{o_cer{ent{{{{entry point{8311
{{erb{1,007{26,compilation error encountered during execution{{{8312
{{ejc{{{{{8313
*      unary at (cursor assignment)
{o_cas{ent{{{{entry point{8317
{{mov{8,wc{10,(xs)+{{load name offset (parm2){8318
{{mov{7,xr{10,(xs)+{{load name base (parm1){8319
{{mov{8,wb{22,=p_cas{{set pcode for cursor assignment{8320
{{jsr{6,pbild{{{build node{8321
{{mov{11,-(xs){7,xr{{stack result{8322
{{lcw{7,xr{{{get next code word{8323
{{bri{9,(xr){{{execute it{8324
{{ejc{{{{{8325
*      concatenation
{o_cnc{ent{{{{entry point{8329
{{mov{7,xr{9,(xs){{load right argument{8330
{{beq{7,xr{21,=nulls{6,ocnc3{jump if right arg is null{8331
{{mov{7,xl{12,1(xs){{load left argument{8332
{{beq{7,xl{21,=nulls{6,ocnc4{jump if left argument is null{8333
{{mov{8,wa{22,=b_scl{{get constant to test for string{8334
{{bne{8,wa{9,(xl){6,ocnc2{jump if left arg not a string{8335
{{bne{8,wa{9,(xr){6,ocnc2{jump if right arg not a string{8336
*      merge here to concatenate two strings
{ocnc1{mov{8,wa{13,sclen(xl){{load left argument length{8340
{{add{8,wa{13,sclen(xr){{compute result length{8341
{{jsr{6,alocs{{{allocate scblk for result{8342
{{mov{12,1(xs){7,xr{{store result ptr over left argument{8343
{{psc{7,xr{{{prepare to store chars of result{8344
{{mov{8,wa{13,sclen(xl){{get number of chars in left arg{8345
{{plc{7,xl{{{prepare to load left arg chars{8346
{{mvc{{{{move characters of left argument{8347
{{mov{7,xl{10,(xs)+{{load right arg pointer, pop stack{8348
{{mov{8,wa{13,sclen(xl){{load number of chars in right arg{8349
{{plc{7,xl{{{prepare to load right arg chars{8350
{{mvc{{{{move characters of right argument{8351
{{zer{7,xl{{{clear garbage value in xl{8352
{{lcw{7,xr{{{result on stack, get code word{8353
{{bri{9,(xr){{{execute next code word{8354
*      come here if arguments are not both strings
{ocnc2{jsr{6,gtstg{{{convert right arg to string{8358
{{ppm{6,ocnc5{{{jump if right arg is not string{8359
{{mov{7,xl{7,xr{{save right arg ptr{8360
{{jsr{6,gtstg{{{convert left arg to string{8361
{{ppm{6,ocnc6{{{jump if left arg is not a string{8362
{{mov{11,-(xs){7,xr{{stack left argument{8363
{{mov{11,-(xs){7,xl{{stack right argument{8364
{{mov{7,xl{7,xr{{move left arg to proper reg{8365
{{mov{7,xr{9,(xs){{move right arg to proper reg{8366
{{brn{6,ocnc1{{{merge back to concatenate strings{8367
{{ejc{{{{{8368
*      concatenation (continued)
*      come here for null right argument
{ocnc3{ica{7,xs{{{remove right arg from stack{8374
{{lcw{7,xr{{{left argument on stack{8375
{{bri{9,(xr){{{execute next code word{8376
*      here for null left argument
{ocnc4{ica{7,xs{{{unstack one argument{8380
{{mov{9,(xs){7,xr{{store right argument{8381
{{lcw{7,xr{{{result on stack, get code word{8382
{{bri{9,(xr){{{execute next code word{8383
*      here if right argument is not a string
{ocnc5{mov{7,xl{7,xr{{move right argument ptr{8387
{{mov{7,xr{10,(xs)+{{load left arg pointer{8388
*      merge here when left argument is not a string
{ocnc6{jsr{6,gtpat{{{convert left arg to pattern{8392
{{err{1,008{26,concatenation left operand is not a string or pattern{{{8393
{{mov{11,-(xs){7,xr{{save result on stack{8394
{{mov{7,xr{7,xl{{point to right operand{8395
{{jsr{6,gtpat{{{convert to pattern{8396
{{err{1,009{26,concatenation right operand is not a string or pattern{{{8397
{{mov{7,xl{7,xr{{move for pconc{8398
{{mov{7,xr{10,(xs)+{{reload left operand ptr{8399
{{jsr{6,pconc{{{concatenate patterns{8400
{{mov{11,-(xs){7,xr{{stack result{8401
{{lcw{7,xr{{{get next code word{8402
{{bri{9,(xr){{{execute it{8403
{{ejc{{{{{8404
*      complementation
{o_com{ent{{{{entry point{8408
{{mov{7,xr{10,(xs)+{{load operand{8409
{{mov{8,wa{9,(xr){{load type word{8410
*      merge back here after conversion
{ocom1{beq{8,wa{22,=b_icl{6,ocom2{jump if integer{8414
{{beq{8,wa{22,=b_rcl{6,ocom3{jump if real{8417
{{jsr{6,gtnum{{{else convert to numeric{8419
{{err{1,010{26,negation operand is not numeric{{{8420
{{brn{6,ocom1{{{back to check cases{8421
*      here to complement integer
{ocom2{ldi{13,icval(xr){{{load integer value{8425
{{ngi{{{{negate{8426
{{ino{6,exint{{{return integer if no overflow{8427
{{erb{1,011{26,negation caused integer overflow{{{8428
*      here to complement real
{ocom3{ldr{13,rcval(xr){{{load real value{8434
{{ngr{{{{negate{8435
{{brn{6,exrea{{{return real result{8436
{{ejc{{{{{8438
*      binary slash (division)
{o_dvd{ent{{{{entry point{8442
{{jsr{6,arith{{{fetch arithmetic operands{8443
{{err{1,012{26,division left operand is not numeric{{{8444
{{err{1,013{26,division right operand is not numeric{{{8445
{{ppm{6,odvd2{{{jump if real operands{8448
*      here to divide two integers
{{dvi{13,icval(xl){{{divide left operand by right{8453
{{ino{6,exint{{{result ok if no overflow{8454
{{erb{1,014{26,division caused integer overflow{{{8455
*      here to divide two reals
{odvd2{dvr{13,rcval(xl){{{divide left operand by right{8461
{{rno{6,exrea{{{return real if no overflow{8462
{{erb{1,262{26,division caused real overflow{{{8463
{{ejc{{{{{8465
*      exponentiation
{o_exp{ent{{{{entry point{8469
{{mov{7,xr{10,(xs)+{{load exponent{8470
{{jsr{6,gtnum{{{convert to number{8471
{{err{1,015{26,exponentiation right operand is not numeric{{{8472
{{mov{7,xl{7,xr{{move exponent to xl{8473
{{mov{7,xr{10,(xs)+{{load base{8474
{{jsr{6,gtnum{{{convert to numeric{8475
{{err{1,016{26,exponentiation left operand is not numeric{{{8476
{{beq{9,(xl){22,=b_rcl{6,oexp7{jump if real exponent{8479
{{ldi{13,icval(xl){{{load exponent{8481
{{ilt{6,oex12{{{jump if negative exponent{8482
{{beq{8,wa{22,=b_rcl{6,oexp3{jump if base is real{8485
*      here to exponentiate an integer base and integer exponent
{{mfi{8,wa{6,oexp2{{convert exponent to 1 word integer{8490
{{lct{8,wa{8,wa{{set loop counter{8491
{{ldi{13,icval(xr){{{load base as initial value{8492
{{bnz{8,wa{6,oexp1{{jump into loop if non-zero exponent{8493
{{ieq{6,oexp4{{{error if 0**0{8494
{{ldi{4,intv1{{{nonzero**0{8495
{{brn{6,exint{{{give one as result for nonzero**0{8496
*      loop to perform exponentiation
{oex13{mli{13,icval(xr){{{multiply by base{8500
{{iov{6,oexp2{{{jump if overflow{8501
{oexp1{bct{8,wa{6,oex13{{loop if more to go{8502
{{brn{6,exint{{{else return integer result{8503
*      here if integer overflow
{oexp2{erb{1,017{26,exponentiation caused integer overflow{{{8507
{{ejc{{{{{8508
*      exponentiation (continued)
*      here to exponentiate a real to an integer power
{oexp3{mfi{8,wa{6,oexp6{{convert exponent to one word{8516
{{lct{8,wa{8,wa{{set loop counter{8517
{{ldr{13,rcval(xr){{{load base as initial value{8518
{{bnz{8,wa{6,oexp5{{jump into loop if non-zero exponent{8519
{{req{6,oexp4{{{error if 0.0**0{8520
{{ldr{4,reav1{{{nonzero**0{8521
{{brn{6,exrea{{{return 1.0 if nonzero**zero{8522
*      here for error of 0**0 or 0.0**0
{oexp4{erb{1,018{26,exponentiation result is undefined{{{8527
*      loop to perform exponentiation
{oex14{mlr{13,rcval(xr){{{multiply by base{8533
{{rov{6,oexp6{{{jump if overflow{8534
{oexp5{bct{8,wa{6,oex14{{loop till computation complete{8535
{{brn{6,exrea{{{then return real result{8536
*      here if real overflow
{oexp6{erb{1,266{26,exponentiation caused real overflow{{{8540
*      here with real exponent in (xl), numeric base in (xr)
{oexp7{beq{9,(xr){22,=b_rcl{6,oexp8{jump if base real{8545
{{ldi{13,icval(xr){{{load integer base{8546
{{itr{{{{convert to real{8547
{{jsr{6,rcbld{{{create real in (xr){8548
*      here with real exponent in (xl)
*      numeric base in (xr) and ra
{oexp8{zer{8,wb{{{set positive result flag{8553
{{ldr{13,rcval(xr){{{load base to ra{8554
{{rne{6,oexp9{{{jump if base non-zero{8555
{{ldr{13,rcval(xl){{{base is zero.  check exponent{8556
{{req{6,oexp4{{{jump if 0.0 ** 0.0{8557
{{ldr{4,reav0{{{0.0 to non-zero exponent yields 0.0{8558
{{brn{6,exrea{{{return zero result{8559
*      here with non-zero base in (xr) and ra, exponent in (xl)
*      a negative base is allowed if the exponent is integral.
{oexp9{rgt{6,oex10{{{jump if base gt 0.0{8565
{{ngr{{{{make base positive{8566
{{jsr{6,rcbld{{{create positive base in (xr){8567
{{ldr{13,rcval(xl){{{examine exponent{8568
{{chp{{{{chop to integral value{8569
{{rti{6,oexp6{{{convert to integer, br if too large{8570
{{sbr{13,rcval(xl){{{chop(exponent) - exponent{8571
{{rne{6,oex11{{{non-integral power with neg base{8572
{{mfi{8,wb{{{record even/odd exponent{8573
{{anb{8,wb{4,bits1{{odd exponent yields negative result{8574
{{ldr{13,rcval(xr){{{restore base to ra{8575
*      here with positive base in ra and (xr), exponent in (xl)
{oex10{lnf{{{{log of base{8579
{{rov{6,oexp6{{{too large{8580
{{mlr{13,rcval(xl){{{times exponent{8581
{{rov{6,oexp6{{{too large{8582
{{etx{{{{e ** (exponent * ln(base)){8583
{{rov{6,oexp6{{{too large{8584
{{bze{8,wb{6,exrea{{if no sign fixup required{8585
{{ngr{{{{negative result needed{8586
{{brn{6,exrea{{{{8587
*      here for non-integral exponent with negative base
{oex11{erb{1,311{26,exponentiation of negative base to non-integral power{{{8591
*      here with negative integer exponent in ia
{oex12{mov{11,-(xs){7,xr{{stack base{8600
{{itr{{{{convert to real exponent{8601
{{jsr{6,rcbld{{{real negative exponent in (xr){8602
{{mov{7,xl{7,xr{{put exponent in xl{8603
{{mov{7,xr{10,(xs)+{{restore base value{8604
{{brn{6,oexp7{{{process real exponent{8605
{{ejc{{{{{8609
*      failure in expression evaluation
*      this entry point is used if the evaluation of an
*      expression, initiated by the evalx procedure, fails.
*      control is returned to an appropriate point in evalx.
{o_fex{ent{{{{entry point{8617
{{brn{6,evlx6{{{jump to failure loc in evalx{8618
{{ejc{{{{{8619
*      failure during evaluation of a complex or direct goto
{o_fif{ent{{{{entry point{8623
{{erb{1,020{26,goto evaluation failure{{{8624
{{ejc{{{{{8625
*      function call (more than one argument)
{o_fnc{ent{{{{entry point{8629
{{lcw{8,wa{{{load number of arguments{8630
{{lcw{7,xr{{{load function vrblk pointer{8631
{{mov{7,xl{13,vrfnc(xr){{load function pointer{8632
{{bne{8,wa{13,fargs(xl){6,cfunc{use central routine if wrong num{8633
{{bri{9,(xl){{{jump to function if arg count ok{8634
{{ejc{{{{{8635
*      function name error
{o_fne{ent{{{{entry point{8639
{{lcw{8,wa{{{get next code word{8640
{{bne{8,wa{21,=ornm_{6,ofne1{fail if not evaluating expression{8641
{{bze{13,num02(xs){6,evlx3{{ok if expr. was wanted by value{8642
*      here for error
{ofne1{erb{1,021{26,function called by name returned a value{{{8646
{{ejc{{{{{8647
*      function call (single argument)
{o_fns{ent{{{{entry point{8651
{{lcw{7,xr{{{load function vrblk pointer{8652
{{mov{8,wa{18,=num01{{set number of arguments to one{8653
{{mov{7,xl{13,vrfnc(xr){{load function pointer{8654
{{bne{8,wa{13,fargs(xl){6,cfunc{use central routine if wrong num{8655
{{bri{9,(xl){{{jump to function if arg count ok{8656
{{ejc{{{{{8657
*      call to undefined function
{o_fun{ent{{{{entry point{8660
{{erb{1,022{26,undefined function called{{{8661
{{ejc{{{{{8662
*      execute complex goto
{o_goc{ent{{{{entry point{8666
{{mov{7,xr{13,num01(xs){{load name base pointer{8667
{{bhi{7,xr{3,state{6,ogoc1{jump if not natural variable{8668
{{add{7,xr{19,*vrtra{{else point to vrtra field{8669
{{bri{9,(xr){{{and jump through it{8670
*      here if goto operand is not natural variable
{ogoc1{erb{1,023{26,goto operand is not a natural variable{{{8674
{{ejc{{{{{8675
*      execute direct goto
{o_god{ent{{{{entry point{8679
{{mov{7,xr{9,(xs){{load operand{8680
{{mov{8,wa{9,(xr){{load first word{8681
{{beq{8,wa{22,=b_cds{6,bcds0{jump if code block to code routine{8682
{{beq{8,wa{22,=b_cdc{6,bcdc0{jump if code block to code routine{8683
{{erb{1,024{26,goto operand in direct goto is not code{{{8684
{{ejc{{{{{8685
*      set goto failure trap
*      this routine is executed at the start of a complex or
*      direct failure goto to trap a subsequent fail (see exfal)
{o_gof{ent{{{{entry point{8692
{{mov{7,xr{3,flptr{{point to fail offset on stack{8693
{{ica{9,(xr){{{point failure to o_fif word{8694
{{icp{{{{point to next code word{8695
{{lcw{7,xr{{{fetch next code word{8696
{{bri{9,(xr){{{execute it{8697
{{ejc{{{{{8698
*      binary dollar (immediate assignment)
*      the pattern built by binary dollar is a compound pattern.
*      see description at start of pattern match section for
*      details of the structure which is constructed.
{o_ima{ent{{{{entry point{8706
{{mov{8,wb{22,=p_imc{{set pcode for last node{8707
{{mov{8,wc{10,(xs)+{{pop name offset (parm2){8708
{{mov{7,xr{10,(xs)+{{pop name base (parm1){8709
{{jsr{6,pbild{{{build p_imc node{8710
{{mov{7,xl{7,xr{{save ptr to node{8711
{{mov{7,xr{9,(xs){{load left argument{8712
{{jsr{6,gtpat{{{convert to pattern{8713
{{err{1,025{26,immediate assignment left operand is not pattern{{{8714
{{mov{9,(xs){7,xr{{save ptr to left operand pattern{8715
{{mov{8,wb{22,=p_ima{{set pcode for first node{8716
{{jsr{6,pbild{{{build p_ima node{8717
{{mov{13,pthen(xr){10,(xs)+{{set left operand as p_ima successor{8718
{{jsr{6,pconc{{{concatenate to form final pattern{8719
{{mov{11,-(xs){7,xr{{stack result{8720
{{lcw{7,xr{{{get next code word{8721
{{bri{9,(xr){{{execute it{8722
{{ejc{{{{{8723
*      indirection (by name)
{o_inn{ent{{{{entry point{8727
{{mnz{8,wb{{{set flag for result by name{8728
{{brn{6,indir{{{jump to common routine{8729
{{ejc{{{{{8730
*      interrogation
{o_int{ent{{{{entry point{8734
{{mov{9,(xs){21,=nulls{{replace operand with null{8735
{{lcw{7,xr{{{get next code word{8736
{{bri{9,(xr){{{execute next code word{8737
{{ejc{{{{{8738
*      indirection (by value)
{o_inv{ent{{{{entry point{8742
{{zer{8,wb{{{set flag for by value{8743
{{brn{6,indir{{{jump to common routine{8744
{{ejc{{{{{8745
*      keyword reference (by name)
{o_kwn{ent{{{{entry point{8749
{{jsr{6,kwnam{{{get keyword name{8750
{{brn{6,exnam{{{exit with result name{8751
{{ejc{{{{{8752
*      keyword reference (by value)
{o_kwv{ent{{{{entry point{8756
{{jsr{6,kwnam{{{get keyword name{8757
{{mov{3,dnamp{7,xr{{delete kvblk{8758
{{jsr{6,acess{{{access value{8759
{{ppm{6,exnul{{{dummy (unused) failure return{8760
{{mov{11,-(xs){7,xr{{stack result{8761
{{lcw{7,xr{{{get next code word{8762
{{bri{9,(xr){{{execute it{8763
{{ejc{{{{{8764
*      load expression by name
{o_lex{ent{{{{entry point{8768
{{mov{8,wa{19,*evsi_{{set size of evblk{8769
{{jsr{6,alloc{{{allocate space for evblk{8770
{{mov{9,(xr){22,=b_evt{{set type word{8771
{{mov{13,evvar(xr){21,=trbev{{set dummy trblk pointer{8772
{{lcw{8,wa{{{load exblk pointer{8773
{{mov{13,evexp(xr){8,wa{{set exblk pointer{8774
{{mov{7,xl{7,xr{{move name base to proper reg{8775
{{mov{8,wa{19,*evvar{{set name offset = zero{8776
{{brn{6,exnam{{{exit with name in (xl,wa){8777
{{ejc{{{{{8778
*      load pattern value
{o_lpt{ent{{{{entry point{8782
{{lcw{7,xr{{{load pattern pointer{8783
{{mov{11,-(xs){7,xr{{stack result{8784
{{lcw{7,xr{{{get next code word{8785
{{bri{9,(xr){{{execute it{8786
{{ejc{{{{{8787
*      load variable name
{o_lvn{ent{{{{entry point{8791
{{lcw{8,wa{{{load vrblk pointer{8792
{{mov{11,-(xs){8,wa{{stack vrblk ptr (name base){8793
{{mov{11,-(xs){19,*vrval{{stack name offset{8794
{{lcw{7,xr{{{get next code word{8795
{{bri{9,(xr){{{execute next code word{8796
{{ejc{{{{{8797
*      binary asterisk (multiplication)
{o_mlt{ent{{{{entry point{8801
{{jsr{6,arith{{{fetch arithmetic operands{8802
{{err{1,026{26,multiplication left operand is not numeric{{{8803
{{err{1,027{26,multiplication right operand is not numeric{{{8804
{{ppm{6,omlt1{{{jump if real operands{8807
*      here to multiply two integers
{{mli{13,icval(xl){{{multiply left operand by right{8812
{{ino{6,exint{{{return integer if no overflow{8813
{{erb{1,028{26,multiplication caused integer overflow{{{8814
*      here to multiply two reals
{omlt1{mlr{13,rcval(xl){{{multiply left operand by right{8820
{{rno{6,exrea{{{return real if no overflow{8821
{{erb{1,263{26,multiplication caused real overflow{{{8822
{{ejc{{{{{8824
*      name reference
{o_nam{ent{{{{entry point{8828
{{mov{8,wa{19,*nmsi_{{set length of nmblk{8829
{{jsr{6,alloc{{{allocate nmblk{8830
{{mov{9,(xr){22,=b_nml{{set name block code{8831
{{mov{13,nmofs(xr){10,(xs)+{{set name offset from operand{8832
{{mov{13,nmbas(xr){10,(xs)+{{set name base from operand{8833
{{mov{11,-(xs){7,xr{{stack result{8834
{{lcw{7,xr{{{get next code word{8835
{{bri{9,(xr){{{execute it{8836
{{ejc{{{{{8837
*      negation
*      initial entry
{o_nta{ent{{{{entry point{8843
{{lcw{8,wa{{{load new failure offset{8844
{{mov{11,-(xs){3,flptr{{stack old failure pointer{8845
{{mov{11,-(xs){8,wa{{stack new failure offset{8846
{{mov{3,flptr{7,xs{{set new failure pointer{8847
{{lcw{7,xr{{{get next code word{8848
{{bri{9,(xr){{{execute next code word{8849
*      entry after successful evaluation of operand
{o_ntb{ent{{{{entry point{8853
{{mov{3,flptr{13,num02(xs){{restore old failure pointer{8854
{{brn{6,exfal{{{and fail{8855
*      entry for failure during operand evaluation
{o_ntc{ent{{{{entry point{8859
{{ica{7,xs{{{pop failure offset{8860
{{mov{3,flptr{10,(xs)+{{restore old failure pointer{8861
{{brn{6,exnul{{{exit giving null result{8862
{{ejc{{{{{8863
*      use of undefined operator
{o_oun{ent{{{{entry point{8867
{{erb{1,029{26,undefined operator referenced{{{8868
{{ejc{{{{{8869
*      binary dot (pattern assignment)
*      the pattern built by binary dot is a compound pattern.
*      see description at start of pattern match section for
*      details of the structure which is constructed.
{o_pas{ent{{{{entry point{8877
{{mov{8,wb{22,=p_pac{{load pcode for p_pac node{8878
{{mov{8,wc{10,(xs)+{{load name offset (parm2){8879
{{mov{7,xr{10,(xs)+{{load name base (parm1){8880
{{jsr{6,pbild{{{build p_pac node{8881
{{mov{7,xl{7,xr{{save ptr to node{8882
{{mov{7,xr{9,(xs){{load left operand{8883
{{jsr{6,gtpat{{{convert to pattern{8884
{{err{1,030{26,pattern assignment left operand is not pattern{{{8885
{{mov{9,(xs){7,xr{{save ptr to left operand pattern{8886
{{mov{8,wb{22,=p_paa{{set pcode for p_paa node{8887
{{jsr{6,pbild{{{build p_paa node{8888
{{mov{13,pthen(xr){10,(xs)+{{set left operand as p_paa successor{8889
{{jsr{6,pconc{{{concatenate to form final pattern{8890
{{mov{11,-(xs){7,xr{{stack result{8891
{{lcw{7,xr{{{get next code word{8892
{{bri{9,(xr){{{execute it{8893
{{ejc{{{{{8894
*      pattern match (by name, for replacement)
{o_pmn{ent{{{{entry point{8898
{{zer{8,wb{{{set type code for match by name{8899
{{brn{6,match{{{jump to routine to start match{8900
{{ejc{{{{{8901
*      pattern match (statement)
*      o_pms is used in place of o_pmv when the pattern match
*      occurs at the outer (statement) level since in this
*      case the substring value need not be constructed.
{o_pms{ent{{{{entry point{8909
{{mov{8,wb{18,=num02{{set flag for statement to match{8910
{{brn{6,match{{{jump to routine to start match{8911
{{ejc{{{{{8912
*      pattern match (by value)
{o_pmv{ent{{{{entry point{8916
{{mov{8,wb{18,=num01{{set type code for value match{8917
{{brn{6,match{{{jump to routine to start match{8918
{{ejc{{{{{8919
*      pop top item on stack
{o_pop{ent{{{{entry point{8923
{{ica{7,xs{{{pop top stack entry{8924
{{lcw{7,xr{{{get next code word{8925
{{bri{9,(xr){{{execute next code word{8926
{{ejc{{{{{8927
*      terminate execution (code compiled for end statement)
{o_stp{ent{{{{entry point{8931
{{brn{6,lend0{{{jump to end circuit{8932
{{ejc{{{{{8933
*      return name from expression
*      this entry points is used if the evaluation of an
*      expression, initiated by the evalx procedure, returns
*      a name. control is returned to the proper point in evalx.
{o_rnm{ent{{{{entry point{8940
{{brn{6,evlx4{{{return to evalx procedure{8941
{{ejc{{{{{8942
*      pattern replacement
*      when this routine gets control, the following stack
*      entries have been made (see end of match routine p_nth)
*                            subject name base
*                            subject name offset
*                            initial cursor value
*                            final cursor value
*                            subject string pointer
*      (xs) ---------------- replacement value
{o_rpl{ent{{{{entry point{8956
{{jsr{6,gtstg{{{convert replacement val to string{8957
{{err{1,031{26,pattern replacement right operand is not a string{{{8958
*      get result length and allocate result scblk
{{mov{7,xl{9,(xs){{load subject string pointer{8962
{{add{8,wa{13,sclen(xl){{add subject string length{8967
{{add{8,wa{13,num02(xs){{add starting cursor{8968
{{sub{8,wa{13,num01(xs){{minus final cursor = total length{8969
{{bze{8,wa{6,orpl3{{jump if result is null{8970
{{mov{11,-(xs){7,xr{{restack replacement string{8971
{{jsr{6,alocs{{{allocate scblk for result{8972
{{mov{8,wa{13,num03(xs){{get initial cursor (part 1 len){8973
{{mov{13,num03(xs){7,xr{{stack result pointer{8974
{{psc{7,xr{{{point to characters of result{8975
*      move part 1 (start of subject) to result
{{bze{8,wa{6,orpl1{{jump if first part is null{8979
{{mov{7,xl{13,num01(xs){{else point to subject string{8980
{{plc{7,xl{{{point to subject string chars{8981
{{mvc{{{{move first part to result{8982
{{ejc{{{{{8983
*      pattern replacement (continued)
*      now move in replacement value
{orpl1{mov{7,xl{10,(xs)+{{load replacement string, pop{8988
{{mov{8,wa{13,sclen(xl){{load length{8989
{{bze{8,wa{6,orpl2{{jump if null replacement{8990
{{plc{7,xl{{{else point to chars of replacement{8991
{{mvc{{{{move in chars (part 2){8992
*      now move in remainder of string (part 3)
{orpl2{mov{7,xl{10,(xs)+{{load subject string pointer, pop{8996
{{mov{8,wc{10,(xs)+{{load final cursor, pop{8997
{{mov{8,wa{13,sclen(xl){{load subject string length{8998
{{sub{8,wa{8,wc{{minus final cursor = part 3 length{8999
{{bze{8,wa{6,oass0{{jump to assign if part 3 is null{9000
{{plc{7,xl{8,wc{{else point to last part of string{9001
{{mvc{{{{move part 3 to result{9002
{{brn{6,oass0{{{jump to perform assignment{9003
*      here if result is null
{orpl3{add{7,xs{19,*num02{{pop subject str ptr, final cursor{9007
{{mov{9,(xs){21,=nulls{{set null result{9008
{{brn{6,oass0{{{jump to assign null value{9009
{{ejc{{{{{9028
*      return value from expression
*      this entry points is used if the evaluation of an
*      expression, initiated by the evalx procedure, returns
*      a value. control is returned to the proper point in evalx
{o_rvl{ent{{{{entry point{9036
{{brn{6,evlx3{{{return to evalx procedure{9037
{{ejc{{{{{9038
*      selection
*      initial entry
{o_sla{ent{{{{entry point{9044
{{lcw{8,wa{{{load new failure offset{9045
{{mov{11,-(xs){3,flptr{{stack old failure pointer{9046
{{mov{11,-(xs){8,wa{{stack new failure offset{9047
{{mov{3,flptr{7,xs{{set new failure pointer{9048
{{lcw{7,xr{{{get next code word{9049
{{bri{9,(xr){{{execute next code word{9050
*      entry after successful evaluation of alternative
{o_slb{ent{{{{entry point{9054
{{mov{7,xr{10,(xs)+{{load result{9055
{{ica{7,xs{{{pop fail offset{9056
{{mov{3,flptr{9,(xs){{restore old failure pointer{9057
{{mov{9,(xs){7,xr{{restack result{9058
{{lcw{8,wa{{{load new code offset{9059
{{add{8,wa{3,r_cod{{point to absolute code location{9060
{{lcp{8,wa{{{set new code pointer{9061
{{lcw{7,xr{{{get next code word{9062
{{bri{9,(xr){{{execute next code word{9063
*      entry at start of subsequent alternatives
{o_slc{ent{{{{entry point{9067
{{lcw{8,wa{{{load new fail offset{9068
{{mov{9,(xs){8,wa{{store new fail offset{9069
{{lcw{7,xr{{{get next code word{9070
{{bri{9,(xr){{{execute next code word{9071
*      entry at start of last alternative
{o_sld{ent{{{{entry point{9075
{{ica{7,xs{{{pop failure offset{9076
{{mov{3,flptr{10,(xs)+{{restore old failure pointer{9077
{{lcw{7,xr{{{get next code word{9078
{{bri{9,(xr){{{execute next code word{9079
{{ejc{{{{{9080
*      binary minus (subtraction)
{o_sub{ent{{{{entry point{9084
{{jsr{6,arith{{{fetch arithmetic operands{9085
{{err{1,032{26,subtraction left operand is not numeric{{{9086
{{err{1,033{26,subtraction right operand is not numeric{{{9087
{{ppm{6,osub1{{{jump if real operands{9090
*      here to subtract two integers
{{sbi{13,icval(xl){{{subtract right operand from left{9095
{{ino{6,exint{{{return integer if no overflow{9096
{{erb{1,034{26,subtraction caused integer overflow{{{9097
*      here to subtract two reals
{osub1{sbr{13,rcval(xl){{{subtract right operand from left{9103
{{rno{6,exrea{{{return real if no overflow{9104
{{erb{1,264{26,subtraction caused real overflow{{{9105
{{ejc{{{{{9107
*      dummy operator to return control to trxeq procedure
{o_txr{ent{{{{entry point{9111
{{brn{6,trxq1{{{jump into trxeq procedure{9112
{{ejc{{{{{9113
*      unexpected failure
*      note that if a setexit trap is operating then
*      transfer to system label continue
*      will result in looping here.  difficult to avoid except
*      with a considerable overhead which is not worthwhile or
*      else by a technique such as setting kverl to zero.
{o_unf{ent{{{{entry point{9123
{{erb{1,035{26,unexpected failure in -nofail mode{{{9124
{{ttl{27,s p i t b o l -- block action routines{{{{9125
*      the first word of every block in dynamic storage and the
*      vrget, vrsto and vrtra fields of a vrblk contain a
*      pointer to an entry point in the program. all such entry
*      points are in the following section except those for
*      pattern blocks which are in the pattern matching segment
*      later on (labels of the form p_xxx), and dope vectors
*      (d_xxx) which are in the dope vector section following
*      the pattern routines (dope vectors are used for cmblks).
*      the entry points in this section have labels of the
*      form b_xxy where xx is the two character block type for
*      the corresponding block and y is any letter.
*      in some cases, the pointers serve no other purpose than
*      to identify the block type. in this case the routine
*      is never executed and thus no code is assembled.
*      for each of these entry points corresponding to a block
*      an entry point identification is assembled (bl_xx).
*      the exact entry conditions depend on the manner in
*      which the routine is accessed and are documented with
*      the individual routines as required.
*      the order of these routines is alphabetical with the
*      following exceptions.
*      the routines for seblk and exblk entries occur first so
*      that expressions can be quickly identified from the fact
*      that their routines lie before the symbol b_e__.
*      these are immediately followed by the routine for a trblk
*      so that the test against the symbol b_t__ checks for
*      trapped values or expression values (see procedure evalp)
*      the pattern routines lie after this section so that
*      patterns are identified with routines starting at or
*      after the initial instruction in these routines (p_aaa).
*      the symbol b_aaa defines the first location for block
*      routines and the symbol p_yyy (at the end of the pattern
*      match routines section) defines the last such entry point
{b_aaa{ent{2,bl__i{{{entry point of first block routine{9170
{{ejc{{{{{9171
*      exblk
*      the routine for an exblk loads the expression onto
*      the stack as a value.
*      (xr)                  pointer to exblk
{b_exl{ent{2,bl_ex{{{entry point (exblk){9180
{{mov{11,-(xs){7,xr{{stack result{9181
{{lcw{7,xr{{{get next code word{9182
{{bri{9,(xr){{{execute it{9183
{{ejc{{{{{9184
*      seblk
*      the routine for seblk is accessed from the generated
*      code to load the expression value onto the stack.
{b_sel{ent{2,bl_se{{{entry point (seblk){9191
{{mov{11,-(xs){7,xr{{stack result{9192
{{lcw{7,xr{{{get next code word{9193
{{bri{9,(xr){{{execute it{9194
*      define symbol which marks end of entries for expressions
{b_e__{ent{2,bl__i{{{entry point{9198
{{ejc{{{{{9199
*      trblk
*      the routine for a trblk is never executed
{b_trt{ent{2,bl_tr{{{entry point (trblk){9205
*      define symbol marking end of trap and expression blocks
{b_t__{ent{2,bl__i{{{end of trblk,seblk,exblk entries{9209
{{ejc{{{{{9210
*      arblk
*      the routine for arblk is never executed
{b_art{ent{2,bl_ar{{{entry point (arblk){9216
{{ejc{{{{{9217
*      bcblk
*      the routine for a bcblk is never executed
*      (xr)                  pointer to bcblk
{b_bct{ent{2,bl_bc{{{entry point (bcblk){9225
{{ejc{{{{{9226
*      bfblk
*      the routine for a bfblk is never executed
*      (xr)                  pointer to bfblk
{b_bft{ent{2,bl_bf{{{entry point (bfblk){9234
{{ejc{{{{{9235
*      ccblk
*      the routine for ccblk is never entered
{b_cct{ent{2,bl_cc{{{entry point (ccblk){9241
{{ejc{{{{{9242
*      cdblk
*      the cdblk routines are executed from the generated code.
*      there are two cases depending on the form of cdfal.
*      entry for complex failure code at cdfal
*      (xr)                  pointer to cdblk
{b_cdc{ent{2,bl_cd{{{entry point (cdblk){9253
{bcdc0{mov{7,xs{3,flptr{{pop garbage off stack{9254
{{mov{9,(xs){13,cdfal(xr){{set failure offset{9255
{{brn{6,stmgo{{{enter stmt{9256
{{ejc{{{{{9257
*      cdblk (continued)
*      entry for simple failure code at cdfal
*      (xr)                  pointer to cdblk
{b_cds{ent{2,bl_cd{{{entry point (cdblk){9265
{bcds0{mov{7,xs{3,flptr{{pop garbage off stack{9266
{{mov{9,(xs){19,*cdfal{{set failure offset{9267
{{brn{6,stmgo{{{enter stmt{9268
{{ejc{{{{{9269
*      cmblk
*      the routine for a cmblk is never executed
{b_cmt{ent{2,bl_cm{{{entry point (cmblk){9275
{{ejc{{{{{9276
*      ctblk
*      the routine for a ctblk is never executed
{b_ctt{ent{2,bl_ct{{{entry point (ctblk){9282
{{ejc{{{{{9283
*      dfblk
*      the routine for a dfblk is accessed from the o_fnc entry
*      to call a datatype function and build a pdblk.
*      (xl)                  pointer to dfblk
{b_dfc{ent{2,bl_df{{{entry point{9292
{{mov{8,wa{13,dfpdl(xl){{load length of pdblk{9293
{{jsr{6,alloc{{{allocate pdblk{9294
{{mov{9,(xr){22,=b_pdt{{store type word{9295
{{mov{13,pddfp(xr){7,xl{{store dfblk pointer{9296
{{mov{8,wc{7,xr{{save pointer to pdblk{9297
{{add{7,xr{8,wa{{point past pdblk{9298
{{lct{8,wa{13,fargs(xl){{set to count fields{9299
*      loop to acquire field values from stack
{bdfc1{mov{11,-(xr){10,(xs)+{{move a field value{9303
{{bct{8,wa{6,bdfc1{{loop till all moved{9304
{{mov{7,xr{8,wc{{recall pointer to pdblk{9305
{{brn{6,exsid{{{exit setting id field{9306
{{ejc{{{{{9307
*      efblk
*      the routine for an efblk is passed control form the o_fnc
*      entry to call an external function.
*      (xl)                  pointer to efblk
{b_efc{ent{2,bl_ef{{{entry point (efblk){9316
{{mov{8,wc{13,fargs(xl){{load number of arguments{9319
{{wtb{8,wc{{{convert to offset{9320
{{mov{11,-(xs){7,xl{{save pointer to efblk{9321
{{mov{7,xt{7,xs{{copy pointer to arguments{9322
*      loop to convert arguments
{befc1{ica{7,xt{{{point to next entry{9326
{{mov{7,xr{9,(xs){{load pointer to efblk{9327
{{dca{8,wc{{{decrement eftar offset{9328
{{add{7,xr{8,wc{{point to next eftar entry{9329
{{mov{7,xr{13,eftar(xr){{load eftar entry{9330
{{bsw{7,xr{1,5{{switch on type{9339
{{iff{1,0{6,befc7{{no conversion needed{9357
{{iff{1,1{6,befc2{{string{9357
{{iff{1,2{6,befc3{{integer{9357
{{iff{1,3{6,befc4{{real{9357
{{iff{1,4{6,beff1{{file{9357
{{esw{{{{end of switch on type{9357
*      here to convert to file
{beff1{mov{11,-(xs){7,xt{{save entry pointer{9362
{{mov{3,befof{8,wc{{save offset{9363
{{mov{11,-(xs){9,(xt){{stack arg pointer{9364
{{jsr{6,iofcb{{{convert to fcb{9365
{{err{1,298{26,external function argument is not file{{{9366
{{err{1,298{26,external function argument is not file{{{9367
{{err{1,298{26,external function argument is not file{{{9368
{{mov{7,xr{8,wa{{point to fcb{9369
{{mov{7,xt{10,(xs)+{{reload entry pointer{9370
{{brn{6,befc5{{{jump to merge{9371
*      here to convert to string
{befc2{mov{11,-(xs){9,(xt){{stack arg ptr{9376
{{jsr{6,gtstg{{{convert argument to string{9377
{{err{1,039{26,external function argument is not a string{{{9378
{{brn{6,befc6{{{jump to merge{9379
{{ejc{{{{{9380
*      efblk (continued)
*      here to convert an integer
{befc3{mov{7,xr{9,(xt){{load next argument{9386
{{mov{3,befof{8,wc{{save offset{9387
{{jsr{6,gtint{{{convert to integer{9388
{{err{1,040{26,external function argument is not integer{{{9389
{{brn{6,befc5{{{merge with real case{9392
*      here to convert a real
{befc4{mov{7,xr{9,(xt){{load next argument{9396
{{mov{3,befof{8,wc{{save offset{9397
{{jsr{6,gtrea{{{convert to real{9398
{{err{1,265{26,external function argument is not real{{{9399
*      integer case merges here
{befc5{mov{8,wc{3,befof{{restore offset{9404
*      string merges here
{befc6{mov{9,(xt){7,xr{{store converted result{9408
*      no conversion merges here
{befc7{bnz{8,wc{6,befc1{{loop back if more to go{9412
*      here after converting all the arguments
{{mov{7,xl{10,(xs)+{{restore efblk pointer{9416
{{mov{8,wa{13,fargs(xl){{get number of args{9417
{{jsr{6,sysex{{{call routine to call external fnc{9418
{{ppm{6,exfal{{{fail if failure{9419
{{err{1,327{26,calling external function - not found{{{9420
{{err{1,326{26,calling external function - bad argument type{{{9421
{{wtb{8,wa{{{convert number of args to bytes{9423
{{add{7,xs{8,wa{{remove arguments from stack{9424
{{ejc{{{{{9426
*      efblk (continued)
*      return here with result in xr
*      first defend against non-standard null string returned
{{mov{8,wb{13,efrsl(xl){{get result type id{9434
{{bnz{8,wb{6,befa8{{branch if not unconverted{9435
{{bne{9,(xr){22,=b_scl{6,befc8{jump if not a string{9436
{{bze{13,sclen(xr){6,exnul{{return null if null{9437
*      here if converted result to check for null string
{befa8{bne{8,wb{18,=num01{6,befc8{jump if not a string{9441
{{bze{13,sclen(xr){6,exnul{{return null if null{9442
*      return if result is in dynamic storage
{befc8{blt{7,xr{3,dnamb{6,befc9{jump if not in dynamic storage{9446
{{ble{7,xr{3,dnamp{6,exixr{return result if already dynamic{9447
*      here we copy a result into the dynamic region
{befc9{mov{8,wa{9,(xr){{get possible type word{9451
{{bze{8,wb{6,bef11{{jump if unconverted result{9452
{{mov{8,wa{22,=b_scl{{string{9453
{{beq{8,wb{18,=num01{6,bef10{yes jump{9454
{{mov{8,wa{22,=b_icl{{integer{9455
{{beq{8,wb{18,=num02{6,bef10{yes jump{9456
{{mov{8,wa{22,=b_rcl{{real{9459
*      store type word in result
{bef10{mov{9,(xr){8,wa{{stored before copying to dynamic{9464
*      merge for unconverted result
{bef11{beq{9,(xr){22,=b_scl{6,bef12{branch if string result{9468
{{jsr{6,blkln{{{get length of block{9469
{{mov{7,xl{7,xr{{copy address of old block{9470
{{jsr{6,alloc{{{allocate dynamic block same size{9471
{{mov{11,-(xs){7,xr{{set pointer to new block as result{9472
{{mvw{{{{copy old block to dynamic block{9473
{{zer{7,xl{{{clear garbage value{9474
{{lcw{7,xr{{{get next code word{9475
{{bri{9,(xr){{{execute next code word{9476
*      here to return a string result that was not in dynamic.
*      cannot use the simple word copy above because it will not
*      guarantee zero padding in the last word.
{bef12{mov{7,xl{7,xr{{save source string pointer{9482
{{mov{8,wa{13,sclen(xr){{fetch string length{9483
{{bze{8,wa{6,exnul{{return null string if length zero{9484
{{jsr{6,alocs{{{allocate space for string{9485
{{mov{11,-(xs){7,xr{{save as result pointer{9486
{{psc{7,xr{{{prepare to store chars of result{9487
{{plc{7,xl{{{point to chars in source string{9488
{{mov{8,wa{8,wc{{number of characters to copy{9489
{{mvc{{{{move characters to result string{9490
{{zer{7,xl{{{clear garbage value{9491
{{lcw{7,xr{{{get next code word{9492
{{bri{9,(xr){{{execute next code word{9493
{{ejc{{{{{9495
*      evblk
*      the routine for an evblk is never executed
{b_evt{ent{2,bl_ev{{{entry point (evblk){9501
{{ejc{{{{{9502
*      ffblk
*      the routine for an ffblk is executed from the o_fnc entry
*      to call a field function and extract a field value/name.
*      (xl)                  pointer to ffblk
{b_ffc{ent{2,bl_ff{{{entry point (ffblk){9511
{{mov{7,xr{7,xl{{copy ffblk pointer{9512
{{lcw{8,wc{{{load next code word{9513
{{mov{7,xl{9,(xs){{load pdblk pointer{9514
{{bne{9,(xl){22,=b_pdt{6,bffc2{jump if not pdblk at all{9515
{{mov{8,wa{13,pddfp(xl){{load dfblk pointer from pdblk{9516
*      loop to find correct ffblk for this pdblk
{bffc1{beq{8,wa{13,ffdfp(xr){6,bffc3{jump if this is the correct ffblk{9520
{{mov{7,xr{13,ffnxt(xr){{else link to next ffblk on chain{9521
{{bnz{7,xr{6,bffc1{{loop back if another entry to check{9522
*      here for bad argument
{bffc2{erb{1,041{26,field function argument is wrong datatype{{{9526
{{ejc{{{{{9527
*      ffblk (continued)
*      here after locating correct ffblk
{bffc3{mov{8,wa{13,ffofs(xr){{load field offset{9533
{{beq{8,wc{21,=ofne_{6,bffc5{jump if called by name{9534
{{add{7,xl{8,wa{{else point to value field{9535
{{mov{7,xr{9,(xl){{load value{9536
{{bne{9,(xr){22,=b_trt{6,bffc4{jump if not trapped{9537
{{sub{7,xl{8,wa{{else restore name base,offset{9538
{{mov{9,(xs){8,wc{{save next code word over pdblk ptr{9539
{{jsr{6,acess{{{access value{9540
{{ppm{6,exfal{{{fail if access fails{9541
{{mov{8,wc{9,(xs){{restore next code word{9542
*      here after getting value in (xr), xl is garbage
{bffc4{mov{9,(xs){7,xr{{store value on stack (over pdblk){9546
{{mov{7,xr{8,wc{{copy next code word{9547
{{mov{7,xl{9,(xr){{load entry address{9548
{{bri{7,xl{{{jump to routine for next code word{9549
*      here if called by name
{bffc5{mov{11,-(xs){8,wa{{store name offset (base is set){9553
{{lcw{7,xr{{{get next code word{9554
{{bri{9,(xr){{{execute next code word{9555
{{ejc{{{{{9556
*      icblk
*      the routine for icblk is executed from the generated
*      code to load an integer value onto the stack.
*      (xr)                  pointer to icblk
{b_icl{ent{2,bl_ic{{{entry point (icblk){9565
{{mov{11,-(xs){7,xr{{stack result{9566
{{lcw{7,xr{{{get next code word{9567
{{bri{9,(xr){{{execute it{9568
{{ejc{{{{{9569
*      kvblk
*      the routine for a kvblk is never executed.
{b_kvt{ent{2,bl_kv{{{entry point (kvblk){9575
{{ejc{{{{{9576
*      nmblk
*      the routine for a nmblk is executed from the generated
*      code for the case of loading a name onto the stack
*      where the name is that of a natural variable which can
*      be preevaluated at compile time.
*      (xr)                  pointer to nmblk
{b_nml{ent{2,bl_nm{{{entry point (nmblk){9587
{{mov{11,-(xs){7,xr{{stack result{9588
{{lcw{7,xr{{{get next code word{9589
{{bri{9,(xr){{{execute it{9590
{{ejc{{{{{9591
*      pdblk
*      the routine for a pdblk is never executed
{b_pdt{ent{2,bl_pd{{{entry point (pdblk){9597
{{ejc{{{{{9598
*      pfblk
*      the routine for a pfblk is executed from the entry o_fnc
*      to call a program defined function.
*      (xl)                  pointer to pfblk
*      the following stack entries are made before passing
*      control to the program defined function.
*                            saved value of first argument
*                            .
*                            saved value of last argument
*                            saved value of first local
*                            .
*                            saved value of last local
*                            saved value of function name
*                            saved code block ptr (r_cod)
*                            saved code pointer (-r_cod)
*                            saved value of flprt
*                            saved value of flptr
*                            pointer to pfblk
*      flptr --------------- zero (to be overwritten with offs)
{b_pfc{ent{2,bl_pf{{{entry point (pfblk){9624
{{mov{3,bpfpf{7,xl{{save pfblk ptr (need not be reloc){9625
{{mov{7,xr{7,xl{{copy for the moment{9626
{{mov{7,xl{13,pfvbl(xr){{point to vrblk for function{9627
*      loop to find old value of function
{bpf01{mov{8,wb{7,xl{{save pointer{9631
{{mov{7,xl{13,vrval(xl){{load value{9632
{{beq{9,(xl){22,=b_trt{6,bpf01{loop if trblk{9633
*      set value to null and save old function value
{{mov{3,bpfsv{7,xl{{save old value{9637
{{mov{7,xl{8,wb{{point back to block with value{9638
{{mov{13,vrval(xl){21,=nulls{{set value to null{9639
{{mov{8,wa{13,fargs(xr){{load number of arguments{9640
{{add{7,xr{19,*pfarg{{point to pfarg entries{9641
{{bze{8,wa{6,bpf04{{jump if no arguments{9642
{{mov{7,xt{7,xs{{ptr to last arg{9643
{{wtb{8,wa{{{convert no. of args to bytes offset{9644
{{add{7,xt{8,wa{{point before first arg{9645
{{mov{3,bpfxt{7,xt{{remember arg pointer{9646
{{ejc{{{{{9647
*      pfblk (continued)
*      loop to save old argument values and set new ones
{bpf02{mov{7,xl{10,(xr)+{{load vrblk ptr for next argument{9653
*      loop through possible trblk chain to find value
{bpf03{mov{8,wc{7,xl{{save pointer{9657
{{mov{7,xl{13,vrval(xl){{load next value{9658
{{beq{9,(xl){22,=b_trt{6,bpf03{loop back if trblk{9659
*      save old value and get new value
{{mov{8,wa{7,xl{{keep old value{9663
{{mov{7,xt{3,bpfxt{{point before next stacked arg{9664
{{mov{8,wb{11,-(xt){{load argument (new value){9665
{{mov{9,(xt){8,wa{{save old value{9666
{{mov{3,bpfxt{7,xt{{keep arg ptr for next time{9667
{{mov{7,xl{8,wc{{point back to block with value{9668
{{mov{13,vrval(xl){8,wb{{set new value{9669
{{bne{7,xs{3,bpfxt{6,bpf02{loop if not all done{9670
*      now process locals
{bpf04{mov{7,xl{3,bpfpf{{restore pfblk pointer{9674
{{mov{8,wa{13,pfnlo(xl){{load number of locals{9675
{{bze{8,wa{6,bpf07{{jump if no locals{9676
{{mov{8,wb{21,=nulls{{get null constant{9677
{{lct{8,wa{8,wa{{set local counter{9678
*      loop to process locals
{bpf05{mov{7,xl{10,(xr)+{{load vrblk ptr for next local{9682
*      loop through possible trblk chain to find value
{bpf06{mov{8,wc{7,xl{{save pointer{9686
{{mov{7,xl{13,vrval(xl){{load next value{9687
{{beq{9,(xl){22,=b_trt{6,bpf06{loop back if trblk{9688
*      save old value and set null as new value
{{mov{11,-(xs){7,xl{{stack old value{9692
{{mov{7,xl{8,wc{{point back to block with value{9693
{{mov{13,vrval(xl){8,wb{{set null as new value{9694
{{bct{8,wa{6,bpf05{{loop till all locals processed{9695
{{ejc{{{{{9696
*      pfblk (continued)
*      here after processing arguments and locals
{bpf07{zer{7,xr{{{zero reg xr in case{9705
{{bze{3,kvpfl{6,bpf7c{{skip if profiling is off{9706
{{beq{3,kvpfl{18,=num02{6,bpf7a{branch on type of profile{9707
*      here if &profile = 1
{{jsr{6,systm{{{get current time{9711
{{sti{3,pfetm{{{save for a sec{9712
{{sbi{3,pfstm{{{find time used by caller{9713
{{jsr{6,icbld{{{build into an icblk{9714
{{ldi{3,pfetm{{{reload current time{9715
{{brn{6,bpf7b{{{merge{9716
*       here if &profile = 2
{bpf7a{ldi{3,pfstm{{{get start time of calling stmt{9720
{{jsr{6,icbld{{{assemble an icblk round it{9721
{{jsr{6,systm{{{get now time{9722
*      both types of profile merge here
{bpf7b{sti{3,pfstm{{{set start time of 1st func stmt{9726
{{mnz{3,pffnc{{{flag function entry{9727
*      no profiling merges here
{bpf7c{mov{11,-(xs){7,xr{{stack icblk ptr (or zero){9731
{{mov{8,wa{3,r_cod{{load old code block pointer{9732
{{scp{8,wb{{{get code pointer{9734
{{sub{8,wb{8,wa{{make code pointer into offset{9735
{{mov{7,xl{3,bpfpf{{recall pfblk pointer{9736
{{mov{11,-(xs){3,bpfsv{{stack old value of function name{9737
{{mov{11,-(xs){8,wa{{stack code block pointer{9738
{{mov{11,-(xs){8,wb{{stack code offset{9739
{{mov{11,-(xs){3,flprt{{stack old flprt{9740
{{mov{11,-(xs){3,flptr{{stack old failure pointer{9741
{{mov{11,-(xs){7,xl{{stack pointer to pfblk{9742
{{zer{11,-(xs){{{dummy zero entry for fail return{9743
{{chk{{{{check for stack overflow{9744
{{mov{3,flptr{7,xs{{set new fail return value{9745
{{mov{3,flprt{7,xs{{set new flprt{9746
{{mov{8,wa{3,kvtra{{load trace value{9747
{{add{8,wa{3,kvftr{{add ftrace value{9748
{{bnz{8,wa{6,bpf09{{jump if tracing possible{9749
{{icv{3,kvfnc{{{else bump fnclevel{9750
*      here to actually jump to function
{bpf08{mov{7,xr{13,pfcod(xl){{point to vrblk of entry label{9754
{{mov{7,xr{13,vrlbl(xr){{point to target code{9755
{{beq{7,xr{21,=stndl{6,bpf17{test for undefined label{9756
{{bne{9,(xr){22,=b_trt{6,bpf8a{jump if not trapped{9757
{{mov{7,xr{13,trlbl(xr){{else load ptr to real label code{9758
{bpf8a{bri{9,(xr){{{off to execute function{9759
*      here if tracing is possible
{bpf09{mov{7,xr{13,pfctr(xl){{load possible call trace trblk{9763
{{mov{7,xl{13,pfvbl(xl){{load vrblk pointer for function{9764
{{mov{8,wa{19,*vrval{{set name offset for variable{9765
{{bze{3,kvtra{6,bpf10{{jump if trace mode is off{9766
{{bze{7,xr{6,bpf10{{or if there is no call trace{9767
*      here if call traced
{{dcv{3,kvtra{{{decrement trace count{9771
{{bze{13,trfnc(xr){6,bpf11{{jump if print trace{9772
{{jsr{6,trxeq{{{execute function type trace{9773
{{ejc{{{{{9774
*      pfblk (continued)
*      here to test for ftrace trace
{bpf10{bze{3,kvftr{6,bpf16{{jump if ftrace is off{9780
{{dcv{3,kvftr{{{else decrement ftrace{9781
*      here for print trace
{bpf11{jsr{6,prtsn{{{print statement number{9785
{{jsr{6,prtnm{{{print function name{9786
{{mov{8,wa{18,=ch_pp{{load left paren{9787
{{jsr{6,prtch{{{print left paren{9788
{{mov{7,xl{13,num01(xs){{recover pfblk pointer{9789
{{bze{13,fargs(xl){6,bpf15{{skip if no arguments{9790
{{zer{8,wb{{{else set argument counter{9791
{{brn{6,bpf13{{{jump into loop{9792
*      loop to print argument values
{bpf12{mov{8,wa{18,=ch_cm{{load comma{9796
{{jsr{6,prtch{{{print to separate from last arg{9797
*      merge here first time (no comma required)
{bpf13{mov{9,(xs){8,wb{{save arg ctr (over failoffs is ok){9801
{{wtb{8,wb{{{convert to byte offset{9802
{{add{7,xl{8,wb{{point to next argument pointer{9803
{{mov{7,xr{13,pfarg(xl){{load next argument vrblk ptr{9804
{{sub{7,xl{8,wb{{restore pfblk pointer{9805
{{mov{7,xr{13,vrval(xr){{load next value{9806
{{jsr{6,prtvl{{{print argument value{9807
{{ejc{{{{{9808
*      here after dealing with one argument
{{mov{8,wb{9,(xs){{restore argument counter{9812
{{icv{8,wb{{{increment argument counter{9813
{{blt{8,wb{13,fargs(xl){6,bpf12{loop if more to print{9814
*      merge here in no args case to print paren
{bpf15{mov{8,wa{18,=ch_rp{{load right paren{9818
{{jsr{6,prtch{{{print to terminate output{9819
{{jsr{6,prtnl{{{terminate print line{9820
*      merge here to exit with test for fnclevel trace
{bpf16{icv{3,kvfnc{{{increment fnclevel{9824
{{mov{7,xl{3,r_fnc{{load ptr to possible trblk{9825
{{jsr{6,ktrex{{{call keyword trace routine{9826
*      call function after trace tests complete
{{mov{7,xl{13,num01(xs){{restore pfblk pointer{9830
{{brn{6,bpf08{{{jump back to execute function{9831
*      here if calling a function whose entry label is undefined
{bpf17{mov{3,flptr{13,num02(xs){{reset so exfal can return to evalx{9835
{{erb{1,286{26,function call to undefined entry label{{{9836
{{ejc{{{{{9839
*      rcblk
*      the routine for an rcblk is executed from the generated
*      code to load a real value onto the stack.
*      (xr)                  pointer to rcblk
{b_rcl{ent{2,bl_rc{{{entry point (rcblk){9848
{{mov{11,-(xs){7,xr{{stack result{9849
{{lcw{7,xr{{{get next code word{9850
{{bri{9,(xr){{{execute it{9851
{{ejc{{{{{9853
*      scblk
*      the routine for an scblk is executed from the generated
*      code to load a string value onto the stack.
*      (xr)                  pointer to scblk
{b_scl{ent{2,bl_sc{{{entry point (scblk){9862
{{mov{11,-(xs){7,xr{{stack result{9863
{{lcw{7,xr{{{get next code word{9864
{{bri{9,(xr){{{execute it{9865
{{ejc{{{{{9866
*      tbblk
*      the routine for a tbblk is never executed
{b_tbt{ent{2,bl_tb{{{entry point (tbblk){9872
{{ejc{{{{{9873
*      teblk
*      the routine for a teblk is never executed
{b_tet{ent{2,bl_te{{{entry point (teblk){9879
{{ejc{{{{{9880
*      vcblk
*      the routine for a vcblk is never executed
{b_vct{ent{2,bl_vc{{{entry point (vcblk){9886
{{ejc{{{{{9887
*      vrblk
*      the vrblk routines are executed from the generated code.
*      there are six entries for vrblk covering various cases
{b_vr_{ent{2,bl__i{{{mark start of vrblk entry points{9894
*      entry for vrget (trapped case). this routine is called
*      from the generated code to load the value of a variable.
*      this entry point is used if an access trace or input
*      association is currently active.
*      (xr)                  pointer to vrget field of vrblk
{b_vra{ent{2,bl__i{{{entry point{9903
{{mov{7,xl{7,xr{{copy name base (vrget = 0){9904
{{mov{8,wa{19,*vrval{{set name offset{9905
{{jsr{6,acess{{{access value{9906
{{ppm{6,exfal{{{fail if access fails{9907
{{mov{11,-(xs){7,xr{{stack result{9908
{{lcw{7,xr{{{get next code word{9909
{{bri{9,(xr){{{execute it{9910
{{ejc{{{{{9911
*      vrblk (continued)
*      entry for vrsto (error case. this routine is called from
*      the executed code for an attempt to modify the value
*      of a protected (pattern valued) natural variable.
{b_vre{ent{{{{entry point{9919
{{erb{1,042{26,attempt to change value of protected variable{{{9920
{{ejc{{{{{9921
*      vrblk (continued)
*      entry for vrtra (untrapped case). this routine is called
*      from the executed code to transfer to a label.
*      (xr)                  pointer to vrtra field of vrblk
{b_vrg{ent{{{{entry point{9930
{{mov{7,xr{13,vrlbo(xr){{load code pointer{9931
{{mov{7,xl{9,(xr){{load entry address{9932
{{bri{7,xl{{{jump to routine for next code word{9933
{{ejc{{{{{9934
*      vrblk (continued)
*      entry for vrget (untrapped case). this routine is called
*      from the generated code to load the value of a variable.
*      (xr)                  points to vrget field of vrblk
{b_vrl{ent{{{{entry point{9943
{{mov{11,-(xs){13,vrval(xr){{load value onto stack (vrget = 0){9944
{{lcw{7,xr{{{get next code word{9945
{{bri{9,(xr){{{execute next code word{9946
{{ejc{{{{{9947
*      vrblk (continued)
*      entry for vrsto (untrapped case). this routine is called
*      from the generated code to store the value of a variable.
*      (xr)                  pointer to vrsto field of vrblk
{b_vrs{ent{{{{entry point{9956
{{mov{13,vrvlo(xr){9,(xs){{store value, leave on stack{9957
{{lcw{7,xr{{{get next code word{9958
{{bri{9,(xr){{{execute next code word{9959
{{ejc{{{{{9960
*      vrblk (continued)
*      vrtra (trapped case). this routine is called from the
*      generated code to transfer to a label when a label
*      trace is currently active.
{b_vrt{ent{{{{entry point{9968
{{sub{7,xr{19,*vrtra{{point back to start of vrblk{9969
{{mov{7,xl{7,xr{{copy vrblk pointer{9970
{{mov{8,wa{19,*vrval{{set name offset{9971
{{mov{7,xr{13,vrlbl(xl){{load pointer to trblk{9972
{{bze{3,kvtra{6,bvrt2{{jump if trace is off{9973
{{dcv{3,kvtra{{{else decrement trace count{9974
{{bze{13,trfnc(xr){6,bvrt1{{jump if print trace case{9975
{{jsr{6,trxeq{{{else execute full trace{9976
{{brn{6,bvrt2{{{merge to jump to label{9977
*      here for print trace -- print colon ( label name )
{bvrt1{jsr{6,prtsn{{{print statement number{9981
{{mov{7,xr{7,xl{{copy vrblk pointer{9982
{{mov{8,wa{18,=ch_cl{{colon{9983
{{jsr{6,prtch{{{print it{9984
{{mov{8,wa{18,=ch_pp{{left paren{9985
{{jsr{6,prtch{{{print it{9986
{{jsr{6,prtvn{{{print label name{9987
{{mov{8,wa{18,=ch_rp{{right paren{9988
{{jsr{6,prtch{{{print it{9989
{{jsr{6,prtnl{{{terminate line{9990
{{mov{7,xr{13,vrlbl(xl){{point back to trblk{9991
*      merge here to jump to label
{bvrt2{mov{7,xr{13,trlbl(xr){{load pointer to actual code{9995
{{bri{9,(xr){{{execute statement at label{9996
{{ejc{{{{{9997
*      vrblk (continued)
*      entry for vrsto (trapped case). this routine is called
*      from the generated code to store the value of a variable.
*      this entry is used when a value trace or output
*      association is currently active.
*      (xr)                  pointer to vrsto field of vrblk
{b_vrv{ent{{{{entry point{10008
{{mov{8,wb{9,(xs){{load value (leave copy on stack){10009
{{sub{7,xr{19,*vrsto{{point to vrblk{10010
{{mov{7,xl{7,xr{{copy vrblk pointer{10011
{{mov{8,wa{19,*vrval{{set offset{10012
{{jsr{6,asign{{{call assignment routine{10013
{{ppm{6,exfal{{{fail if assignment fails{10014
{{lcw{7,xr{{{else get next code word{10015
{{bri{9,(xr){{{execute next code word{10016
{{ejc{{{{{10017
*      xnblk
*      the routine for an xnblk is never executed
{b_xnt{ent{2,bl_xn{{{entry point (xnblk){10023
{{ejc{{{{{10024
*      xrblk
*      the routine for an xrblk is never executed
{b_xrt{ent{2,bl_xr{{{entry point (xrblk){10030
*      mark entry address past last block action routine
{b_yyy{ent{2,bl__i{{{last block routine entry point{10034
{{ttl{27,s p i t b o l -- pattern matching routines{{{{10035
*      the following section consists of the pattern matching
*      routines. all pattern nodes contain a pointer (pcode)
*      to one of the routines in this section (p_xxx).
*      note that this section follows the b_xxx routines to
*      enable a fast test for the pattern datatype.
{p_aaa{ent{2,bl__i{{{entry to mark first pattern{10044
*      the entry conditions to the match routine are as follows
*      (see o_pmn, o_pmv, o_pms and procedure match).
*      stack contents.
*                            name base (o_pmn only)
*                            name offset (o_pmn only)
*                            type (0-o_pmn, 1-o_pmv, 2-o_pms)
*      pmhbs --------------- initial cursor (zero)
*                            initial node pointer
*      xs ------------------ =ndabo (anchored), =nduna (unanch)
*      register values.
*           (xs)             set as shown in stack diagram
*           (xr)             pointer to initial pattern node
*           (wb)             initial cursor (zero)
*      global pattern values
*           r_pms            pointer to subject string scblk
*           pmssl            length of subject string in chars
*           pmdfl            dot flag, initially zero
*           pmhbs            set as shown in stack diagram
*      control is passed by branching through the pcode
*      field of the initial pattern node (bri (xr)).
{{ejc{{{{{10074
*      description of algorithm
*      a pattern structure is represented as a linked graph
*      of nodes with the following structure.
*           +------------------------------------+
*           i                pcode               i
*           +------------------------------------+
*           i                pthen               i
*           +------------------------------------+
*           i                parm1               i
*           +------------------------------------+
*           i                parm2               i
*           +------------------------------------+
*      pcode is a pointer to the routine which will perform
*      the match of this particular node type.
*      pthen is a pointer to the successor node. i.e. the node
*      to be matched if the attempt to match this node succeeds.
*      if this is the last node of the pattern pthen points
*      to the dummy node ndnth which initiates pattern exit.
*      parm1, parm2 are parameters whose use varies with the
*      particular node. they are only present if required.
*      alternatives are handled with the special alternative
*      node whose parameter points to the node to be matched
*      if there is a failure on the successor path.
*      the following example illustrates the manner in which
*      the structure is built up. the pattern is
*      (a / b / c) (d / e)   where / is alternation
*      in the diagram, the node marked + represents an
*      alternative node and the dotted line from a + node
*      represents the parameter pointer to the alternative.
*      +---+     +---+     +---+     +---+
*      i + i-----i a i-----i + i-----i d i-----
*      +---+     +---+  i  +---+     +---+
*        .              i    .
*        .              i    .
*      +---+     +---+  i  +---+
*      i + i-----i b i--i  i e i-----
*      +---+     +---+  i  +---+
*        .              i
*        .              i
*      +---+            i
*      i c i------------i
*      +---+
{{ejc{{{{{10128
*      during the match, the registers are used as follows.
*      (xr)                  points to the current node
*      (xl)                  scratch
*      (xs)                  main stack pointer
*      (wb)                  cursor (number of chars matched)
*      (wa,wc)               scratch
*      to keep track of alternatives, the main stack is used as
*      a history stack and contains two word entries.
*      word 1                saved cursor value
*      word 2                node to match on failure
*      when a failure occurs, the most recent entry on this
*      stack is popped off to restore the cursor and point
*      to the node to be matched as an alternative. the entry
*      at the bottom of the stack points to the following
*      special nodes depending on the scan mode.
*      anchored mode         the bottom entry points to the
*                            special node ndabo which causes an
*                            abort. the cursor value stored
*                            with this entry is always zero.
*      unanchored mode       the bottom entry points to the
*                            special node nduna which moves the
*                            anchor point and restarts the match
*                            the cursor saved with this entry
*                            is the number of characters which
*                            lie before the initial anchor point
*                            (i.e. the number of anchor moves).
*                            this entry is three words long and
*                            also contains the initial pattern.
*      entries are made on this history stack by alternative
*      nodes and by some special compound patterns as described
*      later on. the following global locations are used during
*      pattern matching.
*      r_pms                 pointer to subject string
*      pmssl                 length of subject string
*      pmdfl                 flag set non-zero for dot patterns
*      pmhbs                 base ptr for current history stack
*      the following exit points are available to match routines
*      succp                 success in matching current node
*      failp                 failure in matching current node
{{ejc{{{{{10179
*      compound patterns
*      some patterns have implicit alternatives and their
*      representation in the pattern structure consists of a
*      linked set of nodes as indicated by these diagrams.
*      as before, the + represents an alternative node and
*      the dotted line from a + node is the parameter pointer
*      to the alternative pattern.
*      arb
*      ---
*           +---+            this node (p_arb) matches null
*           i b i-----       and stacks cursor, successor ptr,
*           +---+            cursor (copy) and a ptr to ndarc.
*      bal
*      ---
*           +---+            the p_bal node scans a balanced
*           i b i-----       string and then stacks a pointer
*           +---+            to itself on the history stack.
{{ejc{{{{{10207
*      compound pattern structures (continued)
*      arbno
*      -----
*           +---+            this alternative node matches null
*      +----i + i-----       the first time and stacks a pointer
*      i    +---+            to the argument pattern x.
*      i      .
*      i      .
*      i    +---+            node (p_aba) to stack cursor
*      i    i a i            and history stack base ptr.
*      i    +---+
*      i      i
*      i      i
*      i    +---+            this is the argument pattern. as
*      i    i x i            indicated, the successor of the
*      i    +---+            pattern is the p_abc node
*      i      i
*      i      i
*      i    +---+            this node (p_abc) pops pmhbs,
*      +----i c i            stacks old pmhbs and ptr to ndabd
*           +---+            (unless optimization has occurred)
*      structure and execution of this pattern resemble those of
*      recursive pattern matching and immediate assignment.
*      the alternative node at the head of the structure matches
*      null initially but on subsequent failure ensures attempt
*      to match the argument.  before the argument is matched
*      p_aba stacks the cursor, pmhbs and a ptr to p_abb.  if
*      the argument cant be matched , p_abb removes this special
*      stack entry and fails.
*      if argument is matched , p_abc restores the outer pmhbs
*      value (saved by p_aba) .  then if the argument has left
*      alternatives on stack it stacks the inner value of pmhbs
*      and a ptr to ndabd. if argument left nothing on the stack
*      it optimises by removing items stacked by p_aba.  finally
*      a check is made that argument matched more than the null
*      string (check is intended to prevent useless looping).
*      if so the successor is again the alternative node at the
*      head of the structure , ensuring a possible extra attempt
*      to match the arg if necessary.  if not , the successor to
*      alternative is taken so as to terminate the loop.  p_abd
*      restores inner pmhbs ptr and fails , thus trying to match
*      alternatives left by the arbno argument.
{{ejc{{{{{10255
*      compound pattern structures (continued)
*      breakx
*      ------
*           +---+            this node is a break node for
*      +----i b i            the argument to breakx, identical
*      i    +---+            to an ordinary break node.
*      i      i
*      i      i
*      i    +---+            this alternative node stacks a
*      i    i + i-----       pointer to the breakx node to
*      i    +---+            allow for subsequent failure
*      i      .
*      i      .
*      i    +---+            this is the breakx node itself. it
*      +----i x i            matches one character and then
*           +---+            proceeds back to the break node.
*      fence
*      -----
*           +---+            the fence node matches null and
*           i f i-----       stacks a pointer to node ndabo to
*           +---+            abort on a subsequent rematch
*      succeed
*      -------
*           +---+            the node for succeed matches null
*           i s i-----       and stacks a pointer to itself
*           +---+            to repeat the match on a failure.
{{ejc{{{{{10295
*      compound patterns (continued)
*      binary dot (pattern assignment)
*      -------------------------------
*           +---+            this node (p_paa) saves the current
*           i a i            cursor and a pointer to the
*           +---+            special node ndpab on the stack.
*             i
*             i
*           +---+            this is the structure for the
*           i x i            pattern left argument of the
*           +---+            pattern assignment call.
*             i
*             i
*           +---+            this node (p_pac) saves the cursor,
*           i c i-----       a ptr to itself, the cursor (copy)
*           +---+            and a ptr to ndpad on the stack.
*      the function of the match routine for ndpab (p_pab)
*      is simply to unstack itself and fail back onto the stack.
*      the match routine for p_pac also sets the global pattern
*      flag pmdfl non-zero to indicate that pattern assignments
*      may have occured in the pattern match
*      if pmdfl is set at the end of the match (see p_nth), the
*      history stack is scanned for matching ndpab-ndpad pairs
*      and the corresponding pattern assignments are executed.
*      the function of the match routine for ndpad (p_pad)
*      is simply to remove its entry from the stack and fail.
*      this includes removing the special node pointer stored
*      in addition to the standard two entries on the stack.
{{ejc{{{{{10332
*      compount pattern structures (continued)
*      fence (function)
*      ----------------
*           +---+            this node (p_fna) saves the
*           i a i            current history stack and a
*           +---+            pointer to ndfnb on the stack.
*             i
*             i
*           +---+            this is the pattern structure
*           i x i            given as the argument to the
*           +---+            fence function.
*             i
*             i
*           +---+            this node p_fnc restores the outer
*           i c i            history stack ptr saved in p_fna,
*           +---+            and stacks the inner stack base
*                            ptr and a pointer to ndfnd on the
*                            stack.
*      ndfnb (f_fnb) simply is the failure exit for pattern
*      argument failure, and it pops itself and fails onto the
*      stack.
*      the match routine p_fnc allows for an optimization when
*      the fence pattern leaves no alternatives.  in this case,
*      the ndfnb entry is popped, and the match continues.
*      ndfnd (p_fnd) is entered when the pattern fails after
*      going through a non-optimized p_fnc, and it pops the
*      stack back past the innter stack base created by p_fna
{{ejc{{{{{10366
*      compound patterns (continued)
*      expression patterns (recursive pattern matches)
*      -----------------------------------------------
*      initial entry for a pattern node is to the routine p_exa.
*      if the evaluated result of the expression is itself a
*      pattern, then the following steps are taken to arrange
*      for proper recursive processing.
*      1)   a pointer to the current node (the p_exa node) is
*           stored on the history stack with a dummy cursor.
*      2)   a special history stack entry is made in which the
*           node pointer points to ndexb, and the cursor value
*           is the saved value of pmhbs on entry to this node.
*           the match routine for ndexb (p_exb) restores pmhbs
*           from this cursor entry, pops off the p_exa node
*           pointer and fails.
*      3)   the resulting history stack pointer is saved in
*           pmhbs to establish a new level of history stack.
*      after matching a pattern, the end of match routine gets
*      control (p_nth). this routine proceeds as follows.
*      1)   load the current value of pmhbs and recognize the
*           outer level case by the fact that the associated
*           cursor in this case is the pattern match type code
*           which is less than 3. terminate the match in this
*           case and continue execution of the program.
*      2)   otherwise make a special history stack entry in
*           which the node pointer points to the special node
*           ndexc and the cursor is the current value of pmhbs.
*           the match routine for ndexc (p_exc) resets pmhbs to
*           this (inner) value and and then fails.
*      3)   using the history stack entry made on starting the
*           expression (accessible with the current value of
*           pmhbs), restore the p_exa node pointer and the old
*           pmhbs setting. take the successor and continue.
*      an optimization is possible if the expression pattern
*      makes no entries on the history stack. in this case,
*      instead of building the p_exc node in step 2, it is more
*      efficient to simply pop off the p_exb entry and its
*      associated node pointer. the effect is the same.
{{ejc{{{{{10416
*      compound patterns (continued)
*      binary dollar (immediate assignment)
*      ------------------------------------
*           +---+            this node (p_ima) stacks the cursor
*           i a i            pmhbs and a ptr to ndimb and resets
*           +---+            the stack ptr pmhbs.
*             i
*             i
*           +---+            this is the left structure for the
*           i x i            pattern left argument of the
*           +---+            immediate assignment call.
*             i
*             i
*           +---+            this node (p_imc) performs the
*           i c i-----       assignment, pops pmhbs and stacks
*           +---+            the old pmhbs and a ptr to ndimd.
*      the structure and execution of this pattern are similar
*      to those of the recursive expression pattern matching.
*      the match routine for ndimb (p_imb) restores the outer
*      level value of pmhbs, unstacks the saved cursor and fails
*      the match routine p_imc uses the current value of pmhbs
*      to locate the p_imb entry. this entry is used to make
*      the assignment and restore the outer level value of
*      pmhbs. finally, the inner level value of pmhbs and a
*      pointer to the special node ndimd are stacked.
*      the match routine for ndimd (p_imd) restores the inner
*      level value of pmhbs and fails back into the stack.
*      an optimization occurs if the inner pattern makes no
*      entries on the history stack. in this case, p_imc pops
*      the p_imb entry instead of making a p_imd entry.
{{ejc{{{{{10456
*      arbno
*      see compound patterns section for stucture and
*      algorithm for matching this node type.
*      no parameters
{p_aba{ent{2,bl_p0{{{p0blk{10465
{{mov{11,-(xs){8,wb{{stack cursor{10466
{{mov{11,-(xs){7,xr{{stack dummy node ptr{10467
{{mov{11,-(xs){3,pmhbs{{stack old stack base ptr{10468
{{mov{11,-(xs){21,=ndabb{{stack ptr to node ndabb{10469
{{mov{3,pmhbs{7,xs{{store new stack base ptr{10470
{{brn{6,succp{{{succeed{10471
{{ejc{{{{{10472
*      arbno (remove p_aba special stack entry)
*      no parameters (dummy pattern)
{p_abb{ent{{{{entry point{10478
{{mov{3,pmhbs{8,wb{{restore history stack base ptr{10479
{{brn{6,flpop{{{fail and pop dummy node ptr{10480
{{ejc{{{{{10481
*      arbno (check if arg matched null string)
*      no parameters (dummy pattern)
{p_abc{ent{2,bl_p0{{{p0blk{10487
{{mov{7,xt{3,pmhbs{{keep p_abb stack base{10488
{{mov{8,wa{13,num03(xt){{load initial cursor{10489
{{mov{3,pmhbs{13,num01(xt){{restore outer stack base ptr{10490
{{beq{7,xt{7,xs{6,pabc1{jump if no history stack entries{10491
{{mov{11,-(xs){7,xt{{else save inner pmhbs entry{10492
{{mov{11,-(xs){21,=ndabd{{stack ptr to special node ndabd{10493
{{brn{6,pabc2{{{merge{10494
*      optimise case of no extra entries on stack from arbno arg
{pabc1{add{7,xs{19,*num04{{remove ndabb entry and cursor{10498
*      merge to check for matching of null string
{pabc2{bne{8,wa{8,wb{6,succp{allow further attempt if non-null{10502
{{mov{7,xr{13,pthen(xr){{bypass alternative node so as to ...{10503
{{brn{6,succp{{{... refuse further match attempts{10504
{{ejc{{{{{10505
*      arbno (try for alternatives in arbno argument)
*      no parameters (dummy pattern)
{p_abd{ent{{{{entry point{10511
{{mov{3,pmhbs{8,wb{{restore inner stack base ptr{10512
{{brn{6,failp{{{and fail{10513
{{ejc{{{{{10514
*      abort
*      no parameters
{p_abo{ent{2,bl_p0{{{p0blk{10520
{{brn{6,exfal{{{signal statement failure{10521
{{ejc{{{{{10522
*      alternation
*      parm1                 alternative node
{p_alt{ent{2,bl_p1{{{p1blk{10528
{{mov{11,-(xs){8,wb{{stack cursor{10529
{{mov{11,-(xs){13,parm1(xr){{stack pointer to alternative{10530
{{chk{{{{check for stack overflow{10531
{{brn{6,succp{{{if all ok, then succeed{10532
{{ejc{{{{{10533
*      any (one character argument) (1-char string also)
*      parm1                 character argument
{p_ans{ent{2,bl_p1{{{p1blk{10539
{{beq{8,wb{3,pmssl{6,failp{fail if no chars left{10540
{{mov{7,xl{3,r_pms{{else point to subject string{10541
{{plc{7,xl{8,wb{{point to current character{10542
{{lch{8,wa{9,(xl){{load current character{10543
{{bne{8,wa{13,parm1(xr){6,failp{fail if no match{10544
{{icv{8,wb{{{else bump cursor{10545
{{brn{6,succp{{{and succeed{10546
{{ejc{{{{{10547
*      any (multi-character argument case)
*      parm1                 pointer to ctblk
*      parm2                 bit mask to select bit in ctblk
{p_any{ent{2,bl_p2{{{p2blk{10554
*      expression argument case merges here
{pany1{beq{8,wb{3,pmssl{6,failp{fail if no characters left{10558
{{mov{7,xl{3,r_pms{{else point to subject string{10559
{{plc{7,xl{8,wb{{get char ptr to current character{10560
{{lch{8,wa{9,(xl){{load current character{10561
{{mov{7,xl{13,parm1(xr){{point to ctblk{10562
{{wtb{8,wa{{{change to byte offset{10563
{{add{7,xl{8,wa{{point to entry in ctblk{10564
{{mov{8,wa{13,ctchs(xl){{load word from ctblk{10565
{{anb{8,wa{13,parm2(xr){{and with selected bit{10566
{{zrb{8,wa{6,failp{{fail if no match{10567
{{icv{8,wb{{{else bump cursor{10568
{{brn{6,succp{{{and succeed{10569
{{ejc{{{{{10570
*      any (expression argument)
*      parm1                 expression pointer
{p_ayd{ent{2,bl_p1{{{p1blk{10576
{{jsr{6,evals{{{evaluate string argument{10577
{{err{1,043{26,any evaluated argument is not a string{{{10578
{{ppm{6,failp{{{fail if evaluation failure{10579
{{ppm{6,pany1{{{merge multi-char case if ok{10580
{{ejc{{{{{10581
*      p_arb                 initial arb match
*      no parameters
*      the p_arb node is part of a compound pattern structure
*      for an arb pattern (see description of compound patterns)
{p_arb{ent{2,bl_p0{{{p0blk{10590
{{mov{7,xr{13,pthen(xr){{load successor pointer{10591
{{mov{11,-(xs){8,wb{{stack dummy cursor{10592
{{mov{11,-(xs){7,xr{{stack successor pointer{10593
{{mov{11,-(xs){8,wb{{stack cursor{10594
{{mov{11,-(xs){21,=ndarc{{stack ptr to special node ndarc{10595
{{bri{9,(xr){{{execute next node matching null{10596
{{ejc{{{{{10597
*      p_arc                 extend arb match
*      no parameters (dummy pattern)
{p_arc{ent{{{{entry point{10603
{{beq{8,wb{3,pmssl{6,flpop{fail and pop stack to successor{10604
{{icv{8,wb{{{else bump cursor{10605
{{mov{11,-(xs){8,wb{{stack updated cursor{10606
{{mov{11,-(xs){7,xr{{restack pointer to ndarc node{10607
{{mov{7,xr{13,num02(xs){{load successor pointer{10608
{{bri{9,(xr){{{off to reexecute successor node{10609
{{ejc{{{{{10610
*      bal
*      no parameters
*      the p_bal node is part of the compound structure built
*      for bal (see section on compound patterns).
{p_bal{ent{2,bl_p0{{{p0blk{10619
{{zer{8,wc{{{zero parentheses level counter{10620
{{mov{7,xl{3,r_pms{{point to subject string{10621
{{plc{7,xl{8,wb{{point to current character{10622
{{brn{6,pbal2{{{jump into scan loop{10623
*      loop to scan out characters
{pbal1{lch{8,wa{10,(xl)+{{load next character, bump pointer{10627
{{icv{8,wb{{{push cursor for character{10628
{{beq{8,wa{18,=ch_pp{6,pbal3{jump if left paren{10629
{{beq{8,wa{18,=ch_rp{6,pbal4{jump if right paren{10630
{{bze{8,wc{6,pbal5{{else succeed if at outer level{10631
*      here after processing one character
{pbal2{bne{8,wb{3,pmssl{6,pbal1{loop back unless end of string{10635
{{brn{6,failp{{{in which case, fail{10636
*      here on left paren
{pbal3{icv{8,wc{{{bump paren level{10640
{{brn{6,pbal2{{{loop back to check end of string{10641
*      here for right paren
{pbal4{bze{8,wc{6,failp{{fail if no matching left paren{10645
{{dcv{8,wc{{{else decrement level counter{10646
{{bnz{8,wc{6,pbal2{{loop back if not at outer level{10647
*      here after successfully scanning a balanced string
{pbal5{mov{11,-(xs){8,wb{{stack cursor{10651
{{mov{11,-(xs){7,xr{{stack ptr to bal node for extend{10652
{{brn{6,succp{{{and succeed{10653
{{ejc{{{{{10654
*      break (expression argument)
*      parm1                 expression pointer
{p_bkd{ent{2,bl_p1{{{p1blk{10660
{{jsr{6,evals{{{evaluate string expression{10661
{{err{1,044{26,break evaluated argument is not a string{{{10662
{{ppm{6,failp{{{fail if evaluation fails{10663
{{ppm{6,pbrk1{{{merge with multi-char case if ok{10664
{{ejc{{{{{10665
*      break (one character argument)
*      parm1                 character argument
{p_bks{ent{2,bl_p1{{{p1blk{10671
{{mov{8,wc{3,pmssl{{get subject string length{10672
{{sub{8,wc{8,wb{{get number of characters left{10673
{{bze{8,wc{6,failp{{fail if no characters left{10674
{{lct{8,wc{8,wc{{set counter for chars left{10675
{{mov{7,xl{3,r_pms{{point to subject string{10676
{{plc{7,xl{8,wb{{point to current character{10677
*      loop to scan till break character found
{pbks1{lch{8,wa{10,(xl)+{{load next char, bump pointer{10681
{{beq{8,wa{13,parm1(xr){6,succp{succeed if break character found{10682
{{icv{8,wb{{{else push cursor{10683
{{bct{8,wc{6,pbks1{{loop back if more to go{10684
{{brn{6,failp{{{fail if end of string, no break chr{10685
{{ejc{{{{{10686
*      break (multi-character argument)
*      parm1                 pointer to ctblk
*      parm2                 bit mask to select bit column
{p_brk{ent{2,bl_p2{{{p2blk{10693
*      expression argument merges here
{pbrk1{mov{8,wc{3,pmssl{{load subject string length{10697
{{sub{8,wc{8,wb{{get number of characters left{10698
{{bze{8,wc{6,failp{{fail if no characters left{10699
{{lct{8,wc{8,wc{{set counter for characters left{10700
{{mov{7,xl{3,r_pms{{else point to subject string{10701
{{plc{7,xl{8,wb{{point to current character{10702
{{mov{3,psave{7,xr{{save node pointer{10703
*      loop to search for break character
{pbrk2{lch{8,wa{10,(xl)+{{load next char, bump pointer{10707
{{mov{7,xr{13,parm1(xr){{load pointer to ctblk{10708
{{wtb{8,wa{{{convert to byte offset{10709
{{add{7,xr{8,wa{{point to ctblk entry{10710
{{mov{8,wa{13,ctchs(xr){{load ctblk word{10711
{{mov{7,xr{3,psave{{restore node pointer{10712
{{anb{8,wa{13,parm2(xr){{and with selected bit{10713
{{nzb{8,wa{6,succp{{succeed if break character found{10714
{{icv{8,wb{{{else push cursor{10715
{{bct{8,wc{6,pbrk2{{loop back unless end of string{10716
{{brn{6,failp{{{fail if end of string, no break chr{10717
{{ejc{{{{{10718
*      breakx (extension)
*      this is the entry which causes an extension of a breakx
*      match when failure occurs. see section on compound
*      patterns for full details of breakx matching.
*      no parameters
{p_bkx{ent{2,bl_p0{{{p0blk{10728
{{icv{8,wb{{{step cursor past previous break chr{10729
{{brn{6,succp{{{succeed to rematch break{10730
{{ejc{{{{{10731
*      breakx (expression argument)
*      see section on compound patterns for full structure of
*      breakx pattern. the actual character matching uses a
*      break node. however, the entry for the expression
*      argument case is separated to get proper error messages.
*      parm1                 expression pointer
{p_bxd{ent{2,bl_p1{{{p1blk{10742
{{jsr{6,evals{{{evaluate string argument{10743
{{err{1,045{26,breakx evaluated argument is not a string{{{10744
{{ppm{6,failp{{{fail if evaluation fails{10745
{{ppm{6,pbrk1{{{merge with break if all ok{10746
{{ejc{{{{{10747
*      cursor assignment
*      parm1                 name base
*      parm2                 name offset
{p_cas{ent{2,bl_p2{{{p2blk{10754
{{mov{11,-(xs){7,xr{{save node pointer{10755
{{mov{11,-(xs){8,wb{{save cursor{10756
{{mov{7,xl{13,parm1(xr){{load name base{10757
{{mti{8,wb{{{load cursor as integer{10758
{{mov{8,wb{13,parm2(xr){{load name offset{10759
{{jsr{6,icbld{{{get icblk for cursor value{10760
{{mov{8,wa{8,wb{{move name offset{10761
{{mov{8,wb{7,xr{{move value to assign{10762
{{jsr{6,asinp{{{perform assignment{10763
{{ppm{6,flpop{{{fail on assignment failure{10764
{{mov{8,wb{10,(xs)+{{else restore cursor{10765
{{mov{7,xr{10,(xs)+{{restore node pointer{10766
{{brn{6,succp{{{and succeed matching null{10767
{{ejc{{{{{10768
*      expression node (p_exa, initial entry)
*      see compound patterns description for the structure and
*      algorithms for handling expression nodes.
*      parm1                 expression pointer
{p_exa{ent{2,bl_p1{{{p1blk{10777
{{jsr{6,evalp{{{evaluate expression{10778
{{ppm{6,failp{{{fail if evaluation fails{10779
{{blo{8,wa{22,=p_aaa{6,pexa1{jump if result is not a pattern{10780
*      here if result of expression is a pattern
{{mov{11,-(xs){8,wb{{stack dummy cursor{10784
{{mov{11,-(xs){7,xr{{stack ptr to p_exa node{10785
{{mov{11,-(xs){3,pmhbs{{stack history stack base ptr{10786
{{mov{11,-(xs){21,=ndexb{{stack ptr to special node ndexb{10787
{{mov{3,pmhbs{7,xs{{store new stack base pointer{10788
{{mov{7,xr{7,xl{{copy node pointer{10789
{{bri{9,(xr){{{match first node in expression pat{10790
*      here if result of expression is not a pattern
{pexa1{beq{8,wa{22,=b_scl{6,pexa2{jump if it is already a string{10794
{{mov{11,-(xs){7,xl{{else stack result{10795
{{mov{7,xl{7,xr{{save node pointer{10796
{{jsr{6,gtstg{{{convert result to string{10797
{{err{1,046{26,expression does not evaluate to pattern{{{10798
{{mov{8,wc{7,xr{{copy string pointer{10799
{{mov{7,xr{7,xl{{restore node pointer{10800
{{mov{7,xl{8,wc{{copy string pointer again{10801
*      merge here with string pointer in xl
{pexa2{bze{13,sclen(xl){6,succp{{just succeed if null string{10805
{{brn{6,pstr1{{{else merge with string circuit{10806
{{ejc{{{{{10807
*      expression node (p_exb, remove ndexb entry)
*      see compound patterns description for the structure and
*      algorithms for handling expression nodes.
*      no parameters (dummy pattern)
{p_exb{ent{{{{entry point{10816
{{mov{3,pmhbs{8,wb{{restore outer level stack pointer{10817
{{brn{6,flpop{{{fail and pop p_exa node ptr{10818
{{ejc{{{{{10819
*      expression node (p_exc, remove ndexc entry)
*      see compound patterns description for the structure and
*      algorithms for handling expression nodes.
*      no parameters (dummy pattern)
{p_exc{ent{{{{entry point{10828
{{mov{3,pmhbs{8,wb{{restore inner stack base pointer{10829
{{brn{6,failp{{{and fail into expr pattern alternvs{10830
{{ejc{{{{{10831
*      fail
*      no parameters
{p_fal{ent{2,bl_p0{{{p0blk{10837
{{brn{6,failp{{{just signal failure{10838
{{ejc{{{{{10839
*      fence
*      see compound patterns section for the structure and
*      algorithm for matching this node type.
*      no parameters
{p_fen{ent{2,bl_p0{{{p0blk{10848
{{mov{11,-(xs){8,wb{{stack dummy cursor{10849
{{mov{11,-(xs){21,=ndabo{{stack ptr to abort node{10850
{{brn{6,succp{{{and succeed matching null{10851
{{ejc{{{{{10852
*      fence (function)
*      see compound patterns comments at start of this section
*      for details of scheme
*      no parameters
{p_fna{ent{2,bl_p0{{{p0blk{10861
{{mov{11,-(xs){3,pmhbs{{stack current history stack base{10862
{{mov{11,-(xs){21,=ndfnb{{stack indir ptr to p_fnb (failure){10863
{{mov{3,pmhbs{7,xs{{begin new history stack{10864
{{brn{6,succp{{{succeed{10865
{{ejc{{{{{10866
*      fence (function) (reset history stack and fail)
*      no parameters (dummy pattern)
{p_fnb{ent{2,bl_p0{{{p0blk{10872
{{mov{3,pmhbs{8,wb{{restore outer pmhbs stack base{10873
{{brn{6,failp{{{...and fail{10874
{{ejc{{{{{10875
*      fence (function) (make fence trap entry on stack)
*      no parameters (dummy pattern)
{p_fnc{ent{2,bl_p0{{{p0blk{10881
{{mov{7,xt{3,pmhbs{{get inner stack base ptr{10882
{{mov{3,pmhbs{13,num01(xt){{restore outer stack base{10883
{{beq{7,xt{7,xs{6,pfnc1{optimize if no alternatives{10884
{{mov{11,-(xs){7,xt{{else stack inner stack base{10885
{{mov{11,-(xs){21,=ndfnd{{stack ptr to ndfnd{10886
{{brn{6,succp{{{succeed{10887
*      here when fence function left nothing on the stack
{pfnc1{add{7,xs{19,*num02{{pop off p_fnb entry{10891
{{brn{6,succp{{{succeed{10892
{{ejc{{{{{10893
*      fence (function) (skip past alternatives on failure)
*      no parameters (dummy pattern)
{p_fnd{ent{2,bl_p0{{{p0blk{10899
{{mov{7,xs{8,wb{{pop stack to fence() history base{10900
{{brn{6,flpop{{{pop base entry and fail{10901
{{ejc{{{{{10902
*      immediate assignment (initial entry, save current cursor)
*      see compound patterns description for details of the
*      structure and algorithm for matching this node type.
*      no parameters
{p_ima{ent{2,bl_p0{{{p0blk{10911
{{mov{11,-(xs){8,wb{{stack cursor{10912
{{mov{11,-(xs){7,xr{{stack dummy node pointer{10913
{{mov{11,-(xs){3,pmhbs{{stack old stack base pointer{10914
{{mov{11,-(xs){21,=ndimb{{stack ptr to special node ndimb{10915
{{mov{3,pmhbs{7,xs{{store new stack base pointer{10916
{{brn{6,succp{{{and succeed{10917
{{ejc{{{{{10918
*      immediate assignment (remove cursor mark entry)
*      see compound patterns description for details of the
*      structure and algorithms for matching this node type.
*      no parameters (dummy pattern)
{p_imb{ent{{{{entry point{10927
{{mov{3,pmhbs{8,wb{{restore history stack base ptr{10928
{{brn{6,flpop{{{fail and pop dummy node ptr{10929
{{ejc{{{{{10930
*      immediate assignment (perform actual assignment)
*      see compound patterns description for details of the
*      structure and algorithms for matching this node type.
*      parm1                 name base of variable
*      parm2                 name offset of variable
{p_imc{ent{2,bl_p2{{{p2blk{10940
{{mov{7,xt{3,pmhbs{{load pointer to p_imb entry{10941
{{mov{8,wa{8,wb{{copy final cursor{10942
{{mov{8,wb{13,num03(xt){{load initial cursor{10943
{{mov{3,pmhbs{13,num01(xt){{restore outer stack base pointer{10944
{{beq{7,xt{7,xs{6,pimc1{jump if no history stack entries{10945
{{mov{11,-(xs){7,xt{{else save inner pmhbs pointer{10946
{{mov{11,-(xs){21,=ndimd{{and a ptr to special node ndimd{10947
{{brn{6,pimc2{{{merge{10948
*      here if no entries made on history stack
{pimc1{add{7,xs{19,*num04{{remove ndimb entry and cursor{10952
*      merge here to perform assignment
{pimc2{mov{11,-(xs){8,wa{{save current (final) cursor{10956
{{mov{11,-(xs){7,xr{{save current node pointer{10957
{{mov{7,xl{3,r_pms{{point to subject string{10958
{{sub{8,wa{8,wb{{compute substring length{10959
{{jsr{6,sbstr{{{build substring{10960
{{mov{8,wb{7,xr{{move result{10961
{{mov{7,xr{9,(xs){{reload node pointer{10962
{{mov{7,xl{13,parm1(xr){{load name base{10963
{{mov{8,wa{13,parm2(xr){{load name offset{10964
{{jsr{6,asinp{{{perform assignment{10965
{{ppm{6,flpop{{{fail if assignment fails{10966
{{mov{7,xr{10,(xs)+{{else restore node pointer{10967
{{mov{8,wb{10,(xs)+{{restore cursor{10968
{{brn{6,succp{{{and succeed{10969
{{ejc{{{{{10970
*      immediate assignment (remove ndimd entry on failure)
*      see compound patterns description for details of the
*      structure and algorithms for matching this node type.
*      no parameters (dummy pattern)
{p_imd{ent{{{{entry point{10979
{{mov{3,pmhbs{8,wb{{restore inner stack base pointer{10980
{{brn{6,failp{{{and fail{10981
{{ejc{{{{{10982
*      len (integer argument)
*      parm1                 integer argument
{p_len{ent{2,bl_p1{{{p1blk{10988
*      expression argument case merges here
{plen1{add{8,wb{13,parm1(xr){{push cursor indicated amount{10992
{{ble{8,wb{3,pmssl{6,succp{succeed if not off end{10993
{{brn{6,failp{{{else fail{10994
{{ejc{{{{{10995
*      len (expression argument)
*      parm1                 expression pointer
{p_lnd{ent{2,bl_p1{{{p1blk{11001
{{jsr{6,evali{{{evaluate integer argument{11002
{{err{1,047{26,len evaluated argument is not integer{{{11003
{{err{1,048{26,len evaluated argument is negative or too large{{{11004
{{ppm{6,failp{{{fail if evaluation fails{11005
{{ppm{6,plen1{{{merge with normal circuit if ok{11006
{{ejc{{{{{11007
*      notany (expression argument)
*      parm1                 expression pointer
{p_nad{ent{2,bl_p1{{{p1blk{11013
{{jsr{6,evals{{{evaluate string argument{11014
{{err{1,049{26,notany evaluated argument is not a string{{{11015
{{ppm{6,failp{{{fail if evaluation fails{11016
{{ppm{6,pnay1{{{merge with multi-char case if ok{11017
{{ejc{{{{{11018
*      notany (one character argument)
*      parm1                 character argument
{p_nas{ent{2,bl_p1{{{entry point{11024
{{beq{8,wb{3,pmssl{6,failp{fail if no chars left{11025
{{mov{7,xl{3,r_pms{{else point to subject string{11026
{{plc{7,xl{8,wb{{point to current character in strin{11027
{{lch{8,wa{9,(xl){{load current character{11028
{{beq{8,wa{13,parm1(xr){6,failp{fail if match{11029
{{icv{8,wb{{{else bump cursor{11030
{{brn{6,succp{{{and succeed{11031
{{ejc{{{{{11032
*      notany (multi-character string argument)
*      parm1                 pointer to ctblk
*      parm2                 bit mask to select bit column
{p_nay{ent{2,bl_p2{{{p2blk{11039
*      expression argument case merges here
{pnay1{beq{8,wb{3,pmssl{6,failp{fail if no characters left{11043
{{mov{7,xl{3,r_pms{{else point to subject string{11044
{{plc{7,xl{8,wb{{point to current character{11045
{{lch{8,wa{9,(xl){{load current character{11046
{{wtb{8,wa{{{convert to byte offset{11047
{{mov{7,xl{13,parm1(xr){{load pointer to ctblk{11048
{{add{7,xl{8,wa{{point to entry in ctblk{11049
{{mov{8,wa{13,ctchs(xl){{load entry from ctblk{11050
{{anb{8,wa{13,parm2(xr){{and with selected bit{11051
{{nzb{8,wa{6,failp{{fail if character is matched{11052
{{icv{8,wb{{{else bump cursor{11053
{{brn{6,succp{{{and succeed{11054
{{ejc{{{{{11055
*      end of pattern match
*      this routine is entered on successful completion.
*      see description of expression patterns in compound
*      pattern section for handling of recursion in matching.
*      this pattern also results from an attempt to convert the
*      null string to a pattern via convert()
*      no parameters (dummy pattern)
{p_nth{ent{2,bl_p0{{{p0blk (dummy){11068
{{mov{7,xt{3,pmhbs{{load pointer to base of stack{11069
{{mov{8,wa{13,num01(xt){{load saved pmhbs (or pattern type){11070
{{ble{8,wa{18,=num02{6,pnth2{jump if outer level (pattern type){11071
*      here we are at the end of matching an expression pattern
{{mov{3,pmhbs{8,wa{{restore outer stack base pointer{11075
{{mov{7,xr{13,num02(xt){{restore pointer to p_exa node{11076
{{beq{7,xt{7,xs{6,pnth1{jump if no history stack entries{11077
{{mov{11,-(xs){7,xt{{else stack inner stack base ptr{11078
{{mov{11,-(xs){21,=ndexc{{stack ptr to special node ndexc{11079
{{brn{6,succp{{{and succeed{11080
*      here if no history stack entries during pattern
{pnth1{add{7,xs{19,*num04{{remove p_exb entry and node ptr{11084
{{brn{6,succp{{{and succeed{11085
*      here if end of match at outer level
{pnth2{mov{3,pmssl{8,wb{{save final cursor in safe place{11089
{{bze{3,pmdfl{6,pnth6{{jump if no pattern assignments{11090
{{ejc{{{{{11091
*      end of pattern match (continued)
*      now we must perform pattern assignments. this is done by
*      scanning the history stack for matching ndpab-ndpad pairs
{pnth3{dca{7,xt{{{point past cursor entry{11098
{{mov{8,wa{11,-(xt){{load node pointer{11099
{{beq{8,wa{21,=ndpad{6,pnth4{jump if ndpad entry{11100
{{bne{8,wa{21,=ndpab{6,pnth5{jump if not ndpab entry{11101
*      here for ndpab entry, stack initial cursor
*      note that there must be more entries on the stack.
{{mov{11,-(xs){13,num01(xt){{stack initial cursor{11106
{{chk{{{{check for stack overflow{11107
{{brn{6,pnth3{{{loop back if ok{11108
*      here for ndpad entry. the starting cursor from the
*      matching ndpad entry is now the top stack entry.
{pnth4{mov{8,wa{13,num01(xt){{load final cursor{11113
{{mov{8,wb{9,(xs){{load initial cursor from stack{11114
{{mov{9,(xs){7,xt{{save history stack scan ptr{11115
{{sub{8,wa{8,wb{{compute length of string{11116
*      build substring and perform assignment
{{mov{7,xl{3,r_pms{{point to subject string{11120
{{jsr{6,sbstr{{{construct substring{11121
{{mov{8,wb{7,xr{{copy substring pointer{11122
{{mov{7,xt{9,(xs){{reload history stack scan ptr{11123
{{mov{7,xl{13,num02(xt){{load pointer to p_pac node with nam{11124
{{mov{8,wa{13,parm2(xl){{load name offset{11125
{{mov{7,xl{13,parm1(xl){{load name base{11126
{{jsr{6,asinp{{{perform assignment{11127
{{ppm{6,exfal{{{match fails if name eval fails{11128
{{mov{7,xt{10,(xs)+{{else restore history stack ptr{11129
{{ejc{{{{{11130
*      end of pattern match (continued)
*      here check for end of entries
{pnth5{bne{7,xt{7,xs{6,pnth3{loop if more entries to scan{11136
*      here after dealing with pattern assignments
{pnth6{mov{7,xs{3,pmhbs{{wipe out history stack{11140
{{mov{8,wb{10,(xs)+{{load initial cursor{11141
{{mov{8,wc{10,(xs)+{{load match type code{11142
{{mov{8,wa{3,pmssl{{load final cursor value{11143
{{mov{7,xl{3,r_pms{{point to subject string{11144
{{zer{3,r_pms{{{clear subject string ptr for gbcol{11145
{{bze{8,wc{6,pnth7{{jump if call by name{11146
{{beq{8,wc{18,=num02{6,pnth9{exit if statement level call{11147
*      here we have a call by value, build substring
{{sub{8,wa{8,wb{{compute length of string{11151
{{jsr{6,sbstr{{{build substring{11152
{{mov{11,-(xs){7,xr{{stack result{11153
{{lcw{7,xr{{{get next code word{11154
{{bri{9,(xr){{{execute it{11155
*      here for call by name, make stack entries for o_rpl
{pnth7{mov{11,-(xs){8,wb{{stack initial cursor{11159
{{mov{11,-(xs){8,wa{{stack final cursor{11160
*      here with xl pointing to scblk or bcblk
{pnth8{mov{11,-(xs){7,xl{{stack subject pointer{11169
*      here to obey next code word
{pnth9{lcw{7,xr{{{get next code word{11173
{{bri{9,(xr){{{execute next code word{11174
{{ejc{{{{{11175
*      pos (integer argument)
*      parm1                 integer argument
{p_pos{ent{2,bl_p1{{{p1blk{11181
*      optimize pos if it is the first pattern element,
*      unanchored mode, cursor is zero and pos argument
*      is not beyond end of string.  force cursor position
*      and number of unanchored moves.
*      this optimization is performed invisible provided
*      the argument is either a simple integer or an
*      expression that is an untraced variable (that is,
*      it has no side effects that would be lost by short-
*      circuiting the normal logic of failing and moving the
*      unanchored starting point.)
*      pos (integer argument)
*      parm1                 integer argument
{{beq{8,wb{13,parm1(xr){6,succp{succeed if at right location{11199
{{bnz{8,wb{6,failp{{don't look further if cursor not 0{11200
{{mov{7,xt{3,pmhbs{{get history stack base ptr{11201
{{bne{7,xr{11,-(xt){6,failp{fail if pos is not first node{11202
*      expression argument circuit merges here
{ppos2{bne{11,-(xt){21,=nduna{6,failp{fail if not unanchored mode{11206
{{mov{8,wb{13,parm1(xr){{get desired cursor position{11207
{{bgt{8,wb{3,pmssl{6,exfal{abort if off end{11208
{{mov{13,num02(xt){8,wb{{fake number of unanchored moves{11209
{{brn{6,succp{{{continue match with adjusted cursor{11210
{{ejc{{{{{11211
*      pos (expression argument)
*      parm1                 expression pointer
{p_psd{ent{2,bl_p1{{{p1blk{11217
{{jsr{6,evali{{{evaluate integer argument{11218
{{err{1,050{26,pos evaluated argument is not integer{{{11219
{{err{1,051{26,pos evaluated argument is negative or too large{{{11220
{{ppm{6,failp{{{fail if evaluation fails{11221
{{ppm{6,ppos1{{{process expression case{11222
{ppos1{beq{8,wb{13,parm1(xr){6,succp{succeed if at right location{11224
{{bnz{8,wb{6,failp{{don't look further if cursor not 0{11225
{{bnz{3,evlif{6,failp{{fail if complex argument{11226
{{mov{7,xt{3,pmhbs{{get history stack base ptr{11227
{{mov{8,wa{3,evlio{{get original node ptr{11228
{{bne{8,wa{11,-(xt){6,failp{fail if pos is not first node{11229
{{brn{6,ppos2{{{merge with integer argument code{11230
{{ejc{{{{{11231
*      pattern assignment (initial entry, save cursor)
*      see compound patterns description for the structure and
*      algorithms for matching this node type.
*      no parameters
{p_paa{ent{2,bl_p0{{{p0blk{11240
{{mov{11,-(xs){8,wb{{stack initial cursor{11241
{{mov{11,-(xs){21,=ndpab{{stack ptr to ndpab special node{11242
{{brn{6,succp{{{and succeed matching null{11243
{{ejc{{{{{11244
*      pattern assignment (remove saved cursor)
*      see compound patterns description for the structure and
*      algorithms for matching this node type.
*      no parameters (dummy pattern)
{p_pab{ent{{{{entry point{11253
{{brn{6,failp{{{just fail (entry is already popped){11254
{{ejc{{{{{11255
*      pattern assignment (end of match, make assign entry)
*      see compound patterns description for the structure and
*      algorithms for matching this node type.
*      parm1                 name base of variable
*      parm2                 name offset of variable
{p_pac{ent{2,bl_p2{{{p2blk{11265
{{mov{11,-(xs){8,wb{{stack dummy cursor value{11266
{{mov{11,-(xs){7,xr{{stack pointer to p_pac node{11267
{{mov{11,-(xs){8,wb{{stack final cursor{11268
{{mov{11,-(xs){21,=ndpad{{stack ptr to special ndpad node{11269
{{mnz{3,pmdfl{{{set dot flag non-zero{11270
{{brn{6,succp{{{and succeed{11271
{{ejc{{{{{11272
*      pattern assignment (remove assign entry)
*      see compound patterns description for the structure and
*      algorithms for matching this node type.
*      no parameters (dummy node)
{p_pad{ent{{{{entry point{11281
{{brn{6,flpop{{{fail and remove p_pac node{11282
{{ejc{{{{{11283
*      rem
*      no parameters
{p_rem{ent{2,bl_p0{{{p0blk{11289
{{mov{8,wb{3,pmssl{{point cursor to end of string{11290
{{brn{6,succp{{{and succeed{11291
{{ejc{{{{{11292
*      rpos (expression argument)
*      optimize rpos if it is the first pattern element,
*      unanchored mode, cursor is zero and rpos argument
*      is not beyond end of string.  force cursor position
*      and number of unanchored moves.
*      this optimization is performed invisibly provided
*      the argument is either a simple integer or an
*      expression that is an untraced variable (that is,
*      it has no side effects that would be lost by short-
*      circuiting the normal logic of failing and moving the
*      unanchored starting point).
*      parm1                 expression pointer
{p_rpd{ent{2,bl_p1{{{p1blk{11310
{{jsr{6,evali{{{evaluate integer argument{11311
{{err{1,052{26,rpos evaluated argument is not integer{{{11312
{{err{1,053{26,rpos evaluated argument is negative or too large{{{11313
{{ppm{6,failp{{{fail if evaluation fails{11314
{{ppm{6,prps1{{{merge with normal case if ok{11315
{prps1{mov{8,wc{3,pmssl{{get length of string{11317
{{sub{8,wc{8,wb{{get number of characters remaining{11318
{{beq{8,wc{13,parm1(xr){6,succp{succeed if at right location{11319
{{bnz{8,wb{6,failp{{don't look further if cursor not 0{11320
{{bnz{3,evlif{6,failp{{fail if complex argument{11321
{{mov{7,xt{3,pmhbs{{get history stack base ptr{11322
{{mov{8,wa{3,evlio{{get original node ptr{11323
{{bne{8,wa{11,-(xt){6,failp{fail if pos is not first node{11324
{{brn{6,prps2{{{merge with integer arg code{11325
{{ejc{{{{{11326
*      rpos (integer argument)
*      parm1                 integer argument
{p_rps{ent{2,bl_p1{{{p1blk{11332
*      rpos (integer argument)
*      parm1                 integer argument
{{mov{8,wc{3,pmssl{{get length of string{11338
{{sub{8,wc{8,wb{{get number of characters remaining{11339
{{beq{8,wc{13,parm1(xr){6,succp{succeed if at right location{11340
{{bnz{8,wb{6,failp{{don't look further if cursor not 0{11341
{{mov{7,xt{3,pmhbs{{get history stack base ptr{11342
{{bne{7,xr{11,-(xt){6,failp{fail if rpos is not first node{11343
*      expression argument merges here
{prps2{bne{11,-(xt){21,=nduna{6,failp{fail if not unanchored mode{11347
{{mov{8,wb{3,pmssl{{point to end of string{11348
{{blt{8,wb{13,parm1(xr){6,failp{fail if string not long enough{11349
{{sub{8,wb{13,parm1(xr){{else set new cursor{11350
{{mov{13,num02(xt){8,wb{{fake number of unanchored moves{11351
{{brn{6,succp{{{continue match with adjusted cursor{11352
{{ejc{{{{{11353
*      rtab (integer argument)
*      parm1                 integer argument
{p_rtb{ent{2,bl_p1{{{p1blk{11359
*      expression argument case merges here
{prtb1{mov{8,wc{8,wb{{save initial cursor{11363
{{mov{8,wb{3,pmssl{{point to end of string{11364
{{blt{8,wb{13,parm1(xr){6,failp{fail if string not long enough{11365
{{sub{8,wb{13,parm1(xr){{else set new cursor{11366
{{bge{8,wb{8,wc{6,succp{and succeed if not too far already{11367
{{brn{6,failp{{{in which case, fail{11368
{{ejc{{{{{11369
*      rtab (expression argument)
*      parm1                 expression pointer
{p_rtd{ent{2,bl_p1{{{p1blk{11375
{{jsr{6,evali{{{evaluate integer argument{11376
{{err{1,054{26,rtab evaluated argument is not integer{{{11377
{{err{1,055{26,rtab evaluated argument is negative or too large{{{11378
{{ppm{6,failp{{{fail if evaluation fails{11379
{{ppm{6,prtb1{{{merge with normal case if success{11380
{{ejc{{{{{11381
*      span (expression argument)
*      parm1                 expression pointer
{p_spd{ent{2,bl_p1{{{p1blk{11387
{{jsr{6,evals{{{evaluate string argument{11388
{{err{1,056{26,span evaluated argument is not a string{{{11389
{{ppm{6,failp{{{fail if evaluation fails{11390
{{ppm{6,pspn1{{{merge with multi-char case if ok{11391
{{ejc{{{{{11392
*      span (multi-character argument case)
*      parm1                 pointer to ctblk
*      parm2                 bit mask to select bit column
{p_spn{ent{2,bl_p2{{{p2blk{11399
*      expression argument case merges here
{pspn1{mov{8,wc{3,pmssl{{copy subject string length{11403
{{sub{8,wc{8,wb{{calculate number of characters left{11404
{{bze{8,wc{6,failp{{fail if no characters left{11405
{{mov{7,xl{3,r_pms{{point to subject string{11406
{{plc{7,xl{8,wb{{point to current character{11407
{{mov{3,psavc{8,wb{{save initial cursor{11408
{{mov{3,psave{7,xr{{save node pointer{11409
{{lct{8,wc{8,wc{{set counter for chars left{11410
*      loop to scan matching characters
{pspn2{lch{8,wa{10,(xl)+{{load next character, bump pointer{11414
{{wtb{8,wa{{{convert to byte offset{11415
{{mov{7,xr{13,parm1(xr){{point to ctblk{11416
{{add{7,xr{8,wa{{point to ctblk entry{11417
{{mov{8,wa{13,ctchs(xr){{load ctblk entry{11418
{{mov{7,xr{3,psave{{restore node pointer{11419
{{anb{8,wa{13,parm2(xr){{and with selected bit{11420
{{zrb{8,wa{6,pspn3{{jump if no match{11421
{{icv{8,wb{{{else push cursor{11422
{{bct{8,wc{6,pspn2{{loop back unless end of string{11423
*      here after scanning matching characters
{pspn3{bne{8,wb{3,psavc{6,succp{succeed if chars matched{11427
{{brn{6,failp{{{else fail if null string matched{11428
{{ejc{{{{{11429
*      span (one character argument)
*      parm1                 character argument
{p_sps{ent{2,bl_p1{{{p1blk{11435
{{mov{8,wc{3,pmssl{{get subject string length{11436
{{sub{8,wc{8,wb{{calculate number of characters left{11437
{{bze{8,wc{6,failp{{fail if no characters left{11438
{{mov{7,xl{3,r_pms{{else point to subject string{11439
{{plc{7,xl{8,wb{{point to current character{11440
{{mov{3,psavc{8,wb{{save initial cursor{11441
{{lct{8,wc{8,wc{{set counter for characters left{11442
*      loop to scan matching characters
{psps1{lch{8,wa{10,(xl)+{{load next character, bump pointer{11446
{{bne{8,wa{13,parm1(xr){6,psps2{jump if no match{11447
{{icv{8,wb{{{else push cursor{11448
{{bct{8,wc{6,psps1{{and loop unless end of string{11449
*      here after scanning matching characters
{psps2{bne{8,wb{3,psavc{6,succp{succeed if chars matched{11453
{{brn{6,failp{{{fail if null string matched{11454
{{ejc{{{{{11455
*      multi-character string
*      note that one character strings use the circuit for
*      one character any arguments (p_an1).
*      parm1                 pointer to scblk for string arg
{p_str{ent{2,bl_p1{{{p1blk{11464
{{mov{7,xl{13,parm1(xr){{get pointer to string{11465
*      merge here after evaluating expression with string value
{pstr1{mov{3,psave{7,xr{{save node pointer{11469
{{mov{7,xr{3,r_pms{{load subject string pointer{11470
{{plc{7,xr{8,wb{{point to current character{11471
{{add{8,wb{13,sclen(xl){{compute new cursor position{11472
{{bgt{8,wb{3,pmssl{6,failp{fail if past end of string{11473
{{mov{3,psavc{8,wb{{save updated cursor{11474
{{mov{8,wa{13,sclen(xl){{get number of chars to compare{11475
{{plc{7,xl{{{point to chars of test string{11476
{{cmc{6,failp{6,failp{{compare, fail if not equal{11477
{{mov{7,xr{3,psave{{if all matched, restore node ptr{11478
{{mov{8,wb{3,psavc{{restore updated cursor{11479
{{brn{6,succp{{{and succeed{11480
{{ejc{{{{{11481
*      succeed
*      see section on compound patterns for details of the
*      structure and algorithms for matching this node type
*      no parameters
{p_suc{ent{2,bl_p0{{{p0blk{11490
{{mov{11,-(xs){8,wb{{stack cursor{11491
{{mov{11,-(xs){7,xr{{stack pointer to this node{11492
{{brn{6,succp{{{succeed matching null{11493
{{ejc{{{{{11494
*      tab (integer argument)
*      parm1                 integer argument
{p_tab{ent{2,bl_p1{{{p1blk{11500
*      expression argument case merges here
{ptab1{bgt{8,wb{13,parm1(xr){6,failp{fail if too far already{11504
{{mov{8,wb{13,parm1(xr){{else set new cursor position{11505
{{ble{8,wb{3,pmssl{6,succp{succeed if not off end{11506
{{brn{6,failp{{{else fail{11507
{{ejc{{{{{11508
*      tab (expression argument)
*      parm1                 expression pointer
{p_tbd{ent{2,bl_p1{{{p1blk{11514
{{jsr{6,evali{{{evaluate integer argument{11515
{{err{1,057{26,tab evaluated argument is not integer{{{11516
{{err{1,058{26,tab evaluated argument is negative or too large{{{11517
{{ppm{6,failp{{{fail if evaluation fails{11518
{{ppm{6,ptab1{{{merge with normal case if ok{11519
{{ejc{{{{{11520
*      anchor movement
*      no parameters (dummy node)
{p_una{ent{{{{entry point{11526
{{mov{7,xr{8,wb{{copy initial pattern node pointer{11527
{{mov{8,wb{9,(xs){{get initial cursor{11528
{{beq{8,wb{3,pmssl{6,exfal{match fails if at end of string{11529
{{icv{8,wb{{{else increment cursor{11530
{{mov{9,(xs){8,wb{{store incremented cursor{11531
{{mov{11,-(xs){7,xr{{restack initial node ptr{11532
{{mov{11,-(xs){21,=nduna{{restack unanchored node{11533
{{bri{9,(xr){{{rematch first node{11534
{{ejc{{{{{11535
*      end of pattern match routines
*      the following entry point marks the end of the pattern
*      matching routines and also the end of the entry points
*      referenced from the first word of blocks in dynamic store
{p_yyy{ent{2,bl__i{{{mark last entry in pattern section{11543
{{ttl{27,s p i t b o l -- snobol4 built-in label routines{{{{11544
*      the following section contains the routines for labels
*      which have a predefined meaning in snobol4.
*      control is passed directly to the label name entry point.
*      entry names are of the form l_xxx where xxx is the three
*      letter variable name identifier.
*      entries are in alphabetical order
{{ejc{{{{{11555
*      abort
{l_abo{ent{{{{entry point{11559
*      merge here if execution terminates in error
{labo1{mov{8,wa{3,kvert{{load error code{11563
{{bze{8,wa{6,labo3{{jump if no error has occured{11564
{{jsr{6,sysax{{{call after execution proc{11566
{{mov{8,wc{3,kvstn{{current statement{11570
{{jsr{6,filnm{{{obtain file name for this statement{11571
{{mov{7,xr{3,r_cod{{current code block{11574
{{mov{8,wc{13,cdsln(xr){{line number{11575
{{zer{8,wb{{{column number{11579
{{mov{7,xr{3,stage{{{11580
{{jsr{6,sysea{{{advise system of error{11581
{{ppm{6,stpr4{{{if system does not want print{11582
{{jsr{6,prtpg{{{else eject printer{11584
{{bze{7,xr{6,labo2{{did sysea request print{11586
{{jsr{6,prtst{{{print text from sysea{11587
{labo2{jsr{6,ermsg{{{print error message{11589
{{zer{7,xr{{{indicate no message to print{11590
{{brn{6,stopr{{{jump to routine to stop run{11591
*      here if no error had occured
{labo3{erb{1,036{26,goto abort with no preceding error{{{11595
{{ejc{{{{{11596
*      continue
{l_cnt{ent{{{{entry point{11600
*      merge here after execution error
{lcnt1{mov{7,xr{3,r_cnt{{load continuation code block ptr{11604
{{bze{7,xr{6,lcnt3{{jump if no previous error{11605
{{zer{3,r_cnt{{{clear flag{11606
{{mov{3,r_cod{7,xr{{else store as new code block ptr{11607
{{bne{9,(xr){22,=b_cdc{6,lcnt2{jump if not complex go{11608
{{mov{8,wa{3,stxoc{{get offset of error{11609
{{bge{8,wa{3,stxof{6,lcnt4{jump if error in goto evaluation{11610
*      here if error did not occur in complex failure goto
{lcnt2{add{7,xr{3,stxof{{add failure offset{11614
{{lcp{7,xr{{{load code pointer{11615
{{mov{7,xs{3,flptr{{reset stack pointer{11616
{{lcw{7,xr{{{get next code word{11617
{{bri{9,(xr){{{execute next code word{11618
*      here if no previous error
{lcnt3{icv{3,errft{{{fatal error{11622
{{erb{1,037{26,goto continue with no preceding error{{{11623
*      here if error in evaluation of failure goto.
*      cannot continue back to failure goto!
{lcnt4{icv{3,errft{{{fatal error{11628
{{erb{1,332{26,goto continue with error in failure goto{{{11629
{{ejc{{{{{11630
*      end
{l_end{ent{{{{entry point{11634
*      merge here from end code circuit
{lend0{mov{7,xr{21,=endms{{point to message /normal term.../{11638
{{brn{6,stopr{{{jump to routine to stop run{11639
{{ejc{{{{{11640
*      freturn
{l_frt{ent{{{{entry point{11644
{{mov{8,wa{21,=scfrt{{point to string /freturn/{11645
{{brn{6,retrn{{{jump to common return routine{11646
{{ejc{{{{{11647
*      nreturn
{l_nrt{ent{{{{entry point{11651
{{mov{8,wa{21,=scnrt{{point to string /nreturn/{11652
{{brn{6,retrn{{{jump to common return routine{11653
{{ejc{{{{{11654
*      return
{l_rtn{ent{{{{entry point{11658
{{mov{8,wa{21,=scrtn{{point to string /return/{11659
{{brn{6,retrn{{{jump to common return routine{11660
{{ejc{{{{{11661
*      scontinue
{l_scn{ent{{{{entry point{11665
{{mov{7,xr{3,r_cnt{{load continuation code block ptr{11666
{{bze{7,xr{6,lscn2{{jump if no previous error{11667
{{zer{3,r_cnt{{{clear flag{11668
{{bne{3,kvert{18,=nm320{6,lscn1{error must be user interrupt{11669
{{beq{3,kvert{18,=nm321{6,lscn2{detect scontinue loop{11670
{{mov{3,r_cod{7,xr{{else store as new code block ptr{11671
{{add{7,xr{3,stxoc{{add resume offset{11672
{{lcp{7,xr{{{load code pointer{11673
{{lcw{7,xr{{{get next code word{11674
{{bri{9,(xr){{{execute next code word{11675
*      here if no user interrupt
{lscn1{icv{3,errft{{{fatal error{11679
{{erb{1,331{26,goto scontinue with no user interrupt{{{11680
*      here if in scontinue loop or if no previous error
{lscn2{icv{3,errft{{{fatal error{11684
{{erb{1,321{26,goto scontinue with no preceding error{{{11685
{{ejc{{{{{11686
*      undefined label
{l_und{ent{{{{entry point{11690
{{erb{1,038{26,goto undefined label{{{11691
{{ttl{27,s p i t b o l -- predefined snobol4 functions{{{{11692
*      the following section contains coding for functions
*      which are predefined and available at the snobol level.
*      these routines receive control directly from the code or
*      indirectly through the o_fnc, o_fns or cfunc routines.
*      in both cases the conditions on entry are as follows
*      the arguments are on the stack. the number of arguments
*      has been adjusted to correspond to the svblk svnar field.
*      in certain functions the direct call is not permitted
*      and in these instances we also have.
*      (wa)                  actual number of arguments in call
*      control returns by placing the function result value on
*      on the stack and continuing execution with the next
*      word from the generated code.
*      the names of the entry points of these functions are of
*      the form s_xxx where xxx is the three letter code for
*      the system variable name. the functions are in order
*      alphabetically by their entry names.
{{ejc{{{{{11717
*      any
{s_any{ent{{{{entry point{11771
{{mov{8,wb{22,=p_ans{{set pcode for single char case{11772
{{mov{7,xl{22,=p_any{{pcode for multi-char case{11773
{{mov{8,wc{22,=p_ayd{{pcode for expression case{11774
{{jsr{6,patst{{{call common routine to build node{11775
{{err{1,059{26,any argument is not a string or expression{{{11776
{{mov{11,-(xs){7,xr{{stack result{11777
{{lcw{7,xr{{{get next code word{11778
{{bri{9,(xr){{{execute it{11779
{{ejc{{{{{11780
*      apply
*      apply does not permit the direct (fast) call so that
*      wa contains the actual number of arguments passed.
{s_app{ent{{{{entry point{11806
{{bze{8,wa{6,sapp3{{jump if no arguments{11807
{{dcv{8,wa{{{else get applied func arg count{11808
{{mov{8,wb{8,wa{{copy{11809
{{wtb{8,wb{{{convert to bytes{11810
{{mov{7,xt{7,xs{{copy stack pointer{11811
{{add{7,xt{8,wb{{point to function argument on stack{11812
{{mov{7,xr{9,(xt){{load function ptr (apply 1st arg){11813
{{bze{8,wa{6,sapp2{{jump if no args for applied func{11814
{{lct{8,wb{8,wa{{else set counter for loop{11815
*      loop to move arguments up on stack
{sapp1{dca{7,xt{{{point to next argument{11819
{{mov{13,num01(xt){9,(xt){{move argument up{11820
{{bct{8,wb{6,sapp1{{loop till all moved{11821
*      merge here to call function (wa = number of arguments)
{sapp2{ica{7,xs{{{adjust stack ptr for apply 1st arg{11825
{{jsr{6,gtnvr{{{get variable block addr for func{11826
{{ppm{6,sapp3{{{jump if not natural variable{11827
{{mov{7,xl{13,vrfnc(xr){{else point to function block{11828
{{brn{6,cfunc{{{go call applied function{11829
*      here for invalid first argument
{sapp3{erb{1,060{26,apply first arg is not natural variable name{{{11833
{{ejc{{{{{11834
*      arbno
*      arbno builds a compound pattern. see description at
*      start of pattern matching section for structure formed.
{s_abn{ent{{{{entry point{11841
{{zer{7,xr{{{set parm1 = 0 for the moment{11842
{{mov{8,wb{22,=p_alt{{set pcode for alternative node{11843
{{jsr{6,pbild{{{build alternative node{11844
{{mov{7,xl{7,xr{{save ptr to alternative pattern{11845
{{mov{8,wb{22,=p_abc{{pcode for p_abc{11846
{{zer{7,xr{{{p0blk{11847
{{jsr{6,pbild{{{build p_abc node{11848
{{mov{13,pthen(xr){7,xl{{put alternative node as successor{11849
{{mov{8,wa{7,xl{{remember alternative node pointer{11850
{{mov{7,xl{7,xr{{copy p_abc node ptr{11851
{{mov{7,xr{9,(xs){{load arbno argument{11852
{{mov{9,(xs){8,wa{{stack alternative node pointer{11853
{{jsr{6,gtpat{{{get arbno argument as pattern{11854
{{err{1,061{26,arbno argument is not pattern{{{11855
{{jsr{6,pconc{{{concat arg with p_abc node{11856
{{mov{7,xl{7,xr{{remember ptr to concd patterns{11857
{{mov{8,wb{22,=p_aba{{pcode for p_aba{11858
{{zer{7,xr{{{p0blk{11859
{{jsr{6,pbild{{{build p_aba node{11860
{{mov{13,pthen(xr){7,xl{{concatenate nodes{11861
{{mov{7,xl{9,(xs){{recall ptr to alternative node{11862
{{mov{13,parm1(xl){7,xr{{point alternative back to argument{11863
{{lcw{7,xr{{{get next code word{11864
{{bri{9,(xr){{{execute next code word{11865
{{ejc{{{{{11866
*      arg
{s_arg{ent{{{{entry point{11870
{{jsr{6,gtsmi{{{get second arg as small integer{11871
{{err{1,062{26,arg second argument is not integer{{{11872
{{ppm{6,exfal{{{fail if out of range or negative{11873
{{mov{8,wa{7,xr{{save argument number{11874
{{mov{7,xr{10,(xs)+{{load first argument{11875
{{jsr{6,gtnvr{{{locate vrblk{11876
{{ppm{6,sarg1{{{jump if not natural variable{11877
{{mov{7,xr{13,vrfnc(xr){{else load function block pointer{11878
{{bne{9,(xr){22,=b_pfc{6,sarg1{jump if not program defined{11879
{{bze{8,wa{6,exfal{{fail if arg number is zero{11880
{{bgt{8,wa{13,fargs(xr){6,exfal{fail if arg number is too large{11881
{{wtb{8,wa{{{else convert to byte offset{11882
{{add{7,xr{8,wa{{point to argument selected{11883
{{mov{7,xr{13,pfagb(xr){{load argument vrblk pointer{11884
{{brn{6,exvnm{{{exit to build nmblk{11885
*      here if 1st argument is bad
{sarg1{erb{1,063{26,arg first argument is not program function name{{{11889
{{ejc{{{{{11890
*      array
{s_arr{ent{{{{entry point{11894
{{mov{7,xl{10,(xs)+{{load initial element value{11895
{{mov{7,xr{10,(xs)+{{load first argument{11896
{{jsr{6,gtint{{{convert first arg to integer{11897
{{ppm{6,sar02{{{jump if not integer{11898
*      here for integer first argument, build vcblk
{{ldi{13,icval(xr){{{load integer value{11902
{{ile{6,sar10{{{jump if zero or neg (bad dimension){11903
{{mfi{8,wa{6,sar11{{else convert to one word, test ovfl{11904
{{jsr{6,vmake{{{create vector{11905
{{ppm{6,sar11{{{fail if too large{11906
{{brn{6,exsid{{{exit setting idval{11907
{{ejc{{{{{11908
*      array (continued)
*      here if first argument is not an integer
{sar02{mov{11,-(xs){7,xr{{replace argument on stack{11914
{{jsr{6,xscni{{{initialize scan of first argument{11915
{{err{1,064{26,array first argument is not integer or string{{{11916
{{ppm{6,exnul{{{dummy (unused) null string exit{11917
{{mov{11,-(xs){3,r_xsc{{save prototype pointer{11918
{{mov{11,-(xs){7,xl{{save default value{11919
{{zer{3,arcdm{{{zero count of dimensions{11920
{{zer{3,arptr{{{zero offset to indicate pass one{11921
{{ldi{4,intv1{{{load integer one{11922
{{sti{3,arnel{{{initialize element count{11923
*      the following code is executed twice. the first time
*      (arptr eq 0), it is used to count the number of elements
*      and number of dimensions. the second time (arptr gt 0) is
*      used to actually fill in the dim,lbd fields of the arblk.
{sar03{ldi{4,intv1{{{load one as default low bound{11930
{{sti{3,arsvl{{{save as low bound{11931
{{mov{8,wc{18,=ch_cl{{set delimiter one = colon{11932
{{mov{7,xl{18,=ch_cm{{set delimiter two = comma{11933
{{zer{8,wa{{{retain blanks in prototype{11934
{{jsr{6,xscan{{{scan next bound{11935
{{bne{8,wa{18,=num01{6,sar04{jump if not colon{11936
*      here we have a colon ending a low bound
{{jsr{6,gtint{{{convert low bound{11940
{{err{1,065{26,array first argument lower bound is not integer{{{11941
{{ldi{13,icval(xr){{{load value of low bound{11942
{{sti{3,arsvl{{{store low bound value{11943
{{mov{8,wc{18,=ch_cm{{set delimiter one = comma{11944
{{mov{7,xl{8,wc{{and delimiter two = comma{11945
{{zer{8,wa{{{retain blanks in prototype{11946
{{jsr{6,xscan{{{scan high bound{11947
{{ejc{{{{{11948
*      array (continued)
*      merge here to process upper bound
{sar04{jsr{6,gtint{{{convert high bound to integer{11954
{{err{1,066{26,array first argument upper bound is not integer{{{11955
{{ldi{13,icval(xr){{{get high bound{11956
{{sbi{3,arsvl{{{subtract lower bound{11957
{{iov{6,sar10{{{bad dimension if overflow{11958
{{ilt{6,sar10{{{bad dimension if negative{11959
{{adi{4,intv1{{{add 1 to get dimension{11960
{{iov{6,sar10{{{bad dimension if overflow{11961
{{mov{7,xl{3,arptr{{load offset (also pass indicator){11962
{{bze{7,xl{6,sar05{{jump if first pass{11963
*      here in second pass to store lbd and dim in arblk
{{add{7,xl{9,(xs){{point to current location in arblk{11967
{{sti{13,cfp_i(xl){{{store dimension{11968
{{ldi{3,arsvl{{{load low bound{11969
{{sti{9,(xl){{{store low bound{11970
{{add{3,arptr{19,*ardms{{bump offset to next bounds{11971
{{brn{6,sar06{{{jump to check for end of bounds{11972
*      here in pass 1
{sar05{icv{3,arcdm{{{bump dimension count{11976
{{mli{3,arnel{{{multiply dimension by count so far{11977
{{iov{6,sar11{{{too large if overflow{11978
{{sti{3,arnel{{{else store updated element count{11979
*      merge here after processing one set of bounds
{sar06{bnz{8,wa{6,sar03{{loop back unless end of bounds{11983
{{bnz{3,arptr{6,sar09{{jump if end of pass 2{11984
{{ejc{{{{{11985
*      array (continued)
*      here at end of pass one, build arblk
{{ldi{3,arnel{{{get number of elements{11991
{{mfi{8,wb{6,sar11{{get as addr integer, test ovflo{11992
{{wtb{8,wb{{{else convert to length in bytes{11993
{{mov{8,wa{19,*arsi_{{set size of standard fields{11994
{{lct{8,wc{3,arcdm{{set dimension count to control loop{11995
*      loop to allow space for dimensions
{sar07{add{8,wa{19,*ardms{{allow space for one set of bounds{11999
{{bct{8,wc{6,sar07{{loop back till all accounted for{12000
{{mov{7,xl{8,wa{{save size (=arofs){12001
*      now allocate space for arblk
{{add{8,wa{8,wb{{add space for elements{12005
{{ica{8,wa{{{allow for arpro prototype field{12006
{{bgt{8,wa{3,mxlen{6,sar11{fail if too large{12007
{{jsr{6,alloc{{{else allocate arblk{12008
{{mov{8,wb{9,(xs){{load default value{12009
{{mov{9,(xs){7,xr{{save arblk pointer{12010
{{mov{8,wc{8,wa{{save length in bytes{12011
{{btw{8,wa{{{convert length back to words{12012
{{lct{8,wa{8,wa{{set counter to control loop{12013
*      loop to clear entire arblk to default value
{sar08{mov{10,(xr)+{8,wb{{set one word{12017
{{bct{8,wa{6,sar08{{loop till all set{12018
{{ejc{{{{{12019
*      array (continued)
*      now set initial fields of arblk
{{mov{7,xr{10,(xs)+{{reload arblk pointer{12025
{{mov{8,wb{9,(xs){{load prototype{12026
{{mov{9,(xr){22,=b_art{{set type word{12027
{{mov{13,arlen(xr){8,wc{{store length in bytes{12028
{{zer{13,idval(xr){{{zero id till we get it built{12029
{{mov{13,arofs(xr){7,xl{{set prototype field ptr{12030
{{mov{13,arndm(xr){3,arcdm{{set number of dimensions{12031
{{mov{8,wc{7,xr{{save arblk pointer{12032
{{add{7,xr{7,xl{{point to prototype field{12033
{{mov{9,(xr){8,wb{{store prototype ptr in arblk{12034
{{mov{3,arptr{19,*arlbd{{set offset for pass 2 bounds scan{12035
{{mov{3,r_xsc{8,wb{{reset string pointer for xscan{12036
{{mov{9,(xs){8,wc{{store arblk pointer on stack{12037
{{zer{3,xsofs{{{reset offset ptr to start of string{12038
{{brn{6,sar03{{{jump back to rescan bounds{12039
*      here after filling in bounds information (end pass two)
{sar09{mov{7,xr{10,(xs)+{{reload pointer to arblk{12043
{{brn{6,exsid{{{exit setting idval{12044
*      here for bad dimension
{sar10{erb{1,067{26,array dimension is zero, negative or out of range{{{12048
*      here if array is too large
{sar11{erb{1,068{26,array size exceeds maximum permitted{{{12052
{{ejc{{{{{12053
*      atan
{s_atn{ent{{{{entry point{12058
{{mov{7,xr{10,(xs)+{{get argument{12059
{{jsr{6,gtrea{{{convert to real{12060
{{err{1,301{26,atan argument not numeric{{{12061
{{ldr{13,rcval(xr){{{load accumulator with argument{12062
{{atn{{{{take arctangent{12063
{{brn{6,exrea{{{overflow, out of range not possible{12064
{{ejc{{{{{12065
{{ejc{{{{{12068
*      backspace
{s_bsp{ent{{{{entry point{12072
{{jsr{6,iofcb{{{call fcblk routine{12073
{{err{1,316{26,backspace argument is not a suitable name{{{12074
{{err{1,316{26,backspace argument is not a suitable name{{{12075
{{err{1,317{26,backspace file does not exist{{{12076
{{jsr{6,sysbs{{{call backspace file function{12077
{{err{1,317{26,backspace file does not exist{{{12078
{{err{1,318{26,backspace file does not permit backspace{{{12079
{{err{1,319{26,backspace caused non-recoverable error{{{12080
{{brn{6,exnul{{{return null as result{12081
{{ejc{{{{{12082
*      break
{s_brk{ent{{{{entry point{12115
{{mov{8,wb{22,=p_bks{{set pcode for single char case{12116
{{mov{7,xl{22,=p_brk{{pcode for multi-char case{12117
{{mov{8,wc{22,=p_bkd{{pcode for expression case{12118
{{jsr{6,patst{{{call common routine to build node{12119
{{err{1,069{26,break argument is not a string or expression{{{12120
{{mov{11,-(xs){7,xr{{stack result{12121
{{lcw{7,xr{{{get next code word{12122
{{bri{9,(xr){{{execute it{12123
{{ejc{{{{{12124
*      breakx
*      breakx is a compound pattern. see description at start
*      of pattern matching section for structure formed.
{s_bkx{ent{{{{entry point{12131
{{mov{8,wb{22,=p_bks{{pcode for single char argument{12132
{{mov{7,xl{22,=p_brk{{pcode for multi-char argument{12133
{{mov{8,wc{22,=p_bxd{{pcode for expression case{12134
{{jsr{6,patst{{{call common routine to build node{12135
{{err{1,070{26,breakx argument is not a string or expression{{{12136
*      now hook breakx node on at front end
{{mov{11,-(xs){7,xr{{save ptr to break node{12140
{{mov{8,wb{22,=p_bkx{{set pcode for breakx node{12141
{{jsr{6,pbild{{{build it{12142
{{mov{13,pthen(xr){9,(xs){{set break node as successor{12143
{{mov{8,wb{22,=p_alt{{set pcode for alternation node{12144
{{jsr{6,pbild{{{build (parm1=alt=breakx node){12145
{{mov{8,wa{7,xr{{save ptr to alternation node{12146
{{mov{7,xr{9,(xs){{point to break node{12147
{{mov{13,pthen(xr){8,wa{{set alternate node as successor{12148
{{lcw{7,xr{{{result on stack{12149
{{bri{9,(xr){{{execute next code word{12150
{{ejc{{{{{12151
*      char
{s_chr{ent{{{{entry point{12155
{{jsr{6,gtsmi{{{convert arg to integer{12156
{{err{1,281{26,char argument not integer{{{12157
{{ppm{6,schr1{{{too big error exit{12158
{{bge{8,wc{18,=cfp_a{6,schr1{see if out of range of host set{12159
{{mov{8,wa{18,=num01{{if not set scblk allocation{12160
{{mov{8,wb{8,wc{{save char code{12161
{{jsr{6,alocs{{{allocate 1 bau scblk{12162
{{mov{7,xl{7,xr{{copy scblk pointer{12163
{{psc{7,xl{{{get set to stuff char{12164
{{sch{8,wb{9,(xl){{stuff it{12165
{{csc{7,xl{{{complete store character{12166
{{zer{7,xl{{{clear slop in xl{12167
{{mov{11,-(xs){7,xr{{stack result{12168
{{lcw{7,xr{{{get next code word{12169
{{bri{9,(xr){{{execute it{12170
*      here if char argument is out of range
{schr1{erb{1,282{26,char argument not in range{{{12174
{{ejc{{{{{12175
*      chop
{s_chp{ent{{{{entry point{12180
{{mov{7,xr{10,(xs)+{{get argument{12181
{{jsr{6,gtrea{{{convert to real{12182
{{err{1,302{26,chop argument not numeric{{{12183
{{ldr{13,rcval(xr){{{load accumulator with argument{12184
{{chp{{{{truncate to integer valued real{12185
{{brn{6,exrea{{{no overflow possible{12186
{{ejc{{{{{12187
*      clear
{s_clr{ent{{{{entry point{12192
{{jsr{6,xscni{{{initialize to scan argument{12193
{{err{1,071{26,clear argument is not a string{{{12194
{{ppm{6,sclr2{{{jump if null{12195
*      loop to scan out names in first argument. variables in
*      the list are flagged by setting vrget of vrblk to zero.
{sclr1{mov{8,wc{18,=ch_cm{{set delimiter one = comma{12200
{{mov{7,xl{8,wc{{delimiter two = comma{12201
{{mnz{8,wa{{{skip/trim blanks in prototype{12202
{{jsr{6,xscan{{{scan next variable name{12203
{{jsr{6,gtnvr{{{locate vrblk{12204
{{err{1,072{26,clear argument has null variable name{{{12205
{{zer{13,vrget(xr){{{else flag by zeroing vrget field{12206
{{bnz{8,wa{6,sclr1{{loop back if stopped by comma{12207
*      here after flagging variables in argument list
{sclr2{mov{8,wb{3,hshtb{{point to start of hash table{12211
*      loop through slots in hash table
{sclr3{beq{8,wb{3,hshte{6,exnul{exit returning null if none left{12215
{{mov{7,xr{8,wb{{else copy slot pointer{12216
{{ica{8,wb{{{bump slot pointer{12217
{{sub{7,xr{19,*vrnxt{{set offset to merge into loop{12218
*      loop through vrblks on one hash chain
{sclr4{mov{7,xr{13,vrnxt(xr){{point to next vrblk on chain{12222
{{bze{7,xr{6,sclr3{{jump for next bucket if chain end{12223
{{bnz{13,vrget(xr){6,sclr5{{jump if not flagged{12224
{{ejc{{{{{12225
*      clear (continued)
*      here for flagged variable, do not set value to null
{{jsr{6,setvr{{{for flagged var, restore vrget{12231
{{brn{6,sclr4{{{and loop back for next vrblk{12232
*      here to set value of a variable to null
*      protected variables (arb, etc) are exempt
{sclr5{beq{13,vrsto(xr){22,=b_vre{6,sclr4{check for protected variable{12237
{{mov{7,xl{7,xr{{copy vrblk pointer{12238
*      loop to locate value at end of possible trblk chain
{sclr6{mov{8,wa{7,xl{{save block pointer{12242
{{mov{7,xl{13,vrval(xl){{load next value field{12243
{{beq{9,(xl){22,=b_trt{6,sclr6{loop back if trapped{12244
*      now store the null value
{{mov{7,xl{8,wa{{restore block pointer{12248
{{mov{13,vrval(xl){21,=nulls{{store null constant value{12249
{{brn{6,sclr4{{{loop back for next vrblk{12250
{{ejc{{{{{12251
*      code
{s_cod{ent{{{{entry point{12255
{{mov{7,xr{10,(xs)+{{load argument{12256
{{jsr{6,gtcod{{{convert to code{12257
{{ppm{6,exfal{{{fail if conversion is impossible{12258
{{mov{11,-(xs){7,xr{{stack result{12259
{{zer{3,r_ccb{{{forget interim code block{12260
{{lcw{7,xr{{{get next code word{12261
{{bri{9,(xr){{{execute it{12262
{{ejc{{{{{12263
*      collect
{s_col{ent{{{{entry point{12267
{{mov{7,xr{10,(xs)+{{load argument{12268
{{jsr{6,gtint{{{convert to integer{12269
{{err{1,073{26,collect argument is not integer{{{12270
{{ldi{13,icval(xr){{{load collect argument{12271
{{sti{3,clsvi{{{save collect argument{12272
{{zer{8,wb{{{set no move up{12273
{{zer{3,r_ccb{{{forget interim code block{12274
{{zer{3,dnams{{{collect sediment too{12276
{{jsr{6,gbcol{{{perform garbage collection{12277
{{mov{3,dnams{7,xr{{record new sediment size{12278
{{mov{8,wa{3,dname{{point to end of memory{12282
{{sub{8,wa{3,dnamp{{subtract next location{12283
{{btw{8,wa{{{convert bytes to words{12284
{{mti{8,wa{{{convert words available as integer{12285
{{sbi{3,clsvi{{{subtract argument{12286
{{iov{6,exfal{{{fail if overflow{12287
{{ilt{6,exfal{{{fail if not enough{12288
{{adi{3,clsvi{{{else recompute available{12289
{{brn{6,exint{{{and exit with integer result{12290
{{ejc{{{{{12291
*      convert
{s_cnv{ent{{{{entry point{12320
{{jsr{6,gtstg{{{convert second argument to string{12321
{{ppm{6,scv29{{{error if second argument not string{12322
{{bze{8,wa{6,scv29{{or if null string{12323
{{mov{7,xl{9,(xs){{load first argument{12327
{{bne{9,(xl){22,=b_pdt{6,scv01{jump if not program defined{12328
*      here for program defined datatype
{{mov{7,xl{13,pddfp(xl){{point to dfblk{12332
{{mov{7,xl{13,dfnam(xl){{load datatype name{12333
{{jsr{6,ident{{{compare with second arg{12334
{{ppm{6,exits{{{exit if ident with arg as result{12335
{{brn{6,exfal{{{else fail{12336
*      here if not program defined datatype
{scv01{mov{11,-(xs){7,xr{{save string argument{12340
{{mov{7,xl{21,=svctb{{point to table of names to compare{12341
{{zer{8,wb{{{initialize counter{12342
{{mov{8,wc{8,wa{{save length of argument string{12343
*      loop through table entries
{scv02{mov{7,xr{10,(xl)+{{load next table entry, bump pointer{12347
{{bze{7,xr{6,exfal{{fail if zero marking end of list{12348
{{bne{8,wc{13,sclen(xr){6,scv05{jump if wrong length{12349
{{mov{3,cnvtp{7,xl{{else store table pointer{12350
{{plc{7,xr{{{point to chars of table entry{12351
{{mov{7,xl{9,(xs){{load pointer to string argument{12352
{{plc{7,xl{{{point to chars of string arg{12353
{{mov{8,wa{8,wc{{set number of chars to compare{12354
{{cmc{6,scv04{6,scv04{{compare, jump if no match{12355
{{ejc{{{{{12356
*      convert (continued)
*      here we have a match
{scv03{mov{7,xl{8,wb{{copy entry number{12362
{{ica{7,xs{{{pop string arg off stack{12363
{{mov{7,xr{10,(xs)+{{load first argument{12364
{{bsw{7,xl{2,cnvtt{{jump to appropriate routine{12365
{{iff{1,0{6,scv06{{string{12383
{{iff{1,1{6,scv07{{integer{12383
{{iff{1,2{6,scv09{{name{12383
{{iff{1,3{6,scv10{{pattern{12383
{{iff{1,4{6,scv11{{array{12383
{{iff{1,5{6,scv19{{table{12383
{{iff{1,6{6,scv25{{expression{12383
{{iff{1,7{6,scv26{{code{12383
{{iff{1,8{6,scv27{{numeric{12383
{{iff{2,cnvrt{6,scv08{{real{12383
{{esw{{{{end of switch table{12383
*      here if no match with table entry
{scv04{mov{7,xl{3,cnvtp{{restore table pointer, merge{12387
*      merge here if lengths did not match
{scv05{icv{8,wb{{{bump entry number{12391
{{brn{6,scv02{{{loop back to check next entry{12392
*      here to convert to string
{scv06{mov{11,-(xs){7,xr{{replace string argument on stack{12396
{{jsr{6,gtstg{{{convert to string{12397
{{ppm{6,exfal{{{fail if conversion not possible{12398
{{mov{11,-(xs){7,xr{{stack result{12399
{{lcw{7,xr{{{get next code word{12400
{{bri{9,(xr){{{execute it{12401
{{ejc{{{{{12402
*      convert (continued)
*      here to convert to integer
{scv07{jsr{6,gtint{{{convert to integer{12408
{{ppm{6,exfal{{{fail if conversion not possible{12409
{{mov{11,-(xs){7,xr{{stack result{12410
{{lcw{7,xr{{{get next code word{12411
{{bri{9,(xr){{{execute it{12412
*      here to convert to real
{scv08{jsr{6,gtrea{{{convert to real{12418
{{ppm{6,exfal{{{fail if conversion not possible{12419
{{mov{11,-(xs){7,xr{{stack result{12420
{{lcw{7,xr{{{get next code word{12421
{{bri{9,(xr){{{execute it{12422
*      here to convert to name
{scv09{beq{9,(xr){22,=b_nml{6,exixr{return if already a name{12427
{{jsr{6,gtnvr{{{else try string to name convert{12428
{{ppm{6,exfal{{{fail if conversion not possible{12429
{{brn{6,exvnm{{{else exit building nmblk for vrblk{12430
*      here to convert to pattern
{scv10{jsr{6,gtpat{{{convert to pattern{12434
{{ppm{6,exfal{{{fail if conversion not possible{12435
{{mov{11,-(xs){7,xr{{stack result{12436
{{lcw{7,xr{{{get next code word{12437
{{bri{9,(xr){{{execute it{12438
*      convert to array
*      if the first argument is a table, then we go through
*      an intermediate array of addresses that is sorted to
*      provide a result ordered by time of entry in the
*      original table.  see c3.762.
{scv11{mov{11,-(xs){7,xr{{save argument on stack{12447
{{zer{8,wa{{{use table chain block addresses{12448
{{jsr{6,gtarr{{{get an array{12449
{{ppm{6,exfal{{{fail if empty table{12450
{{ppm{6,exfal{{{fail if not convertible{12451
{{mov{7,xl{10,(xs)+{{reload original arg{12452
{{bne{9,(xl){22,=b_tbt{6,exsid{exit if original not a table{12453
{{mov{11,-(xs){7,xr{{sort the intermediate array{12454
{{mov{11,-(xs){21,=nulls{{on first column{12455
{{zer{8,wa{{{sort ascending{12456
{{jsr{6,sorta{{{do sort{12457
{{ppm{6,exfal{{{if sort fails, so shall we{12458
{{mov{8,wb{7,xr{{save array result{12459
{{ldi{13,ardim(xr){{{load dim 1 (number of elements){12460
{{mfi{8,wa{{{get as one word integer{12461
{{lct{8,wa{8,wa{{copy to control loop{12462
{{add{7,xr{19,*arvl2{{point to first element in array{12463
*      here for each row of this 2-column array
{scv12{mov{7,xl{9,(xr){{get teblk address{12467
{{mov{10,(xr)+{13,tesub(xl){{replace with subscript{12468
{{mov{10,(xr)+{13,teval(xl){{replace with value{12469
{{bct{8,wa{6,scv12{{loop till all copied over{12470
{{mov{7,xr{8,wb{{retrieve array address{12471
{{brn{6,exsid{{{exit setting id field{12472
*      convert to table
{scv19{mov{8,wa{9,(xr){{load first word of block{12476
{{mov{11,-(xs){7,xr{{replace arblk pointer on stack{12477
{{beq{8,wa{22,=b_tbt{6,exits{return arg if already a table{12478
{{bne{8,wa{22,=b_art{6,exfal{else fail if not an array{12479
{{ejc{{{{{12480
*      convert (continued)
*      here to convert an array to table
{{bne{13,arndm(xr){18,=num02{6,exfal{fail if not 2-dim array{12486
{{ldi{13,ardm2(xr){{{load dim 2{12487
{{sbi{4,intv2{{{subtract 2 to compare{12488
{{ine{6,exfal{{{fail if dim2 not 2{12489
*      here we have an arblk of the right shape
{{ldi{13,ardim(xr){{{load dim 1 (number of elements){12493
{{mfi{8,wa{{{get as one word integer{12494
{{lct{8,wb{8,wa{{copy to control loop{12495
{{add{8,wa{18,=tbsi_{{add space for standard fields{12496
{{wtb{8,wa{{{convert length to bytes{12497
{{jsr{6,alloc{{{allocate space for tbblk{12498
{{mov{8,wc{7,xr{{copy tbblk pointer{12499
{{mov{11,-(xs){7,xr{{save tbblk pointer{12500
{{mov{10,(xr)+{22,=b_tbt{{store type word{12501
{{zer{10,(xr)+{{{store zero for idval for now{12502
{{mov{10,(xr)+{8,wa{{store length{12503
{{mov{10,(xr)+{21,=nulls{{null initial lookup value{12504
*      loop to initialize bucket ptrs to point to table
{scv20{mov{10,(xr)+{8,wc{{set bucket ptr to point to tbblk{12508
{{bct{8,wb{6,scv20{{loop till all initialized{12509
{{mov{8,wb{19,*arvl2{{set offset to first arblk element{12510
*      loop to copy elements from array to table
{scv21{mov{7,xl{13,num01(xs){{point to arblk{12514
{{beq{8,wb{13,arlen(xl){6,scv24{jump if all moved{12515
{{add{7,xl{8,wb{{else point to current location{12516
{{add{8,wb{19,*num02{{bump offset{12517
{{mov{7,xr{9,(xl){{load subscript name{12518
{{dca{7,xl{{{adjust ptr to merge (trval=1+1){12519
{{ejc{{{{{12520
*      convert (continued)
*      loop to chase down trblk chain for value
{scv22{mov{7,xl{13,trval(xl){{point to next value{12526
{{beq{9,(xl){22,=b_trt{6,scv22{loop back if trapped{12527
*      here with name in xr, value in xl
{scv23{mov{11,-(xs){7,xl{{stack value{12531
{{mov{7,xl{13,num01(xs){{load tbblk pointer{12532
{{jsr{6,tfind{{{build teblk (note wb gt 0 by name){12533
{{ppm{6,exfal{{{fail if acess fails{12534
{{mov{13,teval(xl){10,(xs)+{{store value in teblk{12535
{{brn{6,scv21{{{loop back for next element{12536
*      here after moving all elements to tbblk
{scv24{mov{7,xr{10,(xs)+{{load tbblk pointer{12540
{{ica{7,xs{{{pop arblk pointer{12541
{{brn{6,exsid{{{exit setting idval{12542
*      convert to expression
{scv25{zer{8,wb{{{by value{12547
{{jsr{6,gtexp{{{convert to expression{12548
{{ppm{6,exfal{{{fail if conversion not possible{12552
{{zer{3,r_ccb{{{forget interim code block{12553
{{mov{11,-(xs){7,xr{{stack result{12554
{{lcw{7,xr{{{get next code word{12555
{{bri{9,(xr){{{execute it{12556
*      convert to code
{scv26{jsr{6,gtcod{{{convert to code{12560
{{ppm{6,exfal{{{fail if conversion is not possible{12561
{{zer{3,r_ccb{{{forget interim code block{12562
{{mov{11,-(xs){7,xr{{stack result{12563
{{lcw{7,xr{{{get next code word{12564
{{bri{9,(xr){{{execute it{12565
*      convert to numeric
{scv27{jsr{6,gtnum{{{convert to numeric{12569
{{ppm{6,exfal{{{fail if unconvertible{12570
{scv31{mov{11,-(xs){7,xr{{stack result{12571
{{lcw{7,xr{{{get next code word{12572
{{bri{9,(xr){{{execute it{12573
{{ejc{{{{{12574
*      second argument not string or null
{scv29{erb{1,074{26,convert second argument is not a string{{{12600
*      copy
{s_cop{ent{{{{entry point{12604
{{jsr{6,copyb{{{copy the block{12605
{{ppm{6,exits{{{return if no idval field{12606
{{brn{6,exsid{{{exit setting id value{12607
{{ejc{{{{{12608
*      cos
{s_cos{ent{{{{entry point{12613
{{mov{7,xr{10,(xs)+{{get argument{12614
{{jsr{6,gtrea{{{convert to real{12615
{{err{1,303{26,cos argument not numeric{{{12616
{{ldr{13,rcval(xr){{{load accumulator with argument{12617
{{cos{{{{take cosine{12618
{{rno{6,exrea{{{if no overflow, return result in ra{12619
{{erb{1,322{26,cos argument is out of range{{{12620
{{ejc{{{{{12621
*      data
{s_dat{ent{{{{entry point{12626
{{jsr{6,xscni{{{prepare to scan argument{12627
{{err{1,075{26,data argument is not a string{{{12628
{{err{1,076{26,data argument is null{{{12629
*      scan out datatype name
{{mov{8,wc{18,=ch_pp{{delimiter one = left paren{12633
{{mov{7,xl{8,wc{{delimiter two = left paren{12634
{{mnz{8,wa{{{skip/trim blanks in prototype{12635
{{jsr{6,xscan{{{scan datatype name{12636
{{bnz{8,wa{6,sdat1{{skip if left paren found{12637
{{erb{1,077{26,data argument is missing a left paren{{{12638
*      here after scanning datatype name
{sdat1{mov{7,xl{7,xr{{save name ptr{12648
{{mov{8,wa{13,sclen(xr){{get length{12650
{{ctb{8,wa{2,scsi_{{compute space needed{12651
{{jsr{6,alost{{{request static store for name{12652
{{mov{11,-(xs){7,xr{{save datatype name{12653
{{mvw{{{{copy name to static{12654
{{mov{7,xr{9,(xs){{get name ptr{12655
{{zer{7,xl{{{scrub dud register{12656
{{jsr{6,gtnvr{{{locate vrblk for datatype name{12657
{{err{1,078{26,data argument has null datatype name{{{12658
{{mov{3,datdv{7,xr{{save vrblk pointer for datatype{12659
{{mov{3,datxs{7,xs{{store starting stack value{12660
{{zer{8,wb{{{zero count of field names{12661
*      loop to scan field names and stack vrblk pointers
{sdat2{mov{8,wc{18,=ch_rp{{delimiter one = right paren{12665
{{mov{7,xl{18,=ch_cm{{delimiter two = comma{12666
{{mnz{8,wa{{{skip/trim blanks in prototype{12667
{{jsr{6,xscan{{{scan next field name{12668
{{bnz{8,wa{6,sdat3{{jump if delimiter found{12669
{{erb{1,079{26,data argument is missing a right paren{{{12670
*      here after scanning out one field name
{sdat3{jsr{6,gtnvr{{{locate vrblk for field name{12674
{{err{1,080{26,data argument has null field name{{{12675
{{mov{11,-(xs){7,xr{{stack vrblk pointer{12676
{{icv{8,wb{{{increment counter{12677
{{beq{8,wa{18,=num02{6,sdat2{loop back if stopped by comma{12678
{{ejc{{{{{12679
*      data (continued)
*      now build the dfblk
{{mov{8,wa{18,=dfsi_{{set size of dfblk standard fields{12685
{{add{8,wa{8,wb{{add number of fields{12686
{{wtb{8,wa{{{convert length to bytes{12687
{{mov{8,wc{8,wb{{preserve no. of fields{12688
{{jsr{6,alost{{{allocate space for dfblk{12689
{{mov{8,wb{8,wc{{get no of fields{12690
{{mov{7,xt{3,datxs{{point to start of stack{12691
{{mov{8,wc{9,(xt){{load datatype name{12692
{{mov{9,(xt){7,xr{{save dfblk pointer on stack{12693
{{mov{10,(xr)+{22,=b_dfc{{store type word{12694
{{mov{10,(xr)+{8,wb{{store number of fields (fargs){12695
{{mov{10,(xr)+{8,wa{{store length (dflen){12696
{{sub{8,wa{19,*pddfs{{compute pdblk length (for dfpdl){12697
{{mov{10,(xr)+{8,wa{{store pdblk length (dfpdl){12698
{{mov{10,(xr)+{8,wc{{store datatype name (dfnam){12699
{{lct{8,wc{8,wb{{copy number of fields{12700
*      loop to move field name vrblk pointers to dfblk
{sdat4{mov{10,(xr)+{11,-(xt){{move one field name vrblk pointer{12704
{{bct{8,wc{6,sdat4{{loop till all moved{12705
*      now define the datatype function
{{mov{8,wc{8,wa{{copy length of pdblk for later loop{12709
{{mov{7,xr{3,datdv{{point to vrblk{12710
{{mov{7,xt{3,datxs{{point back on stack{12711
{{mov{7,xl{9,(xt){{load dfblk pointer{12712
{{jsr{6,dffnc{{{define function{12713
{{ejc{{{{{12714
*      data (continued)
*      loop to build ffblks
*      notice that the ffblks are constructed in reverse order
*      so that the required offsets can be obtained from
*      successive decrementation of the pdblk length (in wc).
{sdat5{mov{8,wa{19,*ffsi_{{set length of ffblk{12725
{{jsr{6,alloc{{{allocate space for ffblk{12726
{{mov{9,(xr){22,=b_ffc{{set type word{12727
{{mov{13,fargs(xr){18,=num01{{store fargs (always one){12728
{{mov{7,xt{3,datxs{{point back on stack{12729
{{mov{13,ffdfp(xr){9,(xt){{copy dfblk ptr to ffblk{12730
{{dca{8,wc{{{decrement old dfpdl to get next ofs{12731
{{mov{13,ffofs(xr){8,wc{{set offset to this field{12732
{{zer{13,ffnxt(xr){{{tentatively set zero forward ptr{12733
{{mov{7,xl{7,xr{{copy ffblk pointer for dffnc{12734
{{mov{7,xr{9,(xs){{load vrblk pointer for field{12735
{{mov{7,xr{13,vrfnc(xr){{load current function pointer{12736
{{bne{9,(xr){22,=b_ffc{6,sdat6{skip if not currently a field func{12737
*      here we must chain an old ffblk ptr to preserve it in the
*      case of multiple field functions with the same name
{{mov{13,ffnxt(xl){7,xr{{link new ffblk to previous chain{12742
*      merge here to define field function
{sdat6{mov{7,xr{10,(xs)+{{load vrblk pointer{12746
{{jsr{6,dffnc{{{define field function{12747
{{bne{7,xs{3,datxs{6,sdat5{loop back till all done{12748
{{ica{7,xs{{{pop dfblk pointer{12749
{{brn{6,exnul{{{return with null result{12750
{{ejc{{{{{12751
*      datatype
{s_dtp{ent{{{{entry point{12755
{{mov{7,xr{10,(xs)+{{load argument{12756
{{jsr{6,dtype{{{get datatype{12757
{{mov{11,-(xs){7,xr{{stack result{12758
{{lcw{7,xr{{{get next code word{12759
{{bri{9,(xr){{{execute it{12760
{{ejc{{{{{12761
*      date
{s_dte{ent{{{{entry point{12765
{{mov{7,xr{10,(xs)+{{load argument{12766
{{jsr{6,gtint{{{convert to an integer{12767
{{err{1,330{26,date argument is not integer{{{12768
{{jsr{6,sysdt{{{call system date routine{12769
{{mov{8,wa{13,num01(xl){{load length for sbstr{12770
{{bze{8,wa{6,exnul{{return null if length is zero{12771
{{zer{8,wb{{{set zero offset{12772
{{jsr{6,sbstr{{{use sbstr to build scblk{12773
{{mov{11,-(xs){7,xr{{stack result{12774
{{lcw{7,xr{{{get next code word{12775
{{bri{9,(xr){{{execute it{12776
{{ejc{{{{{12777
*      define
{s_def{ent{{{{entry point{12781
{{mov{7,xr{10,(xs)+{{load second argument{12782
{{zer{3,deflb{{{zero label pointer in case null{12783
{{beq{7,xr{21,=nulls{6,sdf01{jump if null second argument{12784
{{jsr{6,gtnvr{{{else find vrblk for label{12785
{{ppm{6,sdf12{{{jump if not a variable name{12786
{{mov{3,deflb{7,xr{{else set specified entry{12787
*      scan function name
{sdf01{jsr{6,xscni{{{prepare to scan first argument{12791
{{err{1,081{26,define first argument is not a string{{{12792
{{err{1,082{26,define first argument is null{{{12793
{{mov{8,wc{18,=ch_pp{{delimiter one = left paren{12794
{{mov{7,xl{8,wc{{delimiter two = left paren{12795
{{mnz{8,wa{{{skip/trim blanks in prototype{12796
{{jsr{6,xscan{{{scan out function name{12797
{{bnz{8,wa{6,sdf02{{jump if left paren found{12798
{{erb{1,083{26,define first argument is missing a left paren{{{12799
*      here after scanning out function name
{sdf02{jsr{6,gtnvr{{{get variable name{12803
{{err{1,084{26,define first argument has null function name{{{12804
{{mov{3,defvr{7,xr{{save vrblk pointer for function nam{12805
{{zer{8,wb{{{zero count of arguments{12806
{{mov{3,defxs{7,xs{{save initial stack pointer{12807
{{bnz{3,deflb{6,sdf03{{jump if second argument given{12808
{{mov{3,deflb{7,xr{{else default is function name{12809
*      loop to scan argument names and stack vrblk pointers
{sdf03{mov{8,wc{18,=ch_rp{{delimiter one = right paren{12813
{{mov{7,xl{18,=ch_cm{{delimiter two = comma{12814
{{mnz{8,wa{{{skip/trim blanks in prototype{12815
{{jsr{6,xscan{{{scan out next argument name{12816
{{bnz{8,wa{6,sdf04{{skip if delimiter found{12817
{{erb{1,085{26,null arg name or missing ) in define first arg.{{{12818
{{ejc{{{{{12819
*      define (continued)
*      here after scanning an argument name
{sdf04{bne{7,xr{21,=nulls{6,sdf05{skip if non-null{12825
{{bze{8,wb{6,sdf06{{ignore null if case of no arguments{12826
*      here after dealing with the case of no arguments
{sdf05{jsr{6,gtnvr{{{get vrblk pointer{12830
{{ppm{6,sdf03{{{loop back to ignore null name{12831
{{mov{11,-(xs){7,xr{{stack argument vrblk pointer{12832
{{icv{8,wb{{{increment counter{12833
{{beq{8,wa{18,=num02{6,sdf03{loop back if stopped by a comma{12834
*      here after scanning out function argument names
{sdf06{mov{3,defna{8,wb{{save number of arguments{12838
{{zer{8,wb{{{zero count of locals{12839
*      loop to scan local names and stack vrblk pointers
{sdf07{mov{8,wc{18,=ch_cm{{set delimiter one = comma{12843
{{mov{7,xl{8,wc{{set delimiter two = comma{12844
{{mnz{8,wa{{{skip/trim blanks in prototype{12845
{{jsr{6,xscan{{{scan out next local name{12846
{{bne{7,xr{21,=nulls{6,sdf08{skip if non-null{12847
{{bze{8,wa{6,sdf09{{exit scan if end of string{12848
*      here after scanning out a local name
{sdf08{jsr{6,gtnvr{{{get vrblk pointer{12852
{{ppm{6,sdf07{{{loop back to ignore null name{12853
{{icv{8,wb{{{if ok, increment count{12854
{{mov{11,-(xs){7,xr{{stack vrblk pointer{12855
{{bnz{8,wa{6,sdf07{{loop back if stopped by a comma{12856
{{ejc{{{{{12857
*      define (continued)
*      here after scanning locals, build pfblk
{sdf09{mov{8,wa{8,wb{{copy count of locals{12863
{{add{8,wa{3,defna{{add number of arguments{12864
{{mov{8,wc{8,wa{{set sum args+locals as loop count{12865
{{add{8,wa{18,=pfsi_{{add space for standard fields{12866
{{wtb{8,wa{{{convert length to bytes{12867
{{jsr{6,alloc{{{allocate space for pfblk{12868
{{mov{7,xl{7,xr{{save pointer to pfblk{12869
{{mov{10,(xr)+{22,=b_pfc{{store first word{12870
{{mov{10,(xr)+{3,defna{{store number of arguments{12871
{{mov{10,(xr)+{8,wa{{store length (pflen){12872
{{mov{10,(xr)+{3,defvr{{store vrblk ptr for function name{12873
{{mov{10,(xr)+{8,wb{{store number of locals{12874
{{zer{10,(xr)+{{{deal with label later{12875
{{zer{10,(xr)+{{{zero pfctr{12876
{{zer{10,(xr)+{{{zero pfrtr{12877
{{bze{8,wc{6,sdf11{{skip if no args or locals{12878
{{mov{8,wa{7,xl{{keep pfblk pointer{12879
{{mov{7,xt{3,defxs{{point before arguments{12880
{{lct{8,wc{8,wc{{get count of args+locals for loop{12881
*      loop to move locals and args to pfblk
{sdf10{mov{10,(xr)+{11,-(xt){{store one entry and bump pointers{12885
{{bct{8,wc{6,sdf10{{loop till all stored{12886
{{mov{7,xl{8,wa{{recover pfblk pointer{12887
{{ejc{{{{{12888
*      define (continued)
*      now deal with label
{sdf11{mov{7,xs{3,defxs{{pop stack{12894
{{mov{13,pfcod(xl){3,deflb{{store label vrblk in pfblk{12895
{{mov{7,xr{3,defvr{{point back to vrblk for function{12896
{{jsr{6,dffnc{{{define function{12897
{{brn{6,exnul{{{and exit returning null{12898
*      here for erroneous label
{sdf12{erb{1,086{26,define function entry point is not defined label{{{12902
{{ejc{{{{{12903
*      detach
{s_det{ent{{{{entry point{12907
{{mov{7,xr{10,(xs)+{{load argument{12908
{{jsr{6,gtvar{{{locate variable{12909
{{err{1,087{26,detach argument is not appropriate name{{{12910
{{jsr{6,dtach{{{detach i/o association from name{12911
{{brn{6,exnul{{{return null result{12912
{{ejc{{{{{12913
*      differ
{s_dif{ent{{{{entry point{12917
{{mov{7,xr{10,(xs)+{{load second argument{12918
{{mov{7,xl{10,(xs)+{{load first argument{12919
{{jsr{6,ident{{{call ident comparison routine{12920
{{ppm{6,exfal{{{fail if ident{12921
{{brn{6,exnul{{{return null if differ{12922
{{ejc{{{{{12923
*      dump
{s_dmp{ent{{{{entry point{12927
{{jsr{6,gtsmi{{{load dump arg as small integer{12928
{{err{1,088{26,dump argument is not integer{{{12929
{{err{1,089{26,dump argument is negative or too large{{{12930
{{jsr{6,dumpr{{{else call dump routine{12931
{{brn{6,exnul{{{and return null as result{12932
{{ejc{{{{{12933
*      dupl
{s_dup{ent{{{{entry point{12937
{{jsr{6,gtsmi{{{get second argument as small integr{12938
{{err{1,090{26,dupl second argument is not integer{{{12939
{{ppm{6,sdup7{{{jump if negative or too big{12940
{{mov{8,wb{7,xr{{save duplication factor{12941
{{jsr{6,gtstg{{{get first arg as string{12942
{{ppm{6,sdup4{{{jump if not a string{12943
*      here for case of duplication of a string
{{mti{8,wa{{{acquire length as integer{12947
{{sti{3,dupsi{{{save for the moment{12948
{{mti{8,wb{{{get duplication factor as integer{12949
{{mli{3,dupsi{{{form product{12950
{{iov{6,sdup3{{{jump if overflow{12951
{{ieq{6,exnul{{{return null if result length = 0{12952
{{mfi{8,wa{6,sdup3{{get as addr integer, check ovflo{12953
*      merge here with result length in wa
{sdup1{mov{7,xl{7,xr{{save string pointer{12957
{{jsr{6,alocs{{{allocate space for string{12958
{{mov{11,-(xs){7,xr{{save as result pointer{12959
{{mov{8,wc{7,xl{{save pointer to argument string{12960
{{psc{7,xr{{{prepare to store chars of result{12961
{{lct{8,wb{8,wb{{set counter to control loop{12962
*      loop through duplications
{sdup2{mov{7,xl{8,wc{{point back to argument string{12966
{{mov{8,wa{13,sclen(xl){{get number of characters{12967
{{plc{7,xl{{{point to chars in argument string{12968
{{mvc{{{{move characters to result string{12969
{{bct{8,wb{6,sdup2{{loop till all duplications done{12970
{{zer{7,xl{{{clear garbage value{12971
{{lcw{7,xr{{{get next code word{12972
{{bri{9,(xr){{{execute next code word{12973
{{ejc{{{{{12974
*      dupl (continued)
*      here if too large, set max length and let alocs catch it
{sdup3{mov{8,wa{3,dname{{set impossible length for alocs{12980
{{brn{6,sdup1{{{merge back{12981
*      here if not a string
{sdup4{jsr{6,gtpat{{{convert argument to pattern{12985
{{err{1,091{26,dupl first argument is not a string or pattern{{{12986
*      here to duplicate a pattern argument
{{mov{11,-(xs){7,xr{{store pattern on stack{12990
{{mov{7,xr{21,=ndnth{{start off with null pattern{12991
{{bze{8,wb{6,sdup6{{null pattern is result if dupfac=0{12992
{{mov{11,-(xs){8,wb{{preserve loop count{12993
*      loop to duplicate by successive concatenation
{sdup5{mov{7,xl{7,xr{{copy current value as right argumnt{12997
{{mov{7,xr{13,num01(xs){{get a new copy of left{12998
{{jsr{6,pconc{{{concatenate{12999
{{dcv{9,(xs){{{count down{13000
{{bnz{9,(xs){6,sdup5{{loop{13001
{{ica{7,xs{{{pop loop count{13002
*      here to exit after constructing pattern
{sdup6{mov{9,(xs){7,xr{{store result on stack{13006
{{lcw{7,xr{{{get next code word{13007
{{bri{9,(xr){{{execute next code word{13008
*      fail if second arg is out of range
{sdup7{ica{7,xs{{{pop first argument{13012
{{brn{6,exfal{{{fail{13013
{{ejc{{{{{13014
*      eject
{s_ejc{ent{{{{entry point{13018
{{jsr{6,iofcb{{{call fcblk routine{13019
{{err{1,092{26,eject argument is not a suitable name{{{13020
{{ppm{6,sejc1{{{null argument{13021
{{err{1,093{26,eject file does not exist{{{13022
{{jsr{6,sysef{{{call eject file function{13023
{{err{1,093{26,eject file does not exist{{{13024
{{err{1,094{26,eject file does not permit page eject{{{13025
{{err{1,095{26,eject caused non-recoverable output error{{{13026
{{brn{6,exnul{{{return null as result{13027
*      here to eject standard output file
{sejc1{jsr{6,sysep{{{call routine to eject printer{13031
{{brn{6,exnul{{{exit with null result{13032
{{ejc{{{{{13033
*      endfile
{s_enf{ent{{{{entry point{13037
{{jsr{6,iofcb{{{call fcblk routine{13038
{{err{1,096{26,endfile argument is not a suitable name{{{13039
{{err{1,097{26,endfile argument is null{{{13040
{{err{1,098{26,endfile file does not exist{{{13041
{{jsr{6,sysen{{{call endfile routine{13042
{{err{1,098{26,endfile file does not exist{{{13043
{{err{1,099{26,endfile file does not permit endfile{{{13044
{{err{1,100{26,endfile caused non-recoverable output error{{{13045
{{mov{8,wb{7,xl{{remember vrblk ptr from iofcb call{13046
{{mov{7,xr{7,xl{{copy pointer{13047
*      loop to find trtrf block
{senf1{mov{7,xl{7,xr{{remember previous entry{13051
{{mov{7,xr{13,trval(xr){{chain along{13052
{{bne{9,(xr){22,=b_trt{6,exnul{skip out if chain end{13053
{{bne{13,trtyp(xr){18,=trtfc{6,senf1{loop if not found{13054
{{mov{13,trval(xl){13,trval(xr){{remove trtrf{13055
{{mov{3,enfch{13,trtrf(xr){{point to head of iochn{13056
{{mov{8,wc{13,trfpt(xr){{point to fcblk{13057
{{mov{7,xr{8,wb{{filearg1 vrblk from iofcb{13058
{{jsr{6,setvr{{{reset it{13059
{{mov{7,xl{20,=r_fcb{{ptr to head of fcblk chain{13060
{{sub{7,xl{19,*num02{{adjust ready to enter loop{13061
*      find fcblk
{senf2{mov{7,xr{7,xl{{copy ptr{13065
{{mov{7,xl{13,num02(xl){{get next link{13066
{{bze{7,xl{6,senf4{{stop if chain end{13067
{{beq{13,num03(xl){8,wc{6,senf3{jump if fcblk found{13068
{{brn{6,senf2{{{loop{13069
*      remove fcblk
{senf3{mov{13,num02(xr){13,num02(xl){{delete fcblk from chain{13073
*      loop which detaches all vbls on iochn chain
{senf4{mov{7,xl{3,enfch{{get chain head{13077
{{bze{7,xl{6,exnul{{finished if chain end{13078
{{mov{3,enfch{13,trtrf(xl){{chain along{13079
{{mov{8,wa{13,ionmo(xl){{name offset{13080
{{mov{7,xl{13,ionmb(xl){{name base{13081
{{jsr{6,dtach{{{detach name{13082
{{brn{6,senf4{{{loop till done{13083
{{ejc{{{{{13084
*      eq
{s_eqf{ent{{{{entry point{13088
{{jsr{6,acomp{{{call arithmetic comparison routine{13089
{{err{1,101{26,eq first argument is not numeric{{{13090
{{err{1,102{26,eq second argument is not numeric{{{13091
{{ppm{6,exfal{{{fail if lt{13092
{{ppm{6,exnul{{{return null if eq{13093
{{ppm{6,exfal{{{fail if gt{13094
{{ejc{{{{{13095
*      eval
{s_evl{ent{{{{entry point{13099
{{mov{7,xr{10,(xs)+{{load argument{13100
{{lcw{8,wc{{{load next code word{13106
{{bne{8,wc{21,=ofne_{6,sevl1{jump if called by value{13107
{{scp{7,xl{{{copy code pointer{13108
{{mov{8,wa{9,(xl){{get next code word{13109
{{bne{8,wa{21,=ornm_{6,sevl2{by name unless expression{13110
{{bnz{13,num01(xs){6,sevl2{{jump if by name{13111
*      here if called by value
{sevl1{zer{8,wb{{{set flag for by value{13115
{{mov{11,-(xs){8,wc{{save code word{13117
{{jsr{6,gtexp{{{convert to expression{13118
{{err{1,103{26,eval argument is not expression{{{13119
{{zer{3,r_ccb{{{forget interim code block{13120
{{zer{8,wb{{{set flag for by value{13121
{{jsr{6,evalx{{{evaluate expression by value{13125
{{ppm{6,exfal{{{fail if evaluation fails{13126
{{mov{7,xl{7,xr{{copy result{13127
{{mov{7,xr{9,(xs){{reload next code word{13128
{{mov{9,(xs){7,xl{{stack result{13129
{{bri{9,(xr){{{jump to execute next code word{13130
*      here if called by name
{sevl2{mov{8,wb{18,=num01{{set flag for by name{13134
{{jsr{6,gtexp{{{convert to expression{13136
{{err{1,103{26,eval argument is not expression{{{13137
{{zer{3,r_ccb{{{forget interim code block{13138
{{mov{8,wb{18,=num01{{set flag for by name{13139
{{jsr{6,evalx{{{evaluate expression by name{13141
{{ppm{6,exfal{{{fail if evaluation fails{13142
{{brn{6,exnam{{{exit with name{13143
{{ejc{{{{{13146
*      exit
{s_ext{ent{{{{entry point{13150
{{zer{8,wb{{{clear amount of static shift{13151
{{zer{3,r_ccb{{{forget interim code block{13152
{{zer{3,dnams{{{collect sediment too{13154
{{jsr{6,gbcol{{{compact memory by collecting{13155
{{mov{3,dnams{7,xr{{record new sediment size{13156
{{jsr{6,gtstg{{{{13160
{{err{1,288{26,exit second argument is not a string{{{13161
{{mov{7,xl{7,xr{{copy second arg string pointer{13162
{{jsr{6,gtstg{{{convert arg to string{13163
{{err{1,104{26,exit first argument is not suitable integer or string{{{13164
{{mov{11,-(xs){7,xl{{save second argument{13165
{{mov{7,xl{7,xr{{copy first arg string ptr{13166
{{jsr{6,gtint{{{check it is integer{13167
{{ppm{6,sext1{{{skip if unconvertible{13168
{{zer{7,xl{{{note it is integer{13169
{{ldi{13,icval(xr){{{get integer arg{13170
*      merge to call osint exit routine
{sext1{mov{8,wb{3,r_fcb{{get fcblk chain header{13174
{{mov{7,xr{21,=headv{{point to v.v string{13175
{{mov{8,wa{10,(xs)+{{provide second argument scblk{13176
{{jsr{6,sysxi{{{call external routine{13177
{{err{1,105{26,exit action not available in this implementation{{{13178
{{err{1,106{26,exit action caused irrecoverable error{{{13179
{{ieq{6,exnul{{{return if argument 0{13180
{{igt{6,sext2{{{skip if positive{13181
{{ngi{{{{make positive{13182
*      check for option respecification
*      sysxi returns 0 in wa when a file has been resumed,
*      1 when this is a continuation of an exit(4) or exit(-4)
*      action.
{sext2{mfi{8,wc{{{get value in work reg{13190
{{add{8,wa{8,wc{{prepare to test for continue{13191
{{beq{8,wa{18,=num05{6,sext5{continued execution if 4 plus 1{13192
{{zer{3,gbcnt{{{resuming execution so reset{13193
{{bge{8,wc{18,=num03{6,sext3{skip if was 3 or 4{13194
{{mov{11,-(xs){8,wc{{save value{13195
{{zer{8,wc{{{set to read options{13196
{{jsr{6,prpar{{{read syspp options{13197
{{mov{8,wc{10,(xs)+{{restore value{13198
*      deal with header option (fiddled by prpar)
{sext3{mnz{3,headp{{{assume no headers{13202
{{bne{8,wc{18,=num01{6,sext4{skip if not 1{13203
{{zer{3,headp{{{request header printing{13204
*      almost ready to resume running
{sext4{jsr{6,systm{{{get execution time start (sgd11){13208
{{sti{3,timsx{{{save as initial time{13209
{{ldi{3,kvstc{{{reset to ensure ...{13210
{{sti{3,kvstl{{{... correct execution stats{13211
{{jsr{6,stgcc{{{recompute countdown counters{13212
{{brn{6,exnul{{{resume execution{13213
*      here after exit(4) or exit(-4) -- create save file
*      or load module and continue execution.
*      return integer 1 to signal the continuation of the
*      original execution.
{sext5{mov{7,xr{21,=inton{{integer one{13221
{{brn{6,exixr{{{return as result{13222
{{ejc{{{{{13224
*      exp
{s_exp{ent{{{{entry point{13229
{{mov{7,xr{10,(xs)+{{get argument{13230
{{jsr{6,gtrea{{{convert to real{13231
{{err{1,304{26,exp argument not numeric{{{13232
{{ldr{13,rcval(xr){{{load accumulator with argument{13233
{{etx{{{{take exponential{13234
{{rno{6,exrea{{{if no overflow, return result in ra{13235
{{erb{1,305{26,exp produced real overflow{{{13236
{{ejc{{{{{13237
*      field
{s_fld{ent{{{{entry point{13242
{{jsr{6,gtsmi{{{get second argument (field number){13243
{{err{1,107{26,field second argument is not integer{{{13244
{{ppm{6,exfal{{{fail if out of range{13245
{{mov{8,wb{7,xr{{else save integer value{13246
{{mov{7,xr{10,(xs)+{{load first argument{13247
{{jsr{6,gtnvr{{{point to vrblk{13248
{{ppm{6,sfld1{{{jump (error) if not variable name{13249
{{mov{7,xr{13,vrfnc(xr){{else point to function block{13250
{{bne{9,(xr){22,=b_dfc{6,sfld1{error if not datatype function{13251
*      here if first argument is a datatype function name
{{bze{8,wb{6,exfal{{fail if argument number is zero{13255
{{bgt{8,wb{13,fargs(xr){6,exfal{fail if too large{13256
{{wtb{8,wb{{{else convert to byte offset{13257
{{add{7,xr{8,wb{{point to field name{13258
{{mov{7,xr{13,dfflb(xr){{load vrblk pointer{13259
{{brn{6,exvnm{{{exit to build nmblk{13260
*      here for bad first argument
{sfld1{erb{1,108{26,field first argument is not datatype name{{{13264
{{ejc{{{{{13265
*      fence
{s_fnc{ent{{{{entry point{13269
{{mov{8,wb{22,=p_fnc{{set pcode for p_fnc{13270
{{zer{7,xr{{{p0blk{13271
{{jsr{6,pbild{{{build p_fnc node{13272
{{mov{7,xl{7,xr{{save pointer to it{13273
{{mov{7,xr{10,(xs)+{{get argument{13274
{{jsr{6,gtpat{{{convert to pattern{13275
{{err{1,259{26,fence argument is not pattern{{{13276
{{jsr{6,pconc{{{concatenate to p_fnc node{13277
{{mov{7,xl{7,xr{{save ptr to concatenated pattern{13278
{{mov{8,wb{22,=p_fna{{set for p_fna pcode{13279
{{zer{7,xr{{{p0blk{13280
{{jsr{6,pbild{{{construct p_fna node{13281
{{mov{13,pthen(xr){7,xl{{set pattern as pthen{13282
{{mov{11,-(xs){7,xr{{set as result{13283
{{lcw{7,xr{{{get next code word{13284
{{bri{9,(xr){{{execute next code word{13285
{{ejc{{{{{13286
*      ge
{s_gef{ent{{{{entry point{13290
{{jsr{6,acomp{{{call arithmetic comparison routine{13291
{{err{1,109{26,ge first argument is not numeric{{{13292
{{err{1,110{26,ge second argument is not numeric{{{13293
{{ppm{6,exfal{{{fail if lt{13294
{{ppm{6,exnul{{{return null if eq{13295
{{ppm{6,exnul{{{return null if gt{13296
{{ejc{{{{{13297
*      gt
{s_gtf{ent{{{{entry point{13301
{{jsr{6,acomp{{{call arithmetic comparison routine{13302
{{err{1,111{26,gt first argument is not numeric{{{13303
{{err{1,112{26,gt second argument is not numeric{{{13304
{{ppm{6,exfal{{{fail if lt{13305
{{ppm{6,exfal{{{fail if eq{13306
{{ppm{6,exnul{{{return null if gt{13307
{{ejc{{{{{13308
*      host
{s_hst{ent{{{{entry point{13312
{{mov{8,wc{10,(xs)+{{get fifth arg{13313
{{mov{8,wb{10,(xs)+{{get fourth arg{13314
{{mov{7,xr{10,(xs)+{{get third arg{13315
{{mov{7,xl{10,(xs)+{{get second arg{13316
{{mov{8,wa{10,(xs)+{{get first arg{13317
{{jsr{6,syshs{{{enter syshs routine{13318
{{err{1,254{26,erroneous argument for host{{{13319
{{err{1,255{26,error during execution of host{{{13320
{{ppm{6,shst1{{{store host string{13321
{{ppm{6,exnul{{{return null result{13322
{{ppm{6,exixr{{{return xr{13323
{{ppm{6,exfal{{{fail return{13324
{{ppm{6,shst3{{{store actual string{13325
{{ppm{6,shst4{{{return copy of xr{13326
*      return host string
{shst1{bze{7,xl{6,exnul{{null string if syshs uncooperative{13330
{{mov{8,wa{13,sclen(xl){{length{13331
{{zer{8,wb{{{zero offset{13332
*      copy string and return
{shst2{jsr{6,sbstr{{{build copy of string{13336
{{mov{11,-(xs){7,xr{{stack the result{13337
{{lcw{7,xr{{{load next code word{13338
{{bri{9,(xr){{{execute it{13339
*      return actual string pointed to by xl
{shst3{zer{8,wb{{{treat xl like an scblk ptr{13343
{{sub{8,wb{18,=cfp_f{{by creating a negative offset{13344
{{brn{6,shst2{{{join to copy string{13345
*      return copy of block pointed to by xr
{shst4{mov{11,-(xs){7,xr{{stack results{13349
{{jsr{6,copyb{{{make copy of block{13350
{{ppm{6,exits{{{if not an aggregate structure{13351
{{brn{6,exsid{{{set current id value otherwise{13352
{{ejc{{{{{13353
*      ident
{s_idn{ent{{{{entry point{13357
{{mov{7,xr{10,(xs)+{{load second argument{13358
{{mov{7,xl{10,(xs)+{{load first argument{13359
{{jsr{6,ident{{{call ident comparison routine{13360
{{ppm{6,exnul{{{return null if ident{13361
{{brn{6,exfal{{{fail if differ{13362
{{ejc{{{{{13363
*      input
{s_inp{ent{{{{entry point{13367
{{zer{8,wb{{{input flag{13368
{{jsr{6,ioput{{{call input/output assoc. routine{13369
{{err{1,113{26,input third argument is not a string{{{13370
{{err{1,114{26,inappropriate second argument for input{{{13371
{{err{1,115{26,inappropriate first argument for input{{{13372
{{err{1,116{26,inappropriate file specification for input{{{13373
{{ppm{6,exfal{{{fail if file does not exist{13374
{{err{1,117{26,input file cannot be read{{{13375
{{err{1,289{26,input channel currently in use{{{13376
{{brn{6,exnul{{{return null string{13377
{{ejc{{{{{13378
*      integer
{s_int{ent{{{{entry point{13411
{{mov{7,xr{10,(xs)+{{load argument{13412
{{jsr{6,gtnum{{{convert to numeric{13413
{{ppm{6,exfal{{{fail if non-numeric{13414
{{beq{8,wa{22,=b_icl{6,exnul{return null if integer{13415
{{brn{6,exfal{{{fail if real{13416
{{ejc{{{{{13417
*      item
*      item does not permit the direct (fast) call so that
*      wa contains the actual number of arguments passed.
{s_itm{ent{{{{entry point{13424
*      deal with case of no args
{{bnz{8,wa{6,sitm1{{jump if at least one arg{13428
{{mov{11,-(xs){21,=nulls{{else supply garbage null arg{13429
{{mov{8,wa{18,=num01{{and fix argument count{13430
*      check for name/value cases
{sitm1{scp{7,xr{{{get current code pointer{13434
{{mov{7,xl{9,(xr){{load next code word{13435
{{dcv{8,wa{{{get number of subscripts{13436
{{mov{7,xr{8,wa{{copy for arref{13437
{{beq{7,xl{21,=ofne_{6,sitm2{jump if called by name{13438
*      here if called by value
{{zer{8,wb{{{set code for call by value{13442
{{brn{6,arref{{{off to array reference routine{13443
*      here for call by name
{sitm2{mnz{8,wb{{{set code for call by name{13447
{{lcw{8,wa{{{load and ignore ofne_ call{13448
{{brn{6,arref{{{off to array reference routine{13449
{{ejc{{{{{13450
*      le
{s_lef{ent{{{{entry point{13454
{{jsr{6,acomp{{{call arithmetic comparison routine{13455
{{err{1,118{26,le first argument is not numeric{{{13456
{{err{1,119{26,le second argument is not numeric{{{13457
{{ppm{6,exnul{{{return null if lt{13458
{{ppm{6,exnul{{{return null if eq{13459
{{ppm{6,exfal{{{fail if gt{13460
{{ejc{{{{{13461
*      len
{s_len{ent{{{{entry point{13465
{{mov{8,wb{22,=p_len{{set pcode for integer arg case{13466
{{mov{8,wa{22,=p_lnd{{set pcode for expr arg case{13467
{{jsr{6,patin{{{call common routine to build node{13468
{{err{1,120{26,len argument is not integer or expression{{{13469
{{err{1,121{26,len argument is negative or too large{{{13470
{{mov{11,-(xs){7,xr{{stack result{13471
{{lcw{7,xr{{{get next code word{13472
{{bri{9,(xr){{{execute it{13473
{{ejc{{{{{13474
*      leq
{s_leq{ent{{{{entry point{13478
{{jsr{6,lcomp{{{call string comparison routine{13479
{{err{1,122{26,leq first argument is not a string{{{13480
{{err{1,123{26,leq second argument is not a string{{{13481
{{ppm{6,exfal{{{fail if llt{13482
{{ppm{6,exnul{{{return null if leq{13483
{{ppm{6,exfal{{{fail if lgt{13484
{{ejc{{{{{13485
*      lge
{s_lge{ent{{{{entry point{13489
{{jsr{6,lcomp{{{call string comparison routine{13490
{{err{1,124{26,lge first argument is not a string{{{13491
{{err{1,125{26,lge second argument is not a string{{{13492
{{ppm{6,exfal{{{fail if llt{13493
{{ppm{6,exnul{{{return null if leq{13494
{{ppm{6,exnul{{{return null if lgt{13495
{{ejc{{{{{13496
*      lgt
{s_lgt{ent{{{{entry point{13500
{{jsr{6,lcomp{{{call string comparison routine{13501
{{err{1,126{26,lgt first argument is not a string{{{13502
{{err{1,127{26,lgt second argument is not a string{{{13503
{{ppm{6,exfal{{{fail if llt{13504
{{ppm{6,exfal{{{fail if leq{13505
{{ppm{6,exnul{{{return null if lgt{13506
{{ejc{{{{{13507
*      lle
{s_lle{ent{{{{entry point{13511
{{jsr{6,lcomp{{{call string comparison routine{13512
{{err{1,128{26,lle first argument is not a string{{{13513
{{err{1,129{26,lle second argument is not a string{{{13514
{{ppm{6,exnul{{{return null if llt{13515
{{ppm{6,exnul{{{return null if leq{13516
{{ppm{6,exfal{{{fail if lgt{13517
{{ejc{{{{{13518
*      llt
{s_llt{ent{{{{entry point{13522
{{jsr{6,lcomp{{{call string comparison routine{13523
{{err{1,130{26,llt first argument is not a string{{{13524
{{err{1,131{26,llt second argument is not a string{{{13525
{{ppm{6,exnul{{{return null if llt{13526
{{ppm{6,exfal{{{fail if leq{13527
{{ppm{6,exfal{{{fail if lgt{13528
{{ejc{{{{{13529
*      lne
{s_lne{ent{{{{entry point{13533
{{jsr{6,lcomp{{{call string comparison routine{13534
{{err{1,132{26,lne first argument is not a string{{{13535
{{err{1,133{26,lne second argument is not a string{{{13536
{{ppm{6,exnul{{{return null if llt{13537
{{ppm{6,exfal{{{fail if leq{13538
{{ppm{6,exnul{{{return null if lgt{13539
{{ejc{{{{{13540
*      ln
{s_lnf{ent{{{{entry point{13545
{{mov{7,xr{10,(xs)+{{get argument{13546
{{jsr{6,gtrea{{{convert to real{13547
{{err{1,306{26,ln argument not numeric{{{13548
{{ldr{13,rcval(xr){{{load accumulator with argument{13549
{{req{6,slnf1{{{overflow if argument is 0{13550
{{rlt{6,slnf2{{{error if argument less than 0{13551
{{lnf{{{{take natural logarithm{13552
{{rno{6,exrea{{{if no overflow, return result in ra{13553
{slnf1{erb{1,307{26,ln produced real overflow{{{13554
*      here for bad argument
{slnf2{erb{1,315{26,ln argument negative{{{13558
{{ejc{{{{{13559
*      local
{s_loc{ent{{{{entry point{13564
{{jsr{6,gtsmi{{{get second argument (local number){13565
{{err{1,134{26,local second argument is not integer{{{13566
{{ppm{6,exfal{{{fail if out of range{13567
{{mov{8,wb{7,xr{{save local number{13568
{{mov{7,xr{10,(xs)+{{load first argument{13569
{{jsr{6,gtnvr{{{point to vrblk{13570
{{ppm{6,sloc1{{{jump if not variable name{13571
{{mov{7,xr{13,vrfnc(xr){{else load function pointer{13572
{{bne{9,(xr){22,=b_pfc{6,sloc1{jump if not program defined{13573
*      here if we have a program defined function name
{{bze{8,wb{6,exfal{{fail if second arg is zero{13577
{{bgt{8,wb{13,pfnlo(xr){6,exfal{or too large{13578
{{add{8,wb{13,fargs(xr){{else adjust offset to include args{13579
{{wtb{8,wb{{{convert to bytes{13580
{{add{7,xr{8,wb{{point to local pointer{13581
{{mov{7,xr{13,pfagb(xr){{load vrblk pointer{13582
{{brn{6,exvnm{{{exit building nmblk{13583
*      here if first argument is no good
{sloc1{erb{1,135{26,local first arg is not a program function name{{{13587
{{ejc{{{{{13590
*      load
{s_lod{ent{{{{entry point{13594
{{jsr{6,gtstg{{{load library name{13595
{{err{1,136{26,load second argument is not a string{{{13596
{{mov{7,xl{7,xr{{save library name{13597
{{jsr{6,xscni{{{prepare to scan first argument{13598
{{err{1,137{26,load first argument is not a string{{{13599
{{err{1,138{26,load first argument is null{{{13600
{{mov{11,-(xs){7,xl{{stack library name{13601
{{mov{8,wc{18,=ch_pp{{set delimiter one = left paren{13602
{{mov{7,xl{8,wc{{set delimiter two = left paren{13603
{{mnz{8,wa{{{skip/trim blanks in prototype{13604
{{jsr{6,xscan{{{scan function name{13605
{{mov{11,-(xs){7,xr{{save ptr to function name{13606
{{bnz{8,wa{6,slod1{{jump if left paren found{13607
{{erb{1,139{26,load first argument is missing a left paren{{{13608
*      here after successfully scanning function name
{slod1{jsr{6,gtnvr{{{locate vrblk{13612
{{err{1,140{26,load first argument has null function name{{{13613
{{mov{3,lodfn{7,xr{{save vrblk pointer{13614
{{zer{3,lodna{{{zero count of arguments{13615
*      loop to scan argument datatype names
{slod2{mov{8,wc{18,=ch_rp{{delimiter one is right paren{13619
{{mov{7,xl{18,=ch_cm{{delimiter two is comma{13620
{{mnz{8,wa{{{skip/trim blanks in prototype{13621
{{jsr{6,xscan{{{scan next argument name{13622
{{icv{3,lodna{{{bump argument count{13623
{{bnz{8,wa{6,slod3{{jump if ok delimiter was found{13624
{{erb{1,141{26,load first argument is missing a right paren{{{13625
{{ejc{{{{{13626
*      load (continued)
*      come here to analyze the datatype pointer in (xr). this
*      code is used both for arguments (wa=1,2) and for the
*      result datatype (with wa set to zero).
{slod3{mov{11,-(xs){7,xr{{stack datatype name pointer{13642
{{mov{8,wb{18,=num01{{set string code in case{13644
{{mov{7,xl{21,=scstr{{point to /string/{13645
{{jsr{6,ident{{{check for match{13646
{{ppm{6,slod4{{{jump if match{13647
{{mov{7,xr{9,(xs){{else reload name{13648
{{add{8,wb{8,wb{{set code for integer (2){13649
{{mov{7,xl{21,=scint{{point to /integer/{13650
{{jsr{6,ident{{{check for match{13651
{{ppm{6,slod4{{{jump if match{13652
{{mov{7,xr{9,(xs){{else reload string pointer{13655
{{icv{8,wb{{{set code for real (3){13656
{{mov{7,xl{21,=screa{{point to /real/{13657
{{jsr{6,ident{{{check for match{13658
{{ppm{6,slod4{{{jump if match{13659
{{mov{7,xr{9,(xs){{reload string pointer{13662
{{icv{8,wb{{{code for file (4, or 3 if no reals){13663
{{mov{7,xl{21,=scfil{{point to /file/{13664
{{jsr{6,ident{{{check for match{13665
{{ppm{6,slod4{{{jump if match{13666
{{zer{8,wb{{{else get code for no convert{13668
*      merge here with proper datatype code in wb
{slod4{mov{9,(xs){8,wb{{store code on stack{13672
{{beq{8,wa{18,=num02{6,slod2{loop back if arg stopped by comma{13673
{{bze{8,wa{6,slod5{{jump if that was the result type{13674
*      here we scan out the result type (arg stopped by ) )
{{mov{8,wc{3,mxlen{{set dummy (impossible) delimiter 1{13678
{{mov{7,xl{8,wc{{and delimiter two{13679
{{mnz{8,wa{{{skip/trim blanks in prototype{13680
{{jsr{6,xscan{{{scan result name{13681
{{zer{8,wa{{{set code for processing result{13682
{{brn{6,slod3{{{jump back to process result name{13683
{{ejc{{{{{13684
*      load (continued)
*      here after processing all args and result
{slod5{mov{8,wa{3,lodna{{get number of arguments{13690
{{mov{8,wc{8,wa{{copy for later{13691
{{wtb{8,wa{{{convert length to bytes{13692
{{add{8,wa{19,*efsi_{{add space for standard fields{13693
{{jsr{6,alloc{{{allocate efblk{13694
{{mov{9,(xr){22,=b_efc{{set type word{13695
{{mov{13,fargs(xr){8,wc{{set number of arguments{13696
{{zer{13,efuse(xr){{{set use count (dffnc will set to 1){13697
{{zer{13,efcod(xr){{{zero code pointer for now{13698
{{mov{13,efrsl(xr){10,(xs)+{{store result type code{13699
{{mov{13,efvar(xr){3,lodfn{{store function vrblk pointer{13700
{{mov{13,eflen(xr){8,wa{{store efblk length{13701
{{mov{8,wb{7,xr{{save efblk pointer{13702
{{add{7,xr{8,wa{{point past end of efblk{13703
{{lct{8,wc{8,wc{{set number of arguments for loop{13704
*      loop to set argument type codes from stack
{slod6{mov{11,-(xr){10,(xs)+{{store one type code from stack{13708
{{bct{8,wc{6,slod6{{loop till all stored{13709
*      now load the external function and perform definition
{{mov{7,xr{10,(xs)+{{load function string name{13713
{{mov{7,xl{9,(xs){{load library name{13718
{{mov{9,(xs){8,wb{{store efblk pointer{13719
{{jsr{6,sysld{{{call function to load external func{13720
{{err{1,142{26,load function does not exist{{{13721
{{err{1,143{26,load function caused input error during load{{{13722
{{err{1,328{26,load function - insufficient memory{{{13723
{{mov{7,xl{10,(xs)+{{recall efblk pointer{13724
{{mov{13,efcod(xl){7,xr{{store code pointer{13725
{{mov{7,xr{3,lodfn{{point to vrblk for function{13726
{{jsr{6,dffnc{{{perform function definition{13727
{{brn{6,exnul{{{return null result{13728
{{ejc{{{{{13730
*      lpad
{s_lpd{ent{{{{entry point{13734
{{jsr{6,gtstg{{{get pad character{13735
{{err{1,144{26,lpad third argument is not a string{{{13736
{{plc{7,xr{{{point to character (null is blank){13737
{{lch{8,wb{9,(xr){{load pad character{13738
{{jsr{6,gtsmi{{{get pad length{13739
{{err{1,145{26,lpad second argument is not integer{{{13740
{{ppm{6,slpd4{{{skip if negative or large{13741
*      merge to check first arg
{slpd1{jsr{6,gtstg{{{get first argument (string to pad){13745
{{err{1,146{26,lpad first argument is not a string{{{13746
{{bge{8,wa{8,wc{6,exixr{return 1st arg if too long to pad{13747
{{mov{7,xl{7,xr{{else move ptr to string to pad{13748
*      now we are ready for the pad
*      (xl)                  pointer to string to pad
*      (wb)                  pad character
*      (wc)                  length to pad string to
{{mov{8,wa{8,wc{{copy length{13756
{{jsr{6,alocs{{{allocate scblk for new string{13757
{{mov{11,-(xs){7,xr{{save as result{13758
{{mov{8,wa{13,sclen(xl){{load length of argument{13759
{{sub{8,wc{8,wa{{calculate number of pad characters{13760
{{psc{7,xr{{{point to chars in result string{13761
{{lct{8,wc{8,wc{{set counter for pad loop{13762
*      loop to perform pad
{slpd2{sch{8,wb{10,(xr)+{{store pad character, bump ptr{13766
{{bct{8,wc{6,slpd2{{loop till all pad chars stored{13767
{{csc{7,xr{{{complete store characters{13768
*      now copy string
{{bze{8,wa{6,slpd3{{exit if null string{13772
{{plc{7,xl{{{else point to chars in argument{13773
{{mvc{{{{move characters to result string{13774
{{zer{7,xl{{{clear garbage xl{13775
*      here to exit with result on stack
{slpd3{lcw{7,xr{{{load next code word{13779
{{bri{9,(xr){{{execute it{13780
*      here if 2nd arg is negative or large
{slpd4{zer{8,wc{{{zero pad count{13784
{{brn{6,slpd1{{{merge{13785
{{ejc{{{{{13786
*      lt
{s_ltf{ent{{{{entry point{13790
{{jsr{6,acomp{{{call arithmetic comparison routine{13791
{{err{1,147{26,lt first argument is not numeric{{{13792
{{err{1,148{26,lt second argument is not numeric{{{13793
{{ppm{6,exnul{{{return null if lt{13794
{{ppm{6,exfal{{{fail if eq{13795
{{ppm{6,exfal{{{fail if gt{13796
{{ejc{{{{{13797
*      ne
{s_nef{ent{{{{entry point{13801
{{jsr{6,acomp{{{call arithmetic comparison routine{13802
{{err{1,149{26,ne first argument is not numeric{{{13803
{{err{1,150{26,ne second argument is not numeric{{{13804
{{ppm{6,exnul{{{return null if lt{13805
{{ppm{6,exfal{{{fail if eq{13806
{{ppm{6,exnul{{{return null if gt{13807
{{ejc{{{{{13808
*      notany
{s_nay{ent{{{{entry point{13812
{{mov{8,wb{22,=p_nas{{set pcode for single char arg{13813
{{mov{7,xl{22,=p_nay{{pcode for multi-char arg{13814
{{mov{8,wc{22,=p_nad{{set pcode for expr arg{13815
{{jsr{6,patst{{{call common routine to build node{13816
{{err{1,151{26,notany argument is not a string or expression{{{13817
{{mov{11,-(xs){7,xr{{stack result{13818
{{lcw{7,xr{{{get next code word{13819
{{bri{9,(xr){{{execute it{13820
{{ejc{{{{{13821
*      opsyn
{s_ops{ent{{{{entry point{13825
{{jsr{6,gtsmi{{{load third argument{13826
{{err{1,152{26,opsyn third argument is not integer{{{13827
{{err{1,153{26,opsyn third argument is negative or too large{{{13828
{{mov{8,wb{8,wc{{if ok, save third argumnet{13829
{{mov{7,xr{10,(xs)+{{load second argument{13830
{{jsr{6,gtnvr{{{locate variable block{13831
{{err{1,154{26,opsyn second arg is not natural variable name{{{13832
{{mov{7,xl{13,vrfnc(xr){{if ok, load function block pointer{13833
{{bnz{8,wb{6,sops2{{jump if operator opsyn case{13834
*      here for function opsyn (third arg zero)
{{mov{7,xr{10,(xs)+{{load first argument{13838
{{jsr{6,gtnvr{{{get vrblk pointer{13839
{{err{1,155{26,opsyn first arg is not natural variable name{{{13840
*      merge here to perform function definition
{sops1{jsr{6,dffnc{{{call function definer{13844
{{brn{6,exnul{{{exit with null result{13845
*      here for operator opsyn (third arg non-zero)
{sops2{jsr{6,gtstg{{{get operator name{13849
{{ppm{6,sops5{{{jump if not string{13850
{{bne{8,wa{18,=num01{6,sops5{error if not one char long{13851
{{plc{7,xr{{{else point to character{13852
{{lch{8,wc{9,(xr){{load character name{13853
{{ejc{{{{{13854
*      opsyn (continued)
*      now set to search for matching unary or binary operator
*      name as appropriate. note that there are =opbun undefined
*      binary operators and =opuun undefined unary operators.
{{mov{8,wa{20,=r_uub{{point to unop pointers in case{13862
{{mov{7,xr{21,=opnsu{{point to names of unary operators{13863
{{add{8,wb{18,=opbun{{add no. of undefined binary ops{13864
{{beq{8,wb{18,=opuun{6,sops3{jump if unop (third arg was 1){13865
{{mov{8,wa{20,=r_uba{{else point to binary operator ptrs{13866
{{mov{7,xr{21,=opsnb{{point to names of binary operators{13867
{{mov{8,wb{18,=opbun{{set number of undefined binops{13868
*      merge here to check list (wb = number to check)
{sops3{lct{8,wb{8,wb{{set counter to control loop{13872
*      loop to search for name match
{sops4{beq{8,wc{9,(xr){6,sops6{jump if names match{13876
{{ica{8,wa{{{else push pointer to function ptr{13877
{{ica{7,xr{{{bump pointer{13878
{{bct{8,wb{6,sops4{{loop back till all checked{13879
*      here if bad operator name
{sops5{erb{1,156{26,opsyn first arg is not correct operator name{{{13883
*      come here on finding a match in the operator name table
{sops6{mov{7,xr{8,wa{{copy pointer to function block ptr{13887
{{sub{7,xr{19,*vrfnc{{make it look like dummy vrblk{13888
{{brn{6,sops1{{{merge back to define operator{13889
{{ejc{{{{{13890
*      output
{s_oup{ent{{{{entry point{13915
{{mov{8,wb{18,=num03{{output flag{13916
{{jsr{6,ioput{{{call input/output assoc. routine{13917
{{err{1,157{26,output third argument is not a string{{{13918
{{err{1,158{26,inappropriate second argument for output{{{13919
{{err{1,159{26,inappropriate first argument for output{{{13920
{{err{1,160{26,inappropriate file specification for output{{{13921
{{ppm{6,exfal{{{fail if file does not exist{13922
{{err{1,161{26,output file cannot be written to{{{13923
{{err{1,290{26,output channel currently in use{{{13924
{{brn{6,exnul{{{return null string{13925
{{ejc{{{{{13926
*      pos
{s_pos{ent{{{{entry point{13930
{{mov{8,wb{22,=p_pos{{set pcode for integer arg case{13931
{{mov{8,wa{22,=p_psd{{set pcode for expression arg case{13932
{{jsr{6,patin{{{call common routine to build node{13933
{{err{1,162{26,pos argument is not integer or expression{{{13934
{{err{1,163{26,pos argument is negative or too large{{{13935
{{mov{11,-(xs){7,xr{{stack result{13936
{{lcw{7,xr{{{get next code word{13937
{{bri{9,(xr){{{execute it{13938
{{ejc{{{{{13939
*      prototype
{s_pro{ent{{{{entry point{13943
{{mov{7,xr{10,(xs)+{{load argument{13944
{{mov{8,wb{13,tblen(xr){{length if table, vector (=vclen){13945
{{btw{8,wb{{{convert to words{13946
{{mov{8,wa{9,(xr){{load type word of argument block{13947
{{beq{8,wa{22,=b_art{6,spro4{jump if array{13948
{{beq{8,wa{22,=b_tbt{6,spro1{jump if table{13949
{{beq{8,wa{22,=b_vct{6,spro3{jump if vector{13950
{{erb{1,164{26,prototype argument is not valid object{{{13955
*      here for table
{spro1{sub{8,wb{18,=tbsi_{{subtract standard fields{13959
*      merge for vector
{spro2{mti{8,wb{{{convert to integer{13963
{{brn{6,exint{{{exit with integer result{13964
*      here for vector
{spro3{sub{8,wb{18,=vcsi_{{subtract standard fields{13968
{{brn{6,spro2{{{merge{13969
*      here for array
{spro4{add{7,xr{13,arofs(xr){{point to prototype field{13973
{{mov{7,xr{9,(xr){{load prototype{13974
{{mov{11,-(xs){7,xr{{stack result{13975
{{lcw{7,xr{{{get next code word{13976
{{bri{9,(xr){{{execute it{13977
{{ejc{{{{{13987
*      remdr
{s_rmd{ent{{{{entry point{13991
{{jsr{6,arith{{{get two integers or two reals{13993
{{err{1,166{26,remdr first argument is not numeric{{{13994
{{err{1,165{26,remdr second argument is not numeric{{{13995
{{ppm{6,srm06{{{if real{13996
*      both arguments integer
{{zer{8,wb{{{set positive flag{14013
{{ldi{13,icval(xr){{{load left argument value{14014
{{ige{6,srm01{{{jump if positive{14015
{{mnz{8,wb{{{set negative flag{14016
{srm01{rmi{13,icval(xl){{{get remainder{14017
{{iov{6,srm05{{{error if overflow{14018
*      make sign of result match sign of first argument
{{bze{8,wb{6,srm03{{if result should be positive{14022
{{ile{6,exint{{{if should be negative, and is{14023
{srm02{ngi{{{{adjust sign of result{14024
{{brn{6,exint{{{return result{14025
{srm03{ilt{6,srm02{{{should be pos, and result negative{14026
{{brn{6,exint{{{should be positive, and is{14027
*      fail first argument
{srm04{erb{1,166{26,remdr first argument is not numeric{{{14031
*      fail if overflow
{srm05{erb{1,167{26,remdr caused integer overflow{{{14035
*      here with 1st argument in (xr), 2nd in (xl), both real
*      result = n1 - chop(n1/n2)*n2
{srm06{zer{8,wb{{{set positive flag{14042
{{ldr{13,rcval(xr){{{load left argument value{14043
{{rge{6,srm07{{{jump if positive{14044
{{mnz{8,wb{{{set negative flag{14045
{srm07{dvr{13,rcval(xl){{{compute n1/n2{14046
{{rov{6,srm10{{{jump if overflow{14047
{{chp{{{{chop result{14048
{{mlr{13,rcval(xl){{{times n2{14049
{{sbr{13,rcval(xr){{{compute difference{14050
*      make sign of result match sign of first argument
*      -result is in ra at this point
{{bze{8,wb{6,srm09{{if result should be positive{14055
{{rle{6,exrea{{{if should be negative, and is{14056
{srm08{ngr{{{{adjust sign of result{14057
{{brn{6,exrea{{{return result{14058
{srm09{rlt{6,srm08{{{should be pos, and result negative{14059
{{brn{6,exrea{{{should be positive, and is{14060
*      fail if overflow
{srm10{erb{1,312{26,remdr caused real overflow{{{14064
{{ejc{{{{{14066
*      replace
*      the actual replace operation uses an scblk whose cfp_a
*      chars contain the translated versions of all the chars.
*      the table pointer is remembered from call to call and
*      the table is only built when the arguments change.
*      we also perform an optimization gleaned from spitbol 370.
*      if the second argument is &alphabet, there is no need to
*      to build a replace table.  the third argument can be
*      used directly as the replace table.
{s_rpl{ent{{{{entry point{14080
{{jsr{6,gtstg{{{load third argument as string{14081
{{err{1,168{26,replace third argument is not a string{{{14082
{{mov{7,xl{7,xr{{save third arg ptr{14083
{{jsr{6,gtstg{{{get second argument{14084
{{err{1,169{26,replace second argument is not a string{{{14085
*      check to see if this is the same table as last time
{{bne{7,xr{3,r_ra2{6,srpl1{jump if 2nd argument different{14089
{{beq{7,xl{3,r_ra3{6,srpl4{jump if args same as last time{14090
*      here we build a new replace table (note wa = 2nd arg len)
{srpl1{mov{8,wb{13,sclen(xl){{load 3rd argument length{14094
{{bne{8,wa{8,wb{6,srpl6{jump if arguments not same length{14095
{{beq{7,xr{3,kvalp{6,srpl5{jump if 2nd arg is alphabet string{14096
{{bze{8,wb{6,srpl6{{jump if null 2nd argument{14097
{{mov{3,r_ra3{7,xl{{save third arg for next time in{14098
{{mov{3,r_ra2{7,xr{{save second arg for next time in{14099
{{mov{7,xl{3,kvalp{{point to alphabet string{14100
{{mov{8,wa{13,sclen(xl){{load alphabet scblk length{14101
{{mov{7,xr{3,r_rpt{{point to current table (if any){14102
{{bnz{7,xr{6,srpl2{{jump if we already have a table{14103
*      here we allocate a new table
{{jsr{6,alocs{{{allocate new table{14107
{{mov{8,wa{8,wc{{keep scblk length{14108
{{mov{3,r_rpt{7,xr{{save table pointer for next time{14109
*      merge here with pointer to new table block in (xr)
{srpl2{ctb{8,wa{2,scsi_{{compute length of scblk{14113
{{mvw{{{{copy to get initial table values{14114
{{ejc{{{{{14115
*      replace (continued)
*      now we must plug selected entries as required. note that
*      we are short of index registers for the following loop.
*      hence the need to repeatedly re-initialise char ptr xl
{{mov{7,xl{3,r_ra2{{point to second argument{14123
{{lct{8,wb{8,wb{{number of chars to plug{14124
{{zer{8,wc{{{zero char offset{14125
{{mov{7,xr{3,r_ra3{{point to 3rd arg{14126
{{plc{7,xr{{{get char ptr for 3rd arg{14127
*      loop to plug chars
{srpl3{mov{7,xl{3,r_ra2{{point to 2nd arg{14131
{{plc{7,xl{8,wc{{point to next char{14132
{{icv{8,wc{{{increment offset{14133
{{lch{8,wa{9,(xl){{get next char{14134
{{mov{7,xl{3,r_rpt{{point to translate table{14135
{{psc{7,xl{8,wa{{convert char to offset into table{14136
{{lch{8,wa{10,(xr)+{{get translated char{14137
{{sch{8,wa{9,(xl){{store in table{14138
{{csc{7,xl{{{complete store characters{14139
{{bct{8,wb{6,srpl3{{loop till done{14140
{{ejc{{{{{14141
*      replace (continued)
*      here to use r_rpt as replace table.
{srpl4{mov{7,xl{3,r_rpt{{replace table to use{14147
*      here to perform translate using table in xl.
{srpl5{jsr{6,gtstg{{{get first argument{14152
{{err{1,170{26,replace first argument is not a string{{{14153
{{bze{8,wa{6,exnul{{return null if null argument{14162
{{mov{11,-(xs){7,xl{{stack replace table to use{14163
{{mov{7,xl{7,xr{{copy pointer{14164
{{mov{8,wc{8,wa{{save length{14165
{{ctb{8,wa{2,schar{{get scblk length{14166
{{jsr{6,alloc{{{allocate space for copy{14167
{{mov{8,wb{7,xr{{save address of copy{14168
{{mvw{{{{move scblk contents to copy{14169
{{mov{7,xr{10,(xs)+{{unstack replace table{14170
{{plc{7,xr{{{point to chars of table{14171
{{mov{7,xl{8,wb{{point to string to translate{14172
{{plc{7,xl{{{point to chars of string{14173
{{mov{8,wa{8,wc{{set number of chars to translate{14174
{{trc{{{{perform translation{14175
{srpl8{mov{11,-(xs){8,wb{{stack result{14176
{{lcw{7,xr{{{load next code word{14177
{{bri{9,(xr){{{execute it{14178
*      error point
{srpl6{erb{1,171{26,null or unequally long 2nd, 3rd args to replace{{{14182
{{ejc{{{{{14197
*      rewind
{s_rew{ent{{{{entry point{14201
{{jsr{6,iofcb{{{call fcblk routine{14202
{{err{1,172{26,rewind argument is not a suitable name{{{14203
{{err{1,173{26,rewind argument is null{{{14204
{{err{1,174{26,rewind file does not exist{{{14205
{{jsr{6,sysrw{{{call system rewind function{14206
{{err{1,174{26,rewind file does not exist{{{14207
{{err{1,175{26,rewind file does not permit rewind{{{14208
{{err{1,176{26,rewind caused non-recoverable error{{{14209
{{brn{6,exnul{{{exit with null result if no error{14210
{{ejc{{{{{14211
*      reverse
{s_rvs{ent{{{{entry point{14215
{{jsr{6,gtstg{{{load string argument{14217
{{err{1,177{26,reverse argument is not a string{{{14218
{{bze{8,wa{6,exixr{{return argument if null{14224
{{mov{7,xl{7,xr{{else save pointer to string arg{14225
{{jsr{6,alocs{{{allocate space for new scblk{14226
{{mov{11,-(xs){7,xr{{store scblk ptr on stack as result{14227
{{psc{7,xr{{{prepare to store in new scblk{14228
{{plc{7,xl{8,wc{{point past last char in argument{14229
{{lct{8,wc{8,wc{{set loop counter{14230
*      loop to move chars in reverse order
{srvs1{lch{8,wb{11,-(xl){{load next char from argument{14234
{{sch{8,wb{10,(xr)+{{store in result{14235
{{bct{8,wc{6,srvs1{{loop till all moved{14236
*      here when complete to execute next code word
{srvs4{csc{7,xr{{{complete store characters{14240
{{zer{7,xl{{{clear garbage xl{14241
{srvs2{lcw{7,xr{{{load next code word{14242
{{bri{9,(xr){{{execute it{14243
{{ejc{{{{{14267
*      rpad
{s_rpd{ent{{{{entry point{14271
{{jsr{6,gtstg{{{get pad character{14272
{{err{1,178{26,rpad third argument is not a string{{{14273
{{plc{7,xr{{{point to character (null is blank){14274
{{lch{8,wb{9,(xr){{load pad character{14275
{{jsr{6,gtsmi{{{get pad length{14276
{{err{1,179{26,rpad second argument is not integer{{{14277
{{ppm{6,srpd3{{{skip if negative or large{14278
*      merge to check first arg.
{srpd1{jsr{6,gtstg{{{get first argument (string to pad){14282
{{err{1,180{26,rpad first argument is not a string{{{14283
{{bge{8,wa{8,wc{6,exixr{return 1st arg if too long to pad{14284
{{mov{7,xl{7,xr{{else move ptr to string to pad{14285
*      now we are ready for the pad
*      (xl)                  pointer to string to pad
*      (wb)                  pad character
*      (wc)                  length to pad string to
{{mov{8,wa{8,wc{{copy length{14293
{{jsr{6,alocs{{{allocate scblk for new string{14294
{{mov{11,-(xs){7,xr{{save as result{14295
{{mov{8,wa{13,sclen(xl){{load length of argument{14296
{{sub{8,wc{8,wa{{calculate number of pad characters{14297
{{psc{7,xr{{{point to chars in result string{14298
{{lct{8,wc{8,wc{{set counter for pad loop{14299
*      copy argument string
{{bze{8,wa{6,srpd2{{jump if argument is null{14303
{{plc{7,xl{{{else point to argument chars{14304
{{mvc{{{{move characters to result string{14305
{{zer{7,xl{{{clear garbage xl{14306
*      loop to supply pad characters
{srpd2{sch{8,wb{10,(xr)+{{store pad character, bump ptr{14310
{{bct{8,wc{6,srpd2{{loop till all pad chars stored{14311
{{csc{7,xr{{{complete character storing{14312
{{lcw{7,xr{{{load next code word{14313
{{bri{9,(xr){{{execute it{14314
*      here if 2nd arg is negative or large
{srpd3{zer{8,wc{{{zero pad count{14318
{{brn{6,srpd1{{{merge{14319
{{ejc{{{{{14320
*      rtab
{s_rtb{ent{{{{entry point{14324
{{mov{8,wb{22,=p_rtb{{set pcode for integer arg case{14325
{{mov{8,wa{22,=p_rtd{{set pcode for expression arg case{14326
{{jsr{6,patin{{{call common routine to build node{14327
{{err{1,181{26,rtab argument is not integer or expression{{{14328
{{err{1,182{26,rtab argument is negative or too large{{{14329
{{mov{11,-(xs){7,xr{{stack result{14330
{{lcw{7,xr{{{get next code word{14331
{{bri{9,(xr){{{execute it{14332
{{ejc{{{{{14333
*      set
{s_set{ent{{{{entry point{14338
{{mov{3,r_io2{10,(xs)+{{save third arg (whence){14339
{{mov{3,r_io1{10,(xs)+{{save second arg (offset){14346
{{jsr{6,iofcb{{{call fcblk routine{14348
{{err{1,291{26,set first argument is not a suitable name{{{14349
{{err{1,292{26,set first argument is null{{{14350
{{err{1,295{26,set file does not exist{{{14351
{{mov{8,wb{3,r_io1{{load second arg{14354
{{mov{8,wc{3,r_io2{{load third arg{14356
{{jsr{6,sysst{{{call system set routine{14357
{{err{1,293{26,inappropriate second argument to set{{{14358
{{err{1,294{26,inappropriate third argument to set{{{14359
{{err{1,295{26,set file does not exist{{{14360
{{err{1,296{26,set file does not permit setting file pointer{{{14361
{{err{1,297{26,set caused non-recoverable i/o error{{{14362
{{brn{6,exint{{{otherwise return position{14367
{{ejc{{{{{14369
*      tab
{s_tab{ent{{{{entry point{14374
{{mov{8,wb{22,=p_tab{{set pcode for integer arg case{14375
{{mov{8,wa{22,=p_tbd{{set pcode for expression arg case{14376
{{jsr{6,patin{{{call common routine to build node{14377
{{err{1,183{26,tab argument is not integer or expression{{{14378
{{err{1,184{26,tab argument is negative or too large{{{14379
{{mov{11,-(xs){7,xr{{stack result{14380
{{lcw{7,xr{{{get next code word{14381
{{bri{9,(xr){{{execute it{14382
{{ejc{{{{{14383
*      rpos
{s_rps{ent{{{{entry point{14387
{{mov{8,wb{22,=p_rps{{set pcode for integer arg case{14388
{{mov{8,wa{22,=p_rpd{{set pcode for expression arg case{14389
{{jsr{6,patin{{{call common routine to build node{14390
{{err{1,185{26,rpos argument is not integer or expression{{{14391
{{err{1,186{26,rpos argument is negative or too large{{{14392
{{mov{11,-(xs){7,xr{{stack result{14393
{{lcw{7,xr{{{get next code word{14394
{{bri{9,(xr){{{execute it{14395
{{ejc{{{{{14398
*      rsort
{s_rsr{ent{{{{entry point{14402
{{mnz{8,wa{{{mark as rsort{14403
{{jsr{6,sorta{{{call sort routine{14404
{{ppm{6,exfal{{{if conversion fails, so shall we{14405
{{brn{6,exsid{{{return, setting idval{14406
{{ejc{{{{{14408
*      setexit
{s_stx{ent{{{{entry point{14412
{{mov{7,xr{10,(xs)+{{load argument{14413
{{mov{8,wa{3,stxvr{{load old vrblk pointer{14414
{{zer{7,xl{{{load zero in case null arg{14415
{{beq{7,xr{21,=nulls{6,sstx1{jump if null argument (reset call){14416
{{jsr{6,gtnvr{{{else get specified vrblk{14417
{{ppm{6,sstx2{{{jump if not natural variable{14418
{{mov{7,xl{13,vrlbl(xr){{else load label{14419
{{beq{7,xl{21,=stndl{6,sstx2{jump if label is not defined{14420
{{bne{9,(xl){22,=b_trt{6,sstx1{jump if not trapped{14421
{{mov{7,xl{13,trlbl(xl){{else load ptr to real label code{14422
*      here to set/reset setexit trap
{sstx1{mov{3,stxvr{7,xr{{store new vrblk pointer (or null){14426
{{mov{3,r_sxc{7,xl{{store new code ptr (or zero){14427
{{beq{8,wa{21,=nulls{6,exnul{return null if null result{14428
{{mov{7,xr{8,wa{{else copy vrblk pointer{14429
{{brn{6,exvnm{{{and return building nmblk{14430
*      here if bad argument
{sstx2{erb{1,187{26,setexit argument is not label name or null{{{14434
*      sin
{s_sin{ent{{{{entry point{14439
{{mov{7,xr{10,(xs)+{{get argument{14440
{{jsr{6,gtrea{{{convert to real{14441
{{err{1,308{26,sin argument not numeric{{{14442
{{ldr{13,rcval(xr){{{load accumulator with argument{14443
{{sin{{{{take sine{14444
{{rno{6,exrea{{{if no overflow, return result in ra{14445
{{erb{1,323{26,sin argument is out of range{{{14446
{{ejc{{{{{14447
*      sqrt
{s_sqr{ent{{{{entry point{14453
{{mov{7,xr{10,(xs)+{{get argument{14454
{{jsr{6,gtrea{{{convert to real{14455
{{err{1,313{26,sqrt argument not numeric{{{14456
{{ldr{13,rcval(xr){{{load accumulator with argument{14457
{{rlt{6,ssqr1{{{negative number{14458
{{sqr{{{{take square root{14459
{{brn{6,exrea{{{no overflow possible, result in ra{14460
*      here if bad argument
{ssqr1{erb{1,314{26,sqrt argument negative{{{14464
{{ejc{{{{{14465
{{ejc{{{{{14469
*      sort
{s_srt{ent{{{{entry point{14473
{{zer{8,wa{{{mark as sort{14474
{{jsr{6,sorta{{{call sort routine{14475
{{ppm{6,exfal{{{if conversion fails, so shall we{14476
{{brn{6,exsid{{{return, setting idval{14477
{{ejc{{{{{14479
*      span
{s_spn{ent{{{{entry point{14483
{{mov{8,wb{22,=p_sps{{set pcode for single char arg{14484
{{mov{7,xl{22,=p_spn{{set pcode for multi-char arg{14485
{{mov{8,wc{22,=p_spd{{set pcode for expression arg{14486
{{jsr{6,patst{{{call common routine to build node{14487
{{err{1,188{26,span argument is not a string or expression{{{14488
{{mov{11,-(xs){7,xr{{stack result{14489
{{lcw{7,xr{{{get next code word{14490
{{bri{9,(xr){{{execute it{14491
{{ejc{{{{{14492
*      size
{s_si_{ent{{{{entry point{14496
{{jsr{6,gtstg{{{load string argument{14498
{{err{1,189{26,size argument is not a string{{{14499
*      merge with bfblk or scblk ptr in xr.  wa has length.
{{mti{8,wa{{{load length as integer{14507
{{brn{6,exint{{{exit with integer result{14508
{{ejc{{{{{14509
*      stoptr
{s_stt{ent{{{{entry point{14513
{{zer{7,xl{{{indicate stoptr case{14514
{{jsr{6,trace{{{call trace procedure{14515
{{err{1,190{26,stoptr first argument is not appropriate name{{{14516
{{err{1,191{26,stoptr second argument is not trace type{{{14517
{{brn{6,exnul{{{return null{14518
{{ejc{{{{{14519
*      substr
{s_sub{ent{{{{entry point{14523
{{jsr{6,gtsmi{{{load third argument{14524
{{err{1,192{26,substr third argument is not integer{{{14525
{{ppm{6,exfal{{{jump if negative or too large{14526
{{mov{3,sbssv{7,xr{{save third argument{14527
{{jsr{6,gtsmi{{{load second argument{14528
{{err{1,193{26,substr second argument is not integer{{{14529
{{ppm{6,exfal{{{jump if out of range{14530
{{mov{8,wc{7,xr{{save second argument{14531
{{bze{8,wc{6,exfal{{jump if second argument zero{14532
{{dcv{8,wc{{{else decrement for ones origin{14533
{{jsr{6,gtstg{{{load first argument{14535
{{err{1,194{26,substr first argument is not a string{{{14536
*      merge with bfblk or scblk ptr in xr.  wa has length
{{mov{8,wb{8,wc{{copy second arg to wb{14544
{{mov{8,wc{3,sbssv{{reload third argument{14545
{{bnz{8,wc{6,ssub2{{skip if third arg given{14546
{{mov{8,wc{8,wa{{else get string length{14547
{{bgt{8,wb{8,wc{6,exfal{fail if improper{14548
{{sub{8,wc{8,wb{{reduce by offset to start{14549
*      merge
{ssub2{mov{7,xl{8,wa{{save string length{14553
{{mov{8,wa{8,wc{{set length of substring{14554
{{add{8,wc{8,wb{{add 2nd arg to 3rd arg{14555
{{bgt{8,wc{7,xl{6,exfal{jump if improper substring{14556
{{mov{7,xl{7,xr{{copy pointer to first arg{14557
{{jsr{6,sbstr{{{build substring{14558
{{mov{11,-(xs){7,xr{{stack result{14559
{{lcw{7,xr{{{get next code word{14560
{{bri{9,(xr){{{execute it{14561
{{ejc{{{{{14562
*      table
{s_tbl{ent{{{{entry point{14566
{{mov{7,xl{10,(xs)+{{get initial lookup value{14567
{{ica{7,xs{{{pop second argument{14568
{{jsr{6,gtsmi{{{load argument{14569
{{err{1,195{26,table argument is not integer{{{14570
{{err{1,196{26,table argument is out of range{{{14571
{{bnz{8,wc{6,stbl1{{jump if non-zero{14572
{{mov{8,wc{18,=tbnbk{{else supply default value{14573
*      merge here with number of headers in wc
{stbl1{jsr{6,tmake{{{make table{14577
{{brn{6,exsid{{{exit setting idval{14578
{{ejc{{{{{14579
*      tan
{s_tan{ent{{{{entry point{14584
{{mov{7,xr{10,(xs)+{{get argument{14585
{{jsr{6,gtrea{{{convert to real{14586
{{err{1,309{26,tan argument not numeric{{{14587
{{ldr{13,rcval(xr){{{load accumulator with argument{14588
{{tan{{{{take tangent{14589
{{rno{6,exrea{{{if no overflow, return result in ra{14590
{{erb{1,310{26,tan produced real overflow or argument is out of range{{{14591
{{ejc{{{{{14592
*      time
{s_tim{ent{{{{entry point{14597
{{jsr{6,systm{{{get timer value{14598
{{sbi{3,timsx{{{subtract starting time{14599
{{brn{6,exint{{{exit with integer value{14600
{{ejc{{{{{14601
*      trace
{s_tra{ent{{{{entry point{14605
{{beq{13,num03(xs){21,=nulls{6,str02{jump if first argument is null{14606
{{mov{7,xr{10,(xs)+{{load fourth argument{14607
{{zer{7,xl{{{tentatively set zero pointer{14608
{{beq{7,xr{21,=nulls{6,str01{jump if 4th argument is null{14609
{{jsr{6,gtnvr{{{else point to vrblk{14610
{{ppm{6,str03{{{jump if not variable name{14611
{{mov{7,xl{7,xr{{else save vrblk in trfnc{14612
*      here with vrblk or zero in xl
{str01{mov{7,xr{10,(xs)+{{load third argument (tag){14616
{{zer{8,wb{{{set zero as trtyp value for now{14617
{{jsr{6,trbld{{{build trblk for trace call{14618
{{mov{7,xl{7,xr{{move trblk pointer for trace{14619
{{jsr{6,trace{{{call trace procedure{14620
{{err{1,198{26,trace first argument is not appropriate name{{{14621
{{err{1,199{26,trace second argument is not trace type{{{14622
{{brn{6,exnul{{{return null{14623
*      here to call system trace toggle routine
{str02{jsr{6,systt{{{call it{14627
{{add{7,xs{19,*num04{{pop trace arguments{14628
{{brn{6,exnul{{{return{14629
*      here for bad fourth argument
{str03{erb{1,197{26,trace fourth arg is not function name or null{{{14633
{{ejc{{{{{14634
*      trim
{s_trm{ent{{{{entry point{14638
{{jsr{6,gtstg{{{load argument as string{14640
{{err{1,200{26,trim argument is not a string{{{14641
{{bze{8,wa{6,exnul{{return null if argument is null{14647
{{mov{7,xl{7,xr{{copy string pointer{14648
{{ctb{8,wa{2,schar{{get block length{14649
{{jsr{6,alloc{{{allocate copy same size{14650
{{mov{8,wb{7,xr{{save pointer to copy{14651
{{mvw{{{{copy old string block to new{14652
{{mov{7,xr{8,wb{{restore ptr to new block{14653
{{jsr{6,trimr{{{trim blanks (wb is non-zero){14654
{{mov{11,-(xs){7,xr{{stack result{14655
{{lcw{7,xr{{{get next code word{14656
{{bri{9,(xr){{{execute it{14657
{{ejc{{{{{14700
*      unload
{s_unl{ent{{{{entry point{14704
{{mov{7,xr{10,(xs)+{{load argument{14705
{{jsr{6,gtnvr{{{point to vrblk{14706
{{err{1,201{26,unload argument is not natural variable name{{{14707
{{mov{7,xl{21,=stndf{{get ptr to undefined function{14708
{{jsr{6,dffnc{{{undefine named function{14709
{{brn{6,exnul{{{return null as result{14710
{{ttl{27,s p i t b o l -- utility routines{{{{14732
*      the following section contains utility routines used for
*      various purposes throughout the system. these differ
*      from the procedures in the utility procedures section in
*      they are not in procedure form and they do not return
*      to their callers. they are accessed with a branch type
*      instruction after setting the registers to appropriate
*      parameter values.
*      the register values required for each routine are
*      documented at the start of each routine. registers not
*      mentioned may contain any values except that xr,xl
*      can only contain proper collectable pointers.
*      some of these routines will tolerate garbage pointers
*      in xl,xr on entry. this is always documented and in
*      each case, the routine clears these garbage values before
*      exiting after completing its task.
*      the routines have names consisting of five letters
*      and are assembled in alphabetical order.
{{ejc{{{{{14754
*      arref -- array reference
*      (xl)                  may be non-collectable
*      (xr)                  number of subscripts
*      (wb)                  set zero/nonzero for value/name
*                            the value in wb must be collectable
*      stack                 subscripts and array operand
*      brn  arref            jump to call function
*      arref continues by executing the next code word with
*      the result name or value placed on top of the stack.
*      to deal with the problem of accessing subscripts in the
*      order of stacking, xl is used as a subscript pointer
*      working below the stack pointer.
{arref{rtn{{{{{14770
{{mov{8,wa{7,xr{{copy number of subscripts{14771
{{mov{7,xt{7,xs{{point to stack front{14772
{{wtb{7,xr{{{convert to byte offset{14773
{{add{7,xt{7,xr{{point to array operand on stack{14774
{{ica{7,xt{{{final value for stack popping{14775
{{mov{3,arfxs{7,xt{{keep for later{14776
{{mov{7,xr{11,-(xt){{load array operand pointer{14777
{{mov{3,r_arf{7,xr{{keep array pointer{14778
{{mov{7,xr{7,xt{{save pointer to subscripts{14779
{{mov{7,xl{3,r_arf{{point xl to possible vcblk or tbblk{14780
{{mov{8,wc{9,(xl){{load first word{14781
{{beq{8,wc{22,=b_art{6,arf01{jump if arblk{14782
{{beq{8,wc{22,=b_vct{6,arf07{jump if vcblk{14783
{{beq{8,wc{22,=b_tbt{6,arf10{jump if tbblk{14784
{{erb{1,235{26,subscripted operand is not table or array{{{14785
*      here for array (arblk)
{arf01{bne{8,wa{13,arndm(xl){6,arf09{jump if wrong number of dims{14789
{{ldi{4,intv0{{{get initial subscript of zero{14790
{{mov{7,xt{7,xr{{point before subscripts{14791
{{zer{8,wa{{{initial offset to bounds{14792
{{brn{6,arf03{{{jump into loop{14793
*      loop to compute subscripts by multiplications
{arf02{mli{13,ardm2(xr){{{multiply total by next dimension{14797
*      merge here first time
{arf03{mov{7,xr{11,-(xt){{load next subscript{14801
{{sti{3,arfsi{{{save current subscript{14802
{{ldi{13,icval(xr){{{load integer value in case{14803
{{beq{9,(xr){22,=b_icl{6,arf04{jump if it was an integer{14804
{{ejc{{{{{14805
*      arref (continued)
{{jsr{6,gtint{{{convert to integer{14810
{{ppm{6,arf12{{{jump if not integer{14811
{{ldi{13,icval(xr){{{if ok, load integer value{14812
*      here with integer subscript in (ia)
{arf04{mov{7,xr{3,r_arf{{point to array{14816
{{add{7,xr{8,wa{{offset to next bounds{14817
{{sbi{13,arlbd(xr){{{subtract low bound to compare{14818
{{iov{6,arf13{{{out of range fail if overflow{14819
{{ilt{6,arf13{{{out of range fail if too small{14820
{{sbi{13,ardim(xr){{{subtract dimension{14821
{{ige{6,arf13{{{out of range fail if too large{14822
{{adi{13,ardim(xr){{{else restore subscript offset{14823
{{adi{3,arfsi{{{add to current total{14824
{{add{8,wa{19,*ardms{{point to next bounds{14825
{{bne{7,xt{7,xs{6,arf02{loop back if more to go{14826
*      here with integer subscript computed
{{mfi{8,wa{{{get as one word integer{14830
{{wtb{8,wa{{{convert to offset{14831
{{mov{7,xl{3,r_arf{{point to arblk{14832
{{add{8,wa{13,arofs(xl){{add offset past bounds{14833
{{ica{8,wa{{{adjust for arpro field{14834
{{bnz{8,wb{6,arf08{{exit with name if name call{14835
*      merge here to get value for value call
{arf05{jsr{6,acess{{{get value{14839
{{ppm{6,arf13{{{fail if acess fails{14840
*      return value
{arf06{mov{7,xs{3,arfxs{{pop stack entries{14844
{{zer{3,r_arf{{{finished with array pointer{14845
{{mov{11,-(xs){7,xr{{stack result{14846
{{lcw{7,xr{{{get next code word{14847
{{bri{9,(xr){{{execute it{14848
{{ejc{{{{{14849
*      arref (continued)
*      here for vector
{arf07{bne{8,wa{18,=num01{6,arf09{error if more than 1 subscript{14855
{{mov{7,xr{9,(xs){{else load subscript{14856
{{jsr{6,gtint{{{convert to integer{14857
{{ppm{6,arf12{{{error if not integer{14858
{{ldi{13,icval(xr){{{else load integer value{14859
{{sbi{4,intv1{{{subtract for ones offset{14860
{{mfi{8,wa{6,arf13{{get subscript as one word{14861
{{add{8,wa{18,=vcvls{{add offset for standard fields{14862
{{wtb{8,wa{{{convert offset to bytes{14863
{{bge{8,wa{13,vclen(xl){6,arf13{fail if out of range subscript{14864
{{bze{8,wb{6,arf05{{back to get value if value call{14865
*      return name
{arf08{mov{7,xs{3,arfxs{{pop stack entries{14869
{{zer{3,r_arf{{{finished with array pointer{14870
{{brn{6,exnam{{{else exit with name{14871
*      here if subscript count is wrong
{arf09{erb{1,236{26,array referenced with wrong number of subscripts{{{14875
*      table
{arf10{bne{8,wa{18,=num01{6,arf11{error if more than 1 subscript{14879
{{mov{7,xr{9,(xs){{else load subscript{14880
{{jsr{6,tfind{{{call table search routine{14881
{{ppm{6,arf13{{{fail if failed{14882
{{bnz{8,wb{6,arf08{{exit with name if name call{14883
{{brn{6,arf06{{{else exit with value{14884
*      here for bad table reference
{arf11{erb{1,237{26,table referenced with more than one subscript{{{14888
*      here for bad subscript
{arf12{erb{1,238{26,array subscript is not integer{{{14892
*      here to signal failure
{arf13{zer{3,r_arf{{{finished with array pointer{14896
{{brn{6,exfal{{{fail{14897
{{ejc{{{{{14898
*      cfunc -- call a function
*      cfunc is used to call a snobol level function. it is
*      used by the apply function (s_app), the function
*      trace routine (trxeq) and the main function call entry
*      (o_fnc, o_fns). in the latter cases, cfunc is used only
*      if the number of arguments is incorrect.
*      (xl)                  pointer to function block
*      (wa)                  actual number of arguments
*      (xs)                  points to stacked arguments
*      brn  cfunc            jump to call function
*      cfunc continues by executing the function
{cfunc{rtn{{{{{14915
{{blt{8,wa{13,fargs(xl){6,cfnc1{jump if too few arguments{14916
{{beq{8,wa{13,fargs(xl){6,cfnc3{jump if correct number of args{14917
*      here if too many arguments supplied, pop them off
{{mov{8,wb{8,wa{{copy actual number{14921
{{sub{8,wb{13,fargs(xl){{get number of extra args{14922
{{wtb{8,wb{{{convert to bytes{14923
{{add{7,xs{8,wb{{pop off unwanted arguments{14924
{{brn{6,cfnc3{{{jump to go off to function{14925
*      here if too few arguments
{cfnc1{mov{8,wb{13,fargs(xl){{load required number of arguments{14929
{{beq{8,wb{18,=nini9{6,cfnc3{jump if case of var num of args{14930
{{sub{8,wb{8,wa{{calculate number missing{14931
{{lct{8,wb{8,wb{{set counter to control loop{14932
*      loop to supply extra null arguments
{cfnc2{mov{11,-(xs){21,=nulls{{stack a null argument{14936
{{bct{8,wb{6,cfnc2{{loop till proper number stacked{14937
*      merge here to jump to function
{cfnc3{bri{9,(xl){{{jump through fcode field{14941
{{ejc{{{{{14942
*      exfal -- exit signalling snobol failure
*      (xl,xr)               may be non-collectable
*      brn  exfal            jump to fail
*      exfal continues by executing the appropriate fail goto
{exfal{rtn{{{{{14951
{{mov{7,xs{3,flptr{{pop stack{14952
{{mov{7,xr{9,(xs){{load failure offset{14953
{{add{7,xr{3,r_cod{{point to failure code location{14954
{{lcp{7,xr{{{set code pointer{14955
{{lcw{7,xr{{{load next code word{14956
{{mov{7,xl{9,(xr){{load entry address{14957
{{bri{7,xl{{{jump to execute next code word{14958
{{ejc{{{{{14959
*      exint -- exit with integer result
*      (xl,xr)               may be non-collectable
*      (ia)                  integer value
*      brn  exint            jump to exit with integer
*      exint continues by executing the next code word
*      which it does by falling through to exixr
{exint{rtn{{{{{14970
{{zer{7,xl{{{clear dud value{14971
{{jsr{6,icbld{{{build icblk{14972
{{ejc{{{{{14973
*      exixr -- exit with result in (xr)
*      (xr)                  result
*      (xl)                  may be non-collectable
*      brn  exixr            jump to exit with result in (xr)
*      exixr continues by executing the next code word
*      which it does by falling through to exits.
{exixr{rtn{{{{{14982
{{mov{11,-(xs){7,xr{{stack result{14984
*      exits -- exit with result if any stacked
*      (xr,xl)               may be non-collectable
*      brn  exits            enter exits routine
{exits{rtn{{{{{14993
{{lcw{7,xr{{{load next code word{14994
{{mov{7,xl{9,(xr){{load entry address{14995
{{bri{7,xl{{{jump to execute next code word{14996
{{ejc{{{{{14997
*      exnam -- exit with name in (xl,wa)
*      (xl)                  name base
*      (wa)                  name offset
*      (xr)                  may be non-collectable
*      brn  exnam            jump to exit with name in (xl,wa)
*      exnam continues by executing the next code word
{exnam{rtn{{{{{15008
{{mov{11,-(xs){7,xl{{stack name base{15009
{{mov{11,-(xs){8,wa{{stack name offset{15010
{{lcw{7,xr{{{load next code word{15011
{{bri{9,(xr){{{execute it{15012
{{ejc{{{{{15013
*      exnul -- exit with null result
*      (xl,xr)               may be non-collectable
*      brn  exnul            jump to exit with null value
*      exnul continues by executing the next code word
{exnul{rtn{{{{{15022
{{mov{11,-(xs){21,=nulls{{stack null value{15023
{{lcw{7,xr{{{load next code word{15024
{{mov{7,xl{9,(xr){{load entry address{15025
{{bri{7,xl{{{jump to execute next code word{15026
{{ejc{{{{{15027
*      exrea -- exit with real result
*      (xl,xr)               may be non-collectable
*      (ra)                  real value
*      brn  exrea            jump to exit with real value
*      exrea continues by executing the next code word
{exrea{rtn{{{{{15039
{{zer{7,xl{{{clear dud value{15040
{{jsr{6,rcbld{{{build rcblk{15041
{{brn{6,exixr{{{jump to exit with result in xr{15042
{{ejc{{{{{15044
*      exsid -- exit setting id field
*      exsid is used to exit after building any of the following
*      blocks (arblk, tbblk, pdblk, vcblk). it sets the idval.
*      (xr)                  ptr to block with idval field
*      (xl)                  may be non-collectable
*      brn  exsid            jump to exit after setting id field
*      exsid continues by executing the next code word
{exsid{rtn{{{{{15057
{{mov{8,wa{3,curid{{load current id value{15058
{{bne{8,wa{3,mxint{6,exsi1{jump if no overflow{15059
{{zer{8,wa{{{else reset for wraparound{15060
*      here with old idval in wa
{exsi1{icv{8,wa{{{bump id value{15064
{{mov{3,curid{8,wa{{store for next time{15065
{{mov{13,idval(xr){8,wa{{store id value{15066
{{brn{6,exixr{{{exit with result in (xr){15067
{{ejc{{{{{15068
*      exvnm -- exit with name of variable
*      exvnm exits after stacking a value which is a nmblk
*      referencing the name of a given natural variable.
*      (xr)                  vrblk pointer
*      (xl)                  may be non-collectable
*      brn  exvnm            exit with vrblk pointer in xr
{exvnm{rtn{{{{{15079
{{mov{7,xl{7,xr{{copy name base pointer{15080
{{mov{8,wa{19,*nmsi_{{set size of nmblk{15081
{{jsr{6,alloc{{{allocate nmblk{15082
{{mov{9,(xr){22,=b_nml{{store type word{15083
{{mov{13,nmbas(xr){7,xl{{store name base{15084
{{mov{13,nmofs(xr){19,*vrval{{store name offset{15085
{{brn{6,exixr{{{exit with result in xr{15086
{{ejc{{{{{15087
*      flpop -- fail and pop in pattern matching
*      flpop pops the node and cursor on the stack and then
*      drops through into failp to cause pattern failure
*      (xl,xr)               may be non-collectable
*      brn  flpop            jump to fail and pop stack
{flpop{rtn{{{{{15097
{{add{7,xs{19,*num02{{pop two entries off stack{15098
{{ejc{{{{{15099
*      failp -- failure in matching pattern node
*      failp is used after failing to match a pattern node.
*      see pattern match routines for details of use.
*      (xl,xr)               may be non-collectable
*      brn  failp            signal failure to match
*      failp continues by matching an alternative from the stack
{failp{rtn{{{{{15111
{{mov{7,xr{10,(xs)+{{load alternative node pointer{15112
{{mov{8,wb{10,(xs)+{{restore old cursor{15113
{{mov{7,xl{9,(xr){{load pcode entry pointer{15114
{{bri{7,xl{{{jump to execute code for node{15115
{{ejc{{{{{15116
*      indir -- compute indirect reference
*      (wb)                  nonzero/zero for by name/value
*      brn  indir            jump to get indirect ref on stack
*      indir continues by executing the next code word
{indir{rtn{{{{{15125
{{mov{7,xr{10,(xs)+{{load argument{15126
{{beq{9,(xr){22,=b_nml{6,indr2{jump if a name{15127
{{jsr{6,gtnvr{{{else convert to variable{15128
{{err{1,239{26,indirection operand is not name{{{15129
{{bze{8,wb{6,indr1{{skip if by value{15130
{{mov{11,-(xs){7,xr{{else stack vrblk ptr{15131
{{mov{11,-(xs){19,*vrval{{stack name offset{15132
{{lcw{7,xr{{{load next code word{15133
{{mov{7,xl{9,(xr){{load entry address{15134
{{bri{7,xl{{{jump to execute next code word{15135
*      here to get value of natural variable
{indr1{bri{9,(xr){{{jump through vrget field of vrblk{15139
*      here if operand is a name
{indr2{mov{7,xl{13,nmbas(xr){{load name base{15143
{{mov{8,wa{13,nmofs(xr){{load name offset{15144
{{bnz{8,wb{6,exnam{{exit if called by name{15145
{{jsr{6,acess{{{else get value first{15146
{{ppm{6,exfal{{{fail if access fails{15147
{{brn{6,exixr{{{else return with value in xr{15148
{{ejc{{{{{15149
*      match -- initiate pattern match
*      (wb)                  match type code
*      brn  match            jump to initiate pattern match
*      match continues by executing the pattern match. see
*      pattern match routines (p_xxx) for full details.
{match{rtn{{{{{15159
{{mov{7,xr{10,(xs)+{{load pattern operand{15160
{{jsr{6,gtpat{{{convert to pattern{15161
{{err{1,240{26,pattern match right operand is not pattern{{{15162
{{mov{7,xl{7,xr{{if ok, save pattern pointer{15163
{{bnz{8,wb{6,mtch1{{jump if not match by name{15164
{{mov{8,wa{9,(xs){{else load name offset{15165
{{mov{11,-(xs){7,xl{{save pattern pointer{15166
{{mov{7,xl{13,num02(xs){{load name base{15167
{{jsr{6,acess{{{access subject value{15168
{{ppm{6,exfal{{{fail if access fails{15169
{{mov{7,xl{9,(xs){{restore pattern pointer{15170
{{mov{9,(xs){7,xr{{stack subject string val for merge{15171
{{zer{8,wb{{{restore type code{15172
*      merge here with subject value on stack
{mtch1{jsr{6,gtstg{{{convert subject to string{15177
{{err{1,241{26,pattern match left operand is not a string{{{15178
{{mov{11,-(xs){8,wb{{stack match type code{15179
{{mov{3,r_pms{7,xr{{if ok, store subject string pointer{15187
{{mov{3,pmssl{8,wa{{and length{15188
{{zer{11,-(xs){{{stack initial cursor (zero){15189
{{zer{8,wb{{{set initial cursor{15190
{{mov{3,pmhbs{7,xs{{set history stack base ptr{15191
{{zer{3,pmdfl{{{reset pattern assignment flag{15192
{{mov{7,xr{7,xl{{set initial node pointer{15193
{{bnz{3,kvanc{6,mtch2{{jump if anchored{15194
*      here for unanchored
{{mov{11,-(xs){7,xr{{stack initial node pointer{15198
{{mov{11,-(xs){21,=nduna{{stack pointer to anchor move node{15199
{{bri{9,(xr){{{start match of first node{15200
*      here in anchored mode
{mtch2{zer{11,-(xs){{{dummy cursor value{15204
{{mov{11,-(xs){21,=ndabo{{stack pointer to abort node{15205
{{bri{9,(xr){{{start match of first node{15206
{{ejc{{{{{15207
*      retrn -- return from function
*      (wa)                  string pointer for return type
*      brn  retrn            jump to return from (snobol) func
*      retrn continues by executing the code at the return point
*      the stack is cleaned of any garbage left by other
*      routines which may have altered flptr since function
*      entry by using flprt, reserved for use only by
*      function call and return.
{retrn{rtn{{{{{15220
{{bnz{3,kvfnc{6,rtn01{{jump if not level zero{15221
{{erb{1,242{26,function return from level zero{{{15222
*      here if not level zero return
{rtn01{mov{7,xs{3,flprt{{pop stack{15226
{{ica{7,xs{{{remove failure offset{15227
{{mov{7,xr{10,(xs)+{{pop pfblk pointer{15228
{{mov{3,flptr{10,(xs)+{{pop failure pointer{15229
{{mov{3,flprt{10,(xs)+{{pop old flprt{15230
{{mov{8,wb{10,(xs)+{{pop code pointer offset{15231
{{mov{8,wc{10,(xs)+{{pop old code block pointer{15232
{{add{8,wb{8,wc{{make old code pointer absolute{15233
{{lcp{8,wb{{{restore old code pointer{15234
{{mov{3,r_cod{8,wc{{restore old code block pointer{15235
{{dcv{3,kvfnc{{{decrement function level{15236
{{mov{8,wb{3,kvtra{{load trace{15237
{{add{8,wb{3,kvftr{{add ftrace{15238
{{bze{8,wb{6,rtn06{{jump if no tracing possible{15239
*      here if there may be a trace
{{mov{11,-(xs){8,wa{{save function return type{15243
{{mov{11,-(xs){7,xr{{save pfblk pointer{15244
{{mov{3,kvrtn{8,wa{{set rtntype for trace function{15245
{{mov{7,xl{3,r_fnc{{load fnclevel trblk ptr (if any){15246
{{jsr{6,ktrex{{{execute possible fnclevel trace{15247
{{mov{7,xl{13,pfvbl(xr){{load vrblk ptr (sgd13){15248
{{bze{3,kvtra{6,rtn02{{jump if trace is off{15249
{{mov{7,xr{13,pfrtr(xr){{else load return trace trblk ptr{15250
{{bze{7,xr{6,rtn02{{jump if not return traced{15251
{{dcv{3,kvtra{{{else decrement trace count{15252
{{bze{13,trfnc(xr){6,rtn03{{jump if print trace{15253
{{mov{8,wa{19,*vrval{{else set name offset{15254
{{mov{3,kvrtn{13,num01(xs){{make sure rtntype is set right{15255
{{jsr{6,trxeq{{{execute full trace{15256
{{ejc{{{{{15257
*      retrn (continued)
*      here to test for ftrace
{rtn02{bze{3,kvftr{6,rtn05{{jump if ftrace is off{15263
{{dcv{3,kvftr{{{else decrement ftrace{15264
*      here for print trace of function return
{rtn03{jsr{6,prtsn{{{print statement number{15268
{{mov{7,xr{13,num01(xs){{load return type{15269
{{jsr{6,prtst{{{print it{15270
{{mov{8,wa{18,=ch_bl{{load blank{15271
{{jsr{6,prtch{{{print it{15272
{{mov{7,xl{12,0(xs){{load pfblk ptr{15273
{{mov{7,xl{13,pfvbl(xl){{load function vrblk ptr{15274
{{mov{8,wa{19,*vrval{{set vrblk name offset{15275
{{bne{7,xr{21,=scfrt{6,rtn04{jump if not freturn case{15276
*      for freturn, just print function name
{{jsr{6,prtnm{{{print name{15280
{{jsr{6,prtnl{{{terminate print line{15281
{{brn{6,rtn05{{{merge{15282
*      here for return or nreturn, print function name = value
{rtn04{jsr{6,prtnv{{{print name = value{15286
*      here after completing trace
{rtn05{mov{7,xr{10,(xs)+{{pop pfblk pointer{15290
{{mov{8,wa{10,(xs)+{{pop return type string{15291
*      merge here if no trace required
{rtn06{mov{3,kvrtn{8,wa{{set rtntype keyword{15295
{{mov{7,xl{13,pfvbl(xr){{load pointer to fn vrblk{15296
{{ejc{{{{{15297
*      retrn (continued)
*      get value of function
{rtn07{mov{3,rtnbp{7,xl{{save block pointer{15302
{{mov{7,xl{13,vrval(xl){{load value{15303
{{beq{9,(xl){22,=b_trt{6,rtn07{loop back if trapped{15304
{{mov{3,rtnfv{7,xl{{else save function result value{15305
{{mov{3,rtnsv{10,(xs)+{{save original function value{15306
{{mov{7,xl{10,(xs)+{{pop saved pointer{15310
{{bze{7,xl{6,rtn7c{{no action if none{15311
{{bze{3,kvpfl{6,rtn7c{{jump if no profiling{15312
{{jsr{6,prflu{{{else profile last func stmt{15313
{{beq{3,kvpfl{18,=num02{6,rtn7a{branch on value of profile keywd{15314
*      here if &profile = 1. start time must be frigged to
*      appear earlier than it actually is, by amount used before
*      the call.
{{ldi{3,pfstm{{{load current time{15320
{{sbi{13,icval(xl){{{frig by subtracting saved amount{15321
{{brn{6,rtn7b{{{and merge{15322
*      here if &profile = 2
{rtn7a{ldi{13,icval(xl){{{load saved time{15326
*      both profile types merge here
{rtn7b{sti{3,pfstm{{{store back correct start time{15330
*      merge here if no profiling
{rtn7c{mov{8,wb{13,fargs(xr){{get number of args{15334
{{add{8,wb{13,pfnlo(xr){{add number of locals{15336
{{bze{8,wb{6,rtn10{{jump if no args/locals{15337
{{lct{8,wb{8,wb{{else set loop counter{15338
{{add{7,xr{13,pflen(xr){{and point to end of pfblk{15339
*      loop to restore functions and locals
{rtn08{mov{7,xl{11,-(xr){{load next vrblk pointer{15343
*      loop to find value block
{rtn09{mov{8,wa{7,xl{{save block pointer{15347
{{mov{7,xl{13,vrval(xl){{load pointer to next value{15348
{{beq{9,(xl){22,=b_trt{6,rtn09{loop back if trapped{15349
{{mov{7,xl{8,wa{{else restore last block pointer{15350
{{mov{13,vrval(xl){10,(xs)+{{restore old variable value{15351
{{bct{8,wb{6,rtn08{{loop till all processed{15352
*      now restore function value and exit
{rtn10{mov{7,xl{3,rtnbp{{restore ptr to last function block{15356
{{mov{13,vrval(xl){3,rtnsv{{restore old function value{15357
{{mov{7,xr{3,rtnfv{{reload function result{15358
{{mov{7,xl{3,r_cod{{point to new code block{15359
{{mov{3,kvlst{3,kvstn{{set lastno from stno{15360
{{mov{3,kvstn{13,cdstm(xl){{reset proper stno value{15361
{{mov{3,kvlln{3,kvlin{{set lastline from line{15363
{{mov{3,kvlin{13,cdsln(xl){{reset proper line value{15364
{{mov{8,wa{3,kvrtn{{load return type{15366
{{beq{8,wa{21,=scrtn{6,exixr{exit with result in xr if return{15367
{{beq{8,wa{21,=scfrt{6,exfal{fail if freturn{15368
{{ejc{{{{{15369
*      retrn (continued)
*      here for nreturn
{{beq{9,(xr){22,=b_nml{6,rtn11{jump if is a name{15375
{{jsr{6,gtnvr{{{else try convert to variable name{15376
{{err{1,243{26,function result in nreturn is not name{{{15377
{{mov{7,xl{7,xr{{if ok, copy vrblk (name base) ptr{15378
{{mov{8,wa{19,*vrval{{set name offset{15379
{{brn{6,rtn12{{{and merge{15380
*      here if returned result is a name
{rtn11{mov{7,xl{13,nmbas(xr){{load name base{15384
{{mov{8,wa{13,nmofs(xr){{load name offset{15385
*      merge here with returned name in (xl,wa)
{rtn12{mov{7,xr{7,xl{{preserve xl{15389
{{lcw{8,wb{{{load next word{15390
{{mov{7,xl{7,xr{{restore xl{15391
{{beq{8,wb{21,=ofne_{6,exnam{exit if called by name{15392
{{mov{11,-(xs){8,wb{{else save code word{15393
{{jsr{6,acess{{{get value{15394
{{ppm{6,exfal{{{fail if access fails{15395
{{mov{7,xl{7,xr{{if ok, copy result{15396
{{mov{7,xr{9,(xs){{reload next code word{15397
{{mov{9,(xs){7,xl{{store result on stack{15398
{{mov{7,xl{9,(xr){{load routine address{15399
{{bri{7,xl{{{jump to execute next code word{15400
{{ejc{{{{{15401
*      stcov -- signal statement counter overflow
*      brn  stcov            jump to signal statement count oflo
*      permit up to 10 more statements to be obeyed so that
*      setexit trap can regain control.
*      stcov continues by issuing the error message
{stcov{rtn{{{{{15411
{{icv{3,errft{{{fatal error{15412
{{ldi{4,intvt{{{get 10{15413
{{adi{3,kvstl{{{add to former limit{15414
{{sti{3,kvstl{{{store as new stlimit{15415
{{ldi{4,intvt{{{get 10{15416
{{sti{3,kvstc{{{set as new count{15417
{{jsr{6,stgcc{{{recompute countdown counters{15418
{{erb{1,244{26,statement count exceeds value of stlimit keyword{{{15419
{{ejc{{{{{15420
*      stmgo -- start execution of new statement
*      (xr)                  pointer to cdblk for new statement
*      brn  stmgo            jump to execute new statement
*      stmgo continues by executing the next statement
{stmgo{rtn{{{{{15429
{{mov{3,r_cod{7,xr{{set new code block pointer{15430
{{dcv{3,stmct{{{see if time to check something{15431
{{bze{3,stmct{6,stgo2{{jump if so{15432
{{mov{3,kvlst{3,kvstn{{set lastno{15433
{{mov{3,kvstn{13,cdstm(xr){{set stno{15434
{{mov{3,kvlln{3,kvlin{{set lastline{15436
{{mov{3,kvlin{13,cdsln(xr){{set line{15437
{{add{7,xr{19,*cdcod{{point to first code word{15439
{{lcp{7,xr{{{set code pointer{15440
*      here to execute first code word of statement
{stgo1{lcw{7,xr{{{load next code word{15444
{{zer{7,xl{{{clear garbage xl{15445
{{bri{9,(xr){{{execute it{15446
*      check profiling, polling, stlimit, statement tracing
{stgo2{bze{3,kvpfl{6,stgo3{{skip if no profiling{15450
{{jsr{6,prflu{{{else profile the statement in kvstn{15451
*      here when finished with profiling
{stgo3{mov{3,kvlst{3,kvstn{{set lastno{15455
{{mov{3,kvstn{13,cdstm(xr){{set stno{15456
{{mov{3,kvlln{3,kvlin{{set lastline{15458
{{mov{3,kvlin{13,cdsln(xr){{set line{15459
{{add{7,xr{19,*cdcod{{point to first code word{15461
{{lcp{7,xr{{{set code pointer{15462
*      here to check for polling
{{mov{11,-(xs){3,stmcs{{save present count start on stack{15467
{{dcv{3,polct{{{poll interval within stmct{15468
{{bnz{3,polct{6,stgo4{{jump if not poll time yet{15469
{{zer{8,wa{{{=0 for poll{15470
{{mov{8,wb{3,kvstn{{statement number{15471
{{mov{7,xl{7,xr{{make collectable{15472
{{jsr{6,syspl{{{allow interactive access{15473
{{err{1,320{26,user interrupt{{{15474
{{ppm{{{{single step{15475
{{ppm{{{{expression evaluation{15476
{{mov{7,xr{7,xl{{restore code block pointer{15477
{{mov{3,polcs{8,wa{{poll interval start value{15478
{{jsr{6,stgcc{{{recompute counter values{15479
*      check statement limit
{stgo4{ldi{3,kvstc{{{get stmt count{15484
{{ilt{6,stgo5{{{omit counting if negative{15485
{{mti{10,(xs)+{{{reload start value of counter{15486
{{ngi{{{{negate{15487
{{adi{3,kvstc{{{stmt count minus counter{15488
{{sti{3,kvstc{{{replace it{15489
{{ile{6,stcov{{{fail if stlimit reached{15490
{{bze{3,r_stc{6,stgo5{{jump if no statement trace{15491
{{zer{7,xr{{{clear garbage value in xr{15492
{{mov{7,xl{3,r_stc{{load pointer to stcount trblk{15493
{{jsr{6,ktrex{{{execute keyword trace{15494
*      reset stmgo counter
{stgo5{mov{3,stmct{3,stmcs{{reset counter{15498
{{brn{6,stgo1{{{fetch next code word{15499
{{ejc{{{{{15500
*      stopr -- terminate run
*      (xr)                  points to ending message
*      brn stopr             jump to terminate run
*      terminate run and print statistics.  on entry xr points
*      to ending message or is zero if message  printed already.
{stopr{rtn{{{{{15510
{{bze{7,xr{6,stpra{{skip if sysax already called{15512
{{jsr{6,sysax{{{call after execution proc{15513
{stpra{add{3,dname{3,rsmem{{use the reserve memory{15514
{{bne{7,xr{21,=endms{6,stpr0{skip if not normal end message{15518
{{bnz{3,exsts{6,stpr3{{skip if exec stats suppressed{15519
{{zer{3,erich{{{clear errors to int.ch. flag{15520
*      look to see if an ending message is supplied
{stpr0{jsr{6,prtpg{{{eject printer{15524
{{bze{7,xr{6,stpr1{{skip if no message{15525
{{jsr{6,prtst{{{print message{15526
*      merge here if no message to print
{stpr1{jsr{6,prtis{{{print blank line{15530
{{bnz{3,gbcfl{6,stpr5{{if in garbage collection, skip{15532
{{mov{7,xr{21,=stpm6{{point to message /in file xxx/{15533
{{jsr{6,prtst{{{print it{15534
{{mov{3,profs{18,=prtmf{{set column offset{15535
{{mov{8,wc{3,kvstn{{get statement number{15536
{{jsr{6,filnm{{{get file name{15537
{{mov{7,xr{7,xl{{prepare to print{15538
{{jsr{6,prtst{{{print file name{15539
{{jsr{6,prtis{{{print to interactive channel{15540
{{mov{7,xr{3,r_cod{{get code pointer{15547
{{mti{13,cdsln(xr){{{get source line number{15548
{{mov{7,xr{21,=stpm4{{point to message /in line xxx/{15549
{{jsr{6,prtmx{{{print it{15550
{stpr5{mti{3,kvstn{{{get statement number{15552
{{mov{7,xr{21,=stpm1{{point to message /in statement xxx/{15553
{{jsr{6,prtmx{{{print it{15554
{{ldi{3,kvstl{{{get statement limit{15555
{{ilt{6,stpr2{{{skip if negative{15556
{{sbi{3,kvstc{{{minus counter = course count{15557
{{sti{3,stpsi{{{save{15558
{{mov{8,wa{3,stmcs{{refine with counter start value{15559
{{sub{8,wa{3,stmct{{minus current counter{15560
{{mti{8,wa{{{convert to integer{15561
{{adi{3,stpsi{{{add in course count{15562
{{sti{3,stpsi{{{save{15563
{{mov{7,xr{21,=stpm2{{point to message /stmts executed/{15564
{{jsr{6,prtmx{{{print it{15565
{{jsr{6,systm{{{get current time{15566
{{sbi{3,timsx{{{minus start time = elapsed exec tim in nanosec{15567
{{sti{3,stpti{{{save for later{15568
{{dvi{4,intth{{{divide by 1000 to convert to microseconds{15569
{{iov{6,stpr2{{{jump if we cannot compute{15570
{{dvi{4,intth{{{divide by 1000 to convert to milliseconds{15571
{{iov{6,stpr2{{{jump if we cannot compute{15572
{{sti{3,stpti{{{save elapsed time in milliseconds{15573
{{mov{7,xr{21,=stpm3{{point to msg /execution time msec /{15574
{{jsr{6,prtmx{{{print it{15575
*      Only list peformance statistics giving stmts / millisec, etc.
*      if program ran for more than one millisecond.
{{ldi{3,stpti{{{reload execution time in milliseconds{15580
{{ile{6,stpr2{{{jump if exection time less than a millisecond{15581
{{ldi{3,stpsi{{{load statement count{15585
{{dvi{3,stpti{{{divide to get stmts per millisecond{15586
{{iov{6,stpr2{{{jump if we cannot compute{15587
{{dvi{4,intth{{{divide to get stmts per microsecond{15588
{{iov{6,stpr2{{{jump if we cannot compute{15589
{{mov{7,xr{21,=stpm7{{point to msg (stmt / microsec){15590
{{jsr{6,prtmx{{{print it{15591
{{ldi{3,stpsi{{{reload statement count{15593
{{dvi{3,stpti{{{divide to get stmts per millisecond{15594
{{iov{6,stpr2{{{jump if we cannot compute{15595
{{mov{7,xr{21,=stpm8{{point to msg (stmt / millisec ){15596
{{jsr{6,prtmx{{{print it{15597
{{ldi{3,stpsi{{{reload statement count{15599
{{dvi{3,stpti{{{divide to get stmts per millisecond{15600
{{iov{6,stpr2{{{jump if we cannot compute{15601
{{mli{4,intth{{{multiply by 1000 to get stmts per microsecond{15602
{{iov{6,stpr2{{{jump if overflow{15603
{{mov{7,xr{21,=stpm9{{point to msg ( stmt / second ){15604
{{jsr{6,prtmx{{{print it{15605
{{ejc{{{{{15607
*      stopr (continued)
*      merge to skip message (overflow or negative stlimit)
{stpr2{mti{3,gbcnt{{{load count of collections{15613
{{mov{7,xr{21,=stpm4{{point to message /regenerations /{15614
{{jsr{6,prtmx{{{print it{15615
{{jsr{6,prtmm{{{print memory usage{15616
{{jsr{6,prtis{{{one more blank for luck{15617
*      check if dump requested
{stpr3{jsr{6,prflr{{{print profile if wanted{15624
{{mov{7,xr{3,kvdmp{{load dump keyword{15626
{{jsr{6,dumpr{{{execute dump if requested{15628
{{mov{7,xl{3,r_fcb{{get fcblk chain head{15629
{{mov{8,wa{3,kvabe{{load abend value{15630
{{mov{8,wb{3,kvcod{{load code value{15631
{{jsr{6,sysej{{{exit to system{15632
*      here after sysea call and suppressing error msg print
{stpr4{rtn{{{{{15637
{{add{3,dname{3,rsmem{{use the reserve memory{15638
{{bze{3,exsts{6,stpr1{{if execution stats requested{15639
{{brn{6,stpr3{{{check if dump or profile needed{15640
{{ejc{{{{{15643
*      succp -- signal successful match of a pattern node
*      see pattern match routines for details
*      (xr)                  current node
*      (wb)                  current cursor
*      (xl)                  may be non-collectable
*      brn  succp            signal successful pattern match
*      succp continues by matching the successor node
{succp{rtn{{{{{15656
{{mov{7,xr{13,pthen(xr){{load successor node{15657
{{mov{7,xl{9,(xr){{load node code entry address{15658
{{bri{7,xl{{{jump to match successor node{15659
{{ejc{{{{{15660
*      sysab -- print /abnormal end/ and terminate
{sysab{rtn{{{{{15664
{{mov{7,xr{21,=endab{{point to message{15665
{{mov{3,kvabe{18,=num01{{set abend flag{15666
{{jsr{6,prtnl{{{skip to new line{15667
{{brn{6,stopr{{{jump to pack up{15668
{{ejc{{{{{15669
*      systu -- print /time up/ and terminate
{systu{rtn{{{{{15673
{{mov{7,xr{21,=endtu{{point to message{15674
{{mov{8,wa{4,strtu{{get chars /tu/{15675
{{mov{3,kvcod{8,wa{{put in kvcod{15676
{{mov{8,wa{3,timup{{check state of timeup switch{15677
{{mnz{3,timup{{{set switch{15678
{{bnz{8,wa{6,stopr{{stop run if already set{15679
{{erb{1,245{26,translation/execution time expired{{{15680
{{ttl{27,s p i t b o l -- utility procedures{{{{15681
*      the following section contains procedures which are
*      used for various purposes throughout the system.
*      each procedure is preceded by a description of the
*      calling sequence. usually the arguments are in registers
*      but arguments can also occur on the stack and as
*      parameters assembled after the jsr instruction.
*      the following considerations apply to these descriptions.
*      1)   the stack pointer (xs) is not changed unless the
*           change is explicitly documented in the call.
*      2)   registers whose entry values are not mentioned
*           may contain any value except that xl,xr may only
*           contain proper (collectable) pointer values.
*           this condition on means that the called routine
*           may if it chooses preserve xl,xr by stacking.
*      3)   registers not mentioned on exit contain the same
*           values as they did on entry except that values in
*           xr,xl may have been relocated by the collector.
*      4)   registers which are destroyed on exit may contain
*           any value except that values in xl,xr are proper
*           (collectable) pointers.
*      5)   the code pointer register points to the current
*           code location on entry and is unchanged on exit.
*      in the above description, a collectable pointer is one
*      which either points outside the dynamic region or
*      points to the start of a block in the dynamic region.
*      in those cases where the calling sequence contains
*      parameters which are used as alternate return points,
*      these parameters may be replaced by error codes
*      assembled with the err instruction. this will result
*      in the posting of the error if the return is taken.
*      the procedures all have names consisting of five letters
*      and are in alphabetical order by their names.
{{ejc{{{{{15725
*      acess - access variable value with trace/input checks
*      acess loads the value of a variable. trace and input
*      associations are tested for and executed as required.
*      acess also handles the special cases of pseudo-variables.
*      (xl)                  variable name base
*      (wa)                  variable name offset
*      jsr  acess            call to access value
*      ppm  loc              transfer loc if access failure
*      (xr)                  variable value
*      (wa,wb,wc)            destroyed
*      (xl,ra)               destroyed
*      failure can occur if an input association causes an end
*      of file condition or if the evaluation of an expression
*      associated with an expression variable fails.
{acess{prc{25,r{1,1{{entry point (recursive){15745
{{mov{7,xr{7,xl{{copy name base{15746
{{add{7,xr{8,wa{{point to variable location{15747
{{mov{7,xr{9,(xr){{load variable value{15748
*      loop here to check for successive trblks
{acs02{bne{9,(xr){22,=b_trt{6,acs18{jump if not trapped{15752
*      here if trapped
{{beq{7,xr{21,=trbkv{6,acs12{jump if keyword variable{15756
{{bne{7,xr{21,=trbev{6,acs05{jump if not expression variable{15757
*      here for expression variable, evaluate variable
{{mov{7,xr{13,evexp(xl){{load expression pointer{15761
{{zer{8,wb{{{evaluate by value{15762
{{jsr{6,evalx{{{evaluate expression{15763
{{ppm{6,acs04{{{jump if evaluation failure{15764
{{brn{6,acs02{{{check value for more trblks{15765
{{ejc{{{{{15766
*      acess (continued)
*      here on reading end of file
{acs03{add{7,xs{19,*num03{{pop trblk ptr, name base and offset{15772
{{mov{3,dnamp{7,xr{{pop unused scblk{15773
*      merge here when evaluation of expression fails
{acs04{exi{1,1{{{take alternate (failure) return{15777
*      here if not keyword or expression variable
{acs05{mov{8,wb{13,trtyp(xr){{load trap type code{15781
{{bnz{8,wb{6,acs10{{jump if not input association{15782
{{bze{3,kvinp{6,acs09{{ignore input assoc if input is off{15783
*      here for input association
{{mov{11,-(xs){7,xl{{stack name base{15787
{{mov{11,-(xs){8,wa{{stack name offset{15788
{{mov{11,-(xs){7,xr{{stack trblk pointer{15789
{{mov{3,actrm{3,kvtrm{{temp to hold trim keyword{15790
{{mov{7,xl{13,trfpt(xr){{get file ctrl blk ptr or zero{15791
{{bnz{7,xl{6,acs06{{jump if not standard input file{15792
{{beq{13,trter(xr){21,=v_ter{6,acs21{jump if terminal{15793
*      here to read from standard input file
{{mov{8,wa{3,cswin{{length for read buffer{15797
{{jsr{6,alocs{{{build string of appropriate length{15798
{{jsr{6,sysrd{{{read next standard input image{15799
{{ppm{6,acs03{{{jump to fail exit if end of file{15800
{{brn{6,acs07{{{else merge with other file case{15801
*      here for input from other than standard input file
{acs06{mov{8,wa{7,xl{{fcblk ptr{15805
{{jsr{6,sysil{{{get input record max length (to wa){15806
{{bnz{8,wc{6,acs6a{{jump if not binary file{15807
{{mov{3,actrm{8,wc{{disable trim for binary file{15808
{acs6a{jsr{6,alocs{{{allocate string of correct size{15809
{{mov{8,wa{7,xl{{fcblk ptr{15810
{{jsr{6,sysin{{{call system input routine{15811
{{ppm{6,acs03{{{jump to fail exit if end of file{15812
{{ppm{6,acs22{{{error{15813
{{ppm{6,acs23{{{error{15814
{{ejc{{{{{15815
*      acess (continued)
*      merge here after obtaining input record
{acs07{mov{8,wb{3,actrm{{load trim indicator{15821
{{jsr{6,trimr{{{trim record as required{15822
{{mov{8,wb{7,xr{{copy result pointer{15823
{{mov{7,xr{9,(xs){{reload pointer to trblk{15824
*      loop to chase to end of trblk chain and store value
{acs08{mov{7,xl{7,xr{{save pointer to this trblk{15828
{{mov{7,xr{13,trnxt(xr){{load forward pointer{15829
{{beq{9,(xr){22,=b_trt{6,acs08{loop if this is another trblk{15830
{{mov{13,trnxt(xl){8,wb{{else store result at end of chain{15831
{{mov{7,xr{10,(xs)+{{restore initial trblk pointer{15832
{{mov{8,wa{10,(xs)+{{restore name offset{15833
{{mov{7,xl{10,(xs)+{{restore name base pointer{15834
*      come here to move to next trblk
{acs09{mov{7,xr{13,trnxt(xr){{load forward ptr to next value{15838
{{brn{6,acs02{{{back to check if trapped{15839
*      here to check for access trace trblk
{acs10{bne{8,wb{18,=trtac{6,acs09{loop back if not access trace{15843
{{bze{3,kvtra{6,acs09{{ignore access trace if trace off{15844
{{dcv{3,kvtra{{{else decrement trace count{15845
{{bze{13,trfnc(xr){6,acs11{{jump if print trace{15846
{{ejc{{{{{15847
*      acess (continued)
*      here for full function trace
{{jsr{6,trxeq{{{call routine to execute trace{15853
{{brn{6,acs09{{{jump for next trblk{15854
*      here for case of print trace
{acs11{jsr{6,prtsn{{{print statement number{15858
{{jsr{6,prtnv{{{print name = value{15859
{{brn{6,acs09{{{jump back for next trblk{15860
*      here for keyword variable
{acs12{mov{7,xr{13,kvnum(xl){{load keyword number{15864
{{bge{7,xr{18,=k_v__{6,acs14{jump if not one word value{15865
{{mti{15,kvabe(xr){{{else load value as integer{15866
*      common exit with keyword value as integer in (ia)
{acs13{jsr{6,icbld{{{build icblk{15870
{{brn{6,acs18{{{jump to exit{15871
*      here if not one word keyword value
{acs14{bge{7,xr{18,=k_s__{6,acs15{jump if special case{15875
{{sub{7,xr{18,=k_v__{{else get offset{15876
{{wtb{7,xr{{{convert to byte offset{15877
{{add{7,xr{21,=ndabo{{point to pattern value{15878
{{brn{6,acs18{{{jump to exit{15879
*      here if special keyword case
{acs15{mov{7,xl{3,kvrtn{{load rtntype in case{15883
{{ldi{3,kvstl{{{load stlimit in case{15884
{{sub{7,xr{18,=k_s__{{get case number{15885
{{bsw{7,xr{2,k__n_{{switch on keyword number{15886
{{iff{2,k__al{6,acs16{{jump if alphabet{15900
{{iff{2,k__rt{6,acs17{{rtntype{15900
{{iff{2,k__sc{6,acs19{{stcount{15900
{{iff{2,k__et{6,acs20{{errtext{15900
{{iff{2,k__fl{6,acs26{{file{15900
{{iff{2,k__lf{6,acs27{{lastfile{15900
{{iff{2,k__sl{6,acs13{{stlimit{15900
{{iff{2,k__lc{6,acs24{{lcase{15900
{{iff{2,k__uc{6,acs25{{ucase{15900
{{esw{{{{end switch on keyword number{15900
{{ejc{{{{{15901
*      acess (continued)
*      lcase
{acs24{mov{7,xr{21,=lcase{{load pointer to lcase string{15908
{{brn{6,acs18{{{common return{15909
*      ucase
{acs25{mov{7,xr{21,=ucase{{load pointer to ucase string{15913
{{brn{6,acs18{{{common return{15914
*      file
{acs26{mov{8,wc{3,kvstn{{load current stmt number{15920
{{brn{6,acs28{{{merge to obtain file name{15921
*      lastfile
{acs27{mov{8,wc{3,kvlst{{load last stmt number{15925
*      merge here to map statement number in wc to file name
{acs28{jsr{6,filnm{{{obtain file name for this stmt{15929
{{brn{6,acs17{{{merge to return string in xl{15930
*      alphabet
{acs16{mov{7,xl{3,kvalp{{load pointer to alphabet string{15934
*      rtntype merges here
{acs17{mov{7,xr{7,xl{{copy string ptr to proper reg{15938
*      common return point
{acs18{exi{{{{return to acess caller{15942
*      here for stcount (ia has stlimit)
{acs19{ilt{6,acs29{{{if counting suppressed{15946
{{mov{8,wa{3,stmcs{{refine with counter start value{15947
{{sub{8,wa{3,stmct{{minus current counter{15948
{{mti{8,wa{{{convert to integer{15949
{{adi{3,kvstl{{{add stlimit{15950
{acs29{sbi{3,kvstc{{{stcount = limit - left{15951
{{brn{6,acs13{{{merge back with integer result{15952
*      errtext
{acs20{mov{7,xr{3,r_etx{{get errtext string{15956
{{brn{6,acs18{{{merge with result{15957
*      here to read a record from terminal
{acs21{mov{8,wa{18,=rilen{{buffer length{15961
{{jsr{6,alocs{{{allocate buffer{15962
{{jsr{6,sysri{{{read record{15963
{{ppm{6,acs03{{{endfile{15964
{{brn{6,acs07{{{merge with record read{15965
*      error returns
{acs22{mov{3,dnamp{7,xr{{pop unused scblk{15969
{{erb{1,202{26,input from file caused non-recoverable error{{{15970
{acs23{mov{3,dnamp{7,xr{{pop unused scblk{15972
{{erb{1,203{26,input file record has incorrect format{{{15973
{{enp{{{{end procedure acess{15974
{{ejc{{{{{15975
*      acomp -- compare two arithmetic values
*      1(xs)                 first argument
*      0(xs)                 second argument
*      jsr  acomp            call to compare values
*      ppm  loc              transfer loc if arg1 is non-numeric
*      ppm  loc              transfer loc if arg2 is non-numeric
*      ppm  loc              transfer loc for arg1 lt arg2
*      ppm  loc              transfer loc for arg1 eq arg2
*      ppm  loc              transfer loc for arg1 gt arg2
*      (normal return is never given)
*      (wa,wb,wc,ia,ra)      destroyed
*      (xl,xr)               destroyed
{acomp{prc{25,n{1,5{{entry point{15991
{{jsr{6,arith{{{load arithmetic operands{15992
{{ppm{6,acmp7{{{jump if first arg non-numeric{15993
{{ppm{6,acmp8{{{jump if second arg non-numeric{15994
{{ppm{6,acmp4{{{jump if real arguments{15997
*      here for integer arguments
{{sbi{13,icval(xl){{{subtract to compare{16002
{{iov{6,acmp3{{{jump if overflow{16003
{{ilt{6,acmp5{{{else jump if arg1 lt arg2{16004
{{ieq{6,acmp2{{{jump if arg1 eq arg2{16005
*      here if arg1 gt arg2
{acmp1{exi{1,5{{{take gt exit{16009
*      here if arg1 eq arg2
{acmp2{exi{1,4{{{take eq exit{16013
{{ejc{{{{{16014
*      acomp (continued)
*      here for integer overflow on subtract
{acmp3{ldi{13,icval(xl){{{load second argument{16020
{{ilt{6,acmp1{{{gt if negative{16021
{{brn{6,acmp5{{{else lt{16022
*      here for real operands
{acmp4{sbr{13,rcval(xl){{{subtract to compare{16028
{{rov{6,acmp6{{{jump if overflow{16029
{{rgt{6,acmp1{{{else jump if arg1 gt{16030
{{req{6,acmp2{{{jump if arg1 eq arg2{16031
*      here if arg1 lt arg2
{acmp5{exi{1,3{{{take lt exit{16036
*      here if overflow on real subtraction
{acmp6{ldr{13,rcval(xl){{{reload arg2{16042
{{rlt{6,acmp1{{{gt if negative{16043
{{brn{6,acmp5{{{else lt{16044
*      here if arg1 non-numeric
{acmp7{exi{1,1{{{take error exit{16049
*      here if arg2 non-numeric
{acmp8{exi{1,2{{{take error exit{16053
{{enp{{{{end procedure acomp{16054
{{ejc{{{{{16055
*      alloc                 allocate block of dynamic storage
*      (wa)                  length required in bytes
*      jsr  alloc            call to allocate block
*      (xr)                  pointer to allocated block
*      a possible alternative to aov ... and following stmt is -
*      mov  dname,xr .  sub  wa,xr .  blo xr,dnamp,aloc2 .
*      mov  dnamp,xr .  add  wa,xr
{alloc{prc{25,e{1,0{{entry point{16067
*      common exit point
{aloc1{mov{7,xr{3,dnamp{{point to next available loc{16071
{{aov{8,wa{7,xr{6,aloc2{point past allocated block{16072
{{bgt{7,xr{3,dname{6,aloc2{jump if not enough room{16073
{{mov{3,dnamp{7,xr{{store new pointer{16074
{{sub{7,xr{8,wa{{point back to start of allocated bk{16075
{{exi{{{{return to caller{16076
*      here if insufficient room, try a garbage collection
{aloc2{mov{3,allsv{8,wb{{save wb{16080
{alc2a{zer{8,wb{{{set no upward move for gbcol{16081
{{jsr{6,gbcol{{{garbage collect{16082
{{mov{8,wb{7,xr{{remember new sediment size{16084
*      see if room after gbcol or sysmm call
{aloc3{mov{7,xr{3,dnamp{{point to first available loc{16089
{{aov{8,wa{7,xr{6,alc3a{point past new block{16090
{{blo{7,xr{3,dname{6,aloc4{jump if there is room now{16091
*      failed again, see if we can get more core
{alc3a{jsr{6,sysmm{{{try to get more memory{16095
{{wtb{7,xr{{{convert to baus (sgd05){16096
{{add{3,dname{7,xr{{bump ptr by amount obtained{16097
{{bnz{7,xr{6,aloc3{{jump if got more core{16098
{{bze{3,dnams{6,alc3b{{jump if there was no sediment{16100
{{zer{3,dnams{{{try collecting the sediment{16101
{{brn{6,alc2a{{{{16102
*      sysmm failed and there was no sediment to collect
{alc3b{add{3,dname{3,rsmem{{get the reserve memory{16106
{{zer{3,rsmem{{{only permissible once{16110
{{icv{3,errft{{{fatal error{16111
{{erb{1,204{26,memory overflow{{{16112
{{ejc{{{{{16113
*      here after successful garbage collection
{aloc4{sti{3,allia{{{save ia{16117
{{mov{3,dnams{8,wb{{record new sediment size{16119
{{mov{8,wb{3,dname{{get dynamic end adrs{16121
{{sub{8,wb{3,dnamp{{compute free store{16122
{{btw{8,wb{{{convert bytes to words{16123
{{mti{8,wb{{{put free store in ia{16124
{{mli{3,alfsf{{{multiply by free store factor{16125
{{iov{6,aloc5{{{jump if overflowed{16126
{{mov{8,wb{3,dname{{dynamic end adrs{16127
{{sub{8,wb{3,dnamb{{compute total amount of dynamic{16128
{{btw{8,wb{{{convert to words{16129
{{mov{3,aldyn{8,wb{{store it{16130
{{sbi{3,aldyn{{{subtract from scaled up free store{16131
{{igt{6,aloc5{{{jump if sufficient free store{16132
{{jsr{6,sysmm{{{try to get more store{16133
{{wtb{7,xr{{{convert to baus (sgd05){16134
{{add{3,dname{7,xr{{adjust dynamic end adrs{16135
*      merge to restore ia and wb
{aloc5{ldi{3,allia{{{recover ia{16139
{{mov{8,wb{3,allsv{{restore wb{16140
{{brn{6,aloc1{{{jump back to exit{16141
{{enp{{{{end procedure alloc{16142
{{ejc{{{{{16143
*      alocs -- allocate string block
*      alocs is used to build a frame for a string block into
*      which the actual characters are placed by the caller.
*      all strings are created with a call to alocs (the
*      exceptions occur in trimr and s_rpl procedures).
*      (wa)                  length of string to be allocated
*      jsr  alocs            call to allocate scblk
*      (xr)                  pointer to resulting scblk
*      (wa)                  destroyed
*      (wc)                  character count (entry value of wa)
*      the resulting scblk has the type word and the length
*      filled in and the last word is cleared to zero characters
*      to ensure correct right padding of the final word.
{alocs{prc{25,e{1,0{{entry point{16203
{{bgt{8,wa{3,kvmxl{6,alcs2{jump if length exceeds maxlength{16204
{{mov{8,wc{8,wa{{else copy length{16205
{{ctb{8,wa{2,scsi_{{compute length of scblk in bytes{16206
{{mov{7,xr{3,dnamp{{point to next available location{16207
{{aov{8,wa{7,xr{6,alcs0{point past block{16208
{{blo{7,xr{3,dname{6,alcs1{jump if there is room{16209
*      insufficient memory
{alcs0{zer{7,xr{{{else clear garbage xr value{16213
{{jsr{6,alloc{{{and use standard allocator{16214
{{add{7,xr{8,wa{{point past end of block to merge{16215
*      merge here with xr pointing beyond new block
{alcs1{mov{3,dnamp{7,xr{{set updated storage pointer{16219
{{zer{11,-(xr){{{store zero chars in last word{16220
{{dca{8,wa{{{decrement length{16221
{{sub{7,xr{8,wa{{point back to start of block{16222
{{mov{9,(xr){22,=b_scl{{set type word{16223
{{mov{13,sclen(xr){8,wc{{store length in chars{16224
{{exi{{{{return to alocs caller{16225
*      come here if string is too long
{alcs2{erb{1,205{26,string length exceeds value of maxlngth keyword{{{16229
{{enp{{{{end procedure alocs{16230
{{ejc{{{{{16231
*      alost -- allocate space in static region
*      (wa)                  length required in bytes
*      jsr  alost            call to allocate space
*      (xr)                  pointer to allocated block
*      (wb)                  destroyed
*      note that the coding ensures that the resulting value
*      of state is always less than dnamb. this fact is used
*      in testing a variable name for being in the static region
{alost{prc{25,e{1,0{{entry point{16244
*      merge back here after allocating new chunk
{alst1{mov{7,xr{3,state{{point to current end of area{16248
{{aov{8,wa{7,xr{6,alst2{point beyond proposed block{16249
{{bge{7,xr{3,dnamb{6,alst2{jump if overlap with dynamic area{16250
{{mov{3,state{7,xr{{else store new pointer{16251
{{sub{7,xr{8,wa{{point back to start of block{16252
{{exi{{{{return to alost caller{16253
*      here if no room, prepare to move dynamic storage up
{alst2{mov{3,alsta{8,wa{{save wa{16257
{{bge{8,wa{19,*e_sts{6,alst3{skip if requested chunk is large{16258
{{mov{8,wa{19,*e_sts{{else set to get large enough chunk{16259
*      here with amount to move up in wa
{alst3{jsr{6,alloc{{{allocate block to ensure room{16263
{{mov{3,dnamp{7,xr{{and delete it{16264
{{mov{8,wb{8,wa{{copy move up amount{16265
{{jsr{6,gbcol{{{call gbcol to move dynamic area up{16266
{{mov{3,dnams{7,xr{{remember new sediment size{16268
{{mov{8,wa{3,alsta{{restore wa{16270
{{brn{6,alst1{{{loop back to try again{16271
{{enp{{{{end procedure alost{16272
{{ejc{{{{{16273
*      arith -- fetch arithmetic operands
*      arith is used by functions and operators which expect
*      two numeric arguments (operands) which must both be
*      integer or both be real. arith fetches two arguments from
*      the stack and performs any necessary conversions.
*      1(xs)                 first argument (left operand)
*      0(xs)                 second argument (right operand)
*      jsr  arith            call to fetch numeric arguments
*      ppm  loc              transfer loc for opnd 1 non-numeric
*      ppm  loc              transfer loc for opnd 2 non-numeric
*      ppm  loc              transfer loc for real operands
*      for integer args, control returns past the parameters
*      (ia)                  left operand value
*      (xr)                  ptr to icblk for left operand
*      (xl)                  ptr to icblk for right operand
*      (xs)                  popped twice
*      (wa,wb,ra)            destroyed
*      for real arguments, control returns to the location
*      specified by the third parameter.
*      (ra)                  left operand value
*      (xr)                  ptr to rcblk for left operand
*      (xl)                  ptr to rcblk for right operand
*      (wa,wb,wc)            destroyed
*      (xs)                  popped twice
{{ejc{{{{{16347
*      arith (continued)
*      entry point
{arith{prc{25,n{1,3{{entry point{16356
{{mov{7,xl{10,(xs)+{{load right operand{16358
{{mov{7,xr{10,(xs)+{{load left operand{16359
{{mov{8,wa{9,(xl){{get right operand type word{16360
{{beq{8,wa{22,=b_icl{6,arth1{jump if integer{16361
{{beq{8,wa{22,=b_rcl{6,arth4{jump if real{16364
{{mov{11,-(xs){7,xr{{else replace left arg on stack{16366
{{mov{7,xr{7,xl{{copy left arg pointer{16367
{{jsr{6,gtnum{{{convert to numeric{16368
{{ppm{6,arth6{{{jump if unconvertible{16369
{{mov{7,xl{7,xr{{else copy converted result{16370
{{mov{8,wa{9,(xl){{get right operand type word{16371
{{mov{7,xr{10,(xs)+{{reload left argument{16372
{{beq{8,wa{22,=b_rcl{6,arth4{jump if right arg is real{16375
*      here if right arg is an integer
{arth1{bne{9,(xr){22,=b_icl{6,arth3{jump if left arg not integer{16380
*      exit for integer case
{arth2{ldi{13,icval(xr){{{load left operand value{16384
{{exi{{{{return to arith caller{16385
*      here for right operand integer, left operand not
{arth3{jsr{6,gtnum{{{convert left arg to numeric{16389
{{ppm{6,arth7{{{jump if not convertible{16390
{{beq{8,wa{22,=b_icl{6,arth2{jump back if integer-integer{16391
*      here we must convert real-integer to real-real
{{mov{11,-(xs){7,xr{{put left arg back on stack{16397
{{ldi{13,icval(xl){{{load right argument value{16398
{{itr{{{{convert to real{16399
{{jsr{6,rcbld{{{get real block for right arg, merge{16400
{{mov{7,xl{7,xr{{copy right arg ptr{16401
{{mov{7,xr{10,(xs)+{{load left argument{16402
{{brn{6,arth5{{{merge for real-real case{16403
{{ejc{{{{{16404
*      arith (continued)
*      here if right argument is real
{arth4{beq{9,(xr){22,=b_rcl{6,arth5{jump if left arg real{16410
{{jsr{6,gtrea{{{else convert to real{16411
{{ppm{6,arth7{{{error if unconvertible{16412
*      here for real-real
{arth5{ldr{13,rcval(xr){{{load left operand value{16416
{{exi{1,3{{{take real-real exit{16417
*      here for error converting right argument
{arth6{ica{7,xs{{{pop unwanted left arg{16422
{{exi{1,2{{{take appropriate error exit{16423
*      here for error converting left operand
{arth7{exi{1,1{{{take appropriate error return{16427
{{enp{{{{end procedure arith{16428
{{ejc{{{{{16429
*      asign -- perform assignment
*      asign performs the assignment of a value to a variable
*      with appropriate checks for output associations and
*      value trace associations which are executed as required.
*      asign also handles the special cases of assignment to
*      pattern and expression variables.
*      (wb)                  value to be assigned
*      (xl)                  base pointer for variable
*      (wa)                  offset for variable
*      jsr  asign            call to assign value to variable
*      ppm  loc              transfer loc for failure
*      (xr,xl,wa,wb,wc)      destroyed
*      (ra)                  destroyed
*      failure occurs if the evaluation of an expression
*      associated with an expression variable fails.
{asign{prc{25,r{1,1{{entry point (recursive){16450
*      merge back here to assign result to expression variable.
{asg01{add{7,xl{8,wa{{point to variable value{16454
{{mov{7,xr{9,(xl){{load variable value{16455
{{beq{9,(xr){22,=b_trt{6,asg02{jump if trapped{16456
{{mov{9,(xl){8,wb{{else perform assignment{16457
{{zer{7,xl{{{clear garbage value in xl{16458
{{exi{{{{and return to asign caller{16459
*      here if value is trapped
{asg02{sub{7,xl{8,wa{{restore name base{16463
{{beq{7,xr{21,=trbkv{6,asg14{jump if keyword variable{16464
{{bne{7,xr{21,=trbev{6,asg04{jump if not expression variable{16465
*      here for assignment to expression variable
{{mov{7,xr{13,evexp(xl){{point to expression{16469
{{mov{11,-(xs){8,wb{{store value to assign on stack{16470
{{mov{8,wb{18,=num01{{set for evaluation by name{16471
{{jsr{6,evalx{{{evaluate expression by name{16472
{{ppm{6,asg03{{{jump if evaluation fails{16473
{{mov{8,wb{10,(xs)+{{else reload value to assign{16474
{{brn{6,asg01{{{loop back to perform assignment{16475
{{ejc{{{{{16476
*      asign (continued)
*      here for failure during expression evaluation
{asg03{ica{7,xs{{{remove stacked value entry{16482
{{exi{1,1{{{take failure exit{16483
*      here if not keyword or expression variable
{asg04{mov{11,-(xs){7,xr{{save ptr to first trblk{16487
*      loop to chase down trblk chain and assign value at end
{asg05{mov{8,wc{7,xr{{save ptr to this trblk{16491
{{mov{7,xr{13,trnxt(xr){{point to next trblk{16492
{{beq{9,(xr){22,=b_trt{6,asg05{loop back if another trblk{16493
{{mov{7,xr{8,wc{{else point back to last trblk{16494
{{mov{13,trval(xr){8,wb{{store value at end of chain{16495
{{mov{7,xr{10,(xs)+{{restore ptr to first trblk{16496
*      loop to process trblk entries on chain
{asg06{mov{8,wb{13,trtyp(xr){{load type code of trblk{16500
{{beq{8,wb{18,=trtvl{6,asg08{jump if value trace{16501
{{beq{8,wb{18,=trtou{6,asg10{jump if output association{16502
*      here to move to next trblk on chain
{asg07{mov{7,xr{13,trnxt(xr){{point to next trblk on chain{16506
{{beq{9,(xr){22,=b_trt{6,asg06{loop back if another trblk{16507
{{exi{{{{else end of chain, return to caller{16508
*      here to process value trace
{asg08{bze{3,kvtra{6,asg07{{ignore value trace if trace off{16512
{{dcv{3,kvtra{{{else decrement trace count{16513
{{bze{13,trfnc(xr){6,asg09{{jump if print trace{16514
{{jsr{6,trxeq{{{else execute function trace{16515
{{brn{6,asg07{{{and loop back{16516
{{ejc{{{{{16517
*      asign (continued)
*      here for print trace
{asg09{jsr{6,prtsn{{{print statement number{16523
{{jsr{6,prtnv{{{print name = value{16524
{{brn{6,asg07{{{loop back for next trblk{16525
*      here for output association
{asg10{bze{3,kvoup{6,asg07{{ignore output assoc if output off{16529
{asg1b{mov{7,xl{7,xr{{copy trblk pointer{16530
{{mov{7,xr{13,trnxt(xr){{point to next trblk{16531
{{beq{9,(xr){22,=b_trt{6,asg1b{loop back if another trblk{16532
{{mov{7,xr{7,xl{{else point back to last trblk{16533
{{mov{11,-(xs){13,trval(xr){{stack value to output{16535
{{jsr{6,gtstg{{{convert to string{16541
{{ppm{6,asg12{{{get datatype name if unconvertible{16542
*      merge with string or buffer to output in xr
{asg11{mov{8,wa{13,trfpt(xl){{fcblk ptr{16546
{{bze{8,wa{6,asg13{{jump if standard output file{16547
*      here for output to file
{asg1a{jsr{6,sysou{{{call system output routine{16551
{{err{1,206{26,output caused file overflow{{{16552
{{err{1,207{26,output caused non-recoverable error{{{16553
{{exi{{{{else all done, return to caller{16554
*      if not printable, get datatype name instead
{asg12{jsr{6,dtype{{{call datatype routine{16558
{{brn{6,asg11{{{merge{16559
*      here to print a string to standard output or terminal
{asg13{beq{13,trter(xl){21,=v_ter{6,asg1a{jump if terminal output{16564
{{icv{8,wa{{{signal standard output{16565
{{brn{6,asg1a{{{use sysou to perform output{16566
{{ejc{{{{{16581
*      asign (continued)
*      here for keyword assignment
{asg14{mov{7,xl{13,kvnum(xl){{load keyword number{16587
{{beq{7,xl{18,=k_etx{6,asg19{jump if errtext{16588
{{mov{7,xr{8,wb{{copy value to be assigned{16589
{{jsr{6,gtint{{{convert to integer{16590
{{err{1,208{26,keyword value assigned is not integer{{{16591
{{ldi{13,icval(xr){{{else load value{16592
{{beq{7,xl{18,=k_stl{6,asg16{jump if special case of stlimit{16593
{{mfi{8,wa{6,asg18{{else get addr integer, test ovflow{16594
{{bgt{8,wa{3,mxlen{6,asg18{fail if too large{16595
{{beq{7,xl{18,=k_ert{6,asg17{jump if special case of errtype{16596
{{beq{7,xl{18,=k_pfl{6,asg21{jump if special case of profile{16599
{{beq{7,xl{18,=k_mxl{6,asg24{jump if special case of maxlngth{16601
{{beq{7,xl{18,=k_fls{6,asg26{jump if special case of fullscan{16602
{{blt{7,xl{18,=k_p__{6,asg15{jump unless protected{16603
{{erb{1,209{26,keyword in assignment is protected{{{16604
*      here to do assignment if not protected
{asg15{mov{15,kvabe(xl){8,wa{{store new value{16608
{{exi{{{{return to asign caller{16609
*      here for special case of stlimit
*      since stcount is maintained as (stlimit-stcount)
*      it is also necessary to modify stcount appropriately.
{asg16{sbi{3,kvstl{{{subtract old limit{16616
{{adi{3,kvstc{{{add old counter{16617
{{sti{3,kvstc{{{store course counter value{16618
{{ldi{3,kvstl{{{check if counting suppressed{16619
{{ilt{6,asg25{{{do not refine if so{16620
{{mov{8,wa{3,stmcs{{refine with counter breakout{16621
{{sub{8,wa{3,stmct{{values{16622
{{mti{8,wa{{{convert to integer{16623
{{ngi{{{{current-start value{16624
{{adi{3,kvstc{{{add in course counter value{16625
{{sti{3,kvstc{{{save refined value{16626
{asg25{ldi{13,icval(xr){{{reload new limit value{16627
{{sti{3,kvstl{{{store new limit value{16628
{{jsr{6,stgcc{{{recompute countdown counters{16629
{{exi{{{{return to asign caller{16630
*      here for special case of errtype
{asg17{ble{8,wa{18,=nini9{6,error{ok to signal if in range{16634
*      here if value assigned is out of range
{asg18{erb{1,210{26,keyword value assigned is negative or too large{{{16638
*      here for special case of errtext
{asg19{mov{11,-(xs){8,wb{{stack value{16642
{{jsr{6,gtstg{{{convert to string{16643
{{err{1,211{26,value assigned to keyword errtext not a string{{{16644
{{mov{3,r_etx{7,xr{{make assignment{16645
{{exi{{{{return to caller{16646
*      here for keyword profile
{asg21{bgt{8,wa{18,=num02{6,asg18{moan if not 0,1, or 2{16660
{{bze{8,wa{6,asg15{{just assign if zero{16661
{{bze{3,pfdmp{6,asg22{{branch if first assignment{16662
{{beq{8,wa{3,pfdmp{6,asg23{also if same value as before{16663
{{erb{1,268{26,inconsistent value assigned to keyword profile{{{16664
{asg22{mov{3,pfdmp{8,wa{{note value on first assignment{16666
{asg23{mov{3,kvpfl{8,wa{{store new value{16667
{{jsr{6,stgcc{{{recompute countdown counts{16668
{{jsr{6,systm{{{get the time{16669
{{sti{3,pfstm{{{fudge some kind of start time{16670
{{exi{{{{return to asign caller{16671
*      here for keyword maxlngth
{asg24{bge{8,wa{18,=mnlen{6,asg15{if acceptable value{16676
{{erb{1,287{26,value assigned to keyword maxlngth is too small{{{16677
*      here for keyword fullscan
{asg26{bnz{8,wa{6,asg15{{if acceptable value{16681
{{erb{1,274{26,value assigned to keyword fullscan is zero{{{16682
{{enp{{{{end procedure asign{16684
{{ejc{{{{{16685
*      asinp -- assign during pattern match
*      asinp is like asign and has a similar calling sequence
*      and effect. the difference is that the global pattern
*      variables are saved and restored if required.
*      (xl)                  base pointer for variable
*      (wa)                  offset for variable
*      (wb)                  value to be assigned
*      jsr  asinp            call to assign value to variable
*      ppm  loc              transfer loc if failure
*      (xr,xl)               destroyed
*      (wa,wb,wc,ra)         destroyed
{asinp{prc{25,r{1,1{{entry point, recursive{16701
{{add{7,xl{8,wa{{point to variable{16702
{{mov{7,xr{9,(xl){{load current contents{16703
{{beq{9,(xr){22,=b_trt{6,asnp1{jump if trapped{16704
{{mov{9,(xl){8,wb{{else perform assignment{16705
{{zer{7,xl{{{clear garbage value in xl{16706
{{exi{{{{return to asinp caller{16707
*      here if variable is trapped
{asnp1{sub{7,xl{8,wa{{restore base pointer{16711
{{mov{11,-(xs){3,pmssl{{stack subject string length{16712
{{mov{11,-(xs){3,pmhbs{{stack history stack base ptr{16713
{{mov{11,-(xs){3,r_pms{{stack subject string pointer{16714
{{mov{11,-(xs){3,pmdfl{{stack dot flag{16715
{{jsr{6,asign{{{call full-blown assignment routine{16716
{{ppm{6,asnp2{{{jump if failure{16717
{{mov{3,pmdfl{10,(xs)+{{restore dot flag{16718
{{mov{3,r_pms{10,(xs)+{{restore subject string pointer{16719
{{mov{3,pmhbs{10,(xs)+{{restore history stack base pointer{16720
{{mov{3,pmssl{10,(xs)+{{restore subject string length{16721
{{exi{{{{return to asinp caller{16722
*      here if failure in asign call
{asnp2{mov{3,pmdfl{10,(xs)+{{restore dot flag{16726
{{mov{3,r_pms{10,(xs)+{{restore subject string pointer{16727
{{mov{3,pmhbs{10,(xs)+{{restore history stack base pointer{16728
{{mov{3,pmssl{10,(xs)+{{restore subject string length{16729
{{exi{1,1{{{take failure exit{16730
{{enp{{{{end procedure asinp{16731
{{ejc{{{{{16732
*      blkln -- determine length of block
*      blkln determines the length of a block in dynamic store.
*      (wa)                  first word of block
*      (xr)                  pointer to block
*      jsr  blkln            call to get block length
*      (wa)                  length of block in bytes
*      (xl)                  destroyed
*      blkln is used by the garbage collector and is not
*      permitted to call gbcol directly or indirectly.
*      the first word stored in the block (i.e. at xr) may
*      be anything, but the contents of wa must be correct.
{blkln{prc{25,e{1,0{{entry point{16750
{{mov{7,xl{8,wa{{copy first word{16751
{{lei{7,xl{{{get entry id (bl_xx){16752
{{bsw{7,xl{2,bl___{6,bln00{switch on block type{16753
{{iff{2,bl_ar{6,bln01{{arblk{16793
{{iff{2,bl_cd{6,bln12{{cdblk{16793
{{iff{2,bl_ex{6,bln12{{exblk{16793
{{iff{2,bl_ic{6,bln07{{icblk{16793
{{iff{2,bl_nm{6,bln03{{nmblk{16793
{{iff{2,bl_p0{6,bln02{{p0blk{16793
{{iff{2,bl_p1{6,bln03{{p1blk{16793
{{iff{2,bl_p2{6,bln04{{p2blk{16793
{{iff{2,bl_rc{6,bln09{{rcblk{16793
{{iff{2,bl_sc{6,bln10{{scblk{16793
{{iff{2,bl_se{6,bln02{{seblk{16793
{{iff{2,bl_tb{6,bln01{{tbblk{16793
{{iff{2,bl_vc{6,bln01{{vcblk{16793
{{iff{1,13{6,bln00{{{16793
{{iff{1,14{6,bln00{{{16793
{{iff{1,15{6,bln00{{{16793
{{iff{2,bl_pd{6,bln08{{pdblk{16793
{{iff{2,bl_tr{6,bln05{{trblk{16793
{{iff{1,18{6,bln00{{{16793
{{iff{1,19{6,bln00{{{16793
{{iff{1,20{6,bln00{{{16793
{{iff{2,bl_ct{6,bln06{{ctblk{16793
{{iff{2,bl_df{6,bln01{{dfblk{16793
{{iff{2,bl_ef{6,bln01{{efblk{16793
{{iff{2,bl_ev{6,bln03{{evblk{16793
{{iff{2,bl_ff{6,bln05{{ffblk{16793
{{iff{2,bl_kv{6,bln03{{kvblk{16793
{{iff{2,bl_pf{6,bln01{{pfblk{16793
{{iff{2,bl_te{6,bln04{{teblk{16793
{{esw{{{{end of jump table on block type{16793
{{ejc{{{{{16794
*      blkln (continued)
*      here for blocks with length in second word
{bln00{mov{8,wa{13,num01(xr){{load length{16800
{{exi{{{{return to blkln caller{16801
*      here for length in third word (ar,cd,df,ef,ex,pf,tb,vc)
{bln01{mov{8,wa{13,num02(xr){{load length from third word{16805
{{exi{{{{return to blkln caller{16806
*      here for two word blocks (p0,se)
{bln02{mov{8,wa{19,*num02{{load length (two words){16810
{{exi{{{{return to blkln caller{16811
*      here for three word blocks (nm,p1,ev,kv)
{bln03{mov{8,wa{19,*num03{{load length (three words){16815
{{exi{{{{return to blkln caller{16816
*      here for four word blocks (p2,te,bc)
{bln04{mov{8,wa{19,*num04{{load length (four words){16820
{{exi{{{{return to blkln caller{16821
*      here for five word blocks (ff,tr)
{bln05{mov{8,wa{19,*num05{{load length{16825
{{exi{{{{return to blkln caller{16826
{{ejc{{{{{16827
*      blkln (continued)
*      here for ctblk
{bln06{mov{8,wa{19,*ctsi_{{set size of ctblk{16833
{{exi{{{{return to blkln caller{16834
*      here for icblk
{bln07{mov{8,wa{19,*icsi_{{set size of icblk{16838
{{exi{{{{return to blkln caller{16839
*      here for pdblk
{bln08{mov{7,xl{13,pddfp(xr){{point to dfblk{16843
{{mov{8,wa{13,dfpdl(xl){{load pdblk length from dfblk{16844
{{exi{{{{return to blkln caller{16845
*      here for rcblk
{bln09{mov{8,wa{19,*rcsi_{{set size of rcblk{16851
{{exi{{{{return to blkln caller{16852
*      here for scblk
{bln10{mov{8,wa{13,sclen(xr){{load length in characters{16857
{{ctb{8,wa{2,scsi_{{calculate length in bytes{16858
{{exi{{{{return to blkln caller{16859
*      here for length in fourth word (cd,ex)
{bln12{mov{8,wa{13,num03(xr){{load length from cdlen/exlen{16873
{{exi{{{{return to blkln caller{16874
{{enp{{{{end procedure blkln{16876
{{ejc{{{{{16877
*      copyb -- copy a block
*      (xs)                  block to be copied
*      jsr  copyb            call to copy block
*      ppm  loc              return if block has no idval field
*                            normal return if idval field
*      (xr)                  copy of block
*      (xs)                  popped
*      (xl,wa,wb,wc)         destroyed
{copyb{prc{25,n{1,1{{entry point{16889
{{mov{7,xr{9,(xs){{load argument{16890
{{beq{7,xr{21,=nulls{6,cop10{return argument if it is null{16891
{{mov{8,wa{9,(xr){{else load type word{16892
{{mov{8,wb{8,wa{{copy type word{16893
{{jsr{6,blkln{{{get length of argument block{16894
{{mov{7,xl{7,xr{{copy pointer{16895
{{jsr{6,alloc{{{allocate block of same size{16896
{{mov{9,(xs){7,xr{{store pointer to copy{16897
{{mvw{{{{copy contents of old block to new{16898
{{zer{7,xl{{{clear garbage xl{16899
{{mov{7,xr{9,(xs){{reload pointer to start of copy{16900
{{beq{8,wb{22,=b_tbt{6,cop05{jump if table{16901
{{beq{8,wb{22,=b_vct{6,cop01{jump if vector{16902
{{beq{8,wb{22,=b_pdt{6,cop01{jump if program defined{16903
{{bne{8,wb{22,=b_art{6,cop10{return copy if not array{16908
*      here for array (arblk)
{{add{7,xr{13,arofs(xr){{point to prototype field{16912
{{brn{6,cop02{{{jump to merge{16913
*      here for vector, program defined
{cop01{add{7,xr{19,*pdfld{{point to pdfld = vcvls{16917
*      merge here for arblk, vcblk, pdblk to delete trap
*      blocks from all value fields (the copy is untrapped)
{cop02{mov{7,xl{9,(xr){{load next pointer{16922
*      loop to get value at end of trblk chain
{cop03{bne{9,(xl){22,=b_trt{6,cop04{jump if not trapped{16926
{{mov{7,xl{13,trval(xl){{else point to next value{16927
{{brn{6,cop03{{{and loop back{16928
{{ejc{{{{{16929
*      copyb (continued)
*      here with untrapped value in xl
{cop04{mov{10,(xr)+{7,xl{{store real value, bump pointer{16935
{{bne{7,xr{3,dnamp{6,cop02{loop back if more to go{16936
{{brn{6,cop09{{{else jump to exit{16937
*      here to copy a table
{cop05{zer{13,idval(xr){{{zero id to stop dump blowing up{16941
{{mov{8,wa{19,*tesi_{{set size of teblk{16942
{{mov{8,wc{19,*tbbuk{{set initial offset{16943
*      loop through buckets in table
{cop06{mov{7,xr{9,(xs){{load table pointer{16947
{{beq{8,wc{13,tblen(xr){6,cop09{jump to exit if all done{16948
{{mov{8,wb{8,wc{{else copy offset{16949
{{sub{8,wb{19,*tenxt{{subtract link offset to merge{16950
{{add{7,xr{8,wb{{next bucket header less link offset{16951
{{ica{8,wc{{{bump offset{16952
*      loop through teblks on one chain
{cop07{mov{7,xl{13,tenxt(xr){{load pointer to next teblk{16956
{{mov{13,tenxt(xr){9,(xs){{set end of chain pointer in case{16957
{{beq{9,(xl){22,=b_tbt{6,cop06{back for next bucket if chain end{16958
{{sub{7,xr{8,wb{{point to head of previous block{16959
{{mov{11,-(xs){7,xr{{stack ptr to previous block{16960
{{mov{8,wa{19,*tesi_{{set size of teblk{16961
{{jsr{6,alloc{{{allocate new teblk{16962
{{mov{11,-(xs){7,xr{{stack ptr to new teblk{16963
{{mvw{{{{copy old teblk to new teblk{16964
{{mov{7,xr{10,(xs)+{{restore pointer to new teblk{16965
{{mov{7,xl{10,(xs)+{{restore pointer to previous block{16966
{{add{7,xl{8,wb{{add offset back in{16967
{{mov{13,tenxt(xl){7,xr{{link new block to previous{16968
{{mov{7,xl{7,xr{{copy pointer to new block{16969
*      loop to set real value after removing trap chain
{cop08{mov{7,xl{13,teval(xl){{load value{16973
{{beq{9,(xl){22,=b_trt{6,cop08{loop back if trapped{16974
{{mov{13,teval(xr){7,xl{{store untrapped value in teblk{16975
{{zer{8,wb{{{zero offset within teblk{16976
{{brn{6,cop07{{{back for next teblk{16977
*      common exit point
{cop09{mov{7,xr{10,(xs)+{{load pointer to block{16981
{{exi{{{{return{16982
*      alternative return
{cop10{exi{1,1{{{return{16986
{{ejc{{{{{16987
{{enp{{{{end procedure copyb{17005
*      cdgcg -- generate code for complex goto
*      used by cmpil to process complex goto tree
*      (wb)                  must be collectable
*      (xr)                  expression pointer
*      jsr  cdgcg            call to generate complex goto
*      (xl,xr,wa)            destroyed
{cdgcg{prc{25,e{1,0{{entry point{17016
{{mov{7,xl{13,cmopn(xr){{get unary goto operator{17017
{{mov{7,xr{13,cmrop(xr){{point to goto operand{17018
{{beq{7,xl{21,=opdvd{6,cdgc2{jump if direct goto{17019
{{jsr{6,cdgnm{{{generate opnd by name if not direct{17020
*      return point
{cdgc1{mov{8,wa{7,xl{{goto operator{17024
{{jsr{6,cdwrd{{{generate it{17025
{{exi{{{{return to caller{17026
*      direct goto
{cdgc2{jsr{6,cdgvl{{{generate operand by value{17030
{{brn{6,cdgc1{{{merge to return{17031
{{enp{{{{end procedure cdgcg{17032
{{ejc{{{{{17033
*      cdgex -- build expression block
*      cdgex is passed a pointer to an expression tree (see
*      expan) and returns an expression (seblk or exblk).
*      (wa)                  0 if by value, 1 if by name
*      (wc)                  some collectable value
*      (wb)                  integer in range 0 le x le mxlen
*      (xl)                  ptr to expression tree
*      jsr  cdgex            call to build expression
*      (xr)                  ptr to seblk or exblk
*      (xl,wa,wb)            destroyed
{cdgex{prc{25,r{1,0{{entry point, recursive{17050
{{blo{9,(xl){22,=b_vr_{6,cdgx1{jump if not variable{17051
*      here for natural variable, build seblk
{{mov{8,wa{19,*sesi_{{set size of seblk{17055
{{jsr{6,alloc{{{allocate space for seblk{17056
{{mov{9,(xr){22,=b_sel{{set type word{17057
{{mov{13,sevar(xr){7,xl{{store vrblk pointer{17058
{{exi{{{{return to cdgex caller{17059
*      here if not variable, build exblk
{cdgx1{mov{7,xr{7,xl{{copy tree pointer{17063
{{mov{11,-(xs){8,wc{{save wc{17064
{{mov{7,xl{3,cwcof{{save current offset{17065
{{bze{8,wa{6,cdgx2{{jump if by value{17067
{{mov{8,wa{9,(xr){{get type word{17069
{{bne{8,wa{22,=b_cmt{6,cdgx2{call by value if not cmblk{17070
{{bge{13,cmtyp(xr){18,=c__nm{6,cdgx2{jump if cmblk only by value{17071
{{ejc{{{{{17072
*      cdgex (continued)
*      here if expression can be evaluated by name
{{jsr{6,cdgnm{{{generate code by name{17078
{{mov{8,wa{21,=ornm_{{load return by name word{17079
{{brn{6,cdgx3{{{merge with value case{17080
*      here if expression can only be evaluated by value
{cdgx2{jsr{6,cdgvl{{{generate code by value{17084
{{mov{8,wa{21,=orvl_{{load return by value word{17085
*      merge here to construct exblk
{cdgx3{jsr{6,cdwrd{{{generate return word{17089
{{jsr{6,exbld{{{build exblk{17090
{{mov{8,wc{10,(xs)+{{restore wc{17091
{{exi{{{{return to cdgex caller{17092
{{enp{{{{end procedure cdgex{17093
{{ejc{{{{{17094
*      cdgnm -- generate code by name
*      cdgnm is called during the compilation process to
*      generate code by name for an expression. see cdblk
*      description for details of code generated. the input
*      to cdgnm is an expression tree as generated by expan.
*      cdgnm is a recursive procedure which proceeds by making
*      recursive calls to generate code for operands.
*      (wb)                  integer in range 0 le n le dnamb
*      (xr)                  ptr to tree generated by expan
*      (wc)                  constant flag (see below)
*      jsr  cdgnm            call to generate code by name
*      (xr,wa)               destroyed
*      (wc)                  set non-zero if non-constant
*      wc is set to a non-zero (collectable) value if the
*      expression for which code is generated cannot be
*      evaluated at compile time, otherwise wc is unchanged.
*      the code is generated in the current ccblk (see cdwrd).
{cdgnm{prc{25,r{1,0{{entry point, recursive{17119
{{mov{11,-(xs){7,xl{{save entry xl{17120
{{mov{11,-(xs){8,wb{{save entry wb{17121
{{chk{{{{check for stack overflow{17122
{{mov{8,wa{9,(xr){{load type word{17123
{{beq{8,wa{22,=b_cmt{6,cgn04{jump if cmblk{17124
{{bhi{8,wa{22,=b_vr_{6,cgn02{jump if simple variable{17125
*      merge here for operand yielding value (e.g. constant)
{cgn01{erb{1,212{26,syntax error: value used where name is required{{{17129
*      here for natural variable reference
{cgn02{mov{8,wa{21,=olvn_{{load variable load call{17133
{{jsr{6,cdwrd{{{generate it{17134
{{mov{8,wa{7,xr{{copy vrblk pointer{17135
{{jsr{6,cdwrd{{{generate vrblk pointer{17136
{{ejc{{{{{17137
*      cdgnm (continued)
*      here to exit with wc set correctly
{cgn03{mov{8,wb{10,(xs)+{{restore entry wb{17143
{{mov{7,xl{10,(xs)+{{restore entry xl{17144
{{exi{{{{return to cdgnm caller{17145
*      here for cmblk
{cgn04{mov{7,xl{7,xr{{copy cmblk pointer{17149
{{mov{7,xr{13,cmtyp(xr){{load cmblk type{17150
{{bge{7,xr{18,=c__nm{6,cgn01{error if not name operand{17151
{{bsw{7,xr{2,c__nm{{else switch on type{17152
{{iff{2,c_arr{6,cgn05{{array reference{17160
{{iff{2,c_fnc{6,cgn08{{function call{17160
{{iff{2,c_def{6,cgn09{{deferred expression{17160
{{iff{2,c_ind{6,cgn10{{indirect reference{17160
{{iff{2,c_key{6,cgn11{{keyword reference{17160
{{iff{2,c_ubo{6,cgn08{{undefined binary op{17160
{{iff{2,c_uuo{6,cgn08{{undefined unary op{17160
{{esw{{{{end switch on cmblk type{17160
*      here to generate code for array reference
{cgn05{mov{8,wb{19,*cmopn{{point to array operand{17164
*      loop to generate code for array operand and subscripts
{cgn06{jsr{6,cmgen{{{generate code for next operand{17168
{{mov{8,wc{13,cmlen(xl){{load length of cmblk{17169
{{blt{8,wb{8,wc{6,cgn06{loop till all generated{17170
*      generate appropriate array call
{{mov{8,wa{21,=oaon_{{load one-subscript case call{17174
{{beq{8,wc{19,*cmar1{6,cgn07{jump to exit if one subscript case{17175
{{mov{8,wa{21,=oamn_{{else load multi-subscript case call{17176
{{jsr{6,cdwrd{{{generate call{17177
{{mov{8,wa{8,wc{{copy cmblk length{17178
{{btw{8,wa{{{convert to words{17179
{{sub{8,wa{18,=cmvls{{calculate number of subscripts{17180
{{ejc{{{{{17181
*      cdgnm (continued)
*      here to exit generating word (non-constant)
{cgn07{mnz{8,wc{{{set result non-constant{17187
{{jsr{6,cdwrd{{{generate word{17188
{{brn{6,cgn03{{{back to exit{17189
*      here to generate code for functions and undefined oprs
{cgn08{mov{7,xr{7,xl{{copy cmblk pointer{17193
{{jsr{6,cdgvl{{{gen code by value for call{17194
{{mov{8,wa{21,=ofne_{{get extra call for by name{17195
{{brn{6,cgn07{{{back to generate and exit{17196
*      here to generate code for defered expression
{cgn09{mov{7,xr{13,cmrop(xl){{check if variable{17200
{{bhi{9,(xr){22,=b_vr_{6,cgn02{treat *variable as simple var{17201
{{mov{7,xl{7,xr{{copy ptr to expression tree{17202
{{mov{8,wa{18,=num01{{return name{17204
{{jsr{6,cdgex{{{else build exblk{17206
{{mov{8,wa{21,=olex_{{set call to load expr by name{17207
{{jsr{6,cdwrd{{{generate it{17208
{{mov{8,wa{7,xr{{copy exblk pointer{17209
{{jsr{6,cdwrd{{{generate exblk pointer{17210
{{brn{6,cgn03{{{back to exit{17211
*      here to generate code for indirect reference
{cgn10{mov{7,xr{13,cmrop(xl){{get operand{17215
{{jsr{6,cdgvl{{{generate code by value for it{17216
{{mov{8,wa{21,=oinn_{{load call for indirect by name{17217
{{brn{6,cgn12{{{merge{17218
*      here to generate code for keyword reference
{cgn11{mov{7,xr{13,cmrop(xl){{get operand{17222
{{jsr{6,cdgnm{{{generate code by name for it{17223
{{mov{8,wa{21,=okwn_{{load call for keyword by name{17224
*      keyword, indirect merge here
{cgn12{jsr{6,cdwrd{{{generate code for operator{17228
{{brn{6,cgn03{{{exit{17229
{{enp{{{{end procedure cdgnm{17230
{{ejc{{{{{17231
*      cdgvl -- generate code by value
*      cdgvl is called during the compilation process to
*      generate code by value for an expression. see cdblk
*      description for details of the code generated. the input
*      to cdgvl is an expression tree as generated by expan.
*      cdgvl is a recursive procedure which proceeds by making
*      recursive calls to generate code for operands.
*      (wb)                  integer in range 0 le n le dnamb
*      (xr)                  ptr to tree generated by expan
*      (wc)                  constant flag (see below)
*      jsr  cdgvl            call to generate code by value
*      (xr,wa)               destroyed
*      (wc)                  set non-zero if non-constant
*      wc is set to a non-zero (collectable) value if the
*      expression for which code is generated cannot be
*      evaluated at compile time, otherwise wc is unchanged.
*      if wc is non-zero on entry, then preevaluation is not
*      allowed regardless of the nature of the operand.
*      the code is generated in the current ccblk (see cdwrd).
{cdgvl{prc{25,r{1,0{{entry point, recursive{17259
{{mov{8,wa{9,(xr){{load type word{17260
{{beq{8,wa{22,=b_cmt{6,cgv01{jump if cmblk{17261
{{blt{8,wa{22,=b_vra{6,cgv00{jump if icblk, rcblk, scblk{17262
{{bnz{13,vrlen(xr){6,cgvl0{{jump if not system variable{17263
{{mov{11,-(xs){7,xr{{stack xr{17264
{{mov{7,xr{13,vrsvp(xr){{point to svblk{17265
{{mov{8,wa{13,svbit(xr){{get svblk property bits{17266
{{mov{7,xr{10,(xs)+{{recover xr{17267
{{anb{8,wa{4,btkwv{{check if constant keyword value{17268
{{beq{8,wa{4,btkwv{6,cgv00{jump if constant keyword value{17269
*      here for variable value reference
{cgvl0{mnz{8,wc{{{indicate non-constant value{17273
*      merge here for simple constant (icblk,rcblk,scblk)
*      and for variables corresponding to constant keywords.
{cgv00{mov{8,wa{7,xr{{copy ptr to var or constant{17278
{{jsr{6,cdwrd{{{generate as code word{17279
{{exi{{{{return to caller{17280
{{ejc{{{{{17281
*      cdgvl (continued)
*      here for tree node (cmblk)
{cgv01{mov{11,-(xs){8,wb{{save entry wb{17287
{{mov{11,-(xs){7,xl{{save entry xl{17288
{{mov{11,-(xs){8,wc{{save entry constant flag{17289
{{mov{11,-(xs){3,cwcof{{save initial code offset{17290
{{chk{{{{check for stack overflow{17291
*      prepare to generate code for cmblk. wc is set to the
*      value of cswno (zero if -optimise, 1 if -noopt) to
*      start with and is reset non-zero for any non-constant
*      code generated. if it is still zero after generating all
*      the cmblk code, then its value is computed as the result.
{{mov{7,xl{7,xr{{copy cmblk pointer{17299
{{mov{7,xr{13,cmtyp(xr){{load cmblk type{17300
{{mov{8,wc{3,cswno{{reset constant flag{17301
{{ble{7,xr{18,=c_pr_{6,cgv02{jump if not predicate value{17302
{{mnz{8,wc{{{else force non-constant case{17303
*      here with wc set appropriately
{cgv02{bsw{7,xr{2,c__nv{{switch to appropriate generator{17307
{{iff{2,c_arr{6,cgv03{{array reference{17327
{{iff{2,c_fnc{6,cgv05{{function call{17327
{{iff{2,c_def{6,cgv14{{deferred expression{17327
{{iff{2,c_ind{6,cgv31{{indirect reference{17327
{{iff{2,c_key{6,cgv27{{keyword reference{17327
{{iff{2,c_ubo{6,cgv29{{undefined binop{17327
{{iff{2,c_uuo{6,cgv30{{undefined unop{17327
{{iff{2,c_bvl{6,cgv18{{binops with val opds{17327
{{iff{2,c_uvl{6,cgv19{{unops with valu opnd{17327
{{iff{2,c_alt{6,cgv18{{alternation{17327
{{iff{2,c_cnc{6,cgv24{{concatenation{17327
{{iff{2,c_cnp{6,cgv24{{concatenation (not pattern match){17327
{{iff{2,c_unm{6,cgv27{{unops with name opnd{17327
{{iff{2,c_bvn{6,cgv26{{binary _ and .{17327
{{iff{2,c_ass{6,cgv21{{assignment{17327
{{iff{2,c_int{6,cgv31{{interrogation{17327
{{iff{2,c_neg{6,cgv28{{negation{17327
{{iff{2,c_sel{6,cgv15{{selection{17327
{{iff{2,c_pmt{6,cgv18{{pattern match{17327
{{esw{{{{end switch on cmblk type{17327
{{ejc{{{{{17328
*      cdgvl (continued)
*      here to generate code for array reference
{cgv03{mov{8,wb{19,*cmopn{{set offset to array operand{17334
*      loop to generate code for array operand and subscripts
{cgv04{jsr{6,cmgen{{{gen value code for next operand{17338
{{mov{8,wc{13,cmlen(xl){{load cmblk length{17339
{{blt{8,wb{8,wc{6,cgv04{loop back if more to go{17340
*      generate call to appropriate array reference routine
{{mov{8,wa{21,=oaov_{{set one subscript call in case{17344
{{beq{8,wc{19,*cmar1{6,cgv32{jump to exit if 1-sub case{17345
{{mov{8,wa{21,=oamv_{{else set call for multi-subscripts{17346
{{jsr{6,cdwrd{{{generate call{17347
{{mov{8,wa{8,wc{{copy length of cmblk{17348
{{sub{8,wa{19,*cmvls{{subtract standard length{17349
{{btw{8,wa{{{get number of words{17350
{{brn{6,cgv32{{{jump to generate subscript count{17351
*      here to generate code for function call
{cgv05{mov{8,wb{19,*cmvls{{set offset to first argument{17355
*      loop to generate code for arguments
{cgv06{beq{8,wb{13,cmlen(xl){6,cgv07{jump if all generated{17359
{{jsr{6,cmgen{{{else gen value code for next arg{17360
{{brn{6,cgv06{{{back to generate next argument{17361
*      here to generate actual function call
{cgv07{sub{8,wb{19,*cmvls{{get number of arg ptrs (bytes){17365
{{btw{8,wb{{{convert bytes to words{17366
{{mov{7,xr{13,cmopn(xl){{load function vrblk pointer{17367
{{bnz{13,vrlen(xr){6,cgv12{{jump if not system function{17368
{{mov{7,xl{13,vrsvp(xr){{load svblk ptr if system var{17369
{{mov{8,wa{13,svbit(xl){{load bit mask{17370
{{anb{8,wa{4,btffc{{test for fast function call allowed{17371
{{zrb{8,wa{6,cgv12{{jump if not{17372
{{ejc{{{{{17373
*      cdgvl (continued)
*      here if fast function call is allowed
{{mov{8,wa{13,svbit(xl){{reload bit indicators{17379
{{anb{8,wa{4,btpre{{test for preevaluation ok{17380
{{nzb{8,wa{6,cgv08{{jump if preevaluation permitted{17381
{{mnz{8,wc{{{else set result non-constant{17382
*      test for correct number of args for fast call
{cgv08{mov{7,xl{13,vrfnc(xr){{load ptr to svfnc field{17386
{{mov{8,wa{13,fargs(xl){{load svnar field value{17387
{{beq{8,wa{8,wb{6,cgv11{jump if argument count is correct{17388
{{bhi{8,wa{8,wb{6,cgv09{jump if too few arguments given{17389
*      here if too many arguments, prepare to generate o_pops
{{sub{8,wb{8,wa{{get number of extra args{17393
{{lct{8,wb{8,wb{{set as count to control loop{17394
{{mov{8,wa{21,=opop_{{set pop call{17395
{{brn{6,cgv10{{{jump to common loop{17396
*      here if too few arguments, prepare to generate nulls
{cgv09{sub{8,wa{8,wb{{get number of missing arguments{17400
{{lct{8,wb{8,wa{{load as count to control loop{17401
{{mov{8,wa{21,=nulls{{load ptr to null constant{17402
*      loop to generate calls to fix argument count
{cgv10{jsr{6,cdwrd{{{generate one call{17406
{{bct{8,wb{6,cgv10{{loop till all generated{17407
*      here after adjusting arg count as required
{cgv11{mov{8,wa{7,xl{{copy pointer to svfnc field{17411
{{brn{6,cgv36{{{jump to generate call{17412
{{ejc{{{{{17413
*      cdgvl (continued)
*      come here if fast call is not permitted
{cgv12{mov{8,wa{21,=ofns_{{set one arg call in case{17419
{{beq{8,wb{18,=num01{6,cgv13{jump if one arg case{17420
{{mov{8,wa{21,=ofnc_{{else load call for more than 1 arg{17421
{{jsr{6,cdwrd{{{generate it{17422
{{mov{8,wa{8,wb{{copy argument count{17423
*      one arg case merges here
{cgv13{jsr{6,cdwrd{{{generate =o_fns or arg count{17427
{{mov{8,wa{7,xr{{copy vrblk pointer{17428
{{brn{6,cgv32{{{jump to generate vrblk ptr{17429
*      here for deferred expression
{cgv14{mov{7,xl{13,cmrop(xl){{point to expression tree{17433
{{zer{8,wa{{{return value{17435
{{jsr{6,cdgex{{{build exblk or seblk{17437
{{mov{8,wa{7,xr{{copy block ptr{17438
{{jsr{6,cdwrd{{{generate ptr to exblk or seblk{17439
{{brn{6,cgv34{{{jump to exit, constant test{17440
*      here to generate code for selection
{cgv15{zer{11,-(xs){{{zero ptr to chain of forward jumps{17444
{{zer{11,-(xs){{{zero ptr to prev o_slc forward ptr{17445
{{mov{8,wb{19,*cmvls{{point to first alternative{17446
{{mov{8,wa{21,=osla_{{set initial code word{17447
*      0(xs)                 is the offset to the previous word
*                            which requires filling in with an
*                            offset to the following o_slc,o_sld
*      1(xs)                 is the head of a chain of offset
*                            pointers indicating those locations
*                            to be filled with offsets past
*                            the end of all the alternatives
{cgv16{jsr{6,cdwrd{{{generate o_slc (o_sla first time){17458
{{mov{9,(xs){3,cwcof{{set current loc as ptr to fill in{17459
{{jsr{6,cdwrd{{{generate garbage word there for now{17460
{{jsr{6,cmgen{{{gen value code for alternative{17461
{{mov{8,wa{21,=oslb_{{load o_slb pointer{17462
{{jsr{6,cdwrd{{{generate o_slb call{17463
{{mov{8,wa{13,num01(xs){{load old chain ptr{17464
{{mov{13,num01(xs){3,cwcof{{set current loc as new chain head{17465
{{jsr{6,cdwrd{{{generate forward chain link{17466
{{ejc{{{{{17467
*      cdgvl (continued)
*      now to fill in the skip offset to o_slc,o_sld
{{mov{7,xr{9,(xs){{load offset to word to plug{17473
{{add{7,xr{3,r_ccb{{point to actual location to plug{17474
{{mov{9,(xr){3,cwcof{{plug proper offset in{17475
{{mov{8,wa{21,=oslc_{{load o_slc ptr for next alternative{17476
{{mov{7,xr{8,wb{{copy offset (destroy garbage xr){17477
{{ica{7,xr{{{bump extra time for test{17478
{{blt{7,xr{13,cmlen(xl){6,cgv16{loop back if not last alternative{17479
*      here to generate code for last alternative
{{mov{8,wa{21,=osld_{{get header call{17483
{{jsr{6,cdwrd{{{generate o_sld call{17484
{{jsr{6,cmgen{{{generate code for last alternative{17485
{{ica{7,xs{{{pop offset ptr{17486
{{mov{7,xr{10,(xs)+{{load chain ptr{17487
*      loop to plug offsets past structure
{cgv17{add{7,xr{3,r_ccb{{make next ptr absolute{17491
{{mov{8,wa{9,(xr){{load forward ptr{17492
{{mov{9,(xr){3,cwcof{{plug required offset{17493
{{mov{7,xr{8,wa{{copy forward ptr{17494
{{bnz{8,wa{6,cgv17{{loop back if more to go{17495
{{brn{6,cgv33{{{else jump to exit (not constant){17496
*      here for binary ops with value operands
{cgv18{mov{7,xr{13,cmlop(xl){{load left operand pointer{17500
{{jsr{6,cdgvl{{{gen value code for left operand{17501
*      here for unary ops with value operand (binops merge)
{cgv19{mov{7,xr{13,cmrop(xl){{load right (only) operand ptr{17505
{{jsr{6,cdgvl{{{gen code by value{17506
{{ejc{{{{{17507
*      cdgvl (continued)
*      merge here to generate operator call from cmopn field
{cgv20{mov{8,wa{13,cmopn(xl){{load operator call pointer{17513
{{brn{6,cgv36{{{jump to generate it with cons test{17514
*      here for assignment
{cgv21{mov{7,xr{13,cmlop(xl){{load left operand pointer{17518
{{blo{9,(xr){22,=b_vr_{6,cgv22{jump if not variable{17519
*      here for assignment to simple variable
{{mov{7,xr{13,cmrop(xl){{load right operand ptr{17523
{{jsr{6,cdgvl{{{generate code by value{17524
{{mov{8,wa{13,cmlop(xl){{reload left operand vrblk ptr{17525
{{add{8,wa{19,*vrsto{{point to vrsto field{17526
{{brn{6,cgv32{{{jump to generate store ptr{17527
*      here if not simple variable assignment
{cgv22{jsr{6,expap{{{test for pattern match on left side{17531
{{ppm{6,cgv23{{{jump if not pattern match{17532
*      here for pattern replacement
{{mov{13,cmlop(xl){13,cmrop(xr){{save pattern ptr in safe place{17536
{{mov{7,xr{13,cmlop(xr){{load subject ptr{17537
{{jsr{6,cdgnm{{{gen code by name for subject{17538
{{mov{7,xr{13,cmlop(xl){{load pattern ptr{17539
{{jsr{6,cdgvl{{{gen code by value for pattern{17540
{{mov{8,wa{21,=opmn_{{load match by name call{17541
{{jsr{6,cdwrd{{{generate it{17542
{{mov{7,xr{13,cmrop(xl){{load replacement value ptr{17543
{{jsr{6,cdgvl{{{gen code by value{17544
{{mov{8,wa{21,=orpl_{{load replace call{17545
{{brn{6,cgv32{{{jump to gen and exit (not constant){17546
*      here for assignment to complex variable
{cgv23{mnz{8,wc{{{inhibit pre-evaluation{17550
{{jsr{6,cdgnm{{{gen code by name for left side{17551
{{brn{6,cgv31{{{merge with unop circuit{17552
{{ejc{{{{{17553
*      cdgvl (continued)
*      here for concatenation
{cgv24{mov{7,xr{13,cmlop(xl){{load left operand ptr{17559
{{bne{9,(xr){22,=b_cmt{6,cgv18{ordinary binop if not cmblk{17560
{{mov{8,wb{13,cmtyp(xr){{load cmblk type code{17561
{{beq{8,wb{18,=c_int{6,cgv25{special case if interrogation{17562
{{beq{8,wb{18,=c_neg{6,cgv25{or negation{17563
{{bne{8,wb{18,=c_fnc{6,cgv18{else ordinary binop if not function{17564
{{mov{7,xr{13,cmopn(xr){{else load function vrblk ptr{17565
{{bnz{13,vrlen(xr){6,cgv18{{ordinary binop if not system var{17566
{{mov{7,xr{13,vrsvp(xr){{else point to svblk{17567
{{mov{8,wa{13,svbit(xr){{load bit indicators{17568
{{anb{8,wa{4,btprd{{test for predicate function{17569
{{zrb{8,wa{6,cgv18{{ordinary binop if not{17570
*      here if left arg of concatenation is predicate function
{cgv25{mov{7,xr{13,cmlop(xl){{reload left arg{17574
{{jsr{6,cdgvl{{{gen code by value{17575
{{mov{8,wa{21,=opop_{{load pop call{17576
{{jsr{6,cdwrd{{{generate it{17577
{{mov{7,xr{13,cmrop(xl){{load right operand{17578
{{jsr{6,cdgvl{{{gen code by value as result code{17579
{{brn{6,cgv33{{{exit (not constant){17580
*      here to generate code for pattern, immediate assignment
{cgv26{mov{7,xr{13,cmlop(xl){{load left operand{17584
{{jsr{6,cdgvl{{{gen code by value, merge{17585
*      here for unops with arg by name (binary _ . merge)
{cgv27{mov{7,xr{13,cmrop(xl){{load right operand ptr{17589
{{jsr{6,cdgnm{{{gen code by name for right arg{17590
{{mov{7,xr{13,cmopn(xl){{get operator code word{17591
{{bne{9,(xr){22,=o_kwv{6,cgv20{gen call unless keyword value{17592
{{ejc{{{{{17593
*      cdgvl (continued)
*      here for keyword by value. this is constant only if
*      the operand is one of the special system variables with
*      the svckw bit set to indicate a constant keyword value.
*      note that the only constant operand by name is a variable
{{bnz{8,wc{6,cgv20{{gen call if non-constant (not var){17602
{{mnz{8,wc{{{else set non-constant in case{17603
{{mov{7,xr{13,cmrop(xl){{load ptr to operand vrblk{17604
{{bnz{13,vrlen(xr){6,cgv20{{gen (non-constant) if not sys var{17605
{{mov{7,xr{13,vrsvp(xr){{else load ptr to svblk{17606
{{mov{8,wa{13,svbit(xr){{load bit mask{17607
{{anb{8,wa{4,btckw{{test for constant keyword{17608
{{zrb{8,wa{6,cgv20{{go gen if not constant{17609
{{zer{8,wc{{{else set result constant{17610
{{brn{6,cgv20{{{and jump back to generate call{17611
*      here to generate code for negation
{cgv28{mov{8,wa{21,=onta_{{get initial word{17615
{{jsr{6,cdwrd{{{generate it{17616
{{mov{8,wb{3,cwcof{{save next offset{17617
{{jsr{6,cdwrd{{{generate gunk word for now{17618
{{mov{7,xr{13,cmrop(xl){{load right operand ptr{17619
{{jsr{6,cdgvl{{{gen code by value{17620
{{mov{8,wa{21,=ontb_{{load end of evaluation call{17621
{{jsr{6,cdwrd{{{generate it{17622
{{mov{7,xr{8,wb{{copy offset to word to plug{17623
{{add{7,xr{3,r_ccb{{point to actual word to plug{17624
{{mov{9,(xr){3,cwcof{{plug word with current offset{17625
{{mov{8,wa{21,=ontc_{{load final call{17626
{{brn{6,cgv32{{{jump to generate it (not constant){17627
*      here to generate code for undefined binary operator
{cgv29{mov{7,xr{13,cmlop(xl){{load left operand ptr{17631
{{jsr{6,cdgvl{{{generate code by value{17632
{{ejc{{{{{17633
*      cdgvl (continued)
*      here to generate code for undefined unary operator
{cgv30{mov{8,wb{18,=c_uo_{{set unop code + 1{17639
{{sub{8,wb{13,cmtyp(xl){{set number of args (1 or 2){17640
*      merge here for undefined operators
{{mov{7,xr{13,cmrop(xl){{load right (only) operand pointer{17644
{{jsr{6,cdgvl{{{gen value code for right operand{17645
{{mov{7,xr{13,cmopn(xl){{load pointer to operator dv{17646
{{mov{7,xr{13,dvopn(xr){{load pointer offset{17647
{{wtb{7,xr{{{convert word offset to bytes{17648
{{add{7,xr{20,=r_uba{{point to proper function ptr{17649
{{sub{7,xr{19,*vrfnc{{set standard function offset{17650
{{brn{6,cgv12{{{merge with function call circuit{17651
*      here to generate code for interrogation, indirection
{cgv31{mnz{8,wc{{{set non constant{17655
{{brn{6,cgv19{{{merge{17656
*      here to exit generating a word, result not constant
{cgv32{jsr{6,cdwrd{{{generate word, merge{17660
*      here to exit with no word generated, not constant
{cgv33{mnz{8,wc{{{indicate result is not constant{17664
*      common exit point
{cgv34{ica{7,xs{{{pop initial code offset{17668
{{mov{8,wa{10,(xs)+{{restore old constant flag{17669
{{mov{7,xl{10,(xs)+{{restore entry xl{17670
{{mov{8,wb{10,(xs)+{{restore entry wb{17671
{{bnz{8,wc{6,cgv35{{jump if not constant{17672
{{mov{8,wc{8,wa{{else restore entry constant flag{17673
*      here to return after dealing with wc setting
{cgv35{exi{{{{return to cdgvl caller{17677
*      exit here to generate word and test for constant
{cgv36{jsr{6,cdwrd{{{generate word{17681
{{bnz{8,wc{6,cgv34{{jump to exit if not constant{17682
{{ejc{{{{{17683
*      cdgvl (continued)
*      here to preevaluate constant sub-expression
{{mov{8,wa{21,=orvl_{{load call to return value{17689
{{jsr{6,cdwrd{{{generate it{17690
{{mov{7,xl{9,(xs){{load initial code offset{17691
{{jsr{6,exbld{{{build exblk for expression{17692
{{zer{8,wb{{{set to evaluate by value{17693
{{jsr{6,evalx{{{evaluate expression{17694
{{ppm{{{{should not fail{17695
{{mov{8,wa{9,(xr){{load type word of result{17696
{{blo{8,wa{22,=p_aaa{6,cgv37{jump if not pattern{17697
{{mov{8,wa{21,=olpt_{{else load special pattern load call{17698
{{jsr{6,cdwrd{{{generate it{17699
*      merge here to generate pointer to resulting constant
{cgv37{mov{8,wa{7,xr{{copy constant pointer{17703
{{jsr{6,cdwrd{{{generate ptr{17704
{{zer{8,wc{{{set result constant{17705
{{brn{6,cgv34{{{jump back to exit{17706
{{enp{{{{end procedure cdgvl{17707
{{ejc{{{{{17708
*      cdwrd -- generate one word of code
*      cdwrd writes one word into the current code block under
*      construction. a new, larger, block is allocated if there
*      is insufficient room in the current block. cdwrd ensures
*      that there are at least four words left in the block
*      after entering the new word. this guarantees that any
*      extra space at the end can be split off as a ccblk.
*      (wa)                  word to be generated
*      jsr  cdwrd            call to generate word
{cdwrd{prc{25,e{1,0{{entry point{17726
{{mov{11,-(xs){7,xr{{save entry xr{17727
{{mov{11,-(xs){8,wa{{save code word to be generated{17728
*      merge back here after allocating larger block
{cdwd1{mov{7,xr{3,r_ccb{{load ptr to ccblk being built{17732
{{bnz{7,xr{6,cdwd2{{jump if block allocated{17733
*      here we allocate an entirely fresh block
{{mov{8,wa{19,*e_cbs{{load initial length{17737
{{jsr{6,alloc{{{allocate ccblk{17738
{{mov{9,(xr){22,=b_cct{{store type word{17739
{{mov{3,cwcof{19,*cccod{{set initial offset{17740
{{mov{13,cclen(xr){8,wa{{store block length{17741
{{zer{13,ccsln(xr){{{zero line number{17743
{{mov{3,r_ccb{7,xr{{store ptr to new block{17745
*      here we have a block we can use
{cdwd2{mov{8,wa{3,cwcof{{load current offset{17749
{{add{8,wa{19,*num05{{adjust for test (five words){17751
{{blo{8,wa{13,cclen(xr){6,cdwd4{jump if room in this block{17755
*      here if no room in current block
{{bge{8,wa{3,mxlen{6,cdwd5{jump if already at max size{17759
{{add{8,wa{19,*e_cbs{{else get new size{17760
{{mov{11,-(xs){7,xl{{save entry xl{17761
{{mov{7,xl{7,xr{{copy pointer{17762
{{blt{8,wa{3,mxlen{6,cdwd3{jump if not too large{17763
{{mov{8,wa{3,mxlen{{else reset to max allowed size{17764
{{ejc{{{{{17765
*      cdwrd (continued)
*      here with new block size in wa
{cdwd3{jsr{6,alloc{{{allocate new block{17771
{{mov{3,r_ccb{7,xr{{store pointer to new block{17772
{{mov{10,(xr)+{22,=b_cct{{store type word in new block{17773
{{mov{10,(xr)+{8,wa{{store block length{17774
{{mov{10,(xr)+{13,ccsln(xl){{copy source line number word{17776
{{add{7,xl{19,*ccuse{{point to ccuse,cccod fields in old{17778
{{mov{8,wa{9,(xl){{load ccuse value{17779
{{mvw{{{{copy useful words from old block{17780
{{mov{7,xl{10,(xs)+{{restore xl{17781
{{brn{6,cdwd1{{{merge back to try again{17782
*      here with room in current block
{cdwd4{mov{8,wa{3,cwcof{{load current offset{17786
{{ica{8,wa{{{get new offset{17787
{{mov{3,cwcof{8,wa{{store new offset{17788
{{mov{13,ccuse(xr){8,wa{{store in ccblk for gbcol{17789
{{dca{8,wa{{{restore ptr to this word{17790
{{add{7,xr{8,wa{{point to current entry{17791
{{mov{8,wa{10,(xs)+{{reload word to generate{17792
{{mov{9,(xr){8,wa{{store word in block{17793
{{mov{7,xr{10,(xs)+{{restore entry xr{17794
{{exi{{{{return to caller{17795
*      here if compiled code is too long for cdblk
{cdwd5{erb{1,213{26,syntax error: statement is too complicated.{{{17799
{{enp{{{{end procedure cdwrd{17800
{{ejc{{{{{17801
*      cmgen -- generate code for cmblk ptr
*      cmgen is a subsidiary procedure used to generate value
*      code for a cmblk ptr from the main code generators.
*      (xl)                  cmblk pointer
*      (wb)                  offset to pointer in cmblk
*      jsr  cmgen            call to generate code
*      (xr,wa)               destroyed
*      (wb)                  bumped by one word
{cmgen{prc{25,r{1,0{{entry point, recursive{17814
{{mov{7,xr{7,xl{{copy cmblk pointer{17815
{{add{7,xr{8,wb{{point to cmblk pointer{17816
{{mov{7,xr{9,(xr){{load cmblk pointer{17817
{{jsr{6,cdgvl{{{generate code by value{17818
{{ica{8,wb{{{bump offset{17819
{{exi{{{{return to caller{17820
{{enp{{{{end procedure cmgen{17821
{{ejc{{{{{17822
*      cmpil (compile source code)
*      cmpil is used to convert snobol4 source code to internal
*      form (see cdblk format). it is used both for the initial
*      compile and at run time by the code and convert functions
*      this procedure has control for the entire duration of
*      initial compilation. an error in any procedure called
*      during compilation will lead first to the error section
*      and ultimately back here for resumed compilation. the
*      re-entry points after an error are specially labelled -
*      cmpce                 resume after control card error
*      cmple                 resume after label error
*      cmpse                 resume after statement error
*      jsr  cmpil            call to compile code
*      (xr)                  ptr to cdblk for entry statement
*      (xl,wa,wb,wc,ra)      destroyed
*      the following global variables are referenced
*      cmpln                 line number of first line of
*                            statement to be compiled
*      cmpsn                 number of next statement
*                            to be compiled.
*      cswxx                 control card switch values are
*                            changed when relevant control
*                            cards are met.
*      cwcof                 offset to next word in code block
*                            being built (see cdwrd).
*      lstsn                 number of statement most recently
*                            compiled (initially set to zero).
*      r_cim                 current (initial) compiler image
*                            (zero for initial compile call)
*      r_cni                 used to point to following image.
*                            (see readr procedure).
*      scngo                 goto switch for scane procedure
*      scnil                 length of current image excluding
*                            characters removed by -input.
*      scnpt                 current scan offset, see scane.
*      scnrs                 rescan switch for scane procedure.
*      scnse                 offset (in r_cim) of most recently
*                            scanned element. set zero if not
*                            currently scanning items
{{ejc{{{{{17879
*      cmpil (continued)
*      stage               stgic  initial compile in progress
*                          stgxc  code/convert compile
*                          stgev  building exblk for eval
*                          stgxt  execute time (outside compile)
*                          stgce  initial compile after end line
*                          stgxe  execute compile after end line
*      cmpil also uses a fixed number of locations on the
*      main stack as follows. (the definitions of the actual
*      offsets are in the definitions section).
*      cmstm(xs)             pointer to expan tree for body of
*                            statement (see expan procedure).
*      cmsgo(xs)             pointer to tree representation of
*                            success goto (see procedure scngo)
*                            zero if no success goto is given
*      cmfgo(xs)             like cmsgo for failure goto.
*      cmcgo(xs)             set non-zero only if there is a
*                            conditional goto. used for -fail,
*                            -nofail code generation.
*      cmpcd(xs)             pointer to cdblk for previous
*                            statement. zero for 1st statement.
*      cmffp(xs)             set non-zero if cdfal in previous
*                            cdblk needs filling with forward
*                            pointer, else set to zero.
*      cmffc(xs)             same as cmffp for current cdblk
*      cmsop(xs)             offset to word in previous cdblk
*                            to be filled in with forward ptr
*                            to next cdblk for success goto.
*                            zero if no fill in is required.
*      cmsoc(xs)             same as cmsop for current cdblk.
*      cmlbl(xs)             pointer to vrblk for label of
*                            current statement. zero if no label
*      cmtra(xs)             pointer to cdblk for entry stmnt.
{{ejc{{{{{17927
*      cmpil (continued)
*      entry point
{cmpil{prc{25,e{1,0{{entry point{17933
{{lct{8,wb{18,=cmnen{{set number of stack work locations{17934
*      loop to initialize stack working locations
{cmp00{zer{11,-(xs){{{store a zero, make one entry{17938
{{bct{8,wb{6,cmp00{{loop back until all set{17939
{{mov{3,cmpxs{7,xs{{save stack pointer for error sec{17940
{{sss{3,cmpss{{{save s-r stack pointer if any{17941
*      loop through statements
{cmp01{mov{8,wb{3,scnpt{{set scan pointer offset{17945
{{mov{3,scnse{8,wb{{set start of element location{17946
{{mov{8,wa{21,=ocer_{{point to compile error call{17947
{{jsr{6,cdwrd{{{generate as temporary cdfal{17948
{{blt{8,wb{3,scnil{6,cmp04{jump if chars left on this image{17949
*      loop here after comment or control card
*      also special entry after control card error
{cmpce{zer{7,xr{{{clear possible garbage xr value{17954
{{bnz{3,cnind{6,cmpc2{{if within include file{17956
{{bne{3,stage{18,=stgic{6,cmp02{skip unless initial compile{17958
{cmpc2{jsr{6,readr{{{read next input image{17959
{{bze{7,xr{6,cmp09{{jump if no input available{17960
{{jsr{6,nexts{{{acquire next source image{17961
{{mov{3,lstsn{3,cmpsn{{store stmt no for use by listr{17962
{{mov{3,cmpln{3,rdcln{{store line number at start of stmt{17963
{{zer{3,scnpt{{{reset scan pointer{17964
{{brn{6,cmp04{{{go process image{17965
*      for execute time compile, permit embedded control cards
*      and comments (by skipping to next semi-colon)
{cmp02{mov{7,xr{3,r_cim{{get current image{17970
{{mov{8,wb{3,scnpt{{get current offset{17971
{{plc{7,xr{8,wb{{prepare to get chars{17972
*      skip to semi-colon
{cmp03{bge{3,scnpt{3,scnil{6,cmp09{end loop if end of image{17976
{{lch{8,wc{10,(xr)+{{get char{17977
{{icv{3,scnpt{{{advance offset{17978
{{bne{8,wc{18,=ch_sm{6,cmp03{loop if not semi-colon{17979
{{ejc{{{{{17980
*      cmpil (continued)
*      here with image available to scan. note that if the input
*      string is null, then everything is ok since null is
*      actually assembled as a word of blanks.
{cmp04{mov{7,xr{3,r_cim{{point to current image{17988
{{mov{8,wb{3,scnpt{{load current offset{17989
{{mov{8,wa{8,wb{{copy for label scan{17990
{{plc{7,xr{8,wb{{point to first character{17991
{{lch{8,wc{10,(xr)+{{load first character{17992
{{beq{8,wc{18,=ch_sm{6,cmp12{no label if semicolon{17993
{{beq{8,wc{18,=ch_as{6,cmpce{loop back if comment card{17994
{{beq{8,wc{18,=ch_mn{6,cmp32{jump if control card{17995
{{mov{3,r_cmp{3,r_cim{{about to destroy r_cim{17996
{{mov{7,xl{20,=cmlab{{point to label work string{17997
{{mov{3,r_cim{7,xl{{scane is to scan work string{17998
{{psc{7,xl{{{point to first character position{17999
{{sch{8,wc{10,(xl)+{{store char just loaded{18000
{{mov{8,wc{18,=ch_sm{{get a semicolon{18001
{{sch{8,wc{9,(xl){{store after first char{18002
{{csc{7,xl{{{finished character storing{18003
{{zer{7,xl{{{clear pointer{18004
{{zer{3,scnpt{{{start at first character{18005
{{mov{11,-(xs){3,scnil{{preserve image length{18006
{{mov{3,scnil{18,=num02{{read 2 chars at most{18007
{{jsr{6,scane{{{scan first char for type{18008
{{mov{3,scnil{10,(xs)+{{restore image length{18009
{{mov{8,wc{7,xl{{note return code{18010
{{mov{7,xl{3,r_cmp{{get old r_cim{18011
{{mov{3,r_cim{7,xl{{put it back{18012
{{mov{3,scnpt{8,wb{{reinstate offset{18013
{{bnz{3,scnbl{6,cmp12{{blank seen - cant be label{18014
{{mov{7,xr{7,xl{{point to current image{18015
{{plc{7,xr{8,wb{{point to first char again{18016
{{beq{8,wc{18,=t_var{6,cmp06{ok if letter{18017
{{beq{8,wc{18,=t_con{6,cmp06{ok if digit{18018
*      drop in or jump from error section if scane failed
{cmple{mov{3,r_cim{3,r_cmp{{point to bad line{18022
{{erb{1,214{26,bad label or misplaced continuation line{{{18023
*      loop to scan label
{cmp05{beq{8,wc{18,=ch_sm{6,cmp07{skip if semicolon{18027
{{icv{8,wa{{{bump offset{18028
{{beq{8,wa{3,scnil{6,cmp07{jump if end of image (label end){18029
{{ejc{{{{{18030
*      cmpil (continued)
*      enter loop at this point
{cmp06{lch{8,wc{10,(xr)+{{else load next character{18036
{{beq{8,wc{18,=ch_ht{6,cmp07{jump if horizontal tab{18038
{{bne{8,wc{18,=ch_bl{6,cmp05{loop back if non-blank{18043
*      here after scanning out label
{cmp07{mov{3,scnpt{8,wa{{save updated scan offset{18047
{{sub{8,wa{8,wb{{get length of label{18048
{{bze{8,wa{6,cmp12{{skip if label length zero{18049
{{zer{7,xr{{{clear garbage xr value{18050
{{jsr{6,sbstr{{{build scblk for label name{18051
{{jsr{6,gtnvr{{{locate/contruct vrblk{18052
{{ppm{{{{dummy (impossible) error return{18053
{{mov{13,cmlbl(xs){7,xr{{store label pointer{18054
{{bnz{13,vrlen(xr){6,cmp11{{jump if not system label{18055
{{bne{13,vrsvp(xr){21,=v_end{6,cmp11{jump if not end label{18056
*      here for end label scanned out
{{add{3,stage{18,=stgnd{{adjust stage appropriately{18060
{{jsr{6,scane{{{scan out next element{18061
{{beq{7,xl{18,=t_smc{6,cmp10{jump if end of image{18062
{{bne{7,xl{18,=t_var{6,cmp08{else error if not variable{18063
*      here check for valid initial transfer
{{beq{13,vrlbl(xr){21,=stndl{6,cmp08{jump if not defined (error){18067
{{mov{13,cmtra(xs){13,vrlbl(xr){{else set initial entry pointer{18068
{{jsr{6,scane{{{scan next element{18069
{{beq{7,xl{18,=t_smc{6,cmp10{jump if ok (end of image){18070
*      here for bad transfer label
{cmp08{erb{1,215{26,syntax error: undefined or erroneous entry label{{{18074
*      here for end of input (no end label detected)
{cmp09{zer{7,xr{{{clear garbage xr value{18078
{{add{3,stage{18,=stgnd{{adjust stage appropriately{18079
{{beq{3,stage{18,=stgxe{6,cmp10{jump if code call (ok){18080
{{erb{1,216{26,syntax error: missing end line{{{18081
*      here after processing end line (merge here on end error)
{cmp10{mov{8,wa{21,=ostp_{{set stop call pointer{18085
{{jsr{6,cdwrd{{{generate as statement call{18086
{{brn{6,cmpse{{{jump to generate as failure{18087
{{ejc{{{{{18088
*      cmpil (continued)
*      here after processing label other than end
{cmp11{bne{3,stage{18,=stgic{6,cmp12{jump if code call - redef. ok{18094
{{beq{13,vrlbl(xr){21,=stndl{6,cmp12{else check for redefinition{18095
{{zer{13,cmlbl(xs){{{leave first label decln undisturbed{18096
{{erb{1,217{26,syntax error: duplicate label{{{18097
*      here after dealing with label
*      null statements and statements just containing a
*      constant subject are optimized out by resetting the
*      current ccblk to empty.
{cmp12{zer{8,wb{{{set flag for statement body{18104
{{jsr{6,expan{{{get tree for statement body{18105
{{mov{13,cmstm(xs){7,xr{{store for later use{18106
{{zer{13,cmsgo(xs){{{clear success goto pointer{18107
{{zer{13,cmfgo(xs){{{clear failure goto pointer{18108
{{zer{13,cmcgo(xs){{{clear conditional goto flag{18109
{{jsr{6,scane{{{scan next element{18110
{{beq{7,xl{18,=t_col{6,cmp13{jump if colon (goto){18111
{{bnz{3,cswno{6,cmp18{{jump if not optimizing{18112
{{bnz{13,cmlbl(xs){6,cmp18{{jump if label present{18113
{{mov{7,xr{13,cmstm(xs){{load tree ptr for statement body{18114
{{mov{8,wa{9,(xr){{load type word{18115
{{beq{8,wa{22,=b_cmt{6,cmp18{jump if cmblk{18116
{{bge{8,wa{22,=b_vra{6,cmp18{jump if not icblk, scblk, or rcblk{18117
{{mov{7,xl{3,r_ccb{{load ptr to ccblk{18118
{{mov{13,ccuse(xl){19,*cccod{{reset use offset in ccblk{18119
{{mov{3,cwcof{19,*cccod{{and in global{18120
{{icv{3,cmpsn{{{bump statement number{18121
{{brn{6,cmp01{{{generate no code for statement{18122
*      loop to process goto fields
{cmp13{mnz{3,scngo{{{set goto flag{18126
{{jsr{6,scane{{{scan next element{18127
{{beq{7,xl{18,=t_smc{6,cmp31{jump if no fields left{18128
{{beq{7,xl{18,=t_sgo{6,cmp14{jump if s for success goto{18129
{{beq{7,xl{18,=t_fgo{6,cmp16{jump if f for failure goto{18130
*      here for unconditional goto (i.e. not f or s)
{{mnz{3,scnrs{{{set to rescan element not f,s{18134
{{jsr{6,scngf{{{scan out goto field{18135
{{bnz{13,cmfgo(xs){6,cmp17{{error if fgoto already{18136
{{mov{13,cmfgo(xs){7,xr{{else set as fgoto{18137
{{brn{6,cmp15{{{merge with sgoto circuit{18138
*      here for success goto
{cmp14{jsr{6,scngf{{{scan success goto field{18142
{{mov{13,cmcgo(xs){18,=num01{{set conditional goto flag{18143
*      uncontional goto merges here
{cmp15{bnz{13,cmsgo(xs){6,cmp17{{error if sgoto already given{18147
{{mov{13,cmsgo(xs){7,xr{{else set sgoto{18148
{{brn{6,cmp13{{{loop back for next goto field{18149
*      here for failure goto
{cmp16{jsr{6,scngf{{{scan goto field{18153
{{mov{13,cmcgo(xs){18,=num01{{set conditonal goto flag{18154
{{bnz{13,cmfgo(xs){6,cmp17{{error if fgoto already given{18155
{{mov{13,cmfgo(xs){7,xr{{else store fgoto pointer{18156
{{brn{6,cmp13{{{loop back for next field{18157
{{ejc{{{{{18158
*      cmpil (continued)
*      here for duplicated goto field
{cmp17{erb{1,218{26,syntax error: duplicated goto field{{{18164
*      here to generate code
{cmp18{zer{3,scnse{{{stop positional error flags{18168
{{mov{7,xr{13,cmstm(xs){{load tree ptr for statement body{18169
{{zer{8,wb{{{collectable value for wb for cdgvl{18170
{{zer{8,wc{{{reset constant flag for cdgvl{18171
{{jsr{6,expap{{{test for pattern match{18172
{{ppm{6,cmp19{{{jump if not pattern match{18173
{{mov{13,cmopn(xr){21,=opms_{{else set pattern match pointer{18174
{{mov{13,cmtyp(xr){18,=c_pmt{{{18175
*      here after dealing with special pattern match case
{cmp19{jsr{6,cdgvl{{{generate code for body of statement{18179
{{mov{7,xr{13,cmsgo(xs){{load sgoto pointer{18180
{{mov{8,wa{7,xr{{copy it{18181
{{bze{7,xr{6,cmp21{{jump if no success goto{18182
{{zer{13,cmsoc(xs){{{clear success offset fillin ptr{18183
{{bhi{7,xr{3,state{6,cmp20{jump if complex goto{18184
*      here for simple success goto (label)
{{add{8,wa{19,*vrtra{{point to vrtra field as required{18188
{{jsr{6,cdwrd{{{generate success goto{18189
{{brn{6,cmp22{{{jump to deal with fgoto{18190
*      here for complex success goto
{cmp20{beq{7,xr{13,cmfgo(xs){6,cmp22{no code if same as fgoto{18194
{{zer{8,wb{{{else set ok value for cdgvl in wb{18195
{{jsr{6,cdgcg{{{generate code for success goto{18196
{{brn{6,cmp22{{{jump to deal with fgoto{18197
*      here for no success goto
{cmp21{mov{13,cmsoc(xs){3,cwcof{{set success fill in offset{18201
{{mov{8,wa{21,=ocer_{{point to compile error call{18202
{{jsr{6,cdwrd{{{generate as temporary value{18203
{{ejc{{{{{18204
*      cmpil (continued)
*      here to deal with failure goto
{cmp22{mov{7,xr{13,cmfgo(xs){{load failure goto pointer{18210
{{mov{8,wa{7,xr{{copy it{18211
{{zer{13,cmffc(xs){{{set no fill in required yet{18212
{{bze{7,xr{6,cmp23{{jump if no failure goto given{18213
{{add{8,wa{19,*vrtra{{point to vrtra field in case{18214
{{blo{7,xr{3,state{6,cmpse{jump to gen if simple fgoto{18215
*      here for complex failure goto
{{mov{8,wb{3,cwcof{{save offset to o_gof call{18219
{{mov{8,wa{21,=ogof_{{point to failure goto call{18220
{{jsr{6,cdwrd{{{generate{18221
{{mov{8,wa{21,=ofif_{{point to fail in fail word{18222
{{jsr{6,cdwrd{{{generate{18223
{{jsr{6,cdgcg{{{generate code for failure goto{18224
{{mov{8,wa{8,wb{{copy offset to o_gof for cdfal{18225
{{mov{8,wb{22,=b_cdc{{set complex case cdtyp{18226
{{brn{6,cmp25{{{jump to build cdblk{18227
*      here if no failure goto given
{cmp23{mov{8,wa{21,=ounf_{{load unexpected failure call in cas{18231
{{mov{8,wc{3,cswfl{{get -nofail flag{18232
{{orb{8,wc{13,cmcgo(xs){{check if conditional goto{18233
{{zrb{8,wc{6,cmpse{{jump if -nofail and no cond. goto{18234
{{mnz{13,cmffc(xs){{{else set fill in flag{18235
{{mov{8,wa{21,=ocer_{{and set compile error for temporary{18236
*      merge here with cdfal value in wa, simple cdblk
*      also special entry after statement error
{cmpse{mov{8,wb{22,=b_cds{{set cdtyp for simple case{18241
{{ejc{{{{{18242
*      cmpil (continued)
*      merge here to build cdblk
*      (wa)                  cdfal value to be generated
*      (wb)                  cdtyp value to be generated
*      at this stage, we chop off an appropriate chunk of the
*      current ccblk and convert it into a cdblk. the remainder
*      of the ccblk is reformatted to be the new ccblk.
{cmp25{mov{7,xr{3,r_ccb{{point to ccblk{18255
{{mov{7,xl{13,cmlbl(xs){{get possible label pointer{18256
{{bze{7,xl{6,cmp26{{skip if no label{18257
{{zer{13,cmlbl(xs){{{clear flag for next statement{18258
{{mov{13,vrlbl(xl){7,xr{{put cdblk ptr in vrblk label field{18259
*      merge after doing label
{cmp26{mov{9,(xr){8,wb{{set type word for new cdblk{18263
{{mov{13,cdfal(xr){8,wa{{set failure word{18264
{{mov{7,xl{7,xr{{copy pointer to ccblk{18265
{{mov{8,wb{13,ccuse(xr){{load length gen (= new cdlen){18266
{{mov{8,wc{13,cclen(xr){{load total ccblk length{18267
{{add{7,xl{8,wb{{point past cdblk{18268
{{sub{8,wc{8,wb{{get length left for chop off{18269
{{mov{9,(xl){22,=b_cct{{set type code for new ccblk at end{18270
{{mov{13,ccuse(xl){19,*cccod{{set initial code offset{18271
{{mov{3,cwcof{19,*cccod{{reinitialise cwcof{18272
{{mov{13,cclen(xl){8,wc{{set new length{18273
{{mov{3,r_ccb{7,xl{{set new ccblk pointer{18274
{{zer{13,ccsln(xl){{{initialize new line number{18276
{{mov{13,cdsln(xr){3,cmpln{{set line number in old block{18277
{{mov{13,cdstm(xr){3,cmpsn{{set statement number{18279
{{icv{3,cmpsn{{{bump statement number{18280
*      set pointers in previous code block as required
{{mov{7,xl{13,cmpcd(xs){{load ptr to previous cdblk{18284
{{bze{13,cmffp(xs){6,cmp27{{jump if no failure fill in required{18285
{{mov{13,cdfal(xl){7,xr{{else set failure ptr in previous{18286
*      here to deal with success forward pointer
{cmp27{mov{8,wa{13,cmsop(xs){{load success offset{18290
{{bze{8,wa{6,cmp28{{jump if no fill in required{18291
{{add{7,xl{8,wa{{else point to fill in location{18292
{{mov{9,(xl){7,xr{{store forward pointer{18293
{{zer{7,xl{{{clear garbage xl value{18294
{{ejc{{{{{18295
*      cmpil (continued)
*      now set fill in pointers for this statement
{cmp28{mov{13,cmffp(xs){13,cmffc(xs){{copy failure fill in flag{18301
{{mov{13,cmsop(xs){13,cmsoc(xs){{copy success fill in offset{18302
{{mov{13,cmpcd(xs){7,xr{{save ptr to this cdblk{18303
{{bnz{13,cmtra(xs){6,cmp29{{jump if initial entry already set{18304
{{mov{13,cmtra(xs){7,xr{{else set ptr here as default{18305
*      here after compiling one statement
{cmp29{blt{3,stage{18,=stgce{6,cmp01{jump if not end line just done{18309
{{bze{3,cswls{6,cmp30{{skip if -nolist{18310
{{jsr{6,listr{{{list last line{18311
*      return
{cmp30{mov{7,xr{13,cmtra(xs){{load initial entry cdblk pointer{18315
{{add{7,xs{19,*cmnen{{pop work locations off stack{18316
{{exi{{{{and return to cmpil caller{18317
*      here at end of goto field
{cmp31{mov{8,wb{13,cmfgo(xs){{get fail goto{18321
{{orb{8,wb{13,cmsgo(xs){{or in success goto{18322
{{bnz{8,wb{6,cmp18{{ok if non-null field{18323
{{erb{1,219{26,syntax error: empty goto field{{{18324
*      control card found
{cmp32{icv{8,wb{{{point past ch_mn{18328
{{jsr{6,cncrd{{{process control card{18329
{{zer{3,scnse{{{clear start of element loc.{18330
{{brn{6,cmpce{{{loop for next statement{18331
{{enp{{{{end procedure cmpil{18332
{{ejc{{{{{18333
*      cncrd -- control card processor
*      called to deal with control cards
*      r_cim                 points to current image
*      (wb)                  offset to 1st char of control card
*      jsr  cncrd            call to process control cards
*      (xl,xr,wa,wb,wc,ia)   destroyed
{cncrd{prc{25,e{1,0{{entry point{18344
{{mov{3,scnpt{8,wb{{offset for control card scan{18345
{{mov{8,wa{18,=ccnoc{{number of chars for comparison{18346
{{ctw{8,wa{1,0{{convert to word count{18347
{{mov{3,cnswc{8,wa{{save word count{18348
*      loop here if more than one control card
{cnc01{bge{3,scnpt{3,scnil{6,cnc09{return if end of image{18352
{{mov{7,xr{3,r_cim{{point to image{18353
{{plc{7,xr{3,scnpt{{char ptr for first char{18354
{{lch{8,wa{10,(xr)+{{get first char{18355
{{beq{8,wa{18,=ch_li{6,cnc07{special case of -inxxx{18359
{cnc0a{mnz{3,scncc{{{set flag for scane{18360
{{jsr{6,scane{{{scan card name{18361
{{zer{3,scncc{{{clear scane flag{18362
{{bnz{7,xl{6,cnc06{{fail unless control card name{18363
{{mov{8,wa{18,=ccnoc{{no. of chars to be compared{18364
{{blt{13,sclen(xr){8,wa{6,cnc08{fail if too few chars{18366
{{mov{7,xl{7,xr{{point to control card name{18370
{{zer{8,wb{{{zero offset for substring{18371
{{jsr{6,sbstr{{{extract substring for comparison{18372
{{mov{3,cnscc{7,xr{{keep control card substring ptr{18377
{{mov{7,xr{21,=ccnms{{point to list of standard names{18378
{{zer{8,wb{{{initialise name offset{18379
{{lct{8,wc{18,=cc_nc{{number of standard names{18380
*      try to match name
{cnc02{mov{7,xl{3,cnscc{{point to name{18384
{{lct{8,wa{3,cnswc{{counter for inner loop{18385
{{brn{6,cnc04{{{jump into loop{18386
*      inner loop to match card name chars
{cnc03{ica{7,xr{{{bump standard names ptr{18390
{{ica{7,xl{{{bump name pointer{18391
*      here to initiate the loop
{cnc04{cne{13,schar(xl){9,(xr){6,cnc05{comp. up to cfp_c chars at once{18395
{{bct{8,wa{6,cnc03{{loop if more words to compare{18396
{{ejc{{{{{18397
*      cncrd (continued)
*      matched - branch on card offset
{{mov{7,xl{8,wb{{get name offset{18403
{{bsw{7,xl{2,cc_nc{6,cnc08{switch{18405
{{iff{2,cc_do{6,cnc10{{-double{18444
{{iff{1,1{6,cnc08{{{18444
{{iff{2,cc_du{6,cnc11{{-dump{18444
{{iff{2,cc_cp{6,cnc41{{-copy{18444
{{iff{2,cc_ej{6,cnc12{{-eject{18444
{{iff{2,cc_er{6,cnc13{{-errors{18444
{{iff{2,cc_ex{6,cnc14{{-execute{18444
{{iff{2,cc_fa{6,cnc15{{-fail{18444
{{iff{2,cc_in{6,cnc41{{-include{18444
{{iff{2,cc_ln{6,cnc44{{-line{18444
{{iff{2,cc_li{6,cnc16{{-list{18444
{{iff{2,cc_nr{6,cnc17{{-noerrors{18444
{{iff{2,cc_nx{6,cnc18{{-noexecute{18444
{{iff{2,cc_nf{6,cnc19{{-nofail{18444
{{iff{2,cc_nl{6,cnc20{{-nolist{18444
{{iff{2,cc_no{6,cnc21{{-noopt{18444
{{iff{2,cc_np{6,cnc22{{-noprint{18444
{{iff{2,cc_op{6,cnc24{{-optimise{18444
{{iff{2,cc_pr{6,cnc25{{-print{18444
{{iff{2,cc_si{6,cnc27{{-single{18444
{{iff{2,cc_sp{6,cnc28{{-space{18444
{{iff{2,cc_st{6,cnc31{{-stitle{18444
{{iff{2,cc_ti{6,cnc32{{-title{18444
{{iff{2,cc_tr{6,cnc36{{-trace{18444
{{esw{{{{end switch{18444
*      not matched yet. align std names ptr and try again
{cnc05{ica{7,xr{{{bump standard names ptr{18448
{{bct{8,wa{6,cnc05{{loop{18449
{{icv{8,wb{{{bump names offset{18450
{{bct{8,wc{6,cnc02{{continue if more names{18451
{{brn{6,cnc08{{{ignore unrecognized control card{18453
*      invalid control card name
{cnc06{erb{1,247{26,invalid control statement{{{18458
*      special processing for -inxxx
{cnc07{lch{8,wa{10,(xr)+{{get next char{18462
{{bne{8,wa{18,=ch_ln{6,cnc0a{if not letter n{18466
{{lch{8,wa{9,(xr){{get third char{18467
{{blt{8,wa{18,=ch_d0{6,cnc0a{if not digit{18468
{{bgt{8,wa{18,=ch_d9{6,cnc0a{if not digit{18469
{{add{3,scnpt{18,=num02{{bump offset past -in{18470
{{jsr{6,scane{{{scan integer after -in{18471
{{mov{11,-(xs){7,xr{{stack scanned item{18472
{{jsr{6,gtsmi{{{check if integer{18473
{{ppm{6,cnc06{{{fail if not integer{18474
{{ppm{6,cnc06{{{fail if negative or large{18475
{{mov{3,cswin{7,xr{{keep integer{18476
{{ejc{{{{{18477
*      cncrd (continued)
*      check for more control cards before returning
{cnc08{mov{8,wa{3,scnpt{{preserve in case xeq time compile{18483
{{jsr{6,scane{{{look for comma{18484
{{beq{7,xl{18,=t_cma{6,cnc01{loop if comma found{18485
{{mov{3,scnpt{8,wa{{restore scnpt in case xeq time{18486
*      return point
{cnc09{exi{{{{return{18490
*      -double
{cnc10{mnz{3,cswdb{{{set switch{18494
{{brn{6,cnc08{{{merge{18495
*      -dump
*      this is used for system debugging . it has the effect of
*      producing a core dump at compilation time
{cnc11{jsr{6,sysdm{{{call dumper{18501
{{brn{6,cnc09{{{finished{18502
*      -eject
{cnc12{bze{3,cswls{6,cnc09{{return if -nolist{18506
{{jsr{6,prtps{{{eject{18507
{{jsr{6,listt{{{list title{18508
{{brn{6,cnc09{{{finished{18509
*      -errors
{cnc13{zer{3,cswer{{{clear switch{18513
{{brn{6,cnc08{{{merge{18514
*      -execute
{cnc14{zer{3,cswex{{{clear switch{18518
{{brn{6,cnc08{{{merge{18519
*      -fail
{cnc15{mnz{3,cswfl{{{set switch{18523
{{brn{6,cnc08{{{merge{18524
*      -list
{cnc16{mnz{3,cswls{{{set switch{18528
{{beq{3,stage{18,=stgic{6,cnc08{done if compile time{18529
*      list code line if execute time compile
{{zer{3,lstpf{{{permit listing{18533
{{jsr{6,listr{{{list line{18534
{{brn{6,cnc08{{{merge{18535
{{ejc{{{{{18536
*      cncrd (continued)
*      -noerrors
{cnc17{mnz{3,cswer{{{set switch{18542
{{brn{6,cnc08{{{merge{18543
*      -noexecute
{cnc18{mnz{3,cswex{{{set switch{18547
{{brn{6,cnc08{{{merge{18548
*      -nofail
{cnc19{zer{3,cswfl{{{clear switch{18552
{{brn{6,cnc08{{{merge{18553
*      -nolist
{cnc20{zer{3,cswls{{{clear switch{18557
{{brn{6,cnc08{{{merge{18558
*      -nooptimise
{cnc21{mnz{3,cswno{{{set switch{18562
{{brn{6,cnc08{{{merge{18563
*      -noprint
{cnc22{zer{3,cswpr{{{clear switch{18567
{{brn{6,cnc08{{{merge{18568
*      -optimise
{cnc24{zer{3,cswno{{{clear switch{18572
{{brn{6,cnc08{{{merge{18573
*      -print
{cnc25{mnz{3,cswpr{{{set switch{18577
{{brn{6,cnc08{{{merge{18578
{{ejc{{{{{18579
*      cncrd (continued)
*      -single
{cnc27{zer{3,cswdb{{{clear switch{18585
{{brn{6,cnc08{{{merge{18586
*      -space
{cnc28{bze{3,cswls{6,cnc09{{return if -nolist{18590
{{jsr{6,scane{{{scan integer after -space{18591
{{mov{8,wc{18,=num01{{1 space in case{18592
{{beq{7,xr{18,=t_smc{6,cnc29{jump if no integer{18593
{{mov{11,-(xs){7,xr{{stack it{18594
{{jsr{6,gtsmi{{{check integer{18595
{{ppm{6,cnc06{{{fail if not integer{18596
{{ppm{6,cnc06{{{fail if negative or large{18597
{{bnz{8,wc{6,cnc29{{jump if non zero{18598
{{mov{8,wc{18,=num01{{else 1 space{18599
*      merge with count of lines to skip
{cnc29{add{3,lstlc{8,wc{{bump line count{18603
{{lct{8,wc{8,wc{{convert to loop counter{18604
{{blt{3,lstlc{3,lstnp{6,cnc30{jump if fits on page{18605
{{jsr{6,prtps{{{eject{18606
{{jsr{6,listt{{{list title{18607
{{brn{6,cnc09{{{merge{18608
*      skip lines
{cnc30{jsr{6,prtnl{{{print a blank{18612
{{bct{8,wc{6,cnc30{{loop{18613
{{brn{6,cnc09{{{merge{18614
{{ejc{{{{{18615
*      cncrd (continued)
*      -stitl
{cnc31{mov{3,cnr_t{20,=r_stl{{ptr to r_stl{18621
{{brn{6,cnc33{{{merge{18622
*      -title
{cnc32{mov{3,r_stl{21,=nulls{{clear subtitle{18626
{{mov{3,cnr_t{20,=r_ttl{{ptr to r_ttl{18627
*      common processing for -title, -stitl
{cnc33{mov{7,xr{21,=nulls{{null in case needed{18631
{{mnz{3,cnttl{{{set flag for next listr call{18632
{{mov{8,wb{18,=ccofs{{offset to title/subtitle{18633
{{mov{8,wa{3,scnil{{input image length{18634
{{blo{8,wa{8,wb{6,cnc34{jump if no chars left{18635
{{sub{8,wa{8,wb{{no of chars to extract{18636
{{mov{7,xl{3,r_cim{{point to image{18637
{{jsr{6,sbstr{{{get title/subtitle{18638
*      store title/subtitle
{cnc34{mov{7,xl{3,cnr_t{{point to storage location{18642
{{mov{9,(xl){7,xr{{store title/subtitle{18643
{{beq{7,xl{20,=r_stl{6,cnc09{return if stitl{18644
{{bnz{3,precl{6,cnc09{{return if extended listing{18645
{{bze{3,prich{6,cnc09{{return if regular printer{18646
{{mov{7,xl{13,sclen(xr){{get length of title{18647
{{mov{8,wa{7,xl{{copy it{18648
{{bze{7,xl{6,cnc35{{jump if null{18649
{{add{7,xl{18,=num10{{increment{18650
{{bhi{7,xl{3,prlen{6,cnc09{use default lstp0 val if too long{18651
{{add{8,wa{18,=num04{{point just past title{18652
*      store offset to page nn message for short title
{cnc35{mov{3,lstpo{8,wa{{store offset{18656
{{brn{6,cnc09{{{return{18657
*      -trace
*      provided for system debugging.  toggles the system label
*      trace switch at compile time
{cnc36{jsr{6,systt{{{toggle switch{18663
{{brn{6,cnc08{{{merge{18664
*      -include
{cnc41{mnz{3,scncc{{{set flag for scane{18702
{{jsr{6,scane{{{scan quoted file name{18703
{{zer{3,scncc{{{clear scane flag{18704
{{bne{7,xl{18,=t_con{6,cnc06{if not constant{18705
{{bne{9,(xr){22,=b_scl{6,cnc06{if not string constant{18706
{{mov{3,r_ifn{7,xr{{save file name{18707
{{mov{7,xl{3,r_inc{{examine include file name table{18708
{{zer{8,wb{{{lookup by value{18709
{{jsr{6,tfind{{{do lookup{18710
{{ppm{{{{never fails{18711
{{beq{7,xr{21,=inton{6,cnc09{ignore if already in table{18712
{{mnz{8,wb{{{set for trim{18713
{{mov{7,xr{3,r_ifn{{file name{18714
{{jsr{6,trimr{{{remove trailing blanks{18715
{{mov{7,xl{3,r_inc{{include file name table{18716
{{mnz{8,wb{{{lookup by name this time{18717
{{jsr{6,tfind{{{do lookup{18718
{{ppm{{{{never fails{18719
{{mov{13,teval(xl){21,=inton{{make table value integer 1{18720
{{icv{3,cnind{{{increase nesting level{18721
{{mov{8,wa{3,cnind{{load new nest level{18722
{{bgt{8,wa{18,=ccinm{6,cnc42{fail if excessive nesting{18723
*      record the name and line number of the current input file
{{mov{7,xl{3,r_ifa{{array of nested file names{18728
{{add{8,wa{18,=vcvlb{{compute offset in words{18729
{{wtb{8,wa{{{convert to bytes{18730
{{add{7,xl{8,wa{{point to element{18731
{{mov{9,(xl){3,r_sfc{{record current file name{18732
{{mov{7,xl{8,wa{{preserve nesting byte offset{18733
{{mti{3,rdnln{{{fetch source line number as integer{18734
{{jsr{6,icbld{{{convert to icblk{18735
{{add{7,xl{3,r_ifl{{entry in nested line number array{18736
{{mov{9,(xl){7,xr{{record in array{18737
*      here to switch to include file named in r_ifn
{{mov{8,wa{3,cswin{{max read length{18742
{{mov{7,xl{3,r_ifn{{include file name{18743
{{jsr{6,alocs{{{get buffer for complete file name{18744
{{jsr{6,sysif{{{open include file{18745
{{ppm{6,cnc43{{{could not open{18746
*      make note of the complete file name for error messages
{{zer{8,wb{{{do not trim trailing blanks{18751
{{jsr{6,trimr{{{adjust scblk for actual length{18752
{{mov{3,r_sfc{7,xr{{save ptr to file name{18753
{{mti{3,cmpsn{{{current statement as integer{18754
{{jsr{6,icbld{{{build icblk for stmt number{18755
{{mov{7,xl{3,r_sfn{{file name table{18756
{{mnz{8,wb{{{lookup statement number by name{18757
{{jsr{6,tfind{{{allocate new teblk{18758
{{ppm{{{{always possible to allocate block{18759
{{mov{13,teval(xl){3,r_sfc{{record file name as entry value{18760
{{zer{3,rdnln{{{restart line counter for new file{18764
{{beq{3,stage{18,=stgic{6,cnc09{if initial compile{18765
{{bne{3,cnind{18,=num01{6,cnc09{if not first execute-time nesting{18766
*      here for -include during execute-time compile
{{mov{3,r_ici{3,r_cim{{remember code argument string{18770
{{mov{3,cnspt{3,scnpt{{save position in string{18771
{{mov{3,cnsil{3,scnil{{and length of string{18772
{{brn{6,cnc09{{{all done, merge{18773
*      here for excessive include file nesting
{cnc42{erb{1,284{26,excessively nested include files{{{18777
*      here if include file could not be opened
{cnc43{mov{3,dnamp{7,xr{{release allocated scblk{18781
{{erb{1,285{26,include file cannot be opened{{{18782
*      -line n filename
{cnc44{jsr{6,scane{{{scan integer after -line{18789
{{bne{7,xl{18,=t_con{6,cnc06{jump if no line number{18790
{{bne{9,(xr){22,=b_icl{6,cnc06{jump if not integer{18791
{{ldi{13,icval(xr){{{fetch integer line number{18792
{{ile{6,cnc06{{{error if negative or zero{18793
{{beq{3,stage{18,=stgic{6,cnc45{skip if initial compile{18794
{{mfi{3,cmpln{{{set directly for other compiles{18795
{{brn{6,cnc46{{{no need to set rdnln{18796
{cnc45{sbi{4,intv1{{{adjust number by one{18797
{{mfi{3,rdnln{{{save line number{18798
{cnc46{mnz{3,scncc{{{set flag for scane{18800
{{jsr{6,scane{{{scan quoted file name{18801
{{zer{3,scncc{{{clear scane flag{18802
{{beq{7,xl{18,=t_smc{6,cnc47{done if no file name{18803
{{bne{7,xl{18,=t_con{6,cnc06{error if not constant{18804
{{bne{9,(xr){22,=b_scl{6,cnc06{if not string constant{18805
{{jsr{6,newfn{{{record new file name{18806
{{brn{6,cnc09{{{merge{18807
*      here if file name not present
{cnc47{dcv{3,scnpt{{{set to rescan the terminator{18811
{{brn{6,cnc09{{{merge{18812
{{enp{{{{end procedure cncrd{18817
{{ejc{{{{{18818
*      dffnc -- define function
*      dffnc is called whenever a new function is assigned to
*      a variable. it deals with external function use counts.
*      (xr)                  pointer to vrblk
*      (xl)                  pointer to new function block
*      jsr  dffnc            call to define function
*      (wa,wb)               destroyed
{dffnc{prc{25,e{1,0{{entry point{18900
{{bne{9,(xl){22,=b_efc{6,dffn1{skip if new function not external{18903
{{icv{13,efuse(xl){{{else increment its use count{18904
*      here after dealing with new function use count
{dffn1{mov{8,wa{7,xr{{save vrblk pointer{18908
{{mov{7,xr{13,vrfnc(xr){{load old function pointer{18909
{{bne{9,(xr){22,=b_efc{6,dffn2{jump if old function not external{18910
{{mov{8,wb{13,efuse(xr){{else get use count{18911
{{dcv{8,wb{{{decrement{18912
{{mov{13,efuse(xr){8,wb{{store decremented value{18913
{{bnz{8,wb{6,dffn2{{jump if use count still non-zero{18914
{{jsr{6,sysul{{{else call system unload function{18915
*      here after dealing with old function use count
{dffn2{mov{7,xr{8,wa{{restore vrblk pointer{18919
{{mov{8,wa{7,xl{{copy function block ptr{18921
{{blt{7,xr{20,=r_yyy{6,dffn3{skip checks if opsyn op definition{18922
{{bnz{13,vrlen(xr){6,dffn3{{jump if not system variable{18923
*      for system variable, check for illegal redefinition
{{mov{7,xl{13,vrsvp(xr){{point to svblk{18927
{{mov{8,wb{13,svbit(xl){{load bit indicators{18928
{{anb{8,wb{4,btfnc{{is it a system function{18929
{{zrb{8,wb{6,dffn3{{redef ok if not{18930
{{erb{1,248{26,attempted redefinition of system function{{{18931
*      here if redefinition is permitted
{dffn3{mov{13,vrfnc(xr){8,wa{{store new function pointer{18935
{{mov{7,xl{8,wa{{restore function block pointer{18936
{{exi{{{{return to dffnc caller{18937
{{enp{{{{end procedure dffnc{18938
{{ejc{{{{{18939
*      dtach -- detach i/o associated names
*      detaches trblks from i/o associated variables, removes
*      entry from iochn chain attached to filearg1 vrblk and may
*      remove vrblk access and store traps.
*      input, output, terminal are handled specially.
*      (xl)                  i/o assoc. vbl name base ptr
*      (wa)                  offset to name
*      jsr  dtach            call for detach operation
*      (xl,xr,wa,wb,wc)      destroyed
{dtach{prc{25,e{1,0{{entry point{18953
{{mov{3,dtcnb{7,xl{{store name base (gbcol not called){18954
{{add{7,xl{8,wa{{point to name location{18955
{{mov{3,dtcnm{7,xl{{store it{18956
*      loop to search for i/o trblk
{dtch1{mov{7,xr{7,xl{{copy name pointer{18960
*      continue after block deletion
{dtch2{mov{7,xl{9,(xl){{point to next value{18964
{{bne{9,(xl){22,=b_trt{6,dtch6{jump at chain end{18965
{{mov{8,wa{13,trtyp(xl){{get trap block type{18966
{{beq{8,wa{18,=trtin{6,dtch3{jump if input{18967
{{beq{8,wa{18,=trtou{6,dtch3{jump if output{18968
{{add{7,xl{19,*trnxt{{point to next link{18969
{{brn{6,dtch1{{{loop{18970
*      delete an old association
{dtch3{mov{9,(xr){13,trval(xl){{delete trblk{18974
{{mov{8,wa{7,xl{{dump xl ...{18975
{{mov{8,wb{7,xr{{... and xr{18976
{{mov{7,xl{13,trtrf(xl){{point to trtrf trap block{18977
{{bze{7,xl{6,dtch5{{jump if no iochn{18978
{{bne{9,(xl){22,=b_trt{6,dtch5{jump if input, output, terminal{18979
*      loop to search iochn chain for name ptr
{dtch4{mov{7,xr{7,xl{{remember link ptr{18983
{{mov{7,xl{13,trtrf(xl){{point to next link{18984
{{bze{7,xl{6,dtch5{{jump if end of chain{18985
{{mov{8,wc{13,ionmb(xl){{get name base{18986
{{add{8,wc{13,ionmo(xl){{add offset{18987
{{bne{8,wc{3,dtcnm{6,dtch4{loop if no match{18988
{{mov{13,trtrf(xr){13,trtrf(xl){{remove name from chain{18989
{{ejc{{{{{18990
*      dtach (continued)
*      prepare to resume i/o trblk scan
{dtch5{mov{7,xl{8,wa{{recover xl ...{18996
{{mov{7,xr{8,wb{{... and xr{18997
{{add{7,xl{19,*trval{{point to value field{18998
{{brn{6,dtch2{{{continue{18999
*      exit point
{dtch6{mov{7,xr{3,dtcnb{{possible vrblk ptr{19003
{{jsr{6,setvr{{{reset vrblk if necessary{19004
{{exi{{{{return{19005
{{enp{{{{end procedure dtach{19006
{{ejc{{{{{19007
*      dtype -- get datatype name
*      (xr)                  object whose datatype is required
*      jsr  dtype            call to get datatype
*      (xr)                  result datatype
{dtype{prc{25,e{1,0{{entry point{19015
{{beq{9,(xr){22,=b_pdt{6,dtyp1{jump if prog.defined{19016
{{mov{7,xr{9,(xr){{load type word{19017
{{lei{7,xr{{{get entry point id (block code){19018
{{wtb{7,xr{{{convert to byte offset{19019
{{mov{7,xr{14,scnmt(xr){{load table entry{19020
{{exi{{{{exit to dtype caller{19021
*      here if program defined
{dtyp1{mov{7,xr{13,pddfp(xr){{point to dfblk{19025
{{mov{7,xr{13,dfnam(xr){{get datatype name from dfblk{19026
{{exi{{{{return to dtype caller{19027
{{enp{{{{end procedure dtype{19028
{{ejc{{{{{19029
*      dumpr -- print dump of storage
*      (xr)                  dump argument (see below)
*      jsr  dumpr            call to print dump
*      (xr,xl)               destroyed
*      (wa,wb,wc,ra)         destroyed
*      the dump argument has the following significance
*      dmarg = 0             no dump printed
*      dmarg = 1             partial dump (nat vars, keywords)
*      dmarg = 2             full dump (arrays, tables, etc.)
*      dmarg = 3             full dump + null variables
*      dmarg ge 4            core dump
*      since dumpr scrambles store, it is not permissible to
*      collect in mid-dump. hence a collect is done initially
*      and then if store runs out an error message is produced.
{dumpr{prc{25,e{1,0{{entry point{19050
{{bze{7,xr{6,dmp28{{skip dump if argument is zero{19051
{{bgt{7,xr{18,=num03{6,dmp29{jump if core dump required{19052
{{zer{7,xl{{{clear xl{19053
{{zer{8,wb{{{zero move offset{19054
{{mov{3,dmarg{7,xr{{save dump argument{19055
{{zer{3,dnams{{{collect sediment too{19057
{{jsr{6,gbcol{{{collect garbage{19059
{{jsr{6,prtpg{{{eject printer{19060
{{mov{7,xr{21,=dmhdv{{point to heading for variables{19061
{{jsr{6,prtst{{{print it{19062
{{jsr{6,prtnl{{{terminate print line{19063
{{jsr{6,prtnl{{{and print a blank line{19064
*      first all natural variable blocks (vrblk) whose values
*      are non-null are linked in lexical order using dmvch as
*      the chain head and chaining through the vrget fields.
*      note that this scrambles store if the process is
*      interrupted before completion e.g. by exceeding time  or
*      print limits. since the subsequent core dumps and
*      failures if execution is resumed are very confusing, the
*      execution time error routine checks for this event and
*      attempts an unscramble. similar precautions should be
*      observed if translate time dumping is implemented.
{{zer{3,dmvch{{{set null chain to start{19077
{{mov{8,wa{3,hshtb{{point to hash table{19078
*      loop through headers in hash table
{dmp00{mov{7,xr{8,wa{{copy hash bucket pointer{19082
{{ica{8,wa{{{bump pointer{19083
{{sub{7,xr{19,*vrnxt{{set offset to merge{19084
*      loop through vrblks on one chain
{dmp01{mov{7,xr{13,vrnxt(xr){{point to next vrblk on chain{19088
{{bze{7,xr{6,dmp09{{jump if end of this hash chain{19089
{{mov{7,xl{7,xr{{else copy vrblk pointer{19090
{{ejc{{{{{19091
*      dumpr (continued)
*      loop to find value and skip if null
{dmp02{mov{7,xl{13,vrval(xl){{load value{19097
{{beq{3,dmarg{18,=num03{6,dmp2a{skip null value check if dump(3){19098
{{beq{7,xl{21,=nulls{6,dmp01{loop for next vrblk if null value{19099
{dmp2a{beq{9,(xl){22,=b_trt{6,dmp02{loop back if value is trapped{19100
*      non-null value, prepare to search chain
{{mov{8,wc{7,xr{{save vrblk pointer{19104
{{add{7,xr{19,*vrsof{{adjust ptr to be like scblk ptr{19105
{{bnz{13,sclen(xr){6,dmp03{{jump if non-system variable{19106
{{mov{7,xr{13,vrsvo(xr){{else load ptr to name in svblk{19107
*      here with name pointer for new block in xr
{dmp03{mov{8,wb{7,xr{{save pointer to chars{19111
{{mov{3,dmpsv{8,wa{{save hash bucket pointer{19112
{{mov{8,wa{20,=dmvch{{point to chain head{19113
*      loop to search chain for correct insertion point
{dmp04{mov{3,dmpch{8,wa{{save chain pointer{19117
{{mov{7,xl{8,wa{{copy it{19118
{{mov{7,xr{9,(xl){{load pointer to next entry{19119
{{bze{7,xr{6,dmp08{{jump if end of chain to insert{19120
{{add{7,xr{19,*vrsof{{else get name ptr for chained vrblk{19121
{{bnz{13,sclen(xr){6,dmp05{{jump if not system variable{19122
{{mov{7,xr{13,vrsvo(xr){{else point to name in svblk{19123
*      here prepare to compare the names
*      (wa)                  scratch
*      (wb)                  pointer to string of entering vrblk
*      (wc)                  pointer to entering vrblk
*      (xr)                  pointer to string of current block
*      (xl)                  scratch
{dmp05{mov{7,xl{8,wb{{point to entering vrblk string{19133
{{mov{8,wa{13,sclen(xl){{load its length{19134
{{plc{7,xl{{{point to chars of entering string{19135
{{bhi{8,wa{13,sclen(xr){6,dmp06{jump if entering length high{19158
{{plc{7,xr{{{else point to chars of old string{19159
{{cmc{6,dmp08{6,dmp07{{compare, insert if new is llt old{19160
{{brn{6,dmp08{{{or if leq (we had shorter length){19161
*      here when new length is longer than old length
{dmp06{mov{8,wa{13,sclen(xr){{load shorter length{19165
{{plc{7,xr{{{point to chars of old string{19166
{{cmc{6,dmp08{6,dmp07{{compare, insert if new one low{19167
{{ejc{{{{{19168
*      dumpr (continued)
*      here we move out on the chain
{dmp07{mov{7,xl{3,dmpch{{copy chain pointer{19174
{{mov{8,wa{9,(xl){{move to next entry on chain{19176
{{brn{6,dmp04{{{loop back{19177
*      here after locating the proper insertion point
{dmp08{mov{7,xl{3,dmpch{{copy chain pointer{19181
{{mov{8,wa{3,dmpsv{{restore hash bucket pointer{19182
{{mov{7,xr{8,wc{{restore vrblk pointer{19183
{{mov{13,vrget(xr){9,(xl){{link vrblk to rest of chain{19184
{{mov{9,(xl){7,xr{{link vrblk into current chain loc{19185
{{brn{6,dmp01{{{loop back for next vrblk{19186
*      here after processing all vrblks on one chain
{dmp09{bne{8,wa{3,hshte{6,dmp00{loop back if more buckets to go{19190
*      loop to generate dump of natural variable values
{dmp10{mov{7,xr{3,dmvch{{load pointer to next entry on chain{19194
{{bze{7,xr{6,dmp11{{jump if end of chain{19195
{{mov{3,dmvch{9,(xr){{else update chain ptr to next entry{19196
{{jsr{6,setvr{{{restore vrget field{19197
{{mov{7,xl{7,xr{{copy vrblk pointer (name base){19198
{{mov{8,wa{19,*vrval{{set offset for vrblk name{19199
{{jsr{6,prtnv{{{print name = value{19200
{{brn{6,dmp10{{{loop back till all printed{19201
*      prepare to print keywords
{dmp11{jsr{6,prtnl{{{print blank line{19205
{{jsr{6,prtnl{{{and another{19206
{{mov{7,xr{21,=dmhdk{{point to keyword heading{19207
{{jsr{6,prtst{{{print heading{19208
{{jsr{6,prtnl{{{end line{19209
{{jsr{6,prtnl{{{print one blank line{19210
{{mov{7,xl{21,=vdmkw{{point to list of keyword svblk ptrs{19211
{{ejc{{{{{19212
*      dumpr (continued)
*      loop to dump keyword values
{dmp12{mov{7,xr{10,(xl)+{{load next svblk ptr from table{19218
{{bze{7,xr{6,dmp13{{jump if end of list{19219
{{beq{7,xr{18,=num01{6,dmp12{&compare ignored if not implemented{19221
{{mov{8,wa{18,=ch_am{{load ampersand{19223
{{jsr{6,prtch{{{print ampersand{19224
{{jsr{6,prtst{{{print keyword name{19225
{{mov{8,wa{13,svlen(xr){{load name length from svblk{19226
{{ctb{8,wa{2,svchs{{get length of name{19227
{{add{7,xr{8,wa{{point to svknm field{19228
{{mov{3,dmpkn{9,(xr){{store in dummy kvblk{19229
{{mov{7,xr{21,=tmbeb{{point to blank-equal-blank{19230
{{jsr{6,prtst{{{print it{19231
{{mov{3,dmpsv{7,xl{{save table pointer{19232
{{mov{7,xl{20,=dmpkb{{point to dummy kvblk{19233
{{mov{9,(xl){22,=b_kvt{{build type word{19234
{{mov{13,kvvar(xl){21,=trbkv{{build ptr to dummy trace block{19235
{{mov{8,wa{19,*kvvar{{set zero offset{19236
{{jsr{6,acess{{{get keyword value{19237
{{ppm{{{{failure is impossible{19238
{{jsr{6,prtvl{{{print keyword value{19239
{{jsr{6,prtnl{{{terminate print line{19240
{{mov{7,xl{3,dmpsv{{restore table pointer{19241
{{brn{6,dmp12{{{loop back till all printed{19242
*      here after completing partial dump
{dmp13{beq{3,dmarg{18,=num01{6,dmp27{exit if partial dump complete{19246
{{mov{7,xr{3,dnamb{{else point to first dynamic block{19247
*      loop through blocks in dynamic storage
{dmp14{beq{7,xr{3,dnamp{6,dmp27{jump if end of used region{19251
{{mov{8,wa{9,(xr){{else load first word of block{19252
{{beq{8,wa{22,=b_vct{6,dmp16{jump if vector{19253
{{beq{8,wa{22,=b_art{6,dmp17{jump if array{19254
{{beq{8,wa{22,=b_pdt{6,dmp18{jump if program defined{19255
{{beq{8,wa{22,=b_tbt{6,dmp19{jump if table{19256
*      merge here to move to next block
{dmp15{jsr{6,blkln{{{get length of block{19264
{{add{7,xr{8,wa{{point past this block{19265
{{brn{6,dmp14{{{loop back for next block{19266
{{ejc{{{{{19267
*      dumpr (continued)
*      here for vector
{dmp16{mov{8,wb{19,*vcvls{{set offset to first value{19273
{{brn{6,dmp19{{{jump to merge{19274
*      here for array
{dmp17{mov{8,wb{13,arofs(xr){{set offset to arpro field{19278
{{ica{8,wb{{{bump to get offset to values{19279
{{brn{6,dmp19{{{jump to merge{19280
*      here for program defined
{dmp18{mov{8,wb{19,*pdfld{{point to values, merge{19284
*      here for table (others merge)
{dmp19{bze{13,idval(xr){6,dmp15{{ignore block if zero id value{19288
{{jsr{6,blkln{{{else get block length{19289
{{mov{7,xl{7,xr{{copy block pointer{19290
{{mov{3,dmpsv{8,wa{{save length{19291
{{mov{8,wa{8,wb{{copy offset to first value{19292
{{jsr{6,prtnl{{{print blank line{19293
{{mov{3,dmpsa{8,wa{{preserve offset{19294
{{jsr{6,prtvl{{{print block value (for title){19295
{{mov{8,wa{3,dmpsa{{recover offset{19296
{{jsr{6,prtnl{{{end print line{19297
{{beq{9,(xr){22,=b_tbt{6,dmp22{jump if table{19298
{{dca{8,wa{{{point before first word{19299
*      loop to print contents of array, vector, or program def
{dmp20{mov{7,xr{7,xl{{copy block pointer{19303
{{ica{8,wa{{{bump offset{19304
{{add{7,xr{8,wa{{point to next value{19305
{{beq{8,wa{3,dmpsv{6,dmp14{exit if end (xr past block){19306
{{sub{7,xr{19,*vrval{{subtract offset to merge into loop{19307
*      loop to find value and ignore nulls
{dmp21{mov{7,xr{13,vrval(xr){{load next value{19311
{{beq{3,dmarg{18,=num03{6,dmp2b{skip null value check if dump(3){19312
{{beq{7,xr{21,=nulls{6,dmp20{loop back if null value{19313
{dmp2b{beq{9,(xr){22,=b_trt{6,dmp21{loop back if trapped{19314
{{jsr{6,prtnv{{{else print name = value{19315
{{brn{6,dmp20{{{loop back for next field{19316
{{ejc{{{{{19317
*      dumpr (continued)
*      here to dump a table
{dmp22{mov{8,wc{19,*tbbuk{{set offset to first bucket{19323
{{mov{8,wa{19,*teval{{set name offset for all teblks{19324
*      loop through table buckets
{dmp23{mov{11,-(xs){7,xl{{save tbblk pointer{19328
{{add{7,xl{8,wc{{point to next bucket header{19329
{{ica{8,wc{{{bump bucket offset{19330
{{sub{7,xl{19,*tenxt{{subtract offset to merge into loop{19331
*      loop to process teblks on one chain
{dmp24{mov{7,xl{13,tenxt(xl){{point to next teblk{19335
{{beq{7,xl{9,(xs){6,dmp26{jump if end of chain{19336
{{mov{7,xr{7,xl{{else copy teblk pointer{19337
*      loop to find value and ignore if null
{dmp25{mov{7,xr{13,teval(xr){{load next value{19341
{{beq{7,xr{21,=nulls{6,dmp24{ignore if null value{19342
{{beq{9,(xr){22,=b_trt{6,dmp25{loop back if trapped{19343
{{mov{3,dmpsv{8,wc{{else save offset pointer{19344
{{jsr{6,prtnv{{{print name = value{19345
{{mov{8,wc{3,dmpsv{{reload offset{19346
{{brn{6,dmp24{{{loop back for next teblk{19347
*      here to move to next hash chain
{dmp26{mov{7,xl{10,(xs)+{{restore tbblk pointer{19351
{{bne{8,wc{13,tblen(xl){6,dmp23{loop back if more buckets to go{19352
{{mov{7,xr{7,xl{{else copy table pointer{19353
{{add{7,xr{8,wc{{point to following block{19354
{{brn{6,dmp14{{{loop back to process next block{19355
*      here after completing dump
{dmp27{jsr{6,prtpg{{{eject printer{19359
*      merge here if no dump given (dmarg=0)
{dmp28{exi{{{{return to dump caller{19363
*      call system core dump routine
{dmp29{jsr{6,sysdm{{{call it{19367
{{brn{6,dmp28{{{return{19368
{{enp{{{{end procedure dumpr{19404
{{ejc{{{{{19405
*      ermsg -- print error code and error message
*      kvert                 error code
*      jsr  ermsg            call to print message
*      (xr,xl,wa,wb,wc,ia)   destroyed
{ermsg{prc{25,e{1,0{{entry point{19413
{{mov{8,wa{3,kvert{{load error code{19414
{{mov{7,xr{21,=ermms{{point to error message /error/{19415
{{jsr{6,prtst{{{print it{19416
{{jsr{6,ertex{{{get error message text{19417
{{add{8,wa{18,=thsnd{{bump error code for print{19418
{{mti{8,wa{{{fail code in int acc{19419
{{mov{8,wb{3,profs{{save current buffer position{19420
{{jsr{6,prtin{{{print code (now have error1xxx){19421
{{mov{7,xl{3,prbuf{{point to print buffer{19422
{{psc{7,xl{8,wb{{point to the 1{19423
{{mov{8,wa{18,=ch_bl{{load a blank{19424
{{sch{8,wa{9,(xl){{store blank over 1 (error xxx){19425
{{csc{7,xl{{{complete store characters{19426
{{zer{7,xl{{{clear garbage pointer in xl{19427
{{mov{8,wa{7,xr{{keep error text{19428
{{mov{7,xr{21,=ermns{{point to / -- /{19429
{{jsr{6,prtst{{{print it{19430
{{mov{7,xr{8,wa{{get error text again{19431
{{jsr{6,prtst{{{print error message text{19432
{{jsr{6,prtis{{{print line{19433
{{jsr{6,prtis{{{print blank line{19434
{{exi{{{{return to ermsg caller{19435
{{enp{{{{end procedure ermsg{19436
{{ejc{{{{{19437
*      ertex -- get error message text
*      (wa)                  error code
*      jsr  ertex            call to get error text
*      (xr)                  ptr to error text in dynamic
*      (r_etx)               copy of ptr to error text
*      (xl,wc,ia)            destroyed
{ertex{prc{25,e{1,0{{entry point{19447
{{mov{3,ertwa{8,wa{{save wa{19448
{{mov{3,ertwb{8,wb{{save wb{19449
{{jsr{6,sysem{{{get failure message text{19450
{{mov{7,xl{7,xr{{copy pointer to it{19451
{{mov{8,wa{13,sclen(xr){{get length of string{19452
{{bze{8,wa{6,ert02{{jump if null{19453
{{zer{8,wb{{{offset of zero{19454
{{jsr{6,sbstr{{{copy into dynamic store{19455
{{mov{3,r_etx{7,xr{{store for relocation{19456
*      return
{ert01{mov{8,wb{3,ertwb{{restore wb{19460
{{mov{8,wa{3,ertwa{{restore wa{19461
{{exi{{{{return to caller{19462
*      return errtext contents instead of null
{ert02{mov{7,xr{3,r_etx{{get errtext{19466
{{brn{6,ert01{{{return{19467
{{enp{{{{{19468
{{ejc{{{{{19469
*      evali -- evaluate integer argument
*      evali is used by pattern primitives len,tab,rtab,pos,rpos
*      when their argument is an expression value.
*      (xr)                  node pointer
*      (wb)                  cursor
*      jsr  evali            call to evaluate integer
*      ppm  loc              transfer loc for non-integer arg
*      ppm  loc              transfer loc for out of range arg
*      ppm  loc              transfer loc for evaluation failure
*      ppm  loc              transfer loc for successful eval
*      (the normal return is never taken)
*      (xr)                  ptr to node with integer argument
*      (wc,xl,ra)            destroyed
*      on return, the node pointed to has the integer argument
*      in parm1 and the proper successor pointer in pthen.
*      this allows merging with the normal (integer arg) case.
{evali{prc{25,r{1,4{{entry point (recursive){19491
{{jsr{6,evalp{{{evaluate expression{19492
{{ppm{6,evli1{{{jump on failure{19493
{{mov{11,-(xs){7,xl{{stack result for gtsmi{19494
{{mov{7,xl{13,pthen(xr){{load successor pointer{19495
{{mov{3,evlio{7,xr{{save original node pointer{19496
{{mov{3,evlif{8,wc{{zero if simple argument{19497
{{jsr{6,gtsmi{{{convert arg to small integer{19498
{{ppm{6,evli2{{{jump if not integer{19499
{{ppm{6,evli3{{{jump if out of range{19500
{{mov{3,evliv{7,xr{{store result in special dummy node{19501
{{mov{7,xr{20,=evlin{{point to dummy node with result{19502
{{mov{9,(xr){22,=p_len{{dummy pattern block pcode{19503
{{mov{13,pthen(xr){7,xl{{store successor pointer{19504
{{exi{1,4{{{take successful exit{19505
*      here if evaluation fails
{evli1{exi{1,3{{{take failure return{19509
*      here if argument is not integer
{evli2{exi{1,1{{{take non-integer error exit{19513
*      here if argument is out of range
{evli3{exi{1,2{{{take out-of-range error exit{19517
{{enp{{{{end procedure evali{19518
{{ejc{{{{{19519
*      evalp -- evaluate expression during pattern match
*      evalp is used to evaluate an expression (by value) during
*      a pattern match. the effect is like evalx, but pattern
*      variables are stacked and restored if necessary.
*      evalp also differs from evalx in that if the result is
*      an expression it is reevaluated. this occurs repeatedly.
*      to support optimization of pos and rpos, evalp uses wc
*      to signal the caller for the case of a simple vrblk
*      that is not an expression and is not trapped.  because
*      this case cannot have any side effects, optimization is
*      possible.
*      (xr)                  node pointer
*      (wb)                  pattern match cursor
*      jsr  evalp            call to evaluate expression
*      ppm  loc              transfer loc if evaluation fails
*      (xl)                  result
*      (wa)                  first word of result block
*      (wc)                  zero if simple vrblk, else non-zero
*      (xr,wb)               destroyed (failure case only)
*      (ra)                  destroyed
*      the expression pointer is stored in parm1 of the node
*      control returns to failp on failure of evaluation
{evalp{prc{25,r{1,1{{entry point (recursive){19550
{{mov{7,xl{13,parm1(xr){{load expression pointer{19551
{{beq{9,(xl){22,=b_exl{6,evlp1{jump if exblk case{19552
*      here for case of seblk
*      we can give a fast return if the value of the vrblk is
*      not an expression and is not trapped.
{{mov{7,xl{13,sevar(xl){{load vrblk pointer{19559
{{mov{7,xl{13,vrval(xl){{load value of vrblk{19560
{{mov{8,wa{9,(xl){{load first word of value{19561
{{bhi{8,wa{22,=b_t__{6,evlp3{jump if not seblk, trblk or exblk{19562
*      here for exblk or seblk with expr value or trapped value
{evlp1{chk{{{{check for stack space{19566
{{mov{11,-(xs){7,xr{{stack node pointer{19567
{{mov{11,-(xs){8,wb{{stack cursor{19568
{{mov{11,-(xs){3,r_pms{{stack subject string pointer{19569
{{mov{11,-(xs){3,pmssl{{stack subject string length{19570
{{mov{11,-(xs){3,pmdfl{{stack dot flag{19571
{{mov{11,-(xs){3,pmhbs{{stack history stack base pointer{19572
{{mov{7,xr{13,parm1(xr){{load expression pointer{19573
{{ejc{{{{{19574
*      evalp (continued)
*      loop back here to reevaluate expression result
{evlp2{zer{8,wb{{{set flag for by value{19580
{{jsr{6,evalx{{{evaluate expression{19581
{{ppm{6,evlp4{{{jump on failure{19582
{{mov{8,wa{9,(xr){{else load first word of value{19583
{{blo{8,wa{22,=b_e__{6,evlp2{loop back to reevaluate expression{19584
*      here to restore pattern values after successful eval
{{mov{7,xl{7,xr{{copy result pointer{19588
{{mov{3,pmhbs{10,(xs)+{{restore history stack base pointer{19589
{{mov{3,pmdfl{10,(xs)+{{restore dot flag{19590
{{mov{3,pmssl{10,(xs)+{{restore subject string length{19591
{{mov{3,r_pms{10,(xs)+{{restore subject string pointer{19592
{{mov{8,wb{10,(xs)+{{restore cursor{19593
{{mov{7,xr{10,(xs)+{{restore node pointer{19594
{{mov{8,wc{7,xr{{non-zero for simple vrblk{19595
{{exi{{{{return to evalp caller{19596
*      here to return after simple vrblk case
{evlp3{zer{8,wc{{{simple vrblk, no side effects{19600
{{exi{{{{return to evalp caller{19601
*      here for failure during evaluation
{evlp4{mov{3,pmhbs{10,(xs)+{{restore history stack base pointer{19605
{{mov{3,pmdfl{10,(xs)+{{restore dot flag{19606
{{mov{3,pmssl{10,(xs)+{{restore subject string length{19607
{{mov{3,r_pms{10,(xs)+{{restore subject string pointer{19608
{{add{7,xs{19,*num02{{remove node ptr, cursor{19609
{{exi{1,1{{{take failure exit{19610
{{enp{{{{end procedure evalp{19611
{{ejc{{{{{19612
*      evals -- evaluate string argument
*      evals is used by span, any, notany, break, breakx when
*      they are passed an expression argument.
*      (xr)                  node pointer
*      (wb)                  cursor
*      jsr  evals            call to evaluate string
*      ppm  loc              transfer loc for non-string arg
*      ppm  loc              transfer loc for evaluation failure
*      ppm  loc              transfer loc for successful eval
*      (the normal return is never taken)
*      (xr)                  ptr to node with parms set
*      (xl,wc,ra)            destroyed
*      on return, the node pointed to has a character table
*      pointer in parm1 and a bit mask in parm2. the proper
*      successor is stored in pthen of this node. thus it is
*      ok for merging with the normal (multi-char string) case.
{evals{prc{25,r{1,3{{entry point (recursive){19634
{{jsr{6,evalp{{{evaluate expression{19635
{{ppm{6,evls1{{{jump if evaluation fails{19636
{{mov{11,-(xs){13,pthen(xr){{save successor pointer{19637
{{mov{11,-(xs){8,wb{{save cursor{19638
{{mov{11,-(xs){7,xl{{stack result ptr for patst{19639
{{zer{8,wb{{{dummy pcode for one char string{19640
{{zer{8,wc{{{dummy pcode for expression arg{19641
{{mov{7,xl{22,=p_brk{{appropriate pcode for our use{19642
{{jsr{6,patst{{{call routine to build node{19643
{{ppm{6,evls2{{{jump if not string{19644
{{mov{8,wb{10,(xs)+{{restore cursor{19645
{{mov{13,pthen(xr){10,(xs)+{{store successor pointer{19646
{{exi{1,3{{{take success return{19647
*      here if evaluation fails
{evls1{exi{1,2{{{take failure return{19651
*      here if argument is not string
{evls2{add{7,xs{19,*num02{{pop successor and cursor{19655
{{exi{1,1{{{take non-string error exit{19656
{{enp{{{{end procedure evals{19657
{{ejc{{{{{19658
*      evalx -- evaluate expression
*      evalx is called to evaluate an expression
*      (xr)                  pointer to exblk or seblk
*      (wb)                  0 if by value, 1 if by name
*      jsr  evalx            call to evaluate expression
*      ppm  loc              transfer loc if evaluation fails
*      (xr)                  result if called by value
*      (xl,wa)               result name base,offset if by name
*      (xr)                  destroyed (name case only)
*      (xl,wa)               destroyed (value case only)
*      (wb,wc,ra)            destroyed
{evalx{prc{25,r{1,1{{entry point, recursive{19674
{{beq{9,(xr){22,=b_exl{6,evlx2{jump if exblk case{19675
*      here for seblk
{{mov{7,xl{13,sevar(xr){{load vrblk pointer (name base){19679
{{mov{8,wa{19,*vrval{{set name offset{19680
{{bnz{8,wb{6,evlx1{{jump if called by name{19681
{{jsr{6,acess{{{call routine to access value{19682
{{ppm{6,evlx9{{{jump if failure on access{19683
*      merge here to exit for seblk case
{evlx1{exi{{{{return to evalx caller{19687
{{ejc{{{{{19688
*      evalx (continued)
*      here for full expression (exblk) case
*      if an error occurs in the expression code at execution
*      time, control is passed via error section to exfal
*      without returning to this routine.
*      the following entries are made on the stack before
*      giving control to the expression code
*                            evalx return point
*                            saved value of r_cod
*                            code pointer (-r_cod)
*                            saved value of flptr
*                            0 if by value, 1 if by name
*      flptr --------------- *exflc, fail offset in exblk
{evlx2{scp{8,wc{{{get code pointer{19707
{{mov{8,wa{3,r_cod{{load code block pointer{19708
{{sub{8,wc{8,wa{{get code pointer as offset{19709
{{mov{11,-(xs){8,wa{{stack old code block pointer{19710
{{mov{11,-(xs){8,wc{{stack relative code offset{19711
{{mov{11,-(xs){3,flptr{{stack old failure pointer{19712
{{mov{11,-(xs){8,wb{{stack name/value indicator{19713
{{mov{11,-(xs){19,*exflc{{stack new fail offset{19714
{{mov{3,gtcef{3,flptr{{keep in case of error{19715
{{mov{3,r_gtc{3,r_cod{{keep code block pointer similarly{19716
{{mov{3,flptr{7,xs{{set new failure pointer{19717
{{mov{3,r_cod{7,xr{{set new code block pointer{19718
{{mov{13,exstm(xr){3,kvstn{{remember stmnt number{19719
{{add{7,xr{19,*excod{{point to first code word{19720
{{lcp{7,xr{{{set code pointer{19721
{{bne{3,stage{18,=stgxt{6,evlx0{jump if not execution time{19722
{{mov{3,stage{18,=stgee{{evaluating expression{19723
*      here to execute first code word of expression
{evlx0{zer{7,xl{{{clear garbage xl{19727
{{lcw{7,xr{{{load first code word{19728
{{bri{9,(xr){{{execute it{19729
{{ejc{{{{{19730
*      evalx (continued)
*      come here if successful return by value (see o_rvl)
{evlx3{mov{7,xr{10,(xs)+{{load value{19736
{{bze{13,num01(xs){6,evlx5{{jump if called by value{19737
{{erb{1,249{26,expression evaluated by name returned value{{{19738
*      here for expression returning by name (see o_rnm)
{evlx4{mov{8,wa{10,(xs)+{{load name offset{19742
{{mov{7,xl{10,(xs)+{{load name base{19743
{{bnz{13,num01(xs){6,evlx5{{jump if called by name{19744
{{jsr{6,acess{{{else access value first{19745
{{ppm{6,evlx6{{{jump if failure during access{19746
*      here after loading correct result into xr or xl,wa
{evlx5{zer{8,wb{{{note successful{19750
{{brn{6,evlx7{{{merge{19751
*      here for failure in expression evaluation (see o_fex)
{evlx6{mnz{8,wb{{{note unsuccessful{19755
*      restore environment
{evlx7{bne{3,stage{18,=stgee{6,evlx8{skip if was not previously xt{19759
{{mov{3,stage{18,=stgxt{{execute time{19760
*      merge with stage set up
{evlx8{add{7,xs{19,*num02{{pop name/value indicator, *exfal{19764
{{mov{3,flptr{10,(xs)+{{restore old failure pointer{19765
{{mov{8,wc{10,(xs)+{{load code offset{19766
{{add{8,wc{9,(xs){{make code pointer absolute{19767
{{mov{3,r_cod{10,(xs)+{{restore old code block pointer{19768
{{lcp{8,wc{{{restore old code pointer{19769
{{bze{8,wb{6,evlx1{{jump for successful return{19770
*      merge here for failure in seblk case
{evlx9{exi{1,1{{{take failure exit{19774
{{enp{{{{end of procedure evalx{19775
{{ejc{{{{{19776
*      exbld -- build exblk
*      exbld is used to build an expression block from the
*      code compiled most recently in the current ccblk.
*      (xl)                  offset in ccblk to start of code
*      (wb)                  integer in range 0 le n le mxlen
*      jsr  exbld            call to build exblk
*      (xr)                  ptr to constructed exblk
*      (wa,wb,xl)            destroyed
{exbld{prc{25,e{1,0{{entry point{19789
{{mov{8,wa{7,xl{{copy offset to start of code{19790
{{sub{8,wa{19,*excod{{calc reduction in offset in exblk{19791
{{mov{11,-(xs){8,wa{{stack for later{19792
{{mov{8,wa{3,cwcof{{load final offset{19793
{{sub{8,wa{7,xl{{compute length of code{19794
{{add{8,wa{19,*exsi_{{add space for standard fields{19795
{{jsr{6,alloc{{{allocate space for exblk{19796
{{mov{11,-(xs){7,xr{{save pointer to exblk{19797
{{mov{13,extyp(xr){22,=b_exl{{store type word{19798
{{zer{13,exstm(xr){{{zeroise stmnt number field{19799
{{mov{13,exsln(xr){3,cmpln{{set line number field{19801
{{mov{13,exlen(xr){8,wa{{store length{19803
{{mov{13,exflc(xr){21,=ofex_{{store failure word{19804
{{add{7,xr{19,*exsi_{{set xr for mvw{19805
{{mov{3,cwcof{7,xl{{reset offset to start of code{19806
{{add{7,xl{3,r_ccb{{point to start of code{19807
{{sub{8,wa{19,*exsi_{{length of code to move{19808
{{mov{11,-(xs){8,wa{{stack length of code{19809
{{mvw{{{{move code to exblk{19810
{{mov{8,wa{10,(xs)+{{get length of code{19811
{{btw{8,wa{{{convert byte count to word count{19812
{{lct{8,wa{8,wa{{prepare counter for loop{19813
{{mov{7,xl{9,(xs){{copy exblk ptr, dont unstack{19814
{{add{7,xl{19,*excod{{point to code itself{19815
{{mov{8,wb{13,num01(xs){{get reduction in offset{19816
*      this loop searches for negation and selection code so
*      that the offsets computed whilst code was in code block
*      can be transformed to reduced values applicable in an
*      exblk.
{exbl1{mov{7,xr{10,(xl)+{{get next code word{19823
{{beq{7,xr{21,=osla_{6,exbl3{jump if selection found{19824
{{beq{7,xr{21,=onta_{6,exbl3{jump if negation found{19825
{{bct{8,wa{6,exbl1{{loop to end of code{19826
*      no selection found or merge to exit on termination
{exbl2{mov{7,xr{10,(xs)+{{pop exblk ptr into xr{19830
{{mov{7,xl{10,(xs)+{{pop reduction constant{19831
{{exi{{{{return to caller{19832
{{ejc{{{{{19833
*      exbld (continued)
*      selection or negation found
*      reduce the offsets as needed. offsets occur in words
*      following code words -
*           =onta_, =osla_, =oslb_, =oslc_
{exbl3{sub{10,(xl)+{8,wb{{adjust offset{19842
{{bct{8,wa{6,exbl4{{decrement count{19843
{exbl4{bct{8,wa{6,exbl5{{decrement count{19845
*      continue search for more offsets
{exbl5{mov{7,xr{10,(xl)+{{get next code word{19849
{{beq{7,xr{21,=osla_{6,exbl3{jump if offset found{19850
{{beq{7,xr{21,=oslb_{6,exbl3{jump if offset found{19851
{{beq{7,xr{21,=oslc_{6,exbl3{jump if offset found{19852
{{beq{7,xr{21,=onta_{6,exbl3{jump if offset found{19853
{{bct{8,wa{6,exbl5{{loop{19854
{{brn{6,exbl2{{{merge to return{19855
{{enp{{{{end procedure exbld{19856
{{ejc{{{{{19857
*      expan -- analyze expression
*      the expression analyzer (expan) procedure is used to scan
*      an expression and convert it into a tree representation.
*      see the description of cmblk in the structures section
*      for detailed format of tree blocks.
*      the analyzer uses a simple precedence scheme in which
*      operands and operators are placed on a single stack
*      and condensations are made when low precedence operators
*      are stacked after a higher precedence operator. a global
*      variable (in wb) keeps track of the level as follows.
*      0    scanning outer level of statement or expression
*      1    scanning outer level of normal goto
*      2    scanning outer level of direct goto
*      3    scanning inside array brackets
*      4    scanning inside grouping parentheses
*      5    scanning inside function parentheses
*      this variable is saved on the stack on encountering a
*      grouping and restored at the end of the grouping.
*      another global variable (in wc) counts the number of
*      items at one grouping level and is incremented for each
*      comma encountered. it is stacked with the level indicator
*      the scan is controlled by a three state finite machine.
*      a global variable stored in wa is the current state.
*      wa=0                  nothing scanned at this level
*      wa=1                  operand expected
*      wa=2                  operator expected
*      (wb)                  call type (see below)
*      jsr  expan            call to analyze expression
*      (xr)                  pointer to resulting tree
*      (xl,wa,wb,wc,ra)      destroyed
*      the entry value of wb indicates the call type as follows.
*      0    scanning either the main body of a statement or the
*           text of an expression (from eval call). valid
*           terminators are colon, semicolon. the rescan flag is
*           set to return the terminator on the next scane call.
*      1    scanning a normal goto. the only valid
*           terminator is a right paren.
*      2    scanning a direct goto. the only valid
*           terminator is a right bracket.
{{ejc{{{{{19910
*      expan (continued)
*      entry point
{expan{prc{25,e{1,0{{entry point{19916
{{zer{11,-(xs){{{set top of stack indicator{19917
{{zer{8,wa{{{set initial state to zero{19918
{{zer{8,wc{{{zero counter value{19919
*      loop here for successive entries
{exp01{jsr{6,scane{{{scan next element{19923
{{add{7,xl{8,wa{{add state to syntax code{19924
{{bsw{7,xl{2,t_nes{{switch on element type/state{19925
{{iff{2,t_uo0{6,exp27{{unop, s=0{19962
{{iff{2,t_uo1{6,exp27{{unop, s=1{19962
{{iff{2,t_uo2{6,exp04{{unop, s=2{19962
{{iff{2,t_lp0{6,exp06{{left paren, s=0{19962
{{iff{2,t_lp1{6,exp06{{left paren, s=1{19962
{{iff{2,t_lp2{6,exp04{{left paren, s=2{19962
{{iff{2,t_lb0{6,exp08{{left brkt, s=0{19962
{{iff{2,t_lb1{6,exp08{{left brkt, s=1{19962
{{iff{2,t_lb2{6,exp09{{left brkt, s=2{19962
{{iff{2,t_cm0{6,exp02{{comma, s=0{19962
{{iff{2,t_cm1{6,exp05{{comma, s=1{19962
{{iff{2,t_cm2{6,exp11{{comma, s=2{19962
{{iff{2,t_fn0{6,exp10{{function, s=0{19962
{{iff{2,t_fn1{6,exp10{{function, s=1{19962
{{iff{2,t_fn2{6,exp04{{function, s=2{19962
{{iff{2,t_va0{6,exp03{{variable, s=0{19962
{{iff{2,t_va1{6,exp03{{variable, state one{19962
{{iff{2,t_va2{6,exp04{{variable, s=2{19962
{{iff{2,t_co0{6,exp03{{constant, s=0{19962
{{iff{2,t_co1{6,exp03{{constant, s=1{19962
{{iff{2,t_co2{6,exp04{{constant, s=2{19962
{{iff{2,t_bo0{6,exp05{{binop, s=0{19962
{{iff{2,t_bo1{6,exp05{{binop, s=1{19962
{{iff{2,t_bo2{6,exp26{{binop, s=2{19962
{{iff{2,t_rp0{6,exp02{{right paren, s=0{19962
{{iff{2,t_rp1{6,exp05{{right paren, s=1{19962
{{iff{2,t_rp2{6,exp12{{right paren, s=2{19962
{{iff{2,t_rb0{6,exp02{{right brkt, s=0{19962
{{iff{2,t_rb1{6,exp05{{right brkt, s=1{19962
{{iff{2,t_rb2{6,exp18{{right brkt, s=2{19962
{{iff{2,t_cl0{6,exp02{{colon, s=0{19962
{{iff{2,t_cl1{6,exp05{{colon, s=1{19962
{{iff{2,t_cl2{6,exp19{{colon, s=2{19962
{{iff{2,t_sm0{6,exp02{{semicolon, s=0{19962
{{iff{2,t_sm1{6,exp05{{semicolon, s=1{19962
{{iff{2,t_sm2{6,exp19{{semicolon, s=2{19962
{{esw{{{{end switch on element type/state{19962
{{ejc{{{{{19963
*      expan (continued)
*      here for rbr,rpr,col,smc,cma in state 0
*      set to rescan the terminator encountered and create
*      a null constant (case of omitted null)
{exp02{mnz{3,scnrs{{{set to rescan element{19972
{{mov{7,xr{21,=nulls{{point to null, merge{19973
*      here for var or con in states 0,1
*      stack the variable/constant and set state=2
{exp03{mov{11,-(xs){7,xr{{stack pointer to operand{19979
{{mov{8,wa{18,=num02{{set state 2{19980
{{brn{6,exp01{{{jump for next element{19981
*      here for var,con,lpr,fnc,uop in state 2
*      we rescan the element and create a concatenation operator
*      this is the case of the blank concatenation operator.
{exp04{mnz{3,scnrs{{{set to rescan element{19988
{{mov{7,xr{21,=opdvc{{point to concat operator dv{19989
{{bze{8,wb{6,exp4a{{ok if at top level{19990
{{mov{7,xr{21,=opdvp{{else point to unmistakable concat.{19991
*      merge here when xr set up with proper concatenation dvblk
{exp4a{bnz{3,scnbl{6,exp26{{merge bop if blanks, else error{19995
*      dcv  scnse            adjust start of element location
{{erb{1,220{26,syntax error: missing operator{{{19997
*      here for cma,rpr,rbr,col,smc,bop(s=1) bop(s=0)
*      this is an erronous contruction
*exp05 dcv  scnse            adjust start of element location
{exp05{erb{1,221{26,syntax error: missing operand{{{20005
*      here for lpr (s=0,1)
{exp06{mov{7,xl{18,=num04{{set new level indicator{20009
{{zer{7,xr{{{set zero value for cmopn{20010
{{ejc{{{{{20011
*      expan (continued)
*      merge here to store old level on stack and start new one
{exp07{mov{11,-(xs){7,xr{{stack cmopn value{20017
{{mov{11,-(xs){8,wc{{stack old counter{20018
{{mov{11,-(xs){8,wb{{stack old level indicator{20019
{{chk{{{{check for stack overflow{20020
{{zer{8,wa{{{set new state to zero{20021
{{mov{8,wb{7,xl{{set new level indicator{20022
{{mov{8,wc{18,=num01{{initialize new counter{20023
{{brn{6,exp01{{{jump to scan next element{20024
*      here for lbr (s=0,1)
*      this is an illegal use of left bracket
{exp08{erb{1,222{26,syntax error: invalid use of left bracket{{{20030
*      here for lbr (s=2)
*      set new level and start to scan subscripts
{exp09{mov{7,xr{10,(xs)+{{load array ptr for cmopn{20036
{{mov{7,xl{18,=num03{{set new level indicator{20037
{{brn{6,exp07{{{jump to stack old and start new{20038
*      here for fnc (s=0,1)
*      stack old level and start to scan arguments
{exp10{mov{7,xl{18,=num05{{set new lev indic (xr=vrblk=cmopn){20044
{{brn{6,exp07{{{jump to stack old and start new{20045
*      here for cma (s=2)
*      increment argument count and continue
{exp11{icv{8,wc{{{increment counter{20051
{{jsr{6,expdm{{{dump operators at this level{20052
{{zer{11,-(xs){{{set new level for parameter{20053
{{zer{8,wa{{{set new state{20054
{{bgt{8,wb{18,=num02{6,exp01{loop back unless outer level{20055
{{erb{1,223{26,syntax error: invalid use of comma{{{20056
{{ejc{{{{{20057
*      expan (continued)
*      here for rpr (s=2)
*      at outer level in a normal goto this is a terminator
*      otherwise it must terminate a function or grouping
{exp12{beq{8,wb{18,=num01{6,exp20{end of normal goto{20066
{{beq{8,wb{18,=num05{6,exp13{end of function arguments{20067
{{beq{8,wb{18,=num04{6,exp14{end of grouping / selection{20068
{{erb{1,224{26,syntax error: unbalanced right parenthesis{{{20069
*      here at end of function arguments
{exp13{mov{7,xl{18,=c_fnc{{set cmtyp value for function{20073
{{brn{6,exp15{{{jump to build cmblk{20074
*      here for end of grouping
{exp14{beq{8,wc{18,=num01{6,exp17{jump if end of grouping{20078
{{mov{7,xl{18,=c_sel{{else set cmtyp for selection{20079
*      merge here to build cmblk for level just scanned and
*      to pop up to the previous scan level before continuing.
{exp15{jsr{6,expdm{{{dump operators at this level{20084
{{mov{8,wa{8,wc{{copy count{20085
{{add{8,wa{18,=cmvls{{add for standard fields at start{20086
{{wtb{8,wa{{{convert length to bytes{20087
{{jsr{6,alloc{{{allocate space for cmblk{20088
{{mov{9,(xr){22,=b_cmt{{store type code for cmblk{20089
{{mov{13,cmtyp(xr){7,xl{{store cmblk node type indicator{20090
{{mov{13,cmlen(xr){8,wa{{store length{20091
{{add{7,xr{8,wa{{point past end of block{20092
{{lct{8,wc{8,wc{{set loop counter{20093
*      loop to move remaining words to cmblk
{exp16{mov{11,-(xr){10,(xs)+{{move one operand ptr from stack{20097
{{mov{8,wb{10,(xs)+{{pop to old level indicator{20098
{{bct{8,wc{6,exp16{{loop till all moved{20099
{{ejc{{{{{20100
*      expan (continued)
*      complete cmblk and stack pointer to it on stack
{{sub{7,xr{19,*cmvls{{point back to start of block{20106
{{mov{8,wc{10,(xs)+{{restore old counter{20107
{{mov{13,cmopn(xr){9,(xs){{store operand ptr in cmblk{20108
{{mov{9,(xs){7,xr{{stack cmblk pointer{20109
{{mov{8,wa{18,=num02{{set new state{20110
{{brn{6,exp01{{{back for next element{20111
*      here at end of a parenthesized expression
{exp17{jsr{6,expdm{{{dump operators at this level{20115
{{mov{7,xr{10,(xs)+{{restore xr{20116
{{mov{8,wb{10,(xs)+{{restore outer level{20117
{{mov{8,wc{10,(xs)+{{restore outer count{20118
{{mov{9,(xs){7,xr{{store opnd over unused cmopn val{20119
{{mov{8,wa{18,=num02{{set new state{20120
{{brn{6,exp01{{{back for next ele8ent{20121
*      here for rbr (s=2)
*      at outer level in a direct goto, this is a terminator.
*      otherwise it must terminate a subscript list.
{exp18{mov{7,xl{18,=c_arr{{set cmtyp for array reference{20128
{{beq{8,wb{18,=num03{6,exp15{jump to build cmblk if end arrayref{20129
{{beq{8,wb{18,=num02{6,exp20{jump if end of direct goto{20130
{{erb{1,225{26,syntax error: unbalanced right bracket{{{20131
{{ejc{{{{{20132
*      expan (continued)
*      here for col,smc (s=2)
*      error unless terminating statement body at outer level
{exp19{mnz{3,scnrs{{{rescan terminator{20140
{{mov{7,xl{8,wb{{copy level indicator{20141
{{bsw{7,xl{1,6{{switch on level indicator{20142
{{iff{1,0{6,exp20{{normal outer level{20149
{{iff{1,1{6,exp22{{fail if normal goto{20149
{{iff{1,2{6,exp23{{fail if direct goto{20149
{{iff{1,3{6,exp24{{fail array brackets{20149
{{iff{1,4{6,exp21{{fail if in grouping{20149
{{iff{1,5{6,exp21{{fail function args{20149
{{esw{{{{end switch on level{20149
*      here at normal end of expression
{exp20{jsr{6,expdm{{{dump remaining operators{20153
{{mov{7,xr{10,(xs)+{{load tree pointer{20154
{{ica{7,xs{{{pop off bottom of stack marker{20155
{{exi{{{{return to expan caller{20156
*      missing right paren
{exp21{erb{1,226{26,syntax error: missing right paren{{{20160
*      missing right paren in goto field
{exp22{erb{1,227{26,syntax error: right paren missing from goto{{{20164
*      missing bracket in goto
{exp23{erb{1,228{26,syntax error: right bracket missing from goto{{{20168
*      missing array bracket
{exp24{erb{1,229{26,syntax error: missing right array bracket{{{20172
{{ejc{{{{{20173
*      expan (continued)
*      loop here when an operator causes an operator dump
{exp25{mov{3,expsv{7,xr{{{20179
{{jsr{6,expop{{{pop one operator{20180
{{mov{7,xr{3,expsv{{restore op dv pointer and merge{20181
*      here for bop (s=2)
*      remove operators (condense) from stack until no more
*      left at this level or top one has lower precedence.
*      loop here till this condition is met.
{exp26{mov{7,xl{13,num01(xs){{load operator dvptr from stack{20189
{{ble{7,xl{18,=num05{6,exp27{jump if bottom of stack level{20190
{{blt{13,dvrpr(xr){13,dvlpr(xl){6,exp25{else pop if new prec is lo{20191
*      here for uop (s=0,1)
*      binary operator merges after precedence check
*      the operator dv is stored on the stack and the scan
*      continues after setting the scan state to one.
{exp27{mov{11,-(xs){7,xr{{stack operator dvptr on stack{20200
{{chk{{{{check for stack overflow{20201
{{mov{8,wa{18,=num01{{set new state{20202
{{bne{7,xr{21,=opdvs{6,exp01{back for next element unless ={20203
*      here for special case of binary =. the syntax allows a
*      null right argument for this operator to be left
*      out. accordingly we reset to state zero to get proper
*      action on a terminator (supply a null constant).
{{zer{8,wa{{{set state zero{20210
{{brn{6,exp01{{{jump for next element{20211
{{enp{{{{end procedure expan{20212
{{ejc{{{{{20213
*      expap -- test for pattern match tree
*      expap is passed an expression tree to determine if it
*      is a pattern match. the following are recogized as
*      matches in the context of this call.
*      1)   an explicit use of binary question mark
*      2)   a concatenation
*      3)   an alternation whose left operand is a concatenation
*      (xr)                  ptr to expan tree
*      jsr  expap            call to test for pattern match
*      ppm  loc              transfer loc if not a pattern match
*      (wa)                  destroyed
*      (xr)                  unchanged (if not match)
*      (xr)                  ptr to binary operator blk if match
{expap{prc{25,e{1,1{{entry point{20232
{{mov{11,-(xs){7,xl{{save xl{20233
{{bne{9,(xr){22,=b_cmt{6,expp2{no match if not complex{20234
{{mov{8,wa{13,cmtyp(xr){{else load type code{20235
{{beq{8,wa{18,=c_cnc{6,expp1{concatenation is a match{20236
{{beq{8,wa{18,=c_pmt{6,expp1{binary question mark is a match{20237
{{bne{8,wa{18,=c_alt{6,expp2{else not match unless alternation{20238
*      here for alternation. change (a b) / c to a qm (b / c)
{{mov{7,xl{13,cmlop(xr){{load left operand pointer{20242
{{bne{9,(xl){22,=b_cmt{6,expp2{not match if left opnd not complex{20243
{{bne{13,cmtyp(xl){18,=c_cnc{6,expp2{not match if left op not conc{20244
{{mov{13,cmlop(xr){13,cmrop(xl){{xr points to (b / c){20245
{{mov{13,cmrop(xl){7,xr{{set xl opnds to a, (b / c){20246
{{mov{7,xr{7,xl{{point to this altered node{20247
*      exit here for pattern match
{expp1{mov{7,xl{10,(xs)+{{restore entry xl{20251
{{exi{{{{give pattern match return{20252
*      exit here if not pattern match
{expp2{mov{7,xl{10,(xs)+{{restore entry xl{20256
{{exi{1,1{{{give non-match return{20257
{{enp{{{{end procedure expap{20258
{{ejc{{{{{20259
*      expdm -- dump operators at current level (for expan)
*      expdm uses expop to condense all operators at this syntax
*      level. the stack bottom is recognized from the level
*      value which is saved on the top of the stack.
*      jsr  expdm            call to dump operators
*      (xs)                  popped as required
*      (xr,wa)               destroyed
{expdm{prc{25,n{1,0{{entry point{20271
{{mov{3,r_exs{7,xl{{save xl value{20272
*      loop to dump operators
{exdm1{ble{13,num01(xs){18,=num05{6,exdm2{jump if stack bottom (saved level{20276
{{jsr{6,expop{{{else pop one operator{20277
{{brn{6,exdm1{{{and loop back{20278
*      here after popping all operators
{exdm2{mov{7,xl{3,r_exs{{restore xl{20282
{{zer{3,r_exs{{{release save location{20283
{{exi{{{{return to expdm caller{20284
{{enp{{{{end procedure expdm{20285
{{ejc{{{{{20286
*      expop-- pop operator (for expan)
*      expop is used by the expan routine to condense one
*      operator from the top of the syntax stack. an appropriate
*      cmblk is built for the operator (unary or binary) and a
*      pointer to this cmblk is stacked.
*      expop is also used by scngf (goto field scan) procedure
*      jsr  expop            call to pop operator
*      (xs)                  popped appropriately
*      (xr,xl,wa)            destroyed
{expop{prc{25,n{1,0{{entry point{20301
{{mov{7,xr{13,num01(xs){{load operator dv pointer{20302
{{beq{13,dvlpr(xr){18,=lluno{6,expo2{jump if unary{20303
*      here for binary operator
{{mov{8,wa{19,*cmbs_{{set size of binary operator cmblk{20307
{{jsr{6,alloc{{{allocate space for cmblk{20308
{{mov{13,cmrop(xr){10,(xs)+{{pop and store right operand ptr{20309
{{mov{7,xl{10,(xs)+{{pop and load operator dv ptr{20310
{{mov{13,cmlop(xr){9,(xs){{store left operand pointer{20311
*      common exit point
{expo1{mov{9,(xr){22,=b_cmt{{store type code for cmblk{20315
{{mov{13,cmtyp(xr){13,dvtyp(xl){{store cmblk node type code{20316
{{mov{13,cmopn(xr){7,xl{{store dvptr (=ptr to dac o_xxx){20317
{{mov{13,cmlen(xr){8,wa{{store cmblk length{20318
{{mov{9,(xs){7,xr{{store resulting node ptr on stack{20319
{{exi{{{{return to expop caller{20320
*      here for unary operator
{expo2{mov{8,wa{19,*cmus_{{set size of unary operator cmblk{20324
{{jsr{6,alloc{{{allocate space for cmblk{20325
{{mov{13,cmrop(xr){10,(xs)+{{pop and store operand pointer{20326
{{mov{7,xl{9,(xs){{load operator dv pointer{20327
{{brn{6,expo1{{{merge back to exit{20328
{{enp{{{{end procedure expop{20329
{{ejc{{{{{20330
*      filnm -- obtain file name from statement number
*      filnm takes a statement number and examines the file name
*      table pointed to by r_sfn to find the name of the file
*      containing the given statement.  table entries are
*      arranged in order of ascending statement number (there
*      is only one hash bucket in this table).  elements are
*      added to the table each time there is a change in
*      file name, recording the then current statement number.
*      to find the file name, the linked list of teblks is
*      scanned for an element containing a subscript (statement
*      number) greater than the argument statement number, or
*      the end of chain.  when this condition is met, the
*      previous teblk contains the desired file name as its
*      value entry.
*      (wc)                  statement number
*      jsr  filnm            call to obtain file name
*      (xl)                  file name (scblk)
*      (ia)                  destroyed
{filnm{prc{25,e{1,0{{entry point{20355
{{mov{11,-(xs){8,wb{{preserve wb{20356
{{bze{8,wc{6,filn3{{return nulls if stno is zero{20357
{{mov{7,xl{3,r_sfn{{file name table{20358
{{bze{7,xl{6,filn3{{if no table{20359
{{mov{8,wb{13,tbbuk(xl){{get bucket entry{20360
{{beq{8,wb{3,r_sfn{6,filn3{jump if no teblks on chain{20361
{{mov{11,-(xs){7,xr{{preserve xr{20362
{{mov{7,xr{8,wb{{previous block pointer{20363
{{mov{11,-(xs){8,wc{{preserve stmt number{20364
*      loop through teblks on hash chain
{filn1{mov{7,xl{7,xr{{next element to examine{20368
{{mov{7,xr{13,tesub(xl){{load subscript value (an icblk){20369
{{ldi{13,icval(xr){{{load the statement number{20370
{{mfi{8,wc{{{convert to address constant{20371
{{blt{9,(xs){8,wc{6,filn2{compare arg with teblk stmt number{20372
*      here if desired stmt number is ge teblk stmt number
{{mov{8,wb{7,xl{{save previous entry pointer{20376
{{mov{7,xr{13,tenxt(xl){{point to next teblk on chain{20377
{{bne{7,xr{3,r_sfn{6,filn1{jump if there is one{20378
*      here if chain exhausted or desired block found.
{filn2{mov{7,xl{8,wb{{previous teblk{20382
{{mov{7,xl{13,teval(xl){{get ptr to file name scblk{20383
{{mov{8,wc{10,(xs)+{{restore stmt number{20384
{{mov{7,xr{10,(xs)+{{restore xr{20385
{{mov{8,wb{10,(xs)+{{restore wb{20386
{{exi{{{{{20387
*      no table or no table entries
{filn3{mov{8,wb{10,(xs)+{{restore wb{20391
{{mov{7,xl{21,=nulls{{return null string{20392
{{exi{{{{{20393
{{enp{{{{{20394
{{ejc{{{{{20395
*      gbcol -- perform garbage collection
*      gbcol performs a garbage collection on the dynamic region
*      all blocks which are no longer in use are eliminated
*      by moving blocks which are in use down and resetting
*      dnamp, the pointer to the next available location.
*      (wb)                  move offset (see below)
*      jsr  gbcol            call to collect garbage
*      (xr)                  sediment size after collection
*      the following conditions must be met at the time when
*      gbcol is called.
*      1)   all pointers to blocks in the dynamic area must be
*           accessible to the garbage collector. this means
*           that they must occur in one of the following.
*           a)               main stack, with current top
*                            element being indicated by xs
*           b)               in relocatable fields of vrblks.
*           c)               in register xl at the time of call
*           e)               in the special region of working
*                            storage where names begin with r_.
*      2)   all pointers must point to the start of blocks with
*           the sole exception of the contents of the code
*           pointer register which points into the r_cod block.
*      3)   no location which appears to contain a pointer
*           into the dynamic region may occur unless it is in
*           fact a pointer to the start of the block. however
*           pointers outside this area may occur and will
*           not be changed by the garbage collector.
*           it is especially important to make sure that xl
*           does not contain a garbage value from some process
*           carried out before the call to the collector.
*      gbcol has the capability of moving the final compacted
*      result up in memory (with addresses adjusted accordingly)
*      this is used to add space to the static region. the
*      entry value of wb is the number of bytes to move up.
*      the caller must guarantee that there is enough room.
*      furthermore the value in wb if it is non-zero, must be at
*      least 256 so that the mwb instruction conditions are met.
{{ejc{{{{{20497
*      gbcol (continued)
*      the algorithm, which is a modification of the lisp-2
*      garbage collector devised by r.dewar and k.belcher
*      takes three passes as follows.
*      1)   all pointers in memory are scanned and blocks in use
*           determined from this scan. note that this procedure
*           is recursive and uses the main stack for linkage.
*           the marking process is thus similar to that used in
*           a standard lisp collector. however the method of
*           actually marking the blocks is different.
*           the first field of a block normally contains a
*           code entry point pointer. such an entry pointer
*           can be distinguished from the address of any pointer
*           to be processed by the collector. during garbage
*           collection, this word is used to build a back chain
*           of pointers through fields which point to the block.
*           the end of the chain is marked by the occurence
*           of the word which used to be in the first word of
*           the block. this backchain serves both as a mark
*           indicating that the block is in use and as a list of
*           references for the relocation phase.
*      2)   storage is scanned sequentially to discover which
*           blocks are currently in use as indicated by the
*           presence of a backchain. two pointers are maintained
*           one scans through looking at each block. the other
*           is incremented only for blocks found to be in use.
*           in this way, the eventual location of each block can
*           be determined without actually moving any blocks.
*           as each block which is in use is processed, the back
*           chain is used to reset all pointers which point to
*           this block to contain its new address, i.e. the
*           address it will occupy after the blocks are moved.
*           the first word of the block, taken from the end of
*           the chain is restored at this point.
*           during pass 2, the collector builds blocks which
*           describe the regions of storage which are to be
*           moved in the third pass. there is one descriptor for
*           each contiguous set of good blocks. the descriptor
*           is built just behind the block to be moved and
*           contains a pointer to the next block and the number
*           of words to be moved.
*      3)   in the third and final pass, the move descriptor
*           blocks built in pass two are used to actually move
*           the blocks down to the bottom of the dynamic region.
*           the collection is then complete and the next
*           available location pointer is reset.
{{ejc{{{{{20551
*      gbcol (continued)
*      the garbage collector also recognizes the concept of
*      sediment.  sediment is defined as long-lived objects
*      which percipitate to the bottom of dynamic storage.
*      moving these objects during repeated collections is
*      inefficient.  it also contributes to thrashing on
*      systems with virtual memory.  in a typical worst-case
*      situation, there may be several megabytes of live objects
*      in the sediment, and only a few dead objects in need of
*      collection.  without recognising sediment, the standard
*      collector would move those megabytes of objects downward
*      to squeeze out the dead objects.  this type of move
*      would result in excessive thrasing for very little memory
*      gain.
*      scanning of blocks in the sediment cannot be avoided
*      entirely, because these blocks may contain pointers to
*      live objects above the sediment.  however, sediment
*      blocks need not be linked to a back chain as described
*      in pass one above.  since these blocks will not be moved,
*      pointers to them do not need to be adjusted.  eliminating
*      unnecessary back chain links increases locality of
*      reference, improving virtual memory performance.
*      because back chains are used to mark blocks whose con-
*      tents have been processed, a different marking system
*      is needed for blocks in the sediment.  all block type
*      words normally lie in the range b_aaa to p_yyy.  blocks
*      can be marked by adding an offset (created in gbcmk) to
*      move type words out of this range.  during pass three the
*      offset is subtracted to restore them to their original
*      value.
{{ejc{{{{{20595
*      gbcol (continued)
*      the variable dnams contains the number of bytes of memory
*      currently in the sediment.  setting dnams to zero will
*      eliminate the sediment and force it to be included in a
*      full garbage collection.  gbcol returns a suggested new
*      value for dnams (usually dnamp-dnamb) in xr which the
*      caller can store in dnams if it wishes to maintain the
*      sediment.  that is, data remaining after a garbage
*      collection is considered to be sediment.  if one accepts
*      the common lore that most objects are either very short-
*      or very long-lived, then this naive setting of dnams
*      probably includes some short-lived objects toward the end
*      of the sediment.
*      knowing when to reset dnams to zero to collect the sedi-
*      ment is not precisely known.  we force it to zero prior
*      to producing a dump, when gbcol is invoked by collect()
*      (so that the sediment is invisible to the user), when
*      sysmm is unable to obtain additional memory, and when
*      gbcol is called to relocate the dynamic area up in memory
*      (to make room for enlarging the static area).  if there
*      are no other reset situations, this leads to the inexo-
*      rable growth of the sediment, possible forcing a modest
*      program to begin to use virtual memory that it otherwise
*      would not.
*      as we scan sediment blocks in pass three, we maintain
*      aggregate counts of the amount of dead and live storage,
*      which is used to decide when to reset dnams.  when the
*      ratio of free storage found in the sediment to total
*      sediment size exceeds a threshold, the sediment is marked
*      for collection on the next gbcol call.
{{ejc{{{{{20633
*      gbcol (continued)
{gbcol{prc{25,e{1,0{{entry point{20637
*z-
{{bnz{3,dmvch{6,gbc14{{fail if in mid-dump{20639
{{mnz{3,gbcfl{{{note gbcol entered{20640
{{mov{3,gbsva{8,wa{{save entry wa{20641
{{mov{3,gbsvb{8,wb{{save entry wb{20642
{{mov{3,gbsvc{8,wc{{save entry wc{20643
{{mov{11,-(xs){7,xl{{save entry xl{20644
{{scp{8,wa{{{get code pointer value{20645
{{sub{8,wa{3,r_cod{{make relative{20646
{{lcp{8,wa{{{and restore{20647
{{bze{8,wb{6,gbc0a{{check there is no move offset{20649
{{zer{3,dnams{{{collect sediment if must move it{20650
{gbc0a{mov{8,wa{3,dnamb{{start of dynamic area{20651
{{add{8,wa{3,dnams{{size of sediment{20652
{{mov{3,gbcsd{8,wa{{first location past sediment{20653
{{mov{8,wa{22,=p_yyy{{last entry point{20656
{{icv{8,wa{{{address past last entry point{20657
{{sub{8,wa{22,=b_aaa{{size of entry point area{20658
{{mov{3,gbcmk{8,wa{{use to mark processed sed. blocks{20659
*      inform sysgc that collection to commence
{{mnz{7,xr{{{non-zero flags start of collection{20666
{{mov{8,wa{3,dnamb{{start of dynamic area{20667
{{mov{8,wb{3,dnamp{{next available location{20668
{{mov{8,wc{3,dname{{last available location + 1{20669
{{jsr{6,sysgc{{{inform of collection{20670
*      process stack entries
{{mov{7,xr{7,xs{{point to stack front{20675
{{mov{7,xl{3,stbas{{point past end of stack{20676
{{bge{7,xl{7,xr{6,gbc00{ok if d-stack{20677
{{mov{7,xr{7,xl{{reverse if ...{20678
{{mov{7,xl{7,xs{{... u-stack{20679
*      process the stack
{gbc00{jsr{6,gbcpf{{{process pointers on stack{20683
*      process special work locations
{{mov{7,xr{20,=r_aaa{{point to start of relocatable locs{20687
{{mov{7,xl{20,=r_yyy{{point past end of relocatable locs{20688
{{jsr{6,gbcpf{{{process work fields{20689
*      prepare to process variable blocks
{{mov{8,wa{3,hshtb{{point to first hash slot pointer{20693
*      loop through hash slots
{gbc01{mov{7,xl{8,wa{{point to next slot{20697
{{ica{8,wa{{{bump bucket pointer{20698
{{mov{3,gbcnm{8,wa{{save bucket pointer{20699
{{ejc{{{{{20700
*      gbcol (continued)
*      loop through variables on one hash chain
{gbc02{mov{7,xr{9,(xl){{load ptr to next vrblk{20706
{{bze{7,xr{6,gbc03{{jump if end of chain{20707
{{mov{7,xl{7,xr{{else copy vrblk pointer{20708
{{add{7,xr{19,*vrval{{point to first reloc fld{20709
{{add{7,xl{19,*vrnxt{{point past last (and to link ptr){20710
{{jsr{6,gbcpf{{{process reloc fields in vrblk{20711
{{brn{6,gbc02{{{loop back for next block{20712
*      here at end of one hash chain
{gbc03{mov{8,wa{3,gbcnm{{restore bucket pointer{20716
{{bne{8,wa{3,hshte{6,gbc01{loop back if more buckets to go{20717
{{ejc{{{{{20718
*      gbcol (continued)
*      now we are ready to start pass two. registers are used
*      as follows in pass two.
*      (xr)                  scans through all blocks
*      (wc)                  pointer to eventual location
*      the move description blocks built in this pass have
*      the following format.
*      word 1                pointer to next move block,
*                            zero if end of chain of blocks
*      word 2                length of blocks to be moved in
*                            bytes. set to the address of the
*                            first byte while actually scanning
*                            the blocks.
*      the first entry on this chain is a special entry
*      consisting of the two words gbcnm and gbcns. after
*      building the chain of move descriptors, gbcnm points to
*      the first real move block, and gbcns is the length of
*      blocks in use at the start of storage which need not
*      be moved since they are in the correct position.
{{mov{7,xr{3,dnamb{{point to first block{20747
{{zer{8,wb{{{accumulate size of dead blocks{20748
{gbc04{beq{7,xr{3,gbcsd{6,gbc4c{jump if end of sediment{20749
{{mov{8,wa{9,(xr){{else get first word{20750
{{bhi{8,wa{22,=p_yyy{6,gbc4a{skip if not entry ptr (in use){20755
{{bhi{8,wa{22,=b_aaa{6,gbc4b{jump if entry pointer (unused){20756
{gbc4a{sub{8,wa{3,gbcmk{{restore entry pointer{20757
{{mov{9,(xr){8,wa{{restore first word{20759
{{jsr{6,blkln{{{get length of this block{20760
{{add{7,xr{8,wa{{bump actual pointer{20761
{{brn{6,gbc04{{{continue scan through sediment{20762
*      here for unused sediment block
{gbc4b{jsr{6,blkln{{{get length of this block{20766
{{add{7,xr{8,wa{{bump actual pointer{20767
{{add{8,wb{8,wa{{count size of unused blocks{20768
{{brn{6,gbc04{{{continue scan through sediment{20769
*      here at end of sediment.  remember size of free blocks
*      within the sediment.  this will be used later to decide
*      how to set the sediment size returned to caller.
*      then scan rest of dynamic area above sediment.
*      (wb) = aggregate size of free blocks in sediment
*      (xr) = first location past sediment
{gbc4c{mov{3,gbcsf{8,wb{{size of sediment free space{20780
{{mov{8,wc{7,xr{{set as first eventual location{20784
{{add{8,wc{3,gbsvb{{add offset for eventual move up{20785
{{zer{3,gbcnm{{{clear initial forward pointer{20786
{{mov{3,gbclm{20,=gbcnm{{initialize ptr to last move block{20787
{{mov{3,gbcns{7,xr{{initialize first address{20788
*      loop through a series of blocks in use
{gbc05{beq{7,xr{3,dnamp{6,gbc07{jump if end of used region{20792
{{mov{8,wa{9,(xr){{else get first word{20793
{{bhi{8,wa{22,=p_yyy{6,gbc06{skip if not entry ptr (in use){20797
{{bhi{8,wa{22,=b_aaa{6,gbc07{jump if entry pointer (unused){20798
*      here for block in use, loop to relocate references
{gbc06{mov{7,xl{8,wa{{copy pointer{20803
{{mov{8,wa{9,(xl){{load forward pointer{20804
{{mov{9,(xl){8,wc{{relocate reference{20805
{{bhi{8,wa{22,=p_yyy{6,gbc06{loop back if not end of chain{20809
{{blo{8,wa{22,=b_aaa{6,gbc06{loop back if not end of chain{20810
{{ejc{{{{{20812
*      gbcol (continued)
*      at end of chain, restore first word and bump past
{{mov{9,(xr){8,wa{{restore first word{20818
{{jsr{6,blkln{{{get length of this block{20819
{{add{7,xr{8,wa{{bump actual pointer{20820
{{add{8,wc{8,wa{{bump eventual pointer{20821
{{brn{6,gbc05{{{loop back for next block{20822
*      here at end of a series of blocks in use
{gbc07{mov{8,wa{7,xr{{copy pointer past last block{20826
{{mov{7,xl{3,gbclm{{point to previous move block{20827
{{sub{8,wa{13,num01(xl){{subtract starting address{20828
{{mov{13,num01(xl){8,wa{{store length of block to be moved{20829
*      loop through a series of blocks not in use
{gbc08{beq{7,xr{3,dnamp{6,gbc10{jump if end of used region{20833
{{mov{8,wa{9,(xr){{else load first word of next block{20834
{{bhi{8,wa{22,=p_yyy{6,gbc09{jump if in use{20838
{{blo{8,wa{22,=b_aaa{6,gbc09{jump if in use{20839
{{jsr{6,blkln{{{else get length of next block{20841
{{add{7,xr{8,wa{{push pointer{20842
{{brn{6,gbc08{{{and loop back{20843
*      here for a block in use after processing a series of
*      blocks which were not in use, build new move block.
{gbc09{sub{7,xr{19,*num02{{point 2 words behind for move block{20848
{{mov{7,xl{3,gbclm{{point to previous move block{20849
{{mov{9,(xl){7,xr{{set forward ptr in previous block{20850
{{zer{9,(xr){{{zero forward ptr of new block{20851
{{mov{3,gbclm{7,xr{{remember address of this block{20852
{{mov{7,xl{7,xr{{copy ptr to move block{20853
{{add{7,xr{19,*num02{{point back to block in use{20854
{{mov{13,num01(xl){7,xr{{store starting address{20855
{{brn{6,gbc06{{{jump to process block in use{20856
{{ejc{{{{{20857
*      gbcol (continued)
*      here for pass three -- actually move the blocks down
*      (xl)                  pointer to old location
*      (xr)                  pointer to new location
{gbc10{mov{7,xr{3,gbcsd{{point to storage above sediment{20867
{{add{7,xr{3,gbcns{{bump past unmoved blocks at start{20871
*      loop through move descriptors
{gbc11{mov{7,xl{3,gbcnm{{point to next move block{20875
{{bze{7,xl{6,gbc12{{jump if end of chain{20876
{{mov{3,gbcnm{10,(xl)+{{move pointer down chain{20877
{{mov{8,wa{10,(xl)+{{get length to move{20878
{{mvw{{{{perform move{20879
{{brn{6,gbc11{{{loop back{20880
*      now test for move up
{gbc12{mov{3,dnamp{7,xr{{set next available loc ptr{20884
{{mov{8,wb{3,gbsvb{{reload move offset{20885
{{bze{8,wb{6,gbc13{{jump if no move required{20886
{{mov{7,xl{7,xr{{else copy old top of core{20887
{{add{7,xr{8,wb{{point to new top of core{20888
{{mov{3,dnamp{7,xr{{save new top of core pointer{20889
{{mov{8,wa{7,xl{{copy old top{20890
{{sub{8,wa{3,dnamb{{minus old bottom = length{20891
{{add{3,dnamb{8,wb{{bump bottom to get new value{20892
{{mwb{{{{perform move (backwards){20893
*      merge here to exit
{gbc13{zer{7,xr{{{clear garbage value in xr{20897
{{mov{3,gbcfl{7,xr{{note exit from gbcol{20898
{{mov{8,wa{3,dnamb{{start of dynamic area{20900
{{mov{8,wb{3,dnamp{{next available location{20901
{{mov{8,wc{3,dname{{last available location + 1{20902
{{jsr{6,sysgc{{{inform sysgc of completion{20903
*      decide whether to mark sediment for collection next time.
*      this is done by examining the ratio of previous sediment
*      free space to the new sediment size.
{{sti{3,gbcia{{{save ia{20911
{{zer{7,xr{{{presume no sediment will remain{20912
{{mov{8,wb{3,gbcsf{{free space in sediment{20913
{{btw{8,wb{{{convert bytes to words{20914
{{mti{8,wb{{{put sediment free store in ia{20915
{{mli{3,gbsed{{{multiply by sediment factor{20916
{{iov{6,gb13a{{{jump if overflowed{20917
{{mov{8,wb{3,dnamp{{end of dynamic area in use{20918
{{sub{8,wb{3,dnamb{{minus start is sediment remaining{20919
{{btw{8,wb{{{convert to words{20920
{{mov{3,gbcsf{8,wb{{store it{20921
{{sbi{3,gbcsf{{{subtract from scaled up free store{20922
{{igt{6,gb13a{{{jump if large free store in sedimnt{20923
{{mov{7,xr{3,dnamp{{below threshold, return sediment{20924
{{sub{7,xr{3,dnamb{{for use by caller{20925
{gb13a{ldi{3,gbcia{{{restore ia{20926
{{mov{8,wa{3,gbsva{{restore wa{20928
{{mov{8,wb{3,gbsvb{{restore wb{20929
{{scp{8,wc{{{get code pointer{20930
{{add{8,wc{3,r_cod{{make absolute again{20931
{{lcp{8,wc{{{and replace absolute value{20932
{{mov{8,wc{3,gbsvc{{restore wc{20933
{{mov{7,xl{10,(xs)+{{restore entry xl{20934
{{icv{3,gbcnt{{{increment count of collections{20935
{{exi{{{{exit to gbcol caller{20936
*      garbage collection not allowed whilst dumping
{gbc14{icv{3,errft{{{fatal error{20940
{{erb{1,250{26,insufficient memory to complete dump{{{20941
{{enp{{{{end procedure gbcol{20942
{{ejc{{{{{20943
*      gbcpf -- process fields for garbage collector
*      this procedure is used by the garbage collector to
*      process fields in pass one. see gbcol for full details.
*      (xr)                  ptr to first location to process
*      (xl)                  ptr past last location to process
*      jsr  gbcpf            call to process fields
*      (xr,wa,wb,wc,ia)      destroyed
*      note that although this procedure uses a recursive
*      approach, it controls its own stack and is not recursive.
{gbcpf{prc{25,e{1,0{{entry point{20958
{{zer{11,-(xs){{{set zero to mark bottom of stack{20959
{{mov{11,-(xs){7,xl{{save end pointer{20960
*      merge here to go down a level and start a new loop
*      1(xs)                 next lvl field ptr (0 at outer lvl)
*      0(xs)                 ptr past last field to process
*      (xr)                  ptr to first field to process
*      loop to process successive fields
{gpf01{mov{7,xl{9,(xr){{load field contents{20970
{{mov{8,wc{7,xr{{save field pointer{20971
{{blt{7,xl{3,dnamb{6,gpf2a{jump if not ptr into dynamic area{20975
{{bge{7,xl{3,dnamp{6,gpf2a{jump if not ptr into dynamic area{20976
*      here we have a ptr to a block in the dynamic area.
*      link this field onto the reference backchain.
{{mov{8,wa{9,(xl){{load ptr to chain (or entry ptr){20981
{{blt{7,xl{3,gbcsd{6,gpf1a{do not chain if within sediment{20983
{{mov{9,(xl){7,xr{{set this field as new head of chain{20985
{{mov{9,(xr){8,wa{{set forward pointer{20986
*      now see if this block has been processed before
{gpf1a{bhi{8,wa{22,=p_yyy{6,gpf2a{jump if already processed{20993
{{bhi{8,wa{22,=b_aaa{6,gpf03{jump if not already processed{20994
*      here to restore pointer in xr to field just processed
{gpf02{mov{7,xr{8,wc{{restore field pointer{20999
*      here to move to next field
{gpf2a{ica{7,xr{{{bump to next field{21003
{{bne{7,xr{9,(xs){6,gpf01{loop back if more to go{21004
{{ejc{{{{{21005
*      gbcpf (continued)
*      here we pop up a level after finishing a block
{{mov{7,xl{10,(xs)+{{restore pointer past end{21011
{{mov{7,xr{10,(xs)+{{restore block pointer{21012
{{bnz{7,xr{6,gpf2a{{continue loop unless outer levl{21013
{{exi{{{{return to caller if outer level{21014
*      here to process an active block which has not been done
*      since sediment blocks are not marked by putting them on
*      the back chain, they must be explicitly marked in another
*      manner.  if odd parity entry points are present, mark by
*      temporarily converting to even parity.  if odd parity not
*      available, the entry point is adjusted by the value in
*      gbcmk.
{gpf03{bge{7,xl{3,gbcsd{6,gpf3a{if not within sediment{21027
{{add{9,(xl){3,gbcmk{{mark by biasing entry point{21031
{gpf3a{mov{7,xr{7,xl{{copy block pointer{21033
{{mov{7,xl{8,wa{{copy first word of block{21037
{{lei{7,xl{{{load entry point id (bl_xx){21038
*      block type switch. note that blocks with no relocatable
*      fields just return to gpf02 here to continue to next fld.
{{bsw{7,xl{2,bl___{{switch on block type{21043
{{iff{2,bl_ar{6,gpf06{{arblk{21081
{{iff{2,bl_cd{6,gpf19{{cdblk{21081
{{iff{2,bl_ex{6,gpf17{{exblk{21081
{{iff{2,bl_ic{6,gpf02{{icblk{21081
{{iff{2,bl_nm{6,gpf10{{nmblk{21081
{{iff{2,bl_p0{6,gpf10{{p0blk{21081
{{iff{2,bl_p1{6,gpf12{{p1blk{21081
{{iff{2,bl_p2{6,gpf12{{p2blk{21081
{{iff{2,bl_rc{6,gpf02{{rcblk{21081
{{iff{2,bl_sc{6,gpf02{{scblk{21081
{{iff{2,bl_se{6,gpf02{{seblk{21081
{{iff{2,bl_tb{6,gpf08{{tbblk{21081
{{iff{2,bl_vc{6,gpf08{{vcblk{21081
{{iff{2,bl_xn{6,gpf02{{xnblk{21081
{{iff{2,bl_xr{6,gpf09{{xrblk{21081
{{iff{2,bl_bc{6,gpf02{{bcblk - dummy to fill out iffs{21081
{{iff{2,bl_pd{6,gpf13{{pdblk{21081
{{iff{2,bl_tr{6,gpf16{{trblk{21081
{{iff{2,bl_bf{6,gpf02{{bfblk{21081
{{iff{2,bl_cc{6,gpf07{{ccblk{21081
{{iff{2,bl_cm{6,gpf04{{cmblk{21081
{{iff{2,bl_ct{6,gpf02{{ctblk{21081
{{iff{2,bl_df{6,gpf02{{dfblk{21081
{{iff{2,bl_ef{6,gpf02{{efblk{21081
{{iff{2,bl_ev{6,gpf10{{evblk{21081
{{iff{2,bl_ff{6,gpf11{{ffblk{21081
{{iff{2,bl_kv{6,gpf02{{kvblk{21081
{{iff{2,bl_pf{6,gpf14{{pfblk{21081
{{iff{2,bl_te{6,gpf15{{teblk{21081
{{esw{{{{end of jump table{21081
{{ejc{{{{{21082
*      gbcpf (continued)
*      cmblk
{gpf04{mov{8,wa{13,cmlen(xr){{load length{21088
{{mov{8,wb{19,*cmtyp{{set offset{21089
*      here to push down to new level
*      (wc)                  field ptr at previous level
*      (xr)                  ptr to new block
*      (wa)                  length (reloc flds + flds at start)
*      (wb)                  offset to first reloc field
{gpf05{add{8,wa{7,xr{{point past last reloc field{21098
{{add{7,xr{8,wb{{point to first reloc field{21099
{{mov{11,-(xs){8,wc{{stack old field pointer{21100
{{mov{11,-(xs){8,wa{{stack new limit pointer{21101
{{chk{{{{check for stack overflow{21102
{{brn{6,gpf01{{{if ok, back to process{21103
*      arblk
{gpf06{mov{8,wa{13,arlen(xr){{load length{21107
{{mov{8,wb{13,arofs(xr){{set offset to 1st reloc fld (arpro){21108
{{brn{6,gpf05{{{all set{21109
*      ccblk
{gpf07{mov{8,wa{13,ccuse(xr){{set length in use{21113
{{mov{8,wb{19,*ccuse{{1st word (make sure at least one){21114
{{brn{6,gpf05{{{all set{21115
{{ejc{{{{{21116
*      gbcpf (continued)
*      cdblk
{gpf19{mov{8,wa{13,cdlen(xr){{load length{21123
{{mov{8,wb{19,*cdfal{{set offset{21124
{{brn{6,gpf05{{{jump back{21125
*      tbblk, vcblk
{gpf08{mov{8,wa{13,offs2(xr){{load length{21132
{{mov{8,wb{19,*offs3{{set offset{21133
{{brn{6,gpf05{{{jump back{21134
*      xrblk
{gpf09{mov{8,wa{13,xrlen(xr){{load length{21138
{{mov{8,wb{19,*xrptr{{set offset{21139
{{brn{6,gpf05{{{jump back{21140
*      evblk, nmblk, p0blk
{gpf10{mov{8,wa{19,*offs2{{point past second field{21144
{{mov{8,wb{19,*offs1{{offset is one (only reloc fld is 2){21145
{{brn{6,gpf05{{{all set{21146
*      ffblk
{gpf11{mov{8,wa{19,*ffofs{{set length{21150
{{mov{8,wb{19,*ffnxt{{set offset{21151
{{brn{6,gpf05{{{all set{21152
*      p1blk, p2blk
{gpf12{mov{8,wa{19,*parm2{{length (parm2 is non-relocatable){21156
{{mov{8,wb{19,*pthen{{set offset{21157
{{brn{6,gpf05{{{all set{21158
{{ejc{{{{{21159
*      gbcpf (continued)
*      pdblk
{gpf13{mov{7,xl{13,pddfp(xr){{load ptr to dfblk{21165
{{mov{8,wa{13,dfpdl(xl){{get pdblk length{21166
{{mov{8,wb{19,*pdfld{{set offset{21167
{{brn{6,gpf05{{{all set{21168
*      pfblk
{gpf14{mov{8,wa{19,*pfarg{{length past last reloc{21172
{{mov{8,wb{19,*pfcod{{offset to first reloc{21173
{{brn{6,gpf05{{{all set{21174
*      teblk
{gpf15{mov{8,wa{19,*tesi_{{set length{21178
{{mov{8,wb{19,*tesub{{and offset{21179
{{brn{6,gpf05{{{all set{21180
*      trblk
{gpf16{mov{8,wa{19,*trsi_{{set length{21184
{{mov{8,wb{19,*trval{{and offset{21185
{{brn{6,gpf05{{{all set{21186
*      exblk
{gpf17{mov{8,wa{13,exlen(xr){{load length{21190
{{mov{8,wb{19,*exflc{{set offset{21191
{{brn{6,gpf05{{{jump back{21192
{{enp{{{{end procedure gbcpf{21202
{{ejc{{{{{21203
*z+
*      gtarr -- get array
*      gtarr is passed an object and returns an array if possibl
*      (xr)                  value to be converted
*      (wa)                  0 to place table addresses in array
*                            non-zero for keys/values in array
*      jsr  gtarr            call to get array
*      ppm  loc              transfer loc for all null table
*      ppm  loc              transfer loc if convert impossible
*      (xr)                  resulting array
*      (xl,wa,wb,wc)         destroyed
{gtarr{prc{25,e{1,2{{entry point{21219
{{mov{3,gtawa{8,wa{{save wa indicator{21220
{{mov{8,wa{9,(xr){{load type word{21221
{{beq{8,wa{22,=b_art{6,gtar8{exit if already an array{21222
{{beq{8,wa{22,=b_vct{6,gtar8{exit if already an array{21223
{{bne{8,wa{22,=b_tbt{6,gta9a{else fail if not a table (sgd02){21224
*      here we convert a table to an array
{{mov{11,-(xs){7,xr{{replace tbblk pointer on stack{21228
{{zer{7,xr{{{signal first pass{21229
{{zer{8,wb{{{zero non-null element count{21230
*      the following code is executed twice. on the first pass,
*      signalled by xr=0, the number of non-null elements in
*      the table is counted in wb. in the second pass, where
*      xr is a pointer into the arblk, the name and value are
*      entered into the current arblk location provided gtawa
*      is non-zero.  if gtawa is zero, the address of the teblk
*      is entered into the arblk twice (c3.762).
{gtar1{mov{7,xl{9,(xs){{point to table{21240
{{add{7,xl{13,tblen(xl){{point past last bucket{21241
{{sub{7,xl{19,*tbbuk{{set first bucket offset{21242
{{mov{8,wa{7,xl{{copy adjusted pointer{21243
*      loop through buckets in table block
*      next three lines of code rely on tenxt having a value
*      1 less than tbbuk.
{gtar2{mov{7,xl{8,wa{{copy bucket pointer{21249
{{dca{8,wa{{{decrement bucket pointer{21250
*      loop through teblks on one bucket chain
{gtar3{mov{7,xl{13,tenxt(xl){{point to next teblk{21254
{{beq{7,xl{9,(xs){6,gtar6{jump if chain end (tbblk ptr){21255
{{mov{3,cnvtp{7,xl{{else save teblk pointer{21256
*      loop to find value down trblk chain
{gtar4{mov{7,xl{13,teval(xl){{load value{21260
{{beq{9,(xl){22,=b_trt{6,gtar4{loop till value found{21261
{{mov{8,wc{7,xl{{copy value{21262
{{mov{7,xl{3,cnvtp{{restore teblk pointer{21263
{{ejc{{{{{21264
*      gtarr (continued)
*      now check for null and test cases
{{beq{8,wc{21,=nulls{6,gtar3{loop back to ignore null value{21270
{{bnz{7,xr{6,gtar5{{jump if second pass{21271
{{icv{8,wb{{{for the first pass, bump count{21272
{{brn{6,gtar3{{{and loop back for next teblk{21273
*      here in second pass
{gtar5{bze{3,gtawa{6,gta5a{{jump if address wanted{21277
{{mov{10,(xr)+{13,tesub(xl){{store subscript name{21278
{{mov{10,(xr)+{8,wc{{store value in arblk{21279
{{brn{6,gtar3{{{loop back for next teblk{21280
*      here to record teblk address in arblk.  this allows
*      a sort routine to sort by ascending address.
{gta5a{mov{10,(xr)+{7,xl{{store teblk address in name{21285
{{mov{10,(xr)+{7,xl{{and value slots{21286
{{brn{6,gtar3{{{loop back for next teblk{21287
*      here after scanning teblks on one chain
{gtar6{bne{8,wa{9,(xs){6,gtar2{loop back if more buckets to go{21291
{{bnz{7,xr{6,gtar7{{else jump if second pass{21292
*      here after counting non-null elements
{{bze{8,wb{6,gtar9{{fail if no non-null elements{21296
{{mov{8,wa{8,wb{{else copy count{21297
{{add{8,wa{8,wb{{double (two words/element){21298
{{add{8,wa{18,=arvl2{{add space for standard fields{21299
{{wtb{8,wa{{{convert length to bytes{21300
{{bgt{8,wa{3,mxlen{6,gta9b{error if too long for array{21301
{{jsr{6,alloc{{{else allocate space for arblk{21302
{{mov{9,(xr){22,=b_art{{store type word{21303
{{zer{13,idval(xr){{{zero id for the moment{21304
{{mov{13,arlen(xr){8,wa{{store length{21305
{{mov{13,arndm(xr){18,=num02{{set dimensions = 2{21306
{{ldi{4,intv1{{{get integer one{21307
{{sti{13,arlbd(xr){{{store as lbd 1{21308
{{sti{13,arlb2(xr){{{store as lbd 2{21309
{{ldi{4,intv2{{{load integer two{21310
{{sti{13,ardm2(xr){{{store as dim 2{21311
{{mti{8,wb{{{get element count as integer{21312
{{sti{13,ardim(xr){{{store as dim 1{21313
{{zer{13,arpr2(xr){{{zero prototype field for now{21314
{{mov{13,arofs(xr){19,*arpr2{{set offset field (signal pass 2){21315
{{mov{8,wb{7,xr{{save arblk pointer{21316
{{add{7,xr{19,*arvl2{{point to first element location{21317
{{brn{6,gtar1{{{jump back to fill in elements{21318
{{ejc{{{{{21319
*      gtarr (continued)
*      here after filling in element values
{gtar7{mov{7,xr{8,wb{{restore arblk pointer{21325
{{mov{9,(xs){8,wb{{store as result{21326
*      now we need the array prototype which is of the form nn,2
*      this is obtained by building the string for nn02 and
*      changing the zero to a comma before storing it.
{{ldi{13,ardim(xr){{{get number of elements (nn){21332
{{mli{4,intvh{{{multiply by 100{21333
{{adi{4,intv2{{{add 2 (nn02){21334
{{jsr{6,icbld{{{build integer{21335
{{mov{11,-(xs){7,xr{{store ptr for gtstg{21336
{{jsr{6,gtstg{{{convert to string{21337
{{ppm{{{{convert fail is impossible{21338
{{mov{7,xl{7,xr{{copy string pointer{21339
{{mov{7,xr{10,(xs)+{{reload arblk pointer{21340
{{mov{13,arpr2(xr){7,xl{{store prototype ptr (nn02){21341
{{sub{8,wa{18,=num02{{adjust length to point to zero{21342
{{psc{7,xl{8,wa{{point to zero{21343
{{mov{8,wb{18,=ch_cm{{load a comma{21344
{{sch{8,wb{9,(xl){{store a comma over the zero{21345
{{csc{7,xl{{{complete store characters{21346
*      normal return
{gtar8{exi{{{{return to caller{21350
*      null table non-conversion return
{gtar9{mov{7,xr{10,(xs)+{{restore stack for conv err (sgd02){21354
{{exi{1,1{{{return{21355
*      impossible conversion return
{gta9a{exi{1,2{{{return{21359
*      array size too large
{gta9b{erb{1,260{26,conversion array size exceeds maximum permitted{{{21363
{{enp{{{{procedure gtarr{21364
{{ejc{{{{{21365
*      gtcod -- convert to code
*      (xr)                  object to be converted
*      jsr  gtcod            call to convert to code
*      ppm  loc              transfer loc if convert impossible
*      (xr)                  pointer to resulting cdblk
*      (xl,wa,wb,wc,ra)      destroyed
*      if a spitbol error occurs during compilation or pre-
*      evaluation, control is passed via error section to exfal
*      without returning to this routine.
{gtcod{prc{25,e{1,1{{entry point{21379
{{beq{9,(xr){22,=b_cds{6,gtcd1{jump if already code{21380
{{beq{9,(xr){22,=b_cdc{6,gtcd1{jump if already code{21381
*      here we must generate a cdblk by compilation
{{mov{11,-(xs){7,xr{{stack argument for gtstg{21385
{{jsr{6,gtstg{{{convert argument to string{21386
{{ppm{6,gtcd2{{{jump if non-convertible{21387
{{mov{3,gtcef{3,flptr{{save fail ptr in case of error{21388
{{mov{3,r_gtc{3,r_cod{{also save code ptr{21389
{{mov{3,r_cim{7,xr{{else set image pointer{21390
{{mov{3,scnil{8,wa{{set image length{21391
{{zer{3,scnpt{{{set scan pointer{21392
{{mov{3,stage{18,=stgxc{{set stage for execute compile{21393
{{mov{3,lstsn{3,cmpsn{{in case listr called{21394
{{icv{3,cmpln{{{bump line number{21396
{{jsr{6,cmpil{{{compile string{21398
{{mov{3,stage{18,=stgxt{{reset stage for execute time{21399
{{zer{3,r_cim{{{clear image{21400
*      merge here if no convert required
{gtcd1{exi{{{{give normal gtcod return{21404
*      here if unconvertible
{gtcd2{exi{1,1{{{give error return{21408
{{enp{{{{end procedure gtcod{21409
{{ejc{{{{{21410
*      gtexp -- convert to expression
*      (wb)                  0 if by value, 1 if by name
*      (xr)                  input value to be converted
*      jsr  gtexp            call to convert to expression
*      ppm  loc              transfer loc if convert impossible
*      (xr)                  pointer to result exblk or seblk
*      (xl,wa,wb,wc,ra)      destroyed
*      if a spitbol error occurs during compilation or pre-
*      evaluation, control is passed via error section to exfal
*      without returning to this routine.
{gtexp{prc{25,e{1,1{{entry point{21427
{{blo{9,(xr){22,=b_e__{6,gtex1{jump if already an expression{21428
{{mov{11,-(xs){7,xr{{store argument for gtstg{21429
{{jsr{6,gtstg{{{convert argument to string{21430
{{ppm{6,gtex2{{{jump if unconvertible{21431
*      check the last character of the string for colon or
*      semicolon.  these characters can legitimately end an
*      expression in open code, so expan will not detect them
*      as errors, but they are invalid as terminators for a
*      string that is being converted to expression form.
{{mov{7,xl{7,xr{{copy input string pointer{21439
{{plc{7,xl{8,wa{{point one past the string end{21440
{{lch{7,xl{11,-(xl){{fetch the last character{21441
{{beq{7,xl{18,=ch_cl{6,gtex2{error if it is a semicolon{21442
{{beq{7,xl{18,=ch_sm{6,gtex2{or if it is a colon{21443
*      here we convert a string by compilation
{{mov{3,r_cim{7,xr{{set input image pointer{21447
{{zer{3,scnpt{{{set scan pointer{21448
{{mov{3,scnil{8,wa{{set input image length{21449
{{mov{11,-(xs){8,wb{{save value/name flag{21451
{{zer{8,wb{{{set code for normal scan{21453
{{mov{3,gtcef{3,flptr{{save fail ptr in case of error{21454
{{mov{3,r_gtc{3,r_cod{{also save code ptr{21455
{{mov{3,stage{18,=stgev{{adjust stage for compile{21456
{{mov{3,scntp{18,=t_uok{{indicate unary operator acceptable{21457
{{jsr{6,expan{{{build tree for expression{21458
{{zer{3,scnrs{{{reset rescan flag{21459
{{mov{8,wa{10,(xs)+{{restore value/name flag{21461
{{bne{3,scnpt{3,scnil{6,gtex2{error if not end of image{21463
{{zer{8,wb{{{set ok value for cdgex call{21464
{{mov{7,xl{7,xr{{copy tree pointer{21465
{{jsr{6,cdgex{{{build expression block{21466
{{zer{3,r_cim{{{clear pointer{21467
{{mov{3,stage{18,=stgxt{{restore stage for execute time{21468
*      merge here if no conversion required
{gtex1{exi{{{{return to gtexp caller{21472
*      here if unconvertible
{gtex2{exi{1,1{{{take error exit{21476
{{enp{{{{end procedure gtexp{21477
{{ejc{{{{{21478
*      gtint -- get integer value
*      gtint is passed an object and returns an integer after
*      performing any necessary conversions.
*      (xr)                  value to be converted
*      jsr  gtint            call to convert to integer
*      ppm  loc              transfer loc for convert impossible
*      (xr)                  resulting integer
*      (wc,ra)               destroyed
*      (wa,wb)               destroyed (only on conversion err)
*      (xr)                  unchanged (on convert error)
{gtint{prc{25,e{1,1{{entry point{21493
{{beq{9,(xr){22,=b_icl{6,gtin2{jump if already an integer{21494
{{mov{3,gtina{8,wa{{else save wa{21495
{{mov{3,gtinb{8,wb{{save wb{21496
{{jsr{6,gtnum{{{convert to numeric{21497
{{ppm{6,gtin3{{{jump if unconvertible{21498
{{beq{8,wa{22,=b_icl{6,gtin1{jump if integer{21501
*      here we convert a real to integer
{{ldr{13,rcval(xr){{{load real value{21505
{{rti{6,gtin3{{{convert to integer (err if ovflow){21506
{{jsr{6,icbld{{{if ok build icblk{21507
*      here after successful conversion to integer
{gtin1{mov{8,wa{3,gtina{{restore wa{21512
{{mov{8,wb{3,gtinb{{restore wb{21513
*      common exit point
{gtin2{exi{{{{return to gtint caller{21517
*      here on conversion error
{gtin3{exi{1,1{{{take convert error exit{21521
{{enp{{{{end procedure gtint{21522
{{ejc{{{{{21523
*      gtnum -- get numeric value
*      gtnum is given an object and returns either an integer
*      or a real, performing any necessary conversions.
*      (xr)                  object to be converted
*      jsr  gtnum            call to convert to numeric
*      ppm  loc              transfer loc if convert impossible
*      (xr)                  pointer to result (int or real)
*      (wa)                  first word of result block
*      (wb,wc,ra)            destroyed
*      (xr)                  unchanged (on convert error)
{gtnum{prc{25,e{1,1{{entry point{21538
{{mov{8,wa{9,(xr){{load first word of block{21539
{{beq{8,wa{22,=b_icl{6,gtn34{jump if integer (no conversion){21540
{{beq{8,wa{22,=b_rcl{6,gtn34{jump if real (no conversion){21543
*      at this point the only possibility is to convert a string
*      to an integer or real as appropriate.
{{mov{11,-(xs){7,xr{{stack argument in case convert err{21549
{{mov{11,-(xs){7,xr{{stack argument for gtstg{21550
{{jsr{6,gtstg{{{convert argument to string{21552
{{ppm{6,gtn36{{{jump if unconvertible{21556
*      initialize numeric conversion
{{ldi{4,intv0{{{initialize integer result to zero{21560
{{bze{8,wa{6,gtn32{{jump to exit with zero if null{21561
{{lct{8,wa{8,wa{{set bct counter for following loops{21562
{{zer{3,gtnnf{{{tentatively indicate result +{21563
{{sti{3,gtnex{{{initialise exponent to zero{21566
{{zer{3,gtnsc{{{zero scale in case real{21567
{{zer{3,gtndf{{{reset flag for dec point found{21568
{{zer{3,gtnrd{{{reset flag for digits found{21569
{{ldr{4,reav0{{{zero real accum in case real{21570
{{plc{7,xr{{{point to argument characters{21572
*      merge back here after ignoring leading blank
{gtn01{lch{8,wb{10,(xr)+{{load first character{21576
{{blt{8,wb{18,=ch_d0{6,gtn02{jump if not digit{21577
{{ble{8,wb{18,=ch_d9{6,gtn06{jump if first char is a digit{21578
{{ejc{{{{{21579
*      gtnum (continued)
*      here if first digit is non-digit
{gtn02{bne{8,wb{18,=ch_bl{6,gtn03{jump if non-blank{21585
{gtna2{bct{8,wa{6,gtn01{{else decr count and loop back{21586
{{brn{6,gtn07{{{jump to return zero if all blanks{21587
*      here for first character non-blank, non-digit
{gtn03{beq{8,wb{18,=ch_pl{6,gtn04{jump if plus sign{21591
{{beq{8,wb{18,=ch_ht{6,gtna2{horizontal tab equiv to blank{21593
{{bne{8,wb{18,=ch_mn{6,gtn12{jump if not minus (may be real){21601
{{mnz{3,gtnnf{{{if minus sign, set negative flag{21603
*      merge here after processing sign
{gtn04{bct{8,wa{6,gtn05{{jump if chars left{21607
{{brn{6,gtn36{{{else error{21608
*      loop to fetch characters of an integer
{gtn05{lch{8,wb{10,(xr)+{{load next character{21612
{{blt{8,wb{18,=ch_d0{6,gtn08{jump if not a digit{21613
{{bgt{8,wb{18,=ch_d9{6,gtn08{jump if not a digit{21614
*      merge here for first digit
{gtn06{sti{3,gtnsi{{{save current value{21618
{{cvm{6,gtn35{{{current*10-(new dig) jump if ovflow{21622
{{mnz{3,gtnrd{{{set digit read flag{21623
{{bct{8,wa{6,gtn05{{else loop back if more chars{21625
*      here to exit with converted integer value
{gtn07{bnz{3,gtnnf{6,gtn32{{jump if negative (all set){21629
{{ngi{{{{else negate{21630
{{ino{6,gtn32{{{jump if no overflow{21631
{{brn{6,gtn36{{{else signal error{21632
{{ejc{{{{{21633
*      gtnum (continued)
*      here for a non-digit character while attempting to
*      convert an integer, check for trailing blanks or real.
{gtn08{beq{8,wb{18,=ch_bl{6,gtna9{jump if a blank{21640
{{beq{8,wb{18,=ch_ht{6,gtna9{jump if horizontal tab{21642
{{itr{{{{else convert integer to real{21650
{{ngr{{{{negate to get positive value{21651
{{brn{6,gtn12{{{jump to try for real{21652
*      here we scan out blanks to end of string
{gtn09{lch{8,wb{10,(xr)+{{get next char{21657
{{beq{8,wb{18,=ch_ht{6,gtna9{jump if horizontal tab{21659
{{bne{8,wb{18,=ch_bl{6,gtn36{error if non-blank{21664
{gtna9{bct{8,wa{6,gtn09{{loop back if more chars to check{21665
{{brn{6,gtn07{{{return integer if all blanks{21666
*      loop to collect mantissa of real
{gtn10{lch{8,wb{10,(xr)+{{load next character{21672
{{blt{8,wb{18,=ch_d0{6,gtn12{jump if non-numeric{21673
{{bgt{8,wb{18,=ch_d9{6,gtn12{jump if non-numeric{21674
*      merge here to collect first real digit
{gtn11{sub{8,wb{18,=ch_d0{{convert digit to number{21678
{{mlr{4,reavt{{{multiply real by 10.0{21679
{{rov{6,gtn36{{{convert error if overflow{21680
{{str{3,gtnsr{{{save result{21681
{{mti{8,wb{{{get new digit as integer{21682
{{itr{{{{convert new digit to real{21683
{{adr{3,gtnsr{{{add to get new total{21684
{{add{3,gtnsc{3,gtndf{{increment scale if after dec point{21685
{{mnz{3,gtnrd{{{set digit found flag{21686
{{bct{8,wa{6,gtn10{{loop back if more chars{21687
{{brn{6,gtn22{{{else jump to scale{21688
{{ejc{{{{{21689
*      gtnum (continued)
*      here if non-digit found while collecting a real
{gtn12{bne{8,wb{18,=ch_dt{6,gtn13{jump if not dec point{21695
{{bnz{3,gtndf{6,gtn36{{if dec point, error if one already{21696
{{mov{3,gtndf{18,=num01{{else set flag for dec point{21697
{{bct{8,wa{6,gtn10{{loop back if more chars{21698
{{brn{6,gtn22{{{else jump to scale{21699
*      here if not decimal point
{gtn13{beq{8,wb{18,=ch_le{6,gtn15{jump if e for exponent{21703
{{beq{8,wb{18,=ch_ld{6,gtn15{jump if d for exponent{21704
*      here check for trailing blanks
{gtn14{beq{8,wb{18,=ch_bl{6,gtnb4{jump if blank{21712
{{beq{8,wb{18,=ch_ht{6,gtnb4{jump if horizontal tab{21714
{{brn{6,gtn36{{{error if non-blank{21719
{gtnb4{lch{8,wb{10,(xr)+{{get next character{21721
{{bct{8,wa{6,gtn14{{loop back to check if more{21722
{{brn{6,gtn22{{{else jump to scale{21723
*      here to read and process an exponent
{gtn15{zer{3,gtnes{{{set exponent sign positive{21727
{{ldi{4,intv0{{{initialize exponent to zero{21728
{{mnz{3,gtndf{{{reset no dec point indication{21729
{{bct{8,wa{6,gtn16{{jump skipping past e or d{21730
{{brn{6,gtn36{{{error if null exponent{21731
*      check for exponent sign
{gtn16{lch{8,wb{10,(xr)+{{load first exponent character{21735
{{beq{8,wb{18,=ch_pl{6,gtn17{jump if plus sign{21736
{{bne{8,wb{18,=ch_mn{6,gtn19{else jump if not minus sign{21737
{{mnz{3,gtnes{{{set sign negative if minus sign{21738
*      merge here after processing exponent sign
{gtn17{bct{8,wa{6,gtn18{{jump if chars left{21742
{{brn{6,gtn36{{{else error{21743
*      loop to convert exponent digits
{gtn18{lch{8,wb{10,(xr)+{{load next character{21747
{{ejc{{{{{21748
*      gtnum (continued)
*      merge here for first exponent digit
{gtn19{blt{8,wb{18,=ch_d0{6,gtn20{jump if not digit{21754
{{bgt{8,wb{18,=ch_d9{6,gtn20{jump if not digit{21755
{{cvm{6,gtn36{{{else current*10, subtract new digit{21756
{{bct{8,wa{6,gtn18{{loop back if more chars{21757
{{brn{6,gtn21{{{jump if exponent field is exhausted{21758
*      here to check for trailing blanks after exponent
{gtn20{beq{8,wb{18,=ch_bl{6,gtnc0{jump if blank{21762
{{beq{8,wb{18,=ch_ht{6,gtnc0{jump if horizontal tab{21764
{{brn{6,gtn36{{{error if non-blank{21769
{gtnc0{lch{8,wb{10,(xr)+{{get next character{21771
{{bct{8,wa{6,gtn20{{loop back till all blanks scanned{21772
*      merge here after collecting exponent
{gtn21{sti{3,gtnex{{{save collected exponent{21776
{{bnz{3,gtnes{6,gtn22{{jump if it was negative{21777
{{ngi{{{{else complement{21778
{{iov{6,gtn36{{{error if overflow{21779
{{sti{3,gtnex{{{and store positive exponent{21780
*      merge here with exponent (0 if none given)
{gtn22{bze{3,gtnrd{6,gtn36{{error if not digits collected{21784
{{bze{3,gtndf{6,gtn36{{error if no exponent or dec point{21785
{{mti{3,gtnsc{{{else load scale as integer{21786
{{sbi{3,gtnex{{{subtract exponent{21787
{{iov{6,gtn36{{{error if overflow{21788
{{ilt{6,gtn26{{{jump if we must scale up{21789
*      here we have a negative exponent, so scale down
{{mfi{8,wa{6,gtn36{{load scale factor, err if ovflow{21793
*      loop to scale down in steps of 10**10
{gtn23{ble{8,wa{18,=num10{6,gtn24{jump if 10 or less to go{21797
{{dvr{4,reatt{{{else divide by 10**10{21798
{{sub{8,wa{18,=num10{{decrement scale{21799
{{brn{6,gtn23{{{and loop back{21800
{{ejc{{{{{21801
*      gtnum (continued)
*      here scale rest of way from powers of ten table
{gtn24{bze{8,wa{6,gtn30{{jump if scaled{21807
{{lct{8,wb{18,=cfp_r{{else get indexing factor{21808
{{mov{7,xr{21,=reav1{{point to powers of ten table{21809
{{wtb{8,wa{{{convert remaining scale to byte ofs{21810
*      loop to point to powers of ten table entry
{gtn25{add{7,xr{8,wa{{bump pointer{21814
{{bct{8,wb{6,gtn25{{once for each value word{21815
{{dvr{9,(xr){{{scale down as required{21816
{{brn{6,gtn30{{{and jump{21817
*      come here to scale result up (positive exponent)
{gtn26{ngi{{{{get absolute value of exponent{21821
{{iov{6,gtn36{{{error if overflow{21822
{{mfi{8,wa{6,gtn36{{acquire scale, error if ovflow{21823
*      loop to scale up in steps of 10**10
{gtn27{ble{8,wa{18,=num10{6,gtn28{jump if 10 or less to go{21827
{{mlr{4,reatt{{{else multiply by 10**10{21828
{{rov{6,gtn36{{{error if overflow{21829
{{sub{8,wa{18,=num10{{else decrement scale{21830
{{brn{6,gtn27{{{and loop back{21831
*      here to scale up rest of way with table
{gtn28{bze{8,wa{6,gtn30{{jump if scaled{21835
{{lct{8,wb{18,=cfp_r{{else get indexing factor{21836
{{mov{7,xr{21,=reav1{{point to powers of ten table{21837
{{wtb{8,wa{{{convert remaining scale to byte ofs{21838
*      loop to point to proper entry in powers of ten table
{gtn29{add{7,xr{8,wa{{bump pointer{21842
{{bct{8,wb{6,gtn29{{once for each word in value{21843
{{mlr{9,(xr){{{scale up{21844
{{rov{6,gtn36{{{error if overflow{21845
{{ejc{{{{{21846
*      gtnum (continued)
*      here with real value scaled and ready except for sign
{gtn30{bze{3,gtnnf{6,gtn31{{jump if positive{21852
{{ngr{{{{else negate{21853
*      here with properly signed real value in (ra)
{gtn31{jsr{6,rcbld{{{build real block{21857
{{brn{6,gtn33{{{merge to exit{21858
*      here with properly signed integer value in (ia)
{gtn32{jsr{6,icbld{{{build icblk{21863
*      real merges here
{gtn33{mov{8,wa{9,(xr){{load first word of result block{21867
{{ica{7,xs{{{pop argument off stack{21868
*      common exit point
{gtn34{exi{{{{return to gtnum caller{21872
*      come here if overflow occurs during collection of integer
*      have to restore wb which cvm may have destroyed.
{gtn35{lch{8,wb{11,-(xr){{reload current character{21879
{{lch{8,wb{10,(xr)+{{bump character pointer{21880
{{ldi{3,gtnsi{{{reload integer so far{21881
{{itr{{{{convert to real{21882
{{ngr{{{{make value positive{21883
{{brn{6,gtn11{{{merge with real circuit{21884
*      here for unconvertible to string or conversion error
{gtn36{mov{7,xr{10,(xs)+{{reload original argument{21889
{{exi{1,1{{{take convert-error exit{21890
{{enp{{{{end procedure gtnum{21891
{{ejc{{{{{21892
*      gtnvr -- convert to natural variable
*      gtnvr locates a variable block (vrblk) given either an
*      appropriate name (nmblk) or a non-null string (scblk).
*      (xr)                  argument
*      jsr  gtnvr            call to convert to natural variable
*      ppm  loc              transfer loc if convert impossible
*      (xr)                  pointer to vrblk
*      (wa,wb)               destroyed (conversion error only)
*      (wc)                  destroyed
{gtnvr{prc{25,e{1,1{{entry point{21906
*z-
{{bne{9,(xr){22,=b_nml{6,gnv02{jump if not name{21908
{{mov{7,xr{13,nmbas(xr){{else load name base if name{21909
{{blo{7,xr{3,state{6,gnv07{skip if vrblk (in static region){21910
*      common error exit
{gnv01{exi{1,1{{{take convert-error exit{21914
*      here if not name
{gnv02{mov{3,gnvsa{8,wa{{save wa{21918
{{mov{3,gnvsb{8,wb{{save wb{21919
{{mov{11,-(xs){7,xr{{stack argument for gtstg{21920
{{jsr{6,gtstg{{{convert argument to string{21921
{{ppm{6,gnv01{{{jump if conversion error{21922
{{bze{8,wa{6,gnv01{{null string is an error{21923
{{mov{11,-(xs){7,xl{{save xl{21927
{{mov{11,-(xs){7,xr{{stack string ptr for later{21928
{{mov{8,wb{7,xr{{copy string pointer{21929
{{add{8,wb{19,*schar{{point to characters of string{21930
{{mov{3,gnvst{8,wb{{save pointer to characters{21931
{{mov{8,wb{8,wa{{copy length{21932
{{ctw{8,wb{1,0{{get number of words in name{21933
{{mov{3,gnvnw{8,wb{{save for later{21934
{{jsr{6,hashs{{{compute hash index for string{21935
{{rmi{3,hshnb{{{compute hash offset by taking mod{21936
{{mfi{8,wc{{{get as offset{21937
{{wtb{8,wc{{{convert offset to bytes{21938
{{add{8,wc{3,hshtb{{point to proper hash chain{21939
{{sub{8,wc{19,*vrnxt{{subtract offset to merge into loop{21940
{{ejc{{{{{21941
*      gtnvr (continued)
*      loop to search hash chain
{gnv03{mov{7,xl{8,wc{{copy hash chain pointer{21947
{{mov{7,xl{13,vrnxt(xl){{point to next vrblk on chain{21948
{{bze{7,xl{6,gnv08{{jump if end of chain{21949
{{mov{8,wc{7,xl{{save pointer to this vrblk{21950
{{bnz{13,vrlen(xl){6,gnv04{{jump if not system variable{21951
{{mov{7,xl{13,vrsvp(xl){{else point to svblk{21952
{{sub{7,xl{19,*vrsof{{adjust offset for merge{21953
*      merge here with string ptr (like vrblk) in xl
{gnv04{bne{8,wa{13,vrlen(xl){6,gnv03{back for next vrblk if lengths ne{21957
{{add{7,xl{19,*vrchs{{else point to chars of chain entry{21958
{{lct{8,wb{3,gnvnw{{get word counter to control loop{21959
{{mov{7,xr{3,gnvst{{point to chars of new name{21960
*      loop to compare characters of the two names
{gnv05{cne{9,(xr){9,(xl){6,gnv03{jump if no match for next vrblk{21964
{{ica{7,xr{{{bump new name pointer{21965
{{ica{7,xl{{{bump vrblk in chain name pointer{21966
{{bct{8,wb{6,gnv05{{else loop till all compared{21967
{{mov{7,xr{8,wc{{we have found a match, get vrblk{21968
*      exit point after finding vrblk or building new one
{gnv06{mov{8,wa{3,gnvsa{{restore wa{21972
{{mov{8,wb{3,gnvsb{{restore wb{21973
{{ica{7,xs{{{pop string pointer{21974
{{mov{7,xl{10,(xs)+{{restore xl{21975
*      common exit point
{gnv07{exi{{{{return to gtnvr caller{21979
*      not found, prepare to search system variable table
{gnv08{zer{7,xr{{{clear garbage xr pointer{21983
{{mov{3,gnvhe{8,wc{{save ptr to end of hash chain{21984
{{bgt{8,wa{18,=num09{6,gnv14{cannot be system var if length gt 9{21985
{{mov{7,xl{8,wa{{else copy length{21986
{{wtb{7,xl{{{convert to byte offset{21987
{{mov{7,xl{14,vsrch(xl){{point to first svblk of this length{21988
{{ejc{{{{{21989
*      gtnvr (continued)
*      loop to search entries in standard variable table
{gnv09{mov{3,gnvsp{7,xl{{save table pointer{21995
{{mov{8,wc{10,(xl)+{{load svbit bit string{21996
{{mov{8,wb{10,(xl)+{{load length from table entry{21997
{{bne{8,wa{8,wb{6,gnv14{jump if end of right length entries{21998
{{lct{8,wb{3,gnvnw{{get word counter to control loop{21999
{{mov{7,xr{3,gnvst{{point to chars of new name{22000
*      loop to check for matching names
{gnv10{cne{9,(xr){9,(xl){6,gnv11{jump if name mismatch{22004
{{ica{7,xr{{{else bump new name pointer{22005
{{ica{7,xl{{{bump svblk pointer{22006
{{bct{8,wb{6,gnv10{{else loop until all checked{22007
*      here we have a match in the standard variable table
{{zer{8,wc{{{set vrlen value zero{22011
{{mov{8,wa{19,*vrsi_{{set standard size{22012
{{brn{6,gnv15{{{jump to build vrblk{22013
*      here if no match with table entry in svblks table
{gnv11{ica{7,xl{{{bump past word of chars{22017
{{bct{8,wb{6,gnv11{{loop back if more to go{22018
{{rsh{8,wc{2,svnbt{{remove uninteresting bits{22019
*      loop to bump table ptr for each flagged word
{gnv12{mov{8,wb{4,bits1{{load bit to test{22023
{{anb{8,wb{8,wc{{test for word present{22024
{{zrb{8,wb{6,gnv13{{jump if not present{22025
{{ica{7,xl{{{else bump table pointer{22026
*      here after dealing with one word (one bit)
{gnv13{rsh{8,wc{1,1{{remove bit already processed{22030
{{nzb{8,wc{6,gnv12{{loop back if more bits to test{22031
{{brn{6,gnv09{{{else loop back for next svblk{22032
*      here if not system variable
{gnv14{mov{8,wc{8,wa{{copy vrlen value{22036
{{mov{8,wa{18,=vrchs{{load standard size -chars{22037
{{add{8,wa{3,gnvnw{{adjust for chars of name{22038
{{wtb{8,wa{{{convert length to bytes{22039
{{ejc{{{{{22040
*      gtnvr (continued)
*      merge here to build vrblk
{gnv15{jsr{6,alost{{{allocate space for vrblk (static){22046
{{mov{8,wb{7,xr{{save vrblk pointer{22047
{{mov{7,xl{21,=stnvr{{point to model variable block{22048
{{mov{8,wa{19,*vrlen{{set length of standard fields{22049
{{mvw{{{{set initial fields of new block{22050
{{mov{7,xl{3,gnvhe{{load pointer to end of hash chain{22051
{{mov{13,vrnxt(xl){8,wb{{add new block to end of chain{22052
{{mov{10,(xr)+{8,wc{{set vrlen field, bump ptr{22053
{{mov{8,wa{3,gnvnw{{get length in words{22054
{{wtb{8,wa{{{convert to length in bytes{22055
{{bze{8,wc{6,gnv16{{jump if system variable{22056
*      here for non-system variable -- set chars of name
{{mov{7,xl{9,(xs){{point back to string name{22060
{{add{7,xl{19,*schar{{point to chars of name{22061
{{mvw{{{{move characters into place{22062
{{mov{7,xr{8,wb{{restore vrblk pointer{22063
{{brn{6,gnv06{{{jump back to exit{22064
*      here for system variable case to fill in fields where
*      necessary from the fields present in the svblk.
{gnv16{mov{7,xl{3,gnvsp{{load pointer to svblk{22069
{{mov{9,(xr){7,xl{{set svblk ptr in vrblk{22070
{{mov{7,xr{8,wb{{restore vrblk pointer{22071
{{mov{8,wb{13,svbit(xl){{load bit indicators{22072
{{add{7,xl{19,*svchs{{point to characters of name{22073
{{add{7,xl{8,wa{{point past characters{22074
*      skip past keyword number (svknm) if present
{{mov{8,wc{4,btknm{{load test bit{22078
{{anb{8,wc{8,wb{{and to test{22079
{{zrb{8,wc{6,gnv17{{jump if no keyword number{22080
{{ica{7,xl{{{else bump pointer{22081
{{ejc{{{{{22082
*      gtnvr (continued)
*      here test for function (svfnc and svnar)
{gnv17{mov{8,wc{4,btfnc{{get test bit{22088
{{anb{8,wc{8,wb{{and to test{22089
{{zrb{8,wc{6,gnv18{{skip if no system function{22090
{{mov{13,vrfnc(xr){7,xl{{else point vrfnc to svfnc field{22091
{{add{7,xl{19,*num02{{and bump past svfnc, svnar fields{22092
*      now test for label (svlbl)
{gnv18{mov{8,wc{4,btlbl{{get test bit{22096
{{anb{8,wc{8,wb{{and to test{22097
{{zrb{8,wc{6,gnv19{{jump if bit is off (no system labl){22098
{{mov{13,vrlbl(xr){7,xl{{else point vrlbl to svlbl field{22099
{{ica{7,xl{{{bump past svlbl field{22100
*      now test for value (svval)
{gnv19{mov{8,wc{4,btval{{load test bit{22104
{{anb{8,wc{8,wb{{and to test{22105
{{zrb{8,wc{6,gnv06{{all done if no value{22106
{{mov{13,vrval(xr){9,(xl){{else set initial value{22107
{{mov{13,vrsto(xr){22,=b_vre{{set error store access{22108
{{brn{6,gnv06{{{merge back to exit to caller{22109
{{enp{{{{end procedure gtnvr{22110
{{ejc{{{{{22111
*      gtpat -- get pattern
*      gtpat is passed an object in (xr) and returns a
*      pattern after performing any necessary conversions
*      (xr)                  input argument
*      jsr  gtpat            call to convert to pattern
*      ppm  loc              transfer loc if convert impossible
*      (xr)                  resulting pattern
*      (wa)                  destroyed
*      (wb)                  destroyed (only on convert error)
*      (xr)                  unchanged (only on convert error)
{gtpat{prc{25,e{1,1{{entry point{22126
*z+
{{bhi{9,(xr){22,=p_aaa{6,gtpt5{jump if pattern already{22128
*      here if not pattern, try for string
{{mov{3,gtpsb{8,wb{{save wb{22132
{{mov{11,-(xs){7,xr{{stack argument for gtstg{22133
{{jsr{6,gtstg{{{convert argument to string{22134
{{ppm{6,gtpt2{{{jump if impossible{22135
*      here we have a string
{{bnz{8,wa{6,gtpt1{{jump if non-null{22139
*      here for null string. generate pointer to null pattern.
{{mov{7,xr{21,=ndnth{{point to nothen node{22143
{{brn{6,gtpt4{{{jump to exit{22144
{{ejc{{{{{22145
*      gtpat (continued)
*      here for non-null string
{gtpt1{mov{8,wb{22,=p_str{{load pcode for multi-char string{22151
{{bne{8,wa{18,=num01{6,gtpt3{jump if multi-char string{22152
*      here for one character string, share one character any
{{plc{7,xr{{{point to character{22156
{{lch{8,wa{9,(xr){{load character{22157
{{mov{7,xr{8,wa{{set as parm1{22158
{{mov{8,wb{22,=p_ans{{point to pcode for 1-char any{22159
{{brn{6,gtpt3{{{jump to build node{22160
*      here if argument is not convertible to string
{gtpt2{mov{8,wb{22,=p_exa{{set pcode for expression in case{22164
{{blo{9,(xr){22,=b_e__{6,gtpt3{jump to build node if expression{22165
*      here we have an error (conversion impossible)
{{exi{1,1{{{take convert error exit{22169
*      merge here to build node for string or expression
{gtpt3{jsr{6,pbild{{{call routine to build pattern node{22173
*      common exit after successful conversion
{gtpt4{mov{8,wb{3,gtpsb{{restore wb{22177
*      merge here to exit if no conversion required
{gtpt5{exi{{{{return to gtpat caller{22181
{{enp{{{{end procedure gtpat{22182
{{ejc{{{{{22185
*      gtrea -- get real value
*      gtrea is passed an object and returns a real value
*      performing any necessary conversions.
*      (xr)                  object to be converted
*      jsr  gtrea            call to convert object to real
*      ppm  loc              transfer loc if convert impossible
*      (xr)                  pointer to resulting real
*      (wa,wb,wc,ra)         destroyed
*      (xr)                  unchanged (convert error only)
{gtrea{prc{25,e{1,1{{entry point{22199
{{mov{8,wa{9,(xr){{get first word of block{22200
{{beq{8,wa{22,=b_rcl{6,gtre2{jump if real{22201
{{jsr{6,gtnum{{{else convert argument to numeric{22202
{{ppm{6,gtre3{{{jump if unconvertible{22203
{{beq{8,wa{22,=b_rcl{6,gtre2{jump if real was returned{22204
*      here for case of an integer to convert to real
{gtre1{ldi{13,icval(xr){{{load integer{22208
{{itr{{{{convert to real{22209
{{jsr{6,rcbld{{{build rcblk{22210
*      exit with real
{gtre2{exi{{{{return to gtrea caller{22214
*      here on conversion error
{gtre3{exi{1,1{{{take convert error exit{22218
{{enp{{{{end procedure gtrea{22219
{{ejc{{{{{22221
*      gtsmi -- get small integer
*      gtsmi is passed a snobol object and returns an address
*      integer in the range (0 le n le dnamb). such a value can
*      only be derived from an integer in the appropriate range.
*      small integers never appear as snobol values. however,
*      they are used internally for a variety of purposes.
*      -(xs)                 argument to convert (on stack)
*      jsr  gtsmi            call to convert to small integer
*      ppm  loc              transfer loc for not integer
*      ppm  loc              transfer loc for lt 0, gt dnamb
*      (xr,wc)               resulting small int (two copies)
*      (xs)                  popped
*      (ra)                  destroyed
*      (wa,wb)               destroyed (on convert error only)
*      (xr)                  input arg (convert error only)
{gtsmi{prc{25,n{1,2{{entry point{22241
{{mov{7,xr{10,(xs)+{{load argument{22242
{{beq{9,(xr){22,=b_icl{6,gtsm1{skip if already an integer{22243
*      here if not an integer
{{jsr{6,gtint{{{convert argument to integer{22247
{{ppm{6,gtsm2{{{jump if convert is impossible{22248
*      merge here with integer
{gtsm1{ldi{13,icval(xr){{{load integer value{22252
{{mfi{8,wc{6,gtsm3{{move as one word, jump if ovflow{22253
{{bgt{8,wc{3,mxlen{6,gtsm3{or if too large{22254
{{mov{7,xr{8,wc{{copy result to xr{22255
{{exi{{{{return to gtsmi caller{22256
*      here if unconvertible to integer
{gtsm2{exi{1,1{{{take non-integer error exit{22260
*      here if out of range
{gtsm3{exi{1,2{{{take out-of-range error exit{22264
{{enp{{{{end procedure gtsmi{22265
{{ejc{{{{{22266
*      gtstg -- get string
*      gtstg is passed an object and returns a string with
*      any necessary conversions performed.
*      -(xs)                 input argument (on stack)
*      jsr  gtstg            call to convert to string
*      ppm  loc              transfer loc if convert impossible
*      (xr)                  pointer to resulting string
*      (wa)                  length of string in characters
*      (xs)                  popped
*      (ra)                  destroyed
*      (xr)                  input arg (convert error only)
{gtstg{prc{25,n{1,1{{entry point{22332
{{mov{7,xr{10,(xs)+{{load argument, pop stack{22333
{{beq{9,(xr){22,=b_scl{6,gts30{jump if already a string{22334
*      here if not a string already
{gts01{mov{11,-(xs){7,xr{{restack argument in case error{22338
{{mov{11,-(xs){7,xl{{save xl{22339
{{mov{3,gtsvb{8,wb{{save wb{22340
{{mov{3,gtsvc{8,wc{{save wc{22341
{{mov{8,wa{9,(xr){{load first word of block{22342
{{beq{8,wa{22,=b_icl{6,gts05{jump to convert integer{22343
{{beq{8,wa{22,=b_rcl{6,gts10{jump to convert real{22346
{{beq{8,wa{22,=b_nml{6,gts03{jump to convert name{22348
*      here on conversion error
{gts02{mov{7,xl{10,(xs)+{{restore xl{22356
{{mov{7,xr{10,(xs)+{{reload input argument{22357
{{exi{1,1{{{take convert error exit{22358
{{ejc{{{{{22359
*      gtstg (continued)
*      here to convert a name (only possible if natural var)
{gts03{mov{7,xl{13,nmbas(xr){{load name base{22365
{{bhi{7,xl{3,state{6,gts02{error if not natural var (static){22366
{{add{7,xl{19,*vrsof{{else point to possible string name{22367
{{mov{8,wa{13,sclen(xl){{load length{22368
{{bnz{8,wa{6,gts04{{jump if not system variable{22369
{{mov{7,xl{13,vrsvo(xl){{else point to svblk{22370
{{mov{8,wa{13,svlen(xl){{and load name length{22371
*      merge here with string in xr, length in wa
{gts04{zer{8,wb{{{set offset to zero{22375
{{jsr{6,sbstr{{{use sbstr to copy string{22376
{{brn{6,gts29{{{jump to exit{22377
*      come here to convert an integer
{gts05{ldi{13,icval(xr){{{load integer value{22381
{{mov{3,gtssf{18,=num01{{set sign flag negative{22389
{{ilt{6,gts06{{{skip if integer is negative{22390
{{ngi{{{{else negate integer{22391
{{zer{3,gtssf{{{and reset negative flag{22392
{{ejc{{{{{22393
*      gtstg (continued)
*      here with sign flag set and sign forced negative as
*      required by the cvd instruction.
{gts06{mov{7,xr{3,gtswk{{point to result work area{22400
{{mov{8,wb{18,=nstmx{{initialize counter to max length{22401
{{psc{7,xr{8,wb{{prepare to store (right-left){22402
*      loop to convert digits into work area
{gts07{cvd{{{{convert one digit into wa{22406
{{sch{8,wa{11,-(xr){{store in work area{22407
{{dcv{8,wb{{{decrement counter{22408
{{ine{6,gts07{{{loop if more digits to go{22409
{{csc{7,xr{{{complete store characters{22410
*      merge here after converting integer or real into work
*      area. wb is set to nstmx - (number of chars in result).
{gts08{mov{8,wa{18,=nstmx{{get max number of characters{22416
{{sub{8,wa{8,wb{{compute length of result{22417
{{mov{7,xl{8,wa{{remember length for move later on{22418
{{add{8,wa{3,gtssf{{add one for negative sign if needed{22419
{{jsr{6,alocs{{{allocate string for result{22420
{{mov{8,wc{7,xr{{save result pointer for the moment{22421
{{psc{7,xr{{{point to chars of result block{22422
{{bze{3,gtssf{6,gts09{{skip if positive{22423
{{mov{8,wa{18,=ch_mn{{else load negative sign{22424
{{sch{8,wa{10,(xr)+{{and store it{22425
{{csc{7,xr{{{complete store characters{22426
*      here after dealing with sign
{gts09{mov{8,wa{7,xl{{recall length to move{22430
{{mov{7,xl{3,gtswk{{point to result work area{22431
{{plc{7,xl{8,wb{{point to first result character{22432
{{mvc{{{{move chars to result string{22433
{{mov{7,xr{8,wc{{restore result pointer{22434
{{brn{6,gts29{{{jump to exit{22437
{{ejc{{{{{22438
*      gtstg (continued)
*      here to convert a real
{gts10{ldr{13,rcval(xr){{{load real{22444
{{zer{3,gtssf{{{reset negative flag{22456
{{req{6,gts31{{{skip if zero{22457
{{rge{6,gts11{{{jump if real is positive{22458
{{mov{3,gtssf{18,=num01{{else set negative flag{22459
{{ngr{{{{and get absolute value of real{22460
*      now scale the real to the range (0.1 le x lt 1.0)
{gts11{ldi{4,intv0{{{initialize exponent to zero{22464
*      loop to scale up in steps of 10**10
{gts12{str{3,gtsrs{{{save real value{22468
{{sbr{4,reap1{{{subtract 0.1 to compare{22469
{{rge{6,gts13{{{jump if scale up not required{22470
{{ldr{3,gtsrs{{{else reload value{22471
{{mlr{4,reatt{{{multiply by 10**10{22472
{{sbi{4,intvt{{{decrement exponent by 10{22473
{{brn{6,gts12{{{loop back to test again{22474
*      test for scale down required
{gts13{ldr{3,gtsrs{{{reload value{22478
{{sbr{4,reav1{{{subtract 1.0{22479
{{rlt{6,gts17{{{jump if no scale down required{22480
{{ldr{3,gtsrs{{{else reload value{22481
*      loop to scale down in steps of 10**10
{gts14{sbr{4,reatt{{{subtract 10**10 to compare{22485
{{rlt{6,gts15{{{jump if large step not required{22486
{{ldr{3,gtsrs{{{else restore value{22487
{{dvr{4,reatt{{{divide by 10**10{22488
{{str{3,gtsrs{{{store new value{22489
{{adi{4,intvt{{{increment exponent by 10{22490
{{brn{6,gts14{{{loop back{22491
{{ejc{{{{{22492
*      gtstg (continued)
*      at this point we have (1.0 le x lt 10**10)
*      complete scaling with powers of ten table
{gts15{mov{7,xr{21,=reav1{{point to powers of ten table{22499
*      loop to locate correct entry in table
{gts16{ldr{3,gtsrs{{{reload value{22503
{{adi{4,intv1{{{increment exponent{22504
{{add{7,xr{19,*cfp_r{{point to next entry in table{22505
{{sbr{9,(xr){{{subtract it to compare{22506
{{rge{6,gts16{{{loop till we find a larger entry{22507
{{ldr{3,gtsrs{{{then reload the value{22508
{{dvr{9,(xr){{{and complete scaling{22509
{{str{3,gtsrs{{{store value{22510
*      we are now scaled, so round by adding 0.5 * 10**(-cfp_s)
{gts17{ldr{3,gtsrs{{{get value again{22514
{{adr{3,gtsrn{{{add rounding factor{22515
{{str{3,gtsrs{{{store result{22516
*      the rounding operation may have pushed us up past
*      1.0 again, so check one more time.
{{sbr{4,reav1{{{subtract 1.0 to compare{22521
{{rlt{6,gts18{{{skip if ok{22522
{{adi{4,intv1{{{else increment exponent{22523
{{ldr{3,gtsrs{{{reload value{22524
{{dvr{4,reavt{{{divide by 10.0 to rescale{22525
{{brn{6,gts19{{{jump to merge{22526
*      here if rounding did not muck up scaling
{gts18{ldr{3,gtsrs{{{reload rounded value{22530
{{ejc{{{{{22531
*      gtstg (continued)
*      now we have completed the scaling as follows
*      (ia)                  signed exponent
*      (ra)                  scaled real (absolute value)
*      if the exponent is negative or greater than cfp_s, then
*      we convert the number in the form.
*      (neg sign) 0 . (cpf_s digits) e (exp sign) (exp digits)
*      if the exponent is positive and less than or equal to
*      cfp_s, the number is converted in the form.
*      (neg sign) (exponent digits) . (cfp_s-exponent digits)
*      in both cases, the formats obtained from the above
*      rules are modified by deleting trailing zeros after the
*      decimal point. there are no leading zeros in the exponent
*      and the exponent sign is always present.
{gts19{mov{7,xl{18,=cfp_s{{set num dec digits = cfp_s{22555
{{mov{3,gtses{18,=ch_mn{{set exponent sign negative{22556
{{ilt{6,gts21{{{all set if exponent is negative{22557
{{mfi{8,wa{{{else fetch exponent{22558
{{ble{8,wa{18,=cfp_s{6,gts20{skip if we can use special format{22559
{{mti{8,wa{{{else restore exponent{22560
{{ngi{{{{set negative for cvd{22561
{{mov{3,gtses{18,=ch_pl{{set plus sign for exponent sign{22562
{{brn{6,gts21{{{jump to generate exponent{22563
*      here if we can use the format without an exponent
{gts20{sub{7,xl{8,wa{{compute digits after decimal point{22567
{{ldi{4,intv0{{{reset exponent to zero{22568
{{ejc{{{{{22569
*      gtstg (continued)
*      merge here as follows
*      (ia)                  exponent absolute value
*      gtses                 character for exponent sign
*      (ra)                  positive fraction
*      (xl)                  number of digits after dec point
{gts21{mov{7,xr{3,gtswk{{point to work area{22580
{{mov{8,wb{18,=nstmx{{set character ctr to max length{22581
{{psc{7,xr{8,wb{{prepare to store (right to left){22582
{{ieq{6,gts23{{{skip exponent if it is zero{22583
*      loop to generate digits of exponent
{gts22{cvd{{{{convert a digit into wa{22587
{{sch{8,wa{11,-(xr){{store in work area{22588
{{dcv{8,wb{{{decrement counter{22589
{{ine{6,gts22{{{loop back if more digits to go{22590
*      here generate exponent sign and e
{{mov{8,wa{3,gtses{{load exponent sign{22594
{{sch{8,wa{11,-(xr){{store in work area{22595
{{mov{8,wa{18,=ch_le{{get character letter e{22596
{{sch{8,wa{11,-(xr){{store in work area{22597
{{sub{8,wb{18,=num02{{decrement counter for sign and e{22598
*      here to generate the fraction
{gts23{mlr{3,gtssc{{{convert real to integer (10**cfp_s){22602
{{rti{{{{get integer (overflow impossible){22603
{{ngi{{{{negate as required by cvd{22604
*      loop to suppress trailing zeros
{gts24{bze{7,xl{6,gts27{{jump if no digits left to do{22608
{{cvd{{{{else convert one digit{22609
{{bne{8,wa{18,=ch_d0{6,gts26{jump if not a zero{22610
{{dcv{7,xl{{{decrement counter{22611
{{brn{6,gts24{{{loop back for next digit{22612
{{ejc{{{{{22613
*      gtstg (continued)
*      loop to generate digits after decimal point
{gts25{cvd{{{{convert a digit into wa{22619
*      merge here first time
{gts26{sch{8,wa{11,-(xr){{store digit{22623
{{dcv{8,wb{{{decrement counter{22624
{{dcv{7,xl{{{decrement counter{22625
{{bnz{7,xl{6,gts25{{loop back if more to go{22626
*      here generate the decimal point
{gts27{mov{8,wa{18,=ch_dt{{load decimal point{22630
{{sch{8,wa{11,-(xr){{store in work area{22631
{{dcv{8,wb{{{decrement counter{22632
*      here generate the digits before the decimal point
{gts28{cvd{{{{convert a digit into wa{22636
{{sch{8,wa{11,-(xr){{store in work area{22637
{{dcv{8,wb{{{decrement counter{22638
{{ine{6,gts28{{{loop back if more to go{22639
{{csc{7,xr{{{complete store characters{22640
{{brn{6,gts08{{{else jump back to exit{22641
*      exit point after successful conversion
{gts29{mov{7,xl{10,(xs)+{{restore xl{22647
{{ica{7,xs{{{pop argument{22648
{{mov{8,wb{3,gtsvb{{restore wb{22649
{{mov{8,wc{3,gtsvc{{restore wc{22650
*      merge here if no conversion required
{gts30{mov{8,wa{13,sclen(xr){{load string length{22654
{{exi{{{{return to caller{22655
*      here to return string for real zero
{gts31{mov{7,xl{21,=scre0{{point to string{22661
{{mov{8,wa{18,=num02{{2 chars{22662
{{zer{8,wb{{{zero offset{22663
{{jsr{6,sbstr{{{copy string{22664
{{brn{6,gts29{{{return{22665
{{enp{{{{end procedure gtstg{22692
{{ejc{{{{{22693
*      gtvar -- get variable for i/o/trace association
*      gtvar is used to point to an actual variable location
*      for the detach,input,output,trace,stoptr system functions
*      (xr)                  argument to function
*      jsr  gtvar            call to locate variable pointer
*      ppm  loc              transfer loc if not ok variable
*      (xl,wa)               name base,offset of variable
*      (xr,ra)               destroyed
*      (wb,wc)               destroyed (convert error only)
*      (xr)                  input arg (convert error only)
{gtvar{prc{25,e{1,1{{entry point{22708
{{bne{9,(xr){22,=b_nml{6,gtvr2{jump if not a name{22709
{{mov{8,wa{13,nmofs(xr){{else load name offset{22710
{{mov{7,xl{13,nmbas(xr){{load name base{22711
{{beq{9,(xl){22,=b_evt{6,gtvr1{error if expression variable{22712
{{bne{9,(xl){22,=b_kvt{6,gtvr3{all ok if not keyword variable{22713
*      here on conversion error
{gtvr1{exi{1,1{{{take convert error exit{22717
*      here if not a name, try convert to natural variable
{gtvr2{mov{3,gtvrc{8,wc{{save wc{22721
{{jsr{6,gtnvr{{{locate vrblk if possible{22722
{{ppm{6,gtvr1{{{jump if convert error{22723
{{mov{7,xl{7,xr{{else copy vrblk name base{22724
{{mov{8,wa{19,*vrval{{and set offset{22725
{{mov{8,wc{3,gtvrc{{restore wc{22726
*      here for name obtained
{gtvr3{bhi{7,xl{3,state{6,gtvr4{all ok if not natural variable{22730
{{beq{13,vrsto(xl){22,=b_vre{6,gtvr1{error if protected variable{22731
*      common exit point
{gtvr4{exi{{{{return to caller{22735
{{enp{{{{end procedure gtvar{22736
{{ejc{{{{{22737
{{ejc{{{{{22738
*      hashs -- compute hash index for string
*      hashs is used to convert a string to a unique integer
*      value. the resulting hash value is a positive integer
*      in the range 0 to cfp_m
*      (xr)                  string to be hashed
*      jsr  hashs            call to hash string
*      (ia)                  hash value
*      (xr,wb,wc)            destroyed
*      the hash function used is as follows.
*      start with the length of the string.
*      if there is more than one character in a word,
*      take the first e_hnw words of the characters from
*      the string or all the words if fewer than e_hnw.
*      compute the exclusive or of all these words treating
*      them as one word bit string values.
*      if there is just one character in a word,
*      then mimic the word by word hash by shifting
*      successive characters to get a similar effect.
*      e_hnw is set to zero in case only one character per word.
*      move the result as an integer with the mti instruction.
*      the test on e_hnw is done dynamically. this should be done
*      eventually using conditional assembly, but that would require
*      changes to the build process (ds 8 may 2013).
{hashs{prc{25,e{1,0{{entry point{22774
*z-
{{mov{8,wc{18,=e_hnw{{get number of words to use{22776
{{bze{8,wc{6,hshsa{{branch if one character per word{22777
{{mov{8,wc{13,sclen(xr){{load string length in characters{22778
{{mov{8,wb{8,wc{{initialize with length{22779
{{bze{8,wc{6,hshs3{{jump if null string{22780
{{zgb{8,wb{{{correct byte ordering if necessary{22781
{{ctw{8,wc{1,0{{get number of words of chars{22782
{{add{7,xr{19,*schar{{point to characters of string{22783
{{blo{8,wc{18,=e_hnw{6,hshs1{use whole string if short{22784
{{mov{8,wc{18,=e_hnw{{else set to involve first e_hnw wds{22785
*      here with count of words to check in wc
{hshs1{lct{8,wc{8,wc{{set counter to control loop{22789
*      loop to compute exclusive or
{hshs2{xob{8,wb{10,(xr)+{{exclusive or next word of chars{22793
{{bct{8,wc{6,hshs2{{loop till all processed{22794
*      merge here with exclusive or in wb
{hshs3{zgb{8,wb{{{zeroise undefined bits{22798
{{anb{8,wb{4,bitsm{{ensure in range 0 to cfp_m{22799
{{mti{8,wb{{{move result as integer{22800
{{zer{7,xr{{{clear garbage value in xr{22801
{{exi{{{{return to hashs caller{22802
*      here if just one character per word
{hshsa{mov{8,wc{13,sclen(xr){{load string length in characters{22806
{{mov{8,wb{8,wc{{initialize with length{22807
{{bze{8,wc{6,hshs3{{jump if null string{22808
{{zgb{8,wb{{{correct byte ordering if necessary{22809
{{ctw{8,wc{1,0{{get number of words of chars{22810
{{plc{7,xr{{{{22811
{{mov{11,-(xs){7,xl{{save xl{22812
{{mov{7,xl{8,wc{{load length for branch{22813
{{bge{7,xl{18,=num25{6,hsh24{use first characters if longer{22814
{{bsw{7,xl{1,25{{merge to compute hash{22815
{{iff{1,0{6,hsh00{{{22841
{{iff{1,1{6,hsh01{{{22841
{{iff{1,2{6,hsh02{{{22841
{{iff{1,3{6,hsh03{{{22841
{{iff{1,4{6,hsh04{{{22841
{{iff{1,5{6,hsh05{{{22841
{{iff{1,6{6,hsh06{{{22841
{{iff{1,7{6,hsh07{{{22841
{{iff{1,8{6,hsh08{{{22841
{{iff{1,9{6,hsh09{{{22841
{{iff{1,10{6,hsh10{{{22841
{{iff{1,11{6,hsh11{{{22841
{{iff{1,12{6,hsh12{{{22841
{{iff{1,13{6,hsh13{{{22841
{{iff{1,14{6,hsh14{{{22841
{{iff{1,15{6,hsh15{{{22841
{{iff{1,16{6,hsh16{{{22841
{{iff{1,17{6,hsh17{{{22841
{{iff{1,18{6,hsh18{{{22841
{{iff{1,19{6,hsh19{{{22841
{{iff{1,20{6,hsh20{{{22841
{{iff{1,21{6,hsh21{{{22841
{{iff{1,22{6,hsh22{{{22841
{{iff{1,23{6,hsh23{{{22841
{{iff{1,24{6,hsh24{{{22841
{{esw{{{{{22841
{hsh24{lch{8,wc{10,(xr)+{{load next character{22842
{{lsh{8,wc{1,24{{shift for hash{22843
{{xob{8,wb{8,wc{{hash character{22844
{hsh23{lch{8,wc{10,(xr)+{{load next character{22845
{{lsh{8,wc{1,16{{shift for hash{22846
{{xob{8,wb{8,wc{{hash character{22847
{hsh22{lch{8,wc{10,(xr)+{{load next character{22848
{{lsh{8,wc{1,8{{shift for hash{22849
{{xob{8,wb{8,wc{{hash character{22850
{hsh21{lch{8,wc{10,(xr)+{{load next character{22851
{{xob{8,wb{8,wc{{hash character{22852
{hsh20{lch{8,wc{10,(xr)+{{load next character{22853
{{lsh{8,wc{1,24{{shift for hash{22854
{{xob{8,wb{8,wc{{hash character{22855
{hsh19{lch{8,wc{10,(xr)+{{load next character{22856
{{lsh{8,wc{1,16{{shift for hash{22857
{{xob{8,wb{8,wc{{hash character{22858
{hsh18{lch{8,wc{10,(xr)+{{load next character{22859
{{lsh{8,wc{1,8{{shift for hash{22860
{{xob{8,wb{8,wc{{hash character{22861
{hsh17{lch{8,wc{10,(xr)+{{load next character{22862
{{xob{8,wb{8,wc{{hash character{22863
{hsh16{lch{8,wc{10,(xr)+{{load next character{22864
{{lsh{8,wc{1,24{{shift for hash{22865
{{xob{8,wb{8,wc{{hash character{22866
{hsh15{lch{8,wc{10,(xr)+{{load next character{22867
{{lsh{8,wc{1,16{{shift for hash{22868
{{xob{8,wb{8,wc{{hash character{22869
{hsh14{lch{8,wc{10,(xr)+{{load next character{22870
{{lsh{8,wc{1,8{{shift for hash{22871
{{xob{8,wb{8,wc{{hash character{22872
{hsh13{lch{8,wc{10,(xr)+{{load next character{22873
{{xob{8,wb{8,wc{{hash character{22874
{hsh12{lch{8,wc{10,(xr)+{{load next character{22875
{{lsh{8,wc{1,24{{shift for hash{22876
{{xob{8,wb{8,wc{{hash character{22877
{hsh11{lch{8,wc{10,(xr)+{{load next character{22878
{{lsh{8,wc{1,16{{shift for hash{22879
{{xob{8,wb{8,wc{{hash character{22880
{hsh10{lch{8,wc{10,(xr)+{{load next character{22881
{{lsh{8,wc{1,8{{shift for hash{22882
{{xob{8,wb{8,wc{{hash character{22883
{hsh09{lch{8,wc{10,(xr)+{{load next character{22884
{{xob{8,wb{8,wc{{hash character{22885
{hsh08{lch{8,wc{10,(xr)+{{load next character{22886
{{lsh{8,wc{1,24{{shift for hash{22887
{{xob{8,wb{8,wc{{hash character{22888
{hsh07{lch{8,wc{10,(xr)+{{load next character{22889
{{lsh{8,wc{1,16{{shift for hash{22890
{{xob{8,wb{8,wc{{hash character{22891
{hsh06{lch{8,wc{10,(xr)+{{load next character{22892
{{lsh{8,wc{1,8{{shift for hash{22893
{{xob{8,wb{8,wc{{hash character{22894
{hsh05{lch{8,wc{10,(xr)+{{load next character{22895
{{xob{8,wb{8,wc{{hash character{22896
{hsh04{lch{8,wc{10,(xr)+{{load next character{22897
{{lsh{8,wc{1,24{{shift for hash{22898
{{xob{8,wb{8,wc{{hash character{22899
{hsh03{lch{8,wc{10,(xr)+{{load next character{22900
{{lsh{8,wc{1,16{{shift for hash{22901
{{xob{8,wb{8,wc{{hash character{22902
{hsh02{lch{8,wc{10,(xr)+{{load next character{22903
{{lsh{8,wc{1,8{{shift for hash{22904
{{xob{8,wb{8,wc{{hash character{22905
{hsh01{lch{8,wc{10,(xr)+{{load next character{22906
{{xob{8,wb{8,wc{{hash character{22907
{hsh00{mov{7,xl{10,(xs)+{{restore xl{22908
{{brn{6,hshs3{{{merge to complete hash{22909
{{enp{{{{end procedure hashs{22910
*      icbld -- build integer block
*      (ia)                  integer value for icblk
*      jsr  icbld            call to build integer block
*      (xr)                  pointer to result icblk
*      (wa)                  destroyed
{icbld{prc{25,e{1,0{{entry point{22919
*z+
{{mfi{7,xr{6,icbl1{{copy small integers{22921
{{ble{7,xr{18,=num02{6,icbl3{jump if 0,1 or 2{22922
*      construct icblk
{icbl1{mov{7,xr{3,dnamp{{load pointer to next available loc{22926
{{add{7,xr{19,*icsi_{{point past new icblk{22927
{{blo{7,xr{3,dname{6,icbl2{jump if there is room{22928
{{mov{8,wa{19,*icsi_{{else load length of icblk{22929
{{jsr{6,alloc{{{use standard allocator to get block{22930
{{add{7,xr{8,wa{{point past block to merge{22931
*      merge here with xr pointing past the block obtained
{icbl2{mov{3,dnamp{7,xr{{set new pointer{22935
{{sub{7,xr{19,*icsi_{{point back to start of block{22936
{{mov{9,(xr){22,=b_icl{{store type word{22937
{{sti{13,icval(xr){{{store integer value in icblk{22938
{{exi{{{{return to icbld caller{22939
*      optimise by not building icblks for small integers
{icbl3{wtb{7,xr{{{convert integer to offset{22943
{{mov{7,xr{14,intab(xr){{point to pre-built icblk{22944
{{exi{{{{return{22945
{{enp{{{{end procedure icbld{22946
{{ejc{{{{{22947
*      ident -- compare two values
*      ident compares two values in the sense of the ident
*      differ functions available at the snobol level.
*      (xr)                  first argument
*      (xl)                  second argument
*      jsr  ident            call to compare arguments
*      ppm  loc              transfer loc if ident
*      (normal return if differ)
*      (xr,xl,wc,ra)         destroyed
{ident{prc{25,e{1,1{{entry point{22961
{{beq{7,xr{7,xl{6,iden7{jump if same pointer (ident){22962
{{mov{8,wc{9,(xr){{else load arg 1 type word{22963
{{bne{8,wc{9,(xl){6,iden1{differ if arg 2 type word differ{22965
{{beq{8,wc{22,=b_scl{6,iden2{jump if strings{22969
{{beq{8,wc{22,=b_icl{6,iden4{jump if integers{22970
{{beq{8,wc{22,=b_rcl{6,iden5{jump if reals{22973
{{beq{8,wc{22,=b_nml{6,iden6{jump if names{22975
*      for all other datatypes, must be differ if xr ne xl
*      merge here for differ
{iden1{exi{{{{take differ exit{23018
*      here for strings, ident only if lengths and chars same
{iden2{mov{8,wc{13,sclen(xr){{load arg 1 length{23022
{{bne{8,wc{13,sclen(xl){6,iden1{differ if lengths differ{23023
*      buffer and string comparisons merge here
{idn2a{add{7,xr{19,*schar{{point to chars of arg 1{23027
{{add{7,xl{19,*schar{{point to chars of arg 2{23028
{{ctw{8,wc{1,0{{get number of words in strings{23029
{{lct{8,wc{8,wc{{set loop counter{23030
*      loop to compare characters. note that wc cannot be zero
*      since all null strings point to nulls and give xl=xr.
{iden3{cne{9,(xr){9,(xl){6,iden8{differ if chars do not match{23035
{{ica{7,xr{{{else bump arg one pointer{23036
{{ica{7,xl{{{bump arg two pointer{23037
{{bct{8,wc{6,iden3{{loop back till all checked{23038
{{ejc{{{{{23039
*      ident (continued)
*      here to exit for case of two ident strings
{{zer{7,xl{{{clear garbage value in xl{23045
{{zer{7,xr{{{clear garbage value in xr{23046
{{exi{1,1{{{take ident exit{23047
*      here for integers, ident if same values
{iden4{ldi{13,icval(xr){{{load arg 1{23051
{{sbi{13,icval(xl){{{subtract arg 2 to compare{23052
{{iov{6,iden1{{{differ if overflow{23053
{{ine{6,iden1{{{differ if result is not zero{23054
{{exi{1,1{{{take ident exit{23055
*      here for reals, ident if same values
{iden5{ldr{13,rcval(xr){{{load arg 1{23061
{{sbr{13,rcval(xl){{{subtract arg 2 to compare{23062
{{rov{6,iden1{{{differ if overflow{23063
{{rne{6,iden1{{{differ if result is not zero{23064
{{exi{1,1{{{take ident exit{23065
*      here for names, ident if bases and offsets same
{iden6{bne{13,nmofs(xr){13,nmofs(xl){6,iden1{differ if different offset{23070
{{bne{13,nmbas(xr){13,nmbas(xl){6,iden1{differ if different base{23071
*      merge here to signal ident for identical pointers
{iden7{exi{1,1{{{take ident exit{23075
*      here for differ strings
{iden8{zer{7,xr{{{clear garbage ptr in xr{23079
{{zer{7,xl{{{clear garbage ptr in xl{23080
{{exi{{{{return to caller (differ){23081
{{enp{{{{end procedure ident{23082
{{ejc{{{{{23083
*      inout - used to initialise input and output variables
*      (xl)                  pointer to vbl name string
*      (wb)                  trblk type
*      jsr  inout            call to perform initialisation
*      (xl)                  vrblk ptr
*      (xr)                  trblk ptr
*      (wa,wc)               destroyed
*      note that trter (= trtrf) field of standard i/o variables
*      points to corresponding svblk not to a trblk as is the
*      case for ordinary variables.
{inout{prc{25,e{1,0{{entry point{23098
{{mov{11,-(xs){8,wb{{stack trblk type{23099
{{mov{8,wa{13,sclen(xl){{get name length{23100
{{zer{8,wb{{{point to start of name{23101
{{jsr{6,sbstr{{{build a proper scblk{23102
{{jsr{6,gtnvr{{{build vrblk{23103
{{ppm{{{{no error return{23104
{{mov{8,wc{7,xr{{save vrblk pointer{23105
{{mov{8,wb{10,(xs)+{{get trter field{23106
{{zer{7,xl{{{zero trfpt{23107
{{jsr{6,trbld{{{build trblk{23108
{{mov{7,xl{8,wc{{recall vrblk pointer{23109
{{mov{13,trter(xr){13,vrsvp(xl){{store svblk pointer{23110
{{mov{13,vrval(xl){7,xr{{store trblk ptr in vrblk{23111
{{mov{13,vrget(xl){22,=b_vra{{set trapped access{23112
{{mov{13,vrsto(xl){22,=b_vrv{{set trapped store{23113
{{exi{{{{return to caller{23114
{{enp{{{{end procedure inout{23115
{{ejc{{{{{23116
*      insta - used to initialize structures in static region
*      (xr)                  pointer to starting static location
*      jsr  insta            call to initialize static structure
*      (xr)                  ptr to next free static location
*      (wa,wb,wc)            destroyed
*      note that this procedure establishes the pointers
*      prbuf, gtswk, and kvalp.
{insta{prc{25,e{1,0{{entry point{23295
*      initialize print buffer with blank words
*z-
{{mov{8,wc{3,prlen{{no. of chars in print bfr{23300
{{mov{3,prbuf{7,xr{{print bfr is put at static start{23301
{{mov{10,(xr)+{22,=b_scl{{store string type code{23302
{{mov{10,(xr)+{8,wc{{and string length{23303
{{ctw{8,wc{1,0{{get number of words in buffer{23304
{{mov{3,prlnw{8,wc{{store for buffer clear{23305
{{lct{8,wc{8,wc{{words to clear{23306
*      loop to clear buffer
{inst1{mov{10,(xr)+{4,nullw{{store blank{23310
{{bct{8,wc{6,inst1{{loop{23311
*      allocate work area for gtstg conversion procedure
{{mov{8,wa{18,=nstmx{{get max num chars in output number{23315
{{ctb{8,wa{2,scsi_{{no of bytes needed{23316
{{mov{3,gtswk{7,xr{{store bfr adrs{23317
{{add{7,xr{8,wa{{bump for work bfr{23318
*      build alphabet string for alphabet keyword and replace
{{mov{3,kvalp{7,xr{{save alphabet pointer{23322
{{mov{9,(xr){22,=b_scl{{string blk type{23323
{{mov{8,wc{18,=cfp_a{{no of chars in alphabet{23324
{{mov{13,sclen(xr){8,wc{{store as string length{23325
{{mov{8,wb{8,wc{{copy char count{23326
{{ctb{8,wb{2,scsi_{{no. of bytes needed{23327
{{add{8,wb{7,xr{{current end address for static{23328
{{mov{8,wa{8,wb{{save adrs past alphabet string{23329
{{lct{8,wc{8,wc{{loop counter{23330
{{psc{7,xr{{{point to chars of string{23331
{{zer{8,wb{{{set initial character value{23332
*      loop to enter character codes in order
{inst2{sch{8,wb{10,(xr)+{{store next code{23336
{{icv{8,wb{{{bump code value{23337
{{bct{8,wc{6,inst2{{loop till all stored{23338
{{csc{7,xr{{{complete store characters{23339
{{mov{7,xr{8,wa{{return current static ptr{23340
{{exi{{{{return to caller{23341
{{enp{{{{end procedure insta{23342
{{ejc{{{{{23343
*      iofcb -- get input/output fcblk pointer
*      used by endfile, eject and rewind to find the fcblk
*      (if any) corresponding to their argument.
*      -(xs)                 argument
*      jsr  iofcb            call to find fcblk
*      ppm  loc              arg is an unsuitable name
*      ppm  loc              arg is null string
*      ppm  loc              arg file not found
*      (xs)                  popped
*      (xl)                  ptr to filearg1 vrblk
*      (xr)                  argument
*      (wa)                  fcblk ptr or 0
*      (wb,wc)               destroyed
{iofcb{prc{25,n{1,3{{entry point{23361
*z+
{{jsr{6,gtstg{{{get arg as string{23363
{{ppm{6,iofc2{{{fail{23364
{{mov{7,xl{7,xr{{copy string ptr{23365
{{jsr{6,gtnvr{{{get as natural variable{23366
{{ppm{6,iofc3{{{fail if null{23367
{{mov{8,wb{7,xl{{copy string pointer again{23368
{{mov{7,xl{7,xr{{copy vrblk ptr for return{23369
{{zer{8,wa{{{in case no trblk found{23370
*      loop to find file arg1 trblk
{iofc1{mov{7,xr{13,vrval(xr){{get possible trblk ptr{23374
{{bne{9,(xr){22,=b_trt{6,iofc4{fail if end of chain{23375
{{bne{13,trtyp(xr){18,=trtfc{6,iofc1{loop if not file arg trblk{23376
{{mov{8,wa{13,trfpt(xr){{get fcblk ptr{23377
{{mov{7,xr{8,wb{{copy arg{23378
{{exi{{{{return{23379
*      fail return
{iofc2{exi{1,1{{{fail{23383
*      null arg
{iofc3{exi{1,2{{{null arg return{23387
*      file not found
{iofc4{exi{1,3{{{file not found return{23391
{{enp{{{{end procedure iofcb{23392
{{ejc{{{{{23393
*      ioppf -- process filearg2 for ioput
*      (r_xsc)               filearg2 ptr
*      jsr  ioppf            call to process filearg2
*      (xl)                  filearg1 ptr
*      (xr)                  file arg2 ptr
*      -(xs)...-(xs)         fields extracted from filearg2
*      (wc)                  no. of fields extracted
*      (wb)                  input/output flag
*      (wa)                  fcblk ptr or 0
{ioppf{prc{25,n{1,0{{entry point{23406
{{zer{8,wb{{{to count fields extracted{23407
*      loop to extract fields
{iopp1{mov{7,xl{18,=iodel{{get delimiter{23411
{{mov{8,wc{7,xl{{copy it{23412
{{zer{8,wa{{{retain leading blanks in filearg2{23413
{{jsr{6,xscan{{{get next field{23414
{{mov{11,-(xs){7,xr{{stack it{23415
{{icv{8,wb{{{increment count{23416
{{bnz{8,wa{6,iopp1{{loop{23417
{{mov{8,wc{8,wb{{count of fields{23418
{{mov{8,wb{3,ioptt{{i/o marker{23419
{{mov{8,wa{3,r_iof{{fcblk ptr or 0{23420
{{mov{7,xr{3,r_io2{{file arg2 ptr{23421
{{mov{7,xl{3,r_io1{{filearg1{23422
{{exi{{{{return{23423
{{enp{{{{end procedure ioppf{23424
{{ejc{{{{{23425
*      ioput -- routine used by input and output
*      ioput sets up input/output  associations. it builds
*      such trace and file control blocks as are necessary and
*      calls sysfc,sysio to perform checks on the
*      arguments and to open the files.
*         +-----------+   +---------------+       +-----------+
*      +-.i           i   i               i------.i   =b_xrt  i
*      i  +-----------+   +---------------+       +-----------+
*      i  /           /        (r_fcb)            i    *4     i
*      i  /           /                           +-----------+
*      i  +-----------+   +---------------+       i           i-
*      i  i   name    +--.i    =b_trt     i       +-----------+
*      i  /           /   +---------------+       i           i
*      i   (first arg)    i =trtin/=trtou i       +-----------+
*      i                  +---------------+             i
*      i                  i     value     i             i
*      i                  +---------------+             i
*      i                  i(trtrf) 0   or i--+          i
*      i                  +---------------+  i          i
*      i                  i(trfpt) 0   or i----+        i
*      i                  +---------------+  i i        i
*      i                     (i/o trblk)     i i        i
*      i  +-----------+                      i i        i
*      i  i           i                      i i        i
*      i  +-----------+                      i i        i
*      i  i           i                      i i        i
*      i  +-----------+   +---------------+  i i        i
*      i  i           +--.i    =b_trt     i.-+ i        i
*      i  +-----------+   +---------------+    i        i
*      i  /           /   i    =trtfc     i    i        i
*      i  /           /   +---------------+    i        i
*      i    (filearg1     i     value     i    i        i
*      i         vrblk)   +---------------+    i        i
*      i                  i(trtrf) 0   or i--+ i        .
*      i                  +---------------+  i .  +-----------+
*      i                  i(trfpt) 0   or i------./   fcblk   /
*      i                  +---------------+  i    +-----------+
*      i                       (trtrf)       i
*      i                                     i
*      i                                     i
*      i                  +---------------+  i
*      i                  i    =b_xrt     i.-+
*      i                  +---------------+
*      i                  i      *5       i
*      i                  +---------------+
*      +------------------i               i
*                         +---------------+       +-----------+
*                         i(trtrf) o   or i------.i  =b_xrt   i
*                         +---------------+       +-----------+
*                         i  name offset  i       i    etc    i
*                         +---------------+
*                           (iochn - chain of name pointers)
{{ejc{{{{{23481
*      ioput (continued)
*      no additional trap blocks are used for standard input/out
*      files. otherwise an i/o trap block is attached to second
*      arg (filearg1) vrblk. see diagram above for details of
*      the structure built.
*      -(xs)                 1st arg (vbl to be associated)
*      -(xs)                 2nd arg (file arg1)
*      -(xs)                 3rd arg (file arg2)
*      (wb)                  0 for input, 3 for output assoc.
*      jsr  ioput            call for input/output association
*      ppm  loc              3rd arg not a string
*      ppm  loc              2nd arg not a suitable name
*      ppm  loc              1st arg not a suitable name
*      ppm  loc              inappropriate file spec for i/o
*      ppm  loc              i/o file does not exist
*      ppm  loc              i/o file cannot be read/written
*      ppm  loc              i/o fcblk currently in use
*      (xs)                  popped
*      (xl,xr,wa,wb,wc)      destroyed
{ioput{prc{25,n{1,7{{entry point{23505
{{zer{3,r_iot{{{in case no trtrf block used{23506
{{zer{3,r_iof{{{in case no fcblk alocated{23507
{{zer{3,r_iop{{{in case sysio fails{23508
{{mov{3,ioptt{8,wb{{store i/o trace type{23509
{{jsr{6,xscni{{{prepare to scan filearg2{23510
{{ppm{6,iop13{{{fail{23511
{{ppm{6,iopa0{{{null file arg2{23512
{iopa0{mov{3,r_io2{7,xr{{keep file arg2{23514
{{mov{7,xl{8,wa{{copy length{23515
{{jsr{6,gtstg{{{convert filearg1 to string{23516
{{ppm{6,iop14{{{fail{23517
{{mov{3,r_io1{7,xr{{keep filearg1 ptr{23518
{{jsr{6,gtnvr{{{convert to natural variable{23519
{{ppm{6,iop00{{{jump if null{23520
{{brn{6,iop04{{{jump to process non-null args{23521
*      null filearg1
{iop00{bze{7,xl{6,iop01{{skip if both args null{23525
{{jsr{6,ioppf{{{process filearg2{23526
{{jsr{6,sysfc{{{call for filearg2 check{23527
{{ppm{6,iop16{{{fail{23528
{{ppm{6,iop26{{{fail{23529
{{brn{6,iop11{{{complete file association{23530
{{ejc{{{{{23531
*      ioput (continued)
*      here with 0 or fcblk ptr in (xl)
{iop01{mov{8,wb{3,ioptt{{get trace type{23537
{{mov{7,xr{3,r_iot{{get 0 or trtrf ptr{23538
{{jsr{6,trbld{{{build trblk{23539
{{mov{8,wc{7,xr{{copy trblk pointer{23540
{{mov{7,xr{10,(xs)+{{get variable from stack{23541
{{mov{11,-(xs){8,wc{{make trblk collectable{23542
{{jsr{6,gtvar{{{point to variable{23543
{{ppm{6,iop15{{{fail{23544
{{mov{8,wc{10,(xs)+{{recover trblk pointer{23545
{{mov{3,r_ion{7,xl{{save name pointer{23546
{{mov{7,xr{7,xl{{copy name pointer{23547
{{add{7,xr{8,wa{{point to variable{23548
{{sub{7,xr{19,*vrval{{subtract offset,merge into loop{23549
*      loop to end of trblk chain if any
{iop02{mov{7,xl{7,xr{{copy blk ptr{23553
{{mov{7,xr{13,vrval(xr){{load ptr to next trblk{23554
{{bne{9,(xr){22,=b_trt{6,iop03{jump if not trapped{23555
{{bne{13,trtyp(xr){3,ioptt{6,iop02{loop if not same assocn{23556
{{mov{7,xr{13,trnxt(xr){{get value and delete old trblk{23557
*      ioput (continued)
*      store new association
{iop03{mov{13,vrval(xl){8,wc{{link to this trblk{23563
{{mov{7,xl{8,wc{{copy pointer{23564
{{mov{13,trnxt(xl){7,xr{{store value in trblk{23565
{{mov{7,xr{3,r_ion{{restore possible vrblk pointer{23566
{{mov{8,wb{8,wa{{keep offset to name{23567
{{jsr{6,setvr{{{if vrblk, set vrget,vrsto{23568
{{mov{7,xr{3,r_iot{{get 0 or trtrf ptr{23569
{{bnz{7,xr{6,iop19{{jump if trtrf block exists{23570
{{exi{{{{return to caller{23571
*      non standard file
*      see if an fcblk has already been allocated.
{iop04{zer{8,wa{{{in case no fcblk found{23576
{{ejc{{{{{23577
*      ioput (continued)
*      search possible trblk chain to pick up the fcblk
{iop05{mov{8,wb{7,xr{{remember blk ptr{23583
{{mov{7,xr{13,vrval(xr){{chain along{23584
{{bne{9,(xr){22,=b_trt{6,iop06{jump if end of trblk chain{23585
{{bne{13,trtyp(xr){18,=trtfc{6,iop05{loop if more to go{23586
{{mov{3,r_iot{7,xr{{point to file arg1 trblk{23587
{{mov{8,wa{13,trfpt(xr){{get fcblk ptr from trblk{23588
*      wa = 0 or fcblk ptr
*      wb = ptr to preceding blk to which any trtrf block
*           for file arg1 must be chained.
{iop06{mov{3,r_iof{8,wa{{keep possible fcblk ptr{23594
{{mov{3,r_iop{8,wb{{keep preceding blk ptr{23595
{{jsr{6,ioppf{{{process filearg2{23596
{{jsr{6,sysfc{{{see if fcblk required{23597
{{ppm{6,iop16{{{fail{23598
{{ppm{6,iop26{{{fail{23599
{{bze{8,wa{6,iop12{{skip if no new fcblk wanted{23600
{{blt{8,wc{18,=num02{6,iop6a{jump if fcblk in dynamic{23601
{{jsr{6,alost{{{get it in static{23602
{{brn{6,iop6b{{{skip{23603
*      obtain fcblk in dynamic
{iop6a{jsr{6,alloc{{{get space for fcblk{23607
*      merge
{iop6b{mov{7,xl{7,xr{{point to fcblk{23611
{{mov{8,wb{8,wa{{copy its length{23612
{{btw{8,wb{{{get count as words (sgd apr80){23613
{{lct{8,wb{8,wb{{loop counter{23614
*      clear fcblk
{iop07{zer{10,(xr)+{{{clear a word{23618
{{bct{8,wb{6,iop07{{loop{23619
{{beq{8,wc{18,=num02{6,iop09{skip if in static - dont set fields{23620
{{mov{9,(xl){22,=b_xnt{{store xnblk code in case{23621
{{mov{13,num01(xl){8,wa{{store length{23622
{{bnz{8,wc{6,iop09{{jump if xnblk wanted{23623
{{mov{9,(xl){22,=b_xrt{{xrblk code requested{23624
{{ejc{{{{{23626
*      ioput (continued)
*      complete fcblk initialisation
{iop09{mov{7,xr{3,r_iot{{get possible trblk ptr{23631
{{mov{3,r_iof{7,xl{{store fcblk ptr{23632
{{bnz{7,xr{6,iop10{{jump if trblk already found{23633
*      a new trblk is needed
{{mov{8,wb{18,=trtfc{{trtyp for fcblk trap blk{23637
{{jsr{6,trbld{{{make the block{23638
{{mov{3,r_iot{7,xr{{copy trtrf ptr{23639
{{mov{7,xl{3,r_iop{{point to preceding blk{23640
{{mov{13,vrval(xr){13,vrval(xl){{copy value field to trblk{23641
{{mov{13,vrval(xl){7,xr{{link new trblk into chain{23642
{{mov{7,xr{7,xl{{point to predecessor blk{23643
{{jsr{6,setvr{{{set trace intercepts{23644
{{mov{7,xr{13,vrval(xr){{recover trblk ptr{23645
{{brn{6,iop1a{{{store fcblk ptr{23646
*      here if existing trblk
{iop10{zer{3,r_iop{{{do not release if sysio fails{23650
*      xr is ptr to trblk, xl is fcblk ptr or 0
{iop1a{mov{13,trfpt(xr){3,r_iof{{store fcblk ptr{23654
*      call sysio to complete file accessing
{iop11{mov{8,wa{3,r_iof{{copy fcblk ptr or 0{23658
{{mov{8,wb{3,ioptt{{get input/output flag{23659
{{mov{7,xr{3,r_io2{{get file arg2{23660
{{mov{7,xl{3,r_io1{{get file arg1{23661
{{jsr{6,sysio{{{associate to the file{23662
{{ppm{6,iop17{{{fail{23663
{{ppm{6,iop18{{{fail{23664
{{bnz{3,r_iot{6,iop01{{not std input if non-null trtrf blk{23665
{{bnz{3,ioptt{6,iop01{{jump if output{23666
{{bze{8,wc{6,iop01{{no change to standard read length{23667
{{mov{3,cswin{8,wc{{store new read length for std file{23668
{{brn{6,iop01{{{merge to finish the task{23669
*      sysfc may have returned a pointer to a private fcblk
{iop12{bnz{7,xl{6,iop09{{jump if private fcblk{23673
{{brn{6,iop11{{{finish the association{23674
*      failure returns
{iop13{exi{1,1{{{3rd arg not a string{23678
{iop14{exi{1,2{{{2nd arg unsuitable{23679
{iop15{ica{7,xs{{{discard trblk pointer{23680
{{exi{1,3{{{1st arg unsuitable{23681
{iop16{exi{1,4{{{file spec wrong{23682
{iop26{exi{1,7{{{fcblk in use{23683
*      i/o file does not exist
{iop17{mov{7,xr{3,r_iop{{is there a trblk to release{23687
{{bze{7,xr{6,iopa7{{if not{23688
{{mov{7,xl{13,vrval(xr){{point to trblk{23689
{{mov{13,vrval(xr){13,vrval(xl){{unsplice it{23690
{{jsr{6,setvr{{{adjust trace intercepts{23691
{iopa7{exi{1,5{{{i/o file does not exist{23692
*      i/o file cannot be read/written
{iop18{mov{7,xr{3,r_iop{{is there a trblk to release{23696
{{bze{7,xr{6,iopa7{{if not{23697
{{mov{7,xl{13,vrval(xr){{point to trblk{23698
{{mov{13,vrval(xr){13,vrval(xl){{unsplice it{23699
{{jsr{6,setvr{{{adjust trace intercepts{23700
{iopa8{exi{1,6{{{i/o file cannot be read/written{23701
{{ejc{{{{{23702
*      ioput (continued)
*      add to iochn chain of associated variables unless
*      already present.
{iop19{mov{8,wc{3,r_ion{{wc = name base, wb = name offset{23709
*      search loop
{iop20{mov{7,xr{13,trtrf(xr){{next link of chain{23713
{{bze{7,xr{6,iop21{{not found{23714
{{bne{8,wc{13,ionmb(xr){6,iop20{no match{23715
{{beq{8,wb{13,ionmo(xr){6,iop22{exit if matched{23716
{{brn{6,iop20{{{loop{23717
*      not found
{iop21{mov{8,wa{19,*num05{{space needed{23721
{{jsr{6,alloc{{{get it{23722
{{mov{9,(xr){22,=b_xrt{{store xrblk code{23723
{{mov{13,num01(xr){8,wa{{store length{23724
{{mov{13,ionmb(xr){8,wc{{store name base{23725
{{mov{13,ionmo(xr){8,wb{{store name offset{23726
{{mov{7,xl{3,r_iot{{point to trtrf blk{23727
{{mov{8,wa{13,trtrf(xl){{get ptr field contents{23728
{{mov{13,trtrf(xl){7,xr{{store ptr to new block{23729
{{mov{13,trtrf(xr){8,wa{{complete the linking{23730
*      insert fcblk on fcblk chain for sysej, sysxi
{iop22{bze{3,r_iof{6,iop25{{skip if no fcblk{23734
{{mov{7,xl{3,r_fcb{{ptr to head of existing chain{23735
*      see if fcblk already on chain
{iop23{bze{7,xl{6,iop24{{not on if end of chain{23739
{{beq{13,num03(xl){3,r_iof{6,iop25{dont duplicate if find it{23740
{{mov{7,xl{13,num02(xl){{get next link{23741
{{brn{6,iop23{{{loop{23742
*      not found so add an entry for this fcblk
{iop24{mov{8,wa{19,*num04{{space needed{23746
{{jsr{6,alloc{{{get it{23747
{{mov{9,(xr){22,=b_xrt{{store block code{23748
{{mov{13,num01(xr){8,wa{{store length{23749
{{mov{13,num02(xr){3,r_fcb{{store previous link in this node{23750
{{mov{13,num03(xr){3,r_iof{{store fcblk ptr{23751
{{mov{3,r_fcb{7,xr{{insert node into fcblk chain{23752
*      return
{iop25{exi{{{{return to caller{23756
{{enp{{{{end procedure ioput{23757
{{ejc{{{{{23758
*      ktrex -- execute keyword trace
*      ktrex is used to execute a possible keyword trace. it
*      includes the test on trace and tests for trace active.
*      (xl)                  ptr to trblk (or 0 if untraced)
*      jsr  ktrex            call to execute keyword trace
*      (xl,wa,wb,wc)         destroyed
*      (ra)                  destroyed
{ktrex{prc{25,r{1,0{{entry point (recursive){23770
{{bze{7,xl{6,ktrx3{{immediate exit if keyword untraced{23771
{{bze{3,kvtra{6,ktrx3{{immediate exit if trace = 0{23772
{{dcv{3,kvtra{{{else decrement trace{23773
{{mov{11,-(xs){7,xr{{save xr{23774
{{mov{7,xr{7,xl{{copy trblk pointer{23775
{{mov{7,xl{13,trkvr(xr){{load vrblk pointer (nmbas){23776
{{mov{8,wa{19,*vrval{{set name offset{23777
{{bze{13,trfnc(xr){6,ktrx1{{jump if print trace{23778
{{jsr{6,trxeq{{{else execute full trace{23779
{{brn{6,ktrx2{{{and jump to exit{23780
*      here for print trace
{ktrx1{mov{11,-(xs){7,xl{{stack vrblk ptr for kwnam{23784
{{mov{11,-(xs){8,wa{{stack offset for kwnam{23785
{{jsr{6,prtsn{{{print statement number{23786
{{mov{8,wa{18,=ch_am{{load ampersand{23787
{{jsr{6,prtch{{{print ampersand{23788
{{jsr{6,prtnm{{{print keyword name{23789
{{mov{7,xr{21,=tmbeb{{point to blank-equal-blank{23790
{{jsr{6,prtst{{{print blank-equal-blank{23791
{{jsr{6,kwnam{{{get keyword pseudo-variable name{23792
{{mov{3,dnamp{7,xr{{reset ptr to delete kvblk{23793
{{jsr{6,acess{{{get keyword value{23794
{{ppm{{{{failure is impossible{23795
{{jsr{6,prtvl{{{print keyword value{23796
{{jsr{6,prtnl{{{terminate print line{23797
*      here to exit after completing trace
{ktrx2{mov{7,xr{10,(xs)+{{restore entry xr{23801
*      merge here to exit if no trace required
{ktrx3{exi{{{{return to ktrex caller{23805
{{enp{{{{end procedure ktrex{23806
{{ejc{{{{{23807
*      kwnam -- get pseudo-variable name for keyword
*      1(xs)                 name base for vrblk
*      0(xs)                 offset (should be *vrval)
*      jsr  kwnam            call to get pseudo-variable name
*      (xs)                  popped twice
*      (xl,wa)               resulting pseudo-variable name
*      (xr,wa,wb)            destroyed
{kwnam{prc{25,n{1,0{{entry point{23818
{{ica{7,xs{{{ignore name offset{23819
{{mov{7,xr{10,(xs)+{{load name base{23820
{{bge{7,xr{3,state{6,kwnm1{jump if not natural variable name{23821
{{bnz{13,vrlen(xr){6,kwnm1{{error if not system variable{23822
{{mov{7,xr{13,vrsvp(xr){{else point to svblk{23823
{{mov{8,wa{13,svbit(xr){{load bit mask{23824
{{anb{8,wa{4,btknm{{and with keyword bit{23825
{{zrb{8,wa{6,kwnm1{{error if no keyword association{23826
{{mov{8,wa{13,svlen(xr){{else load name length in characters{23827
{{ctb{8,wa{2,svchs{{compute offset to field we want{23828
{{add{7,xr{8,wa{{point to svknm field{23829
{{mov{8,wb{9,(xr){{load svknm value{23830
{{mov{8,wa{19,*kvsi_{{set size of kvblk{23831
{{jsr{6,alloc{{{allocate kvblk{23832
{{mov{9,(xr){22,=b_kvt{{store type word{23833
{{mov{13,kvnum(xr){8,wb{{store keyword number{23834
{{mov{13,kvvar(xr){21,=trbkv{{set dummy trblk pointer{23835
{{mov{7,xl{7,xr{{copy kvblk pointer{23836
{{mov{8,wa{19,*kvvar{{set proper offset{23837
{{exi{{{{return to kvnam caller{23838
*      here if not keyword name
{kwnm1{erb{1,251{26,keyword operand is not name of defined keyword{{{23842
{{enp{{{{end procedure kwnam{23843
{{ejc{{{{{23844
*      lcomp-- compare two strings lexically
*      1(xs)                 first argument
*      0(xs)                 second argument
*      jsr  lcomp            call to compare aruments
*      ppm  loc              transfer loc for arg1 not string
*      ppm  loc              transfer loc for arg2 not string
*      ppm  loc              transfer loc if arg1 llt arg2
*      ppm  loc              transfer loc if arg1 leq arg2
*      ppm  loc              transfer loc if arg1 lgt arg2
*      (the normal return is never taken)
*      (xs)                  popped twice
*      (xr,xl)               destroyed
*      (wa,wb,wc,ra)         destroyed
{lcomp{prc{25,n{1,5{{entry point{23861
{{jsr{6,gtstg{{{convert second arg to string{23863
{{ppm{6,lcmp6{{{jump if second arg not string{23867
{{mov{7,xl{7,xr{{else save pointer{23868
{{mov{8,wc{8,wa{{and length{23869
{{jsr{6,gtstg{{{convert first argument to string{23871
{{ppm{6,lcmp5{{{jump if not string{23875
{{mov{8,wb{8,wa{{save arg 1 length{23876
{{plc{7,xr{{{point to chars of arg 1{23877
{{plc{7,xl{{{point to chars of arg 2{23878
{{blo{8,wa{8,wc{6,lcmp1{jump if arg 1 length is smaller{23890
{{mov{8,wa{8,wc{{else set arg 2 length as smaller{23891
*      here with smaller length in (wa)
{lcmp1{bze{8,wa{6,lcmp7{{if null string, compare lengths{23895
{{cmc{6,lcmp4{6,lcmp3{{compare strings, jump if unequal{23896
{lcmp7{bne{8,wb{8,wc{6,lcmp2{if equal, jump if lengths unequal{23897
{{exi{1,4{{{else identical strings, leq exit{23898
{{ejc{{{{{23899
*      lcomp (continued)
*      here if initial strings identical, but lengths unequal
{lcmp2{bhi{8,wb{8,wc{6,lcmp4{jump if arg 1 length gt arg 2 leng{23905
*      here if first arg llt second arg
{lcmp3{exi{1,3{{{take llt exit{23910
*      here if first arg lgt second arg
{lcmp4{exi{1,5{{{take lgt exit{23914
*      here if first arg is not a string
{lcmp5{exi{1,1{{{take bad first arg exit{23918
*      here for second arg not a string
{lcmp6{exi{1,2{{{take bad second arg error exit{23922
{{enp{{{{end procedure lcomp{23923
{{ejc{{{{{23924
*      listr -- list source line
*      listr is used to list a source line during the initial
*      compilation. it is called from scane and scanl.
*      jsr  listr            call to list line
*      (xr,xl,wa,wb,wc)      destroyed
*      global locations used by listr
*      cnttl                 flag for -title, -stitl
*      erlst                 if listing on account of an error
*      lstid                 include depth of current image
*      lstlc                 count lines on current page
*      lstnp                 max number of lines/page
*      lstpf                 set non-zero if the current source
*                            line has been listed, else zero.
*      lstpg                 compiler listing page number
*      lstsn                 set if stmnt num to be listed
*      r_cim                 pointer to current input line.
*      r_ttl                 title for source listing
*      r_stl                 ptr to sub-title string
*      entry point
{listr{prc{25,e{1,0{{entry point{23963
{{bnz{3,cnttl{6,list5{{jump if -title or -stitl{23964
{{bnz{3,lstpf{6,list4{{immediate exit if already listed{23965
{{bge{3,lstlc{3,lstnp{6,list6{jump if no room{23966
*      here after printing title (if needed)
{list0{mov{7,xr{3,r_cim{{load pointer to current image{23970
{{bze{7,xr{6,list4{{jump if no image to print{23971
{{plc{7,xr{{{point to characters{23972
{{lch{8,wa{9,(xr){{load first character{23973
{{mov{7,xr{3,lstsn{{load statement number{23974
{{bze{7,xr{6,list2{{jump if no statement number{23975
{{mti{7,xr{{{else get stmnt number as integer{23976
{{bne{3,stage{18,=stgic{6,list1{skip if execute time{23977
{{beq{8,wa{18,=ch_as{6,list2{no stmnt number list if comment{23978
{{beq{8,wa{18,=ch_mn{6,list2{no stmnt no. if control card{23979
*      print statement number
{list1{jsr{6,prtin{{{else print statement number{23983
{{zer{3,lstsn{{{and clear for next time in{23984
*      here to test for printing include depth
{list2{mov{7,xr{3,lstid{{include depth of image{23989
{{bze{7,xr{6,list8{{if not from an include file{23990
{{mov{8,wa{18,=stnpd{{position for start of statement{23991
{{sub{8,wa{18,=num03{{position to place include depth{23992
{{mov{3,profs{8,wa{{set as starting position{23993
{{mti{7,xr{{{include depth as integer{23994
{{jsr{6,prtin{{{print include depth{23995
{{ejc{{{{{23996
*      listr (continued)
*      here after printing statement number and include depth
{list8{mov{3,profs{18,=stnpd{{point past statement number{24002
{{mov{7,xr{3,r_cim{{load pointer to current image{24012
{{jsr{6,prtst{{{print it{24013
{{icv{3,lstlc{{{bump line counter{24014
{{bnz{3,erlst{6,list3{{jump if error copy to int.ch.{24015
{{jsr{6,prtnl{{{terminate line{24016
{{bze{3,cswdb{6,list3{{jump if -single mode{24017
{{jsr{6,prtnl{{{else add a blank line{24018
{{icv{3,lstlc{{{and bump line counter{24019
*      here after printing source image
{list3{mnz{3,lstpf{{{set flag for line printed{24023
*      merge here to exit
{list4{exi{{{{return to listr caller{24027
*      print title after -title or -stitl card
{list5{zer{3,cnttl{{{clear flag{24031
*      eject to new page and list title
{list6{jsr{6,prtps{{{eject{24035
{{bze{3,prich{6,list7{{skip if listing to regular printer{24036
{{beq{3,r_ttl{21,=nulls{6,list0{terminal listing omits null title{24037
*      list title
{list7{jsr{6,listt{{{list title{24041
{{brn{6,list0{{{merge{24042
{{enp{{{{end procedure listr{24043
{{ejc{{{{{24044
*      listt -- list title and subtitle
*      used during compilation to print page heading
*      jsr  listt            call to list title
*      (xr,wa)               destroyed
{listt{prc{25,e{1,0{{entry point{24053
{{mov{7,xr{3,r_ttl{{point to source listing title{24054
{{jsr{6,prtst{{{print title{24055
{{mov{3,profs{3,lstpo{{set offset{24056
{{mov{7,xr{21,=lstms{{set page message{24057
{{jsr{6,prtst{{{print page message{24058
{{icv{3,lstpg{{{bump page number{24059
{{mti{3,lstpg{{{load page number as integer{24060
{{jsr{6,prtin{{{print page number{24061
{{jsr{6,prtnl{{{terminate title line{24062
{{add{3,lstlc{18,=num02{{count title line and blank line{24063
*      print sub-title (if any)
{{mov{7,xr{3,r_stl{{load pointer to sub-title{24067
{{bze{7,xr{6,lstt1{{jump if no sub-title{24068
{{jsr{6,prtst{{{else print sub-title{24069
{{jsr{6,prtnl{{{terminate line{24070
{{icv{3,lstlc{{{bump line count{24071
*      return point
{lstt1{jsr{6,prtnl{{{print a blank line{24075
{{exi{{{{return to caller{24076
{{enp{{{{end procedure listt{24077
{{ejc{{{{{24078
*      newfn -- record new source file name
*      newfn is used after switching to a new include file, or
*      after a -line statement which contains a file name.
*      (xr)                  file name scblk
*      jsr  newfn
*      (wa,wb,wc,xl,xr,ra)   destroyed
*      on return, the table that maps statement numbers to file
*      names has been updated to include this new file name and
*      the current statement number.  the entry is made only if
*      the file name had changed from its previous value.
{newfn{prc{25,e{1,0{{entry point{24095
{{mov{11,-(xs){7,xr{{save new name{24096
{{mov{7,xl{3,r_sfc{{load previous name{24097
{{jsr{6,ident{{{check for equality{24098
{{ppm{6,nwfn1{{{jump if identical{24099
{{mov{7,xr{10,(xs)+{{different, restore name{24100
{{mov{3,r_sfc{7,xr{{record current file name{24101
{{mov{8,wb{3,cmpsn{{get current statement{24102
{{mti{8,wb{{{convert to integer{24103
{{jsr{6,icbld{{{build icblk for stmt number{24104
{{mov{7,xl{3,r_sfn{{file name table{24105
{{mnz{8,wb{{{lookup statement number by name{24106
{{jsr{6,tfind{{{allocate new teblk{24107
{{ppm{{{{always possible to allocate block{24108
{{mov{13,teval(xl){3,r_sfc{{record file name as entry value{24109
{{exi{{{{{24110
*     here if new name and old name identical
{nwfn1{ica{7,xs{{{pop stack{24114
{{exi{{{{{24115
{{ejc{{{{{24116
*      nexts -- acquire next source image
*      nexts is used to acquire the next source image at compile
*      time. it assumes that a prior call to readr has input
*      a line image (see procedure readr). before the current
*      image is finally lost it may be listed here.
*      jsr  nexts            call to acquire next input line
*      (xr,xl,wa,wb,wc)      destroyed
*      global values affected
*      lstid                 include depth of next image
*      r_cni                 on input, next image. on
*                            exit reset to zero
*      r_cim                 on exit, set to point to image
*      rdcln                 current ln set from next line num
*      scnil                 input image length on exit
*      scnse                 reset to zero on exit
*      lstpf                 set on exit if line is listed
{nexts{prc{25,e{1,0{{entry point{24148
{{bze{3,cswls{6,nxts2{{jump if -nolist{24149
{{mov{7,xr{3,r_cim{{point to image{24150
{{bze{7,xr{6,nxts2{{jump if no image{24151
{{plc{7,xr{{{get char ptr{24152
{{lch{8,wa{9,(xr){{get first char{24153
{{bne{8,wa{18,=ch_mn{6,nxts1{jump if not ctrl card{24154
{{bze{3,cswpr{6,nxts2{{jump if -noprint{24155
*      here to call lister
{nxts1{jsr{6,listr{{{list line{24159
*      here after possible listing
{nxts2{mov{7,xr{3,r_cni{{point to next image{24163
{{mov{3,r_cim{7,xr{{set as next image{24164
{{mov{3,rdcln{3,rdnln{{set as current line number{24165
{{mov{3,lstid{3,cnind{{set as current include depth{24167
{{zer{3,r_cni{{{clear next image pointer{24169
{{mov{8,wa{13,sclen(xr){{get input image length{24170
{{mov{8,wb{3,cswin{{get max allowable length{24171
{{blo{8,wa{8,wb{6,nxts3{skip if not too long{24172
{{mov{8,wa{8,wb{{else truncate{24173
*      here with length in (wa)
{nxts3{mov{3,scnil{8,wa{{use as record length{24177
{{zer{3,scnse{{{reset scnse{24178
{{zer{3,lstpf{{{set line not listed yet{24179
{{exi{{{{return to nexts caller{24180
{{enp{{{{end procedure nexts{24181
{{ejc{{{{{24182
*      patin -- pattern construction for len,pos,rpos,tab,rtab
*      these pattern types all generate a similar node type. so
*      the construction code is shared. see functions section
*      for actual entry points for these five functions.
*      (wa)                  pcode for expression arg case
*      (wb)                  pcode for integer arg case
*      jsr  patin            call to build pattern node
*      ppm  loc              transfer loc for not integer or exp
*      ppm  loc              transfer loc for int out of range
*      (xr)                  pointer to constructed node
*      (xl,wa,wb,wc,ia)      destroyed
{patin{prc{25,n{1,2{{entry point{24198
{{mov{7,xl{8,wa{{preserve expression arg pcode{24199
{{jsr{6,gtsmi{{{try to convert arg as small integer{24200
{{ppm{6,ptin2{{{jump if not integer{24201
{{ppm{6,ptin3{{{jump if out of range{24202
*      common successful exit point
{ptin1{jsr{6,pbild{{{build pattern node{24206
{{exi{{{{return to caller{24207
*      here if argument is not an integer
{ptin2{mov{8,wb{7,xl{{copy expr arg case pcode{24211
{{blo{9,(xr){22,=b_e__{6,ptin1{all ok if expression arg{24212
{{exi{1,1{{{else take error exit for wrong type{24213
*      here for error of out of range integer argument
{ptin3{exi{1,2{{{take out-of-range error exit{24217
{{enp{{{{end procedure patin{24218
{{ejc{{{{{24219
*      patst -- pattern construction for any,notany,
*               break,span and breakx pattern functions.
*      these pattern functions build similar types of nodes and
*      the construction code is shared. see functions section
*      for actual entry points for these five pattern functions.
*      0(xs)                 string argument
*      (wb)                  pcode for one char argument
*      (xl)                  pcode for multi-char argument
*      (wc)                  pcode for expression argument
*      jsr  patst            call to build node
*      ppm  loc              if not string or expr (or null)
*      (xs)                  popped past string argument
*      (xr)                  pointer to constructed node
*      (xl)                  destroyed
*      (wa,wb,wc,ra)         destroyed
*      note that there is a special call to patst in the evals
*      procedure with a slightly different form. see evals
*      for details of the form of this call.
{patst{prc{25,n{1,1{{entry point{24243
{{jsr{6,gtstg{{{convert argument as string{24244
{{ppm{6,pats7{{{jump if not string{24245
{{bze{8,wa{6,pats7{{jump if null string (catspaw){24246
{{bne{8,wa{18,=num01{6,pats2{jump if not one char string{24247
*      here for one char string case
{{bze{8,wb{6,pats2{{treat as multi-char if evals call{24251
{{plc{7,xr{{{point to character{24252
{{lch{7,xr{9,(xr){{load character{24253
*      common exit point after successful construction
{pats1{jsr{6,pbild{{{call routine to build node{24257
{{exi{{{{return to patst caller{24258
{{ejc{{{{{24259
*      patst (continued)
*      here for multi-character string case
{pats2{mov{11,-(xs){7,xl{{save multi-char pcode{24265
{{mov{8,wc{3,ctmsk{{load current mask bit{24266
{{beq{7,xr{3,r_cts{6,pats6{jump if same as last string c3.738{24267
{{mov{11,-(xs){7,xr{{save string pointer{24268
{{lsh{8,wc{1,1{{shift to next position{24269
{{nzb{8,wc{6,pats4{{skip if position left in this tbl{24270
*      here we must allocate a new character table
{{mov{8,wa{19,*ctsi_{{set size of ctblk{24274
{{jsr{6,alloc{{{allocate ctblk{24275
{{mov{3,r_ctp{7,xr{{store ptr to new ctblk{24276
{{mov{10,(xr)+{22,=b_ctt{{store type code, bump ptr{24277
{{lct{8,wb{18,=cfp_a{{set number of words to clear{24278
{{mov{8,wc{4,bits0{{load all zero bits{24279
*      loop to clear all bits in table to zeros
{pats3{mov{10,(xr)+{8,wc{{move word of zero bits{24283
{{bct{8,wb{6,pats3{{loop till all cleared{24284
{{mov{8,wc{4,bits1{{set initial bit position{24285
*      merge here with bit position available
{pats4{mov{3,ctmsk{8,wc{{save parm2 (new bit position){24289
{{mov{7,xl{10,(xs)+{{restore pointer to argument string{24290
{{mov{3,r_cts{7,xl{{save for next time   c3.738{24291
{{mov{8,wb{13,sclen(xl){{load string length{24292
{{bze{8,wb{6,pats6{{jump if null string case{24293
{{lct{8,wb{8,wb{{else set loop counter{24294
{{plc{7,xl{{{point to characters in argument{24295
{{ejc{{{{{24296
*      patst (continued)
*      loop to set bits in column of table
{pats5{lch{8,wa{10,(xl)+{{load next character{24302
{{wtb{8,wa{{{convert to byte offset{24303
{{mov{7,xr{3,r_ctp{{point to ctblk{24304
{{add{7,xr{8,wa{{point to ctblk entry{24305
{{mov{8,wa{8,wc{{copy bit mask{24306
{{orb{8,wa{13,ctchs(xr){{or in bits already set{24307
{{mov{13,ctchs(xr){8,wa{{store resulting bit string{24308
{{bct{8,wb{6,pats5{{loop till all bits set{24309
*      complete processing for multi-char string case
{pats6{mov{7,xr{3,r_ctp{{load ctblk ptr as parm1 for pbild{24313
{{zer{7,xl{{{clear garbage ptr in xl{24314
{{mov{8,wb{10,(xs)+{{load pcode for multi-char str case{24315
{{brn{6,pats1{{{back to exit (wc=bitstring=parm2){24316
*      here if argument is not a string
*      note that the call from evals cannot pass an expression
*      since evalp always reevaluates expressions.
{pats7{mov{8,wb{8,wc{{set pcode for expression argument{24323
{{blo{9,(xr){22,=b_e__{6,pats1{jump to exit if expression arg{24324
{{exi{1,1{{{else take wrong type error exit{24325
{{enp{{{{end procedure patst{24326
{{ejc{{{{{24327
*      pbild -- build pattern node
*      (xr)                  parm1 (only if required)
*      (wb)                  pcode for node
*      (wc)                  parm2 (only if required)
*      jsr  pbild            call to build node
*      (xr)                  pointer to constructed node
*      (wa)                  destroyed
{pbild{prc{25,e{1,0{{entry point{24338
{{mov{11,-(xs){7,xr{{stack possible parm1{24339
{{mov{7,xr{8,wb{{copy pcode{24340
{{lei{7,xr{{{load entry point id (bl_px){24341
{{beq{7,xr{18,=bl_p1{6,pbld1{jump if one parameter{24342
{{beq{7,xr{18,=bl_p0{6,pbld3{jump if no parameters{24343
*      here for two parameter case
{{mov{8,wa{19,*pcsi_{{set size of p2blk{24347
{{jsr{6,alloc{{{allocate block{24348
{{mov{13,parm2(xr){8,wc{{store second parameter{24349
{{brn{6,pbld2{{{merge with one parm case{24350
*      here for one parameter case
{pbld1{mov{8,wa{19,*pbsi_{{set size of p1blk{24354
{{jsr{6,alloc{{{allocate node{24355
*      merge here from two parm case
{pbld2{mov{13,parm1(xr){9,(xs){{store first parameter{24359
{{brn{6,pbld4{{{merge with no parameter case{24360
*      here for case of no parameters
{pbld3{mov{8,wa{19,*pasi_{{set size of p0blk{24364
{{jsr{6,alloc{{{allocate node{24365
*      merge here from other cases
{pbld4{mov{9,(xr){8,wb{{store pcode{24369
{{ica{7,xs{{{pop first parameter{24370
{{mov{13,pthen(xr){21,=ndnth{{set nothen successor pointer{24371
{{exi{{{{return to pbild caller{24372
{{enp{{{{end procedure pbild{24373
{{ejc{{{{{24374
*      pconc -- concatenate two patterns
*      (xl)                  ptr to right pattern
*      (xr)                  ptr to left pattern
*      jsr  pconc            call to concatenate patterns
*      (xr)                  ptr to concatenated pattern
*      (xl,wa,wb,wc)         destroyed
*      to concatenate two patterns, all successors in the left
*      pattern which point to the nothen node must be changed to
*      point to the right pattern. however, this modification
*      must be performed on a copy of the left argument rather
*      than the left argument itself, since the left argument
*      may be pointed to by some other variable value.
*      accordingly, it is necessary to copy the left argument.
*      this is not a trivial process since we must avoid copying
*      nodes more than once and the pattern is a graph structure
*      the following algorithm is employed.
*      the stack is used to store a list of nodes which
*      have already been copied. the format of the entries on
*      this list consists of a two word block. the first word
*      is the old address and the second word is the address
*      of the copy. this list is searched by the pcopy
*      routine to avoid making duplicate copies. a trick is
*      used to accomplish the concatenation at the same time.
*      a special entry is made to start with on the stack. this
*      entry records that the nothen node has been copied
*      already and the address of its copy is the right pattern.
*      this automatically performs the correct replacements.
{pconc{prc{25,e{1,0{{entry point{24409
{{zer{11,-(xs){{{make room for one entry at bottom{24410
{{mov{8,wc{7,xs{{store pointer to start of list{24411
{{mov{11,-(xs){21,=ndnth{{stack nothen node as old node{24412
{{mov{11,-(xs){7,xl{{store right arg as copy of nothen{24413
{{mov{7,xt{7,xs{{initialize pointer to stack entries{24414
{{jsr{6,pcopy{{{copy first node of left arg{24415
{{mov{13,num02(xt){8,wa{{store as result under list{24416
{{ejc{{{{{24417
*      pconc (continued)
*      the following loop scans entries in the list and makes
*      sure that their successors have been copied.
{pcnc1{beq{7,xt{7,xs{6,pcnc2{jump if all entries processed{24424
{{mov{7,xr{11,-(xt){{else load next old address{24425
{{mov{7,xr{13,pthen(xr){{load pointer to successor{24426
{{jsr{6,pcopy{{{copy successor node{24427
{{mov{7,xr{11,-(xt){{load pointer to new node (copy){24428
{{mov{13,pthen(xr){8,wa{{store ptr to new successor{24429
*      now check for special case of alternation node where
*      parm1 points to a node and must be copied like pthen.
{{bne{9,(xr){22,=p_alt{6,pcnc1{loop back if not{24434
{{mov{7,xr{13,parm1(xr){{else load pointer to alternative{24435
{{jsr{6,pcopy{{{copy it{24436
{{mov{7,xr{9,(xt){{restore ptr to new node{24437
{{mov{13,parm1(xr){8,wa{{store ptr to copied alternative{24438
{{brn{6,pcnc1{{{loop back for next entry{24439
*      here at end of copy process
{pcnc2{mov{7,xs{8,wc{{restore stack pointer{24443
{{mov{7,xr{10,(xs)+{{load pointer to copy{24444
{{exi{{{{return to pconc caller{24445
{{enp{{{{end procedure pconc{24446
{{ejc{{{{{24447
*      pcopy -- copy a pattern node
*      pcopy is called from the pconc procedure to copy a single
*      pattern node. the copy is only carried out if the node
*      has not been copied already.
*      (xr)                  pointer to node to be copied
*      (xt)                  ptr to current loc in copy list
*      (wc)                  pointer to list of copied nodes
*      jsr  pcopy            call to copy a node
*      (wa)                  pointer to copy
*      (wb,xr)               destroyed
{pcopy{prc{25,n{1,0{{entry point{24462
{{mov{8,wb{7,xt{{save xt{24463
{{mov{7,xt{8,wc{{point to start of list{24464
*      loop to search list of nodes copied already
{pcop1{dca{7,xt{{{point to next entry on list{24468
{{beq{7,xr{9,(xt){6,pcop2{jump if match{24469
{{dca{7,xt{{{else skip over copied address{24470
{{bne{7,xt{7,xs{6,pcop1{loop back if more to test{24471
*      here if not in list, perform copy
{{mov{8,wa{9,(xr){{load first word of block{24475
{{jsr{6,blkln{{{get length of block{24476
{{mov{7,xl{7,xr{{save pointer to old node{24477
{{jsr{6,alloc{{{allocate space for copy{24478
{{mov{11,-(xs){7,xl{{store old address on list{24479
{{mov{11,-(xs){7,xr{{store new address on list{24480
{{chk{{{{check for stack overflow{24481
{{mvw{{{{move words from old block to copy{24482
{{mov{8,wa{9,(xs){{load pointer to copy{24483
{{brn{6,pcop3{{{jump to exit{24484
*      here if we find entry in list
{pcop2{mov{8,wa{11,-(xt){{load address of copy from list{24488
*      common exit point
{pcop3{mov{7,xt{8,wb{{restore xt{24492
{{exi{{{{return to pcopy caller{24493
{{enp{{{{end procedure pcopy{24494
{{ejc{{{{{24495
*      prflr -- print profile
*      prflr is called to print the contents of the profile
*      table in a fairly readable tabular format.
*      jsr  prflr            call to print profile
*      (wa,ia)               destroyed
{prflr{prc{25,e{1,0{{{24506
{{bze{3,pfdmp{6,prfl4{{no printing if no profiling done{24507
{{mov{11,-(xs){7,xr{{preserve entry xr{24508
{{mov{3,pfsvw{8,wb{{and also wb{24509
{{jsr{6,prtpg{{{eject{24510
{{mov{7,xr{21,=pfms1{{load msg /program profile/{24511
{{jsr{6,prtst{{{and print it{24512
{{jsr{6,prtnl{{{followed by newline{24513
{{jsr{6,prtnl{{{and another{24514
{{mov{7,xr{21,=pfms2{{point to first hdr{24515
{{jsr{6,prtst{{{print it{24516
{{jsr{6,prtnl{{{new line{24517
{{mov{7,xr{21,=pfms3{{second hdr{24518
{{jsr{6,prtst{{{print it{24519
{{jsr{6,prtnl{{{new line{24520
{{jsr{6,prtnl{{{and another blank line{24521
{{zer{8,wb{{{initial stmt count{24522
{{mov{7,xr{3,pftbl{{point to table origin{24523
{{add{7,xr{19,*xndta{{bias past xnblk header (sgd07){24524
*      loop here to print successive entries
{prfl1{icv{8,wb{{{bump stmt nr{24528
{{ldi{9,(xr){{{load nr of executions{24529
{{ieq{6,prfl3{{{no printing if zero{24530
{{mov{3,profs{18,=pfpd1{{point where to print{24531
{{jsr{6,prtin{{{and print it{24532
{{zer{3,profs{{{back to start of line{24533
{{mti{8,wb{{{load stmt nr{24534
{{jsr{6,prtin{{{print it there{24535
{{mov{3,profs{18,=pfpd2{{and pad past count{24536
{{ldi{13,cfp_i(xr){{{load total exec time{24537
{{jsr{6,prtin{{{print that too{24538
{{ldi{13,cfp_i(xr){{{reload time{24539
{{mli{4,intth{{{convert to microsec{24540
{{iov{6,prfl2{{{omit next bit if overflow{24541
{{dvi{9,(xr){{{divide by executions{24542
{{mov{3,profs{18,=pfpd3{{pad last print{24543
{{jsr{6,prtin{{{and print mcsec/execn{24544
*      merge after printing time
{prfl2{jsr{6,prtnl{{{thats another line{24548
*      here to go to next entry
{prfl3{add{7,xr{19,*pf_i2{{bump index ptr (sgd07){24552
{{blt{8,wb{3,pfnte{6,prfl1{loop if more stmts{24553
{{mov{7,xr{10,(xs)+{{restore callers xr{24554
{{mov{8,wb{3,pfsvw{{and wb too{24555
*      here to exit
{prfl4{exi{{{{return{24559
{{enp{{{{end of prflr{24560
{{ejc{{{{{24561
*      prflu -- update an entry in the profile table
*      on entry, kvstn contains nr of stmt to profile
*      jsr  prflu            call to update entry
*      (ia)                  destroyed
{prflu{prc{25,e{1,0{{{24570
{{bnz{3,pffnc{6,pflu4{{skip if just entered function{24571
{{mov{11,-(xs){7,xr{{preserve entry xr{24572
{{mov{3,pfsvw{8,wa{{save wa (sgd07){24573
{{bnz{3,pftbl{6,pflu2{{branch if table allocated{24574
*      here if space for profile table not yet allocated.
*      calculate size needed, allocate a static xnblk, and
*      initialize it all to zero.
*      the time taken for this will be attributed to the current
*      statement (assignment to keywd profile), but since the
*      timing for this statement is up the pole anyway, this
*      doesnt really matter...
{{sub{3,pfnte{18,=num01{{adjust for extra count (sgd07){24584
{{mti{4,pfi2a{{{convrt entry size to int{24585
{{sti{3,pfste{{{and store safely for later{24586
{{mti{3,pfnte{{{load table length as integer{24587
{{mli{3,pfste{{{multiply by entry size{24588
{{mfi{8,wa{{{get back address-style{24589
{{add{8,wa{18,=num02{{add on 2 word overhead{24590
{{wtb{8,wa{{{convert the whole lot to bytes{24591
{{jsr{6,alost{{{gimme the space{24592
{{mov{3,pftbl{7,xr{{save block pointer{24593
{{mov{10,(xr)+{22,=b_xnt{{put block type and ...{24594
{{mov{10,(xr)+{8,wa{{... length into header{24595
{{mfi{8,wa{{{get back nr of wds in data area{24596
{{lct{8,wa{8,wa{{load the counter{24597
*      loop here to zero the block data
{pflu1{zer{10,(xr)+{{{blank a word{24601
{{bct{8,wa{6,pflu1{{and alllllll the rest{24602
*      end of allocation. merge back into routine
{pflu2{mti{3,kvstn{{{load nr of stmt just ended{24606
{{sbi{4,intv1{{{make into index offset{24607
{{mli{3,pfste{{{make offset of table entry{24608
{{mfi{8,wa{{{convert to address{24609
{{wtb{8,wa{{{get as baus{24610
{{add{8,wa{19,*num02{{offset includes table header{24611
{{mov{7,xr{3,pftbl{{get table start{24612
{{bge{8,wa{13,num01(xr){6,pflu3{if out of table, skip it{24613
{{add{7,xr{8,wa{{else point to entry{24614
{{ldi{9,(xr){{{get nr of executions so far{24615
{{adi{4,intv1{{{nudge up one{24616
{{sti{9,(xr){{{and put back{24617
{{jsr{6,systm{{{get time now{24618
{{sti{3,pfetm{{{stash ending time{24619
{{sbi{3,pfstm{{{subtract start time{24620
{{adi{13,cfp_i(xr){{{add cumulative time so far{24621
{{sti{13,cfp_i(xr){{{and put back new total{24622
{{ldi{3,pfetm{{{load end time of this stmt ...{24623
{{sti{3,pfstm{{{... which is start time of next{24624
*      merge here to exit
{pflu3{mov{7,xr{10,(xs)+{{restore callers xr{24628
{{mov{8,wa{3,pfsvw{{restore saved reg{24629
{{exi{{{{and return{24630
*      here if profile is suppressed because a program defined
*      function is about to be entered, and so the current stmt
*      has not yet finished
{pflu4{zer{3,pffnc{{{reset the condition flag{24636
{{exi{{{{and immediate return{24637
{{enp{{{{end of procedure prflu{24638
{{ejc{{{{{24639
*      prpar - process print parameters
*      (wc)                  if nonzero associate terminal only
*      jsr  prpar            call to process print parameters
*      (xl,xr,wa,wb,wc)      destroyed
*      since memory allocation is undecided on initial call,
*      terminal cannot be associated. the entry with wc non-zero
*      is provided so a later call can be made to complete this.
{prpar{prc{25,e{1,0{{entry point{24652
{{bnz{8,wc{6,prpa8{{jump to associate terminal{24653
{{jsr{6,syspp{{{get print parameters{24654
{{bnz{8,wb{6,prpa1{{jump if lines/page specified{24655
{{mov{8,wb{3,mxint{{else use a large value{24656
{{rsh{8,wb{1,1{{but not too large{24657
*      store line count/page
{prpa1{mov{3,lstnp{8,wb{{store number of lines/page{24661
{{mov{3,lstlc{8,wb{{pretend page is full initially{24662
{{zer{3,lstpg{{{clear page number{24663
{{mov{8,wb{3,prlen{{get prior length if any{24664
{{bze{8,wb{6,prpa2{{skip if no length{24665
{{bgt{8,wa{8,wb{6,prpa3{skip storing if too big{24666
*      store print buffer length
{prpa2{mov{3,prlen{8,wa{{store value{24670
*      process bits options
{prpa3{mov{8,wb{4,bits3{{bit 3 mask{24674
{{anb{8,wb{8,wc{{get -nolist bit{24675
{{zrb{8,wb{6,prpa4{{skip if clear{24676
{{zer{3,cswls{{{set -nolist{24677
*      check if fail reports goto interactive channel
{prpa4{mov{8,wb{4,bits1{{bit 1 mask{24681
{{anb{8,wb{8,wc{{get bit{24682
{{mov{3,erich{8,wb{{store int. chan. error flag{24683
{{mov{8,wb{4,bits2{{bit 2 mask{24684
{{anb{8,wb{8,wc{{get bit{24685
{{mov{3,prich{8,wb{{flag for std printer on int. chan.{24686
{{mov{8,wb{4,bits4{{bit 4 mask{24687
{{anb{8,wb{8,wc{{get bit{24688
{{mov{3,cpsts{8,wb{{flag for compile stats suppressn.{24689
{{mov{8,wb{4,bits5{{bit 5 mask{24690
{{anb{8,wb{8,wc{{get bit{24691
{{mov{3,exsts{8,wb{{flag for exec stats suppression{24692
{{ejc{{{{{24693
*      prpar (continued)
{{mov{8,wb{4,bits6{{bit 6 mask{24697
{{anb{8,wb{8,wc{{get bit{24698
{{mov{3,precl{8,wb{{extended/compact listing flag{24699
{{sub{8,wa{18,=num08{{point 8 chars from line end{24700
{{zrb{8,wb{6,prpa5{{jump if not extended{24701
{{mov{3,lstpo{8,wa{{store for listing page headings{24702
*       continue option processing
{prpa5{mov{8,wb{4,bits7{{bit 7 mask{24706
{{anb{8,wb{8,wc{{get bit 7{24707
{{mov{3,cswex{8,wb{{set -noexecute if non-zero{24708
{{mov{8,wb{4,bit10{{bit 10 mask{24709
{{anb{8,wb{8,wc{{get bit 10{24710
{{mov{3,headp{8,wb{{pretend printed to omit headers{24711
{{mov{8,wb{4,bits9{{bit 9 mask{24712
{{anb{8,wb{8,wc{{get bit 9{24713
{{mov{3,prsto{8,wb{{keep it as std listing option{24714
{{mov{8,wb{4,bit12{{bit 12 mask{24721
{{anb{8,wb{8,wc{{get bit 12{24722
{{mov{3,cswer{8,wb{{keep it as errors/noerrors option{24723
{{zrb{8,wb{6,prpa6{{skip if clear{24724
{{mov{8,wa{3,prlen{{get print buffer length{24725
{{sub{8,wa{18,=num08{{point 8 chars from line end{24726
{{mov{3,lstpo{8,wa{{store page offset{24727
*      check for -print/-noprint
{prpa6{mov{8,wb{4,bit11{{bit 11 mask{24731
{{anb{8,wb{8,wc{{get bit 11{24732
{{mov{3,cswpr{8,wb{{set -print if non-zero{24733
*      check for terminal
{{anb{8,wc{4,bits8{{see if terminal to be activated{24737
{{bnz{8,wc{6,prpa8{{jump if terminal required{24738
{{bze{3,initr{6,prpa9{{jump if no terminal to detach{24739
{{mov{7,xl{21,=v_ter{{ptr to /terminal/{24740
{{jsr{6,gtnvr{{{get vrblk pointer{24741
{{ppm{{{{cant fail{24742
{{mov{13,vrval(xr){21,=nulls{{clear value of terminal{24743
{{jsr{6,setvr{{{remove association{24744
{{brn{6,prpa9{{{return{24745
*      associate terminal
{prpa8{mnz{3,initr{{{note terminal associated{24749
{{bze{3,dnamb{6,prpa9{{cant if memory not organised{24750
{{mov{7,xl{21,=v_ter{{point to terminal string{24751
{{mov{8,wb{18,=trtou{{output trace type{24752
{{jsr{6,inout{{{attach output trblk to vrblk{24753
{{mov{11,-(xs){7,xr{{stack trblk ptr{24754
{{mov{7,xl{21,=v_ter{{point to terminal string{24755
{{mov{8,wb{18,=trtin{{input trace type{24756
{{jsr{6,inout{{{attach input trace blk{24757
{{mov{13,vrval(xr){10,(xs)+{{add output trblk to chain{24758
*      return point
{prpa9{exi{{{{return{24762
{{enp{{{{end procedure prpar{24763
{{ejc{{{{{24764
*      prtch -- print a character
*      prtch is used to print a single character
*      (wa)                  character to be printed
*      jsr  prtch            call to print character
{prtch{prc{25,e{1,0{{entry point{24773
{{mov{11,-(xs){7,xr{{save xr{24774
{{bne{3,profs{3,prlen{6,prch1{jump if room in buffer{24775
{{jsr{6,prtnl{{{else print this line{24776
*      here after making sure we have room
{prch1{mov{7,xr{3,prbuf{{point to print buffer{24780
{{psc{7,xr{3,profs{{point to next character location{24781
{{sch{8,wa{9,(xr){{store new character{24782
{{csc{7,xr{{{complete store characters{24783
{{icv{3,profs{{{bump pointer{24784
{{mov{7,xr{10,(xs)+{{restore entry xr{24785
{{exi{{{{return to prtch caller{24786
{{enp{{{{end procedure prtch{24787
{{ejc{{{{{24788
*      prtic -- print to interactive channel
*      prtic is called to print the contents of the standard
*      print buffer to the interactive channel. it is only
*      called after prtst has set up the string for printing.
*      it does not clear the buffer.
*      jsr  prtic            call for print
*      (wa,wb)               destroyed
{prtic{prc{25,e{1,0{{entry point{24800
{{mov{11,-(xs){7,xr{{save xr{24801
{{mov{7,xr{3,prbuf{{point to buffer{24802
{{mov{8,wa{3,profs{{no of chars{24803
{{jsr{6,syspi{{{print{24804
{{ppm{6,prtc2{{{fail return{24805
*      return
{prtc1{mov{7,xr{10,(xs)+{{restore xr{24809
{{exi{{{{return{24810
*      error occured
{prtc2{zer{3,erich{{{prevent looping{24814
{{erb{1,252{26,error on printing to interactive channel{{{24815
{{brn{6,prtc1{{{return{24816
{{enp{{{{procedure prtic{24817
{{ejc{{{{{24818
*      prtis -- print to interactive and standard printer
*      prtis puts a line from the print buffer onto the
*      interactive channel (if any) and the standard printer.
*      it always prints to the standard printer but does
*      not duplicate lines if the standard printer is
*      interactive.  it clears down the print buffer.
*      jsr  prtis            call for printing
*      (wa,wb)               destroyed
{prtis{prc{25,e{1,0{{entry point{24831
{{bnz{3,prich{6,prts1{{jump if standard printer is int.ch.{24832
{{bze{3,erich{6,prts1{{skip if not doing int. error reps.{24833
{{jsr{6,prtic{{{print to interactive channel{24834
*      merge and exit
{prts1{jsr{6,prtnl{{{print to standard printer{24838
{{exi{{{{return{24839
{{enp{{{{end procedure prtis{24840
{{ejc{{{{{24841
*      prtin -- print an integer
*      prtin prints the integer value which is in the integer
*      accumulator. blocks built in dynamic storage
*      during this process are immediately deleted.
*      (ia)                  integer value to be printed
*      jsr  prtin            call to print integer
*      (ia,ra)               destroyed
{prtin{prc{25,e{1,0{{entry point{24853
{{mov{11,-(xs){7,xr{{save xr{24854
{{jsr{6,icbld{{{build integer block{24855
{{blo{7,xr{3,dnamb{6,prti1{jump if icblk below dynamic{24856
{{bhi{7,xr{3,dnamp{6,prti1{jump if above dynamic{24857
{{mov{3,dnamp{7,xr{{immediately delete it{24858
*      delete icblk from dynamic store
{prti1{mov{11,-(xs){7,xr{{stack ptr for gtstg{24862
{{jsr{6,gtstg{{{convert to string{24863
{{ppm{{{{convert error is impossible{24864
{{mov{3,dnamp{7,xr{{reset pointer to delete scblk{24865
{{jsr{6,prtst{{{print integer string{24866
{{mov{7,xr{10,(xs)+{{restore entry xr{24867
{{exi{{{{return to prtin caller{24868
{{enp{{{{end procedure prtin{24869
{{ejc{{{{{24870
*      prtmi -- print message and integer
*      prtmi is used to print messages together with an integer
*      value starting in column 15 (used by the routines at
*      the end of compilation).
*      jsr  prtmi            call to print message and integer
{prtmi{prc{25,e{1,0{{entry point{24880
{{jsr{6,prtst{{{print string message{24881
{{mov{3,profs{18,=prtmf{{set column offset{24882
{{jsr{6,prtin{{{print integer{24883
{{jsr{6,prtnl{{{print line{24884
{{exi{{{{return to prtmi caller{24885
{{enp{{{{end procedure prtmi{24886
{{ejc{{{{{24887
*      prtmm -- print memory used and available
*      prtmm is used to provide memory usage information in
*      both the end-of-compile and end-of-run statistics.
*      jsr  prtmm            call to print memory stats
{prtmm{prc{25,e{1,0{{{24896
{{mov{8,wa{3,dnamp{{next available loc{24897
{{sub{8,wa{3,statb{{minus start{24898
{{mti{8,wa{{{convert to integer{24903
{{mov{7,xr{21,=encm1{{point to /memory used (words)/{24904
{{jsr{6,prtmi{{{print message{24905
{{mov{8,wa{3,dname{{end of memory{24906
{{sub{8,wa{3,dnamp{{minus next available loc{24907
{{mti{8,wa{{{convert to integer{24912
{{mov{7,xr{21,=encm2{{point to /memory available (words)/{24913
{{jsr{6,prtmi{{{print line{24914
{{exi{{{{return to prtmm caller{24915
{{enp{{{{end of procedure prtmm{24916
{{ejc{{{{{24917
*      prtmx  -- as prtmi with extra copy to interactive chan.
*      jsr  prtmx            call for printing
*      (wa,wb)               destroyed
{prtmx{prc{25,e{1,0{{entry point{24924
{{jsr{6,prtst{{{print string message{24925
{{mov{3,profs{18,=prtmf{{set column offset{24926
{{jsr{6,prtin{{{print integer{24927
{{jsr{6,prtis{{{print line{24928
{{exi{{{{return{24929
{{enp{{{{end procedure prtmx{24930
{{ejc{{{{{24931
*      prtnl -- print new line (end print line)
*      prtnl prints the contents of the print buffer, resets
*      the buffer to all blanks and resets the print pointer.
*      jsr  prtnl            call to print line
{prtnl{prc{25,r{1,0{{entry point{24940
{{bnz{3,headp{6,prnl0{{were headers printed{24941
{{jsr{6,prtps{{{no - print them{24942
*      call syspr
{prnl0{mov{11,-(xs){7,xr{{save entry xr{24946
{{mov{3,prtsa{8,wa{{save wa{24947
{{mov{3,prtsb{8,wb{{save wb{24948
{{mov{7,xr{3,prbuf{{load pointer to buffer{24949
{{mov{8,wa{3,profs{{load number of chars in buffer{24950
{{jsr{6,syspr{{{call system print routine{24951
{{ppm{6,prnl2{{{jump if failed{24952
{{lct{8,wa{3,prlnw{{load length of buffer in words{24953
{{add{7,xr{19,*schar{{point to chars of buffer{24954
{{mov{8,wb{4,nullw{{get word of blanks{24955
*      loop to blank buffer
{prnl1{mov{10,(xr)+{8,wb{{store word of blanks, bump ptr{24959
{{bct{8,wa{6,prnl1{{loop till all blanked{24960
*      exit point
{{mov{8,wb{3,prtsb{{restore wb{24964
{{mov{8,wa{3,prtsa{{restore wa{24965
{{mov{7,xr{10,(xs)+{{restore entry xr{24966
{{zer{3,profs{{{reset print buffer pointer{24967
{{exi{{{{return to prtnl caller{24968
*      file full or no output file for load module
{prnl2{bnz{3,prtef{6,prnl3{{jump if not first time{24972
{{mnz{3,prtef{{{mark first occurrence{24973
{{erb{1,253{26,print limit exceeded on standard output channel{{{24974
*      stop at once
{prnl3{mov{8,wb{18,=nini8{{ending code{24978
{{mov{8,wa{3,kvstn{{statement number{24979
{{mov{7,xl{3,r_fcb{{get fcblk chain head{24980
{{jsr{6,sysej{{{stop{24981
{{enp{{{{end procedure prtnl{24982
{{ejc{{{{{24983
*      prtnm -- print variable name
*      prtnm is used to print a character representation of the
*      name of a variable (not a value of datatype name)
*      names of pseudo-variables may not be passed to prtnm.
*      (xl)                  name base
*      (wa)                  name offset
*      jsr  prtnm            call to print name
*      (wb,wc,ra)            destroyed
{prtnm{prc{25,r{1,0{{entry point (recursive, see prtvl){24996
{{mov{11,-(xs){8,wa{{save wa (offset is collectable){24997
{{mov{11,-(xs){7,xr{{save entry xr{24998
{{mov{11,-(xs){7,xl{{save name base{24999
{{bhi{7,xl{3,state{6,prn02{jump if not natural variable{25000
*      here for natural variable name, recognized by the fact
*      that the name base points into the static area.
{{mov{7,xr{7,xl{{point to vrblk{25005
{{jsr{6,prtvn{{{print name of variable{25006
*      common exit point
{prn01{mov{7,xl{10,(xs)+{{restore name base{25010
{{mov{7,xr{10,(xs)+{{restore entry value of xr{25011
{{mov{8,wa{10,(xs)+{{restore wa{25012
{{exi{{{{return to prtnm caller{25013
*      here for case of non-natural variable
{prn02{mov{8,wb{8,wa{{copy name offset{25017
{{bne{9,(xl){22,=b_pdt{6,prn03{jump if array or table{25018
*      for program defined datatype, prt fld name, left paren
{{mov{7,xr{13,pddfp(xl){{load pointer to dfblk{25022
{{add{7,xr{8,wa{{add name offset{25023
{{mov{7,xr{13,pdfof(xr){{load vrblk pointer for field{25024
{{jsr{6,prtvn{{{print field name{25025
{{mov{8,wa{18,=ch_pp{{load left paren{25026
{{jsr{6,prtch{{{print character{25027
{{ejc{{{{{25028
*      prtnm (continued)
*      now we print an identifying name for the object if one
*      can be found. the following code searches for a natural
*      variable which contains this object as value. if such a
*      variable is found, its name is printed, else the value
*      of the object (as printed by prtvl) is used instead.
*      first we point to the parent tbblk if this is the case of
*      a table element. to do this, chase down the trnxt chain.
{prn03{bne{9,(xl){22,=b_tet{6,prn04{jump if we got there (or not te){25041
{{mov{7,xl{13,tenxt(xl){{else move out on chain{25042
{{brn{6,prn03{{{and loop back{25043
*      now we are ready for the search. to speed things up in
*      the case of calls from dump where the same name base
*      will occur repeatedly while dumping an array or table,
*      we remember the last vrblk pointer found in prnmv. so
*      first check to see if we have this one again.
{prn04{mov{7,xr{3,prnmv{{point to vrblk we found last time{25051
{{mov{8,wa{3,hshtb{{point to hash table in case not{25052
{{brn{6,prn07{{{jump into search for special check{25053
*      loop through hash slots
{prn05{mov{7,xr{8,wa{{copy slot pointer{25057
{{ica{8,wa{{{bump slot pointer{25058
{{sub{7,xr{19,*vrnxt{{introduce standard vrblk offset{25059
*      loop through vrblks on one hash chain
{prn06{mov{7,xr{13,vrnxt(xr){{point to next vrblk on hash chain{25063
*      merge here first time to check block we found last time
{prn07{mov{8,wc{7,xr{{copy vrblk pointer{25067
{{bze{8,wc{6,prn09{{jump if chain end (or prnmv zero){25068
{{ejc{{{{{25069
*      prtnm (continued)
*      loop to find value (chase down possible trblk chain)
{prn08{mov{7,xr{13,vrval(xr){{load value{25075
{{beq{9,(xr){22,=b_trt{6,prn08{loop if that was a trblk{25076
*      now we have the value, is this the block we want
{{beq{7,xr{7,xl{6,prn10{jump if this matches the name base{25080
{{mov{7,xr{8,wc{{else point back to that vrblk{25081
{{brn{6,prn06{{{and loop back{25082
*      here to move to next hash slot
{prn09{blt{8,wa{3,hshte{6,prn05{loop back if more to go{25086
{{mov{7,xr{7,xl{{else not found, copy value pointer{25087
{{jsr{6,prtvl{{{print value{25088
{{brn{6,prn11{{{and merge ahead{25089
*      here when we find a matching entry
{prn10{mov{7,xr{8,wc{{copy vrblk pointer{25093
{{mov{3,prnmv{7,xr{{save for next time in{25094
{{jsr{6,prtvn{{{print variable name{25095
*      merge here if no entry found
{prn11{mov{8,wc{9,(xl){{load first word of name base{25099
{{bne{8,wc{22,=b_pdt{6,prn13{jump if not program defined{25100
*      for program defined datatype, add right paren and exit
{{mov{8,wa{18,=ch_rp{{load right paren, merge{25104
*      merge here to print final right paren or bracket
{prn12{jsr{6,prtch{{{print final character{25108
{{mov{8,wa{8,wb{{restore name offset{25109
{{brn{6,prn01{{{merge back to exit{25110
{{ejc{{{{{25111
*      prtnm (continued)
*      here for array or table
{prn13{mov{8,wa{18,=ch_bb{{load left bracket{25117
{{jsr{6,prtch{{{and print it{25118
{{mov{7,xl{9,(xs){{restore block pointer{25119
{{mov{8,wc{9,(xl){{load type word again{25120
{{bne{8,wc{22,=b_tet{6,prn15{jump if not table{25121
*      here for table, print subscript value
{{mov{7,xr{13,tesub(xl){{load subscript value{25125
{{mov{7,xl{8,wb{{save name offset{25126
{{jsr{6,prtvl{{{print subscript value{25127
{{mov{8,wb{7,xl{{restore name offset{25128
*      merge here from array case to print right bracket
{prn14{mov{8,wa{18,=ch_rb{{load right bracket{25132
{{brn{6,prn12{{{merge back to print it{25133
*      here for array or vector, to print subscript(s)
{prn15{mov{8,wa{8,wb{{copy name offset{25137
{{btw{8,wa{{{convert to words{25138
{{beq{8,wc{22,=b_art{6,prn16{jump if arblk{25139
*      here for vector
{{sub{8,wa{18,=vcvlb{{adjust for standard fields{25143
{{mti{8,wa{{{move to integer accum{25144
{{jsr{6,prtin{{{print linear subscript{25145
{{brn{6,prn14{{{merge back for right bracket{25146
{{ejc{{{{{25147
*      prtnm (continued)
*      here for array. first calculate absolute subscript
*      offsets by successive divisions by the dimension values.
*      this must be done right to left since the elements are
*      stored row-wise. the subscripts are stacked as integers.
{prn16{mov{8,wc{13,arofs(xl){{load length of bounds info{25156
{{ica{8,wc{{{adjust for arpro field{25157
{{btw{8,wc{{{convert to words{25158
{{sub{8,wa{8,wc{{get linear zero-origin subscript{25159
{{mti{8,wa{{{get integer value{25160
{{lct{8,wa{13,arndm(xl){{set num of dimensions as loop count{25161
{{add{7,xl{13,arofs(xl){{point past bounds information{25162
{{sub{7,xl{19,*arlbd{{set ok offset for proper ptr later{25163
*      loop to stack subscript offsets
{prn17{sub{7,xl{19,*ardms{{point to next set of bounds{25167
{{sti{3,prnsi{{{save current offset{25168
{{rmi{13,ardim(xl){{{get remainder on dividing by dimens{25169
{{mfi{11,-(xs){{{store on stack (one word){25170
{{ldi{3,prnsi{{{reload argument{25171
{{dvi{13,ardim(xl){{{divide to get quotient{25172
{{bct{8,wa{6,prn17{{loop till all stacked{25173
{{zer{7,xr{{{set offset to first set of bounds{25174
{{lct{8,wb{13,arndm(xl){{load count of dims to control loop{25175
{{brn{6,prn19{{{jump into print loop{25176
*      loop to print subscripts from stack adjusting by adding
*      the appropriate low bound value from the arblk
{prn18{mov{8,wa{18,=ch_cm{{load a comma{25181
{{jsr{6,prtch{{{print it{25182
*      merge here first time in (no comma required)
{prn19{mti{10,(xs)+{{{load subscript offset as integer{25186
{{add{7,xl{7,xr{{point to current lbd{25187
{{adi{13,arlbd(xl){{{add lbd to get signed subscript{25188
{{sub{7,xl{7,xr{{point back to start of arblk{25189
{{jsr{6,prtin{{{print subscript{25190
{{add{7,xr{19,*ardms{{bump offset to next bounds{25191
{{bct{8,wb{6,prn18{{loop back till all printed{25192
{{brn{6,prn14{{{merge back to print right bracket{25193
{{enp{{{{end procedure prtnm{25194
{{ejc{{{{{25195
*      prtnv -- print name value
*      prtnv is used by the trace and dump routines to print
*      a line of the form
*      name = value
*      note that the name involved can never be a pseudo-var
*      (xl)                  name base
*      (wa)                  name offset
*      jsr  prtnv            call to print name = value
*      (wb,wc,ra)            destroyed
{prtnv{prc{25,e{1,0{{entry point{25211
{{jsr{6,prtnm{{{print argument name{25212
{{mov{11,-(xs){7,xr{{save entry xr{25213
{{mov{11,-(xs){8,wa{{save name offset (collectable){25214
{{mov{7,xr{21,=tmbeb{{point to blank equal blank{25215
{{jsr{6,prtst{{{print it{25216
{{mov{7,xr{7,xl{{copy name base{25217
{{add{7,xr{8,wa{{point to value{25218
{{mov{7,xr{9,(xr){{load value pointer{25219
{{jsr{6,prtvl{{{print value{25220
{{jsr{6,prtnl{{{terminate line{25221
{{mov{8,wa{10,(xs)+{{restore name offset{25222
{{mov{7,xr{10,(xs)+{{restore entry xr{25223
{{exi{{{{return to caller{25224
{{enp{{{{end procedure prtnv{25225
{{ejc{{{{{25226
*      prtpg  -- print a page throw
*      prints a page throw or a few blank lines on the standard
*      listing channel depending on the listing options chosen.
*      jsr  prtpg            call for page eject
{prtpg{prc{25,e{1,0{{entry point{25235
{{beq{3,stage{18,=stgxt{6,prp01{jump if execution time{25236
{{bze{3,lstlc{6,prp06{{return if top of page already{25237
{{zer{3,lstlc{{{clear line count{25238
*      check type of listing
{prp01{mov{11,-(xs){7,xr{{preserve xr{25242
{{bnz{3,prstd{6,prp02{{eject if flag set{25243
{{bnz{3,prich{6,prp03{{jump if interactive listing channel{25244
{{bze{3,precl{6,prp03{{jump if compact listing{25245
*      perform an eject
{prp02{jsr{6,sysep{{{eject{25249
{{brn{6,prp04{{{merge{25250
*      compact or interactive channel listing. cant print
*      blanks until check made for headers printed and flag set.
{prp03{mov{7,xr{3,headp{{remember headp{25256
{{mnz{3,headp{{{set to avoid repeated prtpg calls{25257
{{jsr{6,prtnl{{{print blank line{25258
{{jsr{6,prtnl{{{print blank line{25259
{{jsr{6,prtnl{{{print blank line{25260
{{mov{3,lstlc{18,=num03{{count blank lines{25261
{{mov{3,headp{7,xr{{restore header flag{25262
{{ejc{{{{{25263
*      prptg (continued)
*      print the heading
{prp04{bnz{3,headp{6,prp05{{jump if header listed{25269
{{mnz{3,headp{{{mark headers printed{25270
{{mov{11,-(xs){7,xl{{keep xl{25271
{{mov{7,xr{21,=headr{{point to listing header{25272
{{jsr{6,prtst{{{place it{25273
{{jsr{6,sysid{{{get system identification{25274
{{jsr{6,prtst{{{append extra chars{25275
{{jsr{6,prtnl{{{print it{25276
{{mov{7,xr{7,xl{{extra header line{25277
{{jsr{6,prtst{{{place it{25278
{{jsr{6,prtnl{{{print it{25279
{{jsr{6,prtnl{{{print a blank{25280
{{jsr{6,prtnl{{{and another{25281
{{add{3,lstlc{18,=num04{{four header lines printed{25282
{{mov{7,xl{10,(xs)+{{restore xl{25283
*      merge if header not printed
{prp05{mov{7,xr{10,(xs)+{{restore xr{25287
*      return
{prp06{exi{{{{return{25291
{{enp{{{{end procedure prtpg{25292
{{ejc{{{{{25293
*      prtps - print page with test for standard listing option
*      if the standard listing option is selected, insist that
*      an eject be done
*      jsr  prtps            call for eject
{prtps{prc{25,e{1,0{{entry point{25302
{{mov{3,prstd{3,prsto{{copy option flag{25303
{{jsr{6,prtpg{{{print page{25304
{{zer{3,prstd{{{clear flag{25305
{{exi{{{{return{25306
{{enp{{{{end procedure prtps{25307
{{ejc{{{{{25308
*      prtsn -- print statement number
*      prtsn is used to initiate a print trace line by printing
*      asterisks and the current statement number. the actual
*      format of the output generated is.
*      ***nnnnn**** iii.....iiii
*      nnnnn is the statement number with leading zeros replaced
*      by asterisks (e.g. *******9****)
*      iii...iii represents a variable length output consisting
*      of a number of letter i characters equal to fnclevel.
*      jsr  prtsn            call to print statement number
*      (wc)                  destroyed
{prtsn{prc{25,e{1,0{{entry point{25327
{{mov{11,-(xs){7,xr{{save entry xr{25328
{{mov{3,prsna{8,wa{{save entry wa{25329
{{mov{7,xr{21,=tmasb{{point to asterisks{25330
{{jsr{6,prtst{{{print asterisks{25331
{{mov{3,profs{18,=num04{{point into middle of asterisks{25332
{{mti{3,kvstn{{{load statement number as integer{25333
{{jsr{6,prtin{{{print integer statement number{25334
{{mov{3,profs{18,=prsnf{{point past asterisks plus blank{25335
{{mov{7,xr{3,kvfnc{{get fnclevel{25336
{{mov{8,wa{18,=ch_li{{set letter i{25337
*      loop to generate letter i fnclevel times
{prsn1{bze{7,xr{6,prsn2{{jump if all set{25341
{{jsr{6,prtch{{{else print an i{25342
{{dcv{7,xr{{{decrement counter{25343
{{brn{6,prsn1{{{loop back{25344
*      merge with all letter i characters generated
{prsn2{mov{8,wa{18,=ch_bl{{get blank{25348
{{jsr{6,prtch{{{print blank{25349
{{mov{8,wa{3,prsna{{restore entry wa{25350
{{mov{7,xr{10,(xs)+{{restore entry xr{25351
{{exi{{{{return to prtsn caller{25352
{{enp{{{{end procedure prtsn{25353
{{ejc{{{{{25354
*      prtst -- print string
*      prtst places a string of characters in the print buffer
*      see prtnl for global locations used
*      note that the first word of the block (normally b_scl)
*      is not used and need not be set correctly (see prtvn)
*      (xr)                  string to be printed
*      jsr  prtst            call to print string
*      (profs)               updated past chars placed
{prtst{prc{25,r{1,0{{entry point{25369
{{bnz{3,headp{6,prst0{{were headers printed{25370
{{jsr{6,prtps{{{no - print them{25371
*      call syspr
{prst0{mov{3,prsva{8,wa{{save wa{25375
{{mov{3,prsvb{8,wb{{save wb{25376
{{zer{8,wb{{{set chars printed count to zero{25377
*      loop to print successive lines for long string
{prst1{mov{8,wa{13,sclen(xr){{load string length{25381
{{sub{8,wa{8,wb{{subtract count of chars already out{25382
{{bze{8,wa{6,prst4{{jump to exit if none left{25383
{{mov{11,-(xs){7,xl{{else stack entry xl{25384
{{mov{11,-(xs){7,xr{{save argument{25385
{{mov{7,xl{7,xr{{copy for eventual move{25386
{{mov{7,xr{3,prlen{{load print buffer length{25387
{{sub{7,xr{3,profs{{get chars left in print buffer{25388
{{bnz{7,xr{6,prst2{{skip if room left on this line{25389
{{jsr{6,prtnl{{{else print this line{25390
{{mov{7,xr{3,prlen{{and set full width available{25391
{{ejc{{{{{25392
*      prtst (continued)
*      here with chars to print and some room in buffer
{prst2{blo{8,wa{7,xr{6,prst3{jump if room for rest of string{25398
{{mov{8,wa{7,xr{{else set to fill line{25399
*      merge here with character count in wa
{prst3{mov{7,xr{3,prbuf{{point to print buffer{25403
{{plc{7,xl{8,wb{{point to location in string{25404
{{psc{7,xr{3,profs{{point to location in buffer{25405
{{add{8,wb{8,wa{{bump string chars count{25406
{{add{3,profs{8,wa{{bump buffer pointer{25407
{{mov{3,prsvc{8,wb{{preserve char counter{25408
{{mvc{{{{move characters to buffer{25409
{{mov{8,wb{3,prsvc{{recover char counter{25410
{{mov{7,xr{10,(xs)+{{restore argument pointer{25411
{{mov{7,xl{10,(xs)+{{restore entry xl{25412
{{brn{6,prst1{{{loop back to test for more{25413
*      here to exit after printing string
{prst4{mov{8,wb{3,prsvb{{restore entry wb{25417
{{mov{8,wa{3,prsva{{restore entry wa{25418
{{exi{{{{return to prtst caller{25419
{{enp{{{{end procedure prtst{25420
{{ejc{{{{{25421
*      prttr -- print to terminal
*      called to print contents of standard print buffer to
*      online terminal. clears buffer down and resets profs.
*      jsr  prttr            call for print
*      (wa,wb)               destroyed
{prttr{prc{25,e{1,0{{entry point{25431
{{mov{11,-(xs){7,xr{{save xr{25432
{{jsr{6,prtic{{{print buffer contents{25433
{{mov{7,xr{3,prbuf{{point to print bfr to clear it{25434
{{lct{8,wa{3,prlnw{{get buffer length{25435
{{add{7,xr{19,*schar{{point past scblk header{25436
{{mov{8,wb{4,nullw{{get blanks{25437
*      loop to clear buffer
{prtt1{mov{10,(xr)+{8,wb{{clear a word{25441
{{bct{8,wa{6,prtt1{{loop{25442
{{zer{3,profs{{{reset profs{25443
{{mov{7,xr{10,(xs)+{{restore xr{25444
{{exi{{{{return{25445
{{enp{{{{end procedure prttr{25446
{{ejc{{{{{25447
*      prtvl -- print a value
*      prtvl places an appropriate character representation of
*      a data value in the print buffer for dump/trace use.
*      (xr)                  value to be printed
*      jsr  prtvl            call to print value
*      (wa,wb,wc,ra)         destroyed
{prtvl{prc{25,r{1,0{{entry point, recursive{25458
{{mov{11,-(xs){7,xl{{save entry xl{25459
{{mov{11,-(xs){7,xr{{save argument{25460
{{chk{{{{check for stack overflow{25461
*      loop back here after finding a trap block (trblk)
{prv01{mov{3,prvsi{13,idval(xr){{copy idval (if any){25465
{{mov{7,xl{9,(xr){{load first word of block{25466
{{lei{7,xl{{{load entry point id{25467
{{bsw{7,xl{2,bl__t{6,prv02{switch on block type{25468
{{iff{2,bl_ar{6,prv05{{arblk{25486
{{iff{1,1{6,prv02{{{25486
{{iff{1,2{6,prv02{{{25486
{{iff{2,bl_ic{6,prv08{{icblk{25486
{{iff{2,bl_nm{6,prv09{{nmblk{25486
{{iff{1,5{6,prv02{{{25486
{{iff{1,6{6,prv02{{{25486
{{iff{1,7{6,prv02{{{25486
{{iff{2,bl_rc{6,prv08{{rcblk{25486
{{iff{2,bl_sc{6,prv11{{scblk{25486
{{iff{2,bl_se{6,prv12{{seblk{25486
{{iff{2,bl_tb{6,prv13{{tbblk{25486
{{iff{2,bl_vc{6,prv13{{vcblk{25486
{{iff{1,13{6,prv02{{{25486
{{iff{1,14{6,prv02{{{25486
{{iff{1,15{6,prv02{{{25486
{{iff{2,bl_pd{6,prv10{{pdblk{25486
{{iff{2,bl_tr{6,prv04{{trblk{25486
{{esw{{{{end of switch on block type{25486
*      here for blocks for which we just print datatype name
{prv02{jsr{6,dtype{{{get datatype name{25490
{{jsr{6,prtst{{{print datatype name{25491
*      common exit point
{prv03{mov{7,xr{10,(xs)+{{reload argument{25495
{{mov{7,xl{10,(xs)+{{restore xl{25496
{{exi{{{{return to prtvl caller{25497
*      here for trblk
{prv04{mov{7,xr{13,trval(xr){{load real value{25501
{{brn{6,prv01{{{and loop back{25502
{{ejc{{{{{25503
*      prtvl (continued)
*      here for array (arblk)
*      print array ( prototype ) blank number idval
{prv05{mov{7,xl{7,xr{{preserve argument{25511
{{mov{7,xr{21,=scarr{{point to datatype name (array){25512
{{jsr{6,prtst{{{print it{25513
{{mov{8,wa{18,=ch_pp{{load left paren{25514
{{jsr{6,prtch{{{print left paren{25515
{{add{7,xl{13,arofs(xl){{point to prototype{25516
{{mov{7,xr{9,(xl){{load prototype{25517
{{jsr{6,prtst{{{print prototype{25518
*      vcblk, tbblk, bcblk merge here for ) blank number idval
{prv06{mov{8,wa{18,=ch_rp{{load right paren{25522
{{jsr{6,prtch{{{print right paren{25523
*      pdblk merges here to print blank number idval
{prv07{mov{8,wa{18,=ch_bl{{load blank{25527
{{jsr{6,prtch{{{print it{25528
{{mov{8,wa{18,=ch_nm{{load number sign{25529
{{jsr{6,prtch{{{print it{25530
{{mti{3,prvsi{{{get idval{25531
{{jsr{6,prtin{{{print id number{25532
{{brn{6,prv03{{{back to exit{25533
*      here for integer (icblk), real (rcblk)
*      print character representation of value
{prv08{mov{11,-(xs){7,xr{{stack argument for gtstg{25539
{{jsr{6,gtstg{{{convert to string{25540
{{ppm{{{{error return is impossible{25541
{{jsr{6,prtst{{{print the string{25542
{{mov{3,dnamp{7,xr{{delete garbage string from storage{25543
{{brn{6,prv03{{{back to exit{25544
{{ejc{{{{{25545
*      prtvl (continued)
*      name (nmblk)
*      for pseudo-variable, just print datatype name (name)
*      for all other names, print dot followed by name rep
{prv09{mov{7,xl{13,nmbas(xr){{load name base{25554
{{mov{8,wa{9,(xl){{load first word of block{25555
{{beq{8,wa{22,=b_kvt{6,prv02{just print name if keyword{25556
{{beq{8,wa{22,=b_evt{6,prv02{just print name if expression var{25557
{{mov{8,wa{18,=ch_dt{{else get dot{25558
{{jsr{6,prtch{{{and print it{25559
{{mov{8,wa{13,nmofs(xr){{load name offset{25560
{{jsr{6,prtnm{{{print name{25561
{{brn{6,prv03{{{back to exit{25562
*      program datatype (pdblk)
*      print datatype name ch_bl ch_nm idval
{prv10{jsr{6,dtype{{{get datatype name{25568
{{jsr{6,prtst{{{print datatype name{25569
{{brn{6,prv07{{{merge back to print id{25570
*      here for string (scblk)
*      print quote string-characters quote
{prv11{mov{8,wa{18,=ch_sq{{load single quote{25576
{{jsr{6,prtch{{{print quote{25577
{{jsr{6,prtst{{{print string value{25578
{{jsr{6,prtch{{{print another quote{25579
{{brn{6,prv03{{{back to exit{25580
{{ejc{{{{{25581
*      prtvl (continued)
*      here for simple expression (seblk)
*      print asterisk variable-name
{prv12{mov{8,wa{18,=ch_as{{load asterisk{25589
{{jsr{6,prtch{{{print asterisk{25590
{{mov{7,xr{13,sevar(xr){{load variable pointer{25591
{{jsr{6,prtvn{{{print variable name{25592
{{brn{6,prv03{{{jump back to exit{25593
*      here for table (tbblk) and array (vcblk)
*      print datatype ( prototype ) blank number idval
{prv13{mov{7,xl{7,xr{{preserve argument{25599
{{jsr{6,dtype{{{get datatype name{25600
{{jsr{6,prtst{{{print datatype name{25601
{{mov{8,wa{18,=ch_pp{{load left paren{25602
{{jsr{6,prtch{{{print left paren{25603
{{mov{8,wa{13,tblen(xl){{load length of block (=vclen){25604
{{btw{8,wa{{{convert to word count{25605
{{sub{8,wa{18,=tbsi_{{allow for standard fields{25606
{{beq{9,(xl){22,=b_tbt{6,prv14{jump if table{25607
{{add{8,wa{18,=vctbd{{for vcblk, adjust size{25608
*      print prototype
{prv14{mti{8,wa{{{move as integer{25612
{{jsr{6,prtin{{{print integer prototype{25613
{{brn{6,prv06{{{merge back for rest{25614
{{enp{{{{end procedure prtvl{25637
{{ejc{{{{{25638
*      prtvn -- print natural variable name
*      prtvn prints the name of a natural variable
*      (xr)                  pointer to vrblk
*      jsr  prtvn            call to print variable name
{prtvn{prc{25,e{1,0{{entry point{25647
{{mov{11,-(xs){7,xr{{stack vrblk pointer{25648
{{add{7,xr{19,*vrsof{{point to possible string name{25649
{{bnz{13,sclen(xr){6,prvn1{{jump if not system variable{25650
{{mov{7,xr{13,vrsvo(xr){{point to svblk with name{25651
*      merge here with dummy scblk pointer in xr
{prvn1{jsr{6,prtst{{{print string name of variable{25655
{{mov{7,xr{10,(xs)+{{restore vrblk pointer{25656
{{exi{{{{return to prtvn caller{25657
{{enp{{{{end procedure prtvn{25658
{{ejc{{{{{25661
*      rcbld -- build a real block
*      (ra)                  real value for rcblk
*      jsr  rcbld            call to build real block
*      (xr)                  pointer to result rcblk
*      (wa)                  destroyed
{rcbld{prc{25,e{1,0{{entry point{25670
{{mov{7,xr{3,dnamp{{load pointer to next available loc{25671
{{add{7,xr{19,*rcsi_{{point past new rcblk{25672
{{blo{7,xr{3,dname{6,rcbl1{jump if there is room{25673
{{mov{8,wa{19,*rcsi_{{else load rcblk length{25674
{{jsr{6,alloc{{{use standard allocator to get block{25675
{{add{7,xr{8,wa{{point past block to merge{25676
*      merge here with xr pointing past the block obtained
{rcbl1{mov{3,dnamp{7,xr{{set new pointer{25680
{{sub{7,xr{19,*rcsi_{{point back to start of block{25681
{{mov{9,(xr){22,=b_rcl{{store type word{25682
{{str{13,rcval(xr){{{store real value in rcblk{25683
{{exi{{{{return to rcbld caller{25684
{{enp{{{{end procedure rcbld{25685
{{ejc{{{{{25687
*      readr -- read next source image at compile time
*      readr is used to read the next source image. to process
*      continuation cards properly, the compiler must read one
*      line ahead. thus readr does not destroy the current image
*      see also the nexts routine which actually gets the image.
*      jsr  readr            call to read next image
*      (xr)                  ptr to next image (0 if none)
*      (r_cni)               copy of pointer
*      (wa,wb,wc,xl)         destroyed
{readr{prc{25,e{1,0{{entry point{25701
{{mov{7,xr{3,r_cni{{get ptr to next image{25702
{{bnz{7,xr{6,read3{{exit if already read{25703
{{bnz{3,cnind{6,reada{{if within include file{25705
{{bne{3,stage{18,=stgic{6,read3{exit if not initial compile{25707
{reada{mov{8,wa{3,cswin{{max read length{25708
{{zer{7,xl{{{clear any dud value in xl{25709
{{jsr{6,alocs{{{allocate buffer{25710
{{jsr{6,sysrd{{{read input image{25711
{{ppm{6,read4{{{jump if eof or new file name{25712
{{icv{3,rdnln{{{increment next line number{25713
{{dcv{3,polct{{{test if time to poll interface{25715
{{bnz{3,polct{6,read0{{not yet{25716
{{zer{8,wa{{{=0 for poll{25717
{{mov{8,wb{3,rdnln{{line number{25718
{{jsr{6,syspl{{{allow interactive access{25719
{{err{1,320{26,user interrupt{{{25720
{{ppm{{{{single step{25721
{{ppm{{{{expression evaluation{25722
{{mov{3,polcs{8,wa{{new countdown start value{25723
{{mov{3,polct{8,wa{{new counter value{25724
{read0{ble{13,sclen(xr){3,cswin{6,read1{use smaller of string lnth ...{25726
{{mov{13,sclen(xr){3,cswin{{... and xxx of -inxxx{25727
*      perform the trim
{read1{mnz{8,wb{{{set trimr to perform trim{25731
{{jsr{6,trimr{{{trim trailing blanks{25732
*      merge here after read
{read2{mov{3,r_cni{7,xr{{store copy of pointer{25736
*      merge here if no read attempted
{read3{exi{{{{return to readr caller{25740
*      here on end of file or new source file name.
*      if this is a new source file name, the r_sfn table will
*      be augmented with a new table entry consisting of the
*      current compiler statement number as subscript, and the
*      file name as value.
{read4{bze{13,sclen(xr){6,read5{{jump if true end of file{25749
{{zer{8,wb{{{new source file name{25750
{{mov{3,rdnln{8,wb{{restart line counter for new file{25751
{{jsr{6,trimr{{{remove unused space in block{25752
{{jsr{6,newfn{{{record new file name{25753
{{brn{6,reada{{{now reissue read for record data{25754
*      here on end of file
{read5{mov{3,dnamp{7,xr{{pop unused scblk{25758
{{bze{3,cnind{6,read6{{jump if not within an include file{25760
{{zer{7,xl{{{eof within include file{25761
{{jsr{6,sysif{{{switch stream back to previous file{25762
{{ppm{{{{{25763
{{mov{8,wa{3,cnind{{restore prev line number, file name{25764
{{add{8,wa{18,=vcvlb{{vector offset in words{25765
{{wtb{8,wa{{{convert to bytes{25766
{{mov{7,xr{3,r_ifa{{file name array{25767
{{add{7,xr{8,wa{{ptr to element{25768
{{mov{3,r_sfc{9,(xr){{change source file name{25769
{{mov{9,(xr){21,=nulls{{release scblk{25770
{{mov{7,xr{3,r_ifl{{line number array{25771
{{add{7,xr{8,wa{{ptr to element{25772
{{mov{7,xl{9,(xr){{icblk containing saved line number{25773
{{ldi{13,icval(xl){{{line number integer{25774
{{mfi{3,rdnln{{{change source line number{25775
{{mov{9,(xr){21,=inton{{release icblk{25776
{{dcv{3,cnind{{{decrement nesting level{25777
{{mov{8,wb{3,cmpsn{{current statement number{25778
{{icv{8,wb{{{anticipate end of previous stmt{25779
{{mti{8,wb{{{convert to integer{25780
{{jsr{6,icbld{{{build icblk for stmt number{25781
{{mov{7,xl{3,r_sfn{{file name table{25782
{{mnz{8,wb{{{lookup statement number by name{25783
{{jsr{6,tfind{{{allocate new teblk{25784
{{ppm{{{{always possible to allocate block{25785
{{mov{13,teval(xl){3,r_sfc{{record file name as entry value{25786
{{beq{3,stage{18,=stgic{6,reada{if initial compile, reissue read{25787
{{bnz{3,cnind{6,reada{{still reading from include file{25788
*      outer nesting of execute-time compile of -include
*      resume with any string remaining prior to -include.
{{mov{7,xl{3,r_ici{{restore code argument string{25793
{{zer{3,r_ici{{{release original string{25794
{{mov{8,wa{3,cnsil{{get length of string{25795
{{mov{8,wb{3,cnspt{{offset of characters left{25796
{{sub{8,wa{8,wb{{number of characters left{25797
{{mov{3,scnil{8,wa{{set new scan length{25798
{{zer{3,scnpt{{{scan from start of substring{25799
{{jsr{6,sbstr{{{create substring of remainder{25800
{{mov{3,r_cim{7,xr{{set scan image{25801
{{brn{6,read2{{{return{25802
{read6{zer{7,xr{{{zero ptr as result{25818
{{brn{6,read2{{{merge{25819
{{enp{{{{end procedure readr{25820
{{ejc{{{{{25821
*      sbstr -- build a substring
*      (xl)                  ptr to scblk/bfblk with chars
*      (wa)                  number of chars in substring
*      (wb)                  offset to first char in scblk
*      jsr  sbstr            call to build substring
*      (xr)                  ptr to new scblk with substring
*      (xl)                  zero
*      (wa,wb,wc,xl,ia)      destroyed
*      note that sbstr is called with a dummy string pointer
*      (pointing into a vrblk or svblk) to copy the name of a
*      variable as a standard string value.
{sbstr{prc{25,e{1,0{{entry point{25916
{{bze{8,wa{6,sbst2{{jump if null substring{25917
{{jsr{6,alocs{{{else allocate scblk{25918
{{mov{8,wa{8,wc{{move number of characters{25919
{{mov{8,wc{7,xr{{save ptr to new scblk{25920
{{plc{7,xl{8,wb{{prepare to load chars from old blk{25921
{{psc{7,xr{{{prepare to store chars in new blk{25922
{{mvc{{{{move characters to new string{25923
{{mov{7,xr{8,wc{{then restore scblk pointer{25924
*      return point
{sbst1{zer{7,xl{{{clear garbage pointer in xl{25928
{{exi{{{{return to sbstr caller{25929
*      here for null substring
{sbst2{mov{7,xr{21,=nulls{{set null string as result{25933
{{brn{6,sbst1{{{return{25934
{{enp{{{{end procedure sbstr{25935
{{ejc{{{{{25936
*      stgcc -- compute counters for stmt startup testing
*      jsr  stgcc            call to recompute counters
*      (wa,wb)               destroyed
*      on exit, stmcs and stmct contain the counter value to
*      tested in stmgo.
{stgcc{prc{25,e{1,0{{{25947
{{mov{8,wa{3,polcs{{assume no profiling or stcount tracing{25949
{{mov{8,wb{18,=num01{{poll each time polcs expires{25950
{{ldi{3,kvstl{{{get stmt limit{25954
{{bnz{3,kvpfl{6,stgc1{{jump if profiling enabled{25955
{{ilt{6,stgc3{{{no stcount tracing if negative{25956
{{bze{3,r_stc{6,stgc2{{jump if not stcount tracing{25957
*      here if profiling or if stcount tracing enabled
{stgc1{mov{8,wb{8,wa{{count polcs times within stmg{25962
{{mov{8,wa{18,=num01{{break out of stmgo on each stmt{25963
{{brn{6,stgc3{{{{25967
*      check that stmcs does not exceed kvstl
{stgc2{mti{8,wa{{{breakout count start value{25971
{{sbi{3,kvstl{{{proposed stmcs minus stmt limit{25972
{{ile{6,stgc3{{{jump if stmt count does not limit{25973
{{ldi{3,kvstl{{{stlimit limits breakcount count{25974
{{mfi{8,wa{{{use it instead{25975
*      re-initialize counter
{stgc3{mov{3,stmcs{8,wa{{update breakout count start value{25979
{{mov{3,stmct{8,wa{{reset breakout counter{25980
{{mov{3,polct{8,wb{{{25982
{{exi{{{{{25984
{{ejc{{{{{25985
*      tfind -- locate table element
*      (xr)                  subscript value for element
*      (xl)                  pointer to table
*      (wb)                  zero by value, non-zero by name
*      jsr  tfind            call to locate element
*      ppm  loc              transfer location if access fails
*      (xr)                  element value (if by value)
*      (xr)                  destroyed (if by name)
*      (xl,wa)               teblk name (if by name)
*      (xl,wa)               destroyed (if by value)
*      (wc,ra)               destroyed
*      note that if a call by value specifies a non-existent
*      subscript, the default value is returned without building
*      a new teblk.
{tfind{prc{25,e{1,1{{entry point{26004
{{mov{11,-(xs){8,wb{{save name/value indicator{26005
{{mov{11,-(xs){7,xr{{save subscript value{26006
{{mov{11,-(xs){7,xl{{save table pointer{26007
{{mov{8,wa{13,tblen(xl){{load length of tbblk{26008
{{btw{8,wa{{{convert to word count{26009
{{sub{8,wa{18,=tbbuk{{get number of buckets{26010
{{mti{8,wa{{{convert to integer value{26011
{{sti{3,tfnsi{{{save for later{26012
{{mov{7,xl{9,(xr){{load first word of subscript{26013
{{lei{7,xl{{{load block entry id (bl_xx){26014
{{bsw{7,xl{2,bl__d{6,tfn00{switch on block type{26015
{{iff{1,0{6,tfn00{{{26026
{{iff{1,1{6,tfn00{{{26026
{{iff{1,2{6,tfn00{{{26026
{{iff{2,bl_ic{6,tfn02{{jump if integer{26026
{{iff{2,bl_nm{6,tfn04{{jump if name{26026
{{iff{2,bl_p0{6,tfn03{{jump if pattern{26026
{{iff{2,bl_p1{6,tfn03{{jump if pattern{26026
{{iff{2,bl_p2{6,tfn03{{jump if pattern{26026
{{iff{2,bl_rc{6,tfn02{{real{26026
{{iff{2,bl_sc{6,tfn05{{jump if string{26026
{{iff{1,10{6,tfn00{{{26026
{{iff{1,11{6,tfn00{{{26026
{{iff{1,12{6,tfn00{{{26026
{{iff{1,13{6,tfn00{{{26026
{{iff{1,14{6,tfn00{{{26026
{{iff{1,15{6,tfn00{{{26026
{{iff{1,16{6,tfn00{{{26026
{{esw{{{{end switch on block type{26026
*      here for blocks for which we use the second word of the
*      block as the hash source (see block formats for details).
{tfn00{mov{8,wa{12,1(xr){{load second word{26031
*      merge here with one word hash source in wa
{tfn01{mti{8,wa{{{convert to integer{26035
{{brn{6,tfn06{{{jump to merge{26036
{{ejc{{{{{26037
*      tfind (continued)
*      here for integer or real
*      possibility of overflow exist on twos complement
*      machine if hash source is most negative integer or is
*      a real having the same bit pattern.
{tfn02{ldi{12,1(xr){{{load value as hash source{26047
{{ige{6,tfn06{{{ok if positive or zero{26048
{{ngi{{{{make positive{26049
{{iov{6,tfn06{{{clear possible overflow{26050
{{brn{6,tfn06{{{merge{26051
*      for pattern, use first word (pcode) as source
{tfn03{mov{8,wa{9,(xr){{load first word as hash source{26055
{{brn{6,tfn01{{{merge back{26056
*      for name, use offset as hash source
{tfn04{mov{8,wa{13,nmofs(xr){{load offset as hash source{26060
{{brn{6,tfn01{{{merge back{26061
*      here for string
{tfn05{jsr{6,hashs{{{call routine to compute hash{26065
*      merge here with hash source in (ia)
{tfn06{rmi{3,tfnsi{{{compute hash index by remaindering{26069
{{mfi{8,wc{{{get as one word integer{26070
{{wtb{8,wc{{{convert to byte offset{26071
{{mov{7,xl{9,(xs){{get table ptr again{26072
{{add{7,xl{8,wc{{point to proper bucket{26073
{{mov{7,xr{13,tbbuk(xl){{load first teblk pointer{26074
{{beq{7,xr{9,(xs){6,tfn10{jump if no teblks on chain{26075
*      loop through teblks on hash chain
{tfn07{mov{8,wb{7,xr{{save teblk pointer{26079
{{mov{7,xr{13,tesub(xr){{load subscript value{26080
{{mov{7,xl{12,1(xs){{load input argument subscript val{26081
{{jsr{6,ident{{{compare them{26082
{{ppm{6,tfn08{{{jump if equal (ident){26083
*      here if no match with that teblk
{{mov{7,xl{8,wb{{restore teblk pointer{26087
{{mov{7,xr{13,tenxt(xl){{point to next teblk on chain{26088
{{bne{7,xr{9,(xs){6,tfn07{jump if there is one{26089
*      here if no match with any teblk on chain
{{mov{8,wc{19,*tenxt{{set offset to link field (xl base){26093
{{brn{6,tfn11{{{jump to merge{26094
{{ejc{{{{{26095
*      tfind (continued)
*      here we have found a matching element
{tfn08{mov{7,xl{8,wb{{restore teblk pointer{26101
{{mov{8,wa{19,*teval{{set teblk name offset{26102
{{mov{8,wb{12,2(xs){{restore name/value indicator{26103
{{bnz{8,wb{6,tfn09{{jump if called by name{26104
{{jsr{6,acess{{{else get value{26105
{{ppm{6,tfn12{{{jump if reference fails{26106
{{zer{8,wb{{{restore name/value indicator{26107
*      common exit for entry found
{tfn09{add{7,xs{19,*num03{{pop stack entries{26111
{{exi{{{{return to tfind caller{26112
*      here if no teblks on the hash chain
{tfn10{add{8,wc{19,*tbbuk{{get offset to bucket ptr{26116
{{mov{7,xl{9,(xs){{set tbblk ptr as base{26117
*      merge here with (xl,wc) base,offset of final link
{tfn11{mov{7,xr{9,(xs){{tbblk pointer{26121
{{mov{7,xr{13,tbinv(xr){{load default value in case{26122
{{mov{8,wb{12,2(xs){{load name/value indicator{26123
{{bze{8,wb{6,tfn09{{exit with default if value call{26124
{{mov{8,wb{7,xr{{copy default value{26125
*      here we must build a new teblk
{{mov{8,wa{19,*tesi_{{set size of teblk{26129
{{jsr{6,alloc{{{allocate teblk{26130
{{add{7,xl{8,wc{{point to hash link{26131
{{mov{9,(xl){7,xr{{link new teblk at end of chain{26132
{{mov{9,(xr){22,=b_tet{{store type word{26133
{{mov{13,teval(xr){8,wb{{set default as initial value{26134
{{mov{13,tenxt(xr){10,(xs)+{{set tbblk ptr to mark end of chain{26135
{{mov{13,tesub(xr){10,(xs)+{{store subscript value{26136
{{mov{8,wb{10,(xs)+{{restore name/value indicator{26137
{{mov{7,xl{7,xr{{copy teblk pointer (name base){26138
{{mov{8,wa{19,*teval{{set offset{26139
{{exi{{{{return to caller with new teblk{26140
*      acess fail return
{tfn12{exi{1,1{{{alternative return{26144
{{enp{{{{end procedure tfind{26145
{{ejc{{{{{26146
*      tmake -- make new table
*      (xl)                  initial lookup value
*      (wc)                  number of buckets desired
*      jsr  tmake            call to make new table
*      (xr)                  new table
*      (wa,wb)               destroyed
{tmake{prc{25,e{1,0{{{26156
{{mov{8,wa{8,wc{{copy number of headers{26157
{{add{8,wa{18,=tbsi_{{adjust for standard fields{26158
{{wtb{8,wa{{{convert length to bytes{26159
{{jsr{6,alloc{{{allocate space for tbblk{26160
{{mov{8,wb{7,xr{{copy pointer to tbblk{26161
{{mov{10,(xr)+{22,=b_tbt{{store type word{26162
{{zer{10,(xr)+{{{zero id for the moment{26163
{{mov{10,(xr)+{8,wa{{store length (tblen){26164
{{mov{10,(xr)+{7,xl{{store initial lookup value{26165
{{lct{8,wc{8,wc{{set loop counter (num headers){26166
*      loop to initialize all bucket pointers
{tma01{mov{10,(xr)+{8,wb{{store tbblk ptr in bucket header{26170
{{bct{8,wc{6,tma01{{loop till all stored{26171
{{mov{7,xr{8,wb{{recall pointer to tbblk{26172
{{exi{{{{{26173
{{enp{{{{{26174
{{ejc{{{{{26175
*      vmake -- create a vector
*      (wa)                  number of elements in vector
*      (xl)                  default value for vector elements
*      jsr  vmake            call to create vector
*      ppm  loc              if vector too large
*      (xr)                  pointer to vcblk
*      (wa,wb,wc,xl)         destroyed
{vmake{prc{25,e{1,1{{entry point{26187
{{lct{8,wb{8,wa{{copy elements for loop later on{26188
{{add{8,wa{18,=vcsi_{{add space for standard fields{26189
{{wtb{8,wa{{{convert length to bytes{26190
{{bgt{8,wa{3,mxlen{6,vmak2{fail if too large{26191
{{jsr{6,alloc{{{allocate space for vcblk{26192
{{mov{9,(xr){22,=b_vct{{store type word{26193
{{zer{13,idval(xr){{{initialize idval{26194
{{mov{13,vclen(xr){8,wa{{set length{26195
{{mov{8,wc{7,xl{{copy default value{26196
{{mov{7,xl{7,xr{{copy vcblk pointer{26197
{{add{7,xl{19,*vcvls{{point to first element value{26198
*      loop to set vector elements to default value
{vmak1{mov{10,(xl)+{8,wc{{store one value{26202
{{bct{8,wb{6,vmak1{{loop till all stored{26203
{{exi{{{{success return{26204
*      here if desired vector size too large
{vmak2{exi{1,1{{{fail return{26208
{{enp{{{{{26209
{{ejc{{{{{26210
*      scane -- scan an element
*      scane is called at compile time (by expan ,cmpil,cncrd)
*      to scan one element from the input image.
*      (scncc)               non-zero if called from cncrd
*      jsr  scane            call to scan element
*      (xr)                  result pointer (see below)
*      (xl)                  syntax type code (t_xxx)
*      the following global locations are used.
*      r_cim                 pointer to string block (scblk)
*                            for current input image.
*      r_cni                 pointer to next input image string
*                            pointer (zero if none).
*      r_scp                 save pointer (exit xr) from last
*                            call in case rescan is set.
*      scnbl                 this location is set non-zero on
*                            exit if scane scanned past blanks
*                            before locating the current element
*                            the end of a line counts as blanks.
*      scncc                 cncrd sets this non-zero to scan
*                            control card names and clears it
*                            on return
*      scnil                 length of current input image
*      scngo                 if set non-zero on entry, f and s
*                            are returned as separate syntax
*                            types (not letters) (goto pro-
*                            cessing). scngo is reset on exit.
*      scnpt                 offset to current loc in r_cim
*      scnrs                 if set non-zero on entry, scane
*                            returns the same result as on the
*                            last call (rescan). scnrs is reset
*                            on exit from any call to scane.
*      scntp                 save syntax type from last
*                            call (in case rescan is set).
{{ejc{{{{{26258
*      scane (continued)
*      element scanned       xl        xr
*      ---------------       --        --
*      control card name     0         pointer to scblk for name
*      unary operator        t_uop     ptr to operator dvblk
*      left paren            t_lpr     t_lpr
*      left bracket          t_lbr     t_lbr
*      comma                 t_cma     t_cma
*      function call         t_fnc     ptr to function vrblk
*      variable              t_var     ptr to vrblk
*      string constant       t_con     ptr to scblk
*      integer constant      t_con     ptr to icblk
*      real constant         t_con     ptr to rcblk
*      binary operator       t_bop     ptr to operator dvblk
*      right paren           t_rpr     t_rpr
*      right bracket         t_rbr     t_rbr
*      colon                 t_col     t_col
*      semi-colon            t_smc     t_smc
*      f (scngo ne 0)        t_fgo     t_fgo
*      s (scngo ne 0)        t_sgo     t_sgo
{{ejc{{{{{26303
*      scane (continued)
*      entry point
{scane{prc{25,e{1,0{{entry point{26309
{{zer{3,scnbl{{{reset blanks flag{26310
{{mov{3,scnsa{8,wa{{save wa{26311
{{mov{3,scnsb{8,wb{{save wb{26312
{{mov{3,scnsc{8,wc{{save wc{26313
{{bze{3,scnrs{6,scn03{{jump if no rescan{26314
*      here for rescan request
{{mov{7,xl{3,scntp{{set previous returned scan type{26318
{{mov{7,xr{3,r_scp{{set previous returned pointer{26319
{{zer{3,scnrs{{{reset rescan switch{26320
{{brn{6,scn13{{{jump to exit{26321
*      come here to read new image to test for continuation
{scn01{jsr{6,readr{{{read next image{26325
{{mov{8,wb{19,*dvubs{{set wb for not reading name{26326
{{bze{7,xr{6,scn30{{treat as semi-colon if none{26327
{{plc{7,xr{{{else point to first character{26328
{{lch{8,wc{9,(xr){{load first character{26329
{{beq{8,wc{18,=ch_dt{6,scn02{jump if dot for continuation{26330
{{bne{8,wc{18,=ch_pl{6,scn30{else treat as semicolon unless plus{26331
*      here for continuation line
{scn02{jsr{6,nexts{{{acquire next source image{26335
{{mov{3,scnpt{18,=num01{{set scan pointer past continuation{26336
{{mnz{3,scnbl{{{set blanks flag{26337
{{ejc{{{{{26338
*      scane (continued)
*      merge here to scan next element on current line
{scn03{mov{8,wa{3,scnpt{{load current offset{26344
{{beq{8,wa{3,scnil{6,scn01{check continuation if end{26345
{{mov{7,xl{3,r_cim{{point to current line{26346
{{plc{7,xl{8,wa{{point to current character{26347
{{mov{3,scnse{8,wa{{set start of element location{26348
{{mov{8,wc{21,=opdvs{{point to operator dv list{26349
{{mov{8,wb{19,*dvubs{{set constant for operator circuit{26350
{{brn{6,scn06{{{start scanning{26351
*      loop here to ignore leading blanks and tabs
{scn05{bze{8,wb{6,scn10{{jump if trailing{26355
{{icv{3,scnse{{{increment start of element{26356
{{beq{8,wa{3,scnil{6,scn01{jump if end of image{26357
{{mnz{3,scnbl{{{note blanks seen{26358
*      the following jump is used repeatedly for scanning out
*      the characters of a numeric constant or variable name.
*      the registers are used as follows.
*      (xr)                  scratch
*      (xl)                  ptr to next character
*      (wa)                  current scan offset
*      (wb)                  *dvubs (0 if scanning name,const)
*      (wc)                  =opdvs (0 if scanning constant)
{scn06{lch{7,xr{10,(xl)+{{get next character{26370
{{icv{8,wa{{{bump scan offset{26371
{{mov{3,scnpt{8,wa{{store offset past char scanned{26372
{{bsw{7,xr{2,cfp_u{6,scn07{switch on scanned character{26374
*      switch table for switch on character
{{ejc{{{{{26401
*      scane (continued)
{{ejc{{{{{26457
*      scane (continued)
{{iff{1,0{6,scn07{{{26490
{{iff{1,1{6,scn07{{{26490
{{iff{1,2{6,scn07{{{26490
{{iff{1,3{6,scn07{{{26490
{{iff{1,4{6,scn07{{{26490
{{iff{1,5{6,scn07{{{26490
{{iff{1,6{6,scn07{{{26490
{{iff{1,7{6,scn07{{{26490
{{iff{1,8{6,scn07{{{26490
{{iff{2,ch_ht{6,scn05{{horizontal tab{26490
{{iff{1,10{6,scn07{{{26490
{{iff{1,11{6,scn07{{{26490
{{iff{1,12{6,scn07{{{26490
{{iff{1,13{6,scn07{{{26490
{{iff{1,14{6,scn07{{{26490
{{iff{1,15{6,scn07{{{26490
{{iff{1,16{6,scn07{{{26490
{{iff{1,17{6,scn07{{{26490
{{iff{1,18{6,scn07{{{26490
{{iff{1,19{6,scn07{{{26490
{{iff{1,20{6,scn07{{{26490
{{iff{1,21{6,scn07{{{26490
{{iff{1,22{6,scn07{{{26490
{{iff{1,23{6,scn07{{{26490
{{iff{1,24{6,scn07{{{26490
{{iff{1,25{6,scn07{{{26490
{{iff{1,26{6,scn07{{{26490
{{iff{1,27{6,scn07{{{26490
{{iff{1,28{6,scn07{{{26490
{{iff{1,29{6,scn07{{{26490
{{iff{1,30{6,scn07{{{26490
{{iff{1,31{6,scn07{{{26490
{{iff{2,ch_bl{6,scn05{{blank{26490
{{iff{2,ch_ex{6,scn37{{exclamation mark{26490
{{iff{2,ch_dq{6,scn17{{double quote{26490
{{iff{2,ch_nm{6,scn41{{number sign{26490
{{iff{2,ch_dl{6,scn36{{dollar{26490
{{iff{1,37{6,scn07{{{26490
{{iff{2,ch_am{6,scn44{{ampersand{26490
{{iff{2,ch_sq{6,scn16{{single quote{26490
{{iff{2,ch_pp{6,scn25{{left paren{26490
{{iff{2,ch_rp{6,scn26{{right paren{26490
{{iff{2,ch_as{6,scn49{{asterisk{26490
{{iff{2,ch_pl{6,scn33{{plus{26490
{{iff{2,ch_cm{6,scn31{{comma{26490
{{iff{2,ch_mn{6,scn34{{minus{26490
{{iff{2,ch_dt{6,scn32{{dot{26490
{{iff{2,ch_sl{6,scn40{{slash{26490
{{iff{2,ch_d0{6,scn08{{digit 0{26490
{{iff{2,ch_d1{6,scn08{{digit 1{26490
{{iff{2,ch_d2{6,scn08{{digit 2{26490
{{iff{2,ch_d3{6,scn08{{digit 3{26490
{{iff{2,ch_d4{6,scn08{{digit 4{26490
{{iff{2,ch_d5{6,scn08{{digit 5{26490
{{iff{2,ch_d6{6,scn08{{digit 6{26490
{{iff{2,ch_d7{6,scn08{{digit 7{26490
{{iff{2,ch_d8{6,scn08{{digit 8{26490
{{iff{2,ch_d9{6,scn08{{digit 9{26490
{{iff{2,ch_cl{6,scn29{{colon{26490
{{iff{2,ch_sm{6,scn30{{semi-colon{26490
{{iff{2,ch_bb{6,scn28{{left bracket{26490
{{iff{2,ch_eq{6,scn46{{equal{26490
{{iff{2,ch_rb{6,scn27{{right bracket{26490
{{iff{2,ch_qu{6,scn45{{question mark{26490
{{iff{2,ch_at{6,scn42{{at{26490
{{iff{2,ch_ua{6,scn09{{shifted a{26490
{{iff{2,ch_ub{6,scn09{{shifted b{26490
{{iff{2,ch_uc{6,scn09{{shifted c{26490
{{iff{2,ch_ud{6,scn09{{shifted d{26490
{{iff{2,ch_ue{6,scn09{{shifted e{26490
{{iff{2,ch_uf{6,scn20{{shifted f{26490
{{iff{2,ch_ug{6,scn09{{shifted g{26490
{{iff{2,ch_uh{6,scn09{{shifted h{26490
{{iff{2,ch_ui{6,scn09{{shifted i{26490
{{iff{2,ch_uj{6,scn09{{shifted j{26490
{{iff{2,ch_uk{6,scn09{{shifted k{26490
{{iff{2,ch_ul{6,scn09{{shifted l{26490
{{iff{2,ch_um{6,scn09{{shifted m{26490
{{iff{2,ch_un{6,scn09{{shifted n{26490
{{iff{2,ch_uo{6,scn09{{shifted o{26490
{{iff{2,ch_up{6,scn09{{shifted p{26490
{{iff{2,ch_uq{6,scn09{{shifted q{26490
{{iff{2,ch_ur{6,scn09{{shifted r{26490
{{iff{2,ch_us{6,scn21{{shifted s{26490
{{iff{2,ch_ut{6,scn09{{shifted t{26490
{{iff{2,ch_uu{6,scn09{{shifted u{26490
{{iff{2,ch_uv{6,scn09{{shifted v{26490
{{iff{2,ch_uw{6,scn09{{shifted w{26490
{{iff{2,ch_ux{6,scn09{{shifted x{26490
{{iff{2,ch_uy{6,scn09{{shifted y{26490
{{iff{2,ch_uz{6,scn09{{shifted z{26490
{{iff{2,ch_ob{6,scn28{{left bracket{26490
{{iff{1,92{6,scn07{{{26490
{{iff{2,ch_cb{6,scn27{{right bracket{26490
{{iff{2,ch_pc{6,scn38{{percent{26490
{{iff{2,ch_u_{6,scn24{{underline{26490
{{iff{1,96{6,scn07{{{26490
{{iff{2,ch_la{6,scn09{{letter a{26490
{{iff{2,ch_lb{6,scn09{{letter b{26490
{{iff{2,ch_lc{6,scn09{{letter c{26490
{{iff{2,ch_ld{6,scn09{{letter d{26490
{{iff{2,ch_le{6,scn09{{letter e{26490
{{iff{2,ch_lf{6,scn20{{letter f{26490
{{iff{2,ch_lg{6,scn09{{letter g{26490
{{iff{2,ch_lh{6,scn09{{letter h{26490
{{iff{2,ch_li{6,scn09{{letter i{26490
{{iff{2,ch_lj{6,scn09{{letter j{26490
{{iff{2,ch_lk{6,scn09{{letter k{26490
{{iff{2,ch_ll{6,scn09{{letter l{26490
{{iff{2,ch_lm{6,scn09{{letter m{26490
{{iff{2,ch_ln{6,scn09{{letter n{26490
{{iff{2,ch_lo{6,scn09{{letter o{26490
{{iff{2,ch_lp{6,scn09{{letter p{26490
{{iff{2,ch_lq{6,scn09{{letter q{26490
{{iff{2,ch_lr{6,scn09{{letter r{26490
{{iff{2,ch_ls{6,scn21{{letter s{26490
{{iff{2,ch_lt{6,scn09{{letter t{26490
{{iff{2,ch_lu{6,scn09{{letter u{26490
{{iff{2,ch_lv{6,scn09{{letter v{26490
{{iff{2,ch_lw{6,scn09{{letter w{26490
{{iff{2,ch_lx{6,scn09{{letter x{26490
{{iff{2,ch_ly{6,scn09{{letter y{26490
{{iff{2,ch_l_{6,scn09{{letter z{26490
{{iff{1,123{6,scn07{{{26490
{{iff{2,ch_br{6,scn43{{vertical bar{26490
{{iff{1,125{6,scn07{{{26490
{{iff{2,ch_nt{6,scn35{{not{26490
{{iff{1,127{6,scn07{{{26490
{{esw{{{{end switch on character{26490
*      here for illegal character (underline merges)
{scn07{bze{8,wb{6,scn10{{jump if scanning name or constant{26494
{{erb{1,230{26,syntax error: illegal character{{{26495
{{ejc{{{{{26496
*      scane (continued)
*      here for digits 0-9
{scn08{bze{8,wb{6,scn09{{keep scanning if name/constant{26502
{{zer{8,wc{{{else set flag for scanning constant{26503
*      here for letter. loop here when scanning name/constant
{scn09{beq{8,wa{3,scnil{6,scn11{jump if end of image{26507
{{zer{8,wb{{{set flag for scanning name/const{26508
{{brn{6,scn06{{{merge back to continue scan{26509
*      come here for delimiter ending name or constant
{scn10{dcv{8,wa{{{reset offset to point to delimiter{26513
*      come here after finishing scan of name or constant
{scn11{mov{3,scnpt{8,wa{{store updated scan offset{26517
{{mov{8,wb{3,scnse{{point to start of element{26518
{{sub{8,wa{8,wb{{get number of characters{26519
{{mov{7,xl{3,r_cim{{point to line image{26520
{{bnz{8,wc{6,scn15{{jump if name{26521
*      here after scanning out numeric constant
{{jsr{6,sbstr{{{get string for constant{26525
{{mov{3,dnamp{7,xr{{delete from storage (not needed){26526
{{jsr{6,gtnum{{{convert to numeric{26527
{{ppm{6,scn14{{{jump if conversion failure{26528
*      merge here to exit with constant
{scn12{mov{7,xl{18,=t_con{{set result type of constant{26532
{{ejc{{{{{26533
*      scane (continued)
*      common exit point (xr,xl) set
{scn13{mov{8,wa{3,scnsa{{restore wa{26539
{{mov{8,wb{3,scnsb{{restore wb{26540
{{mov{8,wc{3,scnsc{{restore wc{26541
{{mov{3,r_scp{7,xr{{save xr in case rescan{26542
{{mov{3,scntp{7,xl{{save xl in case rescan{26543
{{zer{3,scngo{{{reset possible goto flag{26544
{{exi{{{{return to scane caller{26545
*      here if conversion error on numeric item
{scn14{erb{1,231{26,syntax error: invalid numeric item{{{26549
*      here after scanning out variable name
{scn15{jsr{6,sbstr{{{build string name of variable{26553
{{bnz{3,scncc{6,scn13{{return if cncrd call{26554
{{jsr{6,gtnvr{{{locate/build vrblk{26555
{{ppm{{{{dummy (unused) error return{26556
{{mov{7,xl{18,=t_var{{set type as variable{26557
{{brn{6,scn13{{{back to exit{26558
*      here for single quote (start of string constant)
{scn16{bze{8,wb{6,scn10{{terminator if scanning name or cnst{26562
{{mov{8,wb{18,=ch_sq{{set terminator as single quote{26563
{{brn{6,scn18{{{merge{26564
*      here for double quote (start of string constant)
{scn17{bze{8,wb{6,scn10{{terminator if scanning name or cnst{26568
{{mov{8,wb{18,=ch_dq{{set double quote terminator, merge{26569
*      loop to scan out string constant
{scn18{beq{8,wa{3,scnil{6,scn19{error if end of image{26573
{{lch{8,wc{10,(xl)+{{else load next character{26574
{{icv{8,wa{{{bump offset{26575
{{bne{8,wc{8,wb{6,scn18{loop back if not terminator{26576
{{ejc{{{{{26577
*      scane (continued)
*      here after scanning out string constant
{{mov{8,wb{3,scnpt{{point to first character{26583
{{mov{3,scnpt{8,wa{{save offset past final quote{26584
{{dcv{8,wa{{{point back past last character{26585
{{sub{8,wa{8,wb{{get number of characters{26586
{{mov{7,xl{3,r_cim{{point to input image{26587
{{jsr{6,sbstr{{{build substring value{26588
{{brn{6,scn12{{{back to exit with constant result{26589
*      here if no matching quote found
{scn19{mov{3,scnpt{8,wa{{set updated scan pointer{26593
{{erb{1,232{26,syntax error: unmatched string quote{{{26594
*      here for f (possible failure goto)
{scn20{mov{7,xr{18,=t_fgo{{set return code for fail goto{26598
{{brn{6,scn22{{{jump to merge{26599
*      here for s (possible success goto)
{scn21{mov{7,xr{18,=t_sgo{{set success goto as return code{26603
*      special goto cases merge here
{scn22{bze{3,scngo{6,scn09{{treat as normal letter if not goto{26607
*      merge here for special character exit
{scn23{bze{8,wb{6,scn10{{jump if end of name/constant{26611
{{mov{7,xl{7,xr{{else copy code{26612
{{brn{6,scn13{{{and jump to exit{26613
*      here for underline
{scn24{bze{8,wb{6,scn09{{part of name if scanning name{26617
{{brn{6,scn07{{{else illegal{26618
{{ejc{{{{{26619
*      scane (continued)
*      here for left paren
{scn25{mov{7,xr{18,=t_lpr{{set left paren return code{26625
{{bnz{8,wb{6,scn23{{return left paren unless name{26626
{{bze{8,wc{6,scn10{{delimiter if scanning constant{26627
*      here for left paren after name (function call)
{{mov{8,wb{3,scnse{{point to start of name{26631
{{mov{3,scnpt{8,wa{{set pointer past left paren{26632
{{dcv{8,wa{{{point back past last char of name{26633
{{sub{8,wa{8,wb{{get name length{26634
{{mov{7,xl{3,r_cim{{point to input image{26635
{{jsr{6,sbstr{{{get string name for function{26636
{{jsr{6,gtnvr{{{locate/build vrblk{26637
{{ppm{{{{dummy (unused) error return{26638
{{mov{7,xl{18,=t_fnc{{set code for function call{26639
{{brn{6,scn13{{{back to exit{26640
*      processing for special characters
{scn26{mov{7,xr{18,=t_rpr{{right paren, set code{26644
{{brn{6,scn23{{{take special character exit{26645
{scn27{mov{7,xr{18,=t_rbr{{right bracket, set code{26647
{{brn{6,scn23{{{take special character exit{26648
{scn28{mov{7,xr{18,=t_lbr{{left bracket, set code{26650
{{brn{6,scn23{{{take special character exit{26651
{scn29{mov{7,xr{18,=t_col{{colon, set code{26653
{{brn{6,scn23{{{take special character exit{26654
{scn30{mov{7,xr{18,=t_smc{{semi-colon, set code{26656
{{brn{6,scn23{{{take special character exit{26657
{scn31{mov{7,xr{18,=t_cma{{comma, set code{26659
{{brn{6,scn23{{{take special character exit{26660
{{ejc{{{{{26661
*      scane (continued)
*      here for operators. on entry, wc points to the table of
*      operator dope vectors and wb is the increment to step
*      to the next pair (binary/unary) of dope vectors in the
*      list. on reaching scn46, the pointer has been adjusted to
*      point to the appropriate pair of dope vectors.
*      the first three entries are special since they can occur
*      as part of a variable name (.) or constant (.+-).
{scn32{bze{8,wb{6,scn09{{dot can be part of name or constant{26673
{{add{8,wc{8,wb{{else bump pointer{26674
{scn33{bze{8,wc{6,scn09{{plus can be part of constant{26676
{{bze{8,wb{6,scn48{{plus cannot be part of name{26677
{{add{8,wc{8,wb{{else bump pointer{26678
{scn34{bze{8,wc{6,scn09{{minus can be part of constant{26680
{{bze{8,wb{6,scn48{{minus cannot be part of name{26681
{{add{8,wc{8,wb{{else bump pointer{26682
{scn35{add{8,wc{8,wb{{not{26684
{scn36{add{8,wc{8,wb{{dollar{26685
{scn37{add{8,wc{8,wb{{exclamation{26686
{scn38{add{8,wc{8,wb{{percent{26687
{scn39{add{8,wc{8,wb{{asterisk{26688
{scn40{add{8,wc{8,wb{{slash{26689
{scn41{add{8,wc{8,wb{{number sign{26690
{scn42{add{8,wc{8,wb{{at sign{26691
{scn43{add{8,wc{8,wb{{vertical bar{26692
{scn44{add{8,wc{8,wb{{ampersand{26693
{scn45{add{8,wc{8,wb{{question mark{26694
*      all operators come here (equal merges directly)
*      (wc) points to the binary/unary pair of operator dvblks.
{scn46{bze{8,wb{6,scn10{{operator terminates name/constant{26699
{{mov{7,xr{8,wc{{else copy dv pointer{26700
{{lch{8,wc{9,(xl){{load next character{26701
{{mov{7,xl{18,=t_bop{{set binary op in case{26702
{{beq{8,wa{3,scnil{6,scn47{should be binary if image end{26703
{{beq{8,wc{18,=ch_bl{6,scn47{should be binary if followed by blk{26704
{{beq{8,wc{18,=ch_ht{6,scn47{jump if horizontal tab{26706
{{beq{8,wc{18,=ch_sm{6,scn47{semicolon can immediately follow ={26711
{{beq{8,wc{18,=ch_cl{6,scn47{colon can immediately follow ={26712
{{beq{8,wc{18,=ch_rp{6,scn47{right paren can immediately follow ={26713
{{beq{8,wc{18,=ch_rb{6,scn47{right bracket can immediately follow ={26714
{{beq{8,wc{18,=ch_cb{6,scn47{right bracket can immediately follow ={26715
*      here for unary operator
{{add{7,xr{19,*dvbs_{{point to dv for unary op{26719
{{mov{7,xl{18,=t_uop{{set type for unary operator{26720
{{ble{3,scntp{18,=t_uok{6,scn13{ok unary if ok preceding element{26721
{{ejc{{{{{26722
*      scane (continued)
*      merge here to require preceding blanks
{scn47{bnz{3,scnbl{6,scn13{{all ok if preceding blanks, exit{26728
*      fail operator in this position
{scn48{erb{1,233{26,syntax error: invalid use of operator{{{26732
*      here for asterisk, could be ** substitute for exclamation
{scn49{bze{8,wb{6,scn10{{end of name if scanning name{26736
{{beq{8,wa{3,scnil{6,scn39{not ** if * at image end{26737
{{mov{7,xr{8,wa{{else save offset past first *{26738
{{mov{3,scnof{8,wa{{save another copy{26739
{{lch{8,wa{10,(xl)+{{load next character{26740
{{bne{8,wa{18,=ch_as{6,scn50{not ** if next char not *{26741
{{icv{7,xr{{{else step offset past second *{26742
{{beq{7,xr{3,scnil{6,scn51{ok exclam if end of image{26743
{{lch{8,wa{9,(xl){{else load next character{26744
{{beq{8,wa{18,=ch_bl{6,scn51{exclamation if blank{26745
{{beq{8,wa{18,=ch_ht{6,scn51{exclamation if horizontal tab{26747
*      unary *
{scn50{mov{8,wa{3,scnof{{recover stored offset{26755
{{mov{7,xl{3,r_cim{{point to line again{26756
{{plc{7,xl{8,wa{{point to current char{26757
{{brn{6,scn39{{{merge with unary *{26758
*      here for ** as substitute for exclamation
{scn51{mov{3,scnpt{7,xr{{save scan pointer past 2nd *{26762
{{mov{8,wa{7,xr{{copy scan pointer{26763
{{brn{6,scn37{{{merge with exclamation{26764
{{enp{{{{end procedure scane{26765
{{ejc{{{{{26766
*      scngf -- scan goto field
*      scngf is called from cmpil to scan and analyze a goto
*      field including the surrounding brackets or parentheses.
*      for a normal goto, the result returned is either a vrblk
*      pointer for a simple label operand, or a pointer to an
*      expression tree with a special outer unary operator
*      (o_goc). for a direct goto, the result returned is a
*      pointer to an expression tree with the special outer
*      unary operator o_god.
*      jsr  scngf            call to scan goto field
*      (xr)                  result (see above)
*      (xl,wa,wb,wc)         destroyed
{scngf{prc{25,e{1,0{{entry point{26783
{{jsr{6,scane{{{scan initial element{26784
{{beq{7,xl{18,=t_lpr{6,scng1{skip if left paren (normal goto){26785
{{beq{7,xl{18,=t_lbr{6,scng2{skip if left bracket (direct goto){26786
{{erb{1,234{26,syntax error: goto field incorrect{{{26787
*      here for left paren (normal goto)
{scng1{mov{8,wb{18,=num01{{set expan flag for normal goto{26791
{{jsr{6,expan{{{analyze goto field{26792
{{mov{8,wa{21,=opdvn{{point to opdv for complex goto{26793
{{ble{7,xr{3,statb{6,scng3{jump if not in static (sgd15){26794
{{blo{7,xr{3,state{6,scng4{jump to exit if simple label name{26795
{{brn{6,scng3{{{complex goto - merge{26796
*      here for left bracket (direct goto)
{scng2{mov{8,wb{18,=num02{{set expan flag for direct goto{26800
{{jsr{6,expan{{{scan goto field{26801
{{mov{8,wa{21,=opdvd{{set opdv pointer for direct goto{26802
{{ejc{{{{{26803
*      scngf (continued)
*      merge here to build outer unary operator block
{scng3{mov{11,-(xs){8,wa{{stack operator dv pointer{26809
{{mov{11,-(xs){7,xr{{stack pointer to expression tree{26810
{{jsr{6,expop{{{pop operator off{26811
{{mov{7,xr{10,(xs)+{{reload new expression tree pointer{26812
*      common exit point
{scng4{exi{{{{return to caller{26816
{{enp{{{{end procedure scngf{26817
{{ejc{{{{{26818
*      setvr -- set vrget,vrsto fields of vrblk
*      setvr sets the proper values in the vrget and vrsto
*      fields of a vrblk. it is called whenever trblks are
*      added or subtracted (trace,stoptr,input,output,detach)
*      (xr)                  pointer to vrblk
*      jsr  setvr            call to set fields
*      (xl,wa)               destroyed
*      note that setvr ignores the call if xr does not point
*      into the static region (i.e. is some other name base)
{setvr{prc{25,e{1,0{{entry point{26833
{{bhi{7,xr{3,state{6,setv1{exit if not natural variable{26834
*      here if we have a vrblk
{{mov{7,xl{7,xr{{copy vrblk pointer{26838
{{mov{13,vrget(xr){22,=b_vrl{{store normal get value{26839
{{beq{13,vrsto(xr){22,=b_vre{6,setv1{skip if protected variable{26840
{{mov{13,vrsto(xr){22,=b_vrs{{store normal store value{26841
{{mov{7,xl{13,vrval(xl){{point to next entry on chain{26842
{{bne{9,(xl){22,=b_trt{6,setv1{jump if end of trblk chain{26843
{{mov{13,vrget(xr){22,=b_vra{{store trapped routine address{26844
{{mov{13,vrsto(xr){22,=b_vrv{{set trapped routine address{26845
*      merge here to exit to caller
{setv1{exi{{{{return to setvr caller{26849
{{enp{{{{end procedure setvr{26850
{{ejc{{{{{26853
*      sorta -- sort array
*      routine to sort an array or table on same basis as in
*      sitbol. a table is converted to an array, leaving two
*      dimensional arrays and vectors as cases to be considered.
*      whole rows of arrays are permuted according to the
*      ordering of the keys they contain, and the stride
*      referred to, is the the length of a row. it is one
*      for a vector.
*      the sort used is heapsort, fundamentals of data structure
*      horowitz and sahni, pitman 1977, page 347.
*      it is an order n*log(n) algorithm. in order
*      to make it stable, comparands may not compare equal. this
*      is achieved by sorting a copy array (referred to as the
*      sort array) containing at its high address end, byte
*      offsets to the rows to be sorted held in the original
*      array (referred to as the key array). sortc, the
*      comparison routine, accesses the keys through these
*      offsets and in the case of equality, resolves it by
*      comparing the offsets themselves. the sort permutes the
*      offsets which are then used in a final operation to copy
*      the actual items into the new array in sorted order.
*      references to zeroth item are to notional item
*      preceding first actual item.
*      reverse sorting for rsort is done by having the less than
*      test for keys effectively be replaced by a
*      greater than test.
*      1(xs)                 first arg - array or table
*      0(xs)                 2nd arg - index or pdtype name
*      (wa)                  0 , non-zero for sort , rsort
*      jsr  sorta            call to sort array
*      ppm  loc              transfer loc if table is empty
*      (xr)                  sorted array
*      (xl,wa,wb,wc)         destroyed
{{ejc{{{{{26890
*      sorta (continued)
{sorta{prc{25,n{1,1{{entry point{26894
{{mov{3,srtsr{8,wa{{sort/rsort indicator{26895
{{mov{3,srtst{19,*num01{{default stride of 1{26896
{{zer{3,srtof{{{default zero offset to sort key{26897
{{mov{3,srtdf{21,=nulls{{clear datatype field name{26898
{{mov{3,r_sxr{10,(xs)+{{unstack argument 2{26899
{{mov{7,xr{10,(xs)+{{get first argument{26900
{{mnz{8,wa{{{use key/values of table entries{26901
{{jsr{6,gtarr{{{convert to array{26902
{{ppm{6,srt18{{{signal that table is empty{26903
{{ppm{6,srt16{{{error if non-convertable{26904
{{mov{11,-(xs){7,xr{{stack ptr to resulting key array{26905
{{mov{11,-(xs){7,xr{{another copy for copyb{26906
{{jsr{6,copyb{{{get copy array for sorting into{26907
{{ppm{{{{cant fail{26908
{{mov{11,-(xs){7,xr{{stack pointer to sort array{26909
{{mov{7,xr{3,r_sxr{{get second arg{26910
{{mov{7,xl{13,num01(xs){{get ptr to key array{26911
{{bne{9,(xl){22,=b_vct{6,srt02{jump if arblk{26912
{{beq{7,xr{21,=nulls{6,srt01{jump if null second arg{26913
{{jsr{6,gtnvr{{{get vrblk ptr for it{26914
{{err{1,257{26,erroneous 2nd arg in sort/rsort of vector{{{26915
{{mov{3,srtdf{7,xr{{store datatype field name vrblk{26916
*      compute n and offset to item a(0) in vector case
{srt01{mov{8,wc{19,*vclen{{offset to a(0){26920
{{mov{8,wb{19,*vcvls{{offset to first item{26921
{{mov{8,wa{13,vclen(xl){{get block length{26922
{{sub{8,wa{19,*vcsi_{{get no. of entries, n (in bytes){26923
{{brn{6,srt04{{{merge{26924
*      here for array
{srt02{ldi{13,ardim(xl){{{get possible dimension{26928
{{mfi{8,wa{{{convert to short integer{26929
{{wtb{8,wa{{{further convert to baus{26930
{{mov{8,wb{19,*arvls{{offset to first value if one{26931
{{mov{8,wc{19,*arpro{{offset before values if one dim.{26932
{{beq{13,arndm(xl){18,=num01{6,srt04{jump in fact if one dim.{26933
{{bne{13,arndm(xl){18,=num02{6,srt16{fail unless two dimens{26934
{{ldi{13,arlb2(xl){{{get lower bound 2 as default{26935
{{beq{7,xr{21,=nulls{6,srt03{jump if default second arg{26936
{{jsr{6,gtint{{{convert to integer{26937
{{ppm{6,srt17{{{fail{26938
{{ldi{13,icval(xr){{{get actual integer value{26939
{{ejc{{{{{26940
*      sorta (continued)
*      here with sort column index in ia in array case
{srt03{sbi{13,arlb2(xl){{{subtract low bound{26946
{{iov{6,srt17{{{fail if overflow{26947
{{ilt{6,srt17{{{fail if below low bound{26948
{{sbi{13,ardm2(xl){{{check against dimension{26949
{{ige{6,srt17{{{fail if too large{26950
{{adi{13,ardm2(xl){{{restore value{26951
{{mfi{8,wa{{{get as small integer{26952
{{wtb{8,wa{{{offset within row to key{26953
{{mov{3,srtof{8,wa{{keep offset{26954
{{ldi{13,ardm2(xl){{{second dimension is row length{26955
{{mfi{8,wa{{{convert to short integer{26956
{{mov{7,xr{8,wa{{copy row length{26957
{{wtb{8,wa{{{convert to bytes{26958
{{mov{3,srtst{8,wa{{store as stride{26959
{{ldi{13,ardim(xl){{{get number of rows{26960
{{mfi{8,wa{{{as a short integer{26961
{{wtb{8,wa{{{convert n to baus{26962
{{mov{8,wc{13,arlen(xl){{offset past array end{26963
{{sub{8,wc{8,wa{{adjust, giving space for n offsets{26964
{{dca{8,wc{{{point to a(0){26965
{{mov{8,wb{13,arofs(xl){{offset to word before first item{26966
{{ica{8,wb{{{offset to first item{26967
*      separate pre-processing for arrays and vectors done.
*      to simplify later key comparisons, removal of any trblk
*      trap blocks from entries in key array is effected.
*      (xl) = 1(xs) = pointer to key array
*      (xs) = pointer to sort array
*      wa = number of items, n (converted to bytes).
*      wb = offset to first item of arrays.
*      wc = offset to a(0)
{srt04{ble{8,wa{19,*num01{6,srt15{return if only a single item{26979
{{mov{3,srtsn{8,wa{{store number of items (in baus){26980
{{mov{3,srtso{8,wc{{store offset to a(0){26981
{{mov{8,wc{13,arlen(xl){{length of array or vec (=vclen){26982
{{add{8,wc{7,xl{{point past end of array or vector{26983
{{mov{3,srtsf{8,wb{{store offset to first row{26984
{{add{7,xl{8,wb{{point to first item in key array{26985
*      loop through array
{srt05{mov{7,xr{9,(xl){{get an entry{26989
*      hunt along trblk chain
{srt06{bne{9,(xr){22,=b_trt{6,srt07{jump out if not trblk{26993
{{mov{7,xr{13,trval(xr){{get value field{26994
{{brn{6,srt06{{{loop{26995
{{ejc{{{{{26996
*      sorta (continued)
*      xr is value from end of chain
{srt07{mov{10,(xl)+{7,xr{{store as array entry{27002
{{blt{7,xl{8,wc{6,srt05{loop if not done{27003
{{mov{7,xl{9,(xs){{get adrs of sort array{27004
{{mov{7,xr{3,srtsf{{initial offset to first key{27005
{{mov{8,wb{3,srtst{{get stride{27006
{{add{7,xl{3,srtso{{offset to a(0){27007
{{ica{7,xl{{{point to a(1){27008
{{mov{8,wc{3,srtsn{{get n{27009
{{btw{8,wc{{{convert from bytes{27010
{{mov{3,srtnr{8,wc{{store as row count{27011
{{lct{8,wc{8,wc{{loop counter{27012
*      store key offsets at top of sort array
{srt08{mov{10,(xl)+{7,xr{{store an offset{27016
{{add{7,xr{8,wb{{bump offset by stride{27017
{{bct{8,wc{6,srt08{{loop through rows{27018
*      perform the sort on offsets in sort array.
*      (srtsn)               number of items to sort, n (bytes)
*      (srtso)               offset to a(0)
{srt09{mov{8,wa{3,srtsn{{get n{27025
{{mov{8,wc{3,srtnr{{get number of rows{27026
{{rsh{8,wc{1,1{{i = n / 2 (wc=i, index into array){27027
{{wtb{8,wc{{{convert back to bytes{27028
*      loop to form initial heap
{srt10{jsr{6,sorth{{{sorth(i,n){27032
{{dca{8,wc{{{i = i - 1{27033
{{bnz{8,wc{6,srt10{{loop if i gt 0{27034
{{mov{8,wc{8,wa{{i = n{27035
*      sorting loop. at this point, a(1) is the largest
*      item, since algorithm initialises it as, and then maintains
*      it as, root of tree.
{srt11{dca{8,wc{{{i = i - 1 (n - 1 initially){27041
{{bze{8,wc{6,srt12{{jump if done{27042
{{mov{7,xr{9,(xs){{get sort array address{27043
{{add{7,xr{3,srtso{{point to a(0){27044
{{mov{7,xl{7,xr{{a(0) address{27045
{{add{7,xl{8,wc{{a(i) address{27046
{{mov{8,wb{13,num01(xl){{copy a(i+1){27047
{{mov{13,num01(xl){13,num01(xr){{move a(1) to a(i+1){27048
{{mov{13,num01(xr){8,wb{{complete exchange of a(1), a(i+1){27049
{{mov{8,wa{8,wc{{n = i for sorth{27050
{{mov{8,wc{19,*num01{{i = 1 for sorth{27051
{{jsr{6,sorth{{{sorth(1,n){27052
{{mov{8,wc{8,wa{{restore wc{27053
{{brn{6,srt11{{{loop{27054
{{ejc{{{{{27055
*      sorta (continued)
*      offsets have been permuted into required order by sort.
*      copy array elements over them.
{srt12{mov{7,xr{9,(xs){{base adrs of key array{27062
{{mov{8,wc{7,xr{{copy it{27063
{{add{8,wc{3,srtso{{offset of a(0){27064
{{add{7,xr{3,srtsf{{adrs of first row of sort array{27065
{{mov{8,wb{3,srtst{{get stride{27066
*      copying loop for successive items. sorted offsets are
*      held at end of sort array.
{srt13{ica{8,wc{{{adrs of next of sorted offsets{27071
{{mov{7,xl{8,wc{{copy it for access{27072
{{mov{7,xl{9,(xl){{get offset{27073
{{add{7,xl{13,num01(xs){{add key array base adrs{27074
{{mov{8,wa{8,wb{{get count of characters in row{27075
{{mvw{{{{copy a complete row{27076
{{dcv{3,srtnr{{{decrement row count{27077
{{bnz{3,srtnr{6,srt13{{repeat till all rows done{27078
*      return point
{srt15{mov{7,xr{10,(xs)+{{pop result array ptr{27082
{{ica{7,xs{{{pop key array ptr{27083
{{zer{3,r_sxl{{{clear junk{27084
{{zer{3,r_sxr{{{clear junk{27085
{{exi{{{{return{27086
*      error point
{srt16{erb{1,256{26,sort/rsort 1st arg not suitable array or table{{{27090
{srt17{erb{1,258{26,sort/rsort 2nd arg out of range or non-integer{{{27091
*      return point if input table is empty
{srt18{exi{1,1{{{return indication of null table{27095
{{enp{{{{end procudure sorta{27096
{{ejc{{{{{27097
*      sortc --  compare sort keys
*      compare two sort keys given their offsets. if
*      equal, compare key offsets to give stable sort.
*      note that if srtsr is non-zero (request for reverse
*      sort), the quoted returns are inverted.
*      for objects of differing datatypes, the entry point
*      identifications are compared.
*      (xl)                  base adrs for keys
*      (wa)                  offset to key 1 item
*      (wb)                  offset to key 2 item
*      (srtsr)               zero/non-zero for sort/rsort
*      (srtof)               offset within row to comparands
*      jsr  sortc            call to compare keys
*      ppm  loc              key1 less than key2
*                            normal return, key1 gt than key2
*      (xl,xr,wa,wb)         destroyed
{sortc{prc{25,e{1,1{{entry point{27118
{{mov{3,srts1{8,wa{{save offset 1{27119
{{mov{3,srts2{8,wb{{save offset 2{27120
{{mov{3,srtsc{8,wc{{save wc{27121
{{add{7,xl{3,srtof{{add offset to comparand field{27122
{{mov{7,xr{7,xl{{copy base + offset{27123
{{add{7,xl{8,wa{{add key1 offset{27124
{{add{7,xr{8,wb{{add key2 offset{27125
{{mov{7,xl{9,(xl){{get key1{27126
{{mov{7,xr{9,(xr){{get key2{27127
{{bne{3,srtdf{21,=nulls{6,src12{jump if datatype field name used{27128
{{ejc{{{{{27129
*      sortc (continued)
*      merge after dealing with field name. try for strings.
{src01{mov{8,wc{9,(xl){{get type code{27135
{{bne{8,wc{9,(xr){6,src02{skip if not same datatype{27136
{{beq{8,wc{22,=b_scl{6,src09{jump if both strings{27137
{{beq{8,wc{22,=b_icl{6,src14{jump if both integers{27138
*      datatypes different.  now try for numeric
{src02{mov{3,r_sxl{7,xl{{keep arg1{27146
{{mov{3,r_sxr{7,xr{{keep arg2{27147
{{beq{8,wc{22,=b_scl{6,src11{do not allow conversion to number{27150
{{beq{9,(xr){22,=b_scl{6,src11{if either arg is a string{27151
{src14{mov{11,-(xs){7,xl{{stack{27194
{{mov{11,-(xs){7,xr{{args{27195
{{jsr{6,acomp{{{compare objects{27196
{{ppm{6,src10{{{not numeric{27197
{{ppm{6,src10{{{not numeric{27198
{{ppm{6,src03{{{key1 less{27199
{{ppm{6,src08{{{keys equal{27200
{{ppm{6,src05{{{key1 greater{27201
*      return if key1 smaller (sort), greater (rsort)
{src03{bnz{3,srtsr{6,src06{{jump if rsort{27205
{src04{mov{8,wc{3,srtsc{{restore wc{27207
{{exi{1,1{{{return{27208
*      return if key1 greater (sort), smaller (rsort)
{src05{bnz{3,srtsr{6,src04{{jump if rsort{27212
{src06{mov{8,wc{3,srtsc{{restore wc{27214
{{exi{{{{return{27215
*      keys are of same datatype
{src07{blt{7,xl{7,xr{6,src03{item first created is less{27219
{{bgt{7,xl{7,xr{6,src05{addresses rise in order of creation{27220
*      drop through or merge for identical or equal objects
{src08{blt{3,srts1{3,srts2{6,src04{test offsets or key addrss instead{27224
{{brn{6,src06{{{offset 1 greater{27225
{{ejc{{{{{27226
*      sortc (continued)
*      strings
{src09{mov{11,-(xs){7,xl{{stack{27236
{{mov{11,-(xs){7,xr{{args{27237
{{jsr{6,lcomp{{{compare objects{27238
{{ppm{{{{cant{27239
{{ppm{{{{fail{27240
{{ppm{6,src03{{{key1 less{27241
{{ppm{6,src08{{{keys equal{27242
{{ppm{6,src05{{{key1 greater{27243
*      arithmetic comparison failed - recover args
{src10{mov{7,xl{3,r_sxl{{get arg1{27247
{{mov{7,xr{3,r_sxr{{get arg2{27248
{{mov{8,wc{9,(xl){{get type of key1{27249
{{beq{8,wc{9,(xr){6,src07{jump if keys of same type{27250
*      here to compare datatype ids
{src11{mov{7,xl{8,wc{{get block type word{27254
{{mov{7,xr{9,(xr){{get block type word{27255
{{lei{7,xl{{{entry point id for key1{27256
{{lei{7,xr{{{entry point id for key2{27257
{{bgt{7,xl{7,xr{6,src05{jump if key1 gt key2{27258
{{brn{6,src03{{{key1 lt key2{27259
*      datatype field name used
{src12{jsr{6,sortf{{{call routine to find field 1{27263
{{mov{11,-(xs){7,xl{{stack item pointer{27264
{{mov{7,xl{7,xr{{get key2{27265
{{jsr{6,sortf{{{find field 2{27266
{{mov{7,xr{7,xl{{place as key2{27267
{{mov{7,xl{10,(xs)+{{recover key1{27268
{{brn{6,src01{{{merge{27269
{{enp{{{{procedure sortc{27270
{{ejc{{{{{27271
*      sortf -- find field for sortc
*      routine used by sortc to obtain item corresponding
*      to a given field name, if this exists, in a programmer
*      defined object passed as argument.
*      if such a match occurs, record is kept of datatype
*      name, field name and offset to field in order to
*      short-circuit later searches on same type. note that
*      dfblks are stored in static and hence cannot be moved.
*      (srtdf)               vrblk pointer of field name
*      (xl)                  possible pdblk pointer
*      jsr  sortf            call to search for field name
*      (xl)                  item found or original pdblk ptr
*      (wc)                  destroyed
{sortf{prc{25,e{1,0{{entry point{27289
{{bne{9,(xl){22,=b_pdt{6,srtf3{return if not pdblk{27290
{{mov{11,-(xs){7,xr{{keep xr{27291
{{mov{7,xr{3,srtfd{{get possible former dfblk ptr{27292
{{bze{7,xr{6,srtf4{{jump if not{27293
{{bne{7,xr{13,pddfp(xl){6,srtf4{jump if not right datatype{27294
{{bne{3,srtdf{3,srtff{6,srtf4{jump if not right field name{27295
{{add{7,xl{3,srtfo{{add offset to required field{27296
*      here with xl pointing to found field
{srtf1{mov{7,xl{9,(xl){{get item from field{27300
*      return point
{srtf2{mov{7,xr{10,(xs)+{{restore xr{27304
{srtf3{exi{{{{return{27306
{{ejc{{{{{27307
*      sortf (continued)
*      conduct a search
{srtf4{mov{7,xr{7,xl{{copy original pointer{27313
{{mov{7,xr{13,pddfp(xr){{point to dfblk{27314
{{mov{3,srtfd{7,xr{{keep a copy{27315
{{mov{8,wc{13,fargs(xr){{get number of fields{27316
{{wtb{8,wc{{{convert to bytes{27317
{{add{7,xr{13,dflen(xr){{point past last field{27318
*      loop to find name in pdfblk
{srtf5{dca{8,wc{{{count down{27322
{{dca{7,xr{{{point in front{27323
{{beq{9,(xr){3,srtdf{6,srtf6{skip out if found{27324
{{bnz{8,wc{6,srtf5{{loop{27325
{{brn{6,srtf2{{{return - not found{27326
*      found
{srtf6{mov{3,srtff{9,(xr){{keep field name ptr{27330
{{add{8,wc{19,*pdfld{{add offset to first field{27331
{{mov{3,srtfo{8,wc{{store as field offset{27332
{{add{7,xl{8,wc{{point to field{27333
{{brn{6,srtf1{{{return{27334
{{enp{{{{procedure sortf{27335
{{ejc{{{{{27336
*      sorth -- heap routine for sorta
*      this routine constructs a heap from elements of array, a.
*      in this application, the elements are offsets to keys in
*      a key array.
*      (xs)                  pointer to sort array base
*      1(xs)                 pointer to key array base
*      (wa)                  max array index, n (in bytes)
*      (wc)                  offset j in a to root (in *1 to *n)
*      jsr  sorth            call sorth(j,n) to make heap
*      (xl,xr,wb)            destroyed
{sorth{prc{25,n{1,0{{entry point{27351
{{mov{3,srtsn{8,wa{{save n{27352
{{mov{3,srtwc{8,wc{{keep wc{27353
{{mov{7,xl{9,(xs){{sort array base adrs{27354
{{add{7,xl{3,srtso{{add offset to a(0){27355
{{add{7,xl{8,wc{{point to a(j){27356
{{mov{3,srtrt{9,(xl){{get offset to root{27357
{{add{8,wc{8,wc{{double j - cant exceed n{27358
*      loop to move down tree using doubled index j
{srh01{bgt{8,wc{3,srtsn{6,srh03{done if j gt n{27362
{{beq{8,wc{3,srtsn{6,srh02{skip if j equals n{27363
{{mov{7,xr{9,(xs){{sort array base adrs{27364
{{mov{7,xl{13,num01(xs){{key array base adrs{27365
{{add{7,xr{3,srtso{{point to a(0){27366
{{add{7,xr{8,wc{{adrs of a(j){27367
{{mov{8,wa{13,num01(xr){{get a(j+1){27368
{{mov{8,wb{9,(xr){{get a(j){27369
*      compare sons. (wa) right son, (wb) left son
{{jsr{6,sortc{{{compare keys - lt(a(j+1),a(j)){27373
{{ppm{6,srh02{{{a(j+1) lt a(j){27374
{{ica{8,wc{{{point to greater son, a(j+1){27375
{{ejc{{{{{27376
*      sorth (continued)
*      compare root with greater son
{srh02{mov{7,xl{13,num01(xs){{key array base adrs{27382
{{mov{7,xr{9,(xs){{get sort array address{27383
{{add{7,xr{3,srtso{{adrs of a(0){27384
{{mov{8,wb{7,xr{{copy this adrs{27385
{{add{7,xr{8,wc{{adrs of greater son, a(j){27386
{{mov{8,wa{9,(xr){{get a(j){27387
{{mov{7,xr{8,wb{{point back to a(0){27388
{{mov{8,wb{3,srtrt{{get root{27389
{{jsr{6,sortc{{{compare them - lt(a(j),root){27390
{{ppm{6,srh03{{{father exceeds sons - done{27391
{{mov{7,xr{9,(xs){{get sort array adrs{27392
{{add{7,xr{3,srtso{{point to a(0){27393
{{mov{7,xl{7,xr{{copy it{27394
{{mov{8,wa{8,wc{{copy j{27395
{{btw{8,wc{{{convert to words{27396
{{rsh{8,wc{1,1{{get j/2{27397
{{wtb{8,wc{{{convert back to bytes{27398
{{add{7,xl{8,wa{{point to a(j){27399
{{add{7,xr{8,wc{{adrs of a(j/2){27400
{{mov{9,(xr){9,(xl){{a(j/2) = a(j){27401
{{mov{8,wc{8,wa{{recover j{27402
{{aov{8,wc{8,wc{6,srh03{j = j*2. done if too big{27403
{{brn{6,srh01{{{loop{27404
*      finish by copying root offset back into array
{srh03{btw{8,wc{{{convert to words{27408
{{rsh{8,wc{1,1{{j = j/2{27409
{{wtb{8,wc{{{convert back to bytes{27410
{{mov{7,xr{9,(xs){{sort array adrs{27411
{{add{7,xr{3,srtso{{adrs of a(0){27412
{{add{7,xr{8,wc{{adrs of a(j/2){27413
{{mov{9,(xr){3,srtrt{{a(j/2) = root{27414
{{mov{8,wa{3,srtsn{{restore wa{27415
{{mov{8,wc{3,srtwc{{restore wc{27416
{{exi{{{{return{27417
{{enp{{{{end procedure sorth{27418
{{ejc{{{{{27420
*      trace -- set/reset a trace association
*      this procedure is shared by trace and stoptr to
*      either initiate or stop a trace respectively.
*      (xl)                  trblk ptr (trace) or zero (stoptr)
*      1(xs)                 first argument (name)
*      0(xs)                 second argument (trace type)
*      jsr  trace            call to set/reset trace
*      ppm  loc              transfer loc if 1st arg is bad name
*      ppm  loc              transfer loc if 2nd arg is bad type
*      (xs)                  popped
*      (xl,xr,wa,wb,wc,ia)   destroyed
{trace{prc{25,n{1,2{{entry point{27436
{{jsr{6,gtstg{{{get trace type string{27437
{{ppm{6,trc15{{{jump if not string{27438
{{plc{7,xr{{{else point to string{27439
{{lch{8,wa{9,(xr){{load first character{27440
{{mov{7,xr{9,(xs){{load name argument{27444
{{mov{9,(xs){7,xl{{stack trblk ptr or zero{27445
{{mov{8,wc{18,=trtac{{set trtyp for access trace{27446
{{beq{8,wa{18,=ch_la{6,trc10{jump if a (access){27447
{{mov{8,wc{18,=trtvl{{set trtyp for value trace{27448
{{beq{8,wa{18,=ch_lv{6,trc10{jump if v (value){27449
{{beq{8,wa{18,=ch_bl{6,trc10{jump if blank (value){27450
*      here for l,k,f,c,r
{{beq{8,wa{18,=ch_lf{6,trc01{jump if f (function){27454
{{beq{8,wa{18,=ch_lr{6,trc01{jump if r (return){27455
{{beq{8,wa{18,=ch_ll{6,trc03{jump if l (label){27456
{{beq{8,wa{18,=ch_lk{6,trc06{jump if k (keyword){27457
{{bne{8,wa{18,=ch_lc{6,trc15{else error if not c (call){27458
*      here for f,c,r
{trc01{jsr{6,gtnvr{{{point to vrblk for name{27462
{{ppm{6,trc16{{{jump if bad name{27463
{{ica{7,xs{{{pop stack{27464
{{mov{7,xr{13,vrfnc(xr){{point to function block{27465
{{bne{9,(xr){22,=b_pfc{6,trc17{error if not program function{27466
{{beq{8,wa{18,=ch_lr{6,trc02{jump if r (return){27467
{{ejc{{{{{27468
*      trace (continued)
*      here for f,c to set/reset call trace
{{mov{13,pfctr(xr){7,xl{{set/reset call trace{27474
{{beq{8,wa{18,=ch_lc{6,exnul{exit with null if c (call){27475
*      here for f,r to set/reset return trace
{trc02{mov{13,pfrtr(xr){7,xl{{set/reset return trace{27479
{{exi{{{{return{27480
*      here for l to set/reset label trace
{trc03{jsr{6,gtnvr{{{point to vrblk{27484
{{ppm{6,trc16{{{jump if bad name{27485
{{mov{7,xl{13,vrlbl(xr){{load label pointer{27486
{{bne{9,(xl){22,=b_trt{6,trc04{jump if no old trace{27487
{{mov{7,xl{13,trlbl(xl){{else delete old trace association{27488
*      here with old label trace association deleted
{trc04{beq{7,xl{21,=stndl{6,trc16{error if undefined label{27492
{{mov{8,wb{10,(xs)+{{get trblk ptr again{27493
{{bze{8,wb{6,trc05{{jump if stoptr case{27494
{{mov{13,vrlbl(xr){8,wb{{else set new trblk pointer{27495
{{mov{13,vrtra(xr){22,=b_vrt{{set label trace routine address{27496
{{mov{7,xr{8,wb{{copy trblk pointer{27497
{{mov{13,trlbl(xr){7,xl{{store real label in trblk{27498
{{exi{{{{return{27499
*      here for stoptr case for label
{trc05{mov{13,vrlbl(xr){7,xl{{store label ptr back in vrblk{27503
{{mov{13,vrtra(xr){22,=b_vrg{{store normal transfer address{27504
{{exi{{{{return{27505
{{ejc{{{{{27506
*      trace (continued)
*      here for k (keyword)
{trc06{jsr{6,gtnvr{{{point to vrblk{27512
{{ppm{6,trc16{{{error if not natural var{27513
{{bnz{13,vrlen(xr){6,trc16{{error if not system var{27514
{{ica{7,xs{{{pop stack{27515
{{bze{7,xl{6,trc07{{jump if stoptr case{27516
{{mov{13,trkvr(xl){7,xr{{store vrblk ptr in trblk for ktrex{27517
*      merge here with trblk set up in wb (or zero)
{trc07{mov{7,xr{13,vrsvp(xr){{point to svblk{27521
{{beq{7,xr{21,=v_ert{6,trc08{jump if errtype{27522
{{beq{7,xr{21,=v_stc{6,trc09{jump if stcount{27523
{{bne{7,xr{21,=v_fnc{6,trc17{else error if not fnclevel{27524
*      fnclevel
{{mov{3,r_fnc{7,xl{{set/reset fnclevel trace{27528
{{exi{{{{return{27529
*      errtype
{trc08{mov{3,r_ert{7,xl{{set/reset errtype trace{27533
{{exi{{{{return{27534
*      stcount
{trc09{mov{3,r_stc{7,xl{{set/reset stcount trace{27538
{{jsr{6,stgcc{{{update countdown counters{27539
{{exi{{{{return{27540
{{ejc{{{{{27541
*      trace (continued)
*      a,v merge here with trtyp value in wc
{trc10{jsr{6,gtvar{{{locate variable{27547
{{ppm{6,trc16{{{error if not appropriate name{27548
{{mov{8,wb{10,(xs)+{{get new trblk ptr again{27549
{{add{8,wa{7,xl{{point to variable location{27550
{{mov{7,xr{8,wa{{copy variable pointer{27551
*      loop to search trblk chain
{trc11{mov{7,xl{9,(xr){{point to next entry{27555
{{bne{9,(xl){22,=b_trt{6,trc13{jump if not trblk{27556
{{blt{8,wc{13,trtyp(xl){6,trc13{jump if too far out on chain{27557
{{beq{8,wc{13,trtyp(xl){6,trc12{jump if this matches our type{27558
{{add{7,xl{19,*trnxt{{else point to link field{27559
{{mov{7,xr{7,xl{{copy pointer{27560
{{brn{6,trc11{{{and loop back{27561
*      here to delete an old trblk of the type we were given
{trc12{mov{7,xl{13,trnxt(xl){{get ptr to next block or value{27565
{{mov{9,(xr){7,xl{{store to delete this trblk{27566
*      here after deleting any old association of this type
{trc13{bze{8,wb{6,trc14{{jump if stoptr case{27570
{{mov{9,(xr){8,wb{{else link new trblk in{27571
{{mov{7,xr{8,wb{{copy trblk pointer{27572
{{mov{13,trnxt(xr){7,xl{{store forward pointer{27573
{{mov{13,trtyp(xr){8,wc{{store appropriate trap type code{27574
*      here to make sure vrget,vrsto are set properly
{trc14{mov{7,xr{8,wa{{recall possible vrblk pointer{27578
{{sub{7,xr{19,*vrval{{point back to vrblk{27579
{{jsr{6,setvr{{{set fields if vrblk{27580
{{exi{{{{return{27581
*      here for bad trace type
{trc15{exi{1,2{{{take bad trace type error exit{27585
*      pop stack before failing
{trc16{ica{7,xs{{{pop stack{27589
*      here for bad name argument
{trc17{exi{1,1{{{take bad name error exit{27593
{{enp{{{{end procedure trace{27594
{{ejc{{{{{27595
*      trbld -- build trblk
*      trblk is used by the input, output and trace functions
*      to construct a trblk (trap block)
*      (xr)                  trtag or trter
*      (xl)                  trfnc or trfpt
*      (wb)                  trtyp
*      jsr  trbld            call to build trblk
*      (xr)                  pointer to trblk
*      (wa)                  destroyed
{trbld{prc{25,e{1,0{{entry point{27609
{{mov{11,-(xs){7,xr{{stack trtag (or trfnm){27610
{{mov{8,wa{19,*trsi_{{set size of trblk{27611
{{jsr{6,alloc{{{allocate trblk{27612
{{mov{9,(xr){22,=b_trt{{store first word{27613
{{mov{13,trfnc(xr){7,xl{{store trfnc (or trfpt){27614
{{mov{13,trtag(xr){10,(xs)+{{store trtag (or trfnm){27615
{{mov{13,trtyp(xr){8,wb{{store type{27616
{{mov{13,trval(xr){21,=nulls{{for now, a null value{27617
{{exi{{{{return to caller{27618
{{enp{{{{end procedure trbld{27619
{{ejc{{{{{27620
*      trimr -- trim trailing blanks
*      trimr is passed a pointer to an scblk which must be the
*      last block in dynamic storage. trailing blanks are
*      trimmed off and the dynamic storage pointer reset to
*      the end of the (possibly) shortened block.
*      (wb)                  non-zero to trim trailing blanks
*      (xr)                  pointer to string to trim
*      jsr  trimr            call to trim string
*      (xr)                  pointer to trimmed string
*      (xl,wa,wb,wc)         destroyed
*      the call with wb zero still performs the end zero pad
*      and dnamp readjustment. it is used from acess if kvtrm=0.
{trimr{prc{25,e{1,0{{entry point{27638
{{mov{7,xl{7,xr{{copy string pointer{27639
{{mov{8,wa{13,sclen(xr){{load string length{27640
{{bze{8,wa{6,trim2{{jump if null input{27641
{{plc{7,xl{8,wa{{else point past last character{27642
{{bze{8,wb{6,trim3{{jump if no trim{27643
{{mov{8,wc{18,=ch_bl{{load blank character{27644
*      loop through characters from right to left
{trim0{lch{8,wb{11,-(xl){{load next character{27648
{{beq{8,wb{18,=ch_ht{6,trim1{jump if horizontal tab{27650
{{bne{8,wb{8,wc{6,trim3{jump if non-blank found{27652
{trim1{dcv{8,wa{{{else decrement character count{27653
{{bnz{8,wa{6,trim0{{loop back if more to check{27654
*      here if result is null (null or all-blank input)
{trim2{mov{3,dnamp{7,xr{{wipe out input string block{27658
{{mov{7,xr{21,=nulls{{load null result{27659
{{brn{6,trim5{{{merge to exit{27660
{{ejc{{{{{27661
*      trimr (continued)
*      here with non-blank found (merge for no trim)
{trim3{mov{13,sclen(xr){8,wa{{set new length{27667
{{mov{7,xl{7,xr{{copy string pointer{27668
{{psc{7,xl{8,wa{{ready for storing blanks{27669
{{ctb{8,wa{2,schar{{get length of block in bytes{27670
{{add{8,wa{7,xr{{point past new block{27671
{{mov{3,dnamp{8,wa{{set new top of storage pointer{27672
{{lct{8,wa{18,=cfp_c{{get count of chars in word{27673
{{zer{8,wc{{{set zero char{27674
*      loop to zero pad last word of characters
{trim4{sch{8,wc{10,(xl)+{{store zero character{27678
{{bct{8,wa{6,trim4{{loop back till all stored{27679
{{csc{7,xl{{{complete store characters{27680
*      common exit point
{trim5{zer{7,xl{{{clear garbage xl pointer{27684
{{exi{{{{return to caller{27685
{{enp{{{{end procedure trimr{27686
{{ejc{{{{{27687
*      trxeq -- execute function type trace
*      trxeq is used to execute a trace when a fourth argument
*      has been supplied. trace has already been decremented.
*      (xr)                  pointer to trblk
*      (xl,wa)               name base,offset for variable
*      jsr  trxeq            call to execute trace
*      (wb,wc,ra)            destroyed
*      the following stack entries are made before passing
*      control to the trace function using the cfunc routine.
*                            trxeq return point word(s)
*                            saved value of trace keyword
*                            trblk pointer
*                            name base
*                            name offset
*                            saved value of r_cod
*                            saved code ptr (-r_cod)
*                            saved value of flptr
*      flptr --------------- zero (dummy fail offset)
*                            nmblk for variable name
*      xs ------------------ trace tag
*      r_cod and the code ptr are set to dummy values which
*      cause control to return to the trxeq procedure on success
*      or failure (trxeq ignores a failure condition).
{trxeq{prc{25,r{1,0{{entry point (recursive){27718
{{mov{8,wc{3,r_cod{{load code block pointer{27719
{{scp{8,wb{{{get current code pointer{27720
{{sub{8,wb{8,wc{{make code pointer into offset{27721
{{mov{11,-(xs){3,kvtra{{stack trace keyword value{27722
{{mov{11,-(xs){7,xr{{stack trblk pointer{27723
{{mov{11,-(xs){7,xl{{stack name base{27724
{{mov{11,-(xs){8,wa{{stack name offset{27725
{{mov{11,-(xs){8,wc{{stack code block pointer{27726
{{mov{11,-(xs){8,wb{{stack code pointer offset{27727
{{mov{11,-(xs){3,flptr{{stack old failure pointer{27728
{{zer{11,-(xs){{{set dummy fail offset{27729
{{mov{3,flptr{7,xs{{set new failure pointer{27730
{{zer{3,kvtra{{{reset trace keyword to zero{27731
{{mov{8,wc{21,=trxdc{{load new (dummy) code blk pointer{27732
{{mov{3,r_cod{8,wc{{set as code block pointer{27733
{{lcp{8,wc{{{and new code pointer{27734
{{ejc{{{{{27735
*      trxeq (continued)
*      now prepare arguments for function
{{mov{8,wb{8,wa{{save name offset{27741
{{mov{8,wa{19,*nmsi_{{load nmblk size{27742
{{jsr{6,alloc{{{allocate space for nmblk{27743
{{mov{9,(xr){22,=b_nml{{set type word{27744
{{mov{13,nmbas(xr){7,xl{{store name base{27745
{{mov{13,nmofs(xr){8,wb{{store name offset{27746
{{mov{7,xl{12,6(xs){{reload pointer to trblk{27747
{{mov{11,-(xs){7,xr{{stack nmblk pointer (1st argument){27748
{{mov{11,-(xs){13,trtag(xl){{stack trace tag (2nd argument){27749
{{mov{7,xl{13,trfnc(xl){{load trace vrblk pointer{27750
{{mov{7,xl{13,vrfnc(xl){{load trace function pointer{27751
{{beq{7,xl{21,=stndf{6,trxq2{jump if not a defined function{27752
{{mov{8,wa{18,=num02{{set number of arguments to two{27753
{{brn{6,cfunc{{{jump to call function{27754
*      see o_txr for details of return to this point
{trxq1{mov{7,xs{3,flptr{{point back to our stack entries{27758
{{ica{7,xs{{{pop off garbage fail offset{27759
{{mov{3,flptr{10,(xs)+{{restore old failure pointer{27760
{{mov{8,wb{10,(xs)+{{reload code offset{27761
{{mov{8,wc{10,(xs)+{{load old code base pointer{27762
{{mov{7,xr{8,wc{{copy cdblk pointer{27763
{{mov{3,kvstn{13,cdstm(xr){{restore stmnt no{27764
{{mov{8,wa{10,(xs)+{{reload name offset{27765
{{mov{7,xl{10,(xs)+{{reload name base{27766
{{mov{7,xr{10,(xs)+{{reload trblk pointer{27767
{{mov{3,kvtra{10,(xs)+{{restore trace keyword value{27768
{{add{8,wb{8,wc{{recompute absolute code pointer{27769
{{lcp{8,wb{{{restore code pointer{27770
{{mov{3,r_cod{8,wc{{and code block pointer{27771
{{exi{{{{return to trxeq caller{27772
*      here if the target function is not defined
{trxq2{erb{1,197{26,trace fourth arg is not function name or null{{{27776
{{enp{{{{end procedure trxeq{27778
{{ejc{{{{{27779
*      xscan -- execution function argument scan
*      xscan scans out one token in a prototype argument in
*      array,clear,data,define,load function calls. xscan
*      calls must be preceded by a call to the initialization
*      procedure xscni. the following variables are used.
*      r_xsc                 pointer to scblk for function arg
*      xsofs                 offset (num chars scanned so far)
*      (wa)                  non-zero to skip and trim blanks
*      (wc)                  delimiter one (ch_xx)
*      (xl)                  delimiter two (ch_xx)
*      jsr  xscan            call to scan next item
*      (xr)                  pointer to scblk for token scanned
*      (wa)                  completion code (see below)
*      (wc,xl)               destroyed
*      the scan starts from the current position and continues
*      until one of the following three conditions occurs.
*      1)   delimiter one is encountered  (wa set to 1)
*      2)   delimiter two encountered  (wa set to 2)
*      3)   end of string encountered  (wa set to 0)
*      the result is a string containing all characters scanned
*      up to but not including any delimiter character.
*      the pointer is left pointing past the delimiter.
*      if only one delimiter is to be detected, delimiter one
*      and delimiter two should be set to the same value.
*      in the case where the end of string is encountered, the
*      string includes all the characters to the end of the
*      string. no further calls can be made to xscan until
*      xscni is called to initialize a new argument scan
{{ejc{{{{{27819
*      xscan (continued)
{xscan{prc{25,e{1,0{{entry point{27823
{{mov{3,xscwb{8,wb{{preserve wb{27824
{{mov{11,-(xs){8,wa{{record blank skip flag{27825
{{mov{11,-(xs){8,wa{{and second copy{27826
{{mov{7,xr{3,r_xsc{{point to argument string{27827
{{mov{8,wa{13,sclen(xr){{load string length{27828
{{mov{8,wb{3,xsofs{{load current offset{27829
{{sub{8,wa{8,wb{{get number of remaining characters{27830
{{bze{8,wa{6,xscn3{{jump if no characters left{27831
{{plc{7,xr{8,wb{{point to current character{27832
*      loop to search for delimiter
{xscn1{lch{8,wb{10,(xr)+{{load next character{27836
{{beq{8,wb{8,wc{6,xscn4{jump if delimiter one found{27837
{{beq{8,wb{7,xl{6,xscn5{jump if delimiter two found{27838
{{bze{9,(xs){6,xscn2{{jump if not skipping blanks{27839
{{icv{3,xsofs{{{assume blank and delete it{27840
{{beq{8,wb{18,=ch_ht{6,xscn2{jump if horizontal tab{27842
{{beq{8,wb{18,=ch_bl{6,xscn2{jump if blank{27847
{{dcv{3,xsofs{{{undelete non-blank character{27848
{{zer{9,(xs){{{and discontinue blank checking{27849
*      here after performing any leading blank trimming.
{xscn2{dcv{8,wa{{{decrement count of chars left{27853
{{bnz{8,wa{6,xscn1{{loop back if more chars to go{27854
*      here for runout
{xscn3{mov{7,xl{3,r_xsc{{point to string block{27858
{{mov{8,wa{13,sclen(xl){{get string length{27859
{{mov{8,wb{3,xsofs{{load offset{27860
{{sub{8,wa{8,wb{{get substring length{27861
{{zer{3,r_xsc{{{clear string ptr for collector{27862
{{zer{3,xscrt{{{set zero (runout) return code{27863
{{brn{6,xscn7{{{jump to exit{27864
{{ejc{{{{{27865
*      xscan (continued)
*      here if delimiter one found
{xscn4{mov{3,xscrt{18,=num01{{set return code{27871
{{brn{6,xscn6{{{jump to merge{27872
*      here if delimiter two found
{xscn5{mov{3,xscrt{18,=num02{{set return code{27876
*      merge here after detecting a delimiter
{xscn6{mov{7,xl{3,r_xsc{{reload pointer to string{27880
{{mov{8,wc{13,sclen(xl){{get original length of string{27881
{{sub{8,wc{8,wa{{minus chars left = chars scanned{27882
{{mov{8,wa{8,wc{{move to reg for sbstr{27883
{{mov{8,wb{3,xsofs{{set offset{27884
{{sub{8,wa{8,wb{{compute length for sbstr{27885
{{icv{8,wc{{{adjust new cursor past delimiter{27886
{{mov{3,xsofs{8,wc{{store new offset{27887
*      common exit point
{xscn7{zer{7,xr{{{clear garbage character ptr in xr{27891
{{jsr{6,sbstr{{{build sub-string{27892
{{ica{7,xs{{{remove copy of blank flag{27893
{{mov{8,wb{10,(xs)+{{original blank skip/trim flag{27894
{{bze{13,sclen(xr){6,xscn8{{cannot trim the null string{27895
{{jsr{6,trimr{{{trim trailing blanks if requested{27896
*      final exit point
{xscn8{mov{8,wa{3,xscrt{{load return code{27900
{{mov{8,wb{3,xscwb{{restore wb{27901
{{exi{{{{return to xscan caller{27902
{{enp{{{{end procedure xscan{27903
{{ejc{{{{{27904
*      xscni -- execution function argument scan
*      xscni initializes the scan used for prototype arguments
*      in the clear, define, load, data, array functions. see
*      xscan for the procedure which is used after this call.
*      -(xs)                 argument to be scanned (on stack)
*      jsr  xscni            call to scan argument
*      ppm  loc              transfer loc if arg is not string
*      ppm  loc              transfer loc if argument is null
*      (xs)                  popped
*      (xr,r_xsc)            argument (scblk ptr)
*      (wa)                  argument length
*      (ia,ra)               destroyed
{xscni{prc{25,n{1,2{{entry point{27921
{{jsr{6,gtstg{{{fetch argument as string{27922
{{ppm{6,xsci1{{{jump if not convertible{27923
{{mov{3,r_xsc{7,xr{{else store scblk ptr for xscan{27924
{{zer{3,xsofs{{{set offset to zero{27925
{{bze{8,wa{6,xsci2{{jump if null string{27926
{{exi{{{{return to xscni caller{27927
*      here if argument is not a string
{xsci1{exi{1,1{{{take not-string error exit{27931
*      here for null string
{xsci2{exi{1,2{{{take null-string error exit{27935
{{enp{{{{end procedure xscni{27936
{{ttl{27,s p i t b o l -- stack overflow section{{{{27937
*      control comes here if the main stack overflows
{{sec{{{{start of stack overflow section{27941
{{add{3,errft{18,=num04{{force conclusive fatal error{27943
{{mov{7,xs{3,flptr{{pop stack to avoid more fails{27944
{{bnz{3,gbcfl{6,stak1{{jump if garbage collecting{27945
{{erb{1,246{26,stack overflow{{{27946
*      no chance of recovery in mid garbage collection
{stak1{mov{7,xr{21,=endso{{point to message{27950
{{zer{3,kvdmp{{{memory is undumpable{27951
{{brn{6,stopr{{{give up{27952
{{ttl{27,s p i t b o l -- error section{{{{27953
*      this section of code is entered whenever a procedure
*      return via an err parameter or an erb opcode is obeyed.
*      (wa)                  is the error code
*      the global variable stage indicates the point at which
*      the error occured as follows.
*      stage=stgic           error during initial compile
*      stage=stgxc           error during compile at execute
*                            time (code, convert function calls)
*      stage=stgev           error during compilation of
*                            expression at execution time
*                            (eval, convert function call).
*      stage=stgxt           error at execute time. compiler
*                            not active.
*      stage=stgce           error during initial compile after
*                            scanning out the end line.
*      stage=stgxe           error during compile at execute
*                            time after scanning end line.
*      stage=stgee           error during expression evaluation
{{sec{{{{start of error section{27983
{error{beq{3,r_cim{20,=cmlab{6,cmple{jump if error in scanning label{27985
{{mov{3,kvert{8,wa{{save error code{27986
{{zer{3,scnrs{{{reset rescan switch for scane{27987
{{zer{3,scngo{{{reset goto switch for scane{27988
{{mov{3,polcs{18,=num01{{reset poll count{27990
{{mov{3,polct{18,=num01{{reset poll count{27991
{{mov{7,xr{3,stage{{load current stage{27993
{{bsw{7,xr{2,stgno{{jump to appropriate error circuit{27994
{{iff{2,stgic{6,err01{{initial compile{28002
{{iff{2,stgxc{6,err04{{execute time compile{28002
{{iff{2,stgev{6,err04{{eval compiling expr.{28002
{{iff{2,stgxt{6,err05{{execute time{28002
{{iff{2,stgce{6,err01{{compile - after end{28002
{{iff{2,stgxe{6,err04{{xeq compile-past end{28002
{{iff{2,stgee{6,err04{{eval evaluating expr{28002
{{esw{{{{end switch on error type{28002
{{ejc{{{{{28003
*      error during initial compile
*      the error message is printed as part of the compiler
*      output. this printout includes the offending line (if not
*      printed already) and an error flag under the appropriate
*      column as indicated by scnse unless scnse is set to zero.
*      after printing the message, the generated code is
*      modified to an error call and control is returned to
*      the cmpil procedure after resetting the stack pointer.
*      if the error occurs after the end line, control returns
*      in a slightly different manner to ensure proper cleanup.
{err01{mov{7,xs{3,cmpxs{{reset stack pointer{28019
{{ssl{3,cmpss{{{restore s-r stack ptr for cmpil{28020
{{bnz{3,errsp{6,err03{{jump if error suppress flag set{28021
{{mov{8,wc{3,cmpsn{{current statement{28024
{{jsr{6,filnm{{{obtain file name for this statement{28025
{{mov{8,wb{3,scnse{{column number{28027
{{mov{8,wc{3,rdcln{{line number{28028
{{mov{7,xr{3,stage{{{28029
{{jsr{6,sysea{{{advise system of error{28030
{{ppm{6,erra3{{{if system does not want print{28031
{{mov{11,-(xs){7,xr{{save any provided print message{28032
{{mov{3,erlst{3,erich{{set flag for listr{28034
{{jsr{6,listr{{{list line{28035
{{jsr{6,prtis{{{terminate listing{28036
{{zer{3,erlst{{{clear listr flag{28037
{{mov{8,wa{3,scnse{{load scan element offset{28038
{{bze{8,wa{6,err02{{skip if not set{28039
{{lct{8,wb{8,wa{{loop counter{28041
{{icv{8,wa{{{increase for ch_ex{28042
{{mov{7,xl{3,r_cim{{point to bad statement{28043
{{jsr{6,alocs{{{string block for error flag{28044
{{mov{8,wa{7,xr{{remember string ptr{28045
{{psc{7,xr{{{ready for character storing{28046
{{plc{7,xl{{{ready to get chars{28047
*      loop to replace all chars but tabs by blanks
{erra1{lch{8,wc{10,(xl)+{{get next char{28051
{{beq{8,wc{18,=ch_ht{6,erra2{skip if tab{28052
{{mov{8,wc{18,=ch_bl{{get a blank{28053
{{ejc{{{{{28054
*      merge to store blank or tab in error line
{erra2{sch{8,wc{10,(xr)+{{store char{28058
{{bct{8,wb{6,erra1{{loop{28059
{{mov{7,xl{18,=ch_ex{{exclamation mark{28060
{{sch{7,xl{9,(xr){{store at end of error line{28061
{{csc{7,xr{{{end of sch loop{28062
{{mov{3,profs{18,=stnpd{{allow for statement number{28063
{{mov{7,xr{8,wa{{point to error line{28064
{{jsr{6,prtst{{{print error line{28065
*      here after placing error flag as required
{err02{jsr{6,prtis{{{print blank line{28079
{{mov{7,xr{10,(xs)+{{restore any sysea message{28081
{{bze{7,xr{6,erra0{{did sysea provide message to print{28082
{{jsr{6,prtst{{{print sysea message{28083
{erra0{jsr{6,ermsg{{{generate flag and error message{28085
{{add{3,lstlc{18,=num03{{bump page ctr for blank, error, blk{28086
{erra3{zer{7,xr{{{in case of fatal error{28087
{{bhi{3,errft{18,=num03{6,stopr{pack up if several fatals{28088
*      count error, inhibit execution if required
{{icv{3,cmerc{{{bump error count{28092
{{add{3,noxeq{3,cswer{{inhibit xeq if -noerrors{28093
{{bne{3,stage{18,=stgic{6,cmp10{special return if after end line{28094
{{ejc{{{{{28095
*      loop to scan to end of statement
{err03{mov{7,xr{3,r_cim{{point to start of image{28099
{{plc{7,xr{{{point to first char{28100
{{lch{7,xr{9,(xr){{get first char{28101
{{beq{7,xr{18,=ch_mn{6,cmpce{jump if error in control card{28102
{{zer{3,scnrs{{{clear rescan flag{28103
{{mnz{3,errsp{{{set error suppress flag{28104
{{jsr{6,scane{{{scan next element{28105
{{bne{7,xl{18,=t_smc{6,err03{loop back if not statement end{28106
{{zer{3,errsp{{{clear error suppress flag{28107
*      generate error call in code and return to cmpil
{{mov{3,cwcof{19,*cdcod{{reset offset in ccblk{28111
{{mov{8,wa{21,=ocer_{{load compile error call{28112
{{jsr{6,cdwrd{{{generate it{28113
{{mov{13,cmsoc(xs){3,cwcof{{set success fill in offset{28114
{{mnz{13,cmffc(xs){{{set failure fill in flag{28115
{{jsr{6,cdwrd{{{generate succ. fill in word{28116
{{brn{6,cmpse{{{merge to generate error as cdfal{28117
*      error during execute time compile or expression evaluatio
*      execute time compilation is initiated through gtcod or
*      gtexp which are called by compile, code or eval.
*      before causing statement failure through exfal it is
*      helpful to set keyword errtext and for generality
*      these errors may be handled by the setexit mechanism.
{err04{bge{3,errft{18,=num03{6,labo1{abort if too many fatal errors{28127
{{beq{3,kvert{18,=nm320{6,err06{treat user interrupt specially{28129
{{zer{3,r_ccb{{{forget garbage code block{28131
{{mov{3,cwcof{19,*cccod{{set initial offset (mbe catspaw){28132
{{ssl{3,iniss{{{restore main prog s-r stack ptr{28133
{{jsr{6,ertex{{{get fail message text{28134
{{dca{7,xs{{{ensure stack ok on loop start{28135
*      pop stack until find flptr for most deeply nested prog.
*      defined function call or call of eval / code.
{erra4{ica{7,xs{{{pop stack{28140
{{beq{7,xs{3,flprt{6,errc4{jump if prog defined fn call found{28141
{{bne{7,xs{3,gtcef{6,erra4{loop if not eval or code call yet{28142
{{mov{3,stage{18,=stgxt{{re-set stage for execute{28143
{{mov{3,r_cod{3,r_gtc{{recover code ptr{28144
{{mov{3,flptr{7,xs{{restore fail pointer{28145
{{zer{3,r_cim{{{forget possible image{28146
{{zer{3,cnind{{{forget possible include{28148
*      test errlimit
{errb4{bnz{3,kverl{6,err07{{jump if errlimit non-zero{28153
{{brn{6,exfal{{{fail{28154
*      return from prog. defined function is outstanding
{errc4{mov{7,xs{3,flptr{{restore stack from flptr{28158
{{brn{6,errb4{{{merge{28159
{{ejc{{{{{28160
*      error at execute time.
*      the action taken on an error is as follows.
*      if errlimit keyword is zero, an abort is signalled,
*      see coding for system label abort at l_abo.
*      otherwise, errlimit is decremented and an errtype trace
*      generated if required. control returns either via a jump
*      to continue (to take the failure exit) or a specified
*      setexit trap is executed and control passes to the trap.
*      if 3 or more fatal errors occur an abort is signalled
*      regardless of errlimit and setexit - looping is all too
*      probable otherwise. fatal errors include stack overflow
*      and exceeding stlimit.
{err05{ssl{3,iniss{{{restore main prog s-r stack ptr{28178
{{bnz{3,dmvch{6,err08{{jump if in mid-dump{28179
*      merge here from err08 and err04 (error 320)
{err06{bze{3,kverl{6,labo1{{abort if errlimit is zero{28183
{{jsr{6,ertex{{{get fail message text{28184
*      merge from err04
{err07{bge{3,errft{18,=num03{6,labo1{abort if too many fatal errors{28188
{{dcv{3,kverl{{{decrement errlimit{28189
{{mov{7,xl{3,r_ert{{load errtype trace pointer{28190
{{jsr{6,ktrex{{{generate errtype trace if required{28191
{{mov{8,wa{3,r_cod{{get current code block{28192
{{mov{3,r_cnt{8,wa{{set cdblk ptr for continuation{28193
{{scp{8,wb{{{current code pointer{28194
{{sub{8,wb{8,wa{{offset within code block{28195
{{mov{3,stxoc{8,wb{{save code ptr offset for scontinue{28196
{{mov{7,xr{3,flptr{{set ptr to failure offset{28197
{{mov{3,stxof{9,(xr){{save failure offset for continue{28198
{{mov{7,xr{3,r_sxc{{load setexit cdblk pointer{28199
{{bze{7,xr{6,lcnt1{{continue if no setexit trap{28200
{{zer{3,r_sxc{{{else reset trap{28201
{{mov{3,stxvr{21,=nulls{{reset setexit arg to null{28202
{{mov{7,xl{9,(xr){{load ptr to code block routine{28203
{{bri{7,xl{{{execute first trap statement{28204
*      interrupted partly through a dump whilst store is in a
*      mess so do a tidy up operation. see dumpr for details.
{err08{mov{7,xr{3,dmvch{{chain head for affected vrblks{28209
{{bze{7,xr{6,err06{{done if zero{28210
{{mov{3,dmvch{9,(xr){{set next link as chain head{28211
{{jsr{6,setvr{{{restore vrget field{28212
*      label to mark end of code
{s_yyy{brn{6,err08{{{loop through chain{28216
{{ttl{27,s p i t b o l -- here endeth the code{{{{28217
*      end of assembly
{{end{{{{end macro-spitbol assembly{28221
