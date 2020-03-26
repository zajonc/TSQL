-- Zapytanie pobiera informacje o indeksach w tabelach użytkownika
--
-- Opisy są brane z Extended Properties, z pola oznaczonego jako MS_Description
--
-- Znaczenie zwracanych wartości:
--		Table - nazwa tabeli, do której należy indeks
--		TableId - identyfikator obiektu tabeli
--		Schema - schemat tabeli
-- 		Name - nazwa indeksu
--		PrimaryKey - jeśli indeks jest PK to 1, w przeciwnym wypadku 0
--		Unique - jeśli indeks jest unikalny wtedy 1, w przeciwnym wypadku 0
-- 		UniqueConstraint - jeśli indeks jest typu Unique Constraint wtedy 1, w przeciwnym wypadku 0
--		Type - typ indeksu (CLUSTERED, NONCLUSTERED)
--		Filter - jeśli indeks ma ustawiony filtr wtedy tutaj będzie on widoczny
--		Description - opis jako pole MS_Description z Extended Properties
--
-- Autor: Zajonc (https://blog.zajonc.pl)


select st.name [Table],
	   st.object_id [TableId],
	   sch.name [Schema],
	   idx.name [Name],
	   idx.is_primary_key [PrimaryKey],
	   idx.is_unique [Unique],
	   idx.is_unique_constraint [UniqeConstraint],
	   idx.type_desc [Type],
	   idx.filter_definition [Filter],
	   sep.value [Description]
from sys.all_objects as st
inner join sys.schemas as sch on st.schema_id = sch.schema_id
inner join sys.indexes as idx on st.object_id = idx.object_id
left join sys.extended_properties sep on idx.index_id = sep.major_id
	and sep.minor_id = 0
	and sep.class_desc = 'OBJECT_OR_COLUMN'
	and sep.name = 'MS_Description'
where st.type in ('U')
  and sch.name not in ('sys', 'INFORMATION_SCHEMA')
  and idx.index_id > 0
