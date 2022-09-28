Drop FUNCTION if exists college.ToMinute
DELIMITER //
CREATE FUNCTION ToMinute(atime time) RETURNS INTEGER
DETERMINISTIC
COMMENT 'for calculate time to minute' 
BEGIN
set @hourtime = convert(left(atime,2),unsigned integer)*60;
set @mintime = convert(right(left(atime,5),2), unsigned integer);
set @allmin = @hourtime + @mintime;

return @allmin;
END
//
DELIMITER ; 
/*********************************************************/
Drop FUNCTION if exists college.ToTime
DELIMITER //
CREATE FUNCTION ToTime(aint int) RETURNS TIME
DETERMINISTIC
COMMENT 'for calculate int to time' 
BEGIN
set @hourtime = (case
when length(FLOOR(aint/60))>=2 then convert(floor(aint/60),char)
when length(FLOOR(aint/60))=1 then concat('0',convert(floor(aint/60),char))
else '00' end );
set @mintime = (case 
when length(MOD(aint,60))=2 then convert(MOD(aint,60),char)
when length(MOD(aint,60))=1 then concat('0',convert(MOD(aint,60),char)) 
else '00' end); 
set @alltime = convert(concat(@hourtime,':',@mintime,':','00'),time);

return @alltime;
END
//
DELIMITER ; 
