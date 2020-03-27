-- Zapytanie pobiera uproszczone informacje o zależnościach pomiędzy obiektami informując o tym, gdzie dany obiekt jest wykorzystywany.
--
-- Zapytanie jest przdatne do odnajdywania obiektów, które wykorzystują interesujący nas obiekt.
--
-- Znaczenie zwracanych wartości:
--		Module - nazwa obiektu
--		ModuleType - typ obiektu
--		ModuleSchema - schemat obiektu
--		ModuleId - identyfikator obiektu
--		DependantObjectId - identyfikator obiektu, który wykorzystuje obiekt Module
--		DependantObjectName - nazwa obiektu, który wykorzystuje obiekt Module
--		DependantObjectSchema - schemat obiektu, który wykorzystuje obiekt Module
--		DependantdObjectType - typ obiektu, który wykorzystuje obiekt Module
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select distinct
	   [m].[name] as [Module],
	   [m].[type_desc] as [ModuleType],
	   [msch].[name] as [ModuleSchema],
	   [m].[object_id] as [ModuleId],
	   [ssed].[referencing_id] as [DependantObjectId],
	   [sal].[name] as [DependantObjectName],
	   [sch].[name] as [DependantObjectSchema],
	   [sal].[type_desc] as [DependantdObjectType]
from [sys].[all_objects] as [m]
inner join [sys].[schemas] as [msch] on [msch].[schema_id] = [m].[schema_id]
inner join [sys].[sql_expression_dependencies] as [ssed] 
		   on [ssed].[referenced_id] = [m].[object_id] and ssed.referencing_class_desc = 'OBJECT_OR_COLUMN'
inner join [sys].[all_objects] as [sal]
		   on [sal].[object_id] = [ssed].[referencing_id] and [ssed].[referenced_class_desc] = 'OBJECT_OR_COLUMN'
inner join [sys].[schemas] as [sch] on [sch].[schema_id] = [sal].[schema_id]
where [referenced_id] is not null
  and [m].[type] in ('IF', 'FN', 'TF', 'AF', 'P', 'U', 'V', 'TG')
  and [msch].[name] not in ('sys', 'INFORMATION_SCHEMA')
