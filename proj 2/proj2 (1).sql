
-- Q1:  which rooms have a given facility

create or replace function
	Q1(text) returns setof FacilityRecord
as $$
... one SQL statement, possibly using other views defined by you ...
$$ language sql
;

-- Q2: semester containing a particular day

create or replace function Q2(_day date) returns text 
as $$
declare
	... PLpgSQL variable delcarations ...
begin
	... PLpgSQL code ...
end;
$$ language plpgsql
;

-- Q3: transcript with variations

create or replace function
	Q3(_sid integer) returns setof TranscriptRecord
as $$
declare
	... PLpgSQL variable delcarations ...
begin
	... PLpgSQL code ...
end;
$$ language plpgsql
;
