# Lab 01 Architecture Notes

## Architectural rule

JES2 is the execution engine. ZSCH is a production-control layer above JES2.

Lab 01 does not interact with JES2 for workload execution. It establishes the scheduler-side model that must exist before submission is safe.

## Definition versus active instance

A permanent definition answers:

- What workload does the scheduler know?
- Where is its JCL?
- Who owns it?
- What policy metadata applies?

An active instance answers:

- Which runtime occurrence is being controlled?
- What Order-ID identifies it?
- What state is it in now?
- Has a JES JOBID been assigned?
- Which run number is this?

```text
Permanent                         Runtime
---------------------------       ----------------------------
DEF(LAB01A)                  ->   ACTIVE(A0000001)
NAME=LAB01A                       ORDERID=0000001
INITIAL=DEFINED                   STATE=ORDERED
MAXRC=4                           JOBID=
RERUN=YES                         RUNNO=1
```

This separation is required before later features such as HOLD/FREE, rerun, restart, dependencies or history can be implemented correctly.

## Integrity boundary

`ZSCHORD` does not directly trust permanent metadata. It first calls `ZSCHVAL`.

```text
             +----------------+
             |    ZSCHORD     |
             +--------+-------+
                      |
                      v
             +----------------+
             |    ZSCHVAL     |
             +--------+-------+
                      |
             +--------+---------+
             |                  |
           RC=0               RC!=0
             |                  |
             v                  v
       create ACTIVE       reject ORDER
```

This is the first control boundary in the project.

## Why PDS first

Lab 01 uses PDS members because they are:

- directly inspectable from ISPF,
- easy to edit and version,
- suitable for FB/80 records,
- simple to process from TSO/E REXX with allocation and EXECIO,
- ideal for validating the scheduler model before adding indexed/persistent complexity.

Future labs may move specific runtime structures to VSAM or Db2 if the access model requires it.
