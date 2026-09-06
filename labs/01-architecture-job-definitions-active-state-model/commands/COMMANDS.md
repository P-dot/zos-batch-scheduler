# Lab 01 Commands

## ISPF / TSO execution commands

Validate the correct definition:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHVAL)' 'LAB01A'
```

Validate the deliberately incomplete definition:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHVAL)' 'LAB01B'
```

Create the first active instance:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHORD)' 'LAB01A'
```

Attempt to order the invalid definition:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHORD)' 'LAB01B'
```

## ISPF checks

List scheduler libraries:

```text
ISPF 3.4
IBMUSER.ZSCH.*
```

Browse the first active member:

```text
IBMUSER.ZSCH.ACTIVE(A0000001)
```

Expected scheduler state after Lab 01:

```text
ORDERID=0000001
NAME=LAB01A
STATE=ORDERED
JOBID=
RUNNO=1
```

## Important execution rule for Lab 01

Do **not** submit `IBMUSER.ZSCH.JCL(LAB01A)` manually as part of this lab. JES2 submission belongs to Lab 02.
