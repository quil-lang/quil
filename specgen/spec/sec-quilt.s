@section[:title "Annex T: Pulse-Level Control"]

@p{This section describes time-domain extensions to Quil, formally known as
@emph{Annex T} of this document; Quil with Annex T in place is also known as
@emph{Quil-T}.}

@p{Quil-T allows specifying the behavior of QAM programs at a physical,
pulse-based level, as needed when programming supeconduncting qubit systems.  A
@emph{pulse} is a waveform that is played by the control system, and is the core
primitive exposed by Quil-T.}

@p{Quil-T provides functionality for defining @link[:target "#12-2Frames"]{the
contexts ("frames") in which waveforms can be played}, @link[:target
"#12-4Pulses"]{primitives for playing these pulses}, @link[:target
"#12-7Defining-Calibrations"]{specifications for lowering QAM-level gates to
pulse-level instructions}, and more.  It also @link[:target
"#12-1Extensions-to-Quil"]{extends some Quil instructions to allow pulse-level
configuration}; the forms that these extensions affect are are called out in the
main text of the specification.}

@subsection[:title "Extensions to Quil"]

@p{Quil-T extends the @c{MEASURE} instruction of Quil to support optional
@emph{measurement names}, which are written with an @c{!} after the @c{MEASURE}
keyword (as mentioned when defining @c{MEASURE} instructions in @link[:target
"#7Measurement"]{§7}).  For instance, a midcircuit measurement of qubit @c{0}
into memory locaiton @c{ro} can be written as @c{MEASURE!midcircuit 0 ro}, which
is distinct from a plain (unnamed) measurement @c{MEASURE 0 ro}; the latter is
still permitted, and simply unrelated to any named measurements.}

@p{These measurement names do not affect the QAM semantics of the program, and
are only used by @link[:target "#12-7-2Measure-Calibrations"]{measurement
calibrations (§12.7.2)} to select specific physical realizations of
measurement.  They are analogous to @link[:target
"https://quantumai.google/reference/python/cirq_google/ops/CalibrationTag"]{
Cirq's @emph{calibration tags}}.}

@p{The replacement syntax rules for @c{MEASURE} instructions are:}

@syntax[:name "Measurement for Effect"]{
    MEASURE @rep[:min 0 :max 1]{@group{! @ms{Identifier}}} @ms{Formal Qubit}
}

@syntax[:name "Measurement for Record"]{
    MEASURE @rep[:min 0 :max 1]{@group{! @ms{Identifier}}} @ms{Formal Qubit} @ms{Memory Reference}
}

@p{These only differ from the original Quil rules in having an additional
@rep[:min 0 :max 1]{@group{! @ms{Identifier}}} after the @c{MEASURE}.}

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

@p{A @emph{calibration} describes how to lower a high-level Quil operation to a
sequence of pulse-level Quil-T operations.  They are defined to match high-level
gate applications and measurements; a single calibration can match multiple such
instructions.}

@p{@link[:target "#12-7-1Gate-Calibrations"]{Calibrations for high-level gates
(§12.7.1)} can be defined by mapping a combination of (gate name, parameters,
qubits) to a sequence of analog control instructions.  Similarly, @link[:target
"#12-7-2Measure-Calibrations"]{calibrations for measurements (§12.7.2)} can be
defined by mapping a combination of (optional measurement name, qubit, optional
identifier) to a sequence of analog control instructions.}

@p{Each calibration can @emph{match} a high-level Quil gate application or
measurement instruction.  This means that this calibration is a candidate for
providing the Quil-T definition of that instruction.   Multiple calibrations can
match a single high-level Quil instruction; for instance, distinct calibrations
might be provided for @c{RZ(%theta) 0} and @c{RZ(pi) 0}.  In this case, the most
precise match is chosen, with ties broken in favor of the calibration defined
@emph{latest} in the program.  The calibration so chosen is called the
@emph{corresponding calibration} for that instruction.  The details of how
calibrations match instructions are defined in the following
subsections.}

@p{In a Quil-T program containing calibrations, the semantics of a high-level
instruction is to substitute it with the body of its corresponding calibration,
replacing any formal parameters (whether classical memory or qubits) with the
value provided in the instruction.  A Quil-T program must contain corresponding
calibrations for all of its gate application and measurement instructions.}

@subsubsection[:title "Gate Calibrations"]

@p{A calibration for a gate application instruction specifies:
@enumerate{
    @item{The gate modifiers (such as @c{DAGGER}), if any;}

    @item{The gate name (such as @c{RX});}

    @item{Any classical parameters to which the gate is applied (such as the
    rotation angle for @c{RX}); and}
    
    @item{The qubits on which the gate is operating.}
}}

@p{The last two categories can either specify an exact match of a concrete term,
or bind a parameter/formal qubit to whatever input is provided in the gate
application.  This latter is how multiple gate calibrations can match a single
gate application.}

@syntax[:name "Calibration Definition"]{
    DEFCAL
        @rep[:min 0]{@ms{Modifier}}
        @ms{Identifier}
        @rep[:min 0 :max 1]{@group{( @ms{Expression List} )}}
        @rep[:min 1]{@ms{Formal Qubit}}
        :
        @rep[:min 1]{@ms{Instruction}}
}

@p{A gate application matches a calibration when:
@enumerate{
    @item{The gate application has the same sequence of modifiers as the
    calibration.}

    @item{The gate name is the same as the name defined by the calibration.}

    @item{There are the same number of classical arguments to the gate
    application and the calibration, and gate argument @m{i} matches calibration
    argument @m{i} for all indices @m{i}.  An argument matches if either:
    @enumerate{
        @item{@emph{(Abstract.)}  The calibration argument is a parameter, such
        as @c{%theta}.}
        
        @item{@emph{(Concrete.)}  The two expressions are identical.}
    }}

    @item{There are the same number of qubits in the gate application and the
    calibration, and qubit @m{i} in the gate application matches qubit @m{i} in
    the calibration for all indices @m{i}.  A qubit matches if either:
    @enumerate{
        @item{@emph{(Abstract.)}  The calibration qubit is a formal qubit, such
        as @c{q}.}
        
        @item{@emph{(Concrete.)}  The two qubits are identical fixed qubits.}
    }}
}}

@p{Multiple gate calibration definitions can be defined with the same modifiers
and gate name but with different parameter and qubit values.  A match is more
precise than another if it has more concrete matches of arguments and qubits
combined.  As mentioned @link[:target "#12-7Defining-Calibrations"]{above}, the
most precise match for an instruction is its corresponding calibration.}

@p{Note that the rules for matching against gate modifiers do not perform any
reasoning or simplification.  Quil supports arbitrarily chained gate modifiers,
and a calibration definition's gate modifiers match a gate application only if
they match exactly.  Thus, given the calibrations

@clist{
DEFCAL T 0:
    # ...

DEFCAL DAGGER T 0:
    # ...
}

the first calibration definition matches @c{T 0}, the second matches @c{DAGGER T 0},
and neither matches @c{DAGGER DAGGER T 0}.  This is true even though at the QAM
level, @c{DAGGER DAGGER T 0} is the same as @c{T 0}.
}

@p{As a concrete example of how corresponding calibrations are chosen for gate
applications, suppose we have the following list of gate calibrations, which
have been provided in this order in the Quil program.

@enumerate{
    @item{@c{DEFCAL RX(pi/2) 1:}}

    @item{@c{DEFCAL RX(%theta) qubit:}}

    @item{@c{DEFCAL RX(pi) qubit:}}

    @item{@c{DEFCAL RX(%theta) 0:}}

    @item{@c{DEFCAL RX(pi/2) 0:}}
}}

@p{In that case, let's look at how some sample gate application instructions
would match these calibrations.

@enumerate{
    @item{@c{RX(pi/2) 0} would have the corresponding calibration (5), as it's
    an exact match.  This instruction matches calibrations (2), (4), and (5),
    but since (4) is the most precise match possible, it would be selected as
    the corresponding calibration.}

    @item{@c{RX(pi) 0} would have the corresponding calibration (4), as it
    matches with one concrete match.  The concrete match is the fixed qubit
    @c{0}, which appears in both the instruction and the calibration.  The angle
    @c{pi} is an abstract match, as it corresponds to @c{%theta}; during
    calibration expansion, @c{%theta} will be replaced with @c{pi} for this
    gate.  This instruction matches calibrations (2–4); it matches (2) with zero
    concrete matches and (4) with one concrete match, so (2) is eliminated, and
    the tie between (3) and (4) is broken by selecting (4) as it occurs later
    in the program.}

    @item{@c{RX(pi) 1} would have the corresponding calibration (2), as this is
    the only matching calibration.  Both the match of @c{pi} against @c{%theta}
    and of @c{1} against @c{qubit} are abstract, so this is the least precise
    match possible, but there are no other options.}

    @item{@c{RX(pi/2) 1} would have the corresponding calibration (1), as it's
    an exact match.  Even though this instruction matches calibrations (1) and
    (2), with (2) occurring later in the program, the fact that (1) is more
    precise means it takes priority.}

    @item{@c{RZ(pi/2) 0} would have no corresponding calibration, as it would
    not match any of the calibrations above.  All those calibrations are for an
    @c{RX} gate, but this is an application of an @c{RZ} gate.}
}}

@p{Examples:

@clist{
# Simple non-parameterized gate on qubit 0
DEFCAL X 0:
    PULSE 0 "xy" gaussian(duration: 1, fwhm: 2, t0: 3)

# Parameterized gate on qubit 0
DEFCAL RX(%theta) 0:
    PULSE 0 "xy" flat(duration: 1e-6, iq: 2+3i)*%theta/(2*pi)

# Applying RZ to any qubit
DEFCAL RZ(%theta) qubit:
    SHIFT-PHASE qubit "xy" %theta
}
}

@subsubsection[:title "Measure Calibrations"]

@p{Measurement calibrations are analogous to gate calibrations, but a bit
simpler.  A calibration for a @c{MEASURE} instruction specifies:
@enumerate{
    @item{The measurement name (such as @c{!midcircuit}), if any;}

    @item{The qubit being measured; and}
    
    @item{A name for the classical memory location being measured into, if any.}
}}

@p{The name used for the classical memory location is irrelevant for matching
purposes; all that matters is whether it is present or absent.  If there is a
classical memory location, this is a calibration for a measurement for record;
otherwise, this is a calibration for a measurement for effect.}

@p{The qubit being measured can either be an exact match of a fixed qubit or
bind a formal qubit to whichever qubit is actually being measured.  This is how
multiple measurement calibrations can match a single @c{MEASURE} instruction.}

@syntax[:name "Measure Calibration"]{
    DEFCAL MEASURE
        @rep[:min 0 :max 1]{@group{! @ms{Identifier}}}
        @ms{Formal Qubit}
        @rep[:min 0 :max 1]{@ms{Identifier}}
        :
        @rep[:min 1]{@ms{Instruction}}
}

@p{Matching is defined much as it is for gate calibrations.  A @c{MEASURE}
instruction matches a measurement calibration when:
@enumerate{
    @item{The optional measurement names match exactly: either both the
    instruction and the calibration have a measurement name and that name is the
    same, or neither has a measurement name at all.}

    @item{The qubit in the measurement instruction matches the qubit in the
    calibration.  A qubit matches if either:
    @enumerate{
        @item{@emph{(Abstract.)}  The calibration qubit is a formal qubit, such
        as @c{q}.}

        @item{@emph{(Concrete.)}  The two qubits are identical fixed qubits.}
    }}

    @item{The optional target memory reference is either present in both the
    instruction and the calibration, or absent in both; that is, either this is
    a measurement for record and a calibration of a measurement for record, or
    this is a measurement for effect and a calibration of a measurement for
    effect.}
}}

@p{Note that because we only measure one qubit at a time, the question of
precision in matches is simpler than for gates.  A concrete match for the qubit
means that this calibration is an exact match, and thus the most precise; an
abstract match means this is the least precise.  This is the same rule as for
gate calibrations – the more concrete matches, the more precise – but
specialized to the case where there is only one possible place for a concrete
match.  As mentioned @link[:target "#12-7Defining-Calibrations"]{above}, the
most precise match for an instruction is its corresponding calibration.}

@p{Gates with and without measurement names, or with distinct measurement names,
are considered wholly distinct operations, just as is the case for differently
named gates; calibrations for @c{MEASURE}, @c{MEASURE!name-1}, and
@c{MEASURE!name-2} will never match the same instruction.  (In particular, a
nameless @c{DEFCAL MEASURE} does @emph{not} behave as a fallback calibration for
named measurement instructions.)}

@p{As a concrete example of how corresponding calibrations are chosen for
@c{MEASURE} instructions, suppose we have the following list of measurement
calibrations, which have been provided in this order in the Quil program.

@enumerate{
    @item{@c{DEFCAL MEASURE!midcircuit qubit dest:}}

    @item{@c{DEFCAL MEASURE qubit:}}

    @item{@c{DEFCAL MEASURE qubit ro:}}

    @item{@c{DEFCAL MEASURE 0 dest:}}

    @item{@c{DEFCAL MEASURE qubit dest:}}

    @item{@c{DEFCAL MEASURE!midcircuit 0 dest:}}
}}

@p{In that case, let's look at how some sample @c{MEASURE} instructions would
match these calibrations.

@enumerate{
    @item{@c{MEASURE!midcircuit 0 ro} would have the corresponding calibration
    (6), as it's an exact match.  This instruction matches calibrations (1) and
    (6), but since (6) is the most precise match possible, it would be selected
    as the corresponding calibration.}

    @item{@c{MEASURE 0 ro} would have the corresponding calibration (4), as it's
    an exact match.  This instruction matches calibrations (3–5), but since (4)
    is the most precise match possible, it would be selected as the
    corresponding calibration.}

    @item{@c{MEASURE 1 ro} would have the corresponding calibration (5).
    Calibrations (3) and (5) are the only matching calibrations, and they are
    identical; the name of the target variable is irrelevant, even if it matches
    the name used in the instruction.  Although the match is not precise – the
    qubit is matched abstractly, with the fixed qubit @c{1} from the @c{MEASURE}
    corresponding to the formal qubit @c{qubit} in the calibration – there are
    no other options.  Since both of these matches are equally imprecise, the
    tie is broken in favor of (5) as it occurs  later in the program.}

    @item{@c{MEASURE 0} and @c{MEASURE 1} would both have the corresponding
    calibration (2), as this is the only matching calibration.  These
    measurement instructions are measurements for effect, but every other
    calibration is for a measurement for record.  Even though the qubit matches
    abstractly and there is a calibration for measurement for record on qubit
    @c{0}, we must select the calibration that defines a measurement for
    effect.}

    @item{@c{MEASURE!destructive 0 ro} would have no corresponding calibration,
    as it would not match any of the calibrations above.  None of these
    instructions define a measurement calibration for the measurement name
    @c{destructive}, even though they define other forms of measurement for
    record on qubit @c{0}.}
}}

@p{Examples:

@clist{
# Measurement and classification of qubit 0
DEFCAL MEASURE 0 dest:
    DECLARE iq REAL[2]
    CAPTURE 0 "out" flat(1e-6, 2+3i) iq
    LT dest iq[0] 0.5 # thresholding

# Perhaps midcircuit measurement of qubit 0 requires a more delicate waveform
DEFCAL MEASURE!midcircuit 0 dest:
    DECLARE iq REAL[2]
    CAPTURE 0 "out" flat(1e-7, 0.2+0.3i) iq
    LT dest iq[0] 0.5 # thresholding
}
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
qubits are affected.  Note that this excludes frames which @emph{intersect} the
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
