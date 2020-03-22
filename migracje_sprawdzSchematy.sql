use master;
go

-- Sprawdzam czy procedura istnieje - jeœli tak to j¹ usuwam. 
-- Dziêki takiemu podejœciu nie muszê siê przejmowaæ czy wykonywaæ skrypt tworzenia procedury czy jej zmiany.
-- Ponad to jeœli chcê nadaæ procedurze jakieœ specyficzne uprawnienia, wtedy nie muszê siê przejmowaæ usuwaniem poprzednich.
-- Przy takim podejœciu mogê ten skrypt wykonywaæ bezpiecznie wielokrotnie i niczego przez przypadek nie zepsujê :)
if exists(select *
		  from [sysobjects]
		  where [id] = object_id(N'[dbo].[migracje_sprawdzSchematy]')
			and OBJECTPROPERTY([id], N'IsProcedure') = 1) begin	
	drop procedure [dbo].[migracje_sprawdzSchematy]
end
go
create procedure [dbo].[migracje_sprawdzSchematy] @dbProd sysname, @dbDev sysname as
begin
	set nocount on;

	declare @error nvarchar(max);

	-- Poniewa¿ zapytanie w dalszej czêœci bêdzie siê opieraæ na dynamicznym SQL (musimy sparametryzowaæ zapytanie nazwami baz danych)
	-- Dlatego aby unikn¹æ ryzyka, ¿e ktoœ wstrzyknie nam coœ do tego zapytania najpierw sprawdzamy czy obie bazy istniej¹
	if exists (select * from dbo.sysdatabases where [name] = @dbProd) begin
		if exists (select * from dbo.sysdatabases where [name] = @dbDev) begin
			declare @query nvarchar(max) = concat(N'
				select coalesce(prod.CATALOG_NAME, dev.CATALOG_NAME) as CATALOG_NAME,
				coalesce(prod.SCHEMA_NAME, dev.SCHEMA_NAME) as SCHEMA_NAME,
				case
					when prod.SCHEMA_NAME is not null then concat(''drop schema ['', prod.SCHEMA_NAME, ''];'')
					when dev.SCHEMA_NAME is not null then concat(''create schema ['', dev.SCHEMA_NAME, ''];'')
					else null
				end as SUGEROWANA_OPERACJA
				from [', @dbProd ,N'].INFORMATION_SCHEMA.SCHEMATA as prod
				full outer join [', @dbDev ,N'].INFORMATION_SCHEMA.SCHEMATA as dev on dev.SCHEMA_NAME = prod.SCHEMA_NAME
				where prod.SCHEMA_NAME is null 
				or dev.SCHEMA_NAME is null
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
-- Poniewa¿ uparwniony do wykonywania procedury jest tylko administrator dlatego nie musimy dodawaæ ¿adnych dodatkowych uprawnieñ