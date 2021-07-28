@section[:title "Classical Control"]

@subsection[:title "Halting the Program"]

@p{The program is @emph{halted} if it is no longer executing. This may
happen under one of three conditions:

@itemize{
    @item{The @c{HALT} instruction was executed,}
    @item{The program counter reaches @m{\vert P\vert}, or}
    @item{An implementation-dependent error condition has happened.}
}}

@syntax[:name "Halt Instruction"]{
    HALT
}

@p{Error conditions may happen, for instance, when a division-by-zero
occurs. There may be other ways in which an implementation may error.}

@subsection[:title "Program Labels and Branching"]

@p{Run-time control flow is achieved through a variety of branching
instructions. Each branching instructions requires a target place in
the program to jump to. These target places are denoted by
@emph{labels}:}


@syntax[:name "Jump Target"]{
    @@@ms{Identifier}
}
@syntax[:name "Label"]{
    LABEL @ms{Jump Target}
}

@p{A label (resp. jump target) is said to be at position @m{p < \vert
P\vert} if the first instruction that follows the label (resp. jump
target's label) is the @m{p}th instruction (zero-indexed). If no
instruction follows the label, then it is said to be a @emph{halting
label at position @m{\vert P\vert}}.}

@p{Each @c{LABEL} jump target name must be unique. It is an error to
have a duplicate jump target name in a program.}

@aside{Jump target names may be duplicated across (but not within)
@c{DEFCIRCUIT} bodies if and only if those names don't appear globally
within the program in which the @c{DEFCIRCUIT} is expanded. Names may
be duplicated because they are made unique when the circuit is
expanded.}

@p{One may transfer control to the @m{p}th position of a program by
using a @c{JUMP} instruction targeting a label at position @m{p}.}

@syntax[:name "Unconditional Branch Instruction"]{
    JUMP @ms{Jump Target}
}

@p{One may transfer control to the @m{p}th position of a program
conditional on a given memory reference using one of the following two
instructions:}

@syntax[:name "Conditional Branch Instruction"]{
         JUMP-WHEN @ms{Jump Target} @ms{Memory Reference}
    @alt JUMP-UNLESS @ms{Jump Target} @ms{Memory Reference}
}

@p{The @c{JUMP-WHEN} (resp. @c{JUMP-UNLESS}) instruction branches if
and only if @ms{Memory Reference} references a @c{BIT}-typed value
that is non-zero (resp. exactly zero).}

@p{Together, these form the branching instructions.}

@syntax[:name "Branch Instruction"]{
         @ms{Unconditional Branch Instruction}
    @alt @ms{Conditional Branch Instruction}
}
