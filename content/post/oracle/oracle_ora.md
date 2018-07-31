


## oracle临时表空间满问题

```sql
--查询表空间使用情况
select * from (
Select a.tablespace_name,
to_char(a.bytes/1024/1024,'99,999.999') total_bytes,
to_char(b.bytes/1024/1024,'99,999.999') free_bytes,
to_char(a.bytes/1024/1024 - b.bytes/1024/1024,'99,999.999') use_bytes,
to_char((1 - b.bytes/a.bytes)*100,'99.99') || '%'use
from (select tablespace_name,
sum(bytes) bytes
from dba_data_files
group by tablespace_name) a,
(select tablespace_name,
sum(bytes) bytes
from dba_free_space
group by tablespace_name) b
where a.tablespace_name = b.tablespace_name
union all
select c.tablespace_name,
to_char(c.bytes/1024/1024,'99,999.999') total_bytes,
to_char( (c.bytes-d.bytes_used)/1024/1024,'99,999.999') free_bytes,
to_char(d.bytes_used/1024/1024,'99,999.999') use_bytes,
to_char(d.bytes_used*100/c.bytes,'99.99') || '%'use
from
(select tablespace_name,sum(bytes) bytes
from dba_temp_files group by tablespace_name) c,
(select tablespace_name,sum(bytes_cached) bytes_used
from v$temp_extent_pool group by tablespace_name) d
where c.tablespace_name = d.tablespace_name
)
order by tablespace_name

--查表空间使用情况
SELECT a.tablespace_name, 
a.bytes total, 
b.bytes used, 
c.bytes free, 
(b.bytes * 100) / a.bytes "% USED ", 
(c.bytes * 100) / a.bytes "% FREE " 
FROM sys.sm$ts_avail a, sys.sm$ts_used b, sys.sm$ts_free c 
WHERE a.tablespace_name = b.tablespace_name 
AND a.tablespace_name = c.tablespace_name; 



--查询临时表空间使用情况
SELECT   se.username,
         se.sid,
         su.extents,
         su.blocks * to_number(rtrim(p.value)) asSpace,
         tablespace,
         segtype,
         sql_text
FROM v$sort_usage su, v$parameter p, v$session se, v$sql s
   WHERE p.name = 'db_block_size'
     AND su.session_addr = se.saddr
     AND s.hash_value = su.sqlhash
     AND s.address = su.sqladdr
ORDER BY se.username, se.sid;

--查询谁在使用临时表空间
SELECT se.username, se.SID, se.serial#, se.sql_address, se.machine, se.program, su.TABLESPACE,su.segtype, su.CONTENTS from
v$session se, v$sort_usage su WHERE se.saddr = su.session_addr


--kill正在使用临时段的进程
Alter system kill session 'sid,serial#';



```
