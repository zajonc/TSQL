-- Zapytanie pobiera informacje o typach użytkownika
--
-- Opisy są brane z Extended Properties, z pola oznaczonego jako MS_Description
--
-- Znaczenie zwracanych wartości:
--		Name - nazwa typu
--		object_id - identyfikator obiektu typu
--		user_type_id - identyfikator typu użytkownika
--		Schema - schemat typu
--		IsTable - jeśli typ jest tabelaryczny wtedy 1, w przeciwnym wypadku 0
--		Description - opis jako pole MS_Description z Extended Properties
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select t.name [Name],
	   tt.type_table_object_id as [object_id],
	   t.user_type_id,
	   sch.name [Schema],
	   t.is_table_type [IsTable],
	   sep.value [Description]
from sys.types as t
inner join sys.schemas as sch on sch.schema_id = t.schema_id
left join sys.table_types as tt on tt.user_type_id = t.user_type_id
left join sys.extended_properties sep on t.user_type_id = sep.major_id
	and sep.minor_id = 0
	and sep.class_desc = 'TYPE'
	and sep.name = 'MS_Description'
where t.is_user_defined = 1
