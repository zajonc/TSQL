-- Zapytanie pobiera informacje o argumentach funkcji i procedur składowanych użytkownika
--
-- Opisy są brane z Extended Properties, z pola oznaczonego jako MS_Description
--
-- Znaczenie zwracanych wartości:
--		Module - nazwa funkcji/procedury
--		ModuleId - identyfikator obiektu funkcji/procedury
--		Schema - schemat funkcji/procedury
--		Name - nazwa argumentu
--		Type - typ argumentu wraz z rozmiarem
--		ArgumentPosition - pozycja na liście argumentów
--		Description - opis jako pole MS_Description z Extended Properties
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select [obj].[name] as [Module],
	   [obj].[object_id] as [ModuleId],
	   [sch].[name] as [Schema],
	   [p].[name] as [Name],
	   concat(coalesce([isp].[USER_DEFINED_TYPE_NAME], [isp].[DATA_TYPE]),
			  '(' + cast(coalesce([isp].[CHARACTER_MAXIMUM_LENGTH], [isp].[DATETIME_PRECISION]) as varchar(100)) +
			  ')') as [Type],
	   [isp].[ORDINAL_POSITION] as [ArgumentPosition]
from [sys].[parameters] as [p]
inner join [sys].[all_objects] as [obj] on [obj].[object_id] = [p].[object_id]
inner join [sys].[schemas] as [sch] on [sch].[schema_id] = [obj].[schema_id]
inner join [INFORMATION_SCHEMA].[PARAMETERS] as [isp]
		   on [isp].[SPECIFIC_SCHEMA] = [sch].[name] and [isp].[SPECIFIC_NAME] = [obj].[name] and
			  [isp].[PARAMETER_NAME] = [p].[name]
where [isp].[IS_RESULT] = 'NO'
