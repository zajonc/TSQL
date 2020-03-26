-- Zapytanie pobiera informacje o kolumnach w widokach użytkownika.
--
-- Opisy widoku są brane z Extended Properties, z pola oznaczone jako MS_Description
--
-- Znaczenie zwracanych wartości:
-- 		View - nazwa widoku
--		Schema - schemat widoku
--		Column - nazwa kolumny
--		Nullable - jeśli kolumna dopuszcza wartości NULL to 1, w przeciwnym przypadku 0
--		object_id - identyfikator obiektu widoku
--		column_id - identyfikator kolumny
--		Type - typ kolumny wraz z rozmiarem
--		Description - opis kolumny jako pole MS_Description z Extended Properties
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select [st].[name] as [View],
	   [sch].[name] as [Schema],
	   [sc].[name] as [Column],
	   [sc].[is_nullable] as [Nullable],
	   [st].[object_id],
	   [sc].[column_id],
	   concat([t].[name],
			  '(' + cast(coalesce([isc].[CHARACTER_MAXIMUM_LENGTH], [isc].[DATETIME_PRECISION]) as varchar(100)) +
			  ')') as [Type],
	   [sep].[value] as [Description]
from [sys].[views] [st]
inner join [sys].[schemas] as [sch] on [sch].[schema_id] = [st].[schema_id]
inner join [sys].[columns] [sc] on [st].[object_id] = [sc].[object_id]
inner join [sys].[types] as [t] on [t].[user_type_id] = [sc].[user_type_id]
inner join [INFORMATION_SCHEMA].[COLUMNS] as [isc]
		   on [isc].[TABLE_NAME] = [st].[name] and [isc].[TABLE_SCHEMA] = [sch].[name] and
			  [isc].[COLUMN_NAME] = [sc].[name]
left join [sys].[extended_properties] [sep]
		  on [st].[object_id] = [sep].[major_id] and [sc].[column_id] = [sep].[minor_id] and
			 [sep].[class_desc] = 'OBJECT_OR_COLUMN' and [sep].[name] = 'MS_Description'
