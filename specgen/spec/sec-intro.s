@aside{This document is in @emph{DRAFT STATUS} and is for review
purposes only. It is being developed by the @link[:target
"https://github.com/quil-lang/"]{Quil-Lang} group.}

@section[:title "Introduction"]

@p{This is the language specification for Quil, a language for hybrid
classical/quantum computations.}

@p{Quil is an instruction-based language; each line of a Quil program
generally corresponds to a single, discrete action. Despite its
resemblance, Quil is @emph{not} an assembly language.}

@aside{An @emph{assembly language} is a textual format for the machine
code of a specific computer architecture. Quil is not that, and may be
used for a variety of quantum computer architectures.}

@p{This is an example Quil program that simulates a coin flip:

@clist{
DECLARE ro BIT[1]
H 0
MEASURE 0 ro[0]
}

Here, we can see the use of both classical data and quantum data. The
qubit numbered @c{0} is prepared in a uniform superposition by the
Hadamard gate @c{H}, and then measured in the computational basis,
depositing the resulting bit into a classic bit register named @c{ro}.
}

@p{The remainder of this document serves as a reference for all Quil
language syntax constructs and their associated semantics.}
