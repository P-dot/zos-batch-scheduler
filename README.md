# z/OS Batch Scheduler

A hands-on educational project to design and implement a native batch scheduler for z/OS, inspired by the operational concepts used by enterprise schedulers such as BMC Control-M for z/OS.

The project is intentionally built in small, observable steps on a real z/OS laboratory. The scheduler does not replace JES2: it is designed as a production-control layer above JES2 that decides **what** should run, **when** it is eligible, **which dependencies and resources are required**, and **how execution results are interpreted**.

> This project is an independent educational implementation. It contains no BMC proprietary code and is not intended to be a Control-M-compatible clone.

## Target architecture

```text
                     JOB DEFINITIONS
                           |
                           v
                       ORDERING
                           |
                           v
                     ACTIVE JOBS
                           |
                 +---------+---------+
                 |         |         |
               TIME    CONDITIONS  RESOURCES
                 |         |         |
                 +---------+---------+
                           |
                           v
                         READY
                           |
                           v
                         JES2
                           |
                           v
                          JCL
                           |
               +-----------+-----------+
               |           |           |
             DFSORT       COBOL        USS
               |           |           |
               +-----------+-----------+
                           |
                        RC / ABEND
                           |
                           v
                  HISTORY / AUDIT
```

## Development principles

- JES2 remains the execution engine.
- Scheduler metadata is kept separate from JCL.
- A permanent job definition is different from a runtime active instance.
- Invalid definitions must never create active workload state.
- Runtime state must be explicit and observable.
- State transitions must be validated, not edited arbitrarily.
- Persistent scheduler identity must survive individual REXX executions.
- Every feature is validated with positive and negative tests.
- The implementation evolves from simple PDS-based state toward more persistent and indexed structures only when justified by the laboratory.

## Architecture V2 alignment

This repository participates in the broader z/OS Engineering Laboratory Architecture V2.

Primary engineering domain:

```text
Workload and Batch Engineering
```

Secondary relationships:

```text
Automation and Modern Operations
Integration Engineering
Operations and Service Management
```

The repository follows the Architecture V2 rule:

```text
Domain repositories validate capabilities.
Production Tracks prove that those capabilities work together.
Core Platform provides the common z/OS environment.
```

The scheduler is a participant in the Enterprise Batch Operations and Enterprise Batch Scheduling production tracks.

## Laboratory roadmap

| Lab | Scope | Status |
|---|---|---|
| 01 | Architecture, job definitions, validation and first active instance | **Completed** |
| 02 | Persistent Order-ID, READY state and JES2 submission | **Parts 1-2 validated; Part 3 planned** |
| 03 | JOBID capture and execution tracking | Planned |
| 04 | RC, JCL error and ABEND classification | Planned |
| 05 | IN/OUT conditions and dependencies | Planned |
| 06 | HOLD/FREE operator control | Planned |
| 07 | Quantitative and shared/exclusive resources | Planned |
| 08 | Rerun/restart integration | Planned |
| 09 | Calendars and logical production day | Planned |
| 10 | Execution history and statistics | Planned |
| 11 | ISPF Active Environment | Planned |
| 12 | Scheduler monitor as a started task | Planned |
| 13 | RACF/JES/SDSF security integration | Planned |
| 14 | SMF observability and audit | Planned |
| 15 | Event-driven triggering | Planned |
| 16+ | Db2, USS, CICS and integrated production flows | Planned |

## Labs

- [Lab 01 — Architecture, Job Definitions & Active State Model](labs/01-architecture-job-definitions-active-state-model/README.md)
- [Lab 02 — Persistent Order-ID & READY Eligibility](labs/02-persistent-order-id-ready-eligibility/README.md)

## Current validated control path

```text
PERMANENT DEFINITION
        |
        v
     ZSCHVAL
        |
        v
     ZSCHORD
        |
        v
Persistent ORDER-ID
        |
        v
ACTIVE / ORDERED
        |
        v
     ZSCHEVL
        |
        v
      READY
        |
        X
      JES2
```

The boundary marked `X` is intentional. Lab 02 Parts 1-2 validate persistent runtime identity and scheduler eligibility. Part 3 will be the first scheduler-controlled submission to JES2.

## Ecosystem integration

The scheduler is the orchestration layer between reusable JCL/JES2 execution mechanics and higher-level application workloads.

See:

[docs/ECOSYSTEM-INTEGRATION.md](docs/ECOSYSTEM-INTEGRATION.md)

## Repository

GitHub repository:

https://github.com/P-dot/zos-batch-scheduler
