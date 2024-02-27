# `EXTERN` / `CALL` - Support for Arbitrary Instructions that Write to Classical Memory

As of this writing, there [a number of instructions](https://quil-lang.github.io/#6-5Classical-Instructions) supported in the Quil specification that act exclusively on classical memory. These include:

| Unary | Binary   | Ternary |
|-------|----------|---------|
| NOT   | MOVE     | LOAD    |
| NEG   | EXCHANGE | STORE   |
|       | CONVERT  | EQ      |
|       | AND      | GT      |
|       | IOR      | GE      |
|       | XOR      | LT      |
|       | ADD      | LE      |
|       | SUB      |         |
|       | MUL      |         |
|       | DIV      |         |

This proposal intends to define an extension of this current instruction set to support arbitrary instructions on classical memory that different quantum control systems may support.

## Motivation

The primary motivation for this work comes from a few promising error mitigation and tomography techniques that require the generation of random gate parameters. Generating these parameters on the control system, rather than generating and sending them from the client, reduces network overhead and lifts memory constraints that otherwise deter their practical implementation. Below are brief summaries of these techniques along with relevant references.

### Classical Shadow Tomography

Classical shadows provide a means to construct an approximate classical description of a quantum state using "few" measurements of the quantum state. This is useful for construction of quantum feature maps in quantum machine learning applications as well as the estimation of local observables and fidelities in quantum engineering.

* [Predicting Many Properties of a Quantum System from Very Few Measurements](https://arxiv.org/abs/2002.08953)
* [Efficient estimation of Pauli observables by derandomization](https://arxiv.org/abs/2103.07510)
* [Provably efficient machine learning for quantum many-body problems](https://arxiv.org/abs/2106.12627)

### Readout Randomization

This protocol is largely equivalent to that of classical shadow collection. In this case, randomized readout is used to effectively remove coherent readout errors, by transforming them into stochastic Pauli errors.

* [Development and Demonstration of an Efficient Readout Error Mitigation Technique for use in NISQ Algorithms](https://arxiv.org/abs/2303.17741)

### Randomized Compiling

This protocol converts coherent errors into stochastic noise, which reduces the overall unpredictability of errors in quantum algorithms and improves prediction of algorithmic performance.

* [Randomized compiling for scalable quantum computing on a noisy superconducting quantum processor](https://arxiv.org/abs/2010.00215)

## Design

We propose introducing two new instructions to the Quil specification that act _exclusively on classical memory_. These are:

* `EXTERN` - Quil programs may include this instruction to declare they expect the target control system to support some arbitrary instruction on classical memory. Quil programs should invoke this prior to corresponding invocations of the `CALL` Quil instruction. The `EXTERN` instruction defines the type of classical memory of both externed instruction arguments and write destinations. See [Appendix 1](#appendix1) for a discussion of the semantic precedence of "extern".
* `CALL` - Quil programs may invoke aribtrary instructions on classical memory that have been declared with the `EXTERN` instruction. Each invocation of `CALL` must conform to the relevant call signature defined in the `EXTERN` invocation. See [Appendix 2](#appendix2) for a discussion of the semantic precedence of "call". 

Additionally, we explicitly propose extending the set of functions supported within expressions to include those declared by `EXTERN` instructions. Currently, the [2021.1 (DRAFT) specification](https://quil-lang.github.io/#3-2-1Arithmetic-Expressions) does not make explicit the set of functions that may be invoked within expressions, but the [Quil.g4](https://github.com/quil-lang/quil/blob/8ea82bf5bde7e96c49f1e05a819109098640bd4f/grammars/Quil.g4#L134) document explicitly lists `SIN | COS | SQRT | EXP | CIS`.

Please see [Appendix 3](#appendix3) for a discussion of alternatives considered. 

### Grammar 

We propose the following grammar (defined in EBNF) for `EXTERN` and `CALL` instructions.

```ebnf
Extern ::= "EXTERN" , S , FunctionName , Parameters , S , ReturnTypes , (S , FunctionAliasClause)?
FunctionName ::= Identifier |
    Identifier , { ":" , Identifier } (* G14: where ":" acts as a namespace delimiter *)
Parameters ::= "(" , Parameter? , ")" |
    "(" , Parameter , { "," , S? , Parameter } , ")"
Parameter ::= (Identifier, ":" , S)? , ParameterType
ParameterType ::= ("mut" , S)? , ("!")? , BaseType , "[" , Integer , "]" | (* G05: where "mut" indicates the input may be written to by the function implementation *)
    ("mut" , S)? , ("!")? , BaseType , "[]" | (* G11: where a value of "REAL[]", for instance, indicates an array of arbitrary length *)
    ("mut" , S)? , "!" , BaseType (* G10: where a value of "!INTEGER" indicates an immediate (or literal) value rather than memory reference *)
ReturnType ::= (Identifier , S)? , BaseType , "[" , Integer , "]" |
    (Identifier , S)? , BaseType , "[]" (* G11: where a value of "REAL[]", for instance, indicates an array of arbitrary length *)
ReturnTypes ::= ReturnType? |
    "(" , ReturnType? , ")" |
    "(" , ReturnType , { "," , S? , ReturnType } , ")"
FunctionAliasClause ::= "AS" , S , Identifier (* G15: where Identifier serves a function alias *)

Call ::= "CALL" , S , CallDestinations , FunctionName , Arguments
CallDestinations ::= CallDestination | CallDestination , { S , CallDestination }
CallDestination ::= "_" | MemoryReference (* G12: where "_" indicates that the return value may be dropped. *)
Value ::= MemoryReference | Number
Arguments ::= "(" , Value? , ")" |
    "(" , Value , { "," , S? , Value } , ")"
```

where `BaseType`, `MemoryReference`, and `Identifier` are to be interpreted exactly as written in the existing Quil specification and `S` is whitespace. The `Call` and `EXTERN` statements above would be appended to the existing "Classical Memory Instruction" in the Quil specification.

A `Call` instruction is said to _correspond_ to an `EXTERN` instruction iff all of the following are true:

* The `FunctionName` in both instructions are equal (case sensitive).
* The length of `Arguments` in `Call` equals the number of `Parameters` in `EXTERN`.
* The `Type` of each `MemoryReference` in the `Call` `Arguments` are equal to the declared `Type` of all `Parameters` in `EXTERN`.
    * If a `ParameterType` is of the form `BaseType , "[]"`, an argument of `BaseType` and _any_ length is acceptable. Otherwise, the length of the `Type` of the argument and parameter _must match exactly_.
* The length of `CallDestinations` in `Call` equals the number `ReturnTypes` in `EXTERN`.
* The `Type` of each `MemoryReference` in the `Call` `CallDestinations` are equal to the declared `Type` of all `ReturnTypes` in `EXTERN`.
    * The length of the `Type` of any corresponding return value and call destination _must match exactly_.

Additionally, the extension of the set of expression functions implies a small amendment to `Term` in order to accept multiple arguments:

```ebnf
(* we include only additions to the grammar here, Term is otherwise unchanged *)
Term ::= Identifier , "(" , Expression , { ",", S?, Expression } , ")" | (* G17: extending the set of expression functions *)
    Identifier , "(" , Expression? , ")" 
```

#### Clarification of the Grammar and Examples

> G01: The number and type of parameters declared in the `EXTERN` instruction _must_ strictly match the type and length of arguments in a corresponding `Call` instruction.

:white_check_mark:

```quil
DECLARE inputs REAL[10]
DECLARE output REAL[1]
EXTERN MY-FUNCTION(REAL, REAL) REAL
CALL output MY-FUNCTION(inputs[0], inputs[1])
```

:x:

```quil
DECLARE output REAL
EXTERN MY-FUNCTION()
CALL output MY-FUNCTION() # there is no return type corresponding to `output`
```

```quil
DECLARE input REAL
EXTERN MY-FUNCTION()
CALL MY-FUNCTION(input) # there is no parameter corresponding to `input`
```

```quil
DECLARE inputs REAL[10]
DECLARE output REAL[1]
EXTERN MY-FUNCTION(REAL, REAL) REAL
CALL output MY-FUNCTION(inputs[0]) # call lacks argument for second parameter
```

```quil
DECLARE input REAL
DECLARE output INTEGER
EXTERN MY-FUNCTION(REAL) (REAL)
CALL output MY-FUNCTION(param) # output is of incorrect type
```

```quil
DECLARE input INTEGER
DECLARE output REAL
EXTERN MY-FUNCTION(REAL) (REAL)
CALL value MY-FUNCTION(param) # input is of correct type
```

```quil
DECLARE inputs REAL[2]
DECLARE outputs REAL[2]
EXTERN MY-FUNCTION(REAL, REAL) (REAL, REAL)
# don't be fooled, the number of arguments and call destinations do not
# match the number of parameters and return types in the `EXTERN` instruction
CALL outputs MY-FUNCTION(inputs) 
```

> G02: A _corresponding_ `EXTERN` instruction _must_ precede any `Call` instruction.

:white_check_mark:

```quil
DECLARE input REAL[1]
DECLARE output REAL[1]
EXTERN RAND(REAL) REAL
CALL output RAND(input)
```

:x:

```quil
DECLARE input REAL[1]
DECLARE output REAL[1]
CALL output RAND(input) # missing corresponding `EXTERN` instruction
```

```quil
DECLARE input REAL[1]
DECLARE output REAL[1]
CALL output RAND(input)
EXTERN RAND(REAL) REAL # `EXTERN` instruction follows corresponding `Call` instruction
```

> G03: A function may have no arguments and no return types.

:white_check_mark:

```quil
EXTERN MY-FUNCTION()
CALL MY-FUNCTION()
```

```quil
EXTERN MY-FUNCTION() ()
```

> G04: Function arguments and call destinations _may_ elide the index of the memory reference if the memory region is of length 1.

:white_check_mark:

```quil
DECLARE input REAL[1]
DECLARE output REAL[1]
EXTERN MY-FUNCTION(REAL) (REAL)
CALL output MY-FUNCTION(input)
```

```quil
DECLARE inputs REAL[2]
DECLARE outputs REAL[2]
EXTERN MY-FUNCTION(REAL) (REAL) 
CALL outputs[0] MY-FUNCTION(inputs[0])
```

:x:

```quil
DECLARE inputs REAL[2]
DECLARE outputs REAL[2]
EXTERN MY-FUNCTION(REAL) (REAL)
CALL outputs MY-FUNCTION(inputs) # both `inputs` and `outputs` have lengths > 1
```

> G05: All parameters are to be considered read-only by the compiler, except those designated as read-write with the "mut" modifier.

:white_check_mark:

```quil
DECLARE input REAL[1]
DECLARE output REAL[1]
EXTERN MY-FUNCTION(mut REAL)
CALL output MY-FUNCTION(input) # the compiler cannot assume MY-FUNCTION does not change the value of input 
```

```quil
DECLARE input REAL[1]
DECLARE output REAL[1]
EXTERN MY-FUNCTION(REAL)
CALL output MY-FUNCTION(input) # the compiler can assume MY-FUNCTION does not change the value of input 
```

> G06: Functions may return more than two values, in which case their types _must_ be enclosed in parentheses.

:white_check_mark:

```quil
DECLARE input REAL
DECLARE outputs REAL[2]
EXTERN MY-FUNCTION(REAL) (REAL, REAL)
CALL outputs[0] outputs[1] MY-FUNCTION(input)
```

:x:

```quil
EXTERN MY-FUNCTION(REAL) REAL, REAL
```

> G07: Function parameter and return types may be of length > 1.

:white_check_mark:

```quil
DECLARE inputs REAL[3]
DECLARE outputs REAL[3]
EXTERN MY-FUNCTION(REAL[3]) REAL[3]
CALL outputs MY-FUNCTION(inputs)
```

:x:

```quil
DECLARE inputs REAL[9]
DECLARE outputs INTEGER[2]
EXTERN MY-FUNCTION(REAL[3]) (INTEGER[2])
CALL outputs MY-FUNCTION(inputs) # length of `inputs` is incorrect
```

```quil
DECLARE inputs REAL[3]
DECLARE outputs INTEGER[9]
CALL outputs MY-FUNCTION(inputs) # length of outputs is incorrect
```

> G08: Function parameters and return types may be heterogeneous.

:white_check_mark:

```quil
DECLARE real-params REAL[2]
DECLARE integer-param INTEGER
DECLARE octet-param OCTET
EXTERN MY-FUNCTION(REAL, INTEGER, OCTET) (REAL, REAL, INTEGER)
CALL real-params[0] real-params[1] integer-param MY-FUNCTION(real-params[0], integer-param, octet-param) 
```

> G09: Parameters and return types _may_ be named within `EXTERN` declarations. Identifier names must be punctuated with ":".

:white_check_mark:

```quil
DECLARE real-inputs REAL[10]
DECLARE integer-inputs INTEGER[10]
DECLARE output REAL
EXTERN MY-FUNCTION(param1: REAL, param2: INTEGER) (result: REAL)
CALL output MY-FUNCTION(real-inputs[0], integer-inputs[0])
```

```quil
DECLARE input REAL[1]
EXTERN MY-FUNCTION(param1: mut REAL)
CALL MY-FUNCTION(input)
```

The primary goal here is to support more meaningful compilation errors, where they may be useful.

```quil
DECLARE input REAL
DECLARE output REAL
EXTERN LSHIFT(value: REAL, shift: !INTEGER) (shifted-value: REAL)
CALL output LSHIFT(input, 99)
```

Parsing the above program could result in an error such as "the \"shift\" operand of \"LSHIFT\" must be less than 64".

> G10: Parameters may be declared as immediate (or literal) by using the `!` modifier.

The goal here is to improve readability and support the ability of the compiler to require that some function parameters are known at compile time, for validation and optimization.

:white_check_mark:

```quil
DECLARE input REAL
DECLARE output REAL
EXTERN LSHIFT(value: REAL, shift: !INTEGER) (shifted-value: REAL)
CALL output LSHIFT(input, 3)
```

:x:

```quil
DECLARE real-input REAL
DECLARE output REAL
DECLARE integer-input INTEGER
EXTERN LSHIFT(value: REAL, shift: !INTEGER) (shifted-value: REAL)
CALL output LSHIFT(real-input, integer-input) # `shift` parameter declared immediate, but program specifies a memory reference
```

> G11: Input parameters and return types _may_ be of variable length. The corresponding arguments and call destinations _must_ not be indexed.

:white_check_mark:

```quil
DECLARE inputs REAL[10]
DECLARE output REAL
EXTERN CHOOSE-RANDOM(REAL[]) REAL
CALL output CHOOSE-RANDOM(inputs)
```

```quil
DECLARE inputs REAL[10]
DECLARE outputs REAL[2]

EXTERN CHOOSE-2(REAL[]) (REAL[2])
CALL outputs CHOOSE-2(inputs)
```

```quil
DECLARE inputs REAL[10]
DECLARE outputs REAL[3]
EXTERN CHOOSE-RANDOM(REAL[]) REAL[]
CALL outputs CHOOSE-RANDOM(inputs)
```

:x:

```quil
DECLARE inputs REAL[5]
DECLARE outputs REAL[5]
EXTERN MY-FUNCTION(REAL[]) (REAL[])
CALL outputs[0] MY-FUNCTION(inputs[0])
```

> G12: In the case an `EXTERN` declaration specifies multiple outputs, any of those results may be discarded.

:white_check_mark:

```quil
DECLARE inputs REAL[10]
DECLARE outputs REAL[2]
EXTERN CHOOSE-2(REAL[]) (REAL, REAL)
CALL _ outputs[1] CHOOSE-2(inputs)
```

> G13: In the case an `EXTERN` declaration specifies multiple outputs, results cannot be written to the same memory address.

The motivation here is to remove any ambiguity as to which of the return values are assigned to the repeated memory address.

:x:

```quil
DECLARE inputs REAL[10]
DECLARE outputs REAL[2]
EXTERN CHOOSE-2(REAL[]) (REAL, REAL)
CALL outputs[0] outputs[0] CHOOSE-2(inputs)
```

> G14: Function names may be namespaced with ":":

:white_check_mark:

```quil
DECLARE input REAL
DECLARE output REAL
EXTERN MY-NAMESPACE:RAND:UNIFORM(state: REAL) (new_state: REAL)
CALL output MY-NAMESPACE:RAND:UNIFORM(input)
```

> G15: Programs may alias functions in the `EXTERN` instruction:

:white_check_mark:

```quil
DECLARE input REAL
DECLARE output REAL
EXTERN MY-NAMESPACE:RAND:UNIFORM(state: REAL) (new_state: REAL) AS RAND
CALL output RAND(input)
```

> G16: Compilers _must_ support overloading multiple `EXTERN` instructions for `FunctionName` with distinguishable parameter and return type sets. In such a case, any `CALL` instruction must match _exactly one_ corresponding `EXTERN` instruction.

We propose explicit support for overloading because its alternatives are not relevant within the context of a Quil program. Consider, for example, Rust's support for overloading via use of traits[^8][^9] (the concept of a trait is too high-level for Quil) or Common Lisp's support for late binding "overloading" via multimethods[^10] (Quil is not dynamically typed).

Further consider, for example, two uniform random number generators, one of which supports `REAL`s and the other which supports `INTEGER`s. These could be named `RAND-REAL` and `RAND-INTEGER`, but that is somewhat verbose and redundant considering the `EXTERN` instruction contains the return types. We, therefore, favor explicit support for overloading in this RFC.

:white_check_mark:

```quil
DECLARE real-param REAL[1]
DECLARE integer-param INTEGER[1]
EXTERN RAND(REAL) REAL
EXTERN RAND(INTEGER) INTEGER
EXTERN RAND(REAL) INTEGER

CALL real-param RAND(real-param)
CALL integer-param RAND(integer-param)
CALL integer-param RAND(real-param)
```

:x:

```quil
DECLARE real-param REAL[1]
DECLARE integer-param INTEGER[1]
EXTERN RAND(REAL) REAL
EXTERN RAND(REAL[1]) REAL # Parameter type sets are indistinguishable
CALL real-param RAND(real-param)
```

```quil
DECLARE integer-param INTEGER[1]
EXTERN RAND(REAL) REAL 
CALL integer-param RAND(integer-param) # type of `integer-param` is incorrect
```

Consider the following relationships between parameter and return type sets:

* $BaseType! = BaseType![1] \subset BaseType = BaseType[1] \subset BaseType[]$
* $BaseType![Integer] \subset BaseType[Integer] \subset BaseType[]$

We provide the following requirements for resolving overloaded functions where the number of parameters and return types are equal and of the same `BaseType`:

1. More specific types take precedence over less specific types (ie any type takes precedence over a type of which it is a subset).
2. Any parameter takes precedence over a parameter to its right.
3. Any parameter takes precedence over a return type.
4. Declared signatures with equivalent type sets are strictly forbidden. This applies regardless of textual representation.

:white_check_mark:

```quil
DECLARE inputs REAL[10]
DECLARE outputs REAL[10]
EXTERN REAL MY-FUNCTION(REAL)
EXTERN REAL[] MY-FUNCTION(REAL[])
EXTERN REAL MY-FUNCTION(!REAL)

CALL outputs[0] MY-FUNCTION(inputs[0]) # corresponds to first declaration
CALL outputs MY-FUNCTION(inputs) # corresponds to second declaration
CALL outputs[0] MY-FUNCTION(1.2345) # corresponds to third declaration
```

```quil
DECLARE input1 REAL[1]
DECLARE input2 REAL[1]
DECLARE inputs REAL[10]
DECLARE output REAL[1]
EXTERN REAL MY-FUNCTION(REAL, REAL[])
EXTERN REAL MY-FUNCTION(REAL[], REAL)

CALL output MY-FUNCTION(input1, input2) # corresponds to first declaration (rule 2) 
CALL output MY-FUNCTION(inputs, input2) # corresponds to second declaration
```

```quil
DECLARE input REAL[1]
DECLARE output REAL[1]
DECLARE outputs REAL[10]
EXTERN REAL[] MY-FUNCTION(REAL)
EXTERN REAL MY-FUNCTION(REAL[])

CALL output MY-FUNCTION(input) # corresponds to first declaration (rule 3)
CALL outputs MY-FUNCTION(input) # corresponds to second declaration
```

:x:

```quil
EXTERN REAL MY-FUNCTION(REAL)
EXTERN REAL MY-FUNCTION(REAL[1]) # this conflicts with the above declaration (rule 4)
```

> G17: Extern declarations _may_ extend the set of functions invoked within Quil expressions _iff_ they include a _single_ return value.

This rule makes no futher explicit restriction on the return type of `EXTERN` functions invoked within expressions. However, implementations may reject invocation of an `EXTERN` function for reasons not explicitly mentioned in this RFC, including reasons concerning the function return type and the expression evaluation context.

We find this omission to be most consistent with the Quil specification in its current form, where there is no explicit restriction on memory region type for memory references within Quil expressions. We also note the inclusion of `Complex` in the list of possible terms of an expression and the absence of support for complex valued memory regions. There is no bijective mapping from `EXTERN` function return types to expression evaluation types.

Additionally, with respect to bit and octet return types, note:

* A declared memory alias must point to a memory region (offset or otherwise) that has a memory size greater than or equal to the type of the declared memory alias. We can assume integers and real numbers exceed the size of a single bit or octet.
* The `CONVERT` instruction does not accept either a destination or source of type octet.

We, therefore, cannot make either of the following statements:

* Return types of type `BIT` or `OCTET` shall be bitcast to integers or real numbers consistent with aliased memory. 
* Return types of type `BIT` or `OCTET` shall be converted to integers or real numbers consistent with the `CONVERT` instruction.

This RFC, therefore, defers to implementations to restrict invocation of `EXTERN` functions within expressions as they find most appropriate.

:white_check_mark:

```quil
EXTERN MY-FUNCTION(REAL) REAL
DECLARE param REAL
RZ(MY-FUNCTION(param[0])) 0
```

```quil
EXTERN MY-FUNCTION(REAL, INTEGER) REAL
DECLARE real-param REAL
DECLARE integer-param REAL
RZ(MY-FUNCTION(real-param[0], integer-param[0])) 0
```

:x:

```quil
EXTERN MY-FUNCTION(REAL) REAL[2]
DECLARE param REAL
RZ(MY-FUNCTION(param[0])) 0 # return value is of length 2
```

```quil
EXTERN MY-FUNCTION(REAL) REAL[2]
DECLARE param REAL
RZ(MY-FUNCTION(param[0])[0]) 0 # cannot index into expression result
```

```quil
EXTERN MY-FUNCTION(REAL) (REAL, REAL)
DECLARE real-param REAL
DECLARE integer-param REAL
RZ(MY-FUNCTION(real-param[0])) 0 # two return values here
```

### Unspecified

This RFC leaves the following behavior unspecified:

* Where classical functions are evaluated (ie client, compiler, or global / local control systems).
* The behavior of compilers targeting hardware backends that do not support the `EXTERN` instructions.
* When invocation of single return value `EXTERN` functions is acceptable within expressions.

## Resolution

After discussion in [quil-lang/quil#69](https://github.com/quil-lang/quil/pull/69), we have agreed to pursue the following additions to the Quil grammar:

```ebnf
<Extern> := 'EXTERN'  <Identifier>

<ExternParameter> := (<Identifier> s* ':' s*)? 'mut'? s+ <Base Type> ("[" , Integer? , "]")?
<ExternParameters> := <ExternParameter> | <ExternParameter> s* ',' s* <ExternParameters>
<TypeString> := '"'(s* <BaseType>)? s* <Identifier> s* '(' s* <ExternParameters>? s* ')' s*'"

<ExternArgument> := <Identifier> | <Memory Reference> | <Complex>
<Call> := 'CALL' <Identifier> <ExternArgument>*
```

### The Type String Pragma

Currently, the specification does not require the program to specify a type string for all extern functions. A program _may_ declare extern type strings under the following circumstances by a designated pragma statement of the form:

```
PRAGMA EXTERN <TypeString>
```

### Return Types and Quil Expressions

A `<TypeString>` may include a return `<BaseType>`, which a program may include in:

1. `CALL` instructions, where the first argument must be a memory reference of length 1 and the same `<BaseType>`.
2. Quil expressions.

The specification supports such return types only in cases where:

1. The extern function is read-only; it does not contain mutable parameters.
2. There is an associated pragma type string declaration.

### Overloading

If a program overloads an extern function name (i.e. there are several type strings declared for one extern function name), consider the following relationships between parameter and return type sets:

* $BaseType \subset BaseType[1] \subset BaseType[]$
* $BaseType[Integer] \subset BaseType[]$

If a `CALL` instruction matches two or more extern function type strings, the compiler must compile the extern function with the highest precedence according to the following rules:

1. More specific types take precedence over less specific types (i.e. any type takes precedence over a type of which it is a subset).
2. Any parameter takes precedence over a parameter to its right. Any parameter takes precedence over the return type `<BaseType>`.
3. Declared signatures with equivalent type sets are strictly forbidden. This applies regardless of textual representation. Note, a parameter of type `mut <Base Type>` is considered equivalent to type `<Base Type>`.

### Issues dropped from the RFC

* Function namespacing and aliasing (G14 and G15). Those are definitel:w
y nice-to-haves and what we have here is forward compatible with adding those in the future.
* Because functions with a return type must exclusivey have read-only parameters, there is no sense in dropping a returned value. As such, dropping values via `_` is unsupported (G12).

## <a name="appendix1"></a>Appendix 1: Semantic Precedent for `EXTERN`

`extern` is a common keyword in several well known classical computing contexts, as well as at least one other quantum computing IR, OpenQASM 3.0.

Typically, `extern` connotes the availability of a function or variable defined _outside_ the scope of the current translation unit or, conversely, making a definition inside the current translation unit available to external translation units, across either some language specific or foreign function interface.

In this RFC, we petition that `EXTERN` imply the availability of a classical instruction on the quantum control system.Similar to the `extern` keyword in strongly typed languages, such as C++ and Rust, the `EXTERN` instruction we propose declares the function identifier, its parameters, and return types.

### C / C++

In C and C++ `extern` serves as a storage class specifier for external linkage, modifying the visibility of variables and functions between translation units[^1][^2][^3]. 

`main.cpp`

```cpp
#include <iostream>
#include "name.h"

int main () {
    extern std::string name;
    std::cout << "Hello, " + name << std::endl;
}
```

`name.h`

```cpp
#include <iostream>

extern std::string name;
```

`name.cpp`

```cpp
#include <iostream>

std::string name = "whoever you are."
```

`extern` is also used in declarations using the linkage conventions of another language, where the linked declarations are defined in a separate translation unit:

```cpp
extern "C" int printf(const char *fmt, ...);
```

### Rust

In Rust "extern" is used within the context of foreign function interfaces (FFI), both[^4]:

1. to declare foreign function interfaces that Rust code may invoke.
2. to define Rust functions that may be linked from foreign code.

_Note, Rust formerly required the use of `extern crate` for linking / importing Rust dependencies within a project; this is no longer required with few exceptions[^5]._

#### Example 1

```rs
#[link(name = "my_c_library")]
extern "C" {
    fn my_c_function(x: i32) -> bool;
}
```

#### Example 2

```rs
#[no_mangle]
pub extern "C" fn callable_from_c(x: i32) -> bool {
    x % 3 == 0
}
```

### OpenQASM 3.0

Open QASM 3.0 has introduced support for extern function calls. Of note, as of this writing[^6], extern functions:

* "are declared by giving their signature."
* "can take of any number of arguments whose types correspond to the classical types of OpenQASM."
* "are invoked using the statement `name(inputs)`."
* "are not required to be idempotent."
* "run on a global processor concurrently with operations on local processors, if possible."

Note, this description is largely consistent with that of this proposed specification, _except_ this proposal does not specify where `EXTERN` functions run. We also use `CALL destination name(inputs)` semantics, rather than `destination = name(inputs)`.

## <a name="appendix2"></a>Appendix 2: Semantic Precedent for `CALL` 

### LLVM

In LLVM IR, `call` "represents a simple function call"[^7], the result of which can be assigned to an SSA value. These call statements may be used on functions regardless of their linkage type[^11].

#### Examples

`example.ll`

```llvm
define i32 @_Z3addii(i32 noundef %0, i32 noundef %1) #4 {
  // ...
  ret i32 %7
}

define i32 @main() #5 {
  %1 = call i32 @_Z3addii(i32 noundef 20, i32 noundef 30)
  ret i32 0
}
```

## <a name="appendix3"></a>Appendix 3: Alternatives Considered

### `DECLARE` in place of `EXTERN`

Because `EXTERN` _declares_ a function signature, we may consider overloading the existing `DECLARE` instruction:

```quil
DECLARE RAND(REAL) REAL
DECLARE current_value REAL[1]
CALL current_value RAND(current_value)
```

The main disadvantage of this approach is that overloaded function declarations less clearly differentiate from program memory regions. We could disambiguate by introducing, instead, `DECLARE-INSTRUCTION`, `DECLARE-EXPRESSION`, or `DEFINSTRUCTION`, however, the `EXTERN` instruction more clearly insinuates a boundary between the Quil program and the classical control system that may, or may not, support the declaration. 

### `INVOKE` in place of `CALL`

In addition to `call`, LLVM also has an invoke[^12] instruction.

> This instruction is designed to operate as a standard ‘call’ instruction in most regards. The primary difference is that it establishes an association with a label, which is used by the runtime library to unwind the stack.

There is currently no notion of a runtime exception in Quil, much less exception handling. As such, we can draw a weaker analogy to the LLVM `invoke` instruction than `call`. This is only analogy, but the decision here is semantic and, perhaps, the best we can do.

### Direct reference to instruction rather than `CALL`

We could drop the `CALL` instruction entirely:

```quil
EXTERN RAND(REAL) REAL
DECLARE current_value REAL
RAND(current_value) current_value
```

This is less verbose, but program structure is perhaps a bit more ambiguous. It is less clear that `RAND` is not explicit in the Quil specification. Additionally, this introduces an issue if an `EXTERN` declaration extends the call signature of an existing Quil instruction:

```quil
EXTERN MOVE(REAL, REAL) REAL
DECLARE params REAL[10]
DECLARE current_value REAL
MOVE(params[0], params[1]) current_value
```

Even more subtly, declaration of function names impede upon the namespace of instructions that the Quil specification may add in the future.

The `CALL` instruction clearly disambiguates instruction extensions from those that are expicit in the Quil specification, thereby providing a clean namespace into which functions may be declared within a program and providing a clearer means for compilers and backends to evaluate support for non-explicitly supported instructions.

## Authorship

_This document was originally composed by the software engineering team at Rigetti Computing October 2023._

## Footnotes and references

[^1]: The Standard C N3096. ISO/IEC, April 1, 2023. https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3096.pdf. PDF download.
[^2]: "C++ Language: extern (C++)". Microsoft Learn, December 2, 2021. https://learn.microsoft.com/en-us/cpp/cpp/extern-cpp?view=msvc-170. October 11, 2023.
[^3]: "extern Storage-Class Specifier". Microsoft Learn, August 2, 2021. https://learn.microsoft.com/en-us/cpp/c-language/extern-storage-class-specifier?view=msvc-170. October 11, 2023.
[^4]: "Keyword extern". The Rust Standard Library. https://doc.rust-lang.org/std/keyword.extern.html. October 11, 2023.
[^5]: "Path and module system changes". The Rust Edition Guide. https://doc.rust-lang.org/edition-guide/rust-2018/path-changes.html#an-exception. October 11, 2023.
[^6]: "Extern function calls". OpenQASM Live Specification. https://openqasm.com/language/classical.html#extern-function-calls. October 11, 2023.
[^7]: "LLVM Languge Reference Manual". LLVM Compiler Infrastructure, October 11, 2023. https://llvm.org/docs/LangRef.html#i-call. October 11, 2023.
[^8]: "Operator Overloading". Rust By Example. https://doc.rust-lang.org/rust-by-example/trait/ops.html. October 11, 2023.
[^9]: Turon, Aaron. "Abstraction without overhead: traits in Rust". Rust Blog, May 11, 2015. https://blog.rust-lang.org/2015/05/11/traits.html#the-many-uses-of-traits. October 11, 2023.
[^10]: "MultiMethods". April 30, 2013. https://wiki.c2.com/?MultiMethods. October 11, 2023.
[^11]: "LLVM Languge Reference Manual". LLVM Compiler Infrastructure. https://llvm.org/docs/LangRef.html#linkage-types. October 11, 2023.
[^12]: "LLVM Languge Reference Manual". LLVM Compiler Infrastructure. https://llvm.org/docs/LangRef.html#invoke-instruction. October 11, 2023.
