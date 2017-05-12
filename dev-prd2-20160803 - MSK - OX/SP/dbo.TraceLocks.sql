ALTER PROCEDURE [dbo].[TraceLocks]
	@i_s_db varchar(50) = 'PRD1',
	@i_n_rsc_type INTEGER = NULL
as
	
	declare
		@i as integer
	
	set @i = 1
	
	create table #rcs_types (
		rsc_type INTEGER primary key
	)
	
	if @i_n_rsc_type is NULL
	    while @i <= 10
	    begin
	    	insert into #rcs_types (
	    		rsc_type
	    	)
	    	values (
	    		@i
	    	)
	    	set @i = @i + 1
	    end
	else
		insert into #rcs_types (
			rsc_type
		)
		values (
			@i_n_rsc_type
		)
	
	select
		case req_mode when 0
				then 'NULL'when 1
				then 'Sch-S'when 2
				then 'Sch-M'when 3
				then 'S'when 4
				then 'U'when 5
				then 'X'when 6
				then 'IS'when 7
				then 'IU'when 8
				then 'IX'when 9
				then 'SIU'when 10
				then 'SIX'when 11
				then 'UIX'when 12
				then 'BU'when 13
				then 'RangeS_S'when 14
				then 'RangeS_U'when 15
				then 'RangeI_N'when 16
				then 'RangeI_S'when 17
				then 'RangeI_U'when 18
				then 'RangeI_X'when 19
				then 'RangeX_S'when 20
				then 'RangeX_U'when 21
				then 'RangeX_X'
			end req_mode,
		case rsc_type when 1
				then 'NULL'when 2
				then 'DATABASE'when 3
				then 'FILE'when 4
				then 'INDEX'when 5
				then 'TABLE'when 6
				then 'PAGE'when 7
				then 'KEY'when 8
				then 'EXTENT'when 9
				then 'RID'when 10
				then 'APPLICATION'
			end rsc_type,
		p.hostname,
		p.program_name,
		p.cmd,
		o.name,
		o.id,
		o.xtype,
		o.uid,
		p.hostprocess,
		p.loginame,
		rsc_flag,
		case req_status when 1
				then 'GRANTED'when 2
				then 'CONVERTING'when 3
				then 'WAITING'
			end req_status,
		req_refcnt,
		req_lifetime,
		req_spid,
		req_ecid,
		case req_ownertype when 1
				then 'TRANSACTION'when 2
				then 'CURSOR'when 3
				then 'SESSION'when 4
				then 'EXSESSION'
			end req_ownertype,
		req_transactionID,
		p.blocked,
		p.waittype,
		p.waittime,
		p.lastwaittype,
		p.waitresource,
		p.status,
		p.open_tran,
		b.hostname by_hostname,
		b.program_name by_program_name,
		b.cmd by_cmd,
		b.hostprocess by_hostprocess,
		b.loginame by_loginame
	from master.dbo.syslockinfo l,
		dbo.sysobjects o,
		master.dbo.sysprocesses p
		left join master.dbo.sysprocesses b on b.spid = p.blocked
	where l.rsc_dbid = (
	      	select
	      		dbid
	      	from master.dbo.sysdatabases
	      	where name = @i_s_db
	      )
		and o.id = l.rsc_objid
		and p.spid = l.req_spid
		and l.rsc_type in (select
		                   	t.rsc_type
		                   from #rcs_types t)

