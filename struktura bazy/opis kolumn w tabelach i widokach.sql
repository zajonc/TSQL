-- Zapytanie pobiera informacje o kolumnach w tabelach użytkownika.
--
-- Opisy tabeli są brane z Extended Properties, z pola oznaczone jako MS_Description
--
-- Znaczenie zwracanych wartoœci:
-- 		Table - nazwa tabeli/widoku
--		Schema - schemat tabeli/widoku
--		Column - nazwa kolumny
--		PrimaryKey - jeśli kolumna jest PK to pojawi się typ CLUSTERED/NONCLUSTERED, w przeciwnym wypadku NULL
--		Identity - jeśli kolumna posiada identity to 1, w przeciwym przypadku 0
--		Nullable - jeśli kolumna dopuszcza wartości NULL to 1, w przeciwnym przypadku 0
--		Default - jeœli kolumna posiada wartość domyślną to będzie ona tutaj widoczna
--		object_id - identyfikator obiektu tabeli/widoku
--		column_id - identyfikator kolumny
--		Type - typ kolumny wraz z rozmiarem
--		ForeignKeyName - jeśli kolumna posiada odniesienie do innej kolumny wtedy tutaj pojawia się nazwa klucza
--		ForeignKeyReference - jeśli kolumna posiada odniesienie do innej kolumny wtedy tutaj pojawia się wskazanie tej kolumny
--		Description - opis kolumny jako pole MS_Description z Extended Properties
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select [st].[name] as [Table],
	   [sch].[name] as [Schema],
	   [sc].[name] as [Column],
	   [idx].[type_desc] as [PrimaryKey],
	   [sc].[is_identity] as [Identity],
	   [sc].[is_nullable] as [Nullable],
	   [isc].[COLUMN_DEFAULT] as [Default],
	   [st].[object_id],
	   [sc].[column_id],
	   concat([t].[name],
			  '(' + cast(coalesce([isc].[CHARACTER_MAXIMUM_LENGTH], [isc].[DATETIME_PRECISION]) as varchar(100)) +
			  ')') as [Type],
	   [fkco].[name] as [ForignKeyName],
	   [fkcs].[name] + '.' + [fkct].[name] + '(' + [fkcc].[name] + ')' as [ForeignKeyReference],
	   [sep].[value] as [Description]
from [sys].[tables] [st]
inner join [sys].[schemas] as [sch] on [sch].[schema_id] = [st].[schema_id]
inner join [sys].[columns] [sc] on [st].[object_id] = [sc].[object_id]
inner join [sys].[types] as [t] on [t].[user_type_id] = [sc].[user_type_id]
inner join [INFORMATION_SCHEMA].[COLUMNS] as [isc]
		   on [isc].[TABLE_NAME] = [st].[name] and [isc].[TABLE_SCHEMA] = [sch].[name] and
			  [isc].[COLUMN_NAME] = [sc].[name]
left join [sys].[extended_properties] [sep]
		  on [st].[object_id] = [sep].[major_id] and [sc].[column_id] = [sep].[minor_id] and
			 [sep].[class_desc] = 'OBJECT_OR_COLUMN' and [sep].[name] = 'MS_Description'
left join [sys].[foreign_key_columns] as [fkc]
		  on [fkc].[parent_object_id] = [st].[object_id] and [fkc].[parent_column_id] = [sc].[column_id]
left join [sys].[all_objects] as [fkco] on [fkco].[object_id] = [fkc].[constraint_object_id]
left join [sys].[all_objects] as [fkct] on [fkct].[object_id] = [fkc].[referenced_object_id]
left join [sys].[schemas] as [fkcs] on [fkcs].[schema_id] = [fkco].[schema_id]
left join [sys].[columns] as [fkcc]
		  on [fkcc].[object_id] = [fkc].[referenced_object_id] and [fkcc].[column_id] = [fkc].[referenced_column_id]
left join [sys].[indexes] as [idx]
		  on [idx].[object_id] = [st].[object_id] and [idx].[is_primary_key] = 1 and exists(select *
																							from [sys].[index_columns] as [ic]
																							where [ic].[index_id] = [idx].[index_id]
																							  and [ic].[object_id] = [st].[object_id]
																							  and [ic].[column_id] = [sc].[column_id])
