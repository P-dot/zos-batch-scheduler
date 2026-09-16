# Control Plane Evolution — From Lab 01 to Lab 02

## Lab 01

Lab 01 established the scheduler control-plane foundation:

```text
definition -> validation -> ORDER -> active runtime state
```

Its purpose was to prove that a scheduler definition and a runtime occurrence are different objects.

## Lab 02 Part 1

Part 1 introduced persistent runtime identity:

```text
active occurrence 0000001
active occurrence 0000002
...
```

The key capability is not merely incrementing a number. It is ensuring that future execution state, JOBID, history and recovery decisions can be tied to one specific occurrence.

## Lab 02 Part 2

Part 2 introduced eligibility as an executable decision:

```text
ORDERED -> READY
```

This is the first point where scheduler state becomes a controlled state machine rather than only stored metadata.

## Part 3 handoff

Part 3 will add the execution boundary:

```text
READY -> SUBMITTED -> JES2
```

The scheduler must verify the active occurrence is `READY`, read the referenced JCL location, submit it through a supported z/OS path, and update the active state only after a successful submission request.

Durable JOBID capture and continuing execution tracking remain the following layer.
