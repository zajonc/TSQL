-- Zapytanie pobiera informacje o triggerach w tabelach użytkownika
--
-- Opisy są brane z Extended Properties, z pola oznaczonego jako MS_Description
--
-- Znaczenie zwracanych wartości:
--		Table - nazwa tabeli, do której należy indeks
--		TableId - identyfikator obiektu tabeli
--		Schema - schemat tabeli
-- 		Name - nazwa triggera
--		object_id - identyfikator obiektu triggera
--		EVENT_INSERT - jeśli trigger reaguje na zdarzenie insert wtedy pojawia się wartośc INSERT, w przeciwnym wypadku NULL
--		EVENT_UPDATE - jeśli trigger reaguje na zdarzenie update wtedy pojawia się wartośc UPDATE, w przeciwnym wypadku NULL
--		EVENT_DELETE - jeśli trigger reaguje na zdarzenie delete wtedy pojawia się wartośc DELETE, w przeciwnym wypadku NULL
--		Description - opis jako pole MS_Description z Extended Properties
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select [obj].[name] as [Table],
	   [obj].[object_id] as [TableId],
	   [sch].[name] as [Schema],
	   [tg].[name] as [Name],
	   [tg].[object_id],
	   [tei].[type_desc] as [EVENT_INSERT],
	   [teu].[type_desc] as [EVENT_UPADTE],
	   [ted].[type_desc] as [EVENT_DELETE],
	   [sep].[value] as [Description]
from [sys].[triggers] as [tg]
inner join [sys].[objects] as [obj] on [obj].[object_id] = [tg].[parent_id]
inner join [sys].[schemas] as [sch] on [sch].[schema_id] = [obj].[schema_id]
left join [sys].[trigger_events] as [tei] on [tei].[object_id] = [tg].[object_id] and [tei].[type_desc] = 'INSERT'
left join [sys].[trigger_events] as [teu] on [teu].[object_id] = [tg].[object_id] and [teu].[type_desc] = 'UPDATE'
left join [sys].[trigger_events] as [ted] on [ted].[object_id] = [tg].[object_id] and [ted].[type_desc] = 'DELETE'
left join [sys].[extended_properties] [sep] on [tg].[object_id] = [sep].[major_id] and [sep].[minor_id] = 0 and
											   [sep].[class_desc] = 'OBJECT_OR_COLUMN' and
											   [sep].[name] = 'MS_Description'
