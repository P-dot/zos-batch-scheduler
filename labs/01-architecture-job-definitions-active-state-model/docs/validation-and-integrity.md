# Definition Validation and Active-State Integrity

## Positive test

Definition:

```text
IBMUSER.ZSCH.DEF(LAB01A)
```

contains all required fields.

Command:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHVAL)' 'LAB01A'
```

Result:

```text
ZSCH000I DEFINITION VALID
```

## Negative test

Definition:

```text
IBMUSER.ZSCH.DEF(LAB01B)
```

intentionally omits `OWNER`.

Command:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHVAL)' 'LAB01B'
```

Result:

```text
ZSCH104E OWNER MISSING
ZSCH900E DEFINITION INVALID - 1 ERROR(S)
```

## ORDER integrity test

Command:

```text
EX 'IBMUSER.ZSCH.EXEC(ZSCHORD)' 'LAB01B'
```

Result:

```text
ZSCH104E OWNER MISSING
ZSCH900E DEFINITION INVALID - 1 ERROR(S)
ZSCH202E ORDER REJECTED - INVALID DEFINITION
```

Final browse of `IBMUSER.ZSCH.ACTIVE(A0000001)` proved that the previously created valid active instance remained unchanged.

## Established invariant

```text
INVALID DEFINITION => NO ACTIVE STATE CREATION
```

This invariant is now part of the scheduler design and should remain true as ORDER functionality becomes more complex.
