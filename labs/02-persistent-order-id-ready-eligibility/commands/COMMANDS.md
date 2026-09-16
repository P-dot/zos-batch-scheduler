# Runtime Commands — Lab 02 Parts 1-2

## Part 1

Create:

```text
IBMUSER.ZSCH.PARM(SEQ01)
```

Initial content:

```text
LASTID=0000001
```

Execute:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHORD)' 'LAB01A'
```

Validate:

```text
IBMUSER.ZSCH.PARM(SEQ01)
LASTID=0000002
```

and:

```text
IBMUSER.ZSCH.ACTIVE
A0000001
A0000002
```

## Part 2

Before evaluation:

```text
IBMUSER.ZSCH.ACTIVE(A0000002)
STATE=ORDERED
```

Execute:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHEVL)' 'A0000002'
```

Validate:

```text
STATE=READY
JOBID=
```

Negative test:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHEVL)' 'A0000002'
```

Expected rejection:

```text
ZSCH320E INSTANCE IS NOT ELIGIBLE FROM STATE: READY
ZSCH321E EXPECTED STATE: ORDERED
```
