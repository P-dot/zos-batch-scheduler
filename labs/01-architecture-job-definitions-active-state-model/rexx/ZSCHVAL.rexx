/* REXX */

/********************************************************************/
/* ZSCHVAL - Z/OS BATCH SCHEDULER                                   */
/* LAB 01 - JOB DEFINITION VALIDATOR                                */
/********************************************************************/

parse upper arg member

if member = '' then do
   say 'ZSCH001E MEMBER NAME REQUIRED'
   exit 8
end

defdsn = 'IBMUSER.ZSCH.DEF('member')'

say 'ZSCH010I VALIDATING DEFINITION:' defdsn

"ALLOC F(DEFDD) DA('"defdsn"') SHR REUSE"

if rc <> 0 then do
   say 'ZSCH002E CANNOT ALLOCATE DEFINITION'
   exit 8
end

"EXECIO * DISKR DEFDD (STEM REC. FINIS"

if rc <> 0 then do
   say 'ZSCH003E CANNOT READ DEFINITION'
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
         say 'ZSCH020W UNKNOWN KEY:' key

   end
end

errors = 0

if name = '' then do
   say 'ZSCH101E NAME MISSING'
   errors = errors + 1
end

if jcldsn = '' then do
   say 'ZSCH102E JCLDSN MISSING'
   errors = errors + 1
end

if jmember = '' then do
   say 'ZSCH103E MEMBER MISSING'
   errors = errors + 1
end

if owner = '' then do
   say 'ZSCH104E OWNER MISSING'
   errors = errors + 1
end

if initial = '' then do
   say 'ZSCH105E INITIAL STATE MISSING'
   errors = errors + 1
end

if maxrc = '' then do
   say 'ZSCH106E MAXRC MISSING'
   errors = errors + 1
end

if rerun = '' then do
   say 'ZSCH107E RERUN POLICY MISSING'
   errors = errors + 1
end

if errors > 0 then do
   say 'ZSCH900E DEFINITION INVALID -' errors 'ERROR(S)'
   exit 8
end

say
say '----------------------------------------'
say ' Z/OS BATCH SCHEDULER - JOB DEFINITION'
say '----------------------------------------'
say 'NAME     :' name
say 'JCLDSN   :' jcldsn
say 'MEMBER   :' jmember
say 'OWNER    :' owner
say 'INITIAL  :' initial
say 'MAXRC    :' maxrc
say 'RERUN    :' rerun
say '----------------------------------------'
say
say 'ZSCH000I DEFINITION VALID'

exit 0
