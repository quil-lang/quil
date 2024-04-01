@section[:title "Annex T: Pulse-Level Control"]

@p{This section is about time-domain extensions to Quil, formally known as @emph{Annex T} of this document, but also known as @emph{Quil-T}.}

@subsection[:title "Frames"]

@syntax[:name "Frame Identifier"]{
    @ms{String}
}

@syntax[:name "Frame"]{
    @rep[:min 0]{@ms{Qubit}} @ms{Frame Identifier}
}

@p{A frame encapsulates any rotating frame relative to which control/readout
waveforms may be defined. For the purposes of scheduling and execution on
possibly heterogenous hardware, frames are specified with respect to a specific
list of qubits. Thus, @c{0 1 "cz"} is the "cz" frame on qubits 0 and 1. The order
of the qubits matters. In particular, the above frame may differ from @c{1 0 "cz"}.}

@subsubsection[:title "DEFFRAME"]

@p{Quil-T itself has no built-in frames. All frames referenced within a program must be defined using the @c{DEFFRAME} directive.}

@syntax[:name "Frame Definition"]{
    DEFFRAME @ms{Frame} @rep[:min 0 :max 1]{@group{: @rep[:min 1]{@ms{Frame Specification}} }}
}

@syntax[:name "Frame Specification"]{
    @ms{Indent} @ms{Identifier} : @group{ @ms{Expression} @alt @ms{String} }
}

@p{All frames used in a program must have a corresponding top-level definition.}


@p{Before execution, a Quil-T program is compiled to target a specific hardware control system,
and frames are mapped to suitable components of that control system. Native or canonical frame definitions may be
provided by a hardware vendor.}


@subsubsubsection[:title "Frame Attributes"]

@p{Frame attributes describe a frame in a way that supports compilation on a particular hardware device. 
These attributes take the form of a mapping with arbitrary string keys. The particular keys and their values
are specific to the hardware vendor; consult their documentation for more information. Whether these may be
modified by the program author or are simply provided for read-only reference depends on the vendor.}


@subsection[:title "Waveforms"]

@syntax[:name "Waveform"]{
     @ms{Identifier}
@alt flat ( duration: @ms{Expression}, iq: @ms{Expression} )
@alt gaussian ( duration: @ms{Expression}, fwhm: @ms{Expression}, t0: @ms{Expression} )
@alt draggaussian ( duration: @ms{Expression}, fwhm: @ms{Expression}, t0: @ms{Expression}, anh: @ms{Expression}, alpha: @ms{Expression} )
@alt erfsquare ( duration: @ms{Expression}, risetime: @ms{Expression}, padleft: @ms{Expression}, padright: @ms{Expression} )
}

@p{Waveforms are referenced either by name or by a built-in waveform generator.}

@p{The built-in waveform generators are:
@itemize{
@item{@c{flat(duration, iq)} creates a flat waveform where:
    @itemize{

    @item{@c{duration} is a rational number representing the duration of the
      waveform in seconds}

    @item{@c{iq} is a complex number representing the IQ value to play for the
      duration of the waveform}
}
}
@item{@c{gaussian(duration, fwhm, t0)} creates a Gaussian waveform where:
@itemize{
    @item{@c{duration} is a rational number representing the duration of the
      waveform in seconds}

    @item{@c{fwhm} is a rational number representing the full-width-half-max of
      the waveform in seconds}

    @item{@c{t0} is a rational number representing the center time coordinate of
      the waveform in seconds}
}
}
@item{@c{draggaussian(duration, fwhm, t0, anh, alpha)} creates a DRAG gaussian pulse where:
@itemize{
    @item{@c{duration} is a rational number representing the duration of the
      waveform in seconds}
    @item{@c{fwhm} is a rational number representing the full-width-half-max of
      the waveform in seconds}
    @item{@c{t0} is a rational number representing the center time coordinate of
      the waveform in seconds}
    @item{@c{anh} is a rational number representing the anharmonicity of the qubit in
      Hertz}
    @item{@c{alpha} is a rational number for the dimensionless drag parameter}
}
}
@item{@c{erfsquare(duration, risetime, padleft, padright)} creates a pulse with a flat top and edges that are error functions (erfs) where:
@itemize{
    @item{@c{duration} is a rational number representing the duration of the
      waveform in seconds}
    @item{@c{risetime} is a rational number representing the rise and fall sections of
      the pulse in seconds}
    @item{@c{padleft} is a rational number representing the amount of zero-amplitude
      padding to add to the left of the pulse}
    @item{@c{padright} is a rational number representing the amount of zero-amplitude
      padding to add to the right of the pulse}
}
}
}
}
@subsubsection[:title "Defining new waveforms"]

@syntax[:name "Waveform Definition"]{
    DEFWAVEFORM @ms{Identifier} @rep[:max 1]{( @ms{Parameters} )} : @ms{Matrix Entries}
}

@p{New waveforms may be defined by listing out all the IQ values as
complex numbers, separated by commas. Waveform definitions may also be
parameterized, although note that Quil has no support for vector level
operations.}

@p{Example:
@clist{
DEFWAVEFORM my_custom_waveform:
    1+2i, 3+4i, 5+6i

DEFWAVEFORM my_custom_parameterized_waveform(%a):
    (1+2i)*%a, (3+4i)*%a, (5+6i)*%a
}
}


@p{A waveform is just a list of samples. The duration of a waveform is
determined by the number of samples divided by the sample rate of the
frame on which the waveform is pulsed. Frames have fixed,
hardware-specific sample rates.}

@subsection[:title "Pulses"]

@syntax[:name "Pulse"]{
    PULSE Frame Waveform
}

@p{Pulses represent the propagation of a specific waveform (either built-in or custom) on a specific frame.}

@p{Examples:

@clist{
# Simple pulse with previously defined waveform
PULSE 0 "xy" my_custom_waveform

# Pulse with previously defined parameterized waveform
PULSE 0 "xy" my_custom_parameterized_waveform(0.5)

# Pulse with built-in waveform generator
PULSE 0 "xy" flat(duration: 1e-6, iq: 2+3i)

# Pulse on a flux line
PULSE 0 1 "cz" flat(duration: 1e-6, iq: 2+3i)
}
}

@p{Each frame has a fixed, hardware-specific sample rate. The behavior of a @c{PULSE}
instruction with a custom waveform whose sample rate does not match the
corresponding frame's sample rate is undefined.}

@subsection[:title "Frame Mutations"]

@subsubsection[:title "Frequency"]

@syntax[:name "Set Frequency"]{
    SET-FREQUENCY @ms{Frame} @ms{Real}
}

@syntax[:name "Shift Frequency"]{
    SHIFT-FREQUENCY @ms{Frame} @ms{Real}
}

@p{Each frame has a frequency which is tracked throughout the program. Initial
frame frequencies are specified in the frame definition's @c{INITIAL-FREQUENCY}
attribute. Subsequent code may update this, either assigning an absolute value (@c{SET-FREQUENCY}) or a relative offset (@c{SHIFT-FREQUENCY}).}


@clist{
SET-FREQUENCY 0 "xy" 5.4e9
SHIFT-FREQUENCY 0 "ro" 6.1e9
}

@subsubsection[:title "Phase"]

@syntax[:name "Set Phase"]{
    SET-PHASE @ms{Frame} @ms{Real}
}

@syntax[:name "Shift Phase"]{
    SHIFT-PHASE @ms{Frame} @ms{Expression}
}

@syntax[:name "Swap Phases"]{
    SWAP-PHASES @ms{Frame} @ms{Frame}
}

@p{Each frame has a phase which is tracked throughout the program. Initially the
phase starts out as 0. It may be set or shifted up and down, as well as swapped
with other frames.}

@p{The phase must be a rational real number. There is also support for
shifted the phase based on some expression, as long as that expression returns
a real number.}

@p{Example:

@clist{
SET-PHASE 0 "xy" pi/2

SHIFT-PHASE 0 "xy" -pi
SHIFT-PHASE 0 "xy" %theta*2/pi

SWAP-PHASE 0 "xy" 1 "xy"
}
}

@subsubsection[:title "Scale"]

@syntax[:name "Set Scale"]{
    SET-SCALE @ms{Frame} @ms{Real}
}

@p{Each frame has a scale which is tracked throughout the program. The
scale is initially 1.}

@p{Example:

@clist{
SET-SCALE 0 "xy" 0.75
}
}

@subsection[:title "Capture"]

@syntax[:name "Capture"]{
    CAPTURE @ms{Frame} @ms{Waveform} @ms{Memory Reference}
}

@syntax[:name "Raw Capture"]{
    RAW-CAPTURE @ms{Frame} @ms{Expression} @ms{Memory Reference}
}

@p{The capture instruction opens up the readout on a frame and measures its state.
An integration waveform will be applied to the raw IQ points and the result is
placed in classical memory.}

@p{The waveform will define the duration of the capture. The memory reference must
be able to store a complex number for each qubit in the frame.}

@p{In the case of a raw capture the waveform is replaced with a rational number
representing the duration of the capture.}

@p{Example:

@clist{
# Simple capture of an IQ point
DECLARE iq REAL[2]
CAPTURE 0 "out" flat(1e-6, 2+3i) iq

# Raw capture
DECLARE iqs REAL[400] # length needs to be determined based on the sample rate
CAPTURE 0 "out" 200e-6 iqs
}
}

@p{The behavior of a @c{CAPTURE} instruction with a custom waveform whose sample rate
does not match the corresponding frame's sample rate is undefined.}

@subsection[:title "Defining Calibrations"]

@syntax[:name "Calibration Definition"]{
    DEFCAL @rep[:min 0]{@ms{Modifier}} @ms{Identifier} ( @ms{Parameters} ) @rep[:min 1]{@ms{Qubit}} : @rep[:min 1]{@ms{Instruction}}
}

@syntax[:name "Measure Calibration"]{
    DEFCAL @ms{Identifier} @rep[:min 0 :max 1]{@ms{Qubit}} @ms{Parameter} : @rep[:min 1]{@ms{Instruction}}
}

@p{Calibrations for high-level gates can be defined by mapping a combination of
(gate name, parameters, qubits) to a sequence of analog control instructions.}

@p{Calibrations with the same gate name as a built-in gate definition or custom
gate definition are assumed to be the same.}

@p{Multiple calibration definitions can be defined for different parameter and
qubit values. When a gate is translated into control instructions the
calibration definitions are enumerated in reverse order of definition and the
first match will be taken.}

@p{For example, given the following list of calibration definitions in this order:

@enumerate{
    @item{@c{DEFCAL RX(%theta) %qubit:}}

    @item{@c{DEFCAL RX(%theta) 0:}}

    @item{@c{DEFCAL RX(pi/2) 0:}}
}

The instruction @c{RX(pi/2) 0} would match (3), the instruction @c{RX(pi) 0} would
match (2), and the instruction @c{RX(pi/2) 1} would match (1).}

@p{The same system applies for @c{MEASURE}. Although @c{MEASURE} cannot be
parameterized, it takes only a single qubit as input, and it has an additional
(optional) parameter for the memory reference into which to store the result.}

@p{Examples:

@clist{
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
}
}

@p{Quil supports arbitrarily chained gate modifiers. As such, calibration
definitions may also incorporate gate modifiers, with the convention that a
calibration definition matches a gate application only if the modifiers match
exactly. Thus in

@clist{
DEFCAL T 0:
    # ...

DEFCAL DAGGER T 0:
    # ...
}

the first calibration definition matches @c{T 0}, the second matches @c{DAGGER T 0},
and neither match @c{DAGGER DAGGER T 0}.
}

@subsection[:title "Timing and Synchronization"]

@syntax[:name "Delay"]{
    DELAY @rep[:min 1]{@ms{Qubit}} @rep[:min 0]{@ms{Frame Identifier}} @ms{Expression}
}

@syntax[:name "Fence"]{
    FENCE @rep[:min 0]{@ms{Qubit}}
}

@p{Delay allows for the insertion of a gap within a list of pulses or gates with
a specified duration in seconds.}

@p{If frame names are specified, then the delay instruction affects those frames on
those qubits. If no frame names are specified, all frames on precisely those
qubits are affected.}

@aside{Note: this excludes frames which @emph{intersect} the
specified qubits but involve others. For example, @c{DELAY 0 1.0} delays one qubit
frames on @c{0}, such as @c{0 "xy"}, but leaves other frames, such as @c{0 1 "cz"},
unaffected.}

@p{Fence ensures that all operations involving the specified qubits that follow the
fence statement happen after all operations involving the specified qubits that
preceed the fence statement. If no qubits are specified, the @c{FENCE} operation
implicitly applies to all qubits on the device.}

@p{Examples:

@clist{
X 0
FENCE 0 1
X 1 # This X gate will be applied to qubit 1 AFTER the X gate on qubit 0

# Simple T1 experiment
X 0
DELAY 0 100e-6
MEASURE 0 ro[0]
}
}
