# Lab 01 — Scheduler Architecture, Job Definitions & Active State Model

## Status

**COMPLETED AND VALIDATED**

## Objective

Build the first functional foundation of the z/OS Batch Scheduler and validate the separation between:

1. a permanent **job definition**,
2. definition validation,
3. an **ORDER** operation,
4. and a runtime **active job instance**.

The lab deliberately stops before JES2 submission. The goal is to establish a trustworthy scheduler control model before the scheduler is allowed to submit workload.

## Environment

- IBM z/OS ADCD 1.11 under Hercules
- TSO/E
- ISPF
- JES2 / SDSF
- REXX
- PDS libraries using FB/80 records
- User-owned namespace: `IBMUSER.ZSCH.*`

## Conceptual model

Enterprise batch schedulers separate job scheduling definitions from the runtime active environment. BMC Control-M for z/OS describes an Active Jobs File containing copies of ordered job scheduling definitions and their runtime status. Only jobs present in that active environment are candidates for submission.

This laboratory adopts the same **general production-control concept**, while implementing all code and formats independently.

```text
                 PERMANENT DEFINITION
                         |
                 ZSCH.DEF(LAB01A)
                         |
                         | validate
                         v
                     ZSCHVAL
                         |
                         | ORDER
                         v
                     ZSCHORD
                         |
                         v
              ZSCH.ACTIVE(A0000001)
                         |
                         v
                   STATE=ORDERED
```

At the end of Lab 01, the scheduler understands a definition and can create an active runtime object, but it still does **not** submit the JCL to JES2.

## Data set architecture

The scheduler is isolated under `IBMUSER.ZSCH.*`.

| Data set | Purpose |
|---|---|
| `IBMUSER.ZSCH.JCL` | Scheduler-controlled JCL workloads and allocation jobs |
| `IBMUSER.ZSCH.DEF` | Permanent job definitions |
| `IBMUSER.ZSCH.EXEC` | REXX scheduler programs |
| `IBMUSER.ZSCH.ACTIVE` | Runtime active job instances |
| `IBMUSER.ZSCH.PARM` | Scheduler parameters and state vocabulary |

All five libraries were successfully created and cataloged. No `SYS1.*`, JES2PARM, PROCLIB, RACF or system-wide configuration was modified.

## Lab components

### `JCL(ALLOC01)`

Creates the initial scheduler libraries:

- `IBMUSER.ZSCH.DEF`
- `IBMUSER.ZSCH.EXEC`
- `IBMUSER.ZSCH.ACTIVE`
- `IBMUSER.ZSCH.PARM`

The JCL uses `IEFBR14` with `DISP=(NEW,CATLG,DELETE)` and PDS allocation parameters `DSORG=PO,RECFM=FB,LRECL=80`.

SDSF evidence confirmed `COND CODE 0000` for all allocation steps and catalog messages for each data set.

### `JCL(LAB01A)`

Minimal scheduler-controlled test workload:

```jcl
//LAB01A  JOB (ACCT),'ZSCH TEST JOB',
//             CLASS=A,MSGCLASS=X,
//             MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*
//* Z/OS BATCH SCHEDULER - TEST WORKLOAD
//*
//STEP01   EXEC PGM=IEFBR14
```

This job was **not submitted in Lab 01**. It exists only as the workload referenced by the scheduler definition.

### `DEF(LAB01A)` — valid definition

```text
NAME=LAB01A
JCLDSN=IBMUSER.ZSCH.JCL
MEMBER=LAB01A
OWNER=IBMUSER
INITIAL=DEFINED
MAXRC=4
RERUN=YES
```

The definition stores scheduler metadata independently from the JCL.

Meaning of the fields in this version:

| Field | Meaning |
|---|---|
| `NAME` | Logical scheduler job name |
| `JCLDSN` | PDS that contains the workload JCL |
| `MEMBER` | JCL member name |
| `OWNER` | Logical owner used by the scheduler |
| `INITIAL` | Initial definition state |
| `MAXRC` | Maximum acceptable return code policy for later labs |
| `RERUN` | Whether the definition allows future rerun logic |

`MAXRC` and `RERUN` are metadata only in Lab 01; runtime enforcement is intentionally deferred.

### `DEF(LAB01B)` — negative test definition

```text
NAME=LAB01B
JCLDSN=IBMUSER.ZSCH.JCL
MEMBER=LAB01A
INITIAL=DEFINED
MAXRC=4
RERUN=YES
```

`OWNER` is deliberately missing. This definition exists only to prove that invalid scheduler metadata is rejected.

### `PARM(STATE01)`

Initial scheduler state vocabulary:

```text
DEFINED
ORDERED
HELD
WAIT_TIME
WAIT_COND
WAIT_RESOURCE
READY
SUBMITTED
EXECUTING
ENDED_OK
ENDED_NOTOK
ABENDED
JCL_ERROR
```

This is the design vocabulary for the scheduler. Lab 01 implements only the early part of the lifecycle.

```text
DEFINED
   |
   | ZSCHORD
   v
ORDERED        <-- implemented in Lab 01
   |
   v
READY          <-- future
   |
   v
SUBMITTED      <-- future
   |
   v
EXECUTING      <-- future
   |
   +------> ENDED_OK
   +------> ENDED_NOTOK
   +------> ABENDED
   +------> JCL_ERROR
```

### `EXEC(ZSCHVAL)` — job definition validator

`ZSCHVAL` is the first functional scheduler program.

Execution syntax:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHVAL)' 'LAB01A'
```

Processing flow:

```text
member argument
      |
      v
IBMUSER.ZSCH.DEF(member)
      |
      v
ALLOC DEFDD
      |
      v
EXECIO * DISKR
      |
      v
parse KEY=VALUE records
      |
      v
validate mandatory fields
      |
  +---+---+
  |       |
valid   invalid
RC=0     RC=8
```

Mandatory fields validated in Lab 01:

- `NAME`
- `JCLDSN`
- `MEMBER`
- `OWNER`
- `INITIAL`
- `MAXRC`
- `RERUN`

Unknown keys generate warning message `ZSCH020W`.

Positive validation result for `LAB01A`:

```text
ZSCH010I VALIDATING DEFINITION: IBMUSER.ZSCH.DEF(LAB01A)
...
ZSCH000I DEFINITION VALID
```

Negative validation result for `LAB01B`:

```text
ZSCH010I VALIDATING DEFINITION: IBMUSER.ZSCH.DEF(LAB01B)
ZSCH104E OWNER MISSING
ZSCH900E DEFINITION INVALID - 1 ERROR(S)
```

This proves the validator does not merely parse records: it enforces a minimum definition contract.

### `EXEC(ZSCHORD)` — first ORDER implementation

`ZSCHORD` creates the first runtime Active Job instance.

Execution syntax:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHORD)' 'LAB01A'
```

Before creating runtime state, `ZSCHORD` invokes `ZSCHVAL`:

```text
ZSCHORD
   |
   v
ZSCHVAL
   |
   +---- invalid ----> ORDER REJECTED
   |
 valid
   |
   v
read definition
   |
   v
create ACTIVE member
```

This design establishes the first scheduler integrity rule:

> **An invalid permanent definition must never be allowed to create or modify active runtime state.**

## First active job instance

The successful `ORDER` operation created:

```text
IBMUSER.ZSCH.ACTIVE(A0000001)
```

Validated content:

```text
ORDERID=0000001
NAME=LAB01A
ODATE=20260906
OTIME=19:41:03
STATE=ORDERED
JOBID=
RUNNO=1
JCLDSN=IBMUSER.ZSCH.JCL
MEMBER=LAB01A
OWNER=IBMUSER
MAXRC=4
RERUN=YES
```

### Why `JOBID` is empty

This is correct and intentional.

```text
STATE=ORDERED
JOBID=
```

The scheduler has created a runtime instance, but the workload has not yet been submitted to JES2. A JES `JOBID` can only be associated with the scheduler instance after submission/tracking functionality is introduced.

### Why `A0000001` is fixed

Lab 01 uses a deliberately fixed identifier:

```text
ORDERID=0000001
ACTIVE member=A0000001
```

A persistent and incrementing Order-ID generator is intentionally deferred to Lab 02. This keeps the first experiment focused on definition/active separation and integrity rather than sequence persistence.

## Validation matrix

| Test | Expected result | Actual result |
|---|---|---|
| Allocate scheduler libraries | All steps RC=0000 | **PASS** |
| Validate `LAB01A` | Definition valid | **PASS** |
| Validate `LAB01B` without OWNER | Reject with one error | **PASS** |
| ORDER `LAB01A` | Create `A0000001` | **PASS** |
| Active instance initial state | `STATE=ORDERED` | **PASS** |
| JOBID before JES2 submission | Empty | **PASS** |
| ORDER invalid `LAB01B` | Reject order | **PASS** |
| Invalid ORDER modifies ACTIVE | Must not modify active state | **PASS** |

## Final integrity proof

After attempting:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHORD)' 'LAB01B'
```

the scheduler returned:

```text
ZSCH010I VALIDATING DEFINITION: IBMUSER.ZSCH.DEF(LAB01B)
ZSCH104E OWNER MISSING
ZSCH900E DEFINITION INVALID - 1 ERROR(S)
ZSCH202E ORDER REJECTED - INVALID DEFINITION
```

A subsequent browse of `IBMUSER.ZSCH.ACTIVE(A0000001)` showed the original valid instance unchanged.

Therefore the negative path terminates before active-state creation.

## What Lab 01 proves

```text
Infrastructure                     PASS
IBMUSER.ZSCH.* namespace           PASS
Job definition format              PASS
State vocabulary                   PASS
REXX definition parser             PASS
Positive validation                PASS
Negative validation                PASS
ORDER operation                    PASS
Active instance creation           PASS
Invalid ORDER rejection            PASS
Definition/active separation       PASS
Active-state integrity             PASS
```

## What Lab 01 intentionally does not implement

The following are **not** claimed by this laboratory:

- Persistent/incrementing Order-ID generation
- Multiple simultaneous instances of the same definition
- `ORDERED -> READY` eligibility evaluation
- JES2 submission
- JES JOBID capture
- SDSF execution tracking
- Runtime RC classification
- ABEND classification
- JCL error classification
- Conditions/dependencies
- Resource management
- HOLD/FREE operator intervention
- Rerun/restart execution
- Execution history
- ISPF application panels
- RACF authorization model
- Started-task monitor

These are future scheduler layers.

## Evidence

All screenshots were extracted from the execution document supplied for the lab and preserved under [`evidence/screenshots`](evidence/screenshots/).

The evidence covers:

1. initial PDS allocation characteristics,
2. `ALLOC01` source,
3. SDSF allocation RC=0000,
4. cataloged `IBMUSER.ZSCH.*` libraries,
5. test JCL,
6. valid and invalid definitions,
7. state vocabulary,
8. complete `ZSCHVAL` source,
9. positive and negative validator execution,
10. complete `ZSCHORD` source,
11. successful ORDER execution,
12. first Active Job instance,
13. invalid ORDER rejection,
14. and final proof that the valid Active instance remained unchanged.

See [`evidence/README.md`](evidence/README.md) for the screenshot index.

## Design relationship to Control-M concepts

The project does not copy Control-M implementation code or internal formats. It uses public Control-M documentation only as an architectural reference for enterprise scheduler concepts.

BMC documents that job scheduling definitions can be placed into an Active Jobs File and that only active jobs are candidates for later submission. It also documents job ordering utilities that place jobs into that Active Jobs File. Lab 01 reproduces the **general architectural separation** with an independent implementation:

```text
Control-M concept              ZSCH Lab 01 concept
--------------------------     -------------------------------
Scheduling definition          IBMUSER.ZSCH.DEF(member)
Ordering                       ZSCHORD
Definition validation          ZSCHVAL
Active Jobs File concept       IBMUSER.ZSCH.ACTIVE
Active runtime record          A0000001
Order ID                       ORDERID=0000001
```

This is an educational analogy, not binary, API, data-format or behavioral compatibility.

## Security and publication scope

Lab 01 operates exclusively under the user-owned `IBMUSER.ZSCH.*` namespace.

No changes were made to:

- `SYS1.PARMLIB`
- `SYS1.PROCLIB`
- JES2 initialization parameters
- RACF profiles
- system exits
- SMF configuration
- network configuration

Published evidence should continue to exclude host IP addresses, MAC addresses, adapter identifiers and other host-network details.

## Next lab

**Lab 02 — Persistent Order-ID, READY State & JES2 Submission**

Planned progression:

```text
DEFINITION
    |
    v
VALIDATE
    |
    v
ORDER
    |
    v
persistent ORDER-ID
    |
    v
ACTIVE / ORDERED
    |
    v
eligibility evaluation
    |
    v
READY
    |
    v
JES2 submission
    |
    v
JOBID association
```

Lab 02 will be the first laboratory in which the scheduler is permitted to cause actual JES2 workload execution.

## References

- BMC, **Active Jobs File**: https://documents.bmc.com/supportu/INC/help/Main_help/en-US/76557.htm
- BMC, **Control-M Utilities / CTMJOB — Order Jobs to the Active Jobs File**: https://documents.bmc.com/supportu/INC/9.0.21/en-US/INCONTROL_for_zOS_Utilities_Guide/Control-M_Utilities.htm
- IBM, **z/OS TSO/E REXX Reference**: https://www.ibm.com/docs/en/zos/3.2.0?topic=tsoe-zos-rexx-reference
- IBM, **Writing REXX Execs**: https://www.ibm.com/docs/en/zos/2.5.0?topic=tsoe-writing-rexx-execs
- IBM, **TSO/E REXX commands / EXECIO**: https://www.ibm.com/docs/en/zos/3.1.0?topic=reference-tsoe-rexx-commands

## Result

**Lab 01 completed successfully.**

The project now has a functional minimum scheduler core capable of storing metadata, parsing and validating job definitions, rejecting incomplete definitions, ordering a valid definition, and preserving an independent Active Job instance with explicit runtime state.
