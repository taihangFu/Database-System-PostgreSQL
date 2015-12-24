-- COMP9311 14s1 Proj 1
--
-- check.sql ... checking functions
--
--

--
-- Helper functions
--

create or replace function
	ass2_table_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='r';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	ass2_view_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='v';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	ass2_function_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_proc
	where proname=tname;
	return (_check > 0);
end;
$$ language plpgsql;

-- ass2_check_result:
-- * determines appropriate message, based on count of
--   excess and missing tuples in user output vs expected output

create or replace function
	ass2_check_result(nexcess integer, nmissing integer) returns text
as $$
begin
	if (nexcess = 0 and nmissing = 0) then
		return 'correct';
	elsif (nexcess > 0 and nmissing = 0) then
		return 'too many result tuples';
	elsif (nexcess = 0 and nmissing > 0) then
		return 'missing result tuples';
	elsif (nexcess > 0 and nmissing > 0) then
		return 'incorrect result tuples';
	end if;
end;
$$ language plpgsql;

-- ass2_check:
-- * compares output of user view/function against expected output
-- * returns string (text message) containing analysis of results

create or replace function
	ass2_check(_type text, _name text, _res text, _query text) returns text
as $$
declare
	nexcess integer;
	nmissing integer;
	excessQ text;
	missingQ text;
begin
	if (_type = 'view' and not ass2_view_exists(_name)) then
		return 'No '||_name||' view; did it load correctly?';
	elsif (_type = 'function' and not ass2_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (not ass2_table_exists(_res)) then
		return _res||': No expected results!';
	else
		excessQ := 'select count(*) '||
			   'from (('||_query||') except '||
			   '(select * from '||_res||')) as X';
		-- raise notice 'Q: %',excessQ;
		execute excessQ into nexcess;
		missingQ := 'select count(*) '||
			    'from ((select * from '||_res||') '||
			    'except ('||_query||')) as X';
		-- raise notice 'Q: %',missingQ;
		execute missingQ into nmissing;
		return ass2_check_result(nexcess,nmissing);
	end if;
	return '???';
end;
$$ language plpgsql;

-- ass2_rescheck:
-- * compares output of user function against expected result
-- * returns string (text message) containing analysis of results

create or replace function
	ass2_rescheck(_type text, _name text, _res text, _query text) returns text
as $$
declare
	_sql text;
	_chk boolean;
begin
	if (_type = 'function' and not ass2_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (_res is null) then
		_sql := 'select ('||_query||') is null';
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	else
		_sql := 'select ('||_query||') = '||quote_literal(_res);
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	end if;
	if (_chk) then
		return 'correct';
	else
		return 'incorrect result';
	end if;
end;
$$ language plpgsql;

-- check_all:
-- * run all of the checks and return a table of results

drop type if exists TestingResult cascade;
create type TestingResult as (test text, result text);

create or replace function
	check_all() returns setof TestingResult
as $$
declare
	i int;
	testQ text;
	result text;
	out TestingResult;
	tests text[] := array[
				'q1', 'q2', 'q3a', 'q3b', 'q3c', 'q3d', 'q3e', 'q3f',
				'q4', 'q5', 'q6'
				];
begin
	for i in array_lower(tests,1) .. array_upper(tests,1)
	loop
		testQ := 'select check_'||tests[i]||'()';
		execute testQ into result;
		out := (tests[i],result);
		return next out;
	end loop;
	return;
end;
$$ language plpgsql;


--
-- Check functions for specific test-cases in Proj 1
--

create or replace function check_q1() returns text
as $chk$
select ass2_check('view','q1','q1_expected',
                   $$select * from q1$$)
$chk$ language sql;

create or replace function check_q2() returns text
as $chk$
select ass2_check('view','q2','q2_expected',
                   $$select * from q2$$)
$chk$ language sql;

create or replace function check_q3a() returns text
as $chk$
select ass2_check('function','q3','q3a_expected',
                   $$select * from q3(190)$$)
$chk$ language sql;

create or replace function check_q3b() returns text
as $chk$
select ass2_check('function','q3','q3b_expected',
                   $$select * from q3(211)$$)
$chk$ language sql;

create or replace function check_q3c() returns text
as $chk$
select ass2_check('function','q3','q3c_expected',
                   $$select * from q3(169)$$)
$chk$ language sql;

create or replace function check_q3d() returns text
as $chk$
select ass2_check('function','q3','q3d_expected',
                   $$select * from q3(226)$$)
$chk$ language sql;

create or replace function check_q3e() returns text
as $chk$
select ass2_check('function','q3','q3e_expected',
                   $$select * from q3(150)$$)
$chk$ language sql;

create or replace function check_q3f() returns text
as $chk$
select ass2_check('function','q3','q3f_expected',
                   $$select * from q3(-1)$$)
$chk$ language sql;

create or replace function check_q4() returns text
as $chk$
select ass2_check('view','q4','q4_expected',
                   $$select * from q4$$)
$chk$ language sql;

create or replace function check_q5() returns text
as $chk$
select ass2_check('view','q5','q5_expected',
                   $$select * from q5$$)
$chk$ language sql;

create or replace function check_q6() returns text
as $chk$
select ass2_check('view','q6','q6_expected',
                   $$select * from q6$$)
$chk$ language sql;



--
-- Tables of expected results for test cases
--

drop table if exists q1_expected;
create table q1_expected (
    name longname,
    school longname,
    starting date
);

drop table if exists q2_expected;
create table q2_expected (
    status text,
    name longname,
    school longname,
    starting date
);

drop table if exists q3a_expected;
create table q3a_expected (
    q3 text
);

drop table if exists q3b_expected;
create table q3b_expected (
    q3 text
);

drop table if exists q3c_expected;
create table q3c_expected (
    q3 text
);

drop table if exists q3d_expected;
create table q3d_expected (
    q3 text
);

drop table if exists q3e_expected;
create table q3e_expected (
    q3 text
);

drop table if exists q3f_expected;
create table q3f_expected (
    q3 text
);

drop table if exists q4_expected;
create table q4_expected (
    term text,
    percent numeric(4,2)
);

drop table if exists q5_expected;
create table q5_expected (
    term text,
    nstudes bigint,
    fte numeric(6,1)
);

drop table if exists q6_expected;
create table q6_expected (
    subject text,
    nofferings bigint
);



COPY q1_expected (name, school, starting) FROM stdin;
Eliathamby Ambikairajah	Electrical Engineering & Telecommunications	1999-08-25
Anthony Dooley	Mathematics & Statistics	1980-11-03
Christopher Rizos	Surveying and Spatial Information Systems	1984-01-03
Nicholas Hawkins	Medical Sciences	1989-01-09
Ross Harley	Media Arts	1989-02-13
Richard Newbury	Physics	1991-03-01
Chandini MacIntyre	Public Health & Community Medicine	2008-03-26
Sylvia Ross	Art - COFA	1990-01-01
Fiona Stapleton	Optometry and Vision Science	1995-09-25
Margaret McKerchar	Australian School of Taxation (ATAX)	2000-01-28
Anne Simmons	Graduate School of Biomedical Engineering	1999-06-28
Andrew Killcross	Psychology	2001-07-01
Rogelia Pe-Pua	Social Sciences and International Studies	1996-02-12
Brendan Edgeworth	School of Law	1989-02-01
Roger Simnett	Accounting	1987-02-02
Philip Mitchell	Psychiatry	1985-01-07
Michael Chapman	Women's and Children's Health	1994-10-10
Kevin Fox	Economics	1994-07-01
Paul Patterson	Marketing	1996-09-02
Stephen Frenkel	Organisation and Management	1975-07-14
Kim Snepvangers	Art History & Art Education (COFA)	1993-02-02
David Cohen	Biological, Earth and Environmental Sciences	1990-01-29
Bruce Hebblewhite	Mining Engineering	1995-04-01
Richard Corkish	Photovoltaic and Renewable Engineering	1994-04-01
Barbara Messerle	Chemistry	1999-03-01
Liz Williamson	Design Studies - COFA	1997-01-02
Michael Frater	Information Technology and Electrical Engineering (ADF	1991-02-28
Michael Hess	Business (ADFA)	2004-05-21
David Lovell	Humanities and Social Sciences (ADFA)	1983-12-16
Christopher Taylor	Business Law and Taxation	1989-07-17
David Waite	Civil and Environmental Engineering	1993-07-05
John Ballard	Biotechnology and Biomolecular Sciences	2005-02-01
Paul Brown	History and Philosophy	1994-01-04
Brian Lees	Physical, Environmental and Mathematical Sciences (ADF	2002-06-26
Maurice Pagnucco	Computer Science and Engineering	2010-07-01
\.

COPY q2_expected (status, name, school, starting) FROM stdin;
Longest serving	Stephen Frenkel	Organisation and Management	1975-07-14
Most recent	Maurice Pagnucco	Computer Science and Engineering	2010-07-01
\.

COPY q3a_expected (q3) FROM stdin;
06x1
\.

COPY q3b_expected (q3) FROM stdin;
10s1
\.

COPY q3c_expected (q3) FROM stdin;
02x2
\.

COPY q3d_expected (q3) FROM stdin;
12s2
\.

COPY q3e_expected (q3) FROM stdin;
\N
\.

COPY q3f_expected (q3) FROM stdin;
\N
\.

COPY q4_expected (term, percent) FROM stdin;
05s1	0.24
05s2	0.23
06s1	0.23
06s2	0.23
07s1	0.23
07s2	0.23
08s1	0.25
08s2	0.26
09s1	0.26
09s2	0.27
10s1	0.27
10s2	0.29
11s1	0.30
\.

COPY q5_expected (term, nstudes, fte) FROM stdin;
00s1	5527	4990.3
00s2	5790	5219.3
01s1	6323	5454.3
01s2	6350	5511.0
02s1	6813	5816.4
02s2	7105	5988.3
03s1	7119	5994.9
03s2	6836	5742.7
04s1	6897	5734.5
04s2	6581	5486.1
05s1	6549	5305.0
05s2	6174	4954.5
06s1	6077	4905.4
06s2	5872	4750.8
07s1	5990	4847.4
07s2	5854	4741.2
08s1	6117	4980.9
08s2	6030	4927.2
09s1	6724	5512.6
09s2	6829	5566.4
10s1	7362	6128.7
10s2	7279	6094.9
\.

COPY q6_expected (subject, nofferings) FROM stdin;
GEND4209 Working with Jewellery	32
MDCN0003 Medicine: Short Course (St V)	32
GEND4208 Working with Ceramics	32
FINS5511 Corporate Finance	34
GEND4210 Textiles and Fashion	31
MDCN0001 Medicine:Short Course (SWSAHS)	31
MDCN0002 Medicine: Short Course (St G)	31
GEND1204 Studies in Painting	32
\.

