/* REXX */

/********************************************************************/
/* ZSCHEVL - Z/OS BATCH SCHEDULER                                   */
/* LAB 02 - ACTIVE JOB ELIGIBILITY EVALUATOR                        */
/*                                                                  */
/* FUNCTIONS                                                        */
/* - Read an ACTIVE runtime instance                                */
/* - Validate its current scheduler state                           */
/* - Evaluate Lab 02 eligibility                                    */
/* - Perform ORDERED -> READY transition                            */
/* - Preserve all runtime metadata                                  */
/********************************************************************/

parse upper arg actmem

if actmem = '' then do
   say 'ZSCH301E ACTIVE MEMBER NAME REQUIRED'
   exit 8
end

/********************************************************************/
/* BUILD ACTIVE MEMBER DATA SET NAME                                */
/********************************************************************/

actdsn = 'IBMUSER.ZSCH.ACTIVE('actmem')'

say
say 'ZSCH310I EVALUATING ACTIVE INSTANCE:' actdsn

/********************************************************************/
/* OBTAIN EXCLUSIVE ACCESS                                          */
/********************************************************************/

address TSO

"ALLOC F(ACTDD) DA('"actdsn"') OLD REUSE"

if rc <> 0 then do
   say 'ZSCH302E CANNOT ALLOCATE ACTIVE INSTANCE'
   exit 8
end

/********************************************************************/
/* READ ACTIVE INSTANCE                                             */
/********************************************************************/

"EXECIO * DISKR ACTDD (STEM REC. FINIS"

if rc <> 0 then do
   say 'ZSCH303E CANNOT READ ACTIVE INSTANCE'
   "FREE F(ACTDD)"
   exit 8
end

if rec.0 = 0 then do
   say 'ZSCH304E ACTIVE INSTANCE IS EMPTY'
   "FREE F(ACTDD)"
   exit 8
end

/********************************************************************/
/* LOCATE CURRENT STATE                                             */
/********************************************************************/

state    = ''
staterec = 0
orderid  = ''
jobname  = ''

do i = 1 to rec.0

   line = strip(rec.i)

   if line = '' then
      iterate

   parse var line key '=' value

   key   = strip(translate(key))
   value = strip(value)

   select

      when key = 'ORDERID' then
         orderid = value

      when key = 'NAME' then
         jobname = translate(value)

      when key = 'STATE' then do
         state = translate(value)
         staterec = i
      end

      otherwise
         nop

   end

end

/********************************************************************/
/* ACTIVE INSTANCE INTEGRITY CHECKS                                 */
/********************************************************************/

if orderid = '' then do
   say 'ZSCH305E ORDERID MISSING FROM ACTIVE INSTANCE'
   "FREE F(ACTDD)"
   exit 8
end

if jobname = '' then do
   say 'ZSCH306E JOB NAME MISSING FROM ACTIVE INSTANCE'
   "FREE F(ACTDD)"
   exit 8
end

if state = '' then do
   say 'ZSCH307E STATE MISSING FROM ACTIVE INSTANCE'
   "FREE F(ACTDD)"
   exit 8
end

/********************************************************************/
/* STATE TRANSITION VALIDATION                                      */
/* LAB 02 PART 2 ONLY ALLOWS: ORDERED ---> READY                    */
/********************************************************************/

if state <> 'ORDERED' then do
   say 'ZSCH320E INSTANCE IS NOT ELIGIBLE FROM STATE:' state
   say 'ZSCH321E EXPECTED STATE: ORDERED'
   "FREE F(ACTDD)"
   exit 8
end

/********************************************************************/
/* ELIGIBILITY EVALUATION                                           */
/********************************************************************/

say
say 'ZSCH311I CURRENT STATE : ORDERED'
say 'ZSCH312I CHECKING SCHEDULER ELIGIBILITY'
say 'ZSCH313I TIME CHECK     : NOT CONFIGURED'
say 'ZSCH314I CONDITIONS     : NOT CONFIGURED'
say 'ZSCH315I RESOURCES      : NOT CONFIGURED'
say 'ZSCH316I OPERATOR HOLD  : NOT CONFIGURED'
say 'ZSCH317I ELIGIBILITY    : SATISFIED'

/********************************************************************/
/* CHANGE STATE IN MEMORY                                           */
/********************************************************************/

rec.staterec = 'STATE=READY'

/********************************************************************/
/* WRITE UPDATED ACTIVE INSTANCE                                    */
/********************************************************************/

"EXECIO "rec.0" DISKW ACTDD (STEM REC. FINIS"

writerc = rc

"FREE F(ACTDD)"

if writerc <> 0 then do
   say 'ZSCH308E CANNOT UPDATE ACTIVE INSTANCE'
   exit 8
end

/********************************************************************/
/* DISPLAY TRANSITION RESULT                                        */
/********************************************************************/

say
say '----------------------------------------'
say ' Z/OS BATCH SCHEDULER - ELIGIBILITY'
say '----------------------------------------'
say 'ORDERID   :' orderid
say 'NAME      :' jobname
say 'OLD STATE : ORDERED'
say 'NEW STATE : READY'
say '----------------------------------------'
say
say 'ZSCH300I INSTANCE IS READY'
say 'ZSCH318I ACTIVE MEMBER:' actmem

exit 0
