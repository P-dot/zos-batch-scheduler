/* REXX */

/********************************************************************/
/* ZSCHORD - Z/OS BATCH SCHEDULER                                   */
/* LAB 02 - ORDER JOB AND CREATE ACTIVE INSTANCE                    */
/*                                                                  */
/* FUNCTIONS                                                        */
/* - Validate the permanent job definition                          */
/* - Read scheduler metadata                                        */
/* - Reserve a persistent unique Order-ID                           */
/* - Create an independent ACTIVE runtime instance                  */
/********************************************************************/

parse upper arg member

if member = '' then do
   say 'ZSCH201E MEMBER NAME REQUIRED'
   exit 8
end

/********************************************************************/
/* VALIDATE DEFINITION FIRST                                        */
/********************************************************************/

address TSO

"EXEC 'IBMUSER.ZSCH.EXEC(ZSCHVAL)' '"member"'"

valrc = rc

if valrc <> 0 then do
   say 'ZSCH202E ORDER REJECTED - INVALID DEFINITION'
   exit 8
end

/********************************************************************/
/* READ PERMANENT JOB DEFINITION                                    */
/********************************************************************/

defdsn = 'IBMUSER.ZSCH.DEF('member')'

"ALLOC F(DEFDD) DA('"defdsn"') SHR REUSE"

if rc <> 0 then do
   say 'ZSCH203E CANNOT ALLOCATE DEFINITION'
   exit 8
end

"EXECIO * DISKR DEFDD (STEM REC. FINIS"

if rc <> 0 then do
   say 'ZSCH204E CANNOT READ DEFINITION'
   "FREE F(DEFDD)"
   exit 8
end

"FREE F(DEFDD)"

/********************************************************************/
/* INITIALIZE DEFINITION VARIABLES                                  */
/********************************************************************/

name    = ''
jcldsn  = ''
jmember = ''
owner   = ''
initial = ''
maxrc   = ''
rerun   = ''

/********************************************************************/
/* PARSE KEY=VALUE DEFINITION                                       */
/********************************************************************/

do i = 1 to rec.0

   line = strip(rec.i)

   if line = '' then
      iterate

   parse var line key '=' value

   key   = strip(translate(key))
   value = strip(value)

   select

      when key = 'NAME' then
         name = translate(value)

      when key = 'JCLDSN' then
         jcldsn = translate(value)

      when key = 'MEMBER' then
         jmember = translate(value)

      when key = 'OWNER' then
         owner = translate(value)

      when key = 'INITIAL' then
         initial = translate(value)

      when key = 'MAXRC' then
         maxrc = value

      when key = 'RERUN' then
         rerun = translate(value)

      otherwise
         nop

   end

end

/********************************************************************/
/* LAB 02 - PERSISTENT ORDER-ID GENERATOR                           */
/********************************************************************/

seqdsn = 'IBMUSER.ZSCH.PARM(SEQ01)'

say
say 'ZSCH220I READING ORDER SEQUENCE:' seqdsn

"ALLOC F(SEQDD) DA('"seqdsn"') OLD REUSE"

if rc <> 0 then do
   say 'ZSCH221E CANNOT ALLOCATE ORDER SEQUENCE'
   exit 8
end

/********************************************************************/
/* READ CURRENT SEQUENCE VALUE                                      */
/********************************************************************/

"EXECIO 1 DISKR SEQDD (STEM SEQ. FINIS"

if rc <> 0 then do
   say 'ZSCH222E CANNOT READ ORDER SEQUENCE'
   "FREE F(SEQDD)"
   exit 8
end

if seq.0 < 1 then do
   say 'ZSCH223E ORDER SEQUENCE IS EMPTY'
   "FREE F(SEQDD)"
   exit 8
end

/********************************************************************/
/* PARSE LASTID=NNNNNNN                                             */
/********************************************************************/

parse var seq.1 seqkey '=' lastid

seqkey = strip(translate(seqkey))
lastid = strip(lastid)

if seqkey <> 'LASTID' then do
   say 'ZSCH224E INVALID SEQUENCE RECORD'
   "FREE F(SEQDD)"
   exit 8
end

if lastid = '' then do
   say 'ZSCH225E LASTID VALUE MISSING'
   "FREE F(SEQDD)"
   exit 8
end

if datatype(lastid,'W') = 0 then do
   say 'ZSCH226E LASTID IS NOT NUMERIC'
   "FREE F(SEQDD)"
   exit 8
end

/********************************************************************/
/* GENERATE NEXT ORDER-ID                                           */
/********************************************************************/

nextid = lastid + 1

if nextid > 9999999 then do
   say 'ZSCH227E ORDER-ID RANGE EXHAUSTED'
   "FREE F(SEQDD)"
   exit 8
end

orderid = right(nextid,7,'0')
actmem  = 'A' || orderid

say 'ZSCH228I ORDER-ID RESERVED:' orderid

/********************************************************************/
/* PERSIST THE NEW LASTID                                           */
/********************************************************************/

seqout.0 = 1
seqout.1 = 'LASTID='orderid

"EXECIO 1 DISKW SEQDD (STEM SEQOUT. FINIS"

seqrc = rc

"FREE F(SEQDD)"

if seqrc <> 0 then do
   say 'ZSCH229E CANNOT UPDATE ORDER SEQUENCE'
   exit 8
end

/********************************************************************/
/* BUILD ACTIVE DATA SET MEMBER NAME                                */
/********************************************************************/

actdsn = 'IBMUSER.ZSCH.ACTIVE('actmem')'

/********************************************************************/
/* BUILD ACTIVE RUNTIME INSTANCE                                    */
/********************************************************************/

out.0  = 12
out.1  = 'ORDERID='orderid
out.2  = 'NAME='name
out.3  = 'ODATE='date('S')
out.4  = 'OTIME='time('N')
out.5  = 'STATE=ORDERED'
out.6  = 'JOBID='
out.7  = 'RUNNO=1'
out.8  = 'JCLDSN='jcldsn
out.9  = 'MEMBER='jmember
out.10 = 'OWNER='owner
out.11 = 'MAXRC='maxrc
out.12 = 'RERUN='rerun

/********************************************************************/
/* CREATE ACTIVE INSTANCE                                           */
/********************************************************************/

say
say 'ZSCH210I CREATING ACTIVE INSTANCE:' actdsn

"ALLOC F(ACTDD) DA('"actdsn"') SHR REUSE"

if rc <> 0 then do
   say 'ZSCH205E CANNOT ALLOCATE ACTIVE INSTANCE'
   exit 8
end

"EXECIO "out.0" DISKW ACTDD (STEM OUT. FINIS"

writerc = rc

"FREE F(ACTDD)"

if writerc <> 0 then do
   say 'ZSCH206E CANNOT WRITE ACTIVE INSTANCE'
   exit 8
end

/********************************************************************/
/* DISPLAY RESULT                                                   */
/********************************************************************/

say
say '----------------------------------------'
say ' Z/OS BATCH SCHEDULER - ACTIVE JOB'
say '----------------------------------------'
say 'ORDERID  :' orderid
say 'NAME     :' name
say 'STATE    : ORDERED'
say 'JCLDSN   :' jcldsn
say 'MEMBER   :' jmember
say 'OWNER    :' owner
say 'MAXRC    :' maxrc
say 'RERUN    :' rerun
say '----------------------------------------'
say
say 'ZSCH200I JOB ORDERED SUCCESSFULLY'
say 'ZSCH211I ACTIVE MEMBER:' actmem

exit 0
