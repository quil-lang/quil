# Quil

*Quil 2.0 released in September, 2018*

**Introduction**

This is the specification for Quil, a practical quantum instruction set
architecture released by Rigetti Computing.

Quil is an instruction-based language for representing quantum computations
with classical feedback and control. It can be written directly for the purpose
of quantum programming, used as an intermediate format within classical
programs, or used as a compilation target for quantum programming languages.

**Copyright notice**

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

## 2. Language

**Whitespace and Instructions**

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

**Names**

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

**Comments**

```
Comment :: # /[^\n]*/
```

Lines starting with the # character are comments and are ignored. Comments may
also be placed after an instruction and will similarly be ignored.

## 3. Quantum Gates

**Qubits**

```
Qubit :: /0|[1-9][0-9]*/
```

A qubit in Quil is referred to by a positive integer. Interpretation of this
integer is at the discretion of the interpreter of the Quil input. Some
interpreters may require qubits be contiguous, others (such as quantum
processors) may use a numbering scheme based on particular physical qubits.

**Simple Gates**

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

**Parametric Gates**

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

**Gate Modifiers**

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

**`CONTROLLED`**

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

**`DAGGER`**

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

**`FORKED`**

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

**Chaining gate modifiers**

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


**Gate Definitions**

```
GateDefinition :: DEFGATE Name ( Parameter+ )? : MatrixRow+
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

**Standard Gates**

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

**Qubit and State Reset**

TODO

State reset
```
RESET
```

Qubit reset
```
RESET q
```

## 4. Measurement and Classical Memory

**Classical Memory Declarations**

TODO

_See [`typed-memory.md`](typed-memory.md)._

**Measurement**

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

## 5. Classical Operations and Control Flow

TODO

_See [`typed-memory.md`](typed-memory.md) for classical operations._

```
LABEL <label>
JUMP <label>
JUMP-WHEN <label> <bit-mem>
JUMP-UNLESS <label> <bit-mem>
HALT
WAIT
```

**Labels**

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

## 6. Language Features

**File Inclusion**

TODO

```
INCLUDE <filename>
```

**Pragmas**

TODO

```
PRAGMA <word> <word>* "string"?
```

## 7. Circuits

**Circuit Definitions**

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

**Simple Circuits**

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

**Parametric Circuits**

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

**Circuit Modifiers**

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
