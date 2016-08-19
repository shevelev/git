ALTER FUNCTION STR_1251_UTF8(@s varchar(8000))
RETURNS VARCHAR(8000)
AS
BEGIN
	DECLARE
		@c int			,
		@t varchar(8000)	
	SELECT @t = ''
	WHILE LEN(@s) > 0
	BEGIN
		SELECT @c = ASCII(SUBSTRING(@s,1,1))
		IF (@c >= 0x80 AND @c <= 0xFF)
		BEGIN
			IF (@c >= 0xF0)
			BEGIN
				SELECT @t = @t + char(0xD1) + char(@c-0x70)
			END
			ELSE
			IF (@c >= 0xC0)
			BEGIN
				SELECT @t = @t + char(0xD0) + char(@c-0x30)
			END
			ELSE
			BEGIN
				IF (@c = 0xA8) SELECT @t = @t + char(0xD0) + char(0x81) -- Ё
				ELSE
				IF (@c = 0xB8) SELECT @t = @t + char(0xD1) + char(0x91) -- ё
				ELSE
				-- украинские символы
				IF (@c = 0xA1) SELECT @t = @t + char(0xD0) + char(0x8E) -- Ў (У)
				ELSE
				IF (@c = 0xA2) SELECT @t = @t + char(0xD1) + char(0x9E) -- ў (у)
				ELSE 
				IF (@c = 0xAA) SELECT @t = @t + char(0xD0) + char(0x84) -- // Є (Э)
				ELSE 
				IF (@c = 0xAF) SELECT @t = @t + char(0xD0) + char(0x87) -- // Ї (I..)
				ELSE 
				IF (@c = 0xB2) SELECT @t = @t + char(0xD0) + char(0x86) -- // I (I)
				ELSE 
				IF (@c = 0xB3) SELECT @t = @t + char(0xD1) + char(0x96) -- // i (i)
				ELSE 
				IF (@c = 0xBA) SELECT @t = @t + char(0xD1) + char(0x94) -- // є (э)
				ELSE 
				IF (@c = 0xBF) SELECT @t = @t + char(0xD1) + char(0x97) -- // ї (i..)
				ELSE 
				-- чувашские символы
				IF (@c = 0x8C) SELECT @t = @t + char(0xD3) + char(0x90) -- // &#1232; (A)
				ELSE 
				IF (@c = 0x8D) SELECT @t = @t + char(0xD3) + char(0x96) -- // &#1238; (E)
				ELSE 
				IF (@c = 0x8E) SELECT @t = @t + char(0xD2) + char(0xAA) -- // &#1194; (С)
				ELSE 
				IF (@c = 0x8F) SELECT @t = @t + char(0xD3) + char(0xB2) -- // &#1266; (У)
				ELSE 
				IF (@c = 0x9C) SELECT @t = @t + char(0xD3) + char(0x91) -- // &#1233; (а)
				ELSE 
				IF (@c = 0x9D) SELECT @t = @t + char(0xD3) + char(0x97) -- // &#1239; (е)
				ELSE 
				IF (@c = 0x9E) SELECT @t = @t + char(0xD2) + char(0xAB) -- // &#1195; (с)
				ELSE 
				IF (@c = 0x9F) SELECT @t = @t + char(0xD3) + char(0xB3) -- // &#1267; (у)
				ELSE 
				-- chars
				IF (@c = 0xB9) SELECT @t = @t + char(0xE2) + char(0x84) + char(0x96) -- // № (No)				ELSE
				ELSE					
				SELECT @t = @t + '?'
			END
  END
  ELSE
   SELECT @t = @t + CHAR(@c)
  
  SELECT @s = SUBSTRING(@s,2,LEN(@s)-1)
 END
 RETURN @t
 END

