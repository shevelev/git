ALTER PROCEDURE [dbo].[UpdatingFREIGHTCLS]
AS      

						
--select s.SKU, s.descr, s.PUTAWAYZONE [Зона_Размещения_Карточка_Товара], dsg.putawayzone [Зона_Размещения_По_Класу_Товара],s.strategykey , dsg.strategykey, s.PUTAWAYSTRATEGYKEY ,dsg.PUTAWAYSTRATEGYKEY	

--from wh1.sku s
--join wh1.CODELKUP c on c.CODE = s.FreightClass and c.LISTNAME = 'FREIGHTCLS' 
--join wh1.strategyxsku dsg on c.SHORT = dsg.class
--where s.PUTAWAYZONE <> dsg.putawayzone

update s 
					set 
		
						s.STRATEGYKEY = dsg.strategykey,
						s.putawayzone = dsg.putawayzone,		
						s.PUTAWAYSTRATEGYKEY = dsg.PUTAWAYSTRATEGYKEY						
																													
					from	wh1.sku s 
							
							join wh1.CODELKUP c on c.CODE = s.FreightClass 	and c.LISTNAME = 'FREIGHTCLS'
							join wh1.strategyxsku dsg on dsg.class = c.SHORT
							
							where s.PUTAWAYZONE <> dsg.putawayzone



