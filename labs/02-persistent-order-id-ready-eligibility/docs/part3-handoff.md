# Part 3 Handoff — READY to JES2 Submission

## Starting point

The validated starting state is:

```text
IBMUSER.ZSCH.ACTIVE(A0000002)

STATE=READY
JOBID=
JCLDSN=IBMUSER.ZSCH.JCL
MEMBER=LAB01A
```

## Target capability

Create:

```text
IBMUSER.ZSCH.EXEC(ZSCHSUB)
```

Target responsibilities:

```text
read ACTIVE instance
      |
      v
validate STATE=READY
      |
      v
read JCLDSN + MEMBER
      |
      v
validate referenced JCL member
      |
      v
submit workload to JES2
      |
      v
confirm submission request
      |
      v
STATE=SUBMITTED
```

## Submission path

IBM documents the TSO/E `SUBMIT` command as a supported way to submit JCL for background processing by JES.

IBM also documents REXX approaches that submit through TSO/E or directly through the internal reader.

The Part 3 implementation should choose one path and validate it experimentally on the existing z/OS 1.11 laboratory before the repository claims submission support.

## State-safety rule

Do not set:

```text
STATE=SUBMITTED
```

before a successful submission request has been observed.

If submission fails, the active instance must remain recoverable and must not falsely claim to have entered JES2.

## JOBID boundary

The repository roadmap separates:

```text
Lab 02 -> submission
Lab 03 -> JOBID capture and execution tracking
```

Part 3 may preserve the TSO/JES submission message as evidence, but durable JOBID association and SDSF-based tracking should be treated as the next separately validated capability unless Part 3 proves a reliable capture mechanism on the current system.
