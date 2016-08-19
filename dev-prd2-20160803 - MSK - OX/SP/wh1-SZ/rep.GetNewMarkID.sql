


ALTER PROCEDURE [rep].[GetNewMarkID] (@wh varchar(10)='dbo', @MarkName varchar(30), @count varchar(10)=1)
as
	declare @ID int,			-- ������� �������� ��������
			@prefix varchar(10),	-- ������� � �� ��������
			@newID varchar(10), -- ������� �������� �������� � ��������� ����
			@countC int, -- ���������� ��������
			@headin varchar (50), -- ����� ��������� ��������
			@t int, -- ��������������
			@const_maxLenOfID int -- ������������ ����� ID. ���������. ������ ����� 10
	create table #ArrayLabel (id varchar(127), header varchar(50))


	-- ������ ����� �������� � ID. �� ��������� ������ ���� 10
	set @const_maxLenOfID = 10
set @t=0;
	while (@count > 0 ) -- ���������� ��������
		begin
			select @countC = count_copy, @headin = head	from dbo.MarkersCounter where name like @MarkName -- ���������� ���������� ����� ������ ��������

			update dbo.MarkersCounter set @ID = counter, -- ������� �������� ��������
										@prefix = prefix, -- �������
										counter = counter+1 -- ���������� �� ������� ��������
				where (whseid like @wh)		-- ���� ���������� 
					and (name like @MarkName)	-- ��� ��������

			set @newID = cast(@ID as varchar(10)) -- �������������� �������� �������� �������� � ��������� ���

			declare @ln as int, -- ����� � �������� �������� �������� ��������
					@lp int	-- ����� �������� ��� �� ��������

			-- ���������� ����� �������� ����� ID � ��������
			select @ln = len(@newID), @lp = len(@prefix) 
			
			-- �������������� � 10���������� ���� � ������ ���� �������� � �������� ����� ID
			set @newID = @prefix+replicate ('0',@const_maxLenOfID-@ln-@lp)+@newID 

			while (@countC > 0) -- ���������� ����� ��������
				begin
					insert into #ArrayLabel (id, header) values (@newID,@headin)
					set @countC = @countC - 1;
				end
			set @count = @count - 1;
		end
		--select top 1 @outValue = ID from #ArrayLabel

select dbo.GetEAN128(id), header, id as numb from #ArrayLabel -- ����� ����������
drop table #ArrayLabel


