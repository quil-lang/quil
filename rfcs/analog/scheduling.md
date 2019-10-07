# Scheduling of Quilt Programs

## Instructions, Events, and Frames

### Events

An _event_ is comprised of:
-   start time
-   end time
-   a frame
-   a parent instruction

The duration of an event, (end time - start time), must be nonnegative.

### Obstructed Frames

Each instruction has a set of _obstructed_ frames. These determine which events
can be scheduled concurrently.

-   Generically, `PULSE`, `CAPTURE`, `RAW-CAPTURE` obstruct all frames sharing a qubit
    with the target frame.
-   If `NONBLOCKING`, the above instructions obstruct only their target frame.
-   Simple frame mutations (i.e. `SET-*`) obstruct their target frame.
-   `DELAY` obstructs the set of delayed frames
-   FENCE obstructs all frames sharing a qubit with the listed qubits
-   SWAP-PHASE obstructs the two listed frames

### Schedules

A schedule for a program is nothing more than a fully elaborated set of events,
_with each instruction parent to a single event on each of its obstructed
frames_.

### Simple vs Compound Instructions

Simple instructions have a well defined _duration_, which for some may be
explicit and unambiguous (e.g. pulse ops), and for others may be hardware
dependent (e.g. frame mutations).

Compound instructions do not in general have a well defined global duration.

#### "Simple" instructions

-   `PULSE`, `CAPTURE`, `RAW-CAPTURE` have explicit durations indicated by the
    waveform or raw capture duration.
-   `DELAY` on a single frame has an explicit duration.
-   `SET-*` have a hardware-dependent (perhaps nearly zero) duration

#### "Compound" instructions

-   `DELAY` on multiple frames is syntactic sugar for a `DELAY` on each of its
    frames. We exclude this from the remaining discussion.
-   `FENCE` may resolve to events on each obstructed frame with varying durations.
-   `SWAP-PHASE` may resolve to events one each obstructed frame with varying durations.

## Schedules and Consistency

With respect to a schedule, the _timeline_ associated to a frame is the
ordered (by start time) sequence of events on this frame. 

### Consistency

A schedule is said to be _consistent_ if it satisfies the following:
1.  (monotonicity of time) events durations are non-negative
2.  (simple duration) simple event durations agree with their instruction durations
3.  (exclusion) for any frame timeline, no two events overlap
4.  (order preservation) for any frame timeline, event A precedes B if and only
    if the instruction associated to A precedes the instruction associated with
    B relative to a frame-local program counter
5.  (atomicity) for a simple instruction, all event start times are equal.
    likewise, all end times are equal.
6.  (synchronization) for a compound instruction, all event end times are equal.

### Non-Uniqueness of Consistent Schedules

Consistent schedules are generally not unique. There are a few sources of
non-uniqueness.

-   The initial events in each timeline can have their start times shifted by an
    arbitrary constant. Thus we occasionally standardize things by setting the
    start time of the earliest event to 0.
-   The events themselves may be rescheduled within some block of time. For
    example, in (abbreviationg waveforms to their durations)
    ```
    FENCE 0 1
    PULSE 0 "xy" 1.0
    PULSE 1 "xy" 2.0
    FENCE 0 1
    ```
    there are many consistent schedules, which start the pulse operations at
    varying times. Even more simply, one could suppose `PULSE 0 "xy" ; PULSE
    0 "xy" ` is scheduled with dead time between the two pulses.
-   `FENCE` and `SWAP-PHASE` instructions may have arbitrary event durations
    (e.g. supposing a FENCE corresponds to events with durations d(1), ...,
    d(k), one may obtain a consistent schedule by adding a constant to the end
    time of each event, resulting in durations d(1) + c, ..., d(k) + c).

## Tightness and Rigidity

Consider the following program, with pulse waveforms omitted
```
PULSE 0 "xy"
PULSE 0 "xy"
PULSE 0 1 "ff"
PULSE 1 "xy"
PULSE 1 "xy"
PULSE 0 1 "ff"
PULSE 0 "xy"
PULSE 0 "xy"
```

Once a start time has been set, there is a natural schedule associated with
the above, imposed simply by the constraints of obstruction. For example, the
initial two `0 "xy"` pulses obstruct the `0 1 "ff"` frame. The `0 1 "ff"`
pulse may immediately follow these, and itself obstructs the `1 "xy"` frame,
and so on.

It is difficult to speak precisely about this without introducing some notation.
A _path_ is a sequence e(1), ..., e(n) of events, ordered by start time, such
that, for 1 <= i < n,

-   (obstructed successor) the frame of e(i+1) is obstructed by the instruction of e(i)
-   (earliest successor) amongst scheduled events obstructed by and starting after e(i), the event e(i+1)
    is the earliest.

For example,
```
PULSE 0 "xy"
PULSE 1 "xy"
PULSE 0 2 "ff"
PULSE 2 "xy"
```

has a path of length 3 (coming from `PULSE 0 "xy" ; PULSE 0 2 "ff" ; PULSE 2
"xy"`) and another of length 1 (from `PULSE 1 "xy"`).

A consistent schedule is _tight_ if, for any path e(1),...,e(n), the start time
of e(i+1) = the end time of e(i). In brief, at the end of each event, the next
earliest obstructed event starts immediately.

Two events s, t in a schedule are _connected_ if there is a path e(1),...,e(n)
with s = e(1) and t = e(n). This relation partitions the schedule into
_connected components_.

A quilt block is _rigid_ if there exists a tight schedule subject to:
1.  (fixed start) the earliest event in any component has start time 0.
2.  (minimality) the end time of any FENCE and SWAP-PHASE instruction is minimal

### Uniqueness

**Proposition**: Every block admits at most one tight schedule subject to (fixed
start) and (minimality).

Sketch of Proof: Consider the result of consistent greedy scheduling subject to (fixed
start) and (minimality). TODO

We refer to this as the _rigid schedule_ associated with the block.

### Failures of Rigidity

By the uniqueness result, a block may fail to be rigid if no tight schedule
satisfying (fixed start) and (minimality) exists.

#### Missing Delay

The following is not rigid (waveforms abbreviated to their durations),
```
PULSE 1 "xy" 2.0
PULSE 0 "xy" 1.0
PULSE 0 1 "ff" 1.0
```
because there does not exist any consistent, tight schedule satisfying (fixed start).

However, with an additional `DELAY`, the result is rigid.
```
PULSE 1 "xy" 2.0
DELAY 0 "xy" 1.0
PULSE 0 "xy" 1.0
PULSE 0 1 "ff" 1.0
```
or
```
PULSE 1 "xy" 2.0
PULSE 0 "xy" 1.0
DELAY 0 "xy" 1.0
PULSE 0 1 "ff" 1.0
```

### The Duration of a Rigid Block

A rigid block has a well-defined duration, indicated by the latest end time in
its rigid schedule.

### Establishing Rigidity

Proposition: Any quilt program may be transformed to a corresponding rigid
program through the insertion of DELAYS.

## Promises to the Programmer

In general, it is up to the compiler/translator to associate a consistent
schedule to a quilt program. But how should rigid blocks be managed?

### The challenge of preserving rigidity

Considering the above example,
```
PULSE 1 "xy" 2.0
PULSE 0 "xy" 1.0
PULSE 0 1 "ff" 1.0
```
the first two instructions form a rigid block, and the last two instructions
form a rigid block, but the set of three do not. In general, it should not be
expected that rigidity of individual blocks be preserved. In this instance,
the compiler/translator will be forced to decide when to schedule the pulse
on `0 "xy"`.

### `PRAGMA PRESERVE_RIGID_BLOCK`

For systematic and predictable control over scheduling, users may surround a
block with `PRAGMA PRESERVE_RIGID_BLOCK` and `PRAGMA END_PRESERVE_RIGID_BLOCK`.
The signal to the compiler/translator is that, if the enclosed block is rigid,
then the rigid schedule for this block will be used in the final schedule (up to
a global time shift, since it may start at a nonzero time with respect to the
global program.

**By default, calibration bodies are treated as if they were surrounded by
enclosing `PRAGMA PRESERVE_RIGID_BLOCK`.**

