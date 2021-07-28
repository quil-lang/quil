@section[:title "Classical Memory"]

@p{This section explains Quil's classical memory model.}

@subsection[:title "Design Considerations"]

@emph{This section is descriptive and not normative.}

@p{In assembly code, in general, types are considered only at the
mnemonic or interpretation level. They're not often a consideration in
the code itself. (Though this is not always true, machine codes for
dynamic languages included the notion of type checking and type tags
at the instruction level.) On modern processor architectures, one has
a large @emph{random access memory} (RAM) which is byte-addressable,
and a series of processor @emph{registers} that hold usually one
word's worth of data. (A @emph{word} is often some multiple of bytes,
usually 4 or 8.) A @emph{register machine} is one that loads values
from memory to the registers, does some operation, and often stores
the results back into memory.}

@p{So far, we've spoken only of bytes or multiples thereof. A byte—or
word for that matter—is simply a measure of a number of bits, with no
additional attached interpretation. What gives a byte interpretation
is the literal machinery attached to the registers in which the bytes
are stored. Implicit in the machinery, usually electrical circuitry,
is a way of transforming bytes into a new ones. This machinery is
invoked with an @emph{opcode}. Since opcodes relate to physical machinery,
opcodes are often only pertinent to a subset of registers that a
machine has. From here, we get a usual partitioning of registers:
registers that deal with general integer arithmetic, registers that
deal with floating point numbers, registers that deal with vectorized
low-precision arithmetic, registers that interact with main memory,
and so on. The partition isn't always so strict; @emph{general purpose
registers} often are capable of many disparate operations.}

@p{RAM more often than not lacks any serious kind of operation except
loading and storing. Similarly, cross-register opcodes also deal with
the movement of data and not operation on the data contained
within. When we want to do something like adding an integer and
floating point number, we have to put the integer into a floating
point representation, move it from an integer register to a floating
point register, and perform the addition across two floating point
registers. Some architectures, such as the x87 floating point unit,
can perform the representation-changing and loading in a single
instruction (e.g., the @c{FILD} instruction).}

@p{Quil was designed to be an instruction language that doesn't
conform to any physical architecture. It was designed to accommodate
evolving quantum architectures in terms of their memory models and
their native gates. In some sense, Quil can be seen as a portable
bytecode of sorts, (currently) without an actual byte-code
representation.}

@p{The original 2016 Quil paper assumes there is an unbounded classical
memory composed of a series of bits, and segments of these bits can be
interpreted as a real or complex number. While very simplistic, it has
a few flaws:

@itemize{
    @item{The type of a data segment is determined solely by its
    length (64 bits indicates a double-precision floating point
    number, 128 bits indicates a double-precision complex number).}

    @item{There are no provisions for the construction or use of
    integer data, which is desirable for counters and frequentist
    statistics.}

    @item{There are no classical instructions that make use of
    segments, despite an inherent desire to do high-speed arithmetic
    on gate angles.}

    @item{Quil code making heavy use of segments quickly becomes
    unwieldy and unreadable.}

    @item{Quil code has no friendly notion of @emph{linkage}, which
    would allow a concurrently run classical program to refer to named
    data.}
}
}

@p{In the remainder of this section, we describe a replacement for the
notion of classical data in Quil. It is similar to C in that we don't
select any particular memory model, and require the user to specify
what he or she requires in terms of layout. Similarly departing from
usual instruction sets, we allow for memory to be interpreted through
multiple type lenses. In C, we accomplish this by casting pointers and
dereferencing. Since we don't have a notion of pointers, we accomplish
this with explicit declaration and aliasing.}

@p{With Quil's classical memory model, we can write code which does
the following:

@clist{
DECLARE count INTEGER
DECLARE stats INTEGER
DECLARE measurement INTEGER
DECLARE angle REAL
DECLARE cond BIT

# Initialize
MOVE stats 0
MOVE angle 0.0

# Start the angle loop
LABEL @@start_angle_loop
LT cond angle 6.283185307179586
JUMP-UNLESS @@end cond
# Perform histogram loop, 1000 shots
MOVE count 1000
LABEL @@stats_loop
RX(angle) 0
MEASURE 0 measurement
ADD stats measurement
SUB count 1
GT cond count 0
JUMP-WHEN @@stats_loop cond
# Calculate next angle
ADD angle 0.3926990816987241   # pi/8
JUMP @@start_angle_loop
LABEL @@end
}
}

@p{This will be roughly equivalent to the following C program:

@clist{
int count, stats, measurement;
float angle;
stats = 0;
for(angle = 0.0; angle < 6.283185307179586; angle += 0.3926990816987241) {
    for(count = 1000; count > 0; count--) {
        RX(angle) 0
        measurement = MEASURE 0
        stats += measurement
    }
}
}
}


@subsection[:title "Types"]

@p{The supported types are @c{BIT} which represents one bit, @c{OCTET}
which represents 8 bits, @c{INTEGER} which represents a machine-sized
signed integer, and @c{REAL} which represents a machine-sized real
number. The formats/layouts of these are specific to the machine being
run on.}

@syntax[:name "Base Type"]{
        BIT
   @alt OCTET
   @alt INTEGER
   @alt REAL
}

@p{When we speak of @emph{size}, we mean the number of octets that a
type represents. The notion of @emph{size} is distinct from
@emph{length}, which instead refers to some count of elements of a
particular type.}

@p{A fixed-length vector of a type is denoted by the type name
followed by an integer in brackets. For instance, @c{REAL[5]} is a
type that represents five real numbers in sequence. The type
@c{INTEGER} is guaranteed to be large enough to hold a valid length of
octets, and is guaranteed to hold at least the values @m{-127} to
@m{128}.}

@syntax[:name "Type"]{
        @ms{Base Type}
   @alt @ms{Base Type}[@ms{Integer}]
}

@p{There are currently no provisions for adding additional types.}

@subsection[:title "Declaring Memory"]

@p{Quil doesn't have a notion of @emph{allocating} memory, but rather
the notion of @emph{declaring the existence} of memory. In the
following, we introduce the @c{DECLARE} directive, which describes
available memory for a program to use.}

@p{Some quantum computing architectures might restrict what can be
declared, what types can be used, what names can be used, etc. It is
recommended to be as liberal as possible in what can be declared,
while remaining true to the architectural constraints of the system on
which Quil is executed.}

@p{The @c{DECLARE} directive is used to declare a vector of typed
memory. There are three variants: plain declaration, aliased
declaration, and aliased declaration with offset.}

@syntax[:name "Classical Memory Declaration"]{
         @ms{Plain Memory Declaration}
    @alt @ms{Aliased Memory Declaration}
    @alt @ms{Offset Memory Declaration}
}

@subsubsection[:title "Declaring Memory"]

@p{The simplest kind of memory declaration is a plain one.}

@syntax[:name "Plain Memory Declaration"]{
    DECLARE @ms{Identifier} @ms{Type}
}

@p{This declares that @ms{Identifier} designates memory which can hold
@ms{Type}. If @ms{Type} is a scalar type, then it is assumed to
designate a vector of length 1. That is, the following two lines are
equivalent:

@clist{
DECLARE x INTEGER
DECLARE x INTEGER[1]
}
}

@p{In the program that would follow either of these declarations,
@c{x} or equivalently @c{x[0]} will refer to an integer quantity.}

@subsubsection[:title "Declaring Aliased Memory"]

@syntax[:name "Aliased Memory Declaration"]{
DECLARE @ms[:sub 1]{Identifier} @ms{Type} SHARING @ms[:sub 2]{Identifier}
}

@p{This declares that @ms[:sub 1]{Identifier} designates memory which can hold
@ms{Type}, but @ms[:sub 1]{Identifier} shares memory with that which is designated
by @ms[:sub 2]{Identifier}. Here, the total memory size pointed to by
@ms[:sub 1]{Identifier} shall not exceed the total memory size pointed to by
@ms[:sub 2]{Identifier}.}

@p{An implementation is free to reject programs where particular
instances of sharing is invalid (e.g., alignment is violated;
disparate memories are unshareable; etc.).}

@subsubsection[:title "Declaring Aliased Memory Declaration with an Offset"]

@syntax[:name "Offset Memory Declaration"]{
DECLARE @ms[:sub 1]{Identifier}
        @ms{Type}
        SHARING @ms[:sub 2]{Identifier}
        OFFSET
        @rep[:min 1]{
          @group{
            @ms[:sub "i"]{Integer}
            @ms[:sub "i"]{Type}
          }
        }
}

@p{This is similar to the aliased declaration, but it allows
@ms[:sub 1]{Identifier} to designate memory in the middle of that which is
designated by @ms[:sub 2]{Identifier}. In particular, @ms[:sub 1]{Identifier} will point
to memory a total of @dm{\sum_i \langle\texttt{Integer}_i\rangle\cdot
\text{sizeof}(\langle\texttt{Type}_i\rangle)} bits after the start of
@ms[:sub 2]{Identifier}. As with an aliased declaration, the memory at
@ms[:sub 1]{Identifier} must not overflow the end of @ms[:sub 2]{Identifier}.}

@p{Implementations may enforce alignment by way of erroring if the
stated declaration is invalid. Implementations must @emph{not} round
up or down to alignment boundaries.}

@subsubsection[:title "Portability of Aliased Declarations"]

@p{Aliased declarations with mixed types require an intimate view of
the target architecture. The widths of each data type, which are
hitherto unspecified, must be known. For example, the following
declarations may not be valid of the size of @c{REAL} exceeds the size
of @c{INTEGER}.

@clist{
DECLARE x INTEGER
DECLARE y REAL SHARING x
}

Even if such a declaration is valid, operations on @c{y} are not
portably specified. For example, continuing the above,

@clist{
DECLARE b BIT
MOVE x 0
EQ b y 0.0
}

could result in any value for @c{b}, depending on the implementation.
}

@p{An implementation shall describe the bit-level description of the
types, the available declarable memories, the limits on the declared
memory, alignment requirements, and limits on sharing and offsets.}

@subsubsection[:title "Duplicate Declaration Identifiers"]

@p{It is an error to declare the same name more than once.}

@subsubsection[:title "Examples"]

@subsubsubsection[:title "Register Machine with a Condition Bit"]

@p{Here we consider a layout for a machine that has one integer
register, two real registers, and a @emph{condition bit} used for
doing comparisons and branching.

@clist{
DECLARE f1 REAL
DECLARE f2 REAL
DECLARE x INTEGER
DECLARE cmp BIT    # cmp for "comparison"
}
}

@p{This might be suitable for a very simple quantum control system
with a single counter for loops.}

@subsubsubsection[:title "Memory-Mapped RAM"]

@p{The following is an example of a memory structure that might be
used in a system with a fixed and known memory layout optimized for
running QAOA-like circuits.

@clist{
DECLARE memory OCTET[131072]                              # 128k global memory
DECLARE qaoa-params REAL[32] SHARING memory               # all QAOA params
DECLARE beta REAL[16] SHARING qaoa-params                 # beta params
DECLARE gamma REAL[16] SHARING qaoa-params OFFSET 16 REAL # gamma params
DECLARE ro BIT[16]                                        # readout registers
}
}

@p{Here, we have two disjoint memories: the global data memory
@c{memory}, and the readout memory @c{ro}. We see that the global data
memory @c{memory} is further partitioned into a section
@c{qaoa-params} specifically for QAOA parameters, which may be useful
if you're changing them all at once. Nonetheless, for actual use in
Quil code, the actual @c{beta} and @c{gamma} parameters are carved out
of this memory.}

@p{This particular scheme may be necessary if software processing Quil
does not have any ability generate memory maps automatically. If that
functionality were possible, one could simply declare @c{beta},
@c{gamma}, and @c{ro} and let the compilation software take care of
mapping that to physical memory.}

@subsubsubsection[:title "Computing Bits of an Angle"]

@p{In algorithms like phase estimation, we compute one bit of the result
at a time with each measurement. If our @c{INTEGER} data type has the
standard binary representation, then one can do:

@clist{
DECLARE unadjusted-theta INTEGER
DECLARE ro BIT[16] SHARING unadjusted-theta
DECLARE theta REAL
# <phase estimation>
MEASURE 0 ro[0]
MEASURE 1 ro[1]
# ...
MEASURE 15 ro[15]
}
}

@p{Here, we have a 16-bit integer @c{unadjusted-theta} with the LSB of
our estimated phase starting with qubit 0. (This depends on our
convention in our implementation of phase estimation.) Since
@c{unadjusted-theta} and @c{ro} are shared, the bits of @c{ro}
directly affect the bits of our integer. Recalling that phase
estimation gives us a bitstring (in this case, an integer between
@m{0} and @m{2^{16} - 1}), we must actually adjust it by multiplying by
@m{2\pi/2^{16}}, which is approximately @m{9.587379924285257\times
10^{-5}}.}

@p{Since @c{theta} and @c{unadjusted-theta} have different types, we
can't quite yet do this multiplication. We need to convert
@c{unadjusted-theta} into a @c{REAL} representation on which we can do
fractional arithmetic. We can do this with @c{CONVERT}, which in other
languages is known as a @emph{cast} or @emph{coercion}.

@clist{
CONVERT theta unadjusted-theta   # convert INTEGER to REAL
MUL     theta theta 9.587379924285257e-5
}
}

@p{Now we can use @c{theta} as an argument to an angle if we
please. For example, we might do a phase adjustment based off of that
angle on qubit @c{16}:

@clist{
RZ(theta) 16
}
}

@subsection[:title "Memory Access and Dereferencing"]

@p{Memory is dereferenced in a Quil program using common array
access syntax. In particular, given a name @c{x} pointing to
memory of type @m{T}, and a non-negative integer offset @m{n}, the
syntax @c{x[@m{n}]} refers to the @m{n}th element of type @m{T} indexing
off of @c{x[0]}.}

@p{If and only if @c{x} was declared with just a single element, then
@c{x} may be referred to simply by its name with no bracket. In this
case, @c{x} and @c{x[0]} would be equivalent.}

@syntax[:name "Memory Reference"]{
         @ms{Identifier}
    @alt @ms{Identifier}[@ms{Integer}]
}

@aside{Note that this memory reference is @emph{formal}. The lone
@ms{Identifier} in certain contexts may refer to a named argument of,
for example, a circuit definition.}

@p{Dereferencing with indirection, e.g., something akin to
@c{x[y[3]]}, is supported through the @c{LOAD} and @c{STORE}
instructions. For example,

@clist{
DECLARE x INTEGER[16]
DECLARE y INTEGER[16]
DECLARE z INTEGER[16]
DECLARE t INTEGER
LOAD t y z[3]          # t := y[z[3]]
LOAD t x t             # t := x[t]
}
}

@subsection[:title "Classical Instructions"]

@p{With typed memory comes a bag of new instructions. Classical
instructions come in unary (single-argument), binary
(double-argument), and ternary (triple-argument) forms. They all share
the same syntax.}

@syntax[:name "Classical Memory Instruction"]{
         @ms{Classical Unary} @ms{Memory Reference}
    @alt @ms{Classical Binary} @rep[:min 2 :max 2]{@ms{Memory Reference}}
    @alt @ms{Classical Ternary} @rep[:min 3 :max 3]{@ms{Memory Reference}}
}

@p{The unary instruction names are:}

@syntax[:name "Classical Unary"]{
    NOT @alt NEG
}

@p{The binary instruction names are:}

@syntax[:name "Classical Binary"]{
         MOVE @alt EXCHANGE @alt CONVERT
    @alt AND @alt IOR @alt XOR
    @alt ADD @alt SUB @alt MUL @alt DIV
}

@p{The ternary instruction names are:}

@syntax[:name "Classical Ternary"]{
    LOAD @alt STORE @alt EQ @alt GT @alt GE @alt LT @alt LE
}

@p{While the instructions all take memory references, they only take
memory references of certain type combinations. Each combination is
called an "instruction mode". In the following table, we use the
following notation to denote an instruction @c{INSTR} and its modes:

@clist{
# Category of instruction
INSTR   a b             # Pseudocode meaning
        <type1a> <type1b>
        <type2a> <type2b>
        ...
}
}

@p{The possibilities for @c{<typeXY>} are:

@itemize{
@item{@c{<!int>}  : Immediate (literal) integer, also used for octets (@c{0} to @c{255}) and bits (@c{0} and @c{1})}
@item{@c{<int>}   : Memory reference to an integer}
@item{@c{<int*>}  : Name of a vector of declared integers}
@item{@c{<!real>} : Immediate (literal) real}
@item{@c{<real>}  : Memory reference to a real}
@item{@c{<real*>} : Name of a vector of declared reals}
@item{@c{<bit>}   : Memory reference to a bit}
@item{@c{<bit*>}  : Name of a vector of declared bits}
@item{@c{<oct>}   : Memory reference to an octet}
@item{@c{<oct*>}  : Name of a vector of declared octets}
}
}

@p{Octet literals share the same syntax as integer literals.}

@p{We generally follow the @c{dest}-@c{src} ordering of arguments.}

@clist{
# Move like-typed data to different locations.
# Also allows loading immediate values.
MOVE     a b            # a := b; Store contents of b at a
         <oct> <!int>
         <oct> <oct>
         <int> <!int>
         <int> <int>
         <real> <!real>
         <real> <real>
         <bit> <!int>
         <bit> <bit>

# Exchange the value at two like-typed locations.
EXCHANGE a b            # Exchange contents of a and b; a <=> b
         <oct> <oct>
         <int> <int>
         <real> <real>
         <bit> <bit>

# Perform an indirect load from x offset by n to a.
LOAD     a x n          # a := x[n]
         <oct> <oct*> <int>
         <int> <int*> <int>
         <real> <real*> <int>
         <bit> <bit*> <int>

# Perform an indirect store of a to x offset by n.
STORE    x n a          # x[n] := a
         <oct*> <int> <oct>
         <oct*> <int> <!int>
         <int*> <int> <int>
         <int*> <int> <!int>
         <real*> <int> <real>
         <real*> <int> <!real>
         <bit*> <int> <bit>
         <bit*> <int> <!int>

# Perform a move of differently typed data.
# The data here is interpreted numerically.
CONVERT  a b            # a := (T)b, where T = type-of(a)
         <int> <real>   # - Best integer approximation of a real.
         <int> <bit>    # - Convert 0 or 1 to an integer.
         <real> <int>   # - Best real approximation of an integer.
         <real> <bit>   # - Convert 0 or 1 to a real.
         <bit> <int>    # - 0 if 0, 1 if non-zero.
         <bit> <real>   # - 0 if 0.0, 1 if non-zero

# Logical Operations
NOT      a              # a := ~a
         <oct>
         <int>
         <bit>

AND      a b            # a := a & b
IOR      a b            # a := a | b
XOR      a b            # a := a ^ b
         <oct> <oct>
         <oct> <!int>
         <int> <int>
         <int> <!int>
         <bit> <bit>
         <bit> <!int>

# Arithmetic Operations
NEG      a              # a := -a
         <int>
         <real>

ADD      a b            # a := a + b
SUB      a b            # a := a - b
MUL      a b            # a := a * b
DIV      a b            # a := a / b
         <int> <int>
         <int> <!int>
         <real> <!real>
         <real> <real>

# Comparison
EQ       r a b          # r := (a == b)
GT       r a b          # r := (a > b)
GE       r a b          # r := (a >= b)
LT       r a b          # r := (a < b)
LE       r a b          # r := (a <= b)
         <bit> <bit> <bit>
         <bit> <bit> <!int>
         <bit> <oct> <oct>
         <bit> <oct> <!int>
         <bit> <int> <int>
         <bit> <int> <!int>
         <bit> <real> <real>
         <bit> <real> <!real>
}

