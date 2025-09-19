@section[:title "Other Instructions and Directives"]

@subsection[:title "No-Operation Instruction"]

@p{The @emph{no-operation instruction} or @emph{@c{NOP} instruction} is an instruction which does not affect the classical or quantum state of the QAM. It only affects the control state by incrementing the program counter by @m{1}.}

@syntax[:name "No-Operation Instruction"]{
    NOP
}

@subsection[:title "Pragmas"]

@p{Programs that process Quil code may want to take advantage of extra
information provided by the programmer. This is especially true when
targeting quantum processors where additional information about the
machine’s characteristics affect how the program will be
processed. Quil supports a @c{PRAGMA} directive to include extra
information in a program which does not otherwise affect execution
semantics.}

@syntax[:name "Pragma"]{
    PRAGMA @ms{Identifier} @rep{@group{@ms{Identifier} @alt @ms{Integer}}} @rep[:max 1]{@ms{String}}
}


@subsection[:title "Extern Functions"]

@p{Programmers and researchers may wish to avail themselves of a rich
vocabulary of analytic and stochastic functions in the designs of
their experiments and algorithms. Quantum control systems or quantum
simulators that consume Quil code may support a variety of functions
that operate on classical data. Quil addresses these cases by
supporting the declaration of @c{EXTERN} functions.}

@subsubsection[:title "Declaring Externs"]

@p{Declaring an identifier to be an extern indicates that the
identifier can appear in @c{CALL} instructions.}

@syntax[:name "Extern Function Declaration"]{
    EXTERN @ms{Identifier}
}

@p{Each @c{EXTERN} identifier must be unique within a program (case-sensitive).
Additionally, @c{EXTERN} identifiers must not conflict with any reserved Quil
keywords or standard gate definitions.}

@subsubsection[:title "Extern Signature Pragmas"]

@p{Under some circumstances it may be desirable to specify the
function signature of an @c{EXTERN} function. Signature declarations are
supplied by way of a pragma.}

@syntax[:name "Extern Signature Pragma"]{
    PRAGMA EXTERN @ms{Identifier} "@ms{Extern Signature}"
}

@syntax[:name "Extern Signature"]{
    @rep[:min 0 :max 1]{@ms{Base Type}} ( @ms{Extern Parameter} @rep[:min 0]{@group{ , @ms{Extern Parameter} }} ) 
}

@syntax[:name "Extern Parameter"]{
    @ms{Identifier} : @rep[:min 0 :max 1]{mut} @ms{Extern Type}
}

@syntax[:name "Extern Type"]{
        @ms{Type}
   @alt @ms{Base Type}[]
}

@p{The "[]" suffix indicates a variable-length array; that is, a parameter
for which there is no length restriction.}

@clist{
DECLARE array1 INTEGER[5]
DECLARE array2 INTEGER[10]
EXTERN foo "(param : INTEGER[])"

# both of these are valid
CALL foo array1
CALL foo array2
}

@p{Type signatures to extern functions require every function parameter to be named. Additionally, the signature must either specify a return type or at least one parameter. }
        
@subsubsection[:title "Call Instructions"]

@p{Declared @c{EXTERN}s may appear in @c{CALL} instructions.  The precise
effect of an @c{EXTERN} function on classical memory is left up to the
implementor. From the perspective of the abstract machine, the effect
of processing a @c{CALL} instruction is to increment the program counter.}

@syntax[:name "Extern Call Instruction"]{
    CALL @ms{Identifier} @rep[:min 1]{@group{@ms{Identifier} @alt @ms{Memory Reference} @alt @ms{Complex}}}
}

@p{Note, for every @c{CALL} instruction, there must be a corresponding @c{EXTERN}
declaration of the same identifier (case-sensitive). There is no restriction
on the order of a @c{CALL} instruction relative to its corresponding @c{EXTERN}
declaration.}

@p{When a function type signature specifies a return type, then calls
to the associated @c{EXTERN} are assumed to write a return value to a
memory reference that appears in the first argument position.
E.g. the following are equivalent:}

@clist{
PRAGMA EXTERN rng "INTEGER (seed : INTEGER)"
EXTERN rng;
DECLARE num INTEGER
... snip ...

CALL rng num 10
}

@p{is equivalent to}

@clist{
PRAGMA EXTERN rng "(out : mut INTEGER, seed : INTEGER)"
EXTERN rng;
DECLARE num INTEGER
... snip ...

CALL rng num 10
}


@subsubsection[:title "Externs in Arithmetic Expressions"]

@p{Extern @c{CALL}s may appear in arithmetic expressions with some
restrictions: the extern MUST have a declared function signature, which
MUST include a return type, and which MUST NOT include any mutable
parameters.}

@p{For example, this is OK:}

@clist{
PRAGMA EXTERN prng "REAL (seed : REAL)"
EXTERN prng;
RX(prng(pi) / 4)
}

@p{But this is not:}

@clist{

PRAGMA EXTERN irng "INTEGER (seed : mut INTEGER)"
EXTERN irng;
EXTERN prng;
DECLARE num INTEGER;

... snip ...

RX(irng(num))       # WRONG: the seed parameter is declared mutable

RZ(prng(33))        # WRONG: we don't know the signature of prng

}


@subsection[:title "File Inclusion"]

@p{One can include a valid Quil file in another valid Quil file by
inclusion.}


@syntax[:name "File Include"]{
    INCLUDE @ms{String}
}

@p{Here, @ms{String} denotes a file name. Implementations processing
Quil must support and document individual file names, and may support
operating-system-dependent file paths.}
