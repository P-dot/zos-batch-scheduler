/* REXX */

/********************************************************************/
/* ZSCHORD - Z/OS BATCH SCHEDULER                                   */
/* LAB 01 - CREATE FIRST ACTIVE JOB INSTANCE                        */
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
/* READ DEFINITION                                                  */
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

name    = ''
jcldsn  = ''
jmember = ''
owner   = ''
initial = ''
maxrc   = ''
rerun   = ''

do i = 1 to rec.0

   line = strip(rec.i)

   if line = '' then iterate

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
/* LAB 01 FIXED ORDER ID                                            */
/* A real sequence generator will be introduced in the next lab.    */
/********************************************************************/

orderid = '0000001'
actmem  = 'A0000001'

actdsn = 'IBMUSER.ZSCH.ACTIVE('actmem')'

/********************************************************************/
/* BUILD ACTIVE INSTANCE                                            */
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
