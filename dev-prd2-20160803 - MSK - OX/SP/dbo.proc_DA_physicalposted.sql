
ALTER PROCEDURE [dbo].[proc_DA_physicalposted] (

	@wh varchar(10),
	@transmitlogkey varchar (10)
	)
as
--3    __Сильнодействующие
--1    1 Склад
--22    Забраковка
--30    Некондиция
--35    Потери
--4    Сертификация


declare @currentdate datetime

set @currentdate = GETDATE() -- текущая дата

declare @bs varchar(3) select @bs = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bs'
declare @bsanalit varchar(3) select @bsanalit = short from wh1.CODELKUP where LISTNAME='sysvar' and CODE = 'bsanalit'

select 
	'INVENTORY' filetype,
	@currentdate [date],
	--inventoryid,
	lli.STORERKEY,
	case when la.LOTTABLE03 != 'OK'
		then '4'--сертификат
		else 
			case when la.LOTTABLE07 != 'OK'
				then '30' --брак
				else
					case when la.LOTTABLE08 != 'OK'
						then '22'--фсн
						else 
							case when lli.LOC = 'LOST'
								then '35' --потери
								else
									case when lli.LOC = 'SD01' OR lli.LOC = 'SD02' 
										then '3' --сильнодействующие
										else '1' --основной
										end
								end
						end
				end
		end sklad,
	lli.SKU,
	la.LOTTABLE01 packkey, 
	case when la.LOTTABLE02 = '' then @bsanalit else la.LOTTABLE02 end LOTTABLE02,
	--la.LOTTABLE03,	
	la.LOTTABLE04,
	la.LOTTABLE05,
	--la.LOTTABLE07,
	--la.LOTTABLE08,	
	sum(lli.qty) factqty
	--deltaqty
from wh1.lotxlocxid lli join wh1.lotattribute la
	
on lli.LOT = la.lot
where QTY > 0
group by 	

	--inventoryid,
	lli.STORERKEY,
	--sklad
	lli.SKU,
	la.LOTTABLE01, 
	case when la.LOTTABLE02 = '' then @bsanalit else la.LOTTABLE02 end,
	--la.LOTTABLE03,
	la.LOTTABLE04,
	la.LOTTABLE05,
	case when la.LOTTABLE03 != 'OK'
		then '4'--сертификат
		else 
			case when la.LOTTABLE07 != 'OK'
				then '30' --брак
				else
					case when la.LOTTABLE08 != 'OK'
						then '22'--фсн
						else 
							case when lli.LOC = 'LOST'
								then '35' --потери
								else
									case when lli.LOC = 'SD01' OR lli.LOC = 'SD02' 
										then '3' --сильнодействующие
										else '1' --основной
										end
								end
						end
				end
		end
	
	--la.LOTTABLE07,
	--la.LOTTABLE08

