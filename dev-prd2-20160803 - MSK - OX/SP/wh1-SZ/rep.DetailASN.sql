ALTER PROCEDURE [rep].[DetailASN] (
	@wh varchar(30),
	@receiptkey varchar(10), 
	@showHist int
)

as
/**** For testing (must be commented in work code)****/
--declare @WH varchar(30),
--		@receiptkey varchar(10), 
--		@showHist int
--select @receiptkey = '0000010396', @showHist = 0, @WH='WH40'
/**** end For testing ****/
	set @wh = upper(@wh)
	set @receiptkey= replace(upper(@receiptkey),';','')  -- удалить ; из строк задаваемых пользователем для увеличения безопасности.
	

	declare @PlaceVol decimal(10,3)
	set @placeVol = 1.6*0.8*1.2
	
	select st.company client, sku.sku, sku.descr,
		rd.receiptkey, rd.receiptlinenumber, rd.externlineno,
		case UOM 
			when 'EA' then qtyexpected+qtyadjusted
			when 'CS' then (qtyexpected+qtyadjusted)/case p.casecnt when 0 then 1 else p.casecnt end
			when 'PL' then (qtyexpected+qtyadjusted)/case p.pallet when 0 then 1 else p.pallet end
		end qtyWaiting, 
		case UOM 
			when 'EA' then qtyreceived
			when 'CS' then qtyreceived/case p.casecnt when 0 then 1 else p.casecnt end
			when 'PL' then qtyreceived/case p.pallet when 0 then 1 else p.pallet end
		end qtyreceived, 
		case UOM 
			when 'EA' then 'Штук'
			when 'CS' then 'ящиков'
			when 'PL' then 'паллет'
		end Measure, rd.adddate, 
		isnull(usr.usr_name,'Exceed') AddUser,
		rd.editdate,
		rd.toloc,
		isnull(usr1.usr_name,'Exceed') ChangeUser,
		sku.stdcube*(qtyExpected+QTYRECEIVED) Volume,
		sku.STDGROSSWGT*(qtyExpected+QTYRECEIVED) expbrutwgt,
		ceiling((sku.stdcube*(qtyExpected+QTYRECEIVED))/cast(@placeVol as varchar)) PalletPlaceAvg,
		ceiling((qtyExpected+QTYRECEIVED)/case p.pallet when 0 then 1 else p.pallet end)  PalletPlaceRFPack,
		case  when isnull(p.pallet,0)=0 or isnull(p.casecnt,0)=0 then 1 else 0 end ErrInPack,
		cast(@showHist as varchar) showHist
	from WH1.receiptdetail rd
		join WH1.sku sku on sku.storerkey=rd.storerkey and sku.sku=rd.sku
		join WH1.storer st on rd.storerkey=st.storerkey
		join WH1.pack p on p.packkey=rd.packkey
		left join ssaadmin.pl_usr usr on usr.usr_login = rd.addwho
		left join ssaadmin.pl_usr usr1 on usr1.usr_login = rd.editwho
	where rd.receiptkey=cast(@receiptkey as varchar)  order by 5
	--print @sql
	


--select * from ssaadmin.pl_usr

