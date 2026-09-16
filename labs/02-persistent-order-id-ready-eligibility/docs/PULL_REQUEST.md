## Summary

This PR closes **Lab 02 Parts 1-2** of the z/OS Batch Scheduler.

It extends the Lab 01 scheduler foundation with:

- persistent Order-ID generation through `IBMUSER.ZSCH.PARM(SEQ01)`;
- multiple independent active occurrences of the same permanent definition;
- an explicit eligibility evaluator (`ZSCHEVL`);
- a validated `ORDERED -> READY` transition;
- rejection of an invalid repeated `READY -> READY` transition;
- Architecture V2 metadata, evidence, security scope and Part 3 handoff documentation.

## Why this change exists

Lab 01 proved the separation between permanent definitions and active runtime state but deliberately used a fixed `ORDERID=0000001`.

This PR removes that limitation and adds the first executable state-machine transition so that the scheduler can identify one specific runtime occurrence and decide whether that occurrence is eligible before submission.

## Validated path

```text
DEFINITION
    |
    v
ZSCHVAL
    |
    v
ZSCHORD
    |
    v
persistent ORDER-ID
    |
    v
ACTIVE / ORDERED
    |
    v
ZSCHEVL
    |
    v
READY
```

## Positive evidence

- `SEQ01` advanced from `0000001` to `0000002`.
- `A0000001` remained present.
- `A0000002` was created independently.
- `A0000002` transitioned from `ORDERED` to `READY`.
- Runtime metadata remained present.
- `JOBID=` remained empty as expected because JES2 submission is not yet implemented.

## Negative evidence

A second `ZSCHEVL` execution against the already-READY instance was rejected:

```text
ZSCH320E INSTANCE IS NOT ELIGIBLE FROM STATE: READY
ZSCH321E EXPECTED STATE: ORDERED
```

## Architecture

Primary domain:

```text
Workload and Batch Engineering
```

Architecture V2 maturity:

```text
M2 - Operational
I1 - Cross-component
```

The implementation remains an independent educational scheduler inspired by enterprise workload-automation concepts. It does not copy Control-M proprietary code or formats.

## Scope boundary

This PR does **not** claim:

- JES2 submission;
- `STATE=SUBMITTED`;
- JOBID persistence;
- SDSF execution tracking;
- RC/ABEND/JCL-error classification;
- conditions/resources/HOLD support.

## Next capability

**Lab 02 Part 3 — READY to JES2 Submission**

Part 3 will implement the first real scheduler-controlled workload submission while preserving the architectural rule:

```text
Scheduler decides and controls.
JCL describes the workload.
JES2 executes the workload.
```

Robust JOBID association and execution tracking remain the next validated layer.
