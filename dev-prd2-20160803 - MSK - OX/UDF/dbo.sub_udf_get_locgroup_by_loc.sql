/*
���������� ������ ����� (�����) �� �� �����:
SD	�����������������
B	����
D	���
P	���������
K	�������
X	������������
E	��������������
*/
ALTER FUNCTION [dbo].[sub_udf_get_locgroup_by_loc](
	@loc varchar(10)
)
RETURNS varchar(5)
WITH RETURNS NULL ON NULL INPUT
AS
BEGIN
	
	if @loc in ('','EHOLOD01','EVOZVRAT01','TAMOGNIA','UNKNOWN','VOROTA1','VOROTA2') return NULL
	if @loc in ('BRAKPRIEM','PRIEM','PRIEM_EA','PRIEM_PL') return NULL
	
	-- LOCATIONTYPE = 'PND'
	if @loc in ('EA_IN','PL_IN') return NULL
	-- LOCATIONTYPE = 'PICKTO'
	if @loc in ('BAD_PICKTO','HOL_PICKTO','PICKTO','PL_KONTR','SD_PICKTO') return NULL
	-- LOCATIONHANDLING < '9'
	if @loc in ('IDZ','OVER','PTV','STAGE') return NULL
	-- LOCATIONFLAG = 'DAMAGE'
	if @loc in ('DAMAGE') return NULL
	-- LOCATIONFLAG = 'HOLD'
	if @loc in ('LOST','QC','RETURN') return NULL
	
	if @loc = 'BAD' return 'D'			-- ��� (����������)
	if left(@loc,2) = 'SD' return 'SD'	-- �����������������
	if left(@loc,1) = 'D' return 'D'	-- ���
	if left(@loc,1) = 'K' return 'K'	-- �������
	if left(@loc,1) = 'P' return 'P'	-- ���������
	if left(@loc,1) = 'X' return 'X'	-- �����������
	if left(@loc,1) = 'B' return 'B'	-- ����
	if left(@loc,1) = 'E' return 'E'	-- ��������������
	
	return NULL
END

