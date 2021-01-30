use master;
go

-- Sprawdzam czy procedura istnieje - jeśli tak to ją usuwam. 
-- Dzięki takiemu podejściu nie muszę się przejmować czy wykonywać skrypt tworzenia procedury czy jej zmiany.
-- Ponad to jeśli chcę nadać procedurze jakieś specyficzne uprawnienia, wtedy nie muszę się przejmować usuwaniem poprzednich.
-- Przy takim podejściu mogę ten skrypt wykonywać bezpiecznie wielokrotnie i niczego przez przypadek nie zepsuję :)
if exists(select *
		  from [sysobjects]
		  where [id] = object_id(N'[dbo].[migracje_sprawdzTabele]')
			and OBJECTPROPERTY([id], N'IsProcedure') = 1) begin	
	drop procedure [dbo].[migracje_sprawdzTabele]
end
go
create procedure [dbo].[migracje_sprawdzTabele]	@dbProd sysname, -- nazwa bazy produkcyjnej
						@dbDev sysname  -- nazwa bazy deweloperskiej
as
begin
	set nocount on;

	declare @error nvarchar(max);

	-- Ponieważ zapytanie w dalszej części będzie się opierać na dynamicznym SQL (musimy sparametryzować zapytanie nazwami baz danych)
	-- dlatego aby uniknąć ryzyka, że ktoś wstrzyknie nam coś do tego zapytania najpierw sprawdzamy czy obie bazy istnieją
	if exists (select * from dbo.sysdatabases where [name] = @dbProd) begin
		if exists (select * from dbo.sysdatabases where [name] = @dbDev) begin
			declare @query nvarchar(max) = concat(N'
				with baza1 as (
					select t.name as [table], s.name as [schema], c.name as [column], tp.name as [typ], c.max_length
					from [', @dbProd ,N'].sys.tables as t
					inner join [', @dbProd ,N'].sys.schemas as s on s.schema_id = t.schema_id
					inner join [', @dbProd ,N'].sys.columns as c on c.object_id = t.object_id
					inner join [', @dbProd ,N'].sys.types as tp on tp.user_type_id = c.user_type_id
				), baza2 as (
					select t.name as [table], s.name as [schema], c.name as [column], tp.name as [typ], c.max_length
					from [', @dbDev ,N'].sys.tables as t
					inner join [', @dbDev ,N'].sys.schemas as s on s.schema_id = t.schema_id
					inner join [', @dbDev ,N'].sys.columns as c on c.object_id = t.object_id
					inner join [', @dbDev ,N'].sys.types as tp on tp.user_type_id = c.user_type_id
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
				coalesce(b1.[column], b2.[column]) as [column],
				b1.typ as b1_typ, b1.max_length as b1_length,
				b2.typ as b2_typ, b2.max_length as b2_length
				from cmp_baza1 as b1
				full outer join cmp_baza2 as b2 on b1.[schema] = b2.[schema] and b1.[table] = b2.[table] and b1.[column] = b2.[column]
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
-- Ponieważ uparwniony do wykonywania procedury jest tylko administrator dlatego nie musimy dodawać żadnych dodatkowych uprawnień
