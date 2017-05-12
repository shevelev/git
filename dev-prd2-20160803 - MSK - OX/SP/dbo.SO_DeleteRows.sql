ALTER PROCEDURE [dbo].[SO_DeleteRows]
AS     


	declare @n bigint 
	declare @n2 bigint 
	declare @id int
	declare @id2 int

		select top 1 @id = id from	[wh1].SZ_ImpOutputOrderlinespic where status=5
		
		select	@n = isnull(max(cast(cast(recid as numeric) as bigint)),0)
			from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrderlinespic	
		
		
		insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrderLinesPic --	анебни
		--insert into [SPB-DAXDEV].[DAX2009_1].[dbo].SZ_ImpOutputOrderlinespic -- реярнбши
				(dataareaid,docid,salesidbase,itemid,salesqty,orderedqty,inventlocationid,inventbatchid,
				inventserialid,inventexpiredate,inventserialproddate,
				status,recid)
		        		
		select	 dataareaid,docid,salesidbase,itemid,salesqty,orderedqty,inventlocationid,inventbatchid,
				inventserialid,inventexpiredate,inventserialproddate,
				status ,@n+1 as recid
				from	[wh1].SZ_ImpOutputOrderlinespic where id=@id
		update	[wh1].SZ_ImpOutputOrderlinespic	set status=10	where id=@id


		select top 1 @id2 = id from	[wh1].SZ_ImpOutputOrderlineShip	 where status=5
		
		select	@n2 = isnull(max(cast(cast(recid as numeric) as bigint)),0)
			from	[SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrderlineShip
			
		insert into [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpOutputOrderlineShip  --	анебни
		--insert into [SPB-DAXDEV].[DAX2009_1].[dbo].SZ_ImpOutputOrderlineShip -- реярнбши
				(dataareaid,docid,salesidbase,itemid,salesqty,lineqty,orderedqty,inventlocationid,inventbatchid,
				inventserialid,inventexpiredate,inventserialproddate,
				status,recid)
    		
		select	dataareaid,docid,salesidbase,itemid,salesqty,lineqty,orderedqty,inventlocationid,inventbatchid,
				inventserialid,inventexpiredate,inventserialproddate,
				status, @n2+1 as recid
		from	[wh1].SZ_ImpOutputOrderlineShip where id=@id
		update	[wh1].SZ_ImpOutputOrderlineShip	 set status=10	where id=@id2
