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

This proposal intends to define an extension of this current instruction set to support arbitrary instructions on classical memory that may be supported by quantum control systems.

## Motivation

The primary motivation for this work comes from a couple of promising error mitigation techniques that require the generation of random gate parameters. Below are a brief summary of these error mitigation techniques along with relevant references.

### Readout Randomization

### Randomized Compiling

## Design

We propose introducing two new instructions to the Quil specification that act _exclusively on classical memory_. These are:

* `EXTERN` - Quil programs may include this instruction to declare they expect the target control system to support some arbitrary instruction on classical memory. Quil programs should invoke this prior to corresponding invocations of the `CALL` Quil instruction. The `EXTERN` instruction defines the type of classical memory of both externed instruction arguments and write destination.
* `CALL` - Quil programs may invoke aribtrary instructions on classical memory that have been declared with the `EXTERN` instruction. Each invocation of `CALL` must conform to the relevant call signature defined in the `EXTERN` invocation.

The syntax of these instructions are defined under [Syntax](### Syntax).

### Syntax

We propose the following syntax for `EXTERN` and `CALL` instructions.

```
EXTERN <Identifier>(<Type*>(, <Type*>)*) (<Type>(, <Type>)

CALL (<typeXY>(, <typeXY>)) <Identifier>(<typeXY>(, <typeXY>)*)
```

* An `EXTERN` instruction _must_ precede any `CALL` to the corresponding `<Identifier>`.

:white_check_mark:

```quil
DECLARE current_value REAL[1]
EXTERN LSFR(REAL) REAL
CALL current_value LSFR(current_value)
```

:x:

```quil
DECLARE current_value REAL[1]
CALL current_value LSFR(current_value)
```

:x:

```quil
DECLARE current_value REAL[1]
CALL current_value LSFR(current_value)
EXTERN LSFR(REAL) REAL
```

* The number and type of parameters declared in the `EXTERN` instruction _must_ strictly match the type and length of arguments in the corresponding `CALL` instructions.

:white_check_mark:

```quil
DECLARE params REAL[10]
DECLARE current_value REAL[1]
EXTERN MYFUNCTION(REAL, REAL) REAL
CALL params[2] MYFUNCTION(params[0], params[1])
```

:x:

```quil
DECLARE params REAL[10]
DECLARE current_value REAL[1]
EXTERN MYFUNCTION(REAL, REAL) REAL
CALL params[1] MYFUNCTION(params[0])
```

* Input parameters _may_ be of variable length, but outputs must be of predeterimined length.

:white_check_mark:

```quil
DECLARE params REAL[10]
DECLARE max_value REAL[1]
EXTERN MAX(REAL*) REAL
CALL max_value MAX(params)
```

:white_check_mark:

```quil
DECLARE params REAL[10]
DECLARE top_values REAL[2]
EXTERN TOP2(REAL*) (REAL, REAL)
CALL top_values[0] top_values[1] TOP2(params)
```

:x:

```quil
DECLARE params REAL[10]
DECLARE n INTEGER
EXTERN TOP_N(REAL*, INTEGER) REAL*
CALL max_value TOP_N(params, n)
```

* In the case an `EXTERN` declaration specifies multiple outputs, results cannot be written to the same memory address.

:x:

```quil
DECLARE params REAL[10]
DECLARE top_values REAL[2]
EXTERN MAX2(REAL*) (REAL, REAL)
CALL top_values[0] top_values[0] MAX2(params)
```

* If the case an `EXTERN` declaration specifies multiple outputs, any of those results may be discarded

```quil
DECLARE params REAL[10]
DECLARE top_values REAL[2]
EXTERN MAX2(REAL*) (REAL, REAL)
CALL _ top_values[0] MAX2(params)
```

* Compilers _may_ support overloading multiple `EXTERN` instructions for `<Identifier>` with different call signatures. In such a case, any `CALL` instruction must match _exactly one_ of those defined call signatures.

:white_check_mark:

```quil
DECLARE random_real REAL[1]
DECLARE random_integer INTEGER[1]
EXTERN RAND(REAL) REAL
EXTERN RAND(INTEGER) INTEGER
EXTERN RAND(REAL) INTEGER
CALL random_real RAND(random_real)
CALL random_integer RAND(random_integer)
CALL random_integer RAND(random_real)
```

:x:

```quil
DECLARE random_real REAL[1]
DECLARE random_integer INTEGER[1]
EXTERN RAND(REAL) REAL
EXTERN RAND(REAL) REAL 
CALL random_real RAND(random_real)
```

:x:

```quil
DECLARE random_integer INTEGER[1]
EXTERN RAND(REAL) REAL 
CALL random_integer RAND(random_integer)
```

* Compilers _may_ support parameter names, so as to support more clear compiler errors.

:white_check_mark:

```quil
DECLARE random_real REAL[1]
EXTERN RAND(state REAL) (new_state REAL)
CALL random_real RAND(random_real)
```

#### Unspecified

This specification leaves the following behavior unspecified:

* Where classical functions are implemented (ie client, compiler, or control system).
* Whether to support parameter names in `EXTERN` instructions.
* The behavior of compilers targeting hardware backends that do not support the `EXTERN`ed instructions.

### Semantic Precedent for `EXTERN`

`extern` is a common keyword in several well known classical computing contexts, as well as at least one other quantum computing IR, OpenQASM 3.0.

Typically, `extern` connotes the availability of a function or variable defined _outside_ the scope of the current translation unit or, conversely, making a definition inside the current translation unit available to external translation units, across either some language specific interface or foreign function interface.

In this RFC, we petition that `EXTERN` imply the availability of a classical instruction on the quantum control system.Similar to the `extern` keyword in strongly typed languages, such as C++ and Rust, the `EXTERN` instruction here declares the function identifier, its parameters, and return type.

#### C / C++ Language Specification

In the [C lanaguage specification](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1124.pdf), `extern` serves as a storage class specifier for external linkage, modifying the visibility of variables and functions between translation units. 

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

https://learn.microsoft.com/en-us/cpp/cpp/extern-cpp?view=msvc-170
Also see https://learn.microsoft.com/en-us/cpp/c-language/extern-storage-class-specifier?view=msvc-170

#### Rust

In Rust [extern](https://doc.rust-lang.org/std/keyword.extern.html) is used within the context of foreign function interfaces (FFI), both:

1. To declare foreign function interfaces that Rust code may invoke.
2. To define Rust functions that may be linked from foreign code.

> Using `extern crate` for linking Rust dependencies is [no longer required in most use cases](https://doc.rust-lang.org/edition-guide/rust-2018/path-changes.html#an-exception).

##### Example 1

```rs
#[link(name = "my_c_library")]
extern "C" {
    fn my_c_function(x: i32) -> bool;
}
```

##### Example 2

```rs
#[no_mangle]
pub extern "C" fn callable_from_c(x: i32) -> bool {
    x % 3 == 0
}
```

#### OpenQASM 3.0

Open QASM 3.0 has introduced support for [extern function calls](https://openqasm.com/language/classical.html#extern-function-calls). Of note, as of this writing:

* `extern functions are declared by giving their signature`
* `extern functions can take of any number of arguments whose types correspond to the classical types of OpenQASM.`
* `extern functions are invoked using the statement name(inputs)`
* `The functions are not required to be idempotent.`

### Semantic Precedent for `CALL` 

#### LLVM

In LLVM IR, [call](https://llvm.org/docs/LangRef.html#i-call) "represents a simple function call", the result of which can be assigned to an SSA value.

* https://llvm.org/docs/LangRef.html#i-call

##### Examples

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

https://llvm.org/docs/LangRef.html#id1742

### Alternatives

#### `DECLARE` in place of `EXTERN`

Because `EXTERN` _declares_ a function signature, we may consider overloading the existing `DECLARE` instruction:

```quil
DECLARE lsfr(REAL) REAL
DECLARE current_value REAL[1]
CALL current_value lsfr(current_value)
```

The main disadvante of this approach is that overloaded function declarations less clearly differentiate from program memory regions. We could disambiguate by introducing, instead, `DECLARE-INSTRUCTION`, `DECLARE-EXPRESSION`, or `DEFINSTRUCTION`, however, the `EXTERN` instruction more clearly insinuates a boundary between the Quil program and the classical control system that may, or may not, support the declaration. 

#### `INVOKE` in place of `CALL`

In addition to `call`, LLVM also has an [invoke](https://llvm.org/docs/LangRef.html#invoke-instruction) instruction.

> This instruction is designed to operate as a standard ‘call’ instruction in most regards. The primary difference is that it establishes an association with a label, which is used by the runtime library to unwind the stack.

There is currently no notion of a runtime exception in Quil, much less exception handling. As such, we can draw a weaker analogy to the LLVM `invoke` instruction than `call`. This is only analogy, but the decision here is semantic and is perhaps the best we can do.

#### Direct reference to instruction rather than `CALL`

We could drop the `CALL` instruction entirely:

```quil
EXTERN RAND(REAL) REAL
DECLARE current_value REAL
RAND(current_value) current_value
```

This is obviously less verbose, but program structure is perhaps a bit more ambiguous. It is less clear that `RAND` is not specific to the Quil specification. Additionally, this introduces an issue if an `EXTERN` declaration extends an the call signature of an existing Quil instruction:

```quil
EXTERN MOVE(REAL, REAL) REAL
DECLARE params REAL[10]
DECLARE current_value REAL
MOVE(params[0], params[1]) current_value
```

The `CALL` instruction clearly disambiguates instruction extensions explicitly specified in the Quil spec, thereby providing a clean namespace into which functions may be declared within a program and providing a clearer means for compilers and backends to evaluate support for out-of-spec instructions.

### Footnotes


