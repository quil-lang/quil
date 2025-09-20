@section[:title "Measurement"]

@p{Measurement is the only way in which the quantum state can affect
classical memory.  Measurement comes in two flavors:
@emph{measurement-for-effect} and @emph{measurement-for-record}.}

@syntax[:name "Measurement Instruction"]{
         @ms{Measurement for Effect}
    @alt @ms{Measurement for Record}
}

@aside{If @link[:target "#12Annex-T--Pulse-Level-Control"]{Annex T (§12)},
the Quil-T extension to this specification, is in effect, then measurements are
extended to support @emph{measurement names}, such as @c{MEASURE!midcircuit},
which affect the physical realization of measurement.  See
@link[:target "#12-1Extensions-to-Quil"]{§12.1} for details.}

@p{Measurement-for-effect measures a single qubit and discards the
result.}

@syntax[:name "Measurement for Effect"]{
    MEASURE @ms{Formal Qubit}
}

@p{Measurement will stochastically project the qubit into either the
zero-state or the one-state depending on its probability of such
dictated by the wavefunction amplitudes.}

@p{@emph{Measurement-for-record} is the same as measurement-for-effect, but also
writes the resulting state to the classical memory of the QAM:}

@syntax[:name "Measurement for Record"]{
    MEASURE @ms{Formal Qubit} @ms{Memory Reference}
}

@p{Here, the memory reference must be either of type @c{BIT} or
@c{INTEGER}. In either case, a @m{0} is deposited at the referenced memory
location if the qubit was measured to be in the zero-state, and a
@m{1} is deposited there otherwise.}

@p{Note that there is no way in Quil to measure all qubits
simultaneously.}
