use master;
go

-- Sprawdzam czy procedura istnieje - jeśli tak to ją usuwam. 
-- Dzięki takiemu podejściu nie muszę się przejmować czy wykonywać skrypt tworzenia procedury czy jej zmiany.
-- Ponad to jeśli chcę nadać procedurze jakieś specyficzne uprawnienia, wtedy nie muszę się przejmować usuwaniem poprzednich.
-- Przy takim podejściu mogę ten skrypt wykonywać bezpiecznie wielokrotnie i niczego przez przypadek nie zepsuję :)
if exists(select *
		  from [sysobjects]
		  where [id] = object_id(N'[dbo].[migracje_sprawdzSchematy]')
			and OBJECTPROPERTY([id], N'IsProcedure') = 1) begin	
	drop procedure [dbo].[migracje_sprawdzSchematy]
end
go
create procedure [dbo].[migracje_sprawdzSchematy]	@dbProd sysname, -- nazwa bazy produkcyjnej
							@dbDev sysname  -- nazwa bazy deweloperskiej
as
begin
	set nocount on;

	declare @error nvarchar(max);

	-- Ponieważ zapytanie w dalszej części będzie się opierać na dynamicznym SQL (musimy sparametryzować zapytanie nazwami baz danych)
	-- Dlatego aby uniknąć ryzyka, że ktoś wstrzyknie nam coś do tego zapytania najpierw sprawdzamy czy obie bazy istnieją
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
-- Ponieważ uparwniony do wykonywania procedury jest tylko administrator dlatego nie musimy dodawać żadnych dodatkowych uprawnień
