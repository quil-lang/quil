@section[:title "Circuits"]

@subsection[:title "Circuit Syntax"]

@p{Circuits in Quil are parameterized templates of instructions that
can be filled in with parameters and arguments. Circuit applications
within a program are expanded according to the circuit's definition in
full before a Quil program is executed.}

@aside{Circuits are intended to be used more as macros than as
specifications for general quantum circuits. Indeed, @c{DEFCIRCUIT} is
very limited in its expressiveness, only performing argument and
parameter substitution. It is included mainly to help with the
debugging and human readability of Quil code. Circuits in Quil are
more like C preprocessor macros than they are like functions. The QAM
has no notion of a circuit as a part of its semantics; circuits are
simply notational conveniences.}

@p{A circuit is defined with the @c{DEFGATE} directive.}

@syntax[:name "Circuit Definition"]{
DEFCIRCUIT @ms{Identifier}
@rep[:min 0 :max 1]{@group{(@ms{Parameters})}}
@rep[:min 0 :max 1]{@ms{Arguments}}
:
@ms{Indent}@rep[:min 1]{@ms{Circuit Line}}@group{@ms{Newline} @alt @syntax-descriptive{End of File}}
}

@p{Within the circuit body, we can write any Quil instruction,
allowing for the named parameters and arguments to show up as
instruction parameters or arguments.}

@syntax[:name "Circuit Line"]{
    @ms{Indent} @ms{Instruction} @rep[:min 0]{@group{;@ms{Instruction}}}
}

@p{A circuit may be used similarly to a gate:}

@syntax[:name "Circuit Application"]{
    @ms{Identifier}
    @rep[:min 0 :max 1]{
        @group{
            (
                @rep[:min 0 :max 1]{@ms{Expression List}}
            )
        }
    }
    @rep[:min 1]{@group{@ms{Formal Qubit} @alt @ms{Memory Reference}}}
}

@subsection[:title "Circuit Expansion"]

@p{Circuits are expanded recursively, outside in. Circuits may not be
self-recursive or mutually recursive. These circuits are invalid
because they exhibit different kinds of non-terminating recursion.}

@clist{
DEFCIRCUIT FOO:
    BAR

DEFCIRCUIT BAR:
    FOO

DEFCIRCUIT BAZ:
    BAZ
}

@p{Labels that are declared within the body of a @c{DEFCIRCUIT} are
unique to each of that circuit's expansions. While it is possible to
jump out of a @c{DEFCIRCUIT} to a globally declared label, it is not
possible to jump inside of one.}

@p{Consider the following two @c{DEFCIRCUIT} declarations and their
instantiations. Note the comments on correct and incorrect usages of
@c{JUMP}.

@clist{
DEFCIRCUIT FOO:
    LABEL @@FOO_A
    JUMP @@GLOBAL   # (A) valid, global label
    JUMP @@FOO_A    # (B) valid, local to FOO
    JUMP @@BAR_A    # (C) invalid

DEFCIRCUIT BAR:
    LABEL @@BAR_A
    JUMP @@FOO_A    # (D) invalid

LABEL @@GLOBAL
FOO
BAR
JUMP @@FOO_A        # (E) invalid
JUMP @@BAR_A        # (F) invalid
}

Line (A) is valid because it is a jump from a circuit to a global
label called @c{@@GLOBAL}.

Line (B) is valid because it is a jump to a label within the same
circuit body.

Line (C) is invalid because it is erroneously attempting to jump to a
different circuit body.

Line (D) is invalid for the same reason as line (C); it is an
erroneous attempt to jump from one local circuit body to another.

Lines (E) and (F) are both invalid because they are attempts to jump
into a local circuit definition.
}
