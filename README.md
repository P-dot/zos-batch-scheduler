# z/OS Batch Scheduler — Workload Automation Engineering

Hands-on engineering project to design and validate a native **z/OS batch scheduling and production-control layer** above JES2.

The scheduler is built incrementally on z/OS ADCD / Hercules using observable runtime state, REXX control logic, explicit transition rules, positive and negative tests, and evidence-backed capability gates.

> **Validated scope:** Lab 01 and Lab 02 Parts 1–2
> **Current runtime endpoint:** `STATE=READY`, `JOBID=`
> **Next capability gate:** Lab 02 Part 3 — `READY -> SUBMITTED` through real JES2 submission
> **Architecture:** Portfolio Navigation V2 / Engineering Control

This is an independent educational implementation. It contains no BMC proprietary code and is not intended to be a Control-M-compatible clone.

## Navigate

- [Lab 01 — Architecture, Job Definitions & Active State Model](labs/01-architecture-job-definitions-active-state-model/README.md)
- [Lab 02 — Persistent Order-ID & READY Eligibility](labs/02-persistent-order-id-ready-eligibility/README.md)
- [Ecosystem Integration](docs/ECOSYSTEM-INTEGRATION.md)
- [JCL Engineering Labs](https://github.com/P-dot/JCL_LABS)
- [MVS TSO/ISPF](https://github.com/P-dot/MVS_TSO_ISPF)
- [REXX](https://github.com/P-dot/Rexx)
- [Master z/OS Engineering Laboratory](https://github.com/P-dot/zos-adcd-hercules-engineering-lab)
- [IBM z/OS Engineering Portfolio](https://github.com/P-dot/P-dot)

## Repository Role

`zos-batch-scheduler` owns **scheduler orchestration and production-control logic**.

Its job is to determine which defined workload occurrence is active, whether that occurrence is eligible to run, when it should be submitted, and eventually how execution results affect scheduler state.

The architectural boundary is:

```text
Scheduler decides and controls.
JCL describes the workload.
JES2 executes the workload.
```

The scheduler therefore does not replace `JCL_LABS`, JES2, application repositories, or the system-level z/OS engineering domain.

## Current Validated Control Path

```text
PERMANENT DEFINITION
        |
        v
     ZSCHVAL
        |
        v
     ZSCHORD
        |
        +--> persistent ORDER-ID
        |
        v
 ACTIVE INSTANCE
  STATE=ORDERED
        |
        v
     ZSCHEVL
        |
        v
    STATE=READY
    JOBID=
        |
        X
        |
       JES2
```

`X` is the current evidence boundary.

Lab 02 Parts 1–2 prove scheduler runtime identity and eligibility. They do **not** prove scheduler-controlled JES2 submission.

## Validated Capabilities

### Lab 01 — Scheduler foundation

[Open Lab 01](labs/01-architecture-job-definitions-active-state-model/README.md)

Validated locally:

- isolated scheduler libraries under `IBMUSER.ZSCH.*`;
- permanent scheduler definitions;
- `ZSCHVAL` definition validation;
- positive and negative metadata validation;
- `ZSCHORD` ORDER processing;
- active runtime-instance creation;
- explicit `STATE=ORDERED`;
- rejection of invalid definitions before active-state creation;
- preservation of valid active state after a rejected ORDER.

Validated transition:

```text
DEFINED -> ORDERED
```

### Lab 02 Parts 1–2 — Runtime identity and eligibility

[Open Lab 02](labs/02-persistent-order-id-ready-eligibility/README.md)

Validated locally:

- persistent Order-ID generation;
- sequence persistence through `SEQ01`;
- preservation of earlier runtime occurrences;
- creation of independent `A0000002`;
- `ZSCHEVL` eligibility evaluation;
- controlled `ORDERED -> READY` transition;
- preservation of runtime metadata;
- rejection of invalid repeated `READY -> READY`;
- empty `JOBID` before JES2 submission.

Validated endpoint:

```text
IBMUSER.ZSCH.ACTIVE(A0000002)

ORDERID=0000002
STATE=READY
JOBID=
```

The empty `JOBID` is intentional and technically meaningful: the scheduler has not submitted the workload yet.

## Next Capability Gate

Lab 02 Part 3 is already defined by the repository handoff documentation.

Target:

```text
ACTIVE / READY
     |
     v
   ZSCHSUB
     |
     +--> verify STATE=READY
     +--> read JCLDSN / MEMBER
     +--> validate workload reference
     |
     v
controlled submission request
     |
     v
    JES2
     |
     v
STATE=SUBMITTED
```

The state must not become `SUBMITTED` before successful submission has been observed.

Durable JOBID association and continuing JES2/SDSF execution tracking remain a later capability unless independently validated.

## Runtime Architecture

The scheduler runtime relationship is:

```text
zos-batch-scheduler
        |
        | eligibility / orchestration
        v
       JCL
        |
        | workload description
        v
      JES2
        |
        | execution
        v
 program / utility
```

This differs from the portfolio learning path:

```text
MVS_TSO_ISPF
      |
      v
   JCL_LABS
      |
      v
zos-batch-scheduler
```

The first diagram describes **runtime responsibility**. The second describes **how the portfolio builds skills and evidence**.

## Implementation Layer

The current scheduler control programs are implemented in REXX and operated through TSO/E / ISPF.

```text
TSO/E + ISPF
     |
     v
    REXX
     |
     v
scheduler control logic
     |
     +--> definitions
     +--> sequence state
     +--> active runtime state
     +--> workload references
```

`Rexx` owns general REXX learning and language capability. This repository owns the scheduler behavior implemented with REXX.

## State Model

The scheduler vocabulary is:

```text
DEFINED
   |
   v
ORDERED          <-- VALIDATED
   |
   +--> HELD
   +--> WAIT_TIME
   +--> WAIT_COND
   +--> WAIT_RESOURCE
   |
   v
READY            <-- VALIDATED
   |
   v
SUBMITTED        <-- NEXT CAPABILITY GATE
   |
   v
EXECUTING
   |
   +--> ENDED_OK
   +--> ENDED_NOTOK
   +--> ABENDED
   +--> JCL_ERROR
```

Only explicitly evidenced transitions are treated as implemented.

## Capability Roadmap

| Capability | Evidence state |
| --- | --- |
| Definition model and validation | **VALIDATED LOCALLY — Lab 01** |
| ORDER and active-instance creation | **VALIDATED LOCALLY — Lab 01** |
| Negative-path active-state integrity | **VALIDATED LOCALLY — Lab 01** |
| Persistent Order-ID | **VALIDATED LOCALLY — Lab 02 Part 1** |
| `ORDERED -> READY` eligibility | **VALIDATED LOCALLY — Lab 02 Part 2** |
| Invalid repeated eligibility transition rejection | **VALIDATED LOCALLY — Lab 02 Part 2** |
| `READY -> SUBMITTED` / JES2 submission | **NEXT — Lab 02 Part 3** |
| Persistent JOBID association / execution tracking | **PLANNED — Lab 03** |
| RC / JCL error / ABEND classification | **PLANNED — Lab 04** |
| Conditions and dependencies | **PLANNED — Lab 05** |
| HOLD / FREE operator control | **PLANNED — Lab 06** |
| Quantitative / shared-exclusive resources | **PLANNED — Lab 07** |
| Rerun / restart integration | **PLANNED — Lab 08** |
| Calendars / logical production day | **PLANNED — Lab 09** |
| Execution history / statistics | **PLANNED — Lab 10** |
| ISPF Active Environment | **PLANNED — Lab 11** |
| Started-task scheduler monitor | **PLANNED — Lab 12** |
| RACF / JES / SDSF security integration | **PLANNED — Lab 13** |
| SMF observability / audit | **PLANNED — Lab 14** |
| Event-driven triggering | **PLANNED — Lab 15** |
| Integrated Db2 / USS / CICS production flows | **PLANNED — Lab 16+** |

## Evidence Method

Scheduler capabilities follow the portfolio engineering cycle:

```text
BUILD
  ->
EXECUTE
  ->
OBSERVE
  ->
DIAGNOSE
  ->
CORRECT
  ->
VALIDATE
  ->
DOCUMENT
```

Scheduler-specific validation additionally asks:

```text
What was the state before the operation?
What control logic was executed?
Was the transition legal?
What state exists afterward?
What negative path proves the integrity rule?
```

The repository preserves negative tests because rejection behavior is part of scheduler correctness.

## Validation States

Public documentation distinguishes:

```text
VALIDATED LOCALLY
    proven by evidence in this repository

VALIDATED IN TARGET REPOSITORY
    proven by evidence owned by another repository

CROSS-DOMAIN / REQUIRES EVIDENCE
    architecture exists but the complete path is not yet proven

NEXT
    immediate capability gate with an established handoff

PLANNED
    roadmap capability, not completed work
```

A capability implemented elsewhere in the portfolio does not automatically become a validated scheduler integration.

## Domain Boundaries

This repository owns scheduler control behavior.

It does **not** own:

- JCL semantics and reusable batch mechanics — `JCL_LABS`;
- JES2 system administration — core z/OS engineering;
- general REXX language learning — `Rexx`;
- TSO/E and ISPF fundamentals — `MVS_TSO_ISPF`;
- COBOL, Db2, VSAM, PL/I or HLASM application/data behavior;
- RACF policy and security administration;
- USS fundamentals;
- Communications Server networking;
- system-wide diagnostics, recovery, storage or SMF engineering.

Cross-domain capabilities must be validated by the repositories that own those layers or by a dedicated Production Track.

## Architecture V2

The repository participates in the portfolio lifecycle:

```text
Discover -> Baseline -> Configure -> Operate -> Observe
        -> Diagnose -> Recover -> Improve -> Automate -> Integrate
```

Capability maturity:

```text
M0 Exploratory -> M1 Foundational -> M2 Operational
               -> M3 Resilient -> M4 Automated -> M5 Integrated
```

Integration maturity:

```text
I0 Standalone -> I1 Cross-component -> I2 Cross-repository
              -> I3 Production-like
```

Maturity is capability-scoped. The presence of Architecture V2 metadata does not upgrade unevidenced scheduler features.

## Publication Security

Before publication, review source, spool output, terminal captures and screenshots for credentials, secrets, private network information, MAC addresses, adapter identifiers, unnecessary hostnames, local workstation paths, and terminal/session identifiers.

The validated scheduler work remains isolated under the user-owned `IBMUSER.ZSCH.*` namespace and does not claim changes to JES2 initialization, RACF policy, PARMLIB, PROCLIB, SMF configuration, or network configuration.

## Continue Through the Portfolio

```text
MVS_TSO_ISPF
      |
      v
   JCL_LABS
      |
      v
zos-batch-scheduler
      |
      +--> Enterprise Batch Operations
      +--> application workloads
      +--> automation
      +--> security
      +--> diagnostics / recovery
```

- [Ecosystem Integration](docs/ECOSYSTEM-INTEGRATION.md)
- [JCL Engineering Labs](https://github.com/P-dot/JCL_LABS)
- [Master z/OS Engineering Laboratory](https://github.com/P-dot/zos-adcd-hercules-engineering-lab)
- [IBM z/OS Engineering Portfolio](https://github.com/P-dot/P-dot)


---

## z/OS Engineering Academy

**Academy role:** Automation School — workload dependencies, eligibility, operational state and restart.

[Start the Academy](https://github.com/P-dot/P-dot/blob/main/docs/ACADEMY.md) · [Course Catalog](https://github.com/P-dot/P-dot/blob/main/docs/COURSES.md) · [Curriculum Graph](https://github.com/P-dot/P-dot/blob/main/docs/CURRICULUM.md) · [Cross-Domain Relationships](https://github.com/P-dot/P-dot/blob/main/docs/RELATIONSHIPS.md)

> Learn the concept → execute the lab → interpret the evidence → understand the subsystem boundary → continue to the next connected course.
