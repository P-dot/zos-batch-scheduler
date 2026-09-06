# Scheduler State Model — Version 0.1

## State vocabulary

`IBMUSER.ZSCH.PARM(STATE01)` defines:

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

## Lab 01 implementation level

Only the early lifecycle is implemented:

```text
DEFINED --ZSCHORD--> ORDERED
```

The remaining values are a design contract for future labs; their transitions are not yet executable scheduler logic.

## Intended future lifecycle

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

## State semantics

| State | Intended meaning |
|---|---|
| `DEFINED` | Permanent definition exists but no active runtime occurrence is implied |
| `ORDERED` | Runtime instance exists in the active environment |
| `HELD` | Operator hold prevents eligibility/submission |
| `WAIT_TIME` | Time window is not yet satisfied |
| `WAIT_COND` | Required logical conditions are missing |
| `WAIT_RESOURCE` | Required scheduler resource is unavailable |
| `READY` | All scheduler eligibility criteria are satisfied |
| `SUBMITTED` | Workload has been sent to JES2 |
| `EXECUTING` | JES2/SDSF tracking indicates execution is active |
| `ENDED_OK` | Runtime result is accepted by scheduler policy |
| `ENDED_NOTOK` | Runtime result violates accepted RC policy |
| `ABENDED` | Execution ended abnormally |
| `JCL_ERROR` | JES/JCL processing failure prevented normal execution |

These semantics will be validated incrementally rather than assumed complete in Lab 01.
