# Guided Evidence — Lab 01: Job Definitions and Active-State Model

[← Lab lesson](../README.md) · [JCL/JES2](https://github.com/P-dot/JCL_LABS) · [Academy](https://github.com/P-dot/P-dot/blob/main/docs/ACADEMY.md)

This lab introduces the scheduler's most important abstraction: **a job definition is not the same thing as an ordered/running instance**.

## Mental model

    reusable definition
      LAB01A
         |
      validate
         |
      ORDER
         |
         v
    active instance
     A0000001
         |
    state changes
         |
    JES2 execution
         |
    completion / history

This mirrors a production scheduler distinction: static workload metadata describes what *may* run; an active/order instance records one concrete lifecycle occurrence.

## Phase 1 — build the scheduler control libraries

Evidence **01–06** establishes the persistent z/OS structures used by the scheduler experiment.

- **01** verifies IBMUSER.ZSCH.JCL allocation characteristics.
- **02–03** show the allocation job source.
- **04** closes allocation with RC=0000 and catalog evidence.
- **05** provides the LAB01A workload JCL.
- **06** confirms the resulting IBMUSER.ZSCH.* library set.

**Interpretation:** before implementing scheduling semantics, the lab establishes where definitions, active records and executable JCL live. This keeps control metadata separate from workload source.

## Phase 2 — define the scheduler vocabulary

Evidence **07–08** introduces a valid LAB01A definition and the scheduler state vocabulary.

**Interpretation:** the definition is declarative metadata. It can describe a job without implying that an instance currently exists in the active workload.

This is the first major boundary:

    DEFINITION != ACTIVE INSTANCE

## Phase 3 — validate before ordering

Evidence **09–12** walks through ZSCHVAL: argument handling, definition reading, parsing, required-field checks and final RC/output logic.

Evidence **13–14** then executes the positive path.

**Observe:** LAB01A passes validation.

**Interpret:** validation is a gate. It checks whether metadata is structurally acceptable before stateful scheduler action occurs.

### Negative validation path

Evidence **15–17** deliberately removes OWNER from LAB01B and executes the same validator.

**Observe:** the definition is rejected for the missing required field.

**Interpret:** a useful scheduler must reject invalid metadata *before* creating active workload state. The negative path is therefore as important as the successful path.

## Phase 4 — ORDER creates state

Evidence **18–22** shows ZSCHORD implementing the order path: invoke the validation gate, read/parse the definition, assign the lab Order-ID and construct/write an active-instance record.

Evidence **23–26** executes that path.

**Observe:** LAB01A is ordered successfully and active member A0000001 is created.

**Interpret:** ORDER is a state transition, not merely another validation command:

    valid definition
          |
        ORDER
          |
          v
    persistent active record

The active record represents this particular ordered occurrence. The reusable definition remains a separate object.

## Phase 5 — prove rejection is non-destructive

Evidence **27–28** attempts to ORDER invalid LAB01B.

**Observe:** validation rejects it before active creation.

Evidence **29** then verifies that A0000001 remains unchanged.

**Interpret:** this is the lab's strongest integrity property:

> invalid input does not mutate the previously valid active state.

That is a production-grade concept: a failed order operation should fail closed rather than corrupt scheduler state.

## Evidence map

| Proof | Screenshots | What it demonstrates |
|---|---|---|
| Control libraries exist | 01–06 | Persistent scheduler structures and workload source |
| Definition vocabulary | 07–08 | Static metadata and states |
| Positive validation | 09–14 | Parser/gate accepts valid definition |
| Negative validation | 15–17 | Missing required metadata is rejected |
| Active-instance creation | 18–26 | ORDER converts definition into persistent active state |
| Failure integrity | 27–29 | Invalid ORDER creates no new state and preserves existing instance |

## Connection to JCL/JES2

The scheduler does **not** replace JCL or JES2.

    Scheduler: WHEN / WHETHER / INSTANCE STATE
                    |
                    v
    JCL:       WHAT WORK IS DESCRIBED
                    |
                    v
    JES2:      QUEUE / CONVERT / EXECUTE / OUTPUT

This separation is why the Academy links the Scheduler course after JCL/JES2 foundations.

## Evidence boundary

**VALIDATED:** local definition schema, positive/negative validation, ordering gate, active-instance creation and rejection without mutation.

**NOT CLAIMED:** Control-M compatibility, enterprise calendars, JES2 submission in this specific evidence set, distributed agents or production HA scheduler architecture.

## Knowledge check

1. Why must a definition remain separate from an active instance?
2. What state changes when ORDER succeeds?
3. Why is the negative LAB01B path essential evidence?
4. What does screenshot 29 prove that screenshot 28 alone does not?
5. Which responsibilities belong to JES2 rather than the scheduler?

---
### Continue learning

**Course:** [Workload Automation](../../../README.md)  
**Next:** [Lab 02 — persistent Order-ID and READY eligibility](../../02-persistent-order-id-ready-eligibility/)  
**Foundation:** [JCL/JES2 Engineering Labs](https://github.com/P-dot/JCL_LABS)  
**Academy:** [z/OS Engineering Academy](https://github.com/P-dot/P-dot/blob/main/docs/ACADEMY.md)
