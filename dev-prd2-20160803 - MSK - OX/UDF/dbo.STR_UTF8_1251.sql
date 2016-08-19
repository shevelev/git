ALTER FUNCTION dbo.STR_UTF8_1251
(
	@s varchar(8000)
)
RETURNS VARCHAR(8000)
AS

BEGIN
    DECLARE @i int,
            @c int,
            @byte2 int,
            @c1 int,
            @new_c1 int,
            @new_i int,
            @new_c2 int,
            @out_i int
    DECLARE @out varchar(8000),
            @a int 
    SET @i = 1
    SET @byte2 = 0
    SET @out = ''
    WHILE (@i<=len(@s))
    BEGIN
        SET @c = ascii(SUBSTRING(@s,@i,1))
        
        IF (@c<=127 )
            SET @out = @out+SUBSTRING(@s,@i,1)
        
        IF (@byte2>0 )
        BEGIN
            SET @new_c2 = (@c1&3)*64+(@c&63)
            
            --Right shift @new_c1 2 bits
            		SET @new_c1 = CAST(@c1/2 AS INT)
            		SET @new_c1 = (CAST(@new_c1/2 AS INT))&5
            		SET @new_i = @new_c1*256+@new_c2
            		IF (@new_i=1025 )
            		    SET @out_i = 168
            		IF (@new_i=1105 )
            		    SET @out_i = 184
            		IF (@new_i<>1025 AND @new_i<>1105 )
            		    SET @out_i = @new_i-848
            		
            		SET @out = @out + char(@out_i)
            		SET @byte2 = 0
        END
        
        --Right shift @c 5 bits
        	     SET @a = CAST(@c/2 AS INT)
        	     SET @a = CAST(@a/2 AS INT)
        	     SET @a = CAST(@a/2 AS INT)
        	     SET @a = CAST(@a/2 AS INT)
        	     SET @a = CAST(@a/2 AS INT)
        	     
        	     IF (@a=6 )
        	     BEGIN
        	         SET @c1 = @c
        	         SET @byte2 = 1
        	     END
        	     SET @i = @i+1
    END
    RETURN @out
END

