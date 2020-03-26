-- Zapytanie pobiera informacje o tabelach i widokach użytkownika
--
-- Opisy są brane z Extended Properties, z pola oznaczonego jako MS_Description
--
-- Znaczenie zwracanych wartości:
-- 		Name - nazwa tabeli/widoku
--		object_id - identyfikator obiektu tabeli/widoku
--		Schema - schemat tabeli/widoku
--		Type - typ obiektu USER_TABLE lub VIEW)
--		Description - opis jako pole MS_Description z Extended Properties
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select [st].[name] as [Name],
	   [st].[object_id],
	   [sch].[name] as [Schema],
	   [st].[type_desc] as [Type],
	   [sep].[value] as [Description]
from [sys].[all_objects] as [st]
inner join [sys].[schemas] as [sch] on [st].[schema_id] = [sch].[schema_id]
left join [sys].[extended_properties] [sep] on [st].[object_id] = [sep].[major_id] and [sep].[minor_id] = 0 and
											   [sep].[class_desc] = 'OBJECT_OR_COLUMN' and
											   [sep].[name] = 'MS_Description'
where [st].[type] in ('U', 'V')
  and [sch].[name] not in ('sys', 'INFORMATION_SCHEMA')
