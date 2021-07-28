@section[:title "Measurement"]

@p{Measurement is the only way in which the quantum state can affect
classical memory. Measurement comes in two flavors:
@emph{measurement-for-effect} and @emph{measurement-for-record}.}

@p{Measurement-for-effect measures a single qubit and discards the
result.}

@syntax[:name "Measurement for Effect"]{
    MEASURE @ms{Formal Qubit}
}

@p{Measurement will stochastically project the qubit into either the
zero-state or the one-state depending on its probability of such
dictated by the wavefunction amplitudes.}

@syntax[:name "Measurement for Record"]{
    MEASURE @ms{Formal Qubit} @ms{Memory Reference}
}

@p{Here, the memory reference must be either of type @c{BIT} or
@c{INTEGER}. In either case, a @m{0} is deposited at the memory
location if the qubit was measured to be in the zero-state, and a
@m{1} otherwise.}

@p{These measurement varieties make up all measurement instructions.}

@syntax[:name "Measurement Instruction"]{
         @ms{Measurement for Effect}
    @alt @ms{Measurement for Record}
}

@p{Note that there is no way in Quil to measure all qubits
simultaneously.}
