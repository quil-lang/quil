# Typed Memory

This document explains Quil's classical memory model.

## Design Considerations

In assembly code, in general, types are considered only at the mnemonic or interpretation level. They're not often a consideration in the code itself. (Though this is not always true, machine codes for dynamic languages included the notion of type checking and type tags at the instruction level.) On modern processor architectures, one has a large *random access memory* (RAM) which is byte-addressable, and a series of processor *registers* that hold usually one word's worth of data. (A *word* is often some multiple of bytes, usually 4 or 8.) A *register machine* is one that loads values from memory to the registers, does some operation, and often stores the results back into memory.

So far, we've spoken only of bytes or multiples thereof. A byte—or word for that matter—is simply a measure of a number of bits, with no additional attached interpretation. What gives a byte interpretation is the literal machinery attached to the registers in which the bytes are stored. Implicit in the machinery, usually electrical circuitry, is a way of transforming bytes into a new ones. This machinery is invoked with an *opcode*. Since opcodes relate to physical machinery, opcodes are often only pertinent to a subset of registers that a machine has. From here, we get a usual partitioning of registers: registers that deal with general integer arithmetic, registers that deal with floating point numbers, registers that deal with vectorized low-precision arithmetic, registers that interact with main memory, and so on. The partition isn't always so strict; _general purpose registers_ often are capable of many disparate operations.

RAM more often than not lacks any serious kind of operation except loading and storing. Similarly, cross-register opcodes also deal with the movement of data and not operation on the data contained within. When we want to do something like adding an integer and floating point number, we have to put the integer into a floating point representation, move it from an integer register to a floating point register, and perform the addition across two floating point registers. Some architectures, such as the x87 floating point unit, can perform the representation-changing and loading in a single instruction (e.g., the `FILD` instruction).

Quil was designed to be an instruction language that doesn't conform to any physical architecture. It was designed to accommodate evolving quantum architectures in terms of their memory models and their native gates. In some sense, Quil can be seen as a portable bytecode of sorts, (currently) without an actual bytecode representation.

The original Quil paper assumes there is an unbounded classical memory composed of a series of bits, and segments of these bits can be interpreted as a real or complex number. While very simplistic, it has a few flaws:

* The type of a data segment is determined solely by its length (64 bits indicates a double-precision floating point number, 128 bits indicates a double-precision complex number).
* There are no provisions for the construction or use of integer data, which is desirable for counters and frequentist statistics.
* There are no classical instructions that make use of segments, despite an inherent desire to do high-speed arithmetic on gate angles.
* Quil code making heavy use of segments quickly becomes unweidly and unreadable.
* Quil code has no friendly notion of *linkage*, which would allow a concurrently run classical program to refer to named data.

In this document, we describe a replacement for the notion of classical data in Quil. It is similar to C in that we don't select any particular memory model, and require the user to specify what he or she requires in terms of layout. Similarly departing from usual instruction sets, we allow for memory to be interpreted through multiple type lenses. In C, we accomplish this by casting pointers and dereferencing. Since we don't have a notion of pointers, we accomplish this with explicit declaration and aliasing.

With all of these revisions, we can write code which does the following:

```
DECLARE count INTEGER
DECLARE stats INTEGER
DECLARE measurement INTEGER
DECLARE angle REAL
DECLARE cond BIT

# Initialize
MOVE stats 0
MOVE angle 0.0

# Start the angle loop
LABEL @start_angle_loop
LT cond angle 6.283185307179586
JUMP-UNLESS @end cond
# Perform histogram loop, 1000 shots
MOVE count 1000
LABEL @stats_loop
RX(angle) 0
MEASURE 0 measurement
ADD stats measurement
SUB count 1
GT cond count 0
JUMP-WHEN @stats_loop cond
# Calculate next angle
ADD angle 0.3926990816987241   # pi/8
JUMP @start_angle_loop
LABEL @end
```

This will be roughly equivalent to the following C program:

```
int count, stats, measurement;
float angle;
stats = 0;
for(angle = 0.0; angle < 6.283185307179586; angle += 0.3926990816987241) {
    for(count = 1000; count > 0; count--) {
        RX(angle) 0
        measurement = MEASURE 0
        stats += measurement
    }
}
```



## Types

The supported types are `BIT` which represents one bit, `OCTET ` which represents 8 bits, `INTEGER` which represents a machine-sized signed integer, and `REAL` which represents a machine-sized real number. The formats/layouts of these are specific to the machine being run on.

When we speak of *size*, we mean the number of octets that a type represents. The notion of *size* is distinct from *length*, which instead refers to some count of elements of a particular type.

A fixed-length vector of a type is denoted by the type name followed by an integer in brackets. For instance, `REAL[5]` is a type that represents five real numbers in sequence. The type `INTEGER` is guaranteed to be large enough to hold a valid length of octets, and is guaranteed to hold at least the values `-127` to `128`.

There are currently no provisions for adding additional types.

## Declaring Memory

Quil doesn't have a notion of _allocating_ memory, but rather the notion of _declaring the existence_ of memory. In the following, we introduce the `DECLARE` directive, which describes available memory for a program to use.

Some quantum computing architectures might restrict what can be declared, what types can be used, what names can be used, etc. It is recommended to be as liberal as possible in what can be declared, while remaining true to the architectural constraints of the system on which Quil is executed.

The `DECLARE` directive is used to declare a vector of typed memory. There are three variants: plain declaration, aliased declaration, and aliased declaration with offset.

### Plain Declaration

```
DECLARE <name> <type>
```

This declares that `<name>` designates memory which can hold `<type>`. If `<type>` is a scalar type, then it is assumed to designate a vector of length 1. That is, the following two lines are equivalent:

```
DECLARE x INTEGER
DECLARE x INTEGER[1]
```

In the program that follows, `x` or equivalently `x[0]`  will refer to an integer quantity.

### Aliased Declaration

```
DECLARE <name> <type> SHARING <other-name>
```

This declares that `<name>` designates memory which can hold `<type>`, but `<name>` shares memory with that which is designated by `<other-name>`. Here, the total memory size pointed to  by `<name>` shall not exceed the total memory size pointed to by `<other-name>`.

An implementation is free to reject programs where particular instances of sharing is invalid (e.g., alignment is violated; disparate memories are unshareable; etc.).

### Aliased Declaration with Offset

```
DECLARE <name> <type> SHARING <other-name> OFFSET <integer_1> <offset-type_1> <integer_2> <offset-type_2> ...
```

This is similar to the aliased declaration, but it allows `<name>` to designate memory in the middle of that which is designated by `<other-name>`. In particular, `<name>` will point to memory a total of `SUM_i <integer_i> * sizeof(<offset-type_i>)` octets after the start of `<other-name>`. As with an aliased declaration, the memory at `<name>` must not overflow the end of `<other-name>`.

Implementations may enforce alignment by way of erroring if the stated declaration is invalid. Implementations must _not_ round up or down to alignment boundaries.

### Portability of Aliased Declarations

Aliased declarations with mixed types require an intimate view of the target architecture. The widths of each data type, which are hitherto unspecified, must be known. For example, the following declarations may not be valid of the size of `REAL` exceeds the size of `INTEGER`.

```
DECLARE x INTEGER
DECLARE y REAL SHARING x
```

Even if such a declaration is valid, operations on `y` are not portably specified. For example, continuing the above,

```
DECLARE b BIT
MOVE x 0
EQ b y 0.0
```

could result in any value for `b`, depending on the implementation.

An implementation shall describe the bit-level description of the types, the available declarable memories, the limits on the declared memory, alignment requirements, and limits on sharing and offsets.

### Examples

#### Register machine with condition bit

Here we consider a layout for a machine that has one integer register, two real registers, and a _condition bit_ used for doing comparisons and branching.

```
DECLARE f1 REAL
DECLARE f2 REAL
DECLARE x INTEGER
DECLARE cmp BIT    # cmp for "comparison"
```

This might be suitable for a very simple quantum control system with a single counter for loops.

#### Memory-mapped RAM

The following is an example of a memory structure that might be used in a system with a fixed and known memory layout optimized for running QAOA-like circuits.

```
DECLARE memory OCTET[131072]                              # 128k global memory
DECLARE qaoa-params REAL[32] SHARING memory               # all QAOA params
DECLARE beta REAL[16] SHARING qaoa-params                 # beta params
DECLARE gamma REAL[16] SHARING qaoa-params OFFSET 16 REAL # gamma params
DECLARE ro BIT[16]                                        # readout registers
```

Here, we have two disjoint memories: the global data memory `memory`, and the readout memory `ro`. We see that the global data memory `memory` is further partitioned into a section `qaoa-params` specifically for QAOA parameters, which may be useful if you're changing them all at once. Nonetheless, for actual use in Quil code, the actual `beta` and `gamma` parameters are carved out of this memory.

This particular scheme may be necessary if software processing Quil does not have any ability generate memory maps automatically. If that functionality were possible, one could simply declare `beta`, `gamma`, and `ro` and let the compilation software take care of mapping that to physical memory.

#### Computing Bits of an Angle

In algorithms like phase estimation, we compute one bit of the result at a time with each measurement. If our `INTEGER` data type has the standard binary representation, then one can do:

```
DECLARE unadjusted-theta INTEGER
DECLARE ro BIT[16] SHARING unadjusted-theta
DECLARE theta REAL
# <phase estimation>
MEASURE 0 ro[0]
MEASURE 1 ro[1]
# ...
MEASURE 15 ro[15]
```

Here, we have a 16-bit integer `unadjusted-theta` with the LSB of our estimated phase starting with qubit 0. (This depends on our convention in our implementation of phase estimation.) Since `unadjusted-theta` and `ro` are shared, the bits of `ro` directly affect the bits of our integer. Recalling that phase estimation gives us a bitstring (in this case, an integer between `0` and `2^16 - 1`), we must actually adjust it by multiplying by `2*pi/2^16`, which is approximately  `9.587379924285257e-5`.

Since `theta` and `unadjusted-theta` have different types, we can't quite yet do this multiplication. We need to convert `unadjusted-theta` into a `REAL` representation on which we can do fractional arithmetic. We can do this with `CONVERT`, which in other languages is known as a _cast_ or _coercion_.

```
CONVERT theta unadjusted-theta   # convert INTEGER to REAL
MUL     theta theta 9.587379924285257e-5
```

Now we can use `theta` as an argument to an angle if we please. For example, we might do a phase adjustment based off of that angle on qubit `16`:

```
RZ(theta) 16
```

## Dereferencing Memory

Memeory is dereferenced in a Quil program using common array dereferencing syntax. In particular, given a name `x` pointing to memory of type `T`, and a non-negative integer offset `n`, the syntax `x[n]` refers to the `n`th element of type `T` indexing off of `x[0]`.

If and only if `x` was declared with just a single element, then `x` may be referred to simply by its name with no bracket. In this case, `x` and `x[0]` would be equivalent.

Dereferencing with indirection, e.g., `x[y[3]]`, is supported through the `LOAD` and `STORE` instructions. For example,

```
DECLARE x INTEGER[16]
DECLARE y INTEGER[16]
DECLARE z INTEGER[16]
DECLARE t INTEGER
LOAD t y z[3]          # t := y[z[3]]
LOAD t x t             # t := x[t]
```

## Classical Instructions

With typed memory comes a bag of new instructions. In the following table, we use the following notation to denote an instruction `INSTR` and its modes:

```
# Category of instruction
INSTR   a b             # Pseudocode meaning
        <type1a> <type1b>
        <type2a> <type2b>
        ...
```

The possibilities for `<typeXY>` are:

```
<!int>  : Immediate (literal) integer, also used for octets (0-255) and bits (0-1)
<int>   : Memory reference to an integer
<int*>  : Name of a vector of declared integers
<!real> : Immediate (literal) real
<real>  : Memory reference to a real
<real*> : Name of a vector of declared reals
<bit>   : Memory reference to a bit
<bit*>  : Name of a vector of declared bits
<oct>   : Memory reference to an octet
<oct*>  : Name of a vector of declared octets
```

Octet literals share the same syntax as integer literals.

We generally follow the `dest`-`src` ordering of arguments.

```
# Move like-typed data to different locations.
# Also allows loading immediate values.
MOVE     a b            # a := b
         <oct> <!int>
         <oct> <oct>
         <int> <!int>
         <int> <int>
         <real> <!real>
         <real> <real>
         <bit> <!int>
         <bit> <bit>

# Exchange the value at two like-typed locations.
EXCHANGE a b            # a <=> b
         <oct> <oct>
         <int> <int>
         <real> <real>
         <bit> <bit>

# Perform an indirect load from x offset by n to a.
LOAD     a x n          # a := x[n]
         <oct> <oct*> <int>
         <int> <int*> <int>
         <real> <real*> <int>
         <bit> <bit*> <int>

# Perform an indirect store of a to x offset by n.
STORE    x n a          # x[n] := a
         <oct*> <int> <oct>
         <oct*> <int> <!int>
         <int*> <int> <int>
         <int*> <int> <!int>
         <real*> <int> <real>
         <real*> <int> <!real>
         <bit*> <int> <bit>
         <bit*> <int> <!int>

# Perform a move of differently typed data.
# The data here is interpreted numerically.
CONVERT  a b            # a := (T)b, where T = type-of(a)
         <int> <real>   # - Best integer approximation of a real.
         <int> <bit>    # - Convert 0 or 1 to an integer.
         <real> <int>   # - Best real approximation of an integer.
         <real> <bit>   # - Convert 0 or 1 to a real.
         <bit> <int>    # - 0 if 0, 1 if non-zero.
         <bit> <real>   # - 0 if 0.0, 1 if non-zero

# Logical Operations
NOT      a              # a := ~a
         <oct>
         <int>
         <bit>

AND      a b            # a := a & b
IOR      a b            # a := a | b
XOR      a b            # a := a ^ b
         <oct> <oct>
         <oct> <!int>
         <int> <int>
         <int> <!int>
         <bit> <bit>
         <bit> <!int>

# Arithmetic Operations
NEG      a              # a := -a
         <int>
         <real>

ADD      a b            # a := a + b 
SUB      a b            # a := a - b
MUL      a b            # a := a * b
DIV      a b            # a := a / b
         <int> <int>
         <int> <!int>
         <real> <!real>
         <real> <real>

# Comparison
EQ       r a b          # r := (a == b)
GT       r a b          # r := (a > b)
GE       r a b          # r := (a >= b)
LT       r a b          # r := (a < b)
LE       r a b          # r := (a <= b)
         <bit> <bit> <bit>
         <bit> <bit> <!int>
         <bit> <oct> <oct>
         <bit> <oct> <!int>
         <bit> <int> <int>
         <bit> <int> <!int>
         <bit> <real> <real>
         <bit> <real> <!real>
```

### Modifications to Existing Instructions

#### Original Quil Classical Instructions

The orignal instructions `FALSE`, `TRUE`, `NOT`, `AND`, `OR`, `MOVE`, and `EXCHANGE` are all either removed or superseded.

#### Control Flow

The existing control flow instructions `JUMP-WHEN` and `JUMP-UNLESS` now branch based off of a memory reference to a `BIT`.

#### Measurement

```
MEASURE <qubit> <bit>
MEASURE <qubit> <int>
```

Measurement-for-record is modified so that it can take either a `BIT` or `INTEGER`. For `BIT`, it behaves as usual. For `INTEGER`, the measurement will overwrite the with a `0` or `1`.

#### Qubit Reset

In addition to the `RESET` instruction with no arguments, which resets all qubits, we also support

```
RESET q
```

for resetting one qubit `q`. This can be potentially implemented on a QPU with active reset without temporary cells of memory.