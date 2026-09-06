# Evidence Index — Lab 01

All screenshots come from the executed z/OS laboratory session supplied for this lab.

| # | File | Evidence |
|---:|---|---|
| 01 | `01-zsch-jcl-dataset-info.png` | `IBMUSER.ZSCH.JCL` allocation characteristics: PDS, FB/80, 3390 |
| 02 | `02-alloc01-source-part1.png` | `ALLOC01` source — first section |
| 03 | `03-alloc01-source-part2.png` | `ALLOC01` source — final section |
| 04 | `04-alloc01-sdsf-rc0000.png` | SDSF allocation results and cataloging, RC=0000 |
| 05 | `05-lab01a-test-jcl.png` | Test workload `JCL(LAB01A)` |
| 06 | `06-zsch-dataset-list.png` | Cataloged `IBMUSER.ZSCH.*` libraries |
| 07 | `07-valid-definition-lab01a.png` | Valid job definition |
| 08 | `08-state01-vocabulary.png` | Scheduler state vocabulary |
| 09 | `09-zschval-source-part1.png` | `ZSCHVAL` source, argument/allocation/read logic |
| 10 | `10-zschval-source-part2.png` | `ZSCHVAL` parser logic |
| 11 | `11-zschval-source-part3.png` | `ZSCHVAL` required-field validation |
| 12 | `12-zschval-source-part4.png` | `ZSCHVAL` final output/RC logic |
| 13 | `13-zschval-lab01a-command.png` | Positive validation command |
| 14 | `14-zschval-lab01a-valid.png` | Positive validation output |
| 15 | `15-invalid-definition-lab01b.png` | Negative definition with OWNER intentionally omitted |
| 16 | `16-zschval-lab01b-command.png` | Negative validation command |
| 17 | `17-zschval-lab01b-invalid.png` | OWNER missing / invalid definition result |
| 18 | `18-zschord-source-part1.png` | `ZSCHORD` validation gate and definition read start |
| 19 | `19-zschord-source-part2.png` | `ZSCHORD` definition read logic |
| 20 | `20-zschord-source-part3.png` | Parser and fixed Lab 01 Order-ID |
| 21 | `21-zschord-source-part4.png` | Active instance record construction |
| 22 | `22-zschord-source-part5.png` | Active write/result logic |
| 23 | `23-zschord-lab01a-command.png` | Successful ORDER command |
| 24 | `24-zschord-lab01a-output-part1.png` | Validation + active-instance creation output |
| 25 | `25-zschord-lab01a-output-part2.png` | Successful ORDER result and active member name |
| 26 | `26-active-a0000001-initial.png` | First Active Job instance content |
| 27 | `27-zschord-lab01b-command.png` | Invalid ORDER command |
| 28 | `28-zschord-lab01b-rejected.png` | Invalid definition rejected before active creation |
| 29 | `29-active-a0000001-final-unchanged.png` | Final integrity evidence: original active instance remains unchanged |

The strongest closure evidence is screenshots **04, 14, 17, 24–26, 28 and 29**.
