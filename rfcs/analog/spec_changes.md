Add section 6 to spec:

## 6. Pulse Level Control

### Frames

```
FrameName :: String
Frame :: Qubit+ FrameName
```

A frame encapsulates any rotating frame relative to which control/readout
waveforms may be defined. For the purposes of scheduling and execution on
possibly heterogeneous hardware, frames are specified with respect to a specific
list of qubits. Thus, `0 1 "cz"` is the "cz" frame on qubits 0 and 1. The order
of the qubits matters. In particular, the above frame may differ from `1 0
"cz"`.

#### DEFFRAME

Frames represent basic physical resources manipulated by Quilt
program, and in any implementation will involve a certain amount of
coupling with the underlying control hardware. As such, Quilt itself
has no built-in frames. Native or canonical frame definitions may be
provided by a hardware vendor, and are exposed to Quilt programs via
the `DEFFRAME` directive.

```
DefFrame :: DEFFRAME Frame (: FrameSpec+ )?
FrameSpec :: Indent FrameAttr : ( Expression | String )
FrameAttr :: Identifier
```

All frames used in a program must have a corresponding top-level
definition. Some examples of Rigetti's canonical frames are listed
below, but this is subject to change.

Examples (names only):
```
"xy"  # eg. for the drive line
"ff"  # eg. for a generic flux line
"cz"  # eg. for a flux pulse for enacting CZ gate
"iswap"
"ro"  # eg. for the readout pulse
"out" # eg. for the capture line
```

Relevant characteristics of a particular frame are indicated in the
body of a `DEFFRAME` by way of frame attributes. Certain of these
attributes are standardized, whereas others are hardware or vendor
specific. The specific set of required and optional frame attributes
is vendor specific.

Here is an example of a full frame definition:

```
DEFFRAME 0 1 "cz":
    DIRECTION: "tx"
    INITIAL-FREQUENCY: 220487409.16137844
    CENTER-FREQUENCY: 375000000.0
    HARDWARE-OBJECT: "q0_ff"
    SAMPLE-RATE: 1000000000.0
```


##### Standard Frame Attributes

All frames have an associated frequency and sample rate. Additionally, operations on frames must respect a certain sort of type safety: namely, certain frames can have `PULSE` applied, others can have `CAPTURE` applied, and the two are assumed to be exclusive.

- `SAMPLE-RATE` is a floating point number indicating the rate (in Hz) of the digital-to-analog converter on the control hardware associated with this frame.
- `INITIAL-FREQUENCY` is a floating point number indicating the initial frame frequency.
- `DIRECTION` is one of `"tx"` or `"rx"`, and indicates whether the frame is available for pulse operations (`"tx"`) or capture operations (`"rx"`).


##### Rigetti Native Frame Attributes

Frame attributes represent quantities associated with a given frame which need not be specified by the programmer, but which are ultimately required to fully link and execute a Quilt program on a physical device.

- `HARDWARE-OBJECT` is a string indicating the (implementation-specific) hardware object that the frame is associated with, used for program linkage.
- `CENTER-FREQUENCY` is an optional attribute, consisting of a floating point value indicating the frame frequency which should be considered the "center" for the purposes digital-to-analog or analog-to-digital conversion.

### Waveforms

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
    top and edges that are error functions (erf) where:
    - `duration` is a rational number representing the duration of the
      waveform in seconds
    - `risetime` is a rational number representing the rise and fall sections of
      the pulse in seconds
    - `padleft` is a rational number representing the amount of zero-amplitude
      padding to add to the left of the pulse
    - `padright` is a rational number representing the amount of zero-amplitude
      padding to add to the right of the pulse

#### Defining new waveforms

```
SampleRate :: Float
WaveformDefinition :: DEFWAVEFORM Name ( Parameter+ ) : MatrixRow
MatrixRow :: Indent (Expression ,)+
```

New waveforms may be defined by by listing out all the IQ values as
complex numbers, separated by commas. Waveform definitions may also be
parameterized, although note that Quil has no support for vector level
operations.

Example:
```
DEFWAVEFORM my_custom_waveform:
    1+2i, 3+4i, 5+6i

DEFWAVEFORM my_custom_parameterized_waveform(%a):
    (1+2i)*%a, (3+4i)*%a, (5+6i)*%a
```

The duration (in seconds) of a custom waveform applied on a particular
frame may be computed by dividing the number of samples in the
waveform by the sample rate of the frame. In the above example, both
waveforms have a duration of 0.5 seconds.

### Pulses

```
Pulse :: PULSE Frame Waveform
```

Pulses represent the propagation of a specific waveform (either built-in or custom) on a specific frame.

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

Each frame has a fixed, hardware-specific sample rate. The behavior of a `PULSE`
instruction with a custom waveform whose sample rate does not match the
corresponding frame's sample rate is undefined.

### Frame Mutations

#### Frequency

```
SetFrequency :: SET-FREQUENCY Frame Expression
ShiftFrequency :: SHIFT-FREQUENCY Frame Expression
```

Each frame has a frequency which is tracked throughout the program. Initial
frame frequencies are specified in the frame definition's `INITIAL-FREQUENCY`
attribute. Subsequent code may update this, either assigning an absolute value (`SET-FREQUENCY`) or a relative offset (`SHIFT-FREQUENCY`).


```
SET-FREQUENCY 0 "xy" 5.4e9
SHIFT-FREQUENCY 0 "ro" 6.1e9
```

#### Phase

```
SetPhase :: SET-PHASE Frame Expression
ShiftPhase :: SHIFT-PHASE Frame Expression
SwapPhases :: SWAP-PHASES Frame Frame
```

Each frame has a phase which is tracked throughout the program. Initially the
phase starts out as 0. It may be set or shifted up and down, as well as swapped
with other frames.

The phase must be a rational real number. There is also support for
shifted the phase based on some expression, as long as that expression returns
a real number.

Example:
```
SET-PHASE 0 "xy" pi/2

SHIFT-PHASE 0 "xy" -pi
SHIFT-PHASE 0 "xy" %theta*2/pi

SWAP-PHASE 0 "xy" 1 "xy"
```

#### Scale

```
SetScale :: SET-SCALE Frame Expression
```

Each frame has a scale which is tracked throughout the program. Initially the
scale starts out as 1.

Example:
```
SET-SCALE 0 "xy" 0.75
```

### Capture

```
Capture :: CAPTURE Frame Waveform MemoryReference
RawCapture :: RAW-CAPTURE Frame Expression MemoryReference
```

The capture instruction opens up the readout on a frame and measures its state.
An integration waveform will be applied to the raw IQ points and the result is
placed in classical memory.

The waveform will define the duration of the capture. The memory reference must
be able to store a complex number for each qubit in the frame.

In the case of a raw capture the waveform is replaced with a rational number
representing the duration of the capture.

Example:
```
# Simple capture of an IQ point
DECLARE iq REAL[2]
CAPTURE 0 "out" flat(1e-6, 2+3i) iq

# Raw capture
DECLARE iqs REAL[400] # length needs to be determined based on the sample rate of the `0 "out"` frame
RAW-CAPTURE 0 "out" 200e-6 iqs
```

**Defining Calibrations**

### Defining Calibrations

```
GateModifier :: CONTROLLED | DAGGER | FORKED
CalibrationDefinition :: DEFCAL OpModifier* Name ( Parameter+ ) Qubit+ : Instruction+
MeasureCalibrationDefinition :: DEFCAL Name Qubit? Parameter : Instruction+
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

The same system applies for `MEASURE`. Although `MEASURE` cannot be
parameterized, it takes only a single qubit as input, and it has an additional
(optional) parameter for the memory reference into which to store the result.

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

Quil supports arbitrarily chained gate modifiers. As such, calibration
definitions may also incorporate gate modifiers, with the convention that a
calibration definition matches a gate application only if the modifiers match
exactly. Thus in

```
DEFCAL T 0:
    ... 
    
DEFCAL DAGGER T 0:
    ...
```

the first calibration definition matches `T 0`, the second matches `DAGGER T 0`,
and neither match `DAGGER DAGGER T 0`.


### Timing and Synchronization

```
Delay :: DELAY Qubit+ FrameName* Expression
Fence :: FENCE Qubit*
```

Delay allows for the insertion of a gap within a list of pulses or gates with
a specified duration in seconds.

If frame names are specified, then the delay instruction affects those frames on
those qubits. If no frame names are specified, all frames on precisely those
qubits are affected. **Note:** this excludes frames which _intersect_ the
specified qubits but involve others. For example, `DELAY 0 1.0` delays one qubit
frames on `0`, such as `0 "xy"`, but leaves other frames, such as `0 1 "cz"`,
unaffected.

Fence ensures that all operations involving the specified qubits that follow the
fence statement happen after all operations involving the specified qubits that
precede the fence statement. If no qubits are specified, the `FENCE` operation
implicitly applies to all qubits on the device.

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
