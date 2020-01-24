# Analog Control RFC

## Introduction

Quil enables users to specify high-level, gate-based, timing-agnostic quantum
programs. Only a subset of experiments can be specified this way (albeit a
large subset), others require lower level control.

In particular there is a desire to:
- be able to define custom waveforms
- have full control over pulse timing and length
- be able to introduce more sophisticated translation for ideas eg. dynamic
decoupling, crosstalk correction, gate decompositions, etc.
- define new gates (e.g. Toffoli and Fredkin) by composing pulses on frames
and/or that exploit levels beyond the two level qubit approximation
- remove channels where discrepancies between internal and external performance
can be introduced

This RFC proposes adding analog control to Quil which will be accessible
through Quil language bindings and used by compilers and simulators.

## Language Proposal

See the diff on Quil.md for the syntax of the introduction of a number of new
Quil instruction types:
- DEFCAL
- DEFFRAME, DEFWAVEFORM
- DELAY
- FENCE
- PULSE
- CAPTURE, RAW-CAPTURE
- SET-SCALE
- SET-FREQUENCY, SHIFT-FREQUENCY
- SET-PHASE, SHIFT-PHASE, SWAP-PHASES

### Frames and Waveforms

Each qubit can have multiple frames, denoted by string names such as "xy", "cz",
or "ro". A frame is an abstraction that captures the instantaneous frequency and
phase that will be mixed into the control signal. The frame frequencies are with
respect to the absolute "lab frame".

Quilt has two notions of _waveforms_. Custom waveforms are defined using
DEFWAVEFORM as a list of complex numbers which represent the desired waveform
envelope, along with a sample rate. Each complex number represents one sample of
the waveform. The exact time to play a waveform can be determined by dividing by
the _sample rate_, which is in units of samples per second.

**NOTE**: Quilt frames also have an associated sample rate, which may be
specified in the corresponding `DEFFRAME` block, and are ultimately
determined/enforced at link time by the underlying control hardware which the
frame is associated to. If a custom waveform is applied (via `PULSE` or
`CAPTURE`) to a frame for which it has an incompatible sample rate, the behavior
is undefined.

There are also some built-in waveform generators which take as a parameter the
duration of the waveform in seconds, alleviating the need to know the sample
rate to calculate duration. These are valid for use regardless of the frame's
underlying sample rate.

In order to materialize the precise waveforms to be played the waveform
envelopes must be modulated by the frame's frequency, in addition to applying
some scaling and phasing factors. Although in theory it would be mostly possible
to simply define new waveforms that did the modulation, scaling, and phasing
manually, this is both tedious and doesn't take advantage of hardware which has
specialized support for tracking these things.

Therefore, each frame has associated with it a triple (frequency, phase, scale)
that can be modified throughout the program using SET-* instructions (and
additional instructions for phase).

Here's a table explaining the differences between these three values that are
tracked through the program:

| Name      | Initial Value | Valid Values          | Can be parameterized? |
|-----------|---------------|-----------------------|-----------------------|
| Frequency | (not set)     | Real numbers          | No                    |
| Phase     | 0.0           | Real numbers          | Yes                   |
| Scale     | 1.0           | Real numbers          | No                    |


### Pulses

Now that frequency, phase, and scale on a frame have been established we can
play pulses. Pulses can be played by using the PULSE instruction and
specifying both the qubit frame as well as the waveform.

Given a waveform `my_custom_waveform` and the following program:
```
SET-FREQUENCY 0 "xy" 5400e6
SET-PHASE 0 "xy" pi/2
SET-SCALE 0 "xy" 1/2
PULSE 0 "xy" my_custom_waveform
```
A compiler would have several options depending on the hardware backend. It
could create a new waveform (eg. `my_custom_waveform_2`) and apply the
(frequency, phase, scale) to it. Or it could take advantage of built-in hardware
instructions to apply those values internally. This would be the responsibility
of the compiler to make a trade-off between number of instructions and number of
waveforms, given some hardware constraints.

### Readout

To readout a qubit the capture instruction is used. It takes a qubit frame, a
waveform, and a classical memory reference. In this case the waveform is used
as an integration kernel. The inner product of the integration kernel and the
list of measured IQ values is evaluated to produce a single complex result.

This complex number needs to be stored in Quil classical memory. Quil does not
currently support complex numbers, so a real array of length 2 is used instead:
```
# Simple capture of an IQ point
DECLARE iq REAL[2]
CAPTURE 0 "ro" flat(duration: 1e-6, iq: 2+3i) iq
```

### Timing

Analog control instructions extend the definition of a quantum abstract machine
to introduce the concept of time. In this new interpretation each instruction in
Quil has an associated time to execute (which may be effectively zero for
certain operations). It is up to the interpreter to provide semantics for how
pulses are scheduled, as long as certain consistency requirements are met.
Roughly speaking:
1. "Events" on a frame happen at a well defined time since eg. updating a
   frame frequency means that it starts to accumulate phase at a new rate.
2. Events happen in the order listed in the program.
3. Pulses on a common frame may not overlap in time.
4. Pulses on distinct frames which involve a common resource may not overlap in
   time unless one is marked as `NONBLOCKING`.
   
A more precise specification of the timing semantics is provided in
[scheduling.md](./scheduling.md).

#### Pulse Operations

The duration of a pulse operation, i.e. `PULSE`, `CAPTURE`, or `RAW-CAPTURE`, is
the duration of the associated waveform.

Each frame is defined relative to a set of qubits. The execution of a pulse
operation on a frame blocks pulse operations on intersecting frames, i.e. frames
with a qubit in common with the pulse frame.

##### NONBLOCKING

In certain instances it may be desirable to support multiple concurrent pulses
on the same qubit, for example in measurements where `CAPTURE` performs a
readout which may overlap with a transmission `PULSE`. 

A pulse operation (`PULSE`, `CAPTURE`, and `RAW-CAPTURE`) with the `NONBLOCKING`
modifier does not exclude pulse operations on other frames. For example,
in

```
NONBLOCKING PULSE 0 "xy" flat(duration: 1.0, iq: 1.0)
PULSE 0 1 "ff" flat(duration: 1.0, iq: 1.0)
```

the two pulses could be emitted simultaneously. Nonetheless, a `NONBLOCKING`
pulse does still exclude the usage of the pulse frame, so e.g. `NONBLOCKING
PULSE 0 "xy" ... ; PULSE 0 "xy" ...` would require serial execution.

#### Delay

A `DELAY` instruction is equivalent to a `NONBLOCKING` no-operation on all
specified frames. For example, `DELAY 0 "xy" 1.0` delays frame `0 "xy"` by one
second.

If the `DELAY` instruction presents a list of qubits with no frame names, _all
frames on exactly these qubits are delayed_. Thus `DELAY 0 1.0` delays all one
qubit frames on qubit 0, but does not affect `0 1 "cz"`.

#### Fence

The `FENCE` instruction provides a means of synchronization of all frames
involving a set of qubits. In particular, it guarantees that all instructions
involving any of the fenced qubits preceding the `FENCE` are completed before
any instructions involving the fenced qubits which follow the `FENCE`

#### Frame Mutations

Single frame mutations (`SET-FREQUENCY`, `SHIFT-FREQUENCY`, `SET-PHASE`, `SHIFT-PHASE`,
`SET-SCALE`) have a hardware dependent duration (which may be effectively zero).
These operations block pulses on the targeted frame.

The `SWAP-PHASE` instruction introduces an implicit synchronization on the two
involved frames. In other words, any operations involving either of the swapped
frames and preceding the `SWAP-PHASE` must complete prior to the `SWAP-PHASE`
event.

### Calibrations

Calibrations can be associated with gates in Quil to aid the compiler in
converting a list of gates into the corresponding series of pulses.

Calibrations can be parameterized and include concrete values, which are
resolved in "Haskell-style", with later definitions being prioritized over
earlier ones. For example, given the following list of calibration definitions
in this order:
1. `DEFCAL RX(%theta) %qubit:`
2. `DEFCAL RX(%theta) 0:`
3. `DEFCAL RX(pi/2) 0:`
The instruction `RX(pi/2) 0` would match (3), the instruction `RX(pi) 0` would
match (2), and the instruction `RX(pi/2) 1` would match (1).

The body of a DEFCAL is a list of analog control instructions that ideally
enacts the corresponding gate.

## Practical Considerations

Below I present some pseudo-PyQuil to indicate how users would interact with
analog control.

### Today's user

If the user simply wants to run gate-based programs, then the usage would not
change.

```
my_program = ...

qvm_result = qvm.simulate(my_program)

# get_calibrations returns a list of DEFCAL instructions for the qubits
# specified. This would be from the most recent recalibration of the system.
# This would probably be handled behind the scenes in the QuantumComputer but
# the purpose of this example is to show how easy it is to combine calibrations
# with an existing gate-based program.
calibrations = get_calibrations([0, 1, 2], version='most_recent')
full_program = calibrations + my_program

binary = compiler.compile(full_program)
qpu_result = qpu.run(binary)
```

### User doing pulse control

For a user writing their program completely at the level of analog control,
we need to expose APIs for getting frame sample rates as well as qubit and
readout frequencies.

```
sample_rate_rf_0 = get_sample_rate(0, 'rf')
q0_freq = get_qubit_frequency(0)

# Takes an awfully long waveform...
one_second_waveform = np.ones(sample_rate_rf_0)

# Python API TBD
my_program = Program()
my_program += DEFWAVEFORM('my_custom_waveform', one_second_waveform)
my_program += SET_FREQUENCY(0, 'rf', q0_freq)
my_program += PULSE(0, 'rf', 'my_custom_waveform')
""")
```

### User doing mixture of gates and pulse control

A user doing a mixture of gates and pulse control has a number of options:
- if they want custom waveforms then they can get the sample rate, if they just
want built-in waveform shapes then they don't need the sample rate
- if they want to know our guesses for the qubit frequency then they will be
provided, otherwise they can find it themselves
- if they want to use our calibrations they can, or they can modify them, or
produce their own
- they can use gates from the PyQuil default library and this will be translated
to pulses by the compiler, or they can resolve the pulses themselves

## Examples

Here are some example calibrations for various types of gates and measurements.

Setting up frequencies:
```
SET-FREQUENCY 0 "xy" 4678266018.71412
SET-FREQUENCY 1 "xy" 3821271416.79618

SET-FREQUENCY 0 1 "cz" 137293415.829024

SET-FREQUENCY 0 "ro" 5901586914.0625
SET-FREQUENCY 1 "ro" 5721752929.6875

SET-FREQUENCY 0 "out" 5901586914.0625
SET-FREQUENCY 1 "out" 5721752929.6875
```

Calibrations of RX:
```
DEFCAL RX(%theta) 0:
    SET-SCALE %theta/pi*0.936
    PULSE 0 "xy" draggaussian(duration: 80e-9, fwhm: 40e-9, t0: 40e-9, anh: -210e6, alpha: 0)

DEFCAL RX(pi/2) 0:
    SET-SCALE 0.468
    PULSE 0 "xy" draggaussian(duration: 80e-9, fwhm: 40e-9, t0: 40e-9, anh: -210e6, alpha: 0)

# With crosstalk mitigation - no pulses on neighbors
DEFCAL RX(pi/2) 0:
    FENCE 0 1 7
    PULSE 0 "xy" draggaussian(duration: 80e-9, fwhm: 40e-9, t0: 40e-9, anh: -210e6, alpha: 0)
    FENCE 0 1 7
```

RZ:
```
DEFCAL RZ(%theta) %qubit:
    # RZ of +theta corresponds to a frame change of -theta
    SHIFT-PHASE %qubit "xy" -%theta
```

Calibrations of CZ:
```
DEFCAL CZ 0 1:
    PULSE 0 1 "cz" erfsquare(duration: 340e-9, risetime: 20e-9, padleft: 8e-9, padright: 8e-9)
    SHIFT-PHASE 0 "xy" 0.00181362669
    SHIFT-PHASE 1 "xy" 3.44695296672

# With no parallel 2Q gates
DEFCAL CZ 0 1:
    FENCE 0 1 2 3 4 5 6 7 10 11 12 13 14 15 16 17
    PULSE 0 1 "cz" erfsquare(duration: 340e-9, risetime: 20e-9, padleft: 8e-9, padright: 8e-9)
    SHIFT-PHASE 0 "xy" 0.00181362669
    SHIFT-PHASE 1 "xy" 3.44695296672
    FENCE 0 1 2 3 4 5 6 7 10 11 12 13 14 15 16 17
```

Readout:
```
DEFCAL MEASURE 0 %dest:
    DECLARE iq REAL[2]
    PULSE 0 "ro" flat(duration: 1.2e-6, iq: ???)
    CAPTURE 0 "out" flat(duration: 1.2e-6, iq: ???) iq
    LT %dest iq[0] ??? # thresholding
```

Toffoli gate (from Colm):
```
SET-FREQUENCY 12 13 "cz" 283.5e6
SET-FREQUENCY 13 14 "iswap" 181e6

DEFCAL CCNOT 12 13 14:
    # iSWAP_02 on 13-14
    FENCE 12 13 14
    PULSE 13 14 "iswap" erfsquare(tmax: 131e-9, risetime: 20e-9, padleft: 12e-9, pad_right: 13e-9)

    # CZ_20 or 12-13
    FENCE 12 13 14
    PULSE 12 13 "cz" erfsquare(tmax: 332e-9, risetime: 20e-9, padleft: 12e-9, pad_right: 12e-9)

    # iSWAP_02 on 13-14
    FENCE 12 13 14
    SHIFT-PHASE 13 14 "iswap" 0.5 # iSWAP_phase from the original code snippet
    PULSE 13 14 "iswap" erfsquare(tmax: 131e-9, risetime: 20e-9, padleft: 12e-9, pad_right: 13e-9)

    FENCE 12 13 14
```

Active Reset Calibration:
```
DEFCAL RESET %qubit:
    DECLARE ro BIT
    MEASURE %qubit ro[0]
    JUMP-UNLESS ro @delay
    RX(pi) %qubit
    JUMP @end
    LABEL delay
    DELAY %qubit 60e-9
    LABEL end
```

Single point of a parametric gate chevron:
(parameterized in amplitude, frequency, and time)
```
RX(pi) 0
RX(pi) 1
SET-FREQUENCY 0 "cz" 160e6
SET-SCALE 0 "cz" 0.45
PULSE 0 1 "cz" erfsquare(duration: 100e-9, risetime: 20e-9, padleft: 0, padright: 0)
```

## FAQs

**How would this interact with quilc and qvm?**

QVM has a couple options:
- Just ignore any all analog control instructions since they don't change the
state of the quantum abstract machine
- Ignore definitions of calibrations but throw an error on pulses and timing
instructions
- Throw an error on any analog control instructions

The compiler will need to do something more sophisticated. At the level of
linear algebra operations, the compiler can either throw an error on
encountering analog control or it can consider them "anonymous gates" which
can't be moved, permuted, or compressed in any way.

Eventually our compilation chain will need to support taking a high-level Quil
program from gates all the way down to only classical control instructions.

**Sample rates, local oscillators, timing, doesn't this all seem pretty hardware
specific??**

Sure, but I've endeavored to keep these considerations out of the language
itself. The language is only tracking a triple (frequency, phase, scale) and it
is left to whatever system is running/compiling the Quil to combine those values
with details about the specific hardware. Timing is the same way, if a compiler
wants to care about timing (for the purposes of scheduling around decoherence)
then it can, otherwise it can be ignored. Sample rates are only needed when
there are both custom waveforms and the system running/compiling cares about
physical time.

**Why not just open source Rigetti's existing IR for pulse control?**

Our existing IR is difficult to use directly since it is intended to be a
compiler target rather than a target for human beings. In order to accomplish
the goals listed at the top of this proposal there is a good amount of manual
bookkeeping needed. Also information about high-level intentions of the
programmer is lost at that level of detail.

In addition, after using our internal IR for the past year, we've learned about
how to make it better, those ideas are included in this proposal. In particular:
- defining a frequency per frame means that the readout detuning problem can be
solved by the compiler instead of the programmer, a very common source of error
(previously the user had to keep track of the difference between the LO and the
readout frequency and then do some arithmetic to calculate detuning and apply
the correct kernel)
- waveform shapes (flat, gaussian) will allow optimizations and ease of use
that wasn't available at the level of IQ values
- using relative (with delays) instead of absolute time
- exposing small, realtime updates to calibrations that can optionally be
applied

Finally by extending Quil we can take advantage of all the great existing
constructions already built in to the language, rather than re-defining all of
these things again at the IR level. This includes:
- a classical memory model
- control flow
- rich support for expressions and built-in mathematical functions
- file inclusion, pragmas, and circuit definitions
- existing tools such as pyquil, qvm, and quilc
