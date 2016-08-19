/*************************************************************************/
/*                  NumPhrase function for MSSQL2000                     */
/*                   Gleb Oufimtsev (dnkvpb@nm.ru)                       */
/*                       http://www.gvu.newmail.ru                       */
/*                          Moscow  Russia  2001                         */
/*************************************************************************/
ALTER FUNCTION [dbo].[NumPhrase] (@Num BIGINT, @IsMaleGender bit=1)
returns varchar(255)
as
begin
  declare @nword varchar(255), @th tinyint, @gr smallint, @d3 tinyint, @d2
tinyint, @d1 tinyint
  if @Num<0 return '*** Error: Negative value' else if @Num=0 return '����'
/* ������ ������ */
  while @Num>0
  begin
    set @th=IsNull(@th,0)+1    set @gr=@Num%1000    set @Num=(@Num-@gr)/1000
    if @gr>0
    begin
      set @d3=(@gr-@gr%100)/100
      set @d1=@gr%10
      set @d2=(@gr-@d3*100-@d1)/10
      if @d2=1 set @d1=10+@d1
      set @nword=case @d3
                  when 1 then ' ���' when 2 then ' ������' when 3 then '
������'
                  when 4 then ' ���������' when 5 then ' �������' when 6
then ' ��������'
                  when 7 then ' �������' when 8 then ' ���������' when 9
then ' ���������' else '' end
                +case @d2
                  when 2 then ' ��������' when 3 then ' ��������' when 4
then ' �����'
                  when 5 then ' ���������' when 6 then ' ����������' when 7
then ' ���������'
                  when 8 then ' �����������' when 9 then ' ���������' else
'' end
                +case @d1
                  when 1 then (case when @th=2 or (@th=1 and
@IsMaleGender=0) then ' ����' else ' ����' end)
                  when 2 then (case when @th=2 or (@th=1 and
@IsMaleGender=0) then ' ���' else ' ���' end)
                  when 3 then ' ���' when 4 then ' ������' when 5 then '
����'
                  when 6 then ' �����' when 7 then ' ����' when 8 then '
������'
                  when 9 then ' ������' when 10 then ' ������' when 11 then
' �����������'
                  when 12 then ' ����������' when 13 then ' ����������' when
14 then ' ������������'
                  when 15 then ' ����������' when 16 then ' �����������'
when 17 then ' ����������'
                  when 18 then ' ������������' when 19 then ' ������������'
else '' end
                +case @th
                  when 2 then ' �����'     +(case when @d1=1 then '�' when
@d1 in (2,3,4) then '�' else ''   end)
                  when 3 then ' �������' when 4 then ' ��������' when 5 then
' ��������' when 6 then ' ����������' when 7 then ' ����������'
                  else '' end
                +case when @th in (3,4,5,6,7) then (case when @d1=1 then ''
when @d1 in (2,3,4) then '�' else '��' end) else '' end
                +IsNull(@nword,'')
    end
  end
  return upper(substring(@nword,2,1))+substring(@nword,3,len(@nword)-2)
end

