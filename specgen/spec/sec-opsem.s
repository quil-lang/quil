@section[:title "Operational Semantic Devices"]

@subsection[:title "Mathematical Preliminaries"]

@p{Define @m{\mathscr{B}} to be a Hilbert space isomorphic to
@m{\mathbb{C}^2}. Some texts refer to this space as a @emph{qubit}. We
may refer to it as a @emph{qubit space}.}

@p{We fix any orthonormal basis of @m{V := \mathscr{B}^{\otimes n}}
and call it the @emph{computational basis}. We use uppercase letters
to refer to the vector space and the corresponding lowercase indexed
letters with an overbar to refer to the computational basis elements
(e.g., @m{V} for the vector space and @m{\bar v_{*}} for the basis
elements). We order the computational basis as @m{\bar v_0} to @m{\bar
v_{2^n-1}} so the @m{k}th bit of the index (i.e., the coefficient of
@m{2^k}) of @m{\bar v_{*}} corresponds to the @m{0}th or @m{1}st basis
of the @m{k}th factor of @m{\mathscr{B}} from the right. For example,
let @m{n=3}, and let the left, middle, and right tensor factors of
@m{\mathscr{B}\otimes\mathscr{B}\otimes\mathscr{B}} be called @m{R},
@m{S}, and @m{T} respectively. Consider the basis element @m{\bar
v_4}. This index @m{4} is @c{100} in binary, and thus @m{\bar v_4}
corresponds to @m{\bar r_1\otimes \bar s_0\otimes \bar t_0}.}

@aside{Some texts might write @m{v_4} as either @m{\vert 001\rangle}
or @m{\vert 100\rangle}. We prefer the latter if we are to use Dirac
notation.}

@p{Given @m{V := \mathscr{B}}, we sometimes call @m{\bar v_0} the
@emph{ground state} or @emph{zero state}, and @m{\bar v_1} the
@emph{excited state} or @emph{one state}.}

@p{Define @m{\mathscr{U}(d)} to be the @emph{projective special
unitary group of dimension @m{d}}.}

@aside{Note that many texts write "PSU" instead of "U". We will often
say "unitary" when we really mean "projective special unitary".}

@subsection[:title "The Quantum Abstract Machine"]

@p{The semantics of Quil are defined operationally; that is, each
instruction of a Quil program is described by a change of some
state. This state is described by a mathematical object called the
"quantum abstract machine".}

@p{A @emph{quantum abstract machine} or @emph{QAM} is specified as:
@itemize{

    @item{A non-negative integer @m{N}, representing the number of
    qubits available to the machine; and a non-negative integer @m{M},
    representing the number of bits available to the machine;}

    @item{A pure quantum state (or @emph{wavefunction}) @m{\Psi},
    which is a vector in Hilbert space @m{\mathscr{B}^{\otimes N}};}

    @item{A classical state @m{C} of @m{M} ordered bits;}

    @item{A set @m{G} of static quantum gates, each of which is an
    element of @m{\mathscr{U}(2^N)}.}

    @item{A set @m{G'} of parametric quantum gates, each of which is a
    @m{k}-ary function @m{\mathbb{C}^k\to \mathscr{U}(2^N)}, where
    @m{k} can vary from gate to gate;}

    @item{A program @m{P} consisting of an ordered list of Quil
    instructions; and}

    @item{A program counter @m{0 \le \kappa \le \vert P\vert}
    represented as an integer indicating the "current" instruction.}
    }

This forms a @m{6}-tuple @m{(\Phi, C, G, G', P, \kappa)}. We may refer
to such a tuple as a QAM.}