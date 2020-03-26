-- Zapytanie pobiera informacje o rolach w bazie danych
--
-- Opisy są brane z Extended Properties, z pola oznaczonego jako MS_Description
--
-- Znaczenie zwracanych wartości:
--		RoleName - nazwa roli
--		Description - opis jako pole MS_Description z Extended Properties
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select [sdp].[name] as [RoleName], [sep].[value] as [Description]
from [sys].[database_principals] as [sdp]
left join [sys].[extended_properties] [sep] on [sdp].[principal_id] = [sep].[major_id] and [sep].[minor_id] = 0 and
											   [sep].[class_desc] = 'DATABASE_PRINCIPAL' and
											   [sep].[name] = 'MS_Description'
where [sdp].[type_desc] = 'DATABASE_ROLE'
  and [sdp].[is_fixed_role] = 0
  and [sdp].[principal_id] != 0
