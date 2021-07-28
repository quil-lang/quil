@section[:title "Structure of a Quil Program"]

@subsection[:title "Meta-Syntax"]

@p{In order to describe the syntax and semantics of a Quil program, we
use a syntax that is similar to @emph{extended Backus-Naur form},
though we deviate occasionally for convenience. While Quil's grammar
is context-free, specifying it is somewhat laborious due to the
possibility of identifiers being able to be used in some syntactic
constructs and other times not. As such, for syntactic constructs
which permit identifiers, we would need one set of productions, and
for those which don't, we would need another (nearly identical) set.}

@p{In order to avoid this laborious repetition, we write productions
of the grammar to always include sometimes forbidden elements, and
instead specify in the surrounding text the context in which those
elements are or are not allowed.}

@aside{When writing a recursive-descent parser, one would likely use
contextual flags to allow or disallow certain parsing rules, like
flags indicating the permission or lack thereof to use
identifiers. This leads to considerably shorter and clearer code.}

@subsection[:title "Syntactic Rudiments"]

@p{Before proceeding to describe each component of a Quil program, it
will be useful to establish a few common pieces of syntax which will
be used later.}

@p{The Quil language is represented as text. The text must be encoded
as UTF-8. The standard language constructs of Quil are all expressible
in the ASCII subset of UTF-8, but user programs may use codepoints
outside of UTF-8.}

@p{Except when noted explicitly, whitespace has no significance and is
ignored. Tokens can be separated by arbitrary amounts and kinds of
whitespace.}

@p{A newline is a single ASCII newline.}

@syntax[:name "Newline"]{
@syntax-descriptive{ASCII 10}
}

@p{A @emph{terminator} is used to terminate most components of a Quil
program syntactically.}

@syntax[:name "Terminator"]{
     @ms{Newline}
@alt ;
@alt @syntax-descriptive{End of File}
}

@p{An @emph{indent} is defined as exactly four spaces at the start of
a line. Indents in Quil programs can only happen following a newline.}

@syntax[:name "Indent"]{
    @ms{Newline}
    @rep[:min 4 :max 4]{@syntax-descriptive{ASCII 32}}
}

@p{Note that since indents must follow a newline, we include the
newline as a part of the syntax definition of an indent.}

@p{Non-negative integers are written as usual. Leading zeros do not
change the interpretation of these numeric literals.}

@syntax[:name "Integer"]{
    @rep[:min 1]{[0-9]}
}

@p{Real numbers are written in usual floating-point number syntax.}

@syntax[:name "Real"]{
  @rep[:min 0 :max 1]{@ms{Integer}}
  @rep[:min 0 :max 1]{.}
  @ms{Integer}
  @rep[:min 0 :max 1]{
    @group{
      @group{e @alt E}
      @rep[:min 0 :max 1]{@group{- @alt +}}
      @ms{Integer}
    }
  }
}

@p{Complex numbers are an extension of this.}

@syntax[:name "Complex"]{
       @ms{Integer}
  @alt @ms{Real}
  @alt @rep[:min 0 :max 1]{@ms{Real}} i
  @alt pi
}

@p{Strings are characters bounded by double-quotation mark characters
'@c{"}'. If a double-quotation mark should be used within the string,
it must be escaped with a backslash, like so: '@c{\"}'. Similarly, if
a backslash should be used within a string, it must be escaped, like
so: '@c{\\}'.}

@syntax[:name "String"]{
    "@rep{@group{[^\"] @alt \" @alt \\}}"
}

@p{Identifiers in Quil are alphanumeric Latin characters, along with
hyphens and underscores. Identifiers cannot start or end with a
hyphen '@c{-}'.}

@syntax[:name "Identifier"]{
         [A-Za-z_]
    @alt [A-Za-z_]@rep{[A-Za-z0-9\-_]}[A-Za-z0-9_]
}

@p{However, the following are @emph{not} identifiers:

@clist{
i pi
}
}

@p{The following identifiers are reserved (as Quil keywords):

@clist{
ADD AND AS CONTROLLED CONVERT DAGGER DECLARE DEFCIRCUIT DEFGATE DIV EQ
EXCHANGE FORKED GE GT HALT INCLUDE IOR JUMP JUMP-UNLESS JUMP-WHEN
LABEL LE LOAD LT MATRIX MEASURE MOVE MUL NEG NOP NOT OFFSET PAULI-SUM
PERMUTATION PRAGMA RESET SHARING STORE SUB WAIT XOR
}
}

@p{The following identifiers are also reserved (for standard gate
definitions):

@clist{
CAN CCNOT CNOT CPHASE CPHASE00 CPHASE01 CPHASE10 CSWAP CZ H I ISWAP
PHASE PISWAP PSWAP RX RY RZ S SWAP T X XY Y Z
}
}

@p{A @emph{formal parameter} is an identifier prefixed with a percent
sign, with no whitespace in between.}

@syntax[:name "Parameter"]{
    %@ms{Identifier}
}

@p{Multiple parameters may be separated by commas.}

@syntax[:name "Parameters"]{
    @rep[:min 0 :max 1]{
        @group{
            @ms{Parameter}
            @rep[:min 0]{
                @group{
                , @ms{Parameter}
                }
            }
        }
    }
}

@p{A @emph{formal argument} is simply an identifier.}

@syntax[:name "Argument"]{
    @ms{Identifier}
}

@p{Several formal arguments are separated by spaces, unlike
parameters.}

@syntax[:name "Arguments"]{
    @rep[:min 1]{@ms{Argument}}
}

@subsubsection[:title "Arithmetic Expressions"]

@p{Frequently, various kinds of arithmetic expressions are needed. A
simple and not unusual grammar defines these arithmetic expressions.}

@p{Depending on the specific grammatical context, arithmetic
expressions may or may not include references to formal parameters or
memory segments. Below, we define the grammar as including all of
these things, but certain contexts may disallow either or both of
them.}

@p{Precedence of binary operators is defined in the following
order of descending tightness. Along with the operators are their
associativity directions.

@clist{
^     RIGHT
* /   LEFT
+ -   LEFT
}
}

@syntax[:name "Expression"]{
         @ms{Expression} + @ms{Expression}
    @alt @ms{Expression} - @ms{Expression}
    @alt @ms{Expression} * @ms{Expression}
    @alt @ms{Expression} / @ms{Expression}
    @alt @ms{Expression} ^ @ms{Expression}
    @alt @ms{Term}
}

@syntax[:name "Term"]{
         - @ms{Expression}
    @alt @ms{Identifier} ( @ms{Expression} )
    @alt ( @ms{Expression} )
    @alt @ms{Complex}
    @alt @ms{Parameter}
    @alt @ms{Memory Reference}
    @alt @ms{Identifier}
}

@p{A @emph{constant expression} is an arithmetic expression which does
not contain any parameters, memory references, or identifiers.}

@p{We use comma-separated lists of arithmetic expressions frequently
enough to warrant their own production.}

@syntax[:name "Expression List"]{
    @ms{Expression}
    @rep[:min 0]{
        @group{
            ,
            @ms{Expression}
        }
    }
}

@subsection[:title "Main Program Elements"]

@p{A Quil program consists of declarations, directives, and
instructions.}

@syntax[:name "Program"]{
@rep{@ms{Program Element}}
}

@syntax[:name "Program Element"]{
     @ms{Declaration} @group{@ms{Newline} @alt @syntax-descriptive{End of File}}
@alt @ms{Directive} @ms{Terminator}
@alt @ms{Instruction} @ms{Terminator}
}

@p{A @emph{declaration} typically specifies the existence of a named
object, like classical memory registers.}

@syntax[:name "Declaration"]{
     @ms{Gate Definition}
@alt @ms{Circuit Definition}
@alt @ms{Classical Memory Declaration}
}

@p{A @emph{directive} specifies information to software processing
Quil, such as the @quil{INCLUDE} directive for including files.}

@syntax[:name "Directive"]{
     @ms{Pragma}
@alt @ms{Label}
@alt @ms{File Include}
}

@p{An @emph{instruction} is an actual run-time executable effect.}

@syntax[:name "Instruction"]{
     @ms{Gate Application}
@alt @ms{Measurement Instruction}
@alt @ms{Circuit Application}
@alt @ms{Classical Memory Instruction}
@alt @ms{Reset Instruction}
@alt @ms{Wait Instruction}
@alt @ms{Branch Instruction}
@alt @ms{No-Operation Instruction}
@alt @ms{Halt Instruction}
}

@subsection[:title "Comments"]

@p{Comments may exist syntactically, but do not change the semantics
of the program. Text including and following the '@c{#}' character are ignored up
to the end of the line.}

@syntax[:name "Comment"]{
#@rep{[^\n]}
}

@p{There are no block comments.}
