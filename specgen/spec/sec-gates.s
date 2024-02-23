@section[:title "Quantum Gates"]

@subsection[:title "Qubits and Quantum State"]

@p{A Quil program manipulates quantum resources called @emph{qubits}. Qubits are indexed by non-negative integers.}

@syntax[:name "Qubit"]{
@ms{Integer}
}

@p{Qubit indexes have no significance on their own. Qubits must always
be referred to by their index. There is no bound on the number of
qubits in a Quil program, and any finite collection of qubits may
interact.}

@p{Quil has no ways to allocate an unbounded or non-deterministic
number of qubits at run-time. The number of qubits used by a program
can always be statically determined.}

@p{Sometimes, a qubit may instead have a formal argument in its
place. This may not be possible in all cases.}

@syntax[:name "Formal Qubit"]{
         @ms{Qubit}
    @alt @ms{Argument}
}

@subsection[:title "Quantum Gate Definitions"]

@subsubsection[:title "Structure of a Gate Definition"]

@p{A gate definition allows us to name a unitary operation for
subsequent use in a program. A gate definition in general has the
following structure:}

@clist{
DEFGATE <name>(<params>) AS <kind>:
    <body>
}

@p{Here, the @c{<name>} names the gate, the @c{<kind>} states how we
are defining the gate, and the @c{<body>} depends on the @c{kind}. For
certain gates, @c{<params>} specifies parameters to the gate.}

@syntax[:name "Gate Definition"]{
     @ms{Matrix Gate Definition}
@alt @ms{Permutation Gate Definition}
@alt @ms{Pauli Sum Gate Definition}
@alt @ms{Sequence Gate Definition}
}

@subsubsection[:title "Definition by Matrix"]

@p{A gate can be defined by its matrix of complex numbers represented
in the computational basis with the aforementioned ordering.}

@syntax[:name "Matrix Gate Definition"]{
DEFGATE @ms{Identifier}
@rep[:min 0 :max 1]{@group{(@ms{Parameters})}}
@rep[:min 0 :max 1]{@group{AS MATRIX}}:
@ms{Matrix Entries}
}

@p{A gate definitions with no parameters represents a static
gate. Otherwise it is a parametric gate.}

@p{For readability, matrix entries are typically broken up into
lines.}

@syntax[:name "Matrix Entries"]{
    @rep[:min 1]{@group{@ms{Indent}@ms{Matrix Entry Line}}}
}

@p{Each line contains a list of comma-separated arithmetic
expressions, most often simple integers or real numbers.}

@syntax[:name "Matrix Entry Line"]{
    @ms{Expression} @rep[:min 0]{@group{, @ms{Expression}}}
}

@p{The arithmetic expressions may either be constant or refer to the
parameters of the defined gate.}


@subsubsection[:title "Definition by Permutation"]

@p{A @emph{permutation gate} is one that permutes the coefficients of
the wavefunction. A permutation @m{p} can be specified mathematically
as an ordering of the integers between @m{0} and @m{n-1} written out
as a list @dm{(p_1\;p_2\;\ldots\;p_n).} Here, @m{p} is a map on
vectors such that if @m{x} is a column vector
@dm{(x_1,\ldots,x_n)^{\intercal}} then @m{p(x)} is a column vector
@dm{(x_{p_1}, x_{p_2}, \ldots, x_{p_n})^{\intercal}.} We specify
permutation gates exactly by these numbers.}

@syntax[:name "Permutation Gate Definition"]{
DEFGATE @ms{Identifier} AS PERMUTATION:@ms{Indent}@ms{Permutation}
}

@p{Here, the permutation is a comma-separated list of non-negative
integers.}

@syntax[:name "Permutation"]{
    @ms{Integer}
    @rep[:min 1]{
    @group{
        ,
        @ms{Integer}
    }
    }
}

@p{There must be at least two integers specified, and the number of
integers specified must be a power-of-two.}

@subsubsection[:title "Definition by Pauli Sum"]

@p{Quantum gates can be defined by an associated Hamiltonian, as in

@dm{U(\mathbf t) = \exp(-i \mathcal H(\mathbf t))}

for a Hermitian operator @m{\mathcal H}. Quil allows @m{\mathcal H} to
be specified as a @emph{Pauli sum}, a sum of combinations of Pauli
operators.
}

@p{The syntax is as follows.}

@syntax[:name "Pauli Sum Gate Definition"]{
DEFGATE @ms{Identifier}
@rep[:min 0 :max 1]{@group{(@ms{Parameters})}}
@ms{Arguments}
AS PAULI-SUM:@ms{Pauli Terms}
}

@p{The collection of Pauli term must be written on their own lines.}

@syntax[:name "Pauli Terms"]{
    @rep[:min 1]{@group{@ms{Indent}@ms{Pauli Term}}}
}

@p{Each Pauli term represents some coefficient multiplied against a
tensor product of Pauli operators.}

@syntax[:name "Pauli Term"]{
    @ms{Pauli Word}(@ms{Expression}) @ms{Arguments}
}

@p{A @c{PAULI-SUM} gate definition is subject to some restrictions:

@itemize{

    @item{The number of @ms{Arguments} must equal the length of the
    @ms{Pauli Word}.}

    @item{The @ms{Expression} must be a real-valued expression which
    references only real numeric literals as well as parameters from
    the @ms{Parameters} list of the gate definition.}

    @item{@ms{Arguments} in a @ms{Pauli Term} must only refer to
    arguments that exist in the gate definition.}

}
}

@syntax[:name "Pauli Word"]{
    @rep[:min 1]{@group{I @alt X @alt Y @alt Z}}
}

@subsubsubsection[:title "Semantics"]

@p{We describe how one is intended to extract a matrix presentation of
an operator from such a Pauli sum, and then we remit the discussion of
semantics to that for @ms{Matrix Gate Definition}.

@enumerate{

    @item{Pad each Pauli word appearing in the sum with @c{I} letters,
    so that all formal qubits appear in all terms.}

    @item{Sort the qubit arguments appearing in each term to agree
    with the qubit argument list in the definition
    header. Simultaneously, sort the letters appearing in the Pauli
    word to match.}

    @item{Using the Quil-standard matrix definitions of @c{I}, @c{X},
    @c{Y}, and @c{Z}, associate to each Pauli term's Pauli word the
    ordered tensor product of these basic matrices.}

   @item{Scale each such matrix by the Pauli term's @ms{Expression}.}

   @item{Sum the matrices, multiply by @m{-i=-\sqrt{-1}}, and form the
   matrix exponential.}
}
}

@p{See the next sections for an example semantic reduction.}

@subsubsubsection[:title "Example Syntax"]

@p{Many standard examples of gates admit short expression in these terms:

@clist{
DEFGATE RY(%theta) q AS PAULI-SUM:
    Y(%theta/2) q
}

This also includes many standard multi-qubit operators:

@clist{
DEFGATE CPHASE(%theta) p q AS PAULI-SUM:
    ZZ(%theta/4) p q
    Z(-%theta/4) p
    Z(-%theta/4) q

DEFGATE CAN(%alpha, %beta, %gamma) p q AS PAULI-SUM:
    XX(%alpha/4) p q
    YY(%beta/4)  p q
    ZZ(%gamma/4) p q
}

It also includes some operators encountered in practice, e.g., the following reduction of an Ansatz appearing in the electronic structure simulation problem for @m{\mathrm H_2}:

@clist{
DEFGATE UCC-H2(%theta) p q r s AS PAULI-SUM:
    YXXX(%theta) p q r s
}
}

@subsubsubsection[:title "Example Semantic Reduction of CPHASE"]

@p{In the example definition of @c{CPHASE} above, these steps proceed as follows:

@enumerate{

    @item{We replace @c{ZZ p q} with @c{ZZ p q} (i.e., no change), @c{Z p}
    by @c{ZI p q}, and @c{Z q} by @c{ZI q p}, which each now apply
    to all the available formal qubits.}

    @item{We replace @c{ZZ p q} by @c{ZZ p q} (i.e., no change), @c{ZI
    p q} by @c{ZI p q}, and @c{ZI q p} by @c{IZ p q}, which now all
    end in @c{p q}.}

    @item{The tensor products associated to these three terms are respectively

      @dm{
      \begin{align*}
        ZZ &= \left( \begin{smallmatrix}1 \\ & -1 \\ & & -1 \\ & & & 1 \end{smallmatrix} \right) &
        ZI &= \left( \begin{smallmatrix}1 \\ & 1 \\ & & -1 \\ & & & -1 \end{smallmatrix} \right) &
        IZ &= \left( \begin{smallmatrix}1 \\ & -1 \\ & & 1 \\ & & & -1 \end{smallmatrix} \right),
      \end{align*}
      }
      where we have elided zero entries.
    }

    @item{After rescaling by the associated expressions, these matrices become

      @dm{
        \left( \begin{smallmatrix}\theta/4 \\ & -\theta/4 \\ & & -\theta/4 \\ & & & \theta/4 \end{smallmatrix} \right)
        \qquad
        \left( \begin{smallmatrix}-\theta/4 \\ & -\theta/4 \\ & & \theta/4 \\ & & & \theta/4 \end{smallmatrix} \right)
        \qquad
        \left( \begin{smallmatrix}-\theta/4 \\ & \theta/4 \\ & & -\theta/4 \\ & & & \theta/4 \end{smallmatrix} \right).
        }
    }

    @item{Taking the sum and multiplying by @m{-i} yields

      @dm{
        \left( \begin{smallmatrix}i\theta/4 \\ & i\theta/4 \\ & & i\theta/4 \\ & & & -3i\theta/4 \end{smallmatrix} \right),
      }

      and exponentiating yields

      @dm{
        \mathtt{CPHASE}(\theta) = \left( \begin{smallmatrix}e^{i\theta/4} \\ & e^{i\theta/4} \\ & & e^{i\theta/4} \\ & & & e^{-3i\theta/4} \end{smallmatrix} \right).
        }
    }
}

Up to global phase, this is evidently equivalent to the usual @c{AS
MATRIX} definition (as specified in the next section).
}

@subsubsection[:title "Sequence Gate Definitions"]

@p{A gate can be defined by a sequence of other gate applications on formal arguments.}

@syntax[:name "Sequence Gate Definition"]{
DEFGATE @ms{Identifier}
@rep[:min 0 :max 1]{@group{(@ms{Parameters})}}
@ms{Arguments}
AS SEQUENCE:
@rep[:min 1]{@ms{Sequence Line}}@group{@ms{Newline} @alt @syntax-descriptive{End of File}}
}

@p{A sequence element is effectively a gate application where the formal qubit must be an argument.}

@syntax[:name "Sequence Element"]{
    @rep[:min 0]{@ms{Modifier}}
    @ms{Identifier}
    @rep[:min 0 :max 1]{
        @group{
            (
                @ms{Expression List}
            )
        }
    }
    @rep[:min 1]{@ms{Argument}}
}

@syntax[:name "Sequence Line"]{
    @ms{Indent} @ms{Sequence Element} @rep[:min 0]{@group{;@ms{Sequence Element}}}
}


@subsubsubsection[:title "Semantics"]

@p{Each argument of a @ms{Sequence Element} must correspond to an @ms{Argument} contained in @ms{Arguments} found in the gate definition header (An @ms{Argument} is not a @ms{Qubit}). An @ms{Expression} in the @ms{Expression List} may reference a @ms{Parameter} from @ms{Parameters} found in the gate definition header.}

@p{The unitary for a sequence gate should be the result of multiplying each unitary from that gate's sequence elements in the order they appear in the body. The resulting unitary should cover the combined space of the arguments for that gate definition, including unused arguments.}

@p{Sequence gate definitions may refer to one another, but any circularity (e.g., defining @m{X} as the product @m{BXA} for some unitary operators @m{A} and @m{B}) is disallowed.}


@subsubsubsection[:title "Example"]

@p{A @m{T} gate on two qubits is:}
@clist{

DEFGATE TT p q AS SEQUENCE:
    T p
    T q
}
@p{The standard gate `CSWAP` (Toffoli) could be defined with the following definition:}
@clist{
DEFGATE TOFFOLI p q r AS SEQUENCE:
    H        r
    CNOT     q r
    DAGGER T r
    CNOT     p r
    T        r
    CNOT     q r
    DAGGER T r
    CNOT     p r
    #Note the use of TT here
    TT       q r
    CNOT     p q
    H        r
    T        p
    DAGGER T q
    CNOT     p q    
}
@p{An arbitrary Euler rotation could be expressed as:}

@clist{    

DEFGATE EULER(%alpha, %beta, %gamma) p AS SEQUENCE:
    RY(%alpha) p
    RZ(%beta)  p 
    RY(%gamma) p 
}

@subsection[:title "Standard Gate Definitions"]


@subsubsection[:title "Pauli Gates"]

@dm{
\begin{align*}
\texttt{I} &= \left(\begin{smallmatrix}
1 & 0\\
0 & 1
\end{smallmatrix}\right)
&
\texttt{X} &= \left(\begin{smallmatrix}
0 & 1\\
1 & 0
\end{smallmatrix}\right)
&
\texttt{Y} &= \left(\begin{smallmatrix}
0 & -i\\
i & 0
\end{smallmatrix}\right)
&
\texttt{Z} &= \left(\begin{smallmatrix}
1 & 0\\
0 & -1
\end{smallmatrix}\right)
\end{align*}
}

@subsubsection[:title "Hadamard Gate"]

@dm{
\texttt{H} = \tfrac{1}{\sqrt{2}}\left(\begin{smallmatrix}
1 & 1\\
1 & -1
\end{smallmatrix}\right)
}

@subsubsection[:title "Phase Gates"]

@dm{
\begin{align*}
\texttt{PHASE}(\theta) &= \left(\begin{smallmatrix}
1 & 0\\
0 & e^{i\theta}
\end{smallmatrix}\right)
&
\texttt{S} &= \texttt{PHASE}(\pi/2)
&
\texttt{T} &= \texttt{PHASE}(\pi/4)
\end{align*}
}

@subsubsection[:title "Controlled-Phase Gates"]

@dm{
\begin{align*}
\texttt{CPHASE00}(\theta) &= \operatorname{diag}(e^{i\theta},1,1,1) \\
\texttt{CPHASE01}(\theta) &= \operatorname{diag}(1,e^{i\theta},1,1) \\
\texttt{CPHASE10}(\theta) &= \operatorname{diag}(1,1,e^{i\theta},1) \\
\texttt{CPHASE}(\theta) &= \operatorname{diag}(1,1,1,e^{i\theta}) \\
\texttt{CZ} &= \texttt{CPHASE}(\pi)
\end{align*}
}

@p{Note that one has the following equivalences in Quil:

@clist{
CZ == CONTROLLED Z
CPHASE = CONTROLLED PHASE
}
}


@subsubsection[:title "Cartesian Rotation Gates"]

@dm{
\begin{align*}
\texttt{RX}(\theta) &= \left(\begin{smallmatrix}
\cos\frac{\theta}{2} & -i\sin\frac{\theta}{2}\\
-i\sin\frac{\theta}{2} & \cos\frac{\theta}{2}
\end{smallmatrix}\right)\\
\texttt{RY}(\theta) &= \left(\begin{smallmatrix}
\cos\frac{\theta}{2} & -\sin\frac{\theta}{2}\\
\sin\frac{\theta}{2} & \cos\frac{\theta}{2}
\end{smallmatrix}\right)\\
\texttt{RZ}(\theta) &= \left(\begin{smallmatrix}
e^{-i\theta/2} & 0\\
0 & e^{i\theta/2}
\end{smallmatrix}\right)
\end{align*}
}

@subsubsection[:title "Controlled-X Gates"]

@dm{
\begin{align*}
\texttt{CNOT} &=
\left(
\begin{smallmatrix}
1 & 0 & 0 & 0\\
0 & 1 & 0 & 0\\
0 & 0 & 0 & 1\\
0 & 0 & 1 & 0
\end{smallmatrix}
\right) &
\texttt{CCNOT} &=
\left(
\begin{smallmatrix}
    1 & 0 & 0 & 0 & 0 & 0 & 0 & 0\\
    0 & 1 & 0 & 0 & 0 & 0 & 0 & 0\\
    0 & 0 & 1 & 0 & 0 & 0 & 0 & 0\\
    0 & 0 & 0 & 1 & 0 & 0 & 0 & 0\\
    0 & 0 & 0 & 0 & 1 & 0 & 0 & 0\\
    0 & 0 & 0 & 0 & 0 & 1 & 0 & 0\\
    0 & 0 & 0 & 0 & 0 & 0 & 0 & 1\\
    0 & 0 & 0 & 0 & 0 & 0 & 1 & 0
\end{smallmatrix}
\right)
\end{align*}
}

@aside{The gate @c{CCNOT} is sometimes known as the @emph{Toffoli
gate}. It is a universal classical logic gate.}

@p{Note that one has the following equivalences in Quil:

@clist{
CNOT  == CONTROLLED X
CCNOT == CONTROLLED CONTROLLED X
}
}

@subsubsection[:title "Swap Gates"]

@dm{
\begin{align*}
\texttt{PSWAP}(\theta) &=
\left(
\begin{smallmatrix}
1 & 0 & 0 & 0\\
0 & 0 & e^{i\theta} & 0\\
0 & e^{i\theta} & 0 & 0\\
0 & 0 & 0 & 1
\end{smallmatrix}
\right)\\
\texttt{SWAP} &= \texttt{PSWAP}(0)\\
\texttt{ISWAP} &= \texttt{PSWAP}(\pi/2)\\
\texttt{PISWAP}(\theta) &=
\left(
\begin{smallmatrix}
1 & 0 & 0 & 0\\
0 & \cos(\theta/2) & i\sin(\theta/2) & 0\\
0 & i\sin(\theta/2) & \cos(\theta/2) & 0\\
0 & 0 & 0 & 1
\end{smallmatrix}
\right)\\
\texttt{CSWAP} &=
\left(
\begin{smallmatrix}
    1 & 0 & 0 & 0 & 0 & 0 & 0 & 0\\
    0 & 1 & 0 & 0 & 0 & 0 & 0 & 0\\
    0 & 0 & 1 & 0 & 0 & 0 & 0 & 0\\
    0 & 0 & 0 & 1 & 0 & 0 & 0 & 0\\
    0 & 0 & 0 & 0 & 1 & 0 & 0 & 0\\
    0 & 0 & 0 & 0 & 0 & 0 & 1 & 0\\
    0 & 0 & 0 & 0 & 0 & 1 & 0 & 0\\
    0 & 0 & 0 & 0 & 0 & 0 & 0 & 1
\end{smallmatrix}
\right)
\end{align*}
}

@aside{The gate @c{CSWAP} is sometimes known as the @emph{Fredkin
gate}. It is a universal classical logic gate.}

@p{Note that one has the following equivalence in Quil:

@clist{
CSWAP == CONTROLLED SWAP
}
}


@subsubsection[:title "Other Gates"]

@dm{
\begin{align*}
\texttt{XY}(\theta) &= \exp\left( -i\theta(\texttt{X}^{\otimes 2} + \texttt{Y}^{\otimes 2}) \right)
                     = \texttt{PISWAP}(\theta)\\
\texttt{CAN}(\alpha, \beta, \gamma) &=
\exp\left( -i (  \alpha\texttt{X}^{\otimes 2}
               + \beta\texttt{Y}^{\otimes 2}
               + \gamma\texttt{Z}^{\otimes 2}
    \right)
\end{align*}
}

@aside{Every two-qubit gate can be written in terms of @c{CAN},
possibly with up to two preceding and two proceeding arbitrary
one-qubit gates.}

@p{The definition of @c{CAN} can be written as the following Quil
matrix definition:

@clist{
DEFGATE CAN(%alpha, %beta, %gamma):
    (cis((%alpha+%beta-%gamma)/2)+cis((%alpha-%beta+%gamma)/2))/2, 0, 0, (cis((%alpha-%beta+%gamma)/2)-cis((%alpha+%beta-%gamma)/2))/2
    0, (cis((%alpha+%beta+%gamma)/(-2))+cis((%beta+%gamma-%alpha)/2))/2, (cis((%alpha+%beta+%gamma)/(-2))-cis((%beta+%gamma-%alpha)/2))/2, 0
    0, (cis((%alpha+%beta+%gamma)/(-2))-cis((%beta+%gamma-%alpha)/2))/2, (cis((%alpha+%beta+%gamma)/(-2))+cis((%beta+%gamma-%alpha)/2))/2, 0
    (cis((%alpha-%beta+%gamma)/2)-cis((%alpha+%beta-%gamma)/2))/2, 0, 0, (cis((%alpha+%beta-%gamma)/2)+cis((%alpha-%beta+%gamma)/2))/2
}

It also has a straightforward definition as a @c{PAULI-SUM}.
}





@subsection[:title "Quantum Gate Applications"]

@subsubsection[:title "Syntax and Semantics"]

@p{A gate is applied via the following syntax.}

@syntax[:name "Gate Application"]{
    @rep[:min 0]{@ms{Modifier}}
    @ms{Identifier}
    @rep[:min 0 :max 1]{
        @group{
            (
                @ms{Expression List}
            )
        }
    }
    @rep[:min 1]{@ms{Formal Qubit}}
}

@p{We refer to Section II.A of @link[:target
"https://arxiv.org/abs/1608.03355"]{@emph{A Practical Quantum
Instruction Set Architecture}} for extensive and detailed mathematical
discussion on the semantics of gate application realized as a matrix
operator on the Hilbert space of the QAM.}

@p{Quil supports three kinds of unitary modifiers.}

@syntax[:name "Modifier"]{
         DAGGER
    @alt CONTROLLED
    @alt FORKED(@ms{Expression List})
}

@p{These are described in the next sections.}

@subsubsection[:title "DAGGER Gate Modifier"]

@p{The @c{DAGGER} modifier represents the adjoint operation or
complex-conjugate transpose. Since every gate is a unitary operator,
this is just the inverse. For example, if @c{G} is a gate described by
the one-qubit operator

@dm{
\begin{pmatrix}
a & b\\
c & d
\end{pmatrix}
}

then @c{DAGGER G} is

@dm{
\begin{pmatrix}
a^* & c^*\\
b^* & d^*
\end{pmatrix}
}

where @m{z^*} is the complex-conjugate of @m{z}.
}

@p{Because @c{DAGGER} is the inverse, the sequence of Quil
instructions

@clist{
G q1 ... qn
DAGGER G q1 ... qn
}

acts as an identity gate. As another example, consider the gate
@c{PHASE}, which is defined as

@clist{
DEFGATE PHASE(%alpha):
    1, 0
    0, cis(%alpha)
}

where
@dm{\operatorname{cis}\alpha := \cos\alpha + i \sin\alpha = e^{i\alpha}.}
Then

@clist{
DAGGER PHASE(t) q
}

is equivalent to

@clist{
PHASE(-t) q
}

for all @m{\mathtt{t}\in\mathbb{R}}.
}


@subsubsection[:title "CONTROLLED Gate Modifier"]

@p{The @c{CONTROLLED} modifier takes some gate @c{G} acting on some
number of qubits @c{q1} to @c{qn} and makes it conditioned on the
state of some new qubit @c{c}. In terms of the matrix representation,
if @c{c} is in the one-state, then @c{G} is applied to the remaining
qubits; and if @c{c} is in the zero-state, no operation is
applied. Therefore, an application of the @m{n}-qubit operator @c{G}
as in

@clist{
G q1 ... qn
}

has the controlled variant with @c{CONTROLLED G} an (n+1)-qubit
operator:

@clist{
CONTROLLED G c q1 ... qn
}
}

@p{For example, the gate @c{CONTROLLED X 1 0} is the familiar
controlled-not gate, which can also be written using the standard
built-in Quil gate @c{CNOT 1 0}.}

@p{Specifically, when acting on a gate @c{G} that can be represented
as an @m{N \times N} matrix @m{U}, @c{CONTROLLED G} produces a gate
@c{G'} described by the @m{2N \times 2N} matrix @m{C(U)} such that
@m{C(U) := I \oplus U}, where @m{I} is the @m{N \times N} identity
matrix and @m{\oplus} is a direct sum. For example, if @m{U} is the
one-qubit operator

@dm{
\begin{pmatrix}
a & b \\
c & d
\end{pmatrix}
}

then @m{C(U)} is

@dm{
\begin{pmatrix}
1 & 0 & 0 & 0 \\
0 & 1 & 0 & 0 \\
0 & 0 & a & b \\
0 & 0 & c & d \\
\end{pmatrix}.
}
}

@aside{The @c{CONTROLLED} modifier is sensitive to
phase. Mathematically, for a gate @m{G} and a phase angle @m{\theta},
@m{C(G)\neq C(e^{i\theta}G)}. Practically, this means that while the
standard gates @c{Z} and @c{PHASE} are equivalent operators in
@m{\mathscr{U}(2)} despite different matrix entries, their controlled
variants (i.e., @c{CZ} and @c{CONTROLLED PHASE}) are @emph{not}
equivalent.}

@subsubsection[:title "FORKED Gate Modifier"]

@p{Let @c{G} be a parametric gate of @m{k} parameters @c{r1} to @c{rk}
and @m{n} qubits @c{q1} to @c{qn}. This is written:

@clist{
G(r1, ..., rk) q1 ... qn
}

Next, consider a second set of @m{k} parameters @c{s1} to @c{sk}. The
@c{FORKED} modifier takes such a gate @c{G} and allows either set of
parameters to be used conditioned on an additional qubit @c{c}.

@clist{
FORKED G(r1, ..., rk, s1, ..., sk) c q1 ... qn
}

Roughly speaking, in terms of the matrix representation of the
operator, this is equivalent to the pseudocode:

@clist{
if c = 0:
    G(r1, ..., rk) q1 ... qn
else if c = 1:
    G(s1, ..., sk) q1 ... qn
}
}

@aside{It is @emph{very} important to note that both @c{CONTROLLED}
and @c{FORKED} are purely quantum, unitary operations. There is no
"actual" conditional branching. The use of the above pseudocode is to
illustrate how one might write the matrix representation in the
standard computational basis.}

@p{For example, the built-in gate @c{RX} takes a single @c{%theta}
parameter and acts on a single qubit, like so @c{RX(pi/2)
0}. Therefore, @c{FORKED RX(pi/2, pi/4) 1 0} produces a "forked"
version of @c{RX}, conditioned on qubit @c{1}. If qubit @c{1} is in
the zero-state, this corresponds to @c{RX(pi/2) 0} and to @c{RX(pi/4)
0} if qubit @c{1} is in the one-state.}

@p{In general, when acting on a parametric gate @c{G} of @m{k}
parameters that can be represented as an @m{N \times N} matrix

@dm{U(p_1,\ldots,p_k),}

@c{FORKED G} produces a @m{2N \times 2N} matrix

@dm{F(U)(p_1,\ldots,p_k,p_{k+1},\ldots,p_{2k})
:=
U(p_1,\ldots,p_k) \oplus U(p_{k+1},\ldots,p_{2k}),}

where @m{\oplus} is the direct sum.
}

@p{For example, the gate @c{RZ} is defined as

@clist{
DEFGATE RZ(%theta):
    cis(-%theta/2), 0
    0,              cis(%theta/2)
}

Therefore, @c{FORKED RZ(@m{\theta_0}, @m{\theta_1}) 1 0}, for real
numbers @m{\theta_0} and @m{\theta_1} results in a two-qubit operator
that can be described by the matrix

@dm{
\begin{pmatrix}
\operatorname{cis}(-\theta_0/2) & 0         & 0          & 0         \\
0          & \operatorname{cis}(\theta_0/2) & 0          & 0         \\
0          & 0         & \operatorname{cis}(-\theta_1/2) & 0         \\
0          & 0         & 0          & \operatorname{cis}(\theta_1/2) \\
\end{pmatrix}.
}
}


@subsubsection[:title "Chaining Modifiers"]

@p{When gate modifiers are chained, they consume qubits left-to-right,
so that in the following example, the @c{CONTROLLED} modifier is
conditioned on qubit @c{0}, @c{FORKED} on qubit @c{1}, and the gate
@c{G} acts on qubit @c{2}.

@clist{
CONTROLLED FORKED DAGGER G 0 1 2
    |         |          | ^ ^ ^
    |         |          | | | |
    |         |          +-|-|-+
    |         +------------|-+
    +----------------------+
}
}

@p{Note that chaining multiple @c{FORKED} modifiers causes the
numbers of parameters consumed by the gate to double for each
additional @c{FORKED}. For example:

@clist{
RX(pi) 0
FORKED RX(pi, pi/2) 1 0
FORKED FORKED RX(pi, pi/2, pi/4, pi/8) 2 1 0
}

You can think of that last example as representing the following
decision tree, where an edge label like @c{q2=0} means that qubit
@c{2} is in the zero state.

@clist{
+----------------------------------------------------------------------------+
|            FORKED FORKED RX(pi, pi/2, pi/4, pi/8) 2 1 0                    |
|                    /                               \                       |
|                 q2=0                              q2=1                     |
|                  /                                   \                     |
|     FORKED RX(pi, pi/2) 1 0                  FORKED RX(pi/4, pi/8) 1 0     |
|        /              \                         /               \          |
|     q1=0             q1=1                    q1=0              q1=1        |
|      /                  \                     /                   \        |
| RX(pi) 0              RX(pi/2) 0        RX(pi/4) 0              RX(pi/8) 0 |
+----------------------------------------------------------------------------+
}
}
