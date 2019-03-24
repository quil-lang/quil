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

## 6. Pulse Level Control

**Frames**

```
Frame :: String
```

A frame encapsulates any rotating frame relative to which control/readout
waveforms may be defined. Frames are defined by simple strings.

There are no built-in frames, they are dependent on the architecture.

Examples:
```
"xy"  # eg. for the drive line
"cz"  # eg. for a flux pulse for enacting CZ gate
"iswap"
"ro"  # eg. for the readout pulse
"out" # eg. for the capture line
```

**Waveforms**

```
Waveform :: Name
Waveform :: flat ( duration: Expression, iq: Expression )
Waveform :: gaussian ( duration: Expression, fwhm: Expression, t0: Expression )
Waveform :: draggaussian ( duration: Expression, fwhm: Expression, t0: Expression,
    anh: Expression, alpha: Expression )
Waveform :: erfsquare ( duration: Expression, risetime: Expression,
    padleft: Expression, padright: Expression )
```

Waveforms are referenced either by name or by a built-in waveform generator.

The built-in waveform generators are:
- `flat(duration, iq)` creates a flat waveform where:
    - `duration` is a rational number representing the duration of the
      waveform in seconds
    - `iq` is a complex number representing the IQ value to play for the
      duration of the waveform
- `gaussian(duration, fwhm, t0)` creates a Gaussian waveform where:
    - `duration` is a rational number representing the duration of the
      waveform in seconds
    - `fwhm` is a rational number representing the full-width-half-max of
      the waveform in seconds
    - `t0` is a rational number representing the center time coordinate of
      the waveform in seconds
- `draggaussian(duration, fwhm, t0, anh, alpha)` creates a DRAG gaussian pulse where:
    - `duration` is a rational number representing the duration of the
      waveform in seconds
    - `fwhm` is a rational number representing the full-width-half-max of
      the waveform in seconds
    - `t0` is a rational number representing the center time coordinate of
      the waveform in seconds
    - `anh` is a rational number representing the anharmonicity of the qubit in
      Hertz
    - `alpha` is a rational number for the dimensionless drag parameter
- `erfsquare(duration, risetime, padleft, padright)` creates a pulse with a flat
    top and edges that are error functions (erfs) where:
    - `duration` is a rational number representing the duration of the
      waveform in seconds
    - `risetime` is a rational number representing the rise and fall sections of
      the pulse in seconds
    - `padleft` is a rational number representing the amount of zero-amplitude
      padding to add to the left of the pulse
    - `padright` is a rational number representing the amount of zero-amplitude
      padding to add to the right of the pulse

**Defining new waveforms**

```
WaveformDefinition :: DEFWAVEFORM Name ( Parameter+ ) : MatrixRow
MatrixRow :: Indent (Expression ,)+
```

New waveforms may be defined by listing out all the IQ values as complex
numbers, separated by commas. Waveform definitions may also be parameterized,
although note that Quil has no support for vector level operations.

Example:
```
DEFWAVEFORM my_custom_waveform:
    1+2i, 3+4i, 5+6i

DEFWAVEFORM my_custom_paramterized_waveform(%a)
    (1+2i)*%a, (3+4i)*%a, (5+6i)*%a
```

**Pulses**

```
Pulse :: PULSE Qubit+ Frame Waveform
```

Pulses can be played on the frame of a particular qubit by listing the qubit,
frame name, waveform name (or generator).

Examples:
```
# Simple pulse with previously defined waveform
PULSE 0 "xy" my_custom_waveform

# Pulse with previously defined parameterized waveform
PULSE 0 "xy" my_custom_parameterized_waveform(0.5)

# Pulse with built-in waveform generator
PULSE 0 "xy" flat(duration: 1e-6, iq: 2+3i)

# Pulse on a flux line
PULSE 0 1 "cz" flat(duration: 1e-6, iq: 2+3i)
```

**Frequency**

```
SetFrequency :: SET-FREQUENCY Qubit Frame Float
ShiftFrequency :: SHIFT-FREQUENCY Qubit Frame Float
```

Each frame has a frequency which is tracked throughout the program. Initially
the frequency starts out as not defined. It may be set or shifted up and down.

Frequency must be a positive real number.

```
SET-FREQUENCY 0 "xy" 5.4e9
SET-FREQUENCY 0 "ro" 6.1e9

SHIFT-FREQUENCY 0 "ro" 100e6
SHIFT-FREQUENCY 0 "ro" -100e6
```

**Phase**

```
SetPhase :: SET-PHASE Qubit Frame Float
ShiftPhase :: SHIFT-PHASE Qubit Frame Expression
```

Each frame has a phase which is tracked throughout the program. Initially the
phase starts out as 0. It may be set or shifted up and down.

The phase must be a rational real number. There is also support for
shifted the phase based on some expression, as long as that expression returns
a real number.

Example:
```
SET-PHASE 0 "xy" pi/2

SHIFT-PHASE 0 "xy" -pi
SHIFT-PHASE 0 "xy" %theta*2/pi
```

**Scale**

```
SetScale :: SET-SCALE Qubit Frame Float
ShiftScale :: SHIFT-SCALE Qubit Frame Float
```

Each frame has a scale which is tracked throughout the program. Initially the
scale starts out as 1. It may be set or shifted up and down.

Example:
```
SET-SCALE 0 "xy" 0.75

SHIFT-SCALE 0 "xy" 0.1
SHIFT-SCALE 0 "xy" -0.1 # is valid
SHIFT-SCALE 0 "xy" -0.8 # would put scale in invalid (-0.05) state
```

**Capture**

```
Capture :: CAPTURE Qubit Frame Waveform MemoryReference
```

The capture instruction opens up the readout on a qubit and measures its state.
An integration waveform will be applied to the raw IQ points and the result is
placed in classical memory.

The waveform will define the length of the capture. The memory reference must be
able to store a complex number.

Example:
```
# Simple capture of an IQ point
DECLARE iq REAL[2]
CAPTURE 0 "ro" flat(1e-6, 2+3i) iq
```

**Defining Calibrations**

```
CalibrationDefinition :: DEFCAL Name ( Parameter+ ) Qubit+ : Instruction+
MeasureCalibrationDefinition :: DEFCAL Name Qubit Parameter : Instruction+
```

Calibrations for high-level gates can be defined by mapping a combination of
(gate name, parameters, qubits) to a sequence of analog control instructions.

Calibrations with the same gate name as a built-in gate definition or custom
gate definition are assumed to be the same.

Multiple calibration definitions can be defined for different parameter and
qubit values. When a gate is translated into control instructions the
calibration definitions are enumerated in reverse order of definition and the
first match will be taken.

For example, given the following list of calibration definitions in this order:
1. `DEFCAL RX(%theta) %qubit:`
2. `DEFCAL RX(%theta) 0:`
3. `DEFCAL RX(pi/2) 0:`
The instruction `RX(pi/2) 0` would match (3), the instruction `RX(pi) 0` would
match (2), and the instruction `RX(pi/2) 1` would match (1).

The same system applies for `MEASURE` although `MEASURE` cannot be
parameterized, it takes only a single qubit as input, and it has an additional
parameter for the memory reference in which to read out the result.

Examples:
```
# Simple non-parameterized gate on qubit 0
DEFCAL X 0:
    PULSE 0 "xy" gaussian(duration: 1, fwhm: 2, t0: 3)

# Parameterized gate on qubit 0
DEFCAL RX(%theta) 0:
    PULSE 0 "xy" flat(duration: 1e-6, iq: 2+3i)*%theta/(2*pi)

# Applying RZ to any qubit
DEFCAL RZ(%theta) %qubit:
    SHIFT-PHASE %qubit "xy" %theta

# Measurement and classification
DEFCAL MEASURE 0 %dest:
    DECLARE iq REAL[2]
    CAPTURE 0 "out" flat(1e-6, 2+3i) iq
    LT %dest iq[0] 0.5 # thresholding
```

**Timing Control**

```
Delay :: DELAY Qubit Expression
Fence :: FENCE Qubit+
```

Delay allows for the insertion of a gap within a list of pulses or gates with
a specified duration in seconds.

Fence ensures that all operations on the specified qubits that proceed the
fence statement happen after the end of the right-most operation of that set
of qubits.

Examples:
```
X 0
FENCE 0 1
X 1 # This X gate will be applied to qubit 1 AFTER the X gate on qubit 0

# Simple T1 experiment
X 0
DELAY 0 100e-6
MEASURE 0 ro[0]
```

## 7. Language Features

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
