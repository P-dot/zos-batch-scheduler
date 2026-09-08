# z/OS Batch Scheduler Ecosystem Integration

## Role

This repository provides the orchestration and production-control layer of the broader z/OS Engineering Laboratory.

Its responsibility is to decide which defined workloads should become active, when they are eligible to run, how they are submitted to JES2, and how their execution state is interpreted over time.

The scheduler does not replace JCL and it does not replace JES2.

```text
MVS_TSO_ISPF
      |
      v
     REXX
      |
      v
zos-batch-scheduler
      |
      v
     JCL
      |
      v
    JES2
      |
  +---+---+
  |   |   |
COBOL VSAM DB2
      |
      v
RC / ABEND / JOBID
      |
      v
scheduler state/history
```

The architectural rule is:

```text
Scheduler decides and controls.
JCL describes the workload.
JES2 executes the workload.
```

## Current Validated Scheduler Foundation

Lab 01 establishes the first functional scheduler core.

Validated components include:

- isolated scheduler libraries under `IBMUSER.ZSCH.*`;
- permanent job definitions;
- definition validation through `ZSCHVAL`;
- positive and negative metadata validation;
- ORDER processing through `ZSCHORD`;
- creation of an independent active runtime instance;
- explicit runtime state;
- rejection of invalid definitions before active-state creation;
- preservation of active-state integrity after a rejected ORDER.

The validated Lab 01 control path is:

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
ACTIVE JOB INSTANCE
        |
        v
 STATE=ORDERED
```

Lab 01 deliberately stops before JES2 submission.

## Upstream Dependencies

### MVS_TSO_ISPF

Provides the interactive operator environment used to maintain definitions, execute REXX tooling, inspect datasets and later operate scheduler controls.

Relationship:

```text
MVS_TSO_ISPF -> scheduler operator workflows
```

Status: **Foundational dependency**

### REXX

REXX is the current implementation language for the scheduler control programs.

Lab 01 already uses REXX for:

- definition validation;
- ORDER processing;
- dataset access;
- runtime-state creation.

Relationship:

```text
REXX -> scheduler control logic
```

Status: **Validated dependency**

### JCL_LABS

Provides reusable JCL and JES2 execution mechanics for workloads that the scheduler will later submit.

Relationship:

```text
zos-batch-scheduler -> JCL_LABS concepts -> JES2
```

Status: **Foundational dependency; first direct submission path planned for Lab 02**

### z/OS Engineering Laboratory

Provides the common ADCD/Hercules system context, JES2 environment, system-engineering methodology, observability, recovery and cross-repository architecture.

Status: **Active architectural dependency**

## Downstream Consumers and Workload Domains

The scheduler will eventually orchestrate workloads from multiple technical tracks.

### COBOL

The scheduler can later order and track batch application jobs containing COBOL execution steps.

Status: **Planned integration**

### VSAM

The scheduler can later control dataset preparation, application access, maintenance and dependent workflows involving VSAM.

Status: **Planned integration**

### DB2

Db2 batch application and utility flows can later be placed under scheduler dependency, return-code and recovery control.

Status: **Planned integration**

### USS

USS-oriented jobs or hybrid batch workflows can later be orchestrated as scheduled workloads.

Status: **Planned integration**

### CICS

CICS-related operational or application flows belong to later integrated production scenarios rather than the current scheduler core.

Status: **Planned integration**

## Consumes

The scheduler currently consumes:

- TSO/E and ISPF;
- REXX;
- partitioned datasets;
- scheduler-owned metadata;
- scheduler-owned active-state libraries;
- workload JCL references.

The scheduler is designed to consume later:

- JES2 submission and JOBID information;
- SDSF or equivalent execution observations;
- return codes and ABEND information;
- conditions and dependencies;
- quantitative and shared/exclusive resources;
- calendars and production-day logic;
- RACF authorization;
- SMF observability;
- application workload metadata.

## Produces

The scheduler currently produces:

- validated permanent definitions;
- validation diagnostics;
- ORDER acceptance or rejection;
- scheduler runtime active instances;
- explicit scheduler state;
- integrity-preserving negative-path behavior.

Future layers are expected to produce:

- persistent Order-IDs;
- READY eligibility state;
- JES2 submissions;
- JOBID associations;
- execution-state transitions;
- RC / ABEND / JCL-error classification;
- dependency state;
- HOLD/FREE operator state;
- resource allocation state;
- rerun/restart decisions;
- execution history and statistics;
- ISPF operator views;
- audit and observability records.

## Current State Model

The repository already defines the following lifecycle vocabulary:

```text
DEFINED
   |
   v
ORDERED
   |
   +--> HELD
   +--> WAIT_TIME
   +--> WAIT_COND
   +--> WAIT_RESOURCE
   |
   v
READY
   |
   v
SUBMITTED
   |
   v
EXECUTING
   |
   +--> ENDED_OK
   +--> ENDED_NOTOK
   +--> ABENDED
   +--> JCL_ERROR
```

Only the early portion is implemented in Lab 01.

The current validated runtime transition is:

```text
DEFINED -> ORDERED
```

The remaining states are roadmap targets.

## Validated Integration Paths

### Definition to active runtime state

```text
scheduler definition
      |
      v
   ZSCHVAL
      |
      v
    ZSCHORD
      |
      v
active instance
      |
      v
STATE=ORDERED
```

Status: **Validated in Lab 01**

### Negative integrity path

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
no active-state modification
```

Status: **Validated in Lab 01**

### Scheduler-to-JCL reference path

The active runtime record already preserves the target workload location:

```text
JCLDSN=<scheduler-controlled JCL library>
MEMBER=<workload member>
```

This establishes the metadata relationship, but Lab 01 does not submit the member.

Status: **Validated metadata relationship; execution deferred**

## Planned Cross-Repository Paths

The following are architectural targets and must not be interpreted as completed integrations.

### Lab 02 — first real JES2 submission path

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
eligibility
    |
    v
READY
    |
    v
JCL submission
    |
    v
JES2
    |
    v
JOBID association
```

This is the first planned integration where the scheduler will cause actual JES2 workload execution.

### Execution tracking path

```text
scheduler
   |
   v
 JES2
   |
   v
 JOBID
   |
   v
execution observation
   |
   +--> executing
   +--> ended
   +--> JCL error
   +--> ABEND
```

### Result classification path

```text
JES2 result
    |
    +--> RC acceptable ------> ENDED_OK
    |
    +--> RC unacceptable ----> ENDED_NOTOK
    |
    +--> ABEND --------------> ABENDED
    |
    +--> JCL error ----------> JCL_ERROR
```

### Dependency path

```text
JOB A
  |
 OUT condition
  |
  v
JOB B eligibility
```

### Resource path

```text
job request
   |
   v
scheduler resource model
   |
   +--> available ------> READY
   |
   +--> unavailable ----> WAIT_RESOURCE
```

### Operator-control path

```text
ISPF / REXX
    |
    v
scheduler active environment
    |
    +--> HOLD
    +--> FREE
    +--> rerun
    +--> restart
```

### Security and observability path

```text
operator / scheduler identity
          |
          v
        RACF
          |
          v
scheduler / JES2 actions
          |
          +--> SDSF observation
          |
          +--> SMF audit
```

## Cross-Repository Production Tracks

### Enterprise batch operations

```text
Scheduler
   |
   v
JCL / JES2
   |
   +--> COBOL
   +--> DB2
   +--> VSAM
   |
   v
RC / ABEND
   |
   v
history / audit / recovery
```

### Batch failure and recovery

```text
Scheduler
   |
   v
JCL / JES2
   |
 failure
   |
   v
SDSF diagnosis
   |
 correction
   |
restart / rerun
   |
   v
scheduler resumes control
```

### End-to-end production cycle

```text
Scheduler
   |
   v
JCL / JES2
   |
   +--> IDCAMS / VSAM preparation
   |
   +--> COBOL
   |
   +--> DB2 / reporting
   |
   +--> backup / housekeeping
   |
   v
RC / ABEND / JOBID
   |
   v
scheduler history and final state
```

RACF, SMF, SDSF, USS, Communications Server and storage/recovery remain cross-cutting services around this flow.

## Integration Status

| Integration | Status | Evidence |
| --- | --- | --- |
| Scheduler libraries and metadata model | Validated | Lab 01 |
| Definition validation | Validated | Lab 01 |
| Positive/negative definition paths | Validated | Lab 01 |
| ORDER operation | Validated | Lab 01 |
| Active runtime instance creation | Validated | Lab 01 |
| Invalid ORDER preserves active state | Validated | Lab 01 |
| Scheduler -> JCL metadata reference | Validated | Lab 01 |
| Persistent Order-ID | Planned | Lab 02 |
| ORDERED -> READY | Planned | Lab 02 |
| Scheduler -> JES2 submission | Planned | Lab 02 |
| JOBID association | Planned | Labs 02-03 |
| RC / JCL error / ABEND classification | Planned | Lab 04 |
| Conditions and dependencies | Planned | Lab 05 |
| HOLD/FREE | Planned | Lab 06 |
| Resource control | Planned | Lab 07 |
| Rerun/restart | Planned | Lab 08 |
| Calendars / production day | Planned | Lab 09 |
| History/statistics | Planned | Lab 10 |
| ISPF active environment | Planned | Lab 11 |
| Started-task monitor | Planned | Lab 12 |
| RACF/JES/SDSF security | Planned | Lab 13 |
| SMF observability/audit | Planned | Lab 14 |
| Event-driven triggering | Planned | Lab 15 |
| Db2/USS/CICS production flows | Planned | Lab 16+ |

## Scope Boundaries

This repository owns scheduler orchestration and production-control logic.

It does **not** replace:

- `JCL_LABS` for JCL semantics and reusable batch mechanics;
- JES2 for workload execution;
- `Rexx` for general REXX language learning;
- `MVS_TSO_ISPF` for TSO/E and ISPF fundamentals;
- `COBOL`, `DB2-`, `vsam01`, `PL-I` or `z_Assembly` for application and language domains;
- `mainframe-racf-security-evidence` for RACF administration and security policy;
- `zos-communications-server-network-lab` for networking;
- `UNIX_System_Services-` for USS fundamentals;
- the core z/OS Engineering Laboratory for system-level JES2, SMF, storage, recovery and platform engineering.

The integration rule is:

```text
Orchestrate workloads here.
Define reusable JCL mechanics in JCL_LABS.
Execute through JES2.
Keep application and subsystem logic in their owning repositories.
```

## Development Direction

The repository should continue to evolve in layers.

```text
definitions
    |
    v
validation
    |
    v
ORDER
    |
    v
active state
    |
    v
persistent Order-ID
    |
    v
eligibility / READY
    |
    v
JES2 submission
    |
    v
JOBID tracking
    |
    v
RC / ABEND classification
    |
    v
dependencies / resources
    |
    v
operator controls
    |
    v
rerun / restart
    |
    v
history / audit
    |
    v
ISPF / started task
    |
    v
security / SMF
    |
    v
integrated production flows
```

Near-term priority should remain Lab 02 because it crosses the boundary from scheduler metadata management into real JES2-controlled workload execution.

## Engineering and Publication Rules

Each scheduler lab should continue to record:

- objective;
- architecture;
- state transitions;
- exact commands;
- JCL and REXX components;
- positive and negative tests;
- observed RCs and messages;
- evidence;
- scope boundaries;
- security review;
- rollback or recovery implications where relevant.

Cross-repository work should follow:

```text
Build -> Execute -> Observe -> Diagnose -> Correct -> Validate -> Document
```

Before publication:

- distinguish implemented state transitions from roadmap states;
- do not claim JES2 execution until an actual submission is validated;
- preserve negative-path evidence;
- preserve RC / ABEND / JOBID evidence when those layers are implemented;
- do not publish credentials, IP addresses, MAC addresses, terminal/network identifiers or host-side network details;
- use short-lived branches and merge completed work into `main`.

## Master Architecture

The broader ecosystem architecture is maintained in:

https://github.com/P-dot/zos-adcd-hercules-engineering-lab
