# State Transition Model — Lab 02 Parts 1-2

## Implemented lifecycle

Before Lab 02:

```text
DEFINED --ZSCHORD--> ORDERED
```

After Parts 1-2:

```text
DEFINED
   |
   | ZSCHORD
   v
ORDERED
   |
   | ZSCHEVL
   v
READY
```

## Transition contract

`ZSCHEVL` currently permits exactly one transition:

```text
ORDERED -> READY
```

It rejects:

```text
READY -> READY
HELD -> READY
WAIT_TIME -> READY
WAIT_COND -> READY
WAIT_RESOURCE -> READY
SUBMITTED -> READY
EXECUTING -> READY
ENDED_* -> READY
ABENDED -> READY
JCL_ERROR -> READY
```

Future versions will introduce explicit transition logic for waiting states and operator control.

## Why READY is separate from ORDERED

`ORDERED` means a runtime occurrence exists in the active environment.

`READY` means the scheduler has evaluated the criteria currently implemented and found no blocker preventing submission.

This separation is necessary before adding:

- time windows;
- logical conditions;
- resource availability;
- operator HOLD/FREE;
- production-day logic.

## Current limitation

The evaluator reports those criteria as `NOT CONFIGURED`.

That output is not a simulation of them. It is an explicit statement that those controls are not yet part of the executable scheduler.
