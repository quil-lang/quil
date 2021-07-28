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

@subsection[:title "File Inclusion"]

@p{One can include a valid Quil file in another valid Quil file by
inclusion.}

@syntax[:name "File Include"]{
    INCLUDE @ms{String}
}

@p{Here, @ms{String} denotes a file name. Implementations processing
Quil must support and document individual file names, and may support
operating-system-dependent file paths.}
