-- solution.sql
-- Sample solution to COMP3311 14s1 Project 1


-- Q1: get details of the current Heads of Schools

create or replace view Q1(name, school, starting)
as
select p.name, u.longname, a.starting
from   People p
         join Affiliation a on (a.staff=p.id)
         join StaffRoles r on (a.role = r.id)
         join OrgUnits u on (a.orgunit = u.id)
         join OrgUnitTypes t on (u.utype = t.id)
where  r.description = 'Head of School'
         and (a.ending is null or a.ending > now()::date)
         and t.name = 'School' and a.isPrimary
;


-- Q2: longest-serving and most-recent current Heads of Schools

create or replace view LongestServingHoS(status, name, school, starting)
as
select 'Longest serving'::text, Q1.*
from   Q1
where  starting = (select min(starting) from Q1)
;

create or replace view MostRecentHoS(status, name, school, starting)
as
select 'Most recent'::text, Q1.*
from   Q1
where  starting = (select max(starting) from Q1)
;

create or replace view Q2(status, name, school, starting)
as
(select * from LongestServingHoS)
union
(select * from MostRecentHoS)
;


-- Q3: term names

create or replace function
	Q3(integer) returns text
as
$$
select substr(year::text,3,2)||lower(sess)
from   Terms
where  id = $1
$$ language sql;


-- Q4: percentage of international students, S1 and S2, 2005..2011

create or replace view EnrolmentInfo(student, stype, term)
as
select distinct pe.student, s.stype, pe.term
from   ProgramEnrolments pe
         join Students s on (pe.student = s.id)
;

create or replace view TermStats(term, nlocals, nintls, ntotal)
as
select term,
         sum(case when stype='local' then 1 else 0 end),
         sum(case when stype='intl' then 1 else 0 end),
         count(distinct student)
from   EnrolmentInfo
group  by term
;

create or replace view Q4(term, percent)
as
select q3(t.id), (nintls::float / ntotal::float)::numeric(4,2)
from   TermStats s
         join Terms t on (s.term = t.id)
where  t.sess like 'S_' and
         t.starting between '2005-01-01' and '2011-12-31'
;


-- Q5: total FTE students per term since 2005

create or replace view FTE_EnrolmentInfo(student,subject,uoc,term)
as
select e.student, s.id, s.uoc, c.term
from   CourseEnrolments e
         join Courses c on (e.course=c.id)
         join Subjects s on (c.subject=s.id)
;

create or replace view Q5(term, nstudes, fte)
as
select q3(t.id), count(distinct e.student),
        (sum(e.uoc)::float/24.0)::numeric(6,1)
from   FTE_EnrolmentInfo e
         join Terms t on (e.term = t.id)
where  t.starting between '2000-01-01' and '2010-12-31'
         and t.sess like 'S_'
group  by t.id
;


-- Q6: subjects with > 30 course offerings and no staff recorded

create or replace view Q6(subject, nOfferings)
as
select s.code||' '||s.name, count(c.id)
from   Courses c
         left outer join CourseStaff cs on (cs.course=c.id)
         join Subjects s on (c.subject = s.id)
group  by s.code,s.name
having count(cs.staff) = 0 and count(c.id) > 30
;
