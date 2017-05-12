--exec dbo.sendmail
ALTER PROCEDURE [dbo].[SendMail] (@recip varchar(max), @subj varchar(255), @message varchar(max))
as
begin

/* -- for DEBUG only
	insert into dbo._MailSent values (@recip,@subj,@message,getdate())
	return
--*/

	exec msdb.dbo.sp_send_dbmail  
			@profile_name =  'rbt-infor' ,
			@recipients = @recip,
			@subject = @subj,
			@body = @message
end

