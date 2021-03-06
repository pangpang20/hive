--! qt:dataset:cbo_t3
--! qt:dataset:cbo_t2
--! qt:dataset:cbo_t1
set hive.mapred.mode=nonstrict;
set hive.cbo.enable=true;
set hive.exec.check.crossproducts=false;

set hive.stats.fetch.column.stats=true;
set hive.auto.convert.join=false;

-- 7. Test Select + TS + Join + Fil + GB + GB Having + Limit
select key, (c_int+1)+2 as x, sum(c_int) from cbo_t1 group by c_float, cbo_t1.c_int, key order by x limit 1;
select x, y, count(*) from (select key, (c_int+c_float+1+2) as x, sum(c_int) as y from cbo_t1 group by c_float, cbo_t1.c_int, key) R group by y, x order by x,y limit 1;
select key from(select key from (select key from cbo_t1 limit 5)cbo_t2  limit 5)cbo_t3  limit 5;
select key, c_int from(select key, c_int from (select key, c_int from cbo_t1 order by c_int limit 5)cbo_t1  order by c_int limit 5)cbo_t2  order by c_int limit 5;

select cbo_t3.c_int, c, count(*) from (select key as a, c_int+1 as b, sum(c_int) as c from cbo_t1 where (cbo_t1.c_int + 1 >= 0) and (cbo_t1.c_int > 0 or cbo_t1.c_float >= 0) group by c_float, cbo_t1.c_int, key order by a limit 5) cbo_t1 join (select key as p, c_int+1 as q, sum(c_int) as r from cbo_t2 where (cbo_t2.c_int + 1 >= 0) and (cbo_t2.c_int > 0 or cbo_t2.c_float >= 0)  group by c_float, cbo_t2.c_int, key order by q/10 desc, r asc limit 5) cbo_t2 on cbo_t1.a=p join cbo_t3 on cbo_t1.a=key where (b + cbo_t2.q >= 0) and (b > 0 or c_int >= 0) group by cbo_t3.c_int, c order by cbo_t3.c_int+c desc, c limit 5;

select cbo_t3.c_int, c, count(*) from (select key as a, c_int+1 as b, sum(c_int) as c from cbo_t1 where (cbo_t1.c_int + 1 >= 0) and (cbo_t1.c_int > 0 or cbo_t1.c_float >= 0)  group by c_float, cbo_t1.c_int, key having cbo_t1.c_float > 0 and (c_int >=1 or c_float >= 1) and (c_int + c_float) >= 0 order by b % c asc, b desc limit 5) cbo_t1 left outer join (select key as p, c_int+1 as q, sum(c_int) as r from cbo_t2 where (cbo_t2.c_int + 1 >= 0) and (cbo_t2.c_int > 0 or cbo_t2.c_float >= 0)  group by c_float, cbo_t2.c_int, key  having cbo_t2.c_float > 0 and (c_int >=1 or c_float >= 1) and (c_int + c_float) >= 0 limit 5) cbo_t2 on cbo_t1.a=p left outer join cbo_t3 on cbo_t1.a=key where (b + cbo_t2.q >= 0) and (b > 0 or c_int >= 0) group by cbo_t3.c_int, c  having cbo_t3.c_int > 0 and (c_int >=1 or c >= 1) and (c_int + c) >= 0  order by cbo_t3.c_int % c asc, cbo_t3.c_int, c desc limit 5;

-- order by and limit
explain cbo select count(*) cs from cbo_t1 where c_int > 1 order by cs limit 100;
select count(*) cs from cbo_t1 where c_int > 1 order by cs limit 100;

-- only order by
explain cbo select count(*) cs from cbo_t1 where c_int > 1 order by cs ;
select count(*) cs from cbo_t1 where c_int > 1 order by cs ;

-- only LIMIT
explain cbo select count(*) cs from cbo_t1 where c_int > 1 LIMIT 100;
select count(*) cs from cbo_t1 where c_int > 1 LIMIT 100;

-- LIMIT 1
explain cbo select c_int from (select c_int from cbo_t1 where c_float > 1.0 limit 1) subq  where c_int > 1 order by c_int;
select c_int from (select c_int from cbo_t1 where c_float > 1.0 limit 1) subq  where c_int > 1 order by c_int;

explain cbo select count(*) from cbo_t1 where c_float > 1.0 group by true limit 0;
select count(*) from cbo_t1 where c_float > 1.0 group by true limit 0;

-- prune un-necessary aggregates
explain cbo select count(*) from cbo_t1 order by sum(c_int), count(*);
select count(*) from cbo_t1 order by sum(c_int), count(*);
