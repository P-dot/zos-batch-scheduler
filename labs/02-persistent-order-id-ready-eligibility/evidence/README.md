# Evidence Index — Lab 02 Parts 1-2

The screenshots in this directory were extracted from the supplied execution document and renamed according to the capability they prove.

## Part 1 — Persistent Order-ID

| File | Evidence |
|---|---|
| `01-zschord-source-part1.png` | Updated `ZSCHORD` header, input handling and validation path |
| `02-zschord-source-part2.png` | Definition read and variable initialization |
| `03-zschord-source-part3.png` | Definition parser and start of persistent sequence logic |
| `04-zschord-source-part4.png` | Persistent sequence generator continuation |
| `05-seq01-initial.png` | Initial `SEQ01` value `LASTID=0000001` |
| `06-zschord-lab01a-command.png` | ORDER invocation for `LAB01A` |
| `07-zschord-persistent-order-output-part1.png` | Definition validation, sequence read and Order-ID reservation |
| `08-zschord-persistent-order-output-part2.png` | Active instance result and successful ORDER |
| `09-seq01-updated.png` | Persisted `LASTID=0000002` |
| `10-active-members-a0000001-a0000002.png` | Coexistence of two independent runtime instances |

## Part 2 — Eligibility Engine

| File | Evidence |
|---|---|
| `11-zschevl-source-part1.png` | `ZSCHEVL` purpose, argument handling and active-member construction |
| `12-zschevl-source-part2.png` | Exclusive allocation and active-instance read |
| `13-zschevl-source-part3.png` | Runtime parsing and state discovery |
| `14-zschevl-source-part4.png` | Integrity checks and transition validation |
| `15-zschevl-source-part5.png` | Eligibility messages and in-memory `STATE=READY` update |
| `16-zschevl-source-part6.png` | Write result and final transition report |
| `17-active-a0000002-before-ordered.png` | Runtime instance before evaluation with `STATE=ORDERED` |
| `18-zschevl-first-command.png` | First evaluator execution |
| `19-zschevl-ready-success.png` | Eligibility satisfied and `ORDERED -> READY` |
| `20-zschevl-active-member-confirmation.png` | Successful active-member completion message |
| `21-active-a0000002-after-ready.png` | Runtime instance after evaluation with `STATE=READY` |
| `22-zschevl-second-command.png` | Repeated evaluator execution |
| `23-zschevl-ready-to-ready-rejected.png` | Expected rejection because current state is already `READY` |

## Evidence conclusion

The evidence proves:

```text
persistent Order-ID             PASS
multiple runtime occurrences    PASS
ORDERED -> READY                PASS
READY -> READY rejection        PASS
JOBID remains empty             EXPECTED
JES2 submission                 NOT YET IMPLEMENTED
```
