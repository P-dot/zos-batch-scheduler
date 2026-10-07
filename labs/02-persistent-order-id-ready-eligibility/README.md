# Lab 02 — Persistent Order-ID & READY Eligibility

## Architecture metadata

```yaml
lab:
  historical_id: "labs/02-persistent-order-id-ready-eligibility"
  title: "Persistent Order-ID and READY Eligibility"
  status: "VALIDATED - PARTS 1 AND 2"

architecture:
  primary_domain: "Workload and Batch Engineering"
  secondary_domains:
    - "Automation and Modern Operations"
    - "Integration Engineering"
  capability: "Scheduler runtime identity and eligibility-state management"
  lifecycle:
    - "Operate"
    - "Automate"
    - "Integrate"
  maturity: "M2 - Operational"
  integration_level: "I1 - Cross-component"

dependencies:
  - "D1 - Lab 01 scheduler definition and active-state foundation"
  - "D4 - TSO/E, ISPF, REXX and scheduler-owned PDS libraries"

failure_classification:
  - "F0 - Expected validation failure for invalid state transition"

relationships:
  components:
    - "TSO/E"
    - "ISPF"
    - "REXX"
    - "Scheduler metadata"
    - "Scheduler active state"
  repositories:
    - "zos-batch-scheduler"
    - "zos-adcd-hercules-engineering-lab"
  tags:
    - "REL-SCHED"
    - "REL-JCL"
    - "REL-JES2"
    - "REL-AUTOMATION"

next_capability:
  - "READY -> JES2 submission"
  - "SUBMITTED runtime state"
  - "JOBID capture and execution tracking in the following layer"
```

## Status

**PARTS 1 AND 2 COMPLETED AND VALIDATED**

Part 3 is intentionally not included in this closure.

The validated endpoint of this package is:

```text
ACTIVE(A0000002)
STATE=READY
JOBID=
```

The empty `JOBID` is correct because no JES2 submission has occurred yet.

---

## Objective

Extend the scheduler foundation built in Lab 01 so that runtime occurrences become individually identifiable, persistent, and subject to a controlled eligibility transition.

This lab adds two scheduler capabilities:

1. **Persistent Order-ID generation** — repeated ORDER operations must create independent active runtime instances rather than reuse a fixed identifier.
2. **Eligibility evaluation** — an active instance must transition from `ORDERED` to `READY` through scheduler logic rather than by manual editing.

The lab deliberately stops before JES2 submission.

That boundary is important. A production-control scheduler should first know **which runtime occurrence it is controlling** and **whether that occurrence is eligible** before it is allowed to submit workload.

---

## Engineering context

### What existed before this lab

Lab 01 established the first functional scheduler control model.

The validated Lab 01 path was:

```text
PERMANENT DEFINITION
        |
        v
     ZSCHVAL
        |
        v
      ORDER
        |
        v
     ZSCHORD
        |
        v
ACTIVE(A0000001)
        |
        v
 STATE=ORDERED
```

Lab 01 proved several foundational rules:

- permanent scheduler metadata is separate from JCL;
- `ZSCHVAL` validates the minimum job-definition contract;
- invalid definitions are rejected before active-state creation;
- `ZSCHORD` creates an independent runtime record;
- the runtime state is explicit;
- the workload JCL is referenced but not submitted.

The first active instance contained:

```text
ORDERID=0000001
NAME=LAB01A
STATE=ORDERED
JOBID=
RUNNO=1
JCLDSN=IBMUSER.ZSCH.JCL
MEMBER=LAB01A
OWNER=IBMUSER
MAXRC=4
RERUN=YES
```

However, Lab 01 intentionally used a fixed value:

```text
ORDERID=0000001
ACTIVE member=A0000001
```

That was sufficient to validate the definition/active separation, but it was not sufficient for repeated runtime occurrences.

### Why Lab 02 is necessary

A scheduler definition and a runtime occurrence are not the same object.

One permanent definition may be ordered many times:

```text
LAB01A definition
       |
       +--> runtime occurrence 0000001
       |
       +--> runtime occurrence 0000002
       |
       +--> runtime occurrence 0000003
```

Each occurrence must be independently identifiable so that future layers can attach:

```text
ORDERID
ODATE
OTIME
STATE
JOBID
RUNNO
return code
ABEND
history
rerun/restart decisions
```

This lab therefore moves the project from a single demonstration instance toward a real active-runtime model.

---

## Relationship to the Control-M-inspired architecture

This project does not copy BMC proprietary implementation code, data structures, APIs, or internal formats.

It uses public enterprise-scheduler concepts as architectural references.

The important conceptual separation is:

```text
Scheduling definition
       |
       | order
       v
Active runtime occurrence
       |
       | scheduling criteria satisfied
       v
Eligible / ready workload
       |
       | submit
       v
JES2 execution
```

The Lab 01 equivalent was:

```text
definition -> ORDER -> active instance
```

Lab 02 Parts 1-2 extend that model to:

```text
definition
   |
   v
ORDER
   |
   v
persistent runtime identity
   |
   v
ACTIVE / ORDERED
   |
   v
eligibility evaluation
   |
   v
READY
```

This is the scheduler control plane. JES2 remains the execution engine.

The architectural rule continues to be:

```text
Scheduler decides and controls.
JCL describes the workload.
JES2 executes the workload.
```

---

# Part 1 — Persistent Order-ID

## Problem being solved

The original `ZSCHORD` used:

```rexx
orderid = '0000001'
actmem  = 'A0000001'
```

A second ORDER would therefore attempt to reuse the same runtime identity.

That is not acceptable once the scheduler begins handling multiple occurrences of the same definition.

## Persistent sequence store

A new scheduler parameter member was introduced:

```text
IBMUSER.ZSCH.PARM(SEQ01)
```

Initial value:

```text
LASTID=0000001
```

The initial value reflects the fact that Lab 01 had already consumed runtime identifier `0000001`.

## Updated `ZSCHORD`

`ZSCHORD` now:

```text
validate definition
      |
      v
read SEQ01
      |
      v
validate LASTID
      |
      v
increment
      |
      v
format as seven digits
      |
      v
persist new LASTID
      |
      v
create ACTIVE(Axxxxxxx)
```

The sequence member is allocated using exclusive access:

```rexx
"ALLOC F(SEQDD) DA('"seqdsn"') OLD REUSE"
```

The laboratory does not claim production-grade multi-system sequence management, but using `OLD` avoids deliberately allowing concurrent writers to the small sequence store.

## Identifier policy

The runtime identifier is:

```text
unique
monotonically increasing
persistent
```

It is **not required to be gapless**.

If an identifier is reserved and a later action fails, the next ORDER may advance again rather than reuse the previous value. Avoiding identifier reuse is more important than guaranteeing consecutive numbers.

## Validated Part 1 result

The first new ORDER generated:

```text
ORDERID=0000002
ACTIVE MEMBER=A0000002
STATE=ORDERED
```

`SEQ01` was updated to:

```text
LASTID=0000002
```

The active library contained both:

```text
A0000001
A0000002
```

This proves that one permanent definition can produce multiple independent runtime occurrences.

---

# Part 2 — Eligibility Engine

## Problem being solved

Creating an active occurrence is not the same as declaring it ready for execution.

The scheduler state vocabulary already defined:

```text
ORDERED
HELD
WAIT_TIME
WAIT_COND
WAIT_RESOURCE
READY
SUBMITTED
...
```

Before this lab, only:

```text
DEFINED -> ORDERED
```

was implemented.

Lab 02 Part 2 introduces the first executable eligibility transition:

```text
ORDERED -> READY
```

## `ZSCHEVL`

New REXX program:

```text
IBMUSER.ZSCH.EXEC(ZSCHEVL)
```

Its responsibilities are:

- read an active runtime instance;
- verify that required runtime fields exist;
- verify the current state;
- evaluate the eligibility criteria available at this maturity stage;
- update the runtime state while preserving all other metadata;
- reject an invalid repeated transition.

## Current eligibility model

Time windows, logical conditions, quantitative resources and operator HOLD are not implemented yet.

The evaluator therefore reports them explicitly as:

```text
TIME CHECK     : NOT CONFIGURED
CONDITIONS     : NOT CONFIGURED
RESOURCES      : NOT CONFIGURED
OPERATOR HOLD  : NOT CONFIGURED
```

This is deliberate.

The scheduler must not pretend that a capability exists before it has been implemented and validated.

At this stage, an `ORDERED` instance with no implemented blockers is eligible for:

```text
READY
```

## State-transition rule

The only transition allowed by this evaluator version is:

```text
ORDERED -> READY
```

If the current state is anything else, the transition is rejected.

This prevents arbitrary state manipulation and establishes an important scheduler rule:

> Runtime state changes are controlled operations governed by explicit transition logic.

## Positive validation

Before evaluation:

```text
IBMUSER.ZSCH.ACTIVE(A0000002)

STATE=ORDERED
JOBID=
```

Execution:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHEVL)' 'A0000002'
```

Observed result:

```text
ZSCH311I CURRENT STATE : ORDERED
ZSCH312I CHECKING SCHEDULER ELIGIBILITY
ZSCH313I TIME CHECK     : NOT CONFIGURED
ZSCH314I CONDITIONS     : NOT CONFIGURED
ZSCH315I RESOURCES      : NOT CONFIGURED
ZSCH316I OPERATOR HOLD  : NOT CONFIGURED
ZSCH317I ELIGIBILITY    : SATISFIED
...
OLD STATE : ORDERED
NEW STATE : READY
...
ZSCH300I INSTANCE IS READY
```

After evaluation:

```text
STATE=READY
JOBID=
```

All other runtime metadata remained present.

## Negative validation

The evaluator was executed a second time against the same instance after it had already reached `READY`.

Observed result:

```text
ZSCH320E INSTANCE IS NOT ELIGIBLE FROM STATE: READY
ZSCH321E EXPECTED STATE: ORDERED
```

This is an expected validation failure (`F0`) and is evidence that the state machine is being enforced.

---

## Validated control path after Parts 1 and 2

```text
IBMUSER.ZSCH.DEF(LAB01A)
          |
          v
       ZSCHVAL
          |
          v
       ZSCHORD
          |
          +--> SEQ01 persistent identity
          |
          v
IBMUSER.ZSCH.ACTIVE(A0000002)
          |
          v
     STATE=ORDERED
          |
          v
       ZSCHEVL
          |
          v
eligibility satisfied
          |
          v
      STATE=READY
          |
          X
        JES2
```

The `X` is a deliberate laboratory boundary.

---

## Components involved

| Component | Role in this lab |
|---|---|
| `IBMUSER.ZSCH.DEF` | Permanent scheduler definitions from Lab 01 |
| `IBMUSER.ZSCH.JCL` | Referenced workload JCL; still not submitted |
| `IBMUSER.ZSCH.EXEC(ZSCHVAL)` | Existing definition validation |
| `IBMUSER.ZSCH.EXEC(ZSCHORD)` | Updated ORDER processing with persistent identity |
| `IBMUSER.ZSCH.EXEC(ZSCHEVL)` | New eligibility evaluator |
| `IBMUSER.ZSCH.PARM(SEQ01)` | Persistent last-issued Order-ID |
| `IBMUSER.ZSCH.ACTIVE` | Runtime active-instance store |
| TSO/E / ISPF | Operator and execution environment |
| REXX / EXECIO | Scheduler control implementation |

---

## Commands executed

Persistent ORDER:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHORD)' 'LAB01A'
```

Eligibility evaluation:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHEVL)' 'A0000002'
```

Negative state-transition test:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHEVL)' 'A0000002'
```

The second evaluator execution is intentionally expected to fail after the state has already become `READY`.

---

## Validation matrix

| Test | Expected result | Actual result |
|---|---|---|
| Initialize `SEQ01` | `LASTID=0000001` | **PASS** |
| ORDER valid `LAB01A` | Definition remains valid | **PASS** |
| Generate next runtime identifier | `0000002` | **PASS** |
| Persist sequence | `LASTID=0000002` | **PASS** |
| Preserve previous active instance | `A0000001` remains | **PASS** |
| Create new runtime instance | `A0000002` created | **PASS** |
| Initial new runtime state | `STATE=ORDERED` | **PASS** |
| Evaluate eligibility | Satisfied at current scope | **PASS** |
| Transition state | `ORDERED -> READY` | **PASS** |
| Preserve runtime metadata | No unrelated fields lost | **PASS** |
| JOBID before JES2 | Empty | **PASS** |
| Repeat evaluator from READY | Reject transition | **PASS** |

---

## Failure / exception analysis

The negative execution:

```text
READY -> READY
```

was intentionally rejected.

Classification:

```text
F0 — Expected validation failure
```

This is not a defect.

It is evidence that the scheduler does not permit uncontrolled transitions.

No recovery action is required because the active instance remains in the valid `READY` state.

---

## Recovery / rollback

Parts 1-2 do not modify JES2 configuration, system libraries, RACF profiles, PARMLIB or PROCLIB.

The persistent scheduler state affected by the lab is limited to the user-owned namespace:

```text
IBMUSER.ZSCH.*
```

For laboratory rollback, the operator can restore the previous `ZSCHORD`, remove `ZSCHEVL`, reset `SEQ01` only if the associated active test instances are also reconciled, and remove test active members as appropriate.

Sequence rollback must not be performed independently of active-instance cleanup because that could cause identifier reuse.

---

## Security and publication review

This lab does not require:

- credentials;
- passwords;
- private keys;
- network configuration;
- IP addresses;
- MAC addresses;
- host adapter information.

Before publication, evidence should still be scanned for unnecessary host/network identifiers and secrets.

The scheduler continues to operate only under:

```text
IBMUSER.ZSCH.*
```

No system-wide authority model is claimed yet.

RACF/JES/SDSF security integration remains a later scheduler capability.

---

## Cross-repository relationships

### Core Platform

The z/OS Engineering Laboratory provides the common runtime environment and Architecture V2 methodology.

### REXX

REXX remains the control-language implementation for the current scheduler stage.

### JCL / JES2

The active runtime instance already preserves:

```text
JCLDSN=IBMUSER.ZSCH.JCL
MEMBER=LAB01A
```

The relationship exists as metadata, but actual scheduler-controlled submission remains outside the validated scope of Parts 1-2.

### Enterprise Batch Operations

The broader production track already contains validated batch foundations involving JES2, JCL, COBOL, DFSORT, GDG and restart/rerun.

The scheduler is now becoming the production-control layer that will eventually orchestrate those capabilities instead of merely demonstrating them independently.

---

## Why Part 3 is next

Parts 1-2 solve two questions:

```text
Which runtime occurrence am I controlling?
Is that occurrence eligible?
```

They do not yet answer:

```text
How does the scheduler cause the workload to enter JES2?
```

Part 3 will cross that boundary.

Target flow:

```text
ACTIVE(A0000002)
STATE=READY
      |
      v
    ZSCHSUB
      |
      +--> verify READY
      |
      +--> read JCLDSN / MEMBER
      |
      v
IBMUSER.ZSCH.JCL(LAB01A)
      |
      v
TSO/E SUBMIT or controlled internal-reader path
      |
      v
     JES2
      |
      v
STATE=SUBMITTED
```

This is important because an enterprise scheduler is not merely a metadata database. Once eligibility is satisfied, it must hand eligible workload to the execution engine in a controlled and observable way.

In this design:

```text
Scheduler -> decides eligibility and submits
JCL       -> describes the workload
JES2      -> executes the workload
```

### Part 3 boundary

Part 3 will validate the first real scheduler-controlled submission to JES2 and the transition to `SUBMITTED`.

Robust, persistent JOBID capture and continuing JES2/SDSF execution tracking remain the next capability layer and should not be claimed before they are separately validated.

This preserves the repository roadmap:

```text
Lab 02 -> submission
Lab 03 -> JOBID capture and execution tracking
```

---

## Evidence

The evidence package contains the screenshots extracted from the execution document supplied for this lab.

It covers:

- updated `ZSCHORD` source;
- initial `SEQ01`;
- persistent ORDER command;
- generated `ORDERID=0000002`;
- new `A0000002` runtime instance;
- persisted `LASTID=0000002`;
- coexistence of `A0000001` and `A0000002`;
- complete `ZSCHEVL` source;
- `A0000002` before evaluation in `ORDERED`;
- successful eligibility transition;
- `A0000002` after evaluation in `READY`;
- second evaluator execution;
- expected rejection of `READY -> READY`.

See [`evidence/README.md`](evidence/README.md).

---

## Result

### Execution result

**PASS**

The persistent ORDER path and eligibility evaluator executed as designed.

### Validation result

**PASS**

Both positive and negative paths were validated.

### Operational result

**PASS**

The scheduler now supports multiple runtime occurrences and a controlled `ORDERED -> READY` transition.

### Security result

**PASS WITH CURRENT SCOPE**

No system security configuration was modified.

### Recovery result

**DOCUMENTED**

State rollback implications are documented; no recovery action was required.

### Publication result

**READY AFTER LOCAL SECURITY SCAN**

Evidence and text must pass the repository publication scan before commit.

---

## What this lab does not claim

This closure does **not** claim:

- JES2 submission;
- `STATE=SUBMITTED`;
- JOBID persistence;
- SDSF execution tracking;
- `STATE=EXECUTING`;
- RC classification;
- ABEND classification;
- JCL-error classification;
- time windows;
- IN/OUT conditions;
- resource acquisition;
- HOLD/FREE;
- production-day logic;
- started-task monitoring.

These remain future capabilities.

---

## Lessons learned

1. Runtime identity must be independent from the permanent job definition.
2. Persistent identity must survive a single REXX invocation.
3. Scheduler state should be changed by explicit control logic, not manual editing.
4. An eligibility decision and an execution request are separate operations.
5. Unsupported scheduling criteria should be reported as not configured rather than silently claimed.
6. Expected negative tests are part of scheduler integrity evidence.
7. JES2 submission should only be introduced after runtime identity and eligibility are trustworthy.

---

## Next capability

**Lab 02 — Part 3: READY to JES2 Submission**

The next validated transition will be:

```text
READY -> SUBMITTED
```

That is the point where the scheduler first moves from active-state control into real workload execution control.

---

## References

- BMC Control-M for z/OS documentation — Active Jobs File and Control-M utilities:
  - https://documents.bmc.com/supportu/INC/help/Main_help/en-US/76557.htm
  - https://documents.bmc.com/supportu/INC/9.0.21/en-US/INCONTROL_for_zOS_Utilities_Guide/Control-M_Utilities.htm
- IBM z/OS — TSO/E SUBMIT command:
  - https://www.ibm.com/docs/en/zos/3.2.0?topic=subcommands-submit-command
- IBM z/OS basic skills — submitting JCL for batch processing:
  - https://www.ibm.com/docs/en/zos-basic-skills?topic=sdsf-how-is-job-submitted-batch-processing
- IBM support — issuing TSO SUBMIT from a REXX exec:
  - https://www.ibm.com/support/pages/node/677177
- z/OS Engineering Laboratory Architecture V2:
  - https://github.com/P-dot/zos-adcd-hercules-engineering-lab/tree/main/docs/architecture/v2


---
### Continue learning

**Previous:** [01-architecture-job-definitions-active-state-model](../01-architecture-job-definitions-active-state-model/)  
**Course:** [Course home](../../README.md)  
**Next:** [Choose the next Academy course](https://github.com/P-dot/P-dot/blob/main/docs/COURSES.md)  
**Academy:** [z/OS Engineering Academy](https://github.com/P-dot/P-dot/blob/main/docs/ACADEMY.md) · [Curriculum](https://github.com/P-dot/P-dot/blob/main/docs/CURRICULUM.md)
