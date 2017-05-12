/*Серега нужно создать отчет по инвентарке, обозвать его prd2_сверка_остатков.

Проверять он будет суммарно без учета ячеек в следующем ключе:
Склад-товар-серия-сроки годности.

Из инфора будем брать из таблицы wh1.physical 
Из аксапты будем брать временно из таблицы: [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventSumFromWMS

И еще отчет: Расхождение по ячейкам, нужно сделать без 
учета lot в запросах, 
брать товар+серия+сроки годности, так как при самой 
инвентаризации lot записываться нигде не будет.*/

ALTER PROCEDURE [rep].[DifferenceBtwnInforAndAxapta]
AS
--Выборка из Аксапты
SELECT	itemid SKU, 
		InventSerialID lottable02, 
		ManufactureDate lottable04,
		ExpireDate lottable05,
		InventQtyOnHandWMS qty,
		inventlocationID sklad
into #AxaptaTable
FROM [SPB-SQL1210DBE\MSSQLDBE].[DAX2009_1].[dbo].SZ_ImpInventSumFromWMSPrev;				

--Выборка из Инфора			

select LOC,SKU, SUSR1,SUSR4,SUSR5, max(inventorytag) mig
into #test
from wh1.physical 
group by LOC, SKU, SUSR1,SUSR4,SUSR5;


select	test.SKU,
		test.SUSR1,
		test.SUSR4,
		test.SUSR5,
		phys.qty,
		w.sklad
into #InforTable
from #test test JOIN WH1.physical phys
			ON  test.LOC = phys.LOC
			AND	test.SKU = phys.SKU
			AND test.SUSR1 = phys.SUSR1
			AND test.SUSR4 = phys.SUSR4
			AND test.SUSR5 = phys.SUSR5
			AND test.mig = phys.inventorytag
				JOIN wh1.loc loc ON test.loc = loc.loc
				JOIN dbo.WHTOZONE w ON w.zone = loc.PUTAWAYZONE

--Отличие в остатках
Select  infor.SKU,
		infor.SUSR1,
		infor.SUSR4,
		infor.SUSR5, 
		infor.sklad, 
		infor.qty - axapta.qty diff
		
FROM #AxaptaTable axapta JOIN #InforTable infor
		ON	axapta.SKU = infor.SKU
		AND axapta.lottable02 = infor.SUSR1
		AND axapta.lottable04 = infor.SUSR4
		AND axapta.lottable05 = infor.SUSR5
		AND axapta.sklad = infor.sklad
WHERE infor.qty - axapta.qty != 0;
			
DROP TABLE #AxaptaTable;
DROP TABLE #test;		
DROP TABLE #InforTable;

					







