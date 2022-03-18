@section[:title "History and Changes"]

@subsection[:title "A History of Quil"]

@p{In 2016, at Rigetti Computing, Quil was defined in an @link[:target
"https://arxiv.org/abs/1608.03355"]{arXiv paper} entitled "A Practical
Quantum Instruction Set Architecture" by R. Smith, M. Curtis, and
W. Zeng.}

@p{In 2018, at Rigetti Computing, R. Smith began work to amend Quil to
include a memory model. Its definition lived in a new Git repository
containing the Quil specification.}

@p{In 2019, at Rigetti Computing, Quil's specification was rewritten
in Markdown format by S. Heidel and other Rigetti-based contributors
for easier consumption. S. Heidel also contributed an ANTLR grammar
for Quil.}

@p{In 2019, at Rigetti Computing, an extension of Quil for
time-domain, pulse-level control was developed by S. Heidel, E. Davis,
and other Rigetti-based contributors. This was code-named "Quilt" but
was later finalized as "Quil-T". Quil-T lived as a proposed extension
(called an "RFC") in the Git repository.}

@p{In 2019, at Rigetti Computing, an addition to Quil to allow gates
to be defined as exponentiated Pauli sums was developed by
E. Peterson. This was code-named "defexpi" but was later finalized as
syntax @c{DEFGATE AS PAULI-SUM}. This syntax lived as an RFC in the
Git repository.}

@p{In 2021, R. Smith (whose affiliation since changed to HRL
Laboratories) and Rigetti Computing set up the @emph{Quil-Lang} GitHub
organization for shared and collaborative governance of the definition
of Quil as well as its @emph{de facto} standard software tooling.}

@p{In 2021, R. Smith rewrote the specification in a custom format to
allow rendering as an HTML page. The specification was synthesized
from all previous official sources on the language.}

@p{Quil's specification, as well as software implementations, have
benefited greatly from their international userbase. Quil has also
benefited from a diverse ecosystem of other quantum computing
languages, such as OpenQASM, Quipper, Q#, and QCL.}

@subsection[:title "Changes"]

@p{@emph{This document only tracks changes since its conception.}}

@p{
    @itemize{
        @item{July 2021: Document created.}
    }
    @itemize{
        @item{March 2022: Sequence gate definitions are added to Quil's specification. (Parker Williams, HRL)}
    }
}
