use master;
go
-- Sprawdzam czy procedura istnieje - jeśli tak to ją usuwam. 
-- Dzięki takiemu podejściu nie muszę się przejmować czy wykonywać skrypt tworzenia procedury czy jej zmiany.
-- Ponad to jeśli chcę nadać procedurze jakieś specyficzne uprawnienia, wtedy nie muszę się przejmować usuwaniem poprzednich.
-- Przy takim podejściu mogę ten skrypt wykonywać bezpiecznie wielokrotnie i niczego przez przypadek nie zepsuję :)
if exists(select *
		  from [sysobjects]
		  where [id] = object_id(N'[dbo].[migracje_sprawdzOgraniczenia]')
			and OBJECTPROPERTY([id], N'IsProcedure') = 1) begin	
	drop procedure [dbo].[migracje_sprawdzOgraniczenia]
end
go
create procedure [dbo].[migracje_sprawdzOgraniczenia]	@dbProd sysname, -- nazwa bazy produkcyjnej
							@dbDev sysname  -- nazwa bazy deweloperskiej
as
begin
	set nocount on;

	declare @error nvarchar(max);

	-- Ponieważ zapytanie w dalszej części będzie się opierać na dynamicznym SQL (musimy sparametryzować zapytanie nazwami baz danych)
	-- dlatego aby uniknąć ryzyka, że ktoś wstrzyknie nam coś do tego zapytania najpierw sprawdzamy czy obie bazy istnieją
	if exists (select * from dbo.sysdatabases where [name] = @dbProd) begin
		if exists (select * from dbo.sysdatabases where [name] = @dbDev) begin
			declare @query nvarchar(max) = N'';

			-- Musimy zastosować sztuczkę z konkatenacją wykrozystującą zmienną o typie nvarchar(max).
			-- Bez tego concat nie zwróci nam typu nvarchar(max) co przy tak długim zapytaniu po prostu je utnie.
			set @query = concat(@query, N'
				with fk_prod as (
					select fk.[object_id], concat(s.name, ''.'', ro.name, ''('', c.name, '')'') as [definition]
					from [', @dbProd ,N'].sys.foreign_keys as fk
					inner join [', @dbProd ,N'].sys.objects as ro on ro.object_id = fk.referenced_object_id
					inner join [', @dbProd ,N'].sys.schemas as s on s.schema_id = ro.schema_id
					inner join [', @dbProd ,N'].sys.columns as c on c.object_id = ro.object_id and c.column_id = fk.key_index_id
				), fk_dev as (
					select fk.[object_id], concat(s.name, ''.'', ro.name, ''('', c.name, '')'') as [definition]
					from [', @dbDev ,N'].sys.foreign_keys as fk
					inner join [', @dbDev ,N'].sys.objects as ro on ro.object_id = fk.referenced_object_id
					inner join [', @dbDev ,N'].sys.schemas as s on s.schema_id = ro.schema_id
					inner join [', @dbDev ,N'].sys.columns as c on c.object_id = ro.object_id and c.column_id = fk.key_index_id
				), uq_prod as (
					select k.object_id, stuff(( select concat('', ['', COLUMN_NAME, '']'')
											from [', @dbProd ,N'].INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
											where CONSTRAINT_NAME = k.name
											order by COLUMN_NAME asc
											for xml path('''')), 1, 2, '''') as [definition]
					from [', @dbProd ,N'].sys.sysconstraints as c
					inner join [', @dbProd ,N'].sys.key_constraints as k on k.object_id = c.constid and k.type_desc in (''UNIQUE_CONSTRAINT'', ''PRIMARY_KEY_CONSTRAINT'')
				), uq_dev as (
					select k.object_id, stuff(( select concat('', ['', COLUMN_NAME, '']'')
											from [', @dbDev ,N'].INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
											where CONSTRAINT_NAME = k.name
											order by COLUMN_NAME asc
											for xml path('''')), 1, 2, '''') as [definition]
					from [', @dbDev ,N'].sys.sysconstraints as c
					inner join [', @dbDev ,N'].sys.key_constraints as k on k.object_id = c.constid and k.type_desc in (''UNIQUE_CONSTRAINT'', ''PRIMARY_KEY_CONSTRAINT'')
				), df_prod as (
					select dc.object_id, concat(''['', c.name, '']='', dc.definition) as [definition]
					from [', @dbProd ,N'].sys.default_constraints as dc
					inner join [', @dbProd ,N'].sys.columns as c on c.object_id = dc.parent_object_id and c.column_id = dc.parent_column_id
				), df_dev as (
					select dc.object_id, concat(''['', c.name, '']='', dc.definition) as [definition]
					from [', @dbDev ,N'].sys.default_constraints as dc
					inner join [', @dbDev ,N'].sys.columns as c on c.object_id = dc.parent_object_id and c.column_id = dc.parent_column_id
				), baza1 as (
					select s.name as [schema], t.name as [table], o.name as [constraint], o.type, o.type_desc, i.type_desc as [clustered],
					coalesce(cc.definition, fk.definition, uq.definition, df.definition) as [definition]
					from [', @dbProd ,N'].sys.sysconstraints as c
					inner join [', @dbProd ,N'].sys.objects as o on o.object_id = constid
					inner join [', @dbProd ,N'].sys.objects as t on t.object_id = o.parent_object_id
					inner join [', @dbProd ,N'].sys.schemas as s on s.schema_id = t.schema_id
					left join [', @dbProd ,N'].sys.indexes as i on i.name = o.name
					left join [', @dbProd ,N'].sys.check_constraints as cc on cc.object_id = o.object_id
					left join fk_prod as fk on fk.object_id = o.object_id
					left join uq_prod as uq on uq.object_id = o.object_id
					left join df_prod as df on df.object_id = o.object_id
				), baza2 as (
					select s.name as [schema], t.name as [table], o.name as [constraint], o.type, o.type_desc, i.type_desc as [clustered],
					coalesce(cc.definition, fk.definition, uq.definition, df.definition) as [definition]
					from [', @dbDev ,N'].sys.sysconstraints as c
					inner join [', @dbDev ,N'].sys.objects as o on o.object_id = constid
					inner join [', @dbDev ,N'].sys.objects as t on t.object_id = o.parent_object_id
					inner join [', @dbDev ,N'].sys.schemas as s on s.schema_id = t.schema_id
					left join [', @dbDev ,N'].sys.indexes as i on i.name = o.name
					left join [', @dbDev ,N'].sys.check_constraints as cc on cc.object_id = o.object_id
					left join fk_dev as fk on fk.object_id = o.object_id
					left join uq_dev as uq on uq.object_id = o.object_id
					left join df_dev as df on df.object_id = o.object_id
				), cmp_baza1 as (
					select * from baza1
					except 
					select * from baza2
				), cmp_baza2 as (
					select * from baza2
					except 
					select * from baza1
				)
				select coalesce(b1.[schema], b2.[schema]) as [schema],
				coalesce(b1.[table], b2.[table]) as [table],
				coalesce(b1.[constraint], b2.[constraint]) as [constraint],
				b1.[type] as b1_type, b1.[type_desc] as b1_type_desc, b1.[clustered] as b1_clustered, b1.[definition] as b1_definiton, 
				b2.[type] as b2_type, b2.[type_desc] as b2_type_desc, b2.[clustered] as b2_clustered, b2.[definition] as b2_definiton,
				case
					when b1.[type] is not null and b2.[type] is null then (	select [constraint]
																			from cmp_baza2 
																			where b1.[schema] = [schema] 
																			and b1.[table] = [table] 
																			and b1.[type] = [type]
																			and b1.[type_desc] = [type_desc]
																			and coalesce(b1.[clustered], '''') = coalesce([clustered], '''')
																			and coalesce(b1.definition, '''') = coalesce([definition], ''''))
					when b2.[type] is not null and b1.[type] is null then (	select [constraint]
																			from cmp_baza1 
																			where b2.[schema] = [schema] 
																			and b2.[table] = [table] 
																			and b2.[type] = [type]
																			and b2.[type_desc] = [type_desc]
																			and coalesce(b2.[clustered], '''') = coalesce([clustered], '''')
																			and coalesce(b2.definition, '''') = coalesce([definition], ''''))
					else null
				end as potential_second_name
				from cmp_baza1 as b1
				full outer join cmp_baza2 as b2 on b1.[schema] = b2.[schema] and b1.[table] = b2.[table] and b1.[constraint] = b2.[constraint]					
			');

			exec sp_sqlexec @query;
		end else begin
			set @error = concat(N'Niepoprawna nazwa bazy danych [', @dbDev, N']');
			throw 51001, @error, 1;
		end
	end else begin
		set @error = concat(N'Niepoprawna nazwa bazy danych [', @dbProd, N']');
		throw 51000, @error, 1;	
	end
end
go
-- Ponieważ uparwniony do wykonywania procedury jest tylko administrator dlatego nie musimy dodawać żadnych dodatkowych uprawnieńdatkowych uprawnień
