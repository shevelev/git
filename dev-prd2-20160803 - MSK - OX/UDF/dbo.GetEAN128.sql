-- =============================================
-- Author:		<Лапшин В.В.>
-- Create date: <май 2008>
-- Description:	<Функция возвращает последовательность символов для печати EAN128 шрифтом Code128bWin>
-- =============================================
ALTER FUNCTION [dbo].[GetEAN128]
(	@CodeEAN128 nvarchar(128)
)


RETURNS nvarchar(128)
AS
Begin
declare
	@Koi128 nvarchar(max), 
	@i integer, 
	@weightcf integer,
	@uncode varchar (max),
	@code integer,
	@asciicurchar integer, -- ascii код обрабатываемого символа
	@ser varchar(30), -- tmp
	@checksum integer
	


--                 |0  |1  |2  |3  |4  |5  |6  |7  |8  |9  |
	set @uncode = '0032003300340035003600370038003900400041'+ -- (1-40)
--                 |10 |11 |12 |13 |14 |15 |16 |17 |18 |19 |
                  '0042004300440045004600470048004900500051'+ -- (41-80)
--                 |20 |21 |22 |23 |24 |25 |26 |27 |28 |29 |
                  '0052005300540055005600570058005900600061'+ -- (81-120)
--                 |30 |31 |32 |33 |34 |35 |36 |37 |38 |39 |
                  '0062006300640065006600670068006900700071'+ -- (121-160)
--                 |40 |41 |42 |43 |44 |45 |46 |47 |48 |49 |
                  '0072007300740075007600770078007900800081'+ -- (161-200)
--                 |50 |51 |52 |53 |54 |55 |56 |57 |58 |59 |
                  '0082008300840085008600870088008900900091'+ -- (201-240)
--                 |60 |61 |62 |63 |64 |65 |66 |67 |68 |69 |
                  '0092009300940095009600970098009901000101'+ -- (241-280)
--                 |70 |71 |72 |73 |74 |75 |76 |77 |78 |79 |
                  '0102010301040105010601070108010901100111'+ -- (281-320)
--                 |80 |81 |82 |83 |84 |85 |86 |87 |88 |89 |
                  '0112011301140115011601170118011901200121'+ -- (321-360)
--                 |z  |{  ||  |}  |~  |DEL|FN3|FN2|Sht|CdC|
--                 |90 |91 |92 |93 |94 |95 |96 |97 |98 |99 |
                  '0122012301240125012682168217822082218226'+ -- (361-400)
--                 |FN4|CdA|FN1|StA|StB|StC|Stop
--                 |100|101|102|103|104|105|106|
                  '8211821207328482035382500339'              -- (401-440)

	set @i = 1         -- первый символ входной строки
	set @weightcf = 1     -- весовой коэффициент элемента
	set @checksum = 0 -- контрольная СУММА
	set @Koi128 = ''
	set @code = 0
	while ( @i <= len (@CodeEan128))
		begin
			if (len (@CodeEan128) - @i) > 0 -- проверка на наличие хотябы 2х необработанных символов
				begin -- >=2 сомвола
					if (isnumeric(substring(@CodeEan128,@i,2)) = 1) and (PATINDEX('%.%',substring(@CodeEan128,@i,2)) = 0 /*and substring(@CodeEan128,@i,2) != '00'*/) -- выбор кода на основании содержимого пары символов
						begin -- пара символов является двузначной цифрой
							if @code = 0  -- обрабатывается первый символ
								begin
									set @code = 105
									set @checksum = @checksum + @code -- выбираем режим С (cо стартовым кодом - 105)
									set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,@code*4+1,4) as  int))
								end
							if @code = 104 or @code = 100
								begin					
									set @code = 99	
									set @checksum = @checksum + @code * @weightcf -- выбираем режим С (cо стартовым кодом - 104)
									set @weightcf = @weightcf + 1
									set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,@code*4+1,4) as  int))
								end
							set @asciicurchar = cast(substring(@CodeEan128,@i,2) as int)
							set @checksum = @checksum + cast(((@asciicurchar)*@weightcf) as int)
							set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,(@asciicurchar)*4+1,4) as int))
							set @i = @i + 1
						end  
					else 
						begin  -- пара символов не является двузначной цифрой
							if @code = 0 
								begin
									set @code = 104 -- первый символ
									set @checksum = @checksum + @code -- выбираем режим B (cо стартовым кодом - 104)
									set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,@code*4+1,4) as  int))
								end
							if @code = 105 or @code = 99
								begin
									set @code = 100 -- не первый символ
									set @checksum = @checksum + @code * @weightcf -- выбираем режим B (cо стартовым кодом - 104)
									set @weightcf = @weightcf + 1
									set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,@code*4+1,4) as  int))
								end
							set @asciicurchar = ascii(substring(@CodeEan128,@i,1));
							set @checksum = @checksum + (@asciicurchar - 32)*@weightcf
							set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,(@asciicurchar-32)*4+1,4) as int))
--							set @i = @i + 1
--							set @weightcf = @weightcf + 1
--							set @asciicurchar = ascii(substring(@CodeEan128,@i,1));
--							set @checksum = @checksum + (@asciicurchar - 32)*@weightcf
--							set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,(@asciicurchar-32)*4+1,4) as int))
						end

				end
			else -- < 2 символов
				begin
					if @code = 0 
						begin
							set @code = 104
							set @checksum = @checksum + @code*@weightcf -- выбираем режим B (cо стартовым кодом - 104)
							set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,@code*4+1,4) as  int))	
							set @weightcf = @weightcf + 1
						end
					if @code = 105 or @code = 99 
						begin
							set @code = 100
							set @checksum = @checksum + @code*@weightcf -- выбираем режим B (cо стартовым кодом - 104)
							set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,@code*4+1,4) as  int))	
							set @weightcf = @weightcf + 1
						end
					set @asciicurchar = ascii(substring(@CodeEan128,@i,1))						
					set @checksum = @checksum + (@asciicurchar - 32)*@weightcf
					set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,(@asciicurchar-32)*4+1,4) as int))	
				end
			set @i = @i+1
			set @weightcf = @weightcf + 1
		end
	set	@checksum = @checksum - (floor(@checksum/103)*103)
	set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,@checksum*4+1,4) as  int)) -- контрольная сумма
	set @Koi128 = @Koi128 + nchar(cast(substring(@uncode,(106*4)+1,4) as int)) -- STOP (cо стартовым кодом - 106)
	RETURN (select @Koi128)
--return nchar(cast(substring(@uncode,(@ser)*4+1,4) as int))
End

--			if (@asciicurchar > 127) set @asciicurchar = 63 -- замен символа с кодом >127 на "?"
--			if (@asciicurchar < 32)  set @asciicurchar = 63 -- замен символа с кодом  <32 на "?"

