-- Zapytanie pobiera informacje o zależnościach pomiędzy obiektami.
--
-- Znaczenie zwracanych wartości:
--		Module - nazwa obiektu
--		ModuleType - typ obiektu
--		ModuleSchema - schemat obiektu
--		ModuleId - identyfikator obiektu
--		DependencyObjectId - identyfikator obiektu, od którego zależy obiekt Module
--		DependencyObjectName - nazwa obiektu, od którego zależy obiekt Module
--		DependencyObjectSchema - schemat obiektu, od którego zależy obiekt Module
--		DependencyObjectType - typ obiektu, od którego zależy obiekt Module. Jeśli obiekt Module korzysta z zapytań Dynamic Sql wtedy
--								w polu pojawia się sztuczna nazwa typu DYNAMIC_SQL
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select distinct
	   [m].[name] as [Module],
	   [m].[type_desc] as [ModuleType],
	   [msch].[name] as [ModuleSchema],
	   [m].[object_id] as [ModuleId],
	   [ssed].[referenced_id] as [DependencyObjectId],
	   [ssed].[referenced_entity_name] as [DependencyObjectName],
	   [sch].[name] as [DependencyObjectSchema],
	   coalesce([sal].[type_desc], [ssed].[referenced_class_desc]) as [DependencyObjectType]
from [sys].[all_objects] as [m]
inner join [sys].[schemas] as [msch] on [msch].[schema_id] = [m].[schema_id]
inner join sys.sql_expression_dependencies as ssed on ssed.referencing_id = m.object_id and ssed.referencing_class_desc = 'OBJECT_OR_COLUMN'
left join [sys].[all_objects] as [sal]
		  on [sal].[object_id] = [ssed].[referenced_id] and [ssed].[referenced_class_desc] = 'OBJECT_OR_COLUMN'
left join [sys].[types] as [st]
		  on [st].[user_type_id] = [ssed].[referenced_id] and [ssed].[referenced_class_desc] = 'TYPE'
left join [sys].[schemas] as [sch] on [sch].[schema_id] = coalesce([sal].[schema_id], [st].[schema_id])
where [referenced_id] is not null
  and [msch].[name] not in ('sys', 'INFORMATION_SCHEMA')
union all
select [m].[name] as [Module],
	   [m].[type_desc] as [ModuleType],
	   [msch].[name] as [ModuleSchema],
	   [m].[object_id] as [ModuleId],
	   null as [DependencyObjectId],
	   'Dynamic SQL' as [DependencyObjectName],
	   null as [DependencyObjectSchema],
	   'DYNAMIC_SQL' as [DependencyObjectType]
from [sys].[all_objects] as [m]
inner join [sys].[schemas] as [msch] on [msch].[schema_id] = [m].[schema_id]
inner join [sys].[all_sql_modules] as [sasm] on [sasm].[object_id] = [m].[object_id]
where [msch].[name] not in ('sys', 'INFORMATION_SCHEMA')
  and [sasm].[definition] like '%sp_executesql%'
