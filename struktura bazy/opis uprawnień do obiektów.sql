-- Zapytanie pobiera informacje o uprawnieniach do obiektów.
--
-- Znaczenie zwracanych wartości:
--		Module - nazwa obiektu
--		ModuleType - typ obiektu
--		ModuleSchema - schemat obiektu
--		ModuleId - identyfikator obiektu
--		Role - rola posiadająca przypisane uprawnienie do obiektu
--		Permission - rodzaj uprawnienia
--		PermissionState - stan uprawnienia
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select distinct
	   [m].[name] as [Module],
	   [m].[type_desc] as [ModuleType],
	   [msch].[name] as [ModuleSchema],
	   [m].[object_id] as [ModuleId],
	   [dp].[name] as [Role],
	   [sdp].[permission_name] as [Permission],
	   [sdp].[state_desc] as [PermissionState]
from [sys].[all_objects] as [m]
inner join [sys].[schemas] as [msch] on [msch].[schema_id] = [m].[schema_id]
inner join [sys].[database_permissions] as [sdp] on [sdp].[major_id] = [m].[object_id]
inner join [sys].[database_principals] as [dp] on [sdp].[grantee_principal_id] = [dp].[principal_id]
where [m].[type] in ('IF', 'FN', 'TF', 'AF', 'P', 'U', 'V', 'TG')
  and [msch].[name] not in ('sys', 'INFORMATION_SCHEMA')
