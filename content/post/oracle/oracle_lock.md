

+++
title = "oracle锁表问题"
description = "oracle锁表问题"
tags = [
    "oracle"
]
date = "2018-08-21T20:46:49+08:00"
categories = [
    "oracle",
]
+++


### 查询oralce锁表

```sql
--查询锁表会话
SELECT  s.username,
decode(l.type,'TM','TABLE LOCK',
'TX','ROW LOCK',
NULL) LOCK_LEVEL,
o.owner,o.object_name,o.object_type,
s.sid,s.serial#,s.terminal,s.machine,s.program,s.osuser
FROM v$session s,v$lock l,dba_objects o
WHERE l.sid = s.sid
AND l.id1 = o.object_id(+)
AND s.username is NOT Null



--杀死事务
alter system kill session'SID,SERIAL#';


--查询锁表的sql语句
SELECT l.session_id sid, s.serial#, l.locked_mode, l.oracle_username, s.user#,
l.os_user_name,s.machine, s.terminal,a.sql_text, a.action
FROM v$sqlarea a,v$session s, v$locked_object l
WHERE l.session_id = s.sid
AND s.prev_sql_addr = a.address
ORDER BY sid, s.serial#;

```

