# z/OS Batch Scheduler

A hands-on educational project to design and implement a native batch scheduler for z/OS, inspired by the operational concepts used by enterprise schedulers such as BMC Control-M for z/OS.

The project is intentionally built in small, observable steps on a real z/OS laboratory. The scheduler does not replace JES2: it is designed as a production-control layer above JES2 that will eventually decide **what** should run, **when** it is eligible, **which dependencies and resources are required**, and **how execution results are interpreted**.

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
- Every feature is validated with positive and negative tests.
- The implementation evolves from simple PDS-based state toward more persistent and indexed structures only when justified by the laboratory.

## Laboratory roadmap

| Lab | Scope | Status |
|---|---|---|
| 01 | Architecture, job definitions, validation and first active instance | **Completed** |
| 02 | Persistent Order-ID, READY state and JES2 submission | Planned |
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

## Repository

Local working directory used for the project:

```text
C:\Carrera_Ciberseguridad\06_Portfolio_GitHub\zos-batch-scheduler
```

Remote repository currently created as:

```text
https://github.com/P-dot/zos-batch-scheduler
```

The local working directory and GitHub repository now use the canonical name `zos-batch-scheduler`.
