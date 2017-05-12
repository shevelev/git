-- =============================================
-- Author:		����� �����
-- Create date: 26.04.2008
-- Description:	��� ������ ����� ������ ������ �����������, ������� ������������
-- ��� ������ ������� ������ ������ ����������� �� ��������� ���� � ��������� ���� ������ ��������
-- =============================================
ALTER PROCEDURE [dbo].[rep_ZTimeStartedWorkForEmployee]
	@wh VarChar(30)
  , @startDate VarChar(10)
AS
BEGIN
    set @wh = upper(@wh)
	declare @sql varchar(max)
	set @sql = 'SELECT usr_name, start, TRANTYPE
                  FROM (SELECT usr_name, CONVERT(varchar(5),start,108) as start,
                               CASE	WHEN TRANTYPE = ''WD'' AND SOURCETYPE = ''ntrPickDetailUpdate'' THEN '''' 
	                                WHEN TRANTYPE = ''AJ'' THEN ''�������������'' 
	                                WHEN TRANTYPE = ''MV'' AND SOURCETYPE = '''' THEN ''�����������'' 
	                                WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''nspRFTRP01'' THEN ''����������'' 
	                                WHEN TRANTYPE = ''MV'' AND SOURCETYPE = ''PICKING'' THEN ''�����'' 
	                                WHEN TRANTYPE = ''DP'' THEN ''�������'' 
	                                WHEN TRANTYPE = ''MV'' THEN ''�����������'' 
	                                     END AS TRANTYPE
                          FROM (SELECT ssaadmin.pl_usr.usr_name
                                     , '+@wh+'.ITRN.EDITWHO, MIN('+@wh+'.ITRN.EDITDATE) AS start
                                  FROM '+@wh+'.ITRN WITH (NOLOCK)
                                       LEFT OUTER JOIN
                                       ssaadmin.pl_usr ON '+@wh+'.ITRN.EDITWHO = ssaadmin.pl_usr.usr_login
                                  WHERE (CONVERT(varchar(10),'+@wh+'.ITRN.EDITDATE, 104) 
                                         = CONVERT(varchar(10), '''+@startdate+''', 104))
                                  GROUP BY ssaadmin.pl_usr.usr_name, '+@wh+'.ITRN.EDITWHO
                               ) stat
                                LEFT JOIN '+@wh+'.ITRN WITH (NOLOCK) 
                                ON '+@wh+'.ITRN.EDITDATE = stat.start AND '+@wh+'.ITRN.EDITWHO = stat.EDITWHO 
                       ) stats
                  GROUP BY usr_name, start, TRANTYPE
                  ORDER BY  start'
    exec (@sql)	
END

