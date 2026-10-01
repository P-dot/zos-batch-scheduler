# z/OS Batch Scheduler — Ecosystem Integration

## Purpose

This document defines how `zos-batch-scheduler` participates in the IBM z/OS Engineering Portfolio and where its current evidence boundary lies.

The repository is the **workload-orchestration and production-control layer**. It owns scheduler state and scheduler decisions. It does not replace JCL or JES2.

```text
Scheduler decides and controls.
JCL describes the workload.
JES2 executes the workload.
```

## Current Evidence Boundary

The scheduler currently proves:

```text
DEFINITION
    |
    v
VALIDATION
    |
    v
ORDER
    |
    v
persistent runtime identity
    |
    v
STATE=ORDERED
    |
    v
eligibility
    |
    v
STATE=READY
JOBID=
    |
    X
    |
   JES2
```

`X` is deliberate.

The scheduler-to-JES2 execution boundary has **not** yet been crossed by validated scheduler evidence.

Lab 02 Part 3 is the next capability gate.

## Repository Ownership

### Owned here

The validated scheduler scope currently includes:

- scheduler-owned `IBMUSER.ZSCH.*` libraries;
- permanent job-definition metadata;
- definition validation through `ZSCHVAL`;
- ORDER processing through `ZSCHORD`;
- active runtime occurrences;
- explicit runtime state;
- invalid-definition rejection before active-state creation;
- active-state integrity after rejected ORDER;
- persistent Order-ID generation;
- sequence persistence through `SEQ01`;
- independent runtime occurrences;
- eligibility evaluation through `ZSCHEVL`;
- controlled `ORDERED -> READY`;
- rejection of an invalid repeated eligibility transition;
- workload JCL references stored in runtime metadata.

### Not owned here

The repository does not replace:

- `MVS_TSO_ISPF` for TSO/E and ISPF fundamentals;
- `Rexx` for general REXX language learning;
- `JCL_LABS` for JCL semantics and reusable batch mechanics;
- core z/OS engineering for JES2 system administration;
- application/data repositories for COBOL, Db2, VSAM, PL/I or HLASM behavior;
- `UNIX_System_Services-` for USS fundamentals;
- `mainframe-racf-security-evidence` for RACF policy and authorization;
- `zos-communications-server-network-lab` for networking;
- diagnostic/recovery repositories for system-wide problem determination and recovery.

The ownership rule is:

```text
scheduler control logic       -> zos-batch-scheduler
JCL workload mechanics        -> JCL_LABS
JES2 execution engine         -> z/OS platform
application/subsystem logic   -> owning domain repository
cross-domain proof            -> dedicated integration evidence
```

## Validated Foundation — Lab 01

[Lab 01](../labs/01-architecture-job-definitions-active-state-model/README.md) established the scheduler control-plane foundation.

Validated path:

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
STATE=ORDERED
JOBID=
```

Validated integrity path:

```text
invalid definition
      |
      v
   ZSCHVAL
      |
      v
    RC=8
      |
      v
ORDER rejected
      |
      v
no modification of valid active state
```

Status: **VALIDATED LOCALLY**

Lab 01 deliberately did not submit workload to JES2.

## Runtime Identity — Lab 02 Part 1

[Lab 02](../labs/02-persistent-order-id-ready-eligibility/README.md) replaced the fixed demonstration identifier with persistent runtime identity.

Validated behavior:

```text
A0000001
   |
   | remains preserved
   |
   +----------------------+
                          |
definition -> ZSCHORD -> SEQ01
                          |
                          v
                    LASTID=0000002
                          |
                          v
                    A0000002
```

The validated runtime identifier is persistent and monotonically increasing. The lab explicitly does not require a gapless sequence.

Status: **VALIDATED LOCALLY**

## Eligibility — Lab 02 Part 2

Part 2 introduced `ZSCHEVL`.

Validated transition:

```text
ACTIVE(A0000002)
STATE=ORDERED
      |
      v
   ZSCHEVL
      |
      +--> TIME CHECK    : NOT CONFIGURED
      +--> CONDITIONS    : NOT CONFIGURED
      +--> RESOURCES     : NOT CONFIGURED
      +--> OPERATOR HOLD : NOT CONFIGURED
      |
      v
eligibility satisfied
      |
      v
STATE=READY
JOBID=
```

The explicit `NOT CONFIGURED` results are important. They prevent the repository from implying support for scheduling criteria that have not yet been implemented.

Negative validation:

```text
STATE=READY
    |
    | run ZSCHEVL again
    v
READY -> READY
    |
    v
REJECTED
```

Status: **VALIDATED LOCALLY**

## Next Capability Gate — Lab 02 Part 3

The existing Part 3 handoff defines the next transition:

```text
ACTIVE(A0000002)
STATE=READY
      |
      v
    ZSCHSUB
      |
      +--> verify READY
      +--> read JCLDSN / MEMBER
      +--> validate referenced JCL
      |
      v
TSO/E SUBMIT or validated controlled path
      |
      v
     JES2
      |
      v
STATE=SUBMITTED
```

State-safety rule:

```text
successful submission observed
            |
       +----+----+
       |         |
      yes        no
       |         |
       v         v
 SUBMITTED     remain recoverable
```

The scheduler must not claim `STATE=SUBMITTED` merely because a submission was attempted.

Status: **NEXT — NOT YET VALIDATED**

Durable JOBID association and continuing JES2/SDSF tracking remain a later capability unless Part 3 independently proves them.

## Scheduler / JCL / JES2 Boundary

Runtime responsibility is:

```text
zos-batch-scheduler
        |
        | scheduler decision
        v
       JCL
        |
        | workload description
        v
      JES2
        |
        | execution
        v
 workload program / utility
```

`JCL_LABS` has independently validated JCL and JES2 batch mechanics. That evidence is a portfolio dependency, not proof that this scheduler has already submitted a workload.

Therefore:

```text
JCL/JES2 capability exists elsewhere
                !=
scheduler-to-JES2 integration validated here
```

This distinction is central to the portfolio evidence model.

## Portfolio Learning Path vs Runtime Architecture

The portfolio learning progression is:

```text
MVS_TSO_ISPF
      |
      v
   JCL_LABS
      |
      v
zos-batch-scheduler
```

The scheduler runtime dependency is:

```text
scheduler
    |
    v
   JCL
    |
    v
  JES2
```

The two views serve different purposes and should not be conflated.

## MVS TSO/ISPF Relationship

`MVS_TSO_ISPF` provides the interactive operator environment used to:

- maintain scheduler members;
- execute REXX control programs;
- inspect scheduler-owned PDS libraries;
- inspect active runtime state.

Classification: **FOUNDATIONAL DEPENDENCY**

The scheduler owns the scheduler semantics performed through that environment.

## REXX Relationship

REXX is the current scheduler implementation mechanism.

Current programs include:

```text
ZSCHVAL   definition validation
ZSCHORD   ORDER processing
ZSCHEVL   eligibility evaluation
```

Classification: **IMPLEMENTATION DEPENDENCY**

General REXX semantics remain owned by `Rexx`; scheduler state-machine behavior remains owned here.

## JCL_LABS Relationship

`JCL_LABS` supplies reusable batch workload mechanics and JES2-facing concepts.

The scheduler active record already stores:

```text
JCLDSN=IBMUSER.ZSCH.JCL
MEMBER=LAB01A
```

This is a validated **metadata relationship**.

It is not yet a validated submission relationship.

Classification:

```text
JCL reference metadata ........ VALIDATED LOCALLY
scheduler -> JES2 submission .. NEXT / REQUIRES EVIDENCE
```

## Application and Data Workloads

The scheduler is designed to orchestrate workloads owned by other domains.

Future examples include:

```text
scheduler
   |
   +--> COBOL batch
   +--> DFSORT
   +--> VSAM workflows
   +--> Db2 batch / utilities
   +--> USS / BPXBATCH
   +--> CICS-related operational flows
```

At the current evidence level these are architectural consumers, not completed scheduler integrations.

Classification: **PLANNED / CROSS-DOMAIN**

## State Model

The scheduler vocabulary is broader than the implemented state machine:

```text
DEFINED
   |
   v
ORDERED              VALIDATED
   |
   +--> HELD          PLANNED
   +--> WAIT_TIME     PLANNED
   +--> WAIT_COND     PLANNED
   +--> WAIT_RESOURCE PLANNED
   |
   v
READY                VALIDATED
   |
   v
SUBMITTED            NEXT
   |
   v
EXECUTING            PLANNED
   |
   +--> ENDED_OK      PLANNED
   +--> ENDED_NOTOK   PLANNED
   +--> ABENDED       PLANNED
   +--> JCL_ERROR     PLANNED
```

Defining a state name is not equivalent to implementing the transition into that state.

## Validation Classification

Use these states consistently:

| State | Meaning |
| --- | --- |
| `VALIDATED LOCALLY` | Proven by evidence inside this repository |
| `VALIDATED IN TARGET REPOSITORY` | Proven by evidence owned by another repository |
| `CROSS-DOMAIN / REQUIRES EVIDENCE` | Architecture is defined but the complete path is not yet proven |
| `NEXT` | Immediate capability gate with a concrete handoff |
| `PLANNED` | Roadmap capability, not completed work |

## Current Capability Matrix

| Capability | Classification | Evidence |
| --- | --- | --- |
| Scheduler library architecture | VALIDATED LOCALLY | Lab 01 |
| Definition model | VALIDATED LOCALLY | Lab 01 |
| Positive/negative definition validation | VALIDATED LOCALLY | Lab 01 |
| ORDER processing | VALIDATED LOCALLY | Lab 01 |
| Active runtime-instance creation | VALIDATED LOCALLY | Lab 01 |
| Invalid ORDER preserves valid active state | VALIDATED LOCALLY | Lab 01 |
| JCLDSN / MEMBER runtime metadata | VALIDATED LOCALLY | Lab 01 |
| Persistent Order-ID | VALIDATED LOCALLY | Lab 02 Part 1 |
| Multiple independent runtime occurrences | VALIDATED LOCALLY | Lab 02 Part 1 |
| Eligibility evaluation | VALIDATED LOCALLY | Lab 02 Part 2 |
| `ORDERED -> READY` | VALIDATED LOCALLY | Lab 02 Part 2 |
| Rejection of `READY -> READY` | VALIDATED LOCALLY | Lab 02 Part 2 |
| `READY -> SUBMITTED` | NEXT / REQUIRES EVIDENCE | Lab 02 Part 3 |
| Persistent JOBID association | PLANNED | Lab 03 |
| JES2/SDSF execution tracking | PLANNED | Lab 03 |
| RC / JCL error / ABEND classification | PLANNED | Lab 04 |
| Conditions / dependencies | PLANNED | Lab 05 |
| HOLD / FREE | PLANNED | Lab 06 |
| Resource control | PLANNED | Lab 07 |
| Rerun / restart | PLANNED | Lab 08 |
| Calendars / production day | PLANNED | Lab 09 |
| History / statistics | PLANNED | Lab 10 |
| ISPF Active Environment | PLANNED | Lab 11 |
| Started-task monitor | PLANNED | Lab 12 |
| RACF / JES / SDSF security | PLANNED | Lab 13 |
| SMF observability / audit | PLANNED | Lab 14 |
| Event-driven triggering | PLANNED | Lab 15 |
| Integrated Db2 / USS / CICS flows | PLANNED | Lab 16+ |

## Production Track — Enterprise Batch Operations

Target architecture:

```text
scheduler
   |
   v
JCL / JES2
   |
   v
workload
   |
   v
RC / ABEND / execution state
   |
   v
scheduler decision
   |
   v
history / recovery / downstream eligibility
```

The portfolio already contains independent evidence for several underlying batch technologies. The complete scheduler-controlled production loop remains a **cross-domain integration target** until dedicated evidence proves it.

## Failure and Recovery Model

Scheduler failures must preserve control-plane integrity.

Preferred pattern:

```text
requested operation
      |
      v
validate precondition
      |
   +--+--+
   |     |
 valid  invalid
   |     |
   v     v
change  reject
state   operation
   |     |
   +--+--+
      |
      v
verify resulting state
```

Existing evidence already demonstrates:

- invalid permanent definition -> ORDER rejected;
- valid active state remains unchanged;
- invalid `READY -> READY` eligibility transition -> rejected;
- active instance remains in valid `READY`.

Future submission and tracking layers should retain the same fail-safe principle.

## Evidence Model

Scheduler evidence follows:

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

For stateful scheduler operations, evidence should additionally capture:

```text
BEFORE STATE
     |
     v
CONTROL OPERATION
     |
     v
MESSAGES / RC
     |
     v
AFTER STATE
     |
     v
NEGATIVE / INTEGRITY TEST
```

This makes scheduler claims reproducible rather than architectural assertions.

## Architecture V2

Portfolio lifecycle:

```text
Discover -> Baseline -> Configure -> Operate -> Observe
        -> Diagnose -> Recover -> Improve -> Automate -> Integrate
```

Maturity:

```text
M0 Exploratory
M1 Foundational
M2 Operational
M3 Resilient
M4 Automated
M5 Integrated
```

Integration:

```text
I0 Standalone
I1 Cross-component
I2 Cross-repository
I3 Production-like
```

Lab 02 metadata classifies its current runtime identity and eligibility capability as `M2 - Operational` and `I1 - Cross-component`.

That classification applies to the evidenced capability. It does not mean the complete scheduler has reached M2/I1 for every roadmap function.

## Cross-Repository Production Targets

### Execution tracking

```text
scheduler -> JES2 -> JOBID -> observation -> scheduler state
```

Status: **PLANNED**

### Result classification

```text
JES2 result
   |
   +--> acceptable RC ----> ENDED_OK
   +--> unacceptable RC --> ENDED_NOTOK
   +--> ABEND -----------> ABENDED
   +--> JCL error -------> JCL_ERROR
```

Status: **PLANNED**

### Dependencies

```text
JOB A -> OUT condition -> JOB B eligibility
```

Status: **PLANNED**

### Resources

```text
request -> resource model
              |
        +-----+-----+
        |           |
   available    unavailable
        |           |
        v           v
      READY    WAIT_RESOURCE
```

Status: **PLANNED**

### Operator control

```text
ISPF / REXX
     |
     v
active environment
     |
     +--> HOLD
     +--> FREE
     +--> rerun
     +--> restart
```

Status: **PLANNED**

### Security and observability

```text
operator / scheduler identity
          |
          v
        RACF
          |
          v
scheduler / JES2 actions
          |
          +--> SDSF
          +--> SMF
```

Status: **PLANNED**

## Engineering Control

New capabilities should pass this gate:

```text
IMPLEMENT
   |
   v
EXECUTE
   |
   v
OBSERVE
   |
   v
VALIDATE POSITIVE PATH
   |
   v
VALIDATE NEGATIVE / INTEGRITY PATH
   |
   v
CLASSIFY
   |
   v
PUBLISH
```

A roadmap state should be promoted only after evidence exists.

## Publication Security

Before publication, inspect source, JCL, REXX output, spool captures, ISPF screenshots and documentation for:

- credentials and secrets;
- private keys or tokens;
- private IP addresses;
- MAC addresses;
- adapter identifiers;
- unnecessary hostnames;
- local workstation paths;
- terminal/session identifiers;
- other host/network details that do not contribute to the engineering evidence.

The current scheduler work is intentionally isolated under:

```text
IBMUSER.ZSCH.*
```

The validated labs do not claim changes to JES2 initialization, RACF policy, PARMLIB, PROCLIB, SMF configuration, or network configuration.

## Development Direction

The next engineering step is intentionally narrow:

```text
READY
  |
  v
validated submission request
  |
  v
JES2
  |
  v
SUBMITTED
```

Only after that boundary is proven should the repository move to durable JOBID association and execution tracking.

This sequencing preserves the design principle already established by Labs 01–02:

> Build scheduler control one observable state transition at a time.

## Navigation

- [Repository README](../README.md)
- [Lab 01](../labs/01-architecture-job-definitions-active-state-model/README.md)
- [Lab 02](../labs/02-persistent-order-id-ready-eligibility/README.md)
- [JCL Engineering Labs](https://github.com/P-dot/JCL_LABS)
- [REXX](https://github.com/P-dot/Rexx)
- [MVS TSO/ISPF](https://github.com/P-dot/MVS_TSO_ISPF)
- [Master z/OS Engineering Laboratory](https://github.com/P-dot/zos-adcd-hercules-engineering-lab)
- [IBM z/OS Engineering Portfolio](https://github.com/P-dot/P-dot)
