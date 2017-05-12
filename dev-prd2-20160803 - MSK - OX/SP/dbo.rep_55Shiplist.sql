/****** Object:  StoredProcedure [dbo].[rep_55Shiplist]    Script Date: 03/24/2011 15:14:50 ******/
ALTER PROCEDURE [dbo].[rep_55Shiplist] (
	@wh varchar(10),
	@key varchar(12),
	@IsWave int -- 0 - заказ, 1-волна
)
AS
