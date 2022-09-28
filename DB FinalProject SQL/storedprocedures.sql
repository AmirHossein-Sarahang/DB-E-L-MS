Drop procedure if exists college.usp_loginuser
DELIMITER //
CREATE PROCEDURE college.usp_loginuser(IN TSNO nvarchar(20),
IN procpass nvarchar(200),out response int,out outtext nvarchar(50),
out kind int,out finaluserid int,out STID int
)
COMMENT "for checking sql login"
BEGIN
SET @dbpass = coalesce((select u.pass dbpass from student s left join users u on s.userid=u.id where s.student_no = TSNO)
,(select u.pass dbpass from teacher t left join users u on t.userid=u.id where t.professor_no = TSNO));
set @dbuser = coalesce((select u.id dbuser from student s left join users u on s.userid=u.id where s.student_no = TSNO)
,(select u.id dbuser from teacher t left join users u on t.userid=u.id where t.professor_no = TSNO));
SET @pass = (MD5(procpass));
SET @useridS = (select userid from student s where s.student_no =TSNO);
SET @useridT = (select userid from teacher t where t.professor_no = TSNO);
SET STID = coalesce((select ID from student s where s.student_no =TSNO)
,(select ID from teacher t where t.professor_no = TSNO));
IF(@dbpass=@pass and @dbuser=@useridS)
	then 
	begin 
	set response = 1 ;
	set outtext = N'دانشجو گرامی به حساب کاربری خود وارد شدید';
    set kind = 1 ;
    set finaluserid = @useridS;
    update logininfo set userstatus=0 where userid=@useridS;
    insert into logininfo(userid,logindate,userstatus)
    values(@useridS,CURRENT_TIMESTAMP(),response);
	end;
ELSEIF(@dbpass=@pass and @dbuser=@useridT)
	then 
	begin 
	set response = 1 ;
	set outtext = N'استاد گرامی به حساب کاربری خود وارد شدید';
    set kind = 2 ;
    set finaluserid = @useridT;
    update logininfo set userstatus=0 where userid=@useridS;
    insert into logininfo(userid,logindate,userstatus)
    values(@useridT,CURRENT_TIMESTAMP(),response);
	end;
ELSE 
	set response = 0;
	set outtext = 'نام کاربری یا رمز عبور اشتباه است';
    set kind = 0;
    set finaluserid = -1;
END IF;
END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_logoutuser
DELIMITER //
Create procedure college.usp_logoutuser(in puserid int,
out outtext nvarchar(50),out ERRORMESSAGE nvarchar(4000))
COMMENT 'for close current user session'
BEGIN

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
		GET DIAGNOSTICS CONDITION 1 @ERRNO = MYSQL_ERRNO, @MESSAGE_TEXT = MESSAGE_TEXT;
        set ERRORMESSAGE = (SELECT  CONCAT('MySQL ERROR: ', @ERRNO, ': ', @MESSAGE_TEXT) AS MESSAGE);
		set outtext=N'خظایی رخ داده است';
        ROLLBACK;
END; 

START TRANSACTION;
set @sessionid = (select max(ID) as sessionid from logininfo li  where li.userstatus=1 and li.userid=puserid );
if @sessionid IS NULL
then 
begin
set outtext=N'کاربری یافت نشد';
ROLLBACK;
end;
end if;
update logininfo set userstatus=0 where id=@sessionid;
IF(select userstatus from logininfo li where id=@sessionid)=0
	then
    begin
    set outtext=N'پنل شما با موفقیت بسته شد';
    end;
END IF;
COMMIT;

END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_changepassword
DELIMITER //
Create procedure college.usp_changepassword(in puserid int,
in newpass nvarchar(25),in newpassrepeat nvarchar(25),out outtext nvarchar(150))
COMMENT 'for change password'
BEGIN

set @passsecurity = (case when(
(REGEXP_LIKE(newpass,'[0-9]')) and
( REGEXP_LIKE(newpass,'[A-Z]') ) and
(length(newpass) between 8 and 20))
 then true else false end);
IF (newpass = newpassrepeat) and @passsecurity
	THEN
    BEGIN
	update users set pass=MD5(newpass) where id = puserid;
    set outtext = N'پسورد با موفقیت تغییر یافت';
    END;
ELSEIF (newpass <> newpassrepeat) 
	THEN
    BEGIN
    set outtext = N'پسوردهای وارد شده مطابقت ندارد';
    END;
ELSE
	set outtext = N'پسورد امن نیست؛ پسورد باید شامل حروف و عدد باشد و کمتر از 8 و بیشتر از 20 رقم نباشد';
END IF;

END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_showcoursesperuser
DELIMITER //
Create procedure college.usp_showcoursesperuser(in puserid int)
COMMENT 'show courses for every user'
BEGIN
select * from(select c.teacherID STID,t.userid,c.id as courseid,
u.name_fa as 'نام استاد',c.course_name as 'نام درس',c.year as 'سال تحصیلی' from
courses c left join
teacher t on t.id=c.teacherid left join
users u on u.id=t.userid
union all
select s.id as STID,s.userid,cl.courseid,u.name_fa as 'نام استاد',
c.course_name as 'نام درس',c.year as 'سال تحصیلی' from 
student s left join
classrooms cl on cl.studentid=s.id left join
courses c on c.id=cl.courseid left join
teacher t on t.id=c.teacherid left join
users u on u.id=t.userid)total
where userid = puserid;
END
//
DELIMITER ;

/**************************************/
Drop procedure if exists college.usp_showstudentsperteacher
DELIMITER //
Create procedure college.usp_showstudentsperteacher(in puserid int)
COMMENT 'show students for every teacher'
BEGIN
select * from (select t.id as teacherid,t.userid,s.id as studentid,cl.courseid,u.name_fa as 'نام دانشجو',
c.course_name as 'نام درس',c.year as 'سال تحصیلی' from 
teacher t left join
courses c on  t.id=c.teacherid left join
classrooms cl on cl.courseid=c.id left join
student s on cl.studentid=s.id left join
users u on u.id=s.userid
where t.userid = puserid)total;
END
//
DELIMITER ;

/**************************************/
Drop procedure if exists college.usp_showexam_practice_perteacher
DELIMITER //
Create procedure college.usp_showexam_practice_perteacher(in puserid int,in pcourseid int)
COMMENT 'show all exam and practice per teacher'
BEGIN

select * from (select p.id,t.id as teacherid,t.userid,c.id as courseid,u.name_fa as 'نام استاد',
c.course_name as 'نام درس',c.year as 'سال تحصیلی','تمرین' as 'موضوع',
IFNULL(p.question,N'تمرینی وجود ندارد') as 'عنوان',CURRENT_TIMESTAMP() as starttime,
IFNULL(p.deadline,CURRENT_TIMESTAMP()) as endtime, 1 as kind from 
teacher t left join
courses c on c.teacherID=t.id left join
practice p on p.courseid=c.id left join
users u on u.id=t.userid
union all
select e.id ,t.id as teacherid,t.userid,c.id as courseid,u.name_fa as 'نام استاد',
c.course_name as 'نام درس',c.year as 'سال تحصیلی','امتحان'  as 'موضوع',
IFNULL(e.exam_name,N'امتحانی وجود ندارد') as 'عنوان',
IFNULL(e.starttime,CURRENT_TIMESTAMP())as starttime,
IFNULL(e.endtime,CURRENT_TIMESTAMP()) as endtime, 2 as kind from 
teacher t left join
courses c on c.teacherID=t.id left join
exam e on e.courseid=c.id left join
users u on u.id=t.userid)total
where userid=puserid and courseid=pcourseid
order by kind;
END
//
DELIMITER ;

/**************************************/
Drop procedure if exists college.usp_insert_practice
DELIMITER //
Create procedure college.usp_insert_practice(in pcourseid int,in pquestion nvarchar(500)
,in panswer nvarchar(500),in pdeadline datetime,out outtext nvarchar(100),
out ERRORMESSAGE nvarchar(4000))
COMMENT 'for insert practice'
BEGIN

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
		GET DIAGNOSTICS CONDITION 1 @ERRNO = MYSQL_ERRNO, @MESSAGE_TEXT = MESSAGE_TEXT;
        set ERRORMESSAGE = (SELECT  CONCAT('MySQL ERROR: ', @ERRNO, ': ', @MESSAGE_TEXT) AS MESSAGE);
		set outtext=N'خظایی رخ داده است';
        ROLLBACK;
END; 

START TRANSACTION;
BEGIN
insert into practice(courseid,question,answer,deadline)
values(pcourseid,pquestion,panswer,pdeadline);
set outtext=N'تمرین جدید با موفقیت ایجاد شد';
END;
COMMIT;
END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_delete_practice
DELIMITER //
Create procedure college.usp_delete_practice(
in practiceid int,out outtext nvarchar(100),
out ERRORMESSAGE nvarchar(4000))
COMMENT 'for delete practice'
BEGIN

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
		GET DIAGNOSTICS CONDITION 1 @ERRNO = MYSQL_ERRNO, @MESSAGE_TEXT = MESSAGE_TEXT;
        set ERRORMESSAGE = (SELECT  CONCAT('MySQL ERROR: ', @ERRNO, ': ', @MESSAGE_TEXT) AS MESSAGE);
		set outtext=N'خظایی رخ داده است';
        ROLLBACK;
END; 

START TRANSACTION;
BEGIN
delete from practice
where practice.id=practiceid;
set outtext=N'تمرین با موفقیت حذف شد';
END;
COMMIT;
END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_insert_exam
DELIMITER //
Create procedure college.usp_insert_exam(in pcourseid int,in pexam_name nvarchar(500)
,in pstarttime datetime,in pendtime datetime,
in pexamlength time,in comment nvarchar(500),out outtext nvarchar(100),
out ERRORMESSAGE nvarchar(4000),out newid int)
COMMENT 'for insert exam'
BEGIN

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
		GET DIAGNOSTICS CONDITION 1 @ERRNO = MYSQL_ERRNO, @MESSAGE_TEXT = MESSAGE_TEXT;
        set ERRORMESSAGE = (SELECT  CONCAT('MySQL ERROR: ', @ERRNO, ': ', @MESSAGE_TEXT) AS MESSAGE);
		set newid = 0;
        set outtext=N'خظایی رخ داده است';
        ROLLBACK;
END; 

START TRANSACTION;
BEGIN
IF(comment = '')
	THEN
    BEGIN
    set comment=Null;
    END;
END IF;
insert into exam(courseid,exam_name,starttime,endtime,examlength,comment)
values(pcourseid,pexam_name,pstarttime,pendtime,pexamlength,comment);
set newid = LAST_INSERT_ID() ;
set outtext=N'امتحان جدید با موفقیت ایجاد شد';
END;
COMMIT;
END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_insert_examdetail
DELIMITER //
Create procedure college.usp_insert_examdetail(in newid int,
in pquestion nvarchar(500),in poption1 nvarchar(100),in poption2 nvarchar(100)
,in poption3 nvarchar(100),in poption4 nvarchar(100),in panswer int
,out outtext nvarchar(100),out ERRORMESSAGE nvarchar(4000))
COMMENT 'for insert examdetail'
BEGIN

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
		GET DIAGNOSTICS CONDITION 1 @ERRNO = MYSQL_ERRNO, @MESSAGE_TEXT = MESSAGE_TEXT;
        set ERRORMESSAGE = (SELECT  CONCAT('MySQL ERROR: ', @ERRNO, ': ', @MESSAGE_TEXT) AS MESSAGE);
        set outtext=N'خظایی رخ داده است';
        ROLLBACK;
END; 

START TRANSACTION;
BEGIN
insert into examdetail(examid,question,option1,option2,option3,option4,answer)
values(newid,pquestion,poption1,poption2,poption3,poption4,panswer);
set outtext=N'سوال به امتحان با موفقیت اضافه شد';
END;
COMMIT;

END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_reviewanswer
DELIMITER //
Create procedure college.usp_reviewanswer(in pid int,in kind int)
COMMENT 'for review practice and exam answers'
BEGIN

select * from (
select s.id studentid,c.teacherID,pa.practiceid peid,s.student_no,u.name_fa,c.course_name,
p.question,p.answer trueanswer,pa.answer studentanswer,pa.grade,1 as kind
,N'تمرین' as subject,current_timestamp() as starttime,p.deadline as endtime from 
student s left join
users u on u.id=s.userid left join
practiceanswer pa on pa.studentid=s.id left join
practice p on p.id=pa.practiceid left join
courses c on c.id=p.courseid
where c.id is not null
union all
select s.id studentid,c.teacherID,ed.examid peid,s.student_no,u.name_fa,c.course_name,
ed.question,ed.answer trueanswer,ea.studentanswer,ea.grade,2 as kind 
,N'امتحان' as subject, e.starttime,e.endtime from 
student s left join
users u on u.id=s.userid left join
examanswer ea on ea.studentid=s.id left join
examdetail ed on ed.id=ea.examdetailid left join
exam e on e.id=ed.examid left join
courses c on c.id=e.courseid
where c.id is not null)total
where total.kind=kind and total.peid=pid;

END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_deadlinepractice
DELIMITER //
Create procedure college.usp_deadlinepractice(in teacherid int)
COMMENT 'for select practice answer after deadline'
BEGIN
drop  temporary table if exists temp;
CREATE TEMPORARY TABLE temp(practiceanswerid int,
 teacherid int, course_name nvarchar(50),
 question nvarchar(500), trueanswer nvarchar(200),
 studentid int, studentname nvarchar(150), answer nvarchar(200));
insert into temp
select * from (select pa.id practiceanswerid,t.id as teacherid,
c.course_name,p.question,p.answer trueanswer,
pa.studentid,u.name_fa studentname,pa.answer from
teacher t left join
courses c on c.teacherID=t.id left join
practice p on p.courseid=c.id left join
practiceanswer pa on pa.practiceid=p.id left join
student s on s.id=pa.studentid left join
users u on u.id=s.userid
where p.deadline<current_timestamp() and pa.checked=0
)total
where total.teacherid = teacherid
order by question
LIMIT 1;

END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_correctionpractice
DELIMITER //
Create procedure college.usp_correctionpractice(in teacherid int,in pgrade float
,out outtext nvarchar(150),out ERRORMESSAGE nvarchar(4000),
out pcomment nvarchar(512))

COMMENT 'for update practice answer after deadline'
BEGIN

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
		GET DIAGNOSTICS CONDITION 1 @ERRNO = MYSQL_ERRNO, @MESSAGE_TEXT = MESSAGE_TEXT;
        set ERRORMESSAGE = (SELECT  CONCAT('MySQL ERROR: ', @ERRNO, ': ', @MESSAGE_TEXT) AS MESSAGE);
        set outtext=N'خظایی رخ داده است';
        ROLLBACK;
END; 

START TRANSACTION;
BEGIN
call usp_deadlinepractice(teacherid);
update practiceanswer set checked =1, grade= pgrade where id=(select practiceanswerid from temp LIMIT 1);
set pcomment = (select
concat(N'درس',' : ',course_name,N' سوال ',' : ',question,N' جواب درست : ',trueanswer,N' دانشجو : ',studentname,N' پاسخ دانشجو : ',answer) as comment
from temp);
drop  temporary table if exists temp;
set outtext=N'انجام شد';
END;
COMMIT;

END
//
DELIMITER ;
/**************************************/
Drop trigger if exists college.tr_CalculateExamGrade
DELIMITER //
Create trigger college.tr_CalculateExamGrade
before insert on examanswer for each row
BEGIN
set @examdetailid = New.examdetailid;
set @studentanswer = New.studentanswer;
set New.grade = 
(select (case when @studentanswer = ed.answer then 1 else 0 end) as grade from
examdetail ed 
where ed.id=@examdetailid);
set New.checked = 1;

END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_showexam_practice_perstudent
DELIMITER //
Create procedure college.usp_showexam_practice_perstudent(in puserid int,in pcourseid int,in pkind int)
COMMENT 'show all exam and practice per student'
BEGIN

select total.*,datediff(CURRENT_TIMESTAMP(),endtime) as remaintime from
 (select IFNULL(p.id,0) as id,t.id as teacherid,s.userid,c.id as courseid,u.name_fa as 'نام استاد',
c.course_name as 'نام درس',c.year as 'سال تحصیلی','تمرین' as 'موضوع',
IFNULL(p.question,N'تمرینی وجود ندارد') as 'عنوان',CURRENT_TIMESTAMP() as starttime,
IFNULL(p.deadline,CURRENT_TIMESTAMP()) as endtime,ifnull(pa.grade,0) as grade,
ifnull(pa.answer,N'پاسخ نداده اید') as answer, 1 as kind from 
student s left join
classrooms cr on cr.studentid= s.id left join
courses c on c.id=cr.courseid left join
teacher t on c.teacherID=t.id left join
practice p on p.courseid=c.id left join
practiceanswer pa on pa.practiceid= p.id left join
users u on u.id=t.userid
union all
select IFNULL(e.id,0) as id ,t.id as teacherid,s.userid,c.id as courseid,u.name_fa as 'نام استاد',
c.course_name as 'نام درس',c.year as 'سال تحصیلی','امتحان'  as 'موضوع',
IFNULL(e.exam_name,N'امتحانی وجود ندارد') as 'عنوان',IFNULL(e.starttime,CURRENT_TIMESTAMP())as starttime,
IFNULL(e.endtime,CURRENT_TIMESTAMP()) as endtime,ifnull(studentgrade.grade,0) as grade,
N'برای  دیدن جزییات شماره آزمون را وارد کنید' as answer, 2 as kind from 
student s left join
classrooms cr on cr.studentid= s.id left join
courses c on c.id=cr.courseid left join
teacher t on c.teacherID=t.id left join
exam e on e.courseid=c.id left join
(select ed.examid,ea.studentid,sum(ifnull(ea.grade,0)) as grade from
examanswer ea left join
examdetail ed on ed.id=ea.examdetailid 
group by ed.examid,ea.studentid
 )studentgrade on studentgrade.examid=e.id and studentgrade.studentid=s.id left join
users u on u.id=t.userid)total
where userid=puserid and courseid=pcourseid and kind = pkind;

END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_answerto_practice
DELIMITER //
Create procedure college.usp_answerto_practice(in ppracticeid int,in pstudentid int,
in pstudentanswer nvarchar(200),out outtext nvarchar(200),
out ERRORMESSAGE nvarchar(4000))
COMMENT 'for answer to each practice before deadline'

BEGIN

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
		GET DIAGNOSTICS CONDITION 1 @ERRNO = MYSQL_ERRNO, @MESSAGE_TEXT = MESSAGE_TEXT, @ESTATE = RETURNED_SQLSTATE;
        set ERRORMESSAGE = (SELECT  CONCAT('MySQL ERROR: ', @ERRNO, ': ', @MESSAGE_TEXT, @ESTATE) AS MESSAGE);
        set outtext=N'خظایی رخ داده است';
        ROLLBACK;
END; 

START TRANSACTION;
set @checkingupdate = (select id from practiceanswer p where p.practiceid=ppracticeid and studentid=pstudentid);
set @checkingdeadline = (select id from practice p where current_timestamp()<p.deadline and p.id=ppracticeid);

IF(@checkingdeadline is not null and @checkingupdate is not null)
	THEN
    BEGIN
    update practiceanswer set answer = pstudentanswer , accepttime = current_timestamp() where id=@checkingupdate;
    set outtext = N'پاسخ شما با موفقیت ویرایش شد';
    END;
ELSEIF(@checkingdeadline is not null and @checkingupdate is null)
	THEN
    BEGIN
    insert into practiceanswer(studentid,practiceid,answer) 
    values(pstudentid,ppracticeid,pstudentanswer);
    set outtext = N'پاسخ شما با موفقیت ارسال شد';
    END;
ELSE
	set outtext = N'متاسفانه مهلت پاسخ تمام شده است';
END IF;
COMMIT;

END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_review_examdetail_student
DELIMITER //
Create procedure college.usp_review_examdetail_student(
in pexamid int,in pstudentid int)
COMMENT 'for review of exam details and student answers'

BEGIN
set @checking =  (select id from exam e where e.endtime<current_timestamp() and e.id=pexamid);
IF(@checking is not null)
	THEN
    BEGIN
select row_number() over (partition by tot.examid order by tot.examdetailid) as rownumber
,tot.* from (
select 
totexam.examid,totexam.examdetailid,totexam.courseid,ifnull(totexam.studentid,pstudentid) as studentid,
totexam.exam_name,totexam.question,
totexam.option1,totexam.option2,totexam.option3,totexam.option4,
totexam.trueanswer,ifnull(studentanswer,'') as studentanswer,ifnull(grade,0) as grade  from 

(select s.id as studentid,ifnull(e.id,0) as examid,ifnull(ed.id,0) as examdetailid,cl.courseid,
ifnull(e.exam_name,N'بدون آزمون')exam_name,ifnull(ed.question,N'آزمون فاقد جزییات است') as question,
ed.option1,ed.option2,ed.option3,ed.option4,ed.answer trueanswer from 
student s left join
classrooms cl on cl.studentid=s.id left join
exam e on cl.courseid=e.courseid left join
examdetail ed on e.id=ed.examid
where e.id is not null)totexam left join 

(select ea.studentid,ea.grade,ea.examdetailid,e.id as examid,
ifnull(ea.studentanswer,N'') as studentanswer
 from examanswer ea left join
 examdetail ed on ed.id=ea.examdetailid left join
 exam e on e.id=ed.examid
 ) ea on ea.examid=totexam.examid 
 and ea.studentid=totexam.studentid and ea.examdetailid=totexam.examdetailid
 
where totexam.examid = pexamid)tot
where studentid=pstudentid;
	END;
ELSE
	select N'تنها پس از پایان آزمون قادر به دیدن نتایج هستید',1;
END IF;

END
//
DELIMITER ;
/**************************************/
Drop procedure if exists college.usp_load_exam_student
DELIMITER //
Create procedure college.usp_load_exam_student(in pexamid int,in pstudentid int)
COMMENT 'load exam for current student'

BEGIN
Drop temporary table if exists temp;
create temporary table temp(
examdetailid int,examid int,rownumber int,question nvarchar(500),option1 nvarchar(100)
,option2 nvarchar(100),option3 nvarchar(100),option4 nvarchar(100),quiztime int,
useminute int,remaintime int,totalquiz int,answerdquiz int ,remainquestion int);
insert into temp
(
select tot.examdetailid,tot.examid,tot.rownumber,tot.question
,tot.option1,tot.option2,tot.option3,tot.option4,tot.quiztime,
tot2.useminute,tot.quiztime-tot2.useminute as remaintime,
tot2.questionnumber as totalquiz,tot2.answernumber as answerdquiz,
tot2.questionnumber-tot2.answernumber as remainquestion from
(select 
ed.id examdetailid,examid,row_number() over() as rownumber, 
question, option1, option2, option3, option4 ,
tominute(e.examlength) as quiztime from
exam e left join
examdetail ed on e.id=ed.examid
where e.id=pexamid
LIMIT 1)tot left join

(select e.id as examid,count(ed.id) as questionnumber,
ifnull(remain.answernumber,0)answernumber,
ifnull(tominute(timediff(cast(eamax.accepttime as time) ,cast(eamin.accepttime as time))),0) as useminute
 from
exam e left join
examdetail ed on ed.examid=e.id left join

(select e.id,count(ea.id) answernumber 
from exam e left join
examdetail ed on e.id=ed.examid left join
examanswer ea on ea.examdetailid=ed.id
where ea.studentid=pstudentid and e.id = pexamid
group by e.id)remain on remain.id=e.id left join

(select e.id examid,min(ea.id) minid,max(ea.id) maxid 
from exam e left join
examdetail ed on e.id=ed.examid left join
examanswer ea on ea.examdetailid=ed.id
where ea.studentid=pstudentid and e.id = pexamid
group by e.id)init on init.examid=e.id left join
examanswer eamax on eamax.id=init.maxid left join
examanswer eamin on eamin.id=init.minid

where e.id=pexamid
group by e.id)tot2 on tot.examid=tot2.examid);

set @checking1 = (select max(ea.studentid) studentid from
				examanswer ea left join
				examdetail ed on ed.id=ea.examdetailid
				where ea.studentid= pstudentid and ed.examid = pexamid);
set @checking2 = (select ifnull(e.id,null) examid from exam e
				where current_timestamp() < e.starttime and e.id=pexamid);
set @checking3 = (select ifnull(e.id,null) examid from exam e
				where current_timestamp() > e.endtime and e.id=pexamid);
set @remaining = (select remaintime from temp);		 
IF(@checking2 is not null)
	THEN
    BEGIN
    select N'!آزمون هنوز شروع نشده است';
    END;
ELSEIF(@checking3 is not null)
	THEN
    BEGIN
    select N'!زمان شرکت در آزمون پایان یافته است';
    END;
ElSEIF(@remaining>0)
	THEN
    BEGIN
	select * from temp;
	END;
ELSEIF(@remaining<=0)
	THEN
    BEGIN
	select N'!متاسفانه زمان شما پایان یافت';
    END;
ELSE
	select N'!شما قبلا در این آزمون شرکت کرده اید';
END IF;

END
//
DELIMITER ;