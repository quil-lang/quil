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

**Instructions**

Instructions in Quil are written one per line, separated by a newline character.
Whitespace such as spaces and tabs are considered insignificant, except at the
beginning of a line.

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
also be placed after an instruction line and will similarly be ignored.

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

Gate applications in Quil are written one per line with the name of the gate
preceding a list of one or more qubits that the gate acts upon.

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

TODO

```
<modified gate> ::= <simple gate>
                  | <parametric gate>
                  | CONTROLLED <modified gate>
                  | DAGGER <modified gate>
```

**Gate Definitions**

```
GateDefinition :: DEFGATE Name ( Parameter+ ) : MatrixRow+
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
JUMP <label>
JUMP-WHEN <label> <bit-mem>
JUMP-UNLESS <label> <bit-mem>
HALT
WAIT
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
