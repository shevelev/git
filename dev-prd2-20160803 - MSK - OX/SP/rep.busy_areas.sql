
ALTER PROCEDURE [rep].[busy_areas]
(
	@loctype VARCHAR(10) = NULL--'pick';--'case'
) 
AS	
SELECT -- какой объём можно хранить по зонам
	loc.PUTAWAYZONE, 
	pz.DESCR,
	SUM(loc.CUBICCAPACITY) Volume
INTO #VolumeZone
FROM 
	WH1.LOC loc INNER JOIN
	WH1.PUTAWAYZONE pz ON loc.PUTAWAYZONE = pz.PUTAWAYZONE 
WHERE loc.CUBICCAPACITY != 0
GROUP BY loc.PUTAWAYZONE,pz.DESCR

SELECT --занятый объём по зонам
	SUM(sl.qty * tov.STDCUBE) busyVolumeCell,
	loc.PUTAWAYZONE
INTO #BusyVolumeZone
FROM 
	WH1.SKUXLOC sl INNER JOIN
	WH1.SKU tov ON sl.SKU = tov.SKU INNER JOIN
	WH1.LOC loc ON sl.loc = loc.loc 
	 
WHERE sl.LOCATIONTYPE like @loctype
GROUP BY loc.PUTAWAYZONE



SELECT v.PUTAWAYZONE, v.DESCR, ROUND(ISNULL(b.busyVolumeCell / v.Volume * 100,0),2) BusyPerPercent
FROM #VolumeZone v LEFT JOIN #BusyVolumeZone b
	ON v.PUTAWAYZONE = b.PUTAWAYZONE
ORDER BY BusyPerPercent DESC

DROP TABLE #VolumeZone
DROP TABLE #BusyVolumeZone










