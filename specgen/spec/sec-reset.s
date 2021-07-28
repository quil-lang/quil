@section[:title "Quantum State Reset"]

@p{The quantum state may be reset to @m{\bar \psi_0} (i.e., all qubits
in the ground state) by issuing a reset instruction.}

@syntax[:name "State Reset Instruction"]{
    RESET
}

@p{Instead, one may reset an individual qubit.}

@syntax[:name "Qubit Reset Instruction"]{
    RESET @ms{Formal Qubit}
}

@p{This has the semantics corresponding to the following pseudo-code:}

@clist{
if 1 == MEASURE(qubit) then X(qubit)
}

@p{These make up the ways the quantum state may be reset.}

@syntax[:name "Reset Instruction"]{
         @ms{State Reset Instruction}
    @alt @ms{Qubit Reset Instruction}
}
