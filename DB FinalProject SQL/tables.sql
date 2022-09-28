create table Users(
id int  not null auto_increment primary key,
national_code nvarchar(10) not null unique,
name_fa nvarchar(100) not null,
name_en nvarchar(100) not null,
father_name nvarchar(100),
birth_date date,
mobile nvarchar(15) default null,
email nvarchar(100) default null,
pass nvarchar(500) default null
)
create index idx_users on users(id)
insert into Users(national_code, name_fa, name_en, father_name, birth_date) 
 values ('4953232312',N'امیرحسین سرهنگ','amirhosein-sarhang',N'مازیار','1355-01-10'),
		('5953232201',N'علی قربانی','ali-ghorbani',N'احمد','1365-09-13'),
		('6953232031',N'صادق علیزاده','Sadegh-alizadeh',N'حسین','1362-08-17'),
		('0253232331',N'کسری زاهدی','kasra-zahedi',N'علی','1375-08-10'),
		('1953232551',N'زهرا امیری','zahra-amiri',N'فرشید','1378-02-02'),
		('3953232601',N'مجید حسینی','majid-hoseini',N'هوشنگ','1377-04-03'),
		('6953232771',N'عمار براری','amar-barari',N'محمد','1376-12-20'),
		('5424328801',N'مریم زیبازاده','maryam-zibazadeh',N'نریمان','1380-01-29'),
		('2953694501',N'شهلا پریزاد','shahla-parizad',N'احمدعلی','1382-06-15')
/*************************************/
create table majorkind(
id int not null unique  primary key auto_increment,
code int not null unique,
check (length(code)=4),
title nvarchar(40) not null unique
)auto_increment=1000 
create index idx_majorkind on majorkind(id)
insert into majorkind(code,title) 
values(1000,N'مهندسی کامپیوتر'),
	  (1001,N'IT مهندسی'),
      (1002,N'مهندسی نرم افزار')
/*************************************/
create table Student(
id int not null auto_increment primary key,
userid int not null unique,
foreign key (userid) references Users(id),
student_no int not null unique,
check (length(student_no)=7),
majorid int not null,
foreign key(majorid) references majorkind(id)
)
create index idx_Student on Student(id,userid)
insert into student(userid,student_no,majorid)
values(4,4011254,1001),
	  (5,4013520,1000),
      (6,4012535,1001),
      (9,4012895,1002)
/*************************************/
create table teacherdepartment(
id int not null unique  primary key auto_increment,
code int not null unique,
check (length(code)=4),
title nvarchar(40) not null unique
)auto_increment=1000 
create index idx_teacherdepartment on teacherdepartment(id)
insert into teacherdepartment(code,title) 
values(1000,N'کامپیوتر'),
	  (1001,N'عمران')
/*************************************/
create table teacherlevel(
id int not null unique  primary key auto_increment,
code int not null unique,
check (length(code)=4),
title nvarchar(40) not null unique
)auto_increment=1000 
create index idx_teacherlevel on teacherlevel(id)
insert into teacherlevel(code,title) 
values(1000,N'استاد'),
	  (1001,N'استادیار'),
      (1002,N'دانش یار')
/************************************/
create table Teacher(
id int not null auto_increment primary key,
userid int not null unique,
foreign key (userid) references Users(id),
professor_no int not null unique,
check (length(professor_no)=5),
departmentID int not null,
foreign key(departmentID) references teacherdepartment(id),
teacherlevelID int not null,
foreign key(teacherlevelID) references teacherlevel(id)
)
create index idx_teacher on teacher(id,userid)
insert into Teacher(userid,professor_no,departmentID,teacherlevelID) 
values(1,25301,1000,1001),
	  (2,30050,1000,1002)
/*****************update emails and password*******************/
update users 
, (
select id,name_en,national_code
,coalesce(pass,MD5(concat(national_code,upper(left(name_en,1)),lower(substring(name_en,(locate('-',name_en)+1),1))))) as pass 
,ifnull(email,concat(left(name_en,1),'.',substring(name_en,locate('-',name_en)+1,length(name_en)),'@aut.ac.ir')) as email
from
users u)u 
set users.pass=u.pass , users.email=u.email
where u.id=users.id
/************************************/

create table Courses(
id int not null auto_increment primary key,
course_name nvarchar(50) not null,
teacherID int not null,
foreign key(teacherID) references teacher(id),
year int not null,
unique(course_name,teacherID,year)
)
create index idx_Courses on Courses(id,teacherID)
insert into Courses(course_name,teacherID,year)
values
(N'ریاضی۱',2,1401),
(N'پایگاه داده',1,1401),
(N'ساختمان داده',1,1401),
(N'آزمایشگاه پایگاه داده',1,1401)
/************************************/

create table Classrooms(
id int not null auto_increment primary key,
courseid int not null ,
foreign key(courseid) references Courses(id),
studentid int not null,
foreign key(studentid) references student(id),
unique(courseid,studentid)
)
create index idx_Classrooms on Classrooms(id,studentid,courseid)
insert into Classrooms(courseid,studentid) values
(1,4),(2,4),(3,4),(4,4),(1,2),(2,2),(1,3),(2,3),(3,3),(3,1)
/************************************/
create table exam(
id int not null primary key auto_increment,
courseid int not null unique,
foreign key(courseid) references courses(id),
exam_name nvarchar(50) not null,
starttime datetime not null,
endtime datetime not null,
examlength time not null,
comment nvarchar(200)
)
create index idx_exam on exam(id)
insert into exam(courseid,exam_name,starttime,endtime,examlength) values
(1,N'امتحان ریاضی 1',N'1401-04-10 14:00:00',N'1401-04-15 18:00:00','02:00:00'),
(2,N'امتحان پایگاه داده',N'1401-04-12 10:00:00',N'1401-04-16 12:00:00','01:30:00')
/************************************/
create table examdetail(
id int not null primary key auto_increment,
examid int not null,
foreign key(examid)references exam(id),
question nvarchar(500) not null,
option1 nvarchar(100) not null,
option2 nvarchar(100) not null,
option3 nvarchar(100) not null,
option4 nvarchar(100) not null,
answer int not null,
unique(examid,question)
)
create index idx_examdetail on examdetail(id,examid)
insert into examdetail(examid,question,option1,option2,option3,option4,answer)values
(1,N'کدام عدد ،عدد اول است؟',N'0',N'5',N'4',N'8',2),
(1,N'کدام عدد بر 3 بخش پذیر است؟',N'1',N'3',N'9',N'گزینه 2و3',4),
(1,N'بزرگترین عدد اول کدام است؟',N'13',N'15',N'17',N'18',3),
(1,N'جواب معادله چیست؟ x=x**2, x=6',N'25',N'35',N'36',N'42',3),
(1,N'500برابر یک عددی برابر خودش است آن عدد چند است؟',N'0',N'5',N'1',N'-1',0),
(2,N'کدام دستور برای نمایش داده ها استفاده میشود؟',N'select',N'insert',N'update',N'printer',1),
(2,N'کدام فرمت تاریخ در sqlاست؟',N'real',N'time',N'int',N'timestamp',4),
(2,N'دستور updateبرای چه منظوری درsql به کار میرود؟',N'تغییر داده موجود',N'حذف یک سطر',N'نمایش داده ها',N'ورود داده ها',1),
(2,N'کدام یک برای ساخت یک table استفاده میگردد؟',N'create',N'alter',N'auto_increment',N'move',1)
/************************************/
create table practice(
id int not null auto_increment primary key,
courseid int not null,
foreign key(courseid) references Courses(id),
question nvarchar(500) not null,
answer nvarchar(500) not null,
deadline datetime,
unique(courseid,question)
)
create index idx_practice on practice(id,courseid)
insert into practice(courseid,question,answer,deadline) values 
(2,N'مفهوم تراکنش را در پایگاه داده توضیح دهید؟',N'در پایگاه داده ها، تراکنش در واقع یک مجموعه ای از عملیات است که مانند یک واحد منطقی عمل میکنند','1401-04-15 12:00:00'),
(2,N'فرمت دستور فراخوانی داده از یک جدول با را مثال بزنید؟',N'select column_name from table_name','1401-04-15 12:00:00'),
(1,N'x=2,y=3, x*y**2?',N'18','1401-04-18 12:00:00'),
(1,N'log10?',N'1','1401-04-12 23:59:59')
/************************************/
create table examanswer(
id int not null auto_increment primary key,
studentid int not null,
foreign key(studentid) references student(id),
examdetailid int not null,
foreign key(examdetailid) references examdetail(id),
studentanswer nvarchar(10) default Null,
grade float default 0.0,
checked bool default 0,
accepttime datetime ,
unique(studentid ,examdetailid)
)
create index idx_examanswer on examanswer(id,studentid)
insert into examanswer(studentid,examdetailid,studentanswer)values
(2,1,1),(2,2,4),(2,3,4),(2,4,3),(2,7,4),(3,7,1),(3,8,1),(3,9,4)
/***************************************/
create table practiceanswer(
id int not null auto_increment primary key,
studentid int not null,
foreign key(studentid) references student(id),
practiceid int not null,
foreign key(practiceid) references practice(id),
answer nvarchar(500) default Null,
grade float default 0,
accepttime datetime default CURRENT_TIMESTAMP(),
checked bool default 0,
unique(studentid ,practiceid)
)
create index idx_practiceanswer on practiceanswer(id,studentid)
insert into practiceanswer(studentid,practiceid,answer)values
(2,1,N'به هر ورودی و خروجی از یک پایگاه داده یک تراکنش گویند'),(2,3,N'18'),(3,2,N'بلد نیستم استاد تروخدا نمره بده'),(3,4,N'1')
/***************************************/
create table logininfo(
id int not null auto_increment primary key,
userid int not null,
foreign key(userid) references users(id),
logindate datetime not null default CURRENT_TIMESTAMP(),
userstatus bool not null default 1,
unique(id)
)
create index idx_logininfo on logininfo(id,userid)