

-- Q1:  which rooms have a given facility

create or replace function
	Q1(text) returns setof FacilityRecord
as $$
select r.longname, f.description
from   Rooms r
        join RoomFacilities rf on (rf.room=r.id)
        join Facilities f on (rf.facility=f.id)
where f.description ilike '%'||$1||'%';
-- where lower(f.description) like lower('%'||$1||'%');
$$ language sql
;

-- Function: term names

create or replace function
	TermName(integer) returns text
as
$$
select substr(year::text,3,2)||lower(sess)
from   Terms
where  id = $1
$$ language sql;

-- Q2: semester containing a particular day

create or replace function Q2(_day date) returns text 
as $$
declare
	minDate date;     -- start date of earliest semester
	maxDate date;     -- end date of last semester (in database)
	nextStart date;   -- effective start date of semester
	prevEnd date;     -- effective end date of semester
	currTerm integer; -- Terms.id of current semester
	prevTerm integer; -- Terms.id of semester before current
	nextTerm integer; -- Terms.id of semester after current
    theTerm integer;  -- matching term
	termGap interval; -- days between terms
begin
	-- check for outside range of known semesters
	select into minDate min(starting) from Terms;
	select into maxDate max(ending) from Terms;
	if (_day < minDate or _day > maxDate) then
		return null;
	end if;
	-- hande the easy case ... lies within existing semester dates
	select id into theTerm
    from   Terms
    where  _day between starting and ending;
	if (theTerm is not null) then
		return TermName(theTerm);
	end if;
	-- not in a Term, find terms around given date
	select id, ending into prevTerm, prevEnd from Terms
	where  ending = (select max(ending) from Terms where ending < _day);
	select id, starting into nextTerm, nextStart from Terms
	where starting = (select min(starting) from Terms where starting > _day);
	termGap := nextStart::timestamp - prevEnd::timestamp;
	if (termGap < '1 week') then
		nextStart := (prevEnd::timestamp + '1 day')::date;
	else
		nextStart := (nextStart::timestamp - interval '1 week')::date;
		prevEnd := (nextStart::timestamp - interval '1 day')::date;
	end if;
	if (_day <= prevEnd::date) then
		return TermName(prevTerm);
	elsif (_day >= nextStart::date) then
		return TermName(nextTerm);
	else
		return 'Ooops?';
	end if;
end;
$$ language plpgsql
;


-- Q3: transcript with variations

create or replace function
	Q3(_sid integer) returns setof TranscriptRecord
as $$
declare
	rec TranscriptRecord;
	var record;
	subj Subjects;
	UOCtotal integer := 0;
	UOCpassed integer := 0;
	UOCadvanced integer := 0;
	wsum integer := 0;
	wam integer := 0;
	stu_id integer;
begin
	select s.id into stu_id
	from   Students s join People p on (p.id=s.id)
	where  p.unswid=_sid;
	if (not found) then
		raise EXCEPTION 'Invalid student %',_sid;
	end if;
	for rec in
		select s.code, substr(t.year::text,3,2)||lower(t.sess),
			s.name, e.mark, e.grade, s.uoc
		from   CourseEnrolments e, Courses c, Subjects s, Terms t
		where  e.student = stu_id and e.course = c.id
			and c.subject = s.id and c.term = t.id
		order by t.starting,s.code
	loop
		if (rec.grade = 'SY') then
			UOCpassed := UOCpassed + rec.uoc;
		elsif (rec.mark is not null) then
			if (rec.grade in ('PT','PC','PS','CR','DN','HD')) then
				-- only counts towards creditted UOC
				-- if they passed the course
				UOCpassed := UOCpassed + rec.uoc;
			end if;
			-- we count fails towards the WAM calculation
			UOCtotal := UOCtotal + rec.uoc;
			-- weighted sum based on mark and uoc for course
			wsum := wsum + (rec.mark * rec.uoc);
		end if;
		return next rec;
	end loop;
	UOCadvanced := 0;
	for var in
		select s.id as subject, s.code, s.uoc,
		         v.vtype, v.intequiv, v.extequiv
		from   Variations v join Subjects s on (v.subject = s.id)
		where  v.student = stu_id
		order by s.code 
	loop
		-- possibilities: advstanding, substitution, exemption
		-- advstanding counts towards UOC, others don't
		rec = (var.code,null,null,null,null,null);
		if (var.vtype = 'advstanding') then
			UOCadvanced := UOCadvanced + var.uoc;
			rec.name := 'Advanced standing, based on ...';
			rec.uoc  := var.uoc;
		elsif (var.vtype = 'substitution') then
			rec.name := 'Substitution, based on ...';
		else
			rec.name := 'Exemption, based on ...';
		end if;
		return next rec;
		-- possibilities: internal/external subject
		rec.code := null; rec.uoc := null;
		if (var.intequiv is not null) then
			select 'studying '||code||' at UNSW' into rec.name
			from   Subjects where id = var.intequiv;
		else
			select 'study at '||institution into rec.name
			from   ExternalSubjects where id = var.extequiv;
		end if;
		return next rec;
	end loop;
	-- append record containing WAM
	if (UOCtotal = 0) then
		rec := (null,null,'No WAM available',null,null,null);
	else
		wam := wsum / UOCtotal;
		rec := (null,null,'Overall WAM',wam,null,UOCpassed+UOCadvanced);
	end if;
	return next rec;
end;
$$ language plpgsql
;
