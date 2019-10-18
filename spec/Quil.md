# Quil

*Quil 2.0 released in September, 2018*

### Introduction

This is the specification for Quil, a practical quantum instruction set
architecture released by Rigetti Computing.

Quil is an instruction-based language for representing quantum computations
with classical feedback and control. It can be written directly for the purpose
of quantum programming, used as an intermediate format within classical
programs, or used as a compilation target for quantum programming languages.

### Copyright notice

Copyright © 2016‐present, Rigetti & Co, Inc.

## 1. Overview

Quil was designed to support the development of hybrid algorithms, algorithms
with both quantum and classical components.

The "hello world" Quil program is doing a quantum coin flip. This initializes
a qubit into an equal superposition state and then measures the qubit, returning
either a 0 or 1 depending on the measured state.

In Quil this would be specified as follows:

```
DECLARE ro BIT[1]
H 0
MEASURE 0 ro[0]
```

- Line 1 declares a single classical bit to be used for readout
- Line 2 applies the Hadamard gate to qubit 0, putting the qubit into an equal
superposition state
- Line 3 measures the qubit and stores it into the classical bit declared on
Line 1

The remainder of this document serves as a reference for all Quil language
constructs and their associated semantics.

### Semantic Conventions

In describing the meaning or interpretation of certain instructions, we will
have occasion to speak of notions such as "quantum state", "collapse of the
wavefunction", and so forth. Here we briefly collect some relevant remarks.

A Quil program manipulates a collection of classical and quantum resources. The
quantum resources consist of a set of _qubits_, which are usually referred to by
numerical indices. There is no bound on the number of qubits in a Quil program,
and in general any finite collection of qubits may interact. Physical devices,
however, may impose constraints on the number of qubits and their allowed
interactions.

(Currently, Quil has no provisions for allocating an unbounded number of qubits at runtime. The number of qubits used by a program can be statically determined.)

**For the purposes of this document**, a full description of the state of a set
of n qubits will usually be expressed via an associated 2ⁿ-dimensional
_wavefunction_. Quil expresses quantum computations with respect to a fixed
computational basis. Thus a wavefunction may be expressed as a linear
combination of _basis elements_, which are written as `|b⟩` for a bitstring b of
length `n`. For example, the _Bell state_, which we write as `(|00⟩ + |11⟩)/sqrt(2)`, 
is a combination of two basis elements. Given some collection of qubits, the 
_zero state_ is that state in which each qubit is deterministically zero. The
corresponding wavefunction is `|00...0⟩`.

**Note:** we also adopt the convention that the "i-th" entry of a bitstring is
to be considered from right-to-left, starting from zero. Thus in `|001⟩`, the
zeroth bit is 1, while bits one and two are 0.

It will sometimes be convenient to speak of _mixed states_. Here we
intentionally keep the discussion light: for the most part, it will suffice to
consider simple probabilistic statements (e.g. "the system is in state A or B,
each with probability 1/2"). This is particularly relevant when considering the
meaning of Quil programs involving measurement or classical control flow.

A fuller discussion of related aspects of Quil semantics may be found in the original whitepaper
```
R. Smith, M. J. Curtis and W. J. Zeng, "A Practical Quantum Instruction Set Architecture," (2016), 
  arXiv:1608.03355 [quant-ph], https://arxiv.org/abs/1608.03355
```
For a detailed treatment of index notation and the interpretation of gate applications, see
```
R. Smith, "Someone Shouts ``|01000⟩!'' Who is excited?," (2017), 
  arXiv:1711.02086 [quant-ph], https://arxiv.org/abs/1711.02086
```

## 2. Language

### Whitespace and Instructions

A single line of Quil source may contain several Quil instructions, delimited by semicolons.

For example:
```
X 0 ; H 1
X 1
```
is equivalent to
``` 
X 0
H 1
X 1
```

Whitespace such as spaces and tabs are considered insignificant, except at the
beginning of a line. For a line containing several semicolon delimited
instructions, the initial indentation applies to each instruction in the line.

For example:
```
DEFCIRCUIT FOO:
    X 0 ; H 1
```
is equivalent to
```
DEFCIRCUIT FOO:
    X 0
    H 1
```

### Names

```
Name :: /[A-Za-z_]|[A-Za-z_][A-Za-z0-9\-_]*[A-Za-z0-9_]/
```

Names in Quil have the following requirements:
- Only uppercase letters, lowercase letters, and underscores may be used for
any part of the name
- The digits 0-9 may be used in any position except the first
- The hyphen character may be used in any position except the first and last
- They cannot be any of the built-in instruction names

Valid examples: `CNOT`, `X_half`, `CPHASE-0`

Invalid examples: `C*NOT`, `-GATE-`, `_GATE`, `01rotation`, `MEASURE`

### Integers

```
Natural :: /\d+/
```

A non-negative integer literal.

### Strings

```
String :: /\"([^\"]|\\\")*\"/
```

Some instructions (`PRAGMA` and `INCLUDE`) take string literals as arguments.
These are bounded by quotation marks, with support for backslash-escaped
quotation marks within the string literal.

Valid examples: `"foo bar"`, `"baz.quil"`, `"valid \"quote\""`

Invalid examples: `foo`, `"invalid "quote""`

### Comments

```
Comment :: # /[^\n]*/
```

Lines starting with the # character are comments and are ignored. Comments may
also be placed after an instruction and will similarly be ignored.

## 3. Quantum Gates

### Qubits

```
Qubit :: Natural
```

A qubit in Quil is referred to by a positive integer. Interpretation of this
integer is at the discretion of the interpreter of the Quil input. Some
interpreters may require qubits be contiguous, others (such as quantum
processors) may use a numbering scheme based on particular physical qubits.

### Simple Gates

```
SimpleGate :: Name Qubit+
```

Gate applications in Quil are written with the name of the gate preceding a list
of one or more qubits that the gate acts upon.

Examples:
```
H 0
CNOT 0 1
```

### Parametric Gates

```
ParametricGate :: Name ( Expression+ ) Qubit+
```

A parametric gate is function which can take a certain number of parameters to
produce a gate. The application of this gate is written as the gate name
followed by a list of parameters in parenthesis followed by a list of qubits.

Examples:
```
RX(pi/2) 0
CPHASE(pi) 0 1
```

### Gate Modifiers

```
<modified gate> ::= <simple gate>
                  | <parametric gate>
                  | CONTROLLED <modified gate>
                  | DAGGER <modified gate>
                  | FORKED <modified gate>
```

Gates can be modified by one of the modifier keywords `CONTROLLED`, `DAGGER`, or
`FORKED`.

Examples:

```
CONTROLLED Z 0 1 # same as CZ 0 1
CONTROLLED X 0 1 # same as CNOT 0 1
CONTROLLED CONTROLLED X 0 1 2 # same as CCNOT 0 1 2

DAGGER RX(pi/2) 0
FORKED RX(pi/2, pi/4) 0 1

DAGGER FORKED CONTROLLED RZ(0, pi) 0 1 2
```

The meaning of the modifiers is as follows:

#### `CONTROLLED`

The `CONTROLLED` modifier takes some gate G acting on some number of qubits
q1...qn and makes it conditioned on the state of some new qubit c1: if c1 is
high, G is applied to q1, ..., qn; and if c1 is low, no operation is
applied. Therefore, if G is an n-qubit gate

```
G q1 ... qn
```

then `CONTROLLED G` is an (n+1)-qubit gate

```
CONTROLLED G c1 q1 ... qn
```

For example, the gate `CONTROLLED X 1 0` is the familiar controlled not gate,
which can also be written using the standard built-in Quil gate `CNOT 1 0`.

Specifically, when acting on a gate G that can be represented as an N x N matrix
U, `CONTROLLED G` produces a gate G' described by the 2N x 2N matrix C(U) such
that C(U) = I (+) U, where I is the N x N identity matrix and (+) is a direct
sum. For example, if U is the 2 x 2, 1-qubit operator

```
[ a b ]
[ c d ]
```

Then C(U) is

```
[ 1 0 0 0 ]
[ 0 1 0 0 ]
[ 0 0 a b ]
[ 0 0 c d ]
```

#### `DAGGER`

The `DAGGER` modifier represents the adjoint operation or complex-conjugate
transpose. Since every gate is a unitary operator, this is just the inverse. For
example, if G is a gate described by the 1-qubit operator

```
[ a b ]
[ c d ]
```

Then `DAGGER G` is

```
[ a* c* ]
[ b* d* ]
```

where `a*` is the complex-conjugate of `a`.

Because `DAGGER` is an inverse, the sequence of Quil instructions

```
G q1 ... qn
DAGGER G q1 ... qn
```

acts as an identity gate. As another example, consider the gate `PHASE`, which
is defined as

```
DEFGATE PHASE(%alpha):
    1, 0
    0, cis(%alpha)
```

where `cis(x) = cos(x) + i sin(x) = e^{ix}`. Therefore, `PHASE(theta) q` ==
`DAGGER PHASE(-theta) q` for all `theta`.

#### `FORKED`

Let G be a parametric gate of k parameters p1 ... pk and n qubits
q1 ... qn. This is written:

```
G(p1, ..., pk) q1 ... qn
```

Consider a second set of k parameters p1' ... pk'. The `FORKED` modifier takes
such a gate G and allows either set of parameters to be used conditioned on an
additional qubit c.

```
FORKED G(p1, ..., pk, p1', ..., pk') c q1 ... qn
```

Roughly speaking, this is equivalent to the pseudocode:

```
if c = 0:
    G(p1, ..., pk) q1 ... qn
else if c = 1:
    G(p1', ..., pk') q1 ... qn
```

For example, the built-in gate `RX` takes a single `%theta` parameter and acts
on a single qubit, like so `RX(pi/2) 0`. Therefore, `FORKED RX(pi/2, pi/4) 1 0`
produces a "forked" version of `RX`, conditioned on qubit 1. If qubit 1 is in
the zero state, this corresponds to `RX(pi/2) 0` and to `RX(pi/4) 0` if qubit 1
is in the one state.

In general, when acting on a gate G that can be represented as an N x N matrix U
= G(p1,...,pk), `FORKED G` produces a 2N x 2N matrix F(G)(p1,...,p2k) =
G(p1,...,pk) (+) G(pk+1,...,p2k), where (+) is the direct sum. For example, when
k=0 and U is the 2 x 2, 1-qubit operator

```
[ a b ]
[ c d ]
```

Then F(U) is

```
[ a b 0 0 ]
[ c d 0 0 ]
[ 0 0 a b ]
[ 0 0 c d ]
```

Likewise the gate `RZ` is defined as

```
DEFGATE RZ(%theta):
    cis(-%theta/2), 0
    0,              cis(%theta/2)
```

Therefore, `FORKED RZ(x1, x2) 1 0`, for real numbers x1 and x2, results in a
2-qubit operator that can be described by the matrix.

```
[ cis(-x1/2), 0,         0,          0         ]
[ 0,          cis(x1/2), 0,          0         ]
[ 0,          0,         cis(-x2/2), 0         ]
[ 0,          0,         0,          cis(x2/2) ]
```

#### Chaining gate modifiers

When gate modifiers are chained, they consume qubits left-to-right, so that in
the following example, the `CONTROLLED` modifier is conditioned on qubit 0,
`FORKED` on qubit 1, and the gate G acts on qubit 2.

```
CONTROLLED FORKED DAGGER G 0 1 2
    |         |          | ^ ^ ^
    |         |          +-|-|-+
    |         +------------|-+
    +----------------------+
```

Note that chaining multiple `FORKED` modifiers causes the numbers of parameters consumed by the gate to double for each additional `FORKED`. For example:

```
RX(pi) 0
FORKED RX(pi, pi/2) 1 0
FORKED FORKED RX(pi, pi/2, pi/4, pi/8) 2 1 0
```

You can think of that last example as representing the following decision tree, where an edge label like `q2=0` means that qubit 2 is in the zero state.

```
           FORKED FORKED RX(pi, pi/2, pi/4, pi/8) 2 1 0
                   /                               \
                q2=0                              q2=1
                 /                                   \
    FORKED RX(pi, pi/2) 1 0                  FORKED RX(pi/4, pi/8) 1 0
       /              \                         /               \
    q1=0             q1=1                    q1=0              q1=1
     /                  \                     /                   \
RX(pi) 0              RX(pi/2) 0        RX(pi/4) 0              RX(pi/8) 0
```


### Gate Definitions

```
GateDefinition :: DEFGATE Name ( Parameter+ | ( AS GateType ) )? : MatrixRow+
GateType :: 'MATRIX' | 'PERMUTATION'
MatrixRow :: Indent (Expression ,)+
```

Gates can be defined by their complex matrices. The number of qubits that a
gate will act upon is inferred from the size of the matrix. Gates may also be
parameterized by one or more formal parameters.

Examples:
```
DEFGATE HADAMARD:
    1/sqrt(2), 1/sqrt(2)
    1/sqrt(2), -1/sqrt(2)

DEFGATE RX(%theta):
    cos(%theta/2), -i*sin(%theta/2)
    -i*sin(%theta/2), cos(%theta/2)
```

If the matrix can be represented as a permutation, then the gate can
be defined with the compact notation:

```
DEFGATE Name AS PERMUTATION:
    P_0, P_1, ..., P_(N-1)
```

with each `P_i` being a non-negative integer, and `N×N` being the
dimension of the intended matrix representation. See the `CCNOT` example
below. The values P_0 to P_(N-1) indicate how the basis states are 
permuted: The zeroth basis state goes to `P_0`, the first basis state
goes to `P_1`, and so on.

### Standard Gates

The following gates are very commonly used and are therefore understood by Quil
without requiring associated DEFGATE definitions.

```
# Pauli Gates

DEFGATE I:
    1, 0
    0, 1

DEFGATE X:
    0, 1
    1, 0

DEFGATE Y:
    0, -i
    i, 0

DEFGATE Z:
    1, 0
    0, -1


# Hadamard Gate

DEFGATE H:
    1/sqrt(2), 1/sqrt(2)
    1/sqrt(2), -1/sqrt(2)


# Cartesian Rotation Gates

DEFGATE RX(%theta):
    cos(%theta/2),    -i*sin(%theta/2)
    -i*sin(%theta/2), cos(%theta/2)

DEFGATE RY(%theta):
    cos(%theta/2), -sin(%theta/2)
    sin(%theta/2), cos(%theta/2)

DEFGATE RZ(%theta):
    cis(-%theta/2), 0
    0,              cis(%theta/2)


# Controlled-NOT Variants

DEFGATE CNOT:
    1, 0, 0, 0
    0, 1, 0, 0
    0, 0, 0, 1
    0, 0, 1, 0

DEFGATE CCNOT:  # Also known as the Toffoli gate.
    1, 0, 0, 0, 0, 0, 0, 0
    0, 1, 0, 0, 0, 0, 0, 0
    0, 0, 1, 0, 0, 0, 0, 0
    0, 0, 0, 1, 0, 0, 0, 0
    0, 0, 0, 0, 1, 0, 0, 0
    0, 0, 0, 0, 0, 1, 0, 0
    0, 0, 0, 0, 0, 0, 0, 1
    0, 0, 0, 0, 0, 0, 1, 0

# CCNOT equivalent using permutation notation
DEFGATE CCNOT AS PERMUTATION:
    0, 1, 2, 3, 4, 5, 7, 6

# Phase Gates

DEFGATE S:
    1, 0
    0, i

DEFGATE T:
    1, 0
    0, cis(pi/4)

DEFGATE PHASE(%alpha):
    1, 0
    0, cis(%alpha)

DEFGATE CPHASE00(%alpha):
    cis(%alpha), 0, 0, 0
    0,           1, 0, 0
    0,           0, 1, 0
    0,           0, 0, 1

DEFGATE CPHASE01(%alpha):
    1, 0,           0, 0
    0, cis(%alpha), 0, 0
    0, 0,           1, 0
    0, 0,           0, 1

DEFGATE CPHASE10(%alpha):
    1, 0, 0,           0
    0, 1, 0,           0
    0, 0, cis(%alpha), 0
    0, 0, 0,           1

DEFGATE CPHASE(%alpha):
    1, 0, 0, 0
    0, 1, 0, 0
    0, 0, 1, 0
    0, 0, 0, cis(%alpha)

DEFGATE CZ:
    1, 0, 0,  0
    0, 1, 0,  0
    0, 0, 1,  0
    0, 0, 0, -1

# Swap Gates

DEFGATE SWAP:
    1, 0, 0, 0
    0, 0, 1, 0
    0, 1, 0, 0
    0, 0, 0, 1

DEFGATE CSWAP:  # Also known as the Fredkin gate.
    1, 0, 0, 0, 0, 0, 0, 0
    0, 1, 0, 0, 0, 0, 0, 0
    0, 0, 1, 0, 0, 0, 0, 0
    0, 0, 0, 1, 0, 0, 0, 0
    0, 0, 0, 0, 1, 0, 0, 0
    0, 0, 0, 0, 0, 0, 1, 0
    0, 0, 0, 0, 0, 1, 0, 0
    0, 0, 0, 0, 0, 0, 0, 1

DEFGATE ISWAP:
    1, 0, 0, 0
    0, 0, i, 0
    0, i, 0, 0
    0, 0, 0, 1

DEFGATE PSWAP(%theta):
    1, 0,           0,           0
    0, 0,           cis(%theta), 0
    0, cis(%theta), 0,           0
    0, 0,           0,           1
```

## 4. Measurement and Classical Memory

### Classical Memory Declarations

Quil doesn't have a notion of _allocating_ memory, but rather the notion of
_declaring the existence_ of memory. In the following, we introduce the
`DECLARE` directive, which describes available memory for a program to use. _For
a discussion of various design considerations, as well as additional examples,
see see [`typed-memory.md`](../rfcs/typed-memory.md)._

The `DECLARE` directive is used to declare a fixed-length one dimensional array,
henceforth known as a _vector_, of _typed memory_. The vector contains elements
of a fixed _scalar type_. Supported scalar types are: `BIT` which represents one
bit, `OCTET ` which represents 8 bits, `INTEGER` which represents a
machine-sized signed integer, and `REAL` which represents a machine-sized real
number.

```
ScalarType :: BIT | OCTET | INTEGER | REAL
```

**NOTE**: The formats/layouts of these are specific to the machine being run on.
The type `INTEGER` is guaranteed to be large enough to hold a valid length of
octets, and is guaranteed to hold at least the values `-127` to `128`.

A fixed-length vector type, relative to a scalar type, is denoted by the scalar
type name followed by an integer in brackets. For instance, `REAL[5]` is a type
that represents five real numbers in sequence.

```
VectorType :: ScalarType ( \[ Natural \])?
```

There are three variants of `DECLARE`: plain declaration, aliased declaration,
and aliased declaration with offset.

```
MemoryDeclaration :: PlainDeclaration | AliasedDeclaration | AliasedDeclarationWithOffset
```

#### Plain Declaration

```
PlainDeclaration :: DECLARE Name VectorType
```

`DECLARE <name> <type>` declares that `<name>` designates memory of the
associated type `<type>`. If this is a scalar type, then it is assumed to
designate a vector of length 1. That is, the following two lines are equivalent:

```
DECLARE x INTEGER
DECLARE x INTEGER[1]
```

In the program that follows, `x` or equivalently `x[0]` would refer to an
integer quantity.

#### Aliased Declaration

```
AliasedDeclaration :: DECLARE Name VectorType SHARING Name
```

Aliased declarations allow for the designation of memory regions which
correspond to initial segments of other memory regions.

For example, in

```
DECLARE bar OCTET
DECLARE foo BIT[2] SHARING bar
```

`bar` designates a memory region of a single octet, and `foo` designates the
first two bits of `bar`.

In general, the total memory size designated by the first region shall not
exceed the total memory size designated by the second region.

An implementation is free to reject programs where particular instances of
sharing is invalid (e.g., alignment is violated; disparate memories are
unshareable; etc.).

#### Aliased Declaration with Offset

```
AliasedDeclarationWithOffset :: DECLARE Name VectorType SHARING Name OFFSET ( Integer VectorType )+
```

With offsets, an aliased declaration may declare a memory region that coincides
with an intermediate segment of some other memory region.


In the declaration

```
DECLARE <name> <type> SHARING <other-name> OFFSET <integer_1> <offset-type_1> <integer_2> <offset-type_2>
```

`<name>` will point to memory a total of `SUM_i <integer_i> *
sizeof(<offset-type_i>)` octets after the start of `<other-name>`. As with an
aliased declaration, the memory at `<name>` must not overflow the end of
`<other-name>`.

##### Extended Example: Memory Aliasing

A system with a fixed and known memory layout optimized for running QAOA-like
circuits might include the following declarations:

```
DECLARE memory OCTET[131072]                              # 128k global memory
DECLARE qaoa-params REAL[32] SHARING memory               # all QAOA params
DECLARE beta REAL[16] SHARING qaoa-params                 # beta params
DECLARE gamma REAL[16] SHARING qaoa-params OFFSET 16 REAL # gamma params
DECLARE ro BIT[16]                                        # readout registers
```

Here, we have two disjoint memories: the global data memory `memory`, and the
readout memory `ro`. We see that the global data memory `memory` is partitioned
into a section `qaoa-params`, which is further partitioned into regions `beta`
and `gamma`. This allows for convenient memory usage. For example, one may wish
to perform a bulk update of `qaoa-params`, while still allowing subsequent Quil
code to reference `beta` and `gamma` individually.

#### Portability of Aliased Declarations

Aliased declarations with mixed types require an intimate view of the target
architecture. The widths of each data type, which are hitherto unspecified, must
be known. For example, the following declarations may not be valid if the size
of `REAL` exceeds the size of `INTEGER`.

```
DECLARE x INTEGER
DECLARE y REAL SHARING x
```

Even if such a declaration is valid, operations on `y` are not portably
specified. For example, continuing the above,

```
DECLARE b BIT
MOVE x 0
EQ b y 0.0
```

could result in any value for `b`, depending on the implementation.

An implementation shall describe the bit-level description of the types, the
available declarable memories, the limits on the declared memory, alignment
requirements, and limits on sharing and offsets. Implementations may enforce
alignment by way of erroring if the stated declaration is invalid.
Implementations must _not_ round up or down to alignment boundaries.

### Dereferencing Memory

```
ClassicalMem :: Name ( \[ Natural \])?
```

Memory is dereferenced in a Quil program using common array dereferencing
syntax. In particular, given a name `x` pointing to memory of type `T`, and a
non-negative integer offset `n`, the syntax `x[n]` refers to the `n`th element
of type `T`, relative to `x[0]`.

If and only if `x` was declared with just a single element, then `x` may be
referred to simply by its name with no bracket. In this case, `x` and `x[0]`
would be equivalent.

Dereferencing with indirection, e.g., `x[y[3]]`, is supported through the `LOAD`
and `STORE` instructions. For example,

```
DECLARE x INTEGER[16]
DECLARE y INTEGER[16]
DECLARE z INTEGER[16]
DECLARE t INTEGER
LOAD t y z[3]          # t := y[z[3]]
LOAD t x t             # t := x[t]
```

### Measurement

```
Measurement :: MEASURE Qubit ClassicalMem
```

Measurement is performed by specifying a qubit to measure followed by the
classical memory address in which to place the result.

Example of measuring two qubits:
```
DECLARE ro BIT[2]
MEASURE 0 ro[0]
MEASURE 1 ro[1]
```

## 5. Other Quantum Operations

The following operations allow for some or all of the quantum state to be
brought to a known reference value.

### Qubit reset

```
RESET q
```
is semantically equivalent to
```
DECLARE ro BIT
MEASURE q ro
JUMP-WHEN @end-reset ro
X q
LABEL @end-reset
```
which brings qubit `q` to the zero state.  This is sometimes called _active reset_.

Note: The resulting quantum system is generally described by a mixed state. For
example, supposing that we have prepared the Bell state `(|00⟩ + |11⟩)/sqrt(2)`,
the effect of resetting qubit 0 is to put the system into either state `|00⟩` or
`|10⟩`, each with probability 1/2.

### State reset

```
RESET
```
brings the full quantum system to the zero state. This is semantically equivalent to 
sequentially resetting all qubits (e.g. `RESET 0 ; RESET 1 ; ...`).

## 6. Classical Operations and Control Flow

TODO

_See [`typed-memory.md`](../rfcs/typed-memory.md) for classical operations._

```
LABEL <label>
JUMP <label>
JUMP-WHEN <label> <bit-mem>
JUMP-UNLESS <label> <bit-mem>
HALT
WAIT
```

### Labels

```
Label :: @Name
```

Locations within the instruction sequence are denoted by labels, which are names
that are prepended with an `@` symbol, like `@START`. Labels are used as targets
in JUMP-like instructions, and are written with the `LABEL` directive.

Examples:

```
LABEL @start
LABEL @MY-LABEL
```

## 7. Language Features

The Quil language provides for several additional directives which do not
directly express classical or quantum operations.

### File Inclusion

```
INCLUDE String
```

Include a Quil file, whose filename is written as a string literal. 

Quil programs may span several source files. A Quil program with an `INCLUDE
"foo.quil"` directive has the same meaning as if the body of the file `foo.quil`
was substituted in at the position of this line.

Included files may themselves feature `INCLUDE` directives. The meaning then is
as if these were themselves recursively included, assuming that this process
terminates in a finite number of steps. If this recursive process would not
terminate in a finite number of steps (for example, if `foo.quil` includes
`bar.quil` and `bar.quil` includes `foo.quil`), the meaning of the program is
undefined.

### Pragmas

```
PRAGMA Name (Name|Natural)* String?
```

Programs which process Quil may benefit from additional information or metadata
provided by the programmer. The `PRAGMA` directive represents one mechanism for
associating such information with a program.

In common usage, the first `Name` token denotes the kind or type of the `PRAGMA`
directive and the remaining tokens serve as a data payload. 

For example, the `quilc` compiler allows programmers to signal that a sequence
of instructions should not be modified during optimization passes by surrounding
them with a pair of `PRESERVE_BLOCK` and `END_PRESERVE_BLOCK` pragmas:

```
PRAGMA PRESERVE_BLOCK
RX(-pi/2) 0
CZ 1 0
RX(pi) 3
PRAGMA END_PRESERVE_BLOCK
```

The set of valid `PRAGMA` directives, and their associated semantics, is
application specific, and otherwise unspecified by the Quil language.

## 8. Circuits

### Circuit Definitions

```
CircuitDefinition :: DEFCIRCUIT Name ( Parameter+ )? CircuitQubit+ : CircuitRow+
CircuitQubit :: Qubit | Name
CircuitRow :: Indent Instruction
```

Sometimes it is convenient to name and parameterize a particular sequence of
Quil instructions for use as a subroutine to other quantum programs. This can be
done with the `DEFCIRCUIT` directive. Similar to the `DEFGATE` directive,
`DEFCIRCUIT` can optionally specify a list of parameters. Additionally,
`DEFCIRCUIT` directives may specify a list of formal arguments which can be
substituted with either classical addresses or qubits.

Examples:
```
DEFCIRCUIT SIMPLE:
    X 0
    X 1

DEFCIRCUIT BELL_STATE q0 q1:
    H q0
    CNOT q0 q1

DEFCIRCUIT LOOP temp:
    LABEL @START
    RESET 0
    RESET 1
    BELL_STATE 0 1
    MEASURE 1 temp
    JUMP-WHEN @START temp
    HALT

DEFCIRCUIT ROT(%theta) q:
    RX(%theta) q
```

### Simple Circuits

```
SimpleCircuit :: Name Qubit*
```

Circuit applications may be written with the name of the circuit preceding a
list of zero or more qubits that the circuit acts upon.

Examples:
```
DEFCIRCUIT MY-RESET:
    RESET 0
    RESET 1

DEFCIRCUIT BELL_STATE q0 q1:
    H q0
    CNOT q0 q1

MY-RESET
BELL_STATE 0 1
```

### Parametric Circuits

```
ParametricCircuit :: Name ( Expression+ ) Qubit*
```

A parametric circuit can take a certain number of parameters in addition to any
formal arguments. The application of this circuit is written as the circuit name
followed by a list of parameters in parenthesis followed by a list of
zero-or-more qubits.

Examples:
```
DEFCIRCUIT MY-PARAMETRIC-CIRCUIT(%theta, %phi) q1 q2:
    H q1
    RX(%theta) q1
    RY(%phi) q2

MY-PARAMETRIC-CIRCUIT(pi/2, pi/4) 1 0
```

### Circuit Modifiers

```
<modified circuit> := <simple circuit>
                    | <parametric circuit>
                    | DAGGER <modified circuit>
```

The `DAGGER` modifier can also be applied to simple or parametric circuits, so
long as the circuit in question is comprised entirely of gate applications or
other daggerable circuit applications, recursively. No classical or control-flow
instructions are allowed to appear in the body of the daggered circuit.

The operation of `DAGGER` on a circuit effectively reverses the order of
instructions that appear in the circuit body and applies `DAGGER` to each of
them individually.

For example,

```
DEFCIRCUIT H1:
    H 1

DEFCIRCUIT GATES-ONLY:
    H 0
    H1
    CCNOT 0 1 2

DAGGER GATES-ONLY
```

is permissible and is equivalent to the following program:

```
DAGGER CCNOT 0 1 2
DAGGER H 1
DAGGER H 0
```

Examples:
```
DEFCIRCUIT BELL_STATE q0 q1:
    H q0
    CNOT q0 q1

DEFCIRCUIT DOUBLE_BELL q0 q1 q2 q3:
    BELL_STATE q0 q1
    BELL_STATE q2 q3

DEFCIRCUIT CANNOT-DAGGER:
    RESET 0
    MEASURE 0

DAGGER BELL_STATE 0 1      # ok, only gate applications
DAGGER DOUBLE_BELL 0 1 2 3 # also ok
DAGGER CANNOT-DAGGER       # error
```
