-- Zapytanie pobiera informacje o funkcjach i procedurach składowanych użytkownika
--
-- Opisy są brane z Extended Properties, z pola oznaczonego jako MS_Description
--
-- Znaczenie zwracanych wartości:
--		Name - nazwa funkcji/procedury
--		object_id - identyfikator obiektu funkcji/procedury
--		Schema - schemat funkcji/procedury
--		Type - typ obiektu funkcji/procedury
--		ReturnType - jeśli obiekt zwraca wartość to tutaj pojawia się jej typ, w przeciwnym wypadku NULL
--		Description - opis jako pole MS_Description z Extended Properties
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select [m].[name] as [Name],
	   [m].[object_id],
	   [sch].[name] as [Schema],
	   [m].[type_desc] as [Type],
	   nullif(concat(coalesce([isp].[USER_DEFINED_TYPE_NAME], [isp].[DATA_TYPE]), '(' + cast(
			   coalesce([isp].[CHARACTER_MAXIMUM_LENGTH], [isp].[DATETIME_PRECISION]) as varchar(100)) + ')'),
			  '') as [ReturnType],
	   [sep].[value] as [Description]
from [sys].[all_objects] as [m]
inner join [sys].[schemas] as [sch] on [sch].[schema_id] = [m].[schema_id]
left join [INFORMATION_SCHEMA].[PARAMETERS] as [isp]
		  on [isp].[SPECIFIC_SCHEMA] = [sch].[name] and [isp].[SPECIFIC_NAME] = [m].[name] and [isp].[IS_RESULT] = 'YES'
left join [sys].[extended_properties] [sep]
		  on [m].[object_id] = [sep].[major_id] and [sep].[minor_id] = 0 and [sep].[class_desc] = 'OBJECT_OR_COLUMN' and
			 [sep].[name] = 'MS_Description'
where [m].[type] in ('IF', 'FN', 'TF', 'AF', 'P')
  and [sch].[name] not in ('sys', 'INFORMATION_SCHEMA')
