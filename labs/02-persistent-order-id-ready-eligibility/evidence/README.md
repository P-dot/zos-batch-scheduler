# Guided Evidence — Lab 02 — Persistent Order-ID & READY Eligibility

[← Lab lesson](../README.md) · [Academy](https://github.com/P-dot/P-dot/blob/main/docs/ACADEMY.md) · [Evidence standard](https://github.com/P-dot/P-dot/blob/main/docs/LAB-STANDARD.md)

## How to read this evidence

This page is the evidence companion to the lab, not a screenshot gallery. Read the artifacts in execution order and correlate each image or file with the command, job, subsystem state or result described by the lab.

Use four questions while reviewing the evidence:

1. **Intent** — what state or behavior was the lab trying to create or inspect?
2. **Mechanism** — which z/OS component, command, utility or program performed the work?
3. **Observation** — what concrete message, return code, object or state was captured?
4. **Boundary** — what does that artifact support, and what would require additional evidence?

The manifest below is retained as the factual index from the executed lab. Its descriptions are the source of truth for what each artifact was captured to demonstrate.

## Evidence manifest

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

## Interpretation discipline

A successful command, return code or panel is interpreted only within the scope described by the lab. It must not be promoted into proof of unrelated production properties such as availability, performance, security hardening or recovery unless those properties have their own evidence.

When troubleshooting, walk the artifacts in order and locate the first point where **expected state** and **observed state** diverge. That point is normally more useful than the final symptom.

## Evidence boundary

**Evidence-backed:** the individual observations explicitly identified in the manifest and the parent lab.

**Not automatically implied:** production readiness, enterprise scale, security completeness, performance characteristics or cross-subsystem behavior that was not exercised by this lab.

## Review questions

- Which artifact establishes the initial or prerequisite state?
- Which artifact is the strongest execution/result proof?
- Is there a separate final-state validation, or only a successful command?
- Which z/OS subsystem owns the observed messages or objects?
- What additional artifact would be required to make a stronger claim?

---
### Continue learning

**Lab:** [Return to the lesson](../README.md)  
**Academy:** [z/OS Engineering Academy](https://github.com/P-dot/P-dot/blob/main/docs/ACADEMY.md) · [Curriculum](https://github.com/P-dot/P-dot/blob/main/docs/CURRICULUM.md) · [Relationships](https://github.com/P-dot/P-dot/blob/main/docs/RELATIONSHIPS.md)
