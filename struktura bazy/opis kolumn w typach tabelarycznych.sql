-- Zapytanie pobiera informacje o kolumnach w tabelarycznych typach użytkownika
--
-- Opisy są brane z Extended Properties, z pola oznaczonego jako MS_Description
--
-- Znaczenie zwracanych wartości:
--		TableType - nazwa typu tabelarczynego
--		object_id - identyfikator obiektu typu tabelarycznego
--		user_type_id - identyfikator typu tabelarycznego użytkownika
--		Schema - schemat typu tabelraczynego
--		Column - nazwa kolumny
--		Type - typ kolumny (bez podawania rozmiaru - te kolumny nie są ujęte w [INFORMATION_SCHEMA].[COLUMNS])
--		Description - opis jako pole MS_Description z Extended Properties
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select [tt].[name] as [TableType],
	   [tt].[type_table_object_id] as [object_id],
	   [tt].[user_type_id],
	   [sch].[name] as [Schema],
	   [sc].[name] as [Column],
	   [t].[name] as [Type],
	   [sep].[value] as [Description]
from [sys].[columns] as [sc]
inner join [sys].[table_types] as [tt] on [tt].[type_table_object_id] = [sc].[object_id]
inner join [sys].[schemas] as [sch] on [sch].[schema_id] = [tt].[schema_id]
inner join [sys].[types] as [t] on [t].[user_type_id] = [sc].[user_type_id]
left join [sys].[extended_properties] [sep]
		  on [tt].[user_type_id] = [sep].[major_id] and [sep].[minor_id] = [sc].[column_id] and
			 [sep].[class_desc] = 'TYPE_COLUMN' and [sep].[name] = 'MS_Description'
