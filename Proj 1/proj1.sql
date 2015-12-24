-- COMP3311 14s1 Project 1
-- Written by thfu013, April 2014

-- Q1: get details of the current Heads of Schools

create or replace view Q1(name, school, starting)
as
select p.name, o.longname, a.starting
from affiliation a join orgunits o on a.orgunit = o.id
join staff s on a.staff = s.id
join people p on s.id = p.id
join staffroles r on a.role = r.id
join orgunittypes t on o.utype = t.id
where r.description = 'Head of School' and
a.ending is NULL and
a.isprimary = 't' and
t.name = 'School'

;

-- Q2: longest-serving and most-recent current Heads of Schools

create or replace view Q2(status, name, school, starting)
as
-- most recent
(select 'Most recent' as status, q1.* 
from q1, 
     (select starting from q1 order by starting desc limit 1) mr
     where q1.starting = mr.starting
)

union

-- longest serving
(select 'Longest serving' as status, q1.* 
from q1, 
     (select starting from q1 order by starting limit 1) mr
     where q1.starting = mr.starting
)
;

-- Q3: term names

create or replace function
	Q3(integer) returns text
as
$$
   select SUBSTR(to_char(year, '9999'),4,2)||lower(sess) from terms where id = $1
$$ language sql;


-- Q4: percentage of international students, S1 and S2, 2005..2011
create or replace view Q4_intl(term, count)
as
select q3(p.term), count(*) 
from programenrolments p, terms t, students s
where p.term = t.id
and t.year >= 2005
and (t.sess = 'S1' or t.sess ='S2')
and p.student = s.id
and s.stype = 'intl'
group by p.term ;

create or replace view Q4_total(term, count)
as
select q3(p.term), count(*) 
from programenrolments p, terms t
where p.term = t.id
and t.year >= 2005
and (t.sess = 'S1' or t.sess ='S2')
group by p.term ;


create or replace view Q4(term, percent)
as
select i.term, (cast(i.count as float) / cast(t.count as float))::numeric(4,2) as percent
from q4_intl i, q4_total t
where i.term = t.term
;

-- Q5: total FTE students per term since 2005

create or replace view Q5(term, nstudes, fte)
as
select F.term, N.nstudes, F.FTE
from
(select q3(t.id) as term, (sum(cast(s.uoc as float))/24)::numeric(6,1) as FTE
from courseenrolments ce, courses c, terms t, subjects s
where ce.course = c.id 
and c.subject = s.id
and c.term = t.id
and (t.year >= 2000 and t.year<=2010)
and (t.sess = 'S1' or t.sess = 'S2')
group by t.id) as F
,
(select q3(t.id) as term, count(distinct(ce.student)) as nstudes
from courseenrolments ce, courses c, terms t, subjects s
where ce.course = c.id 
and c.subject = s.id
and c.term = t.id
and (t.year >= 2000 and t.year<=2010)
and (t.sess = 'S1' or t.sess = 'S2')
group by t.id) as N
where F.term = N.term
;

-- Q6: subjects with > 30 course offerings and no staff recorded

create or replace view Q6(subject, nOfferings)
as
select (s.code || ' ' ||s.name) as subject  , count(*) as nOfferings
from courses c left join coursestaff cs on cs.course = c.id
	                join subjects s on c.subject = s.id	                
group by s.id
having count(*) > 30 and every(cs.staff is NULL)
;



