use [master];
go
-- Sprawdzam czy procedura istnieje - jeśli tak to ją usuwam.
-- Dzięki takiemu podejściu nie muszę się przejmować czy wykonywać skrypt tworzenia procedury czy jej zmiany.
-- Ponad to jeśli chcę nadać procedurze jakieś specyficzne uprawnienia, wtedy nie muszę się przejmować usuwaniem poprzednich.
-- Przy takim podejściu mogę ten skrypt wykonywać bezpiecznie wielokrotnie i niczego przez przypadek nie zepsuję :)
if exists(select *
		  from [sysobjects]
		  where [id] = object_id(N'[dbo].[migracje_sprawdzModuly]')
			and objectproperty([id], N'IsProcedure') = 1) begin
	drop procedure [dbo].[migracje_sprawdzModuly]
end
go
create procedure [dbo].[migracje_sprawdzModuly]
	@dbProd sysname, -- nazwa bazy produkcyjnej
	@dbDev sysname -- nazwa bazy deweloperskiej
as
begin
	set nocount on;

	declare @error nvarchar(max);

	-- Ponieważ zapytanie w dalszej części będzie się opierać na dynamicznym SQL (musimy sparametryzować zapytanie nazwami baz danych)
	-- dlatego aby uniknąć ryzyka, że ktoś wstrzyknie nam coś do tego zapytania najpierw sprawdzamy czy obie bazy istnieją
	if exists(select * from [dbo].[sysdatabases] where [name] = @dbProd) begin
		if exists(select * from [dbo].[sysdatabases] where [name] = @dbDev) begin
			declare @query nvarchar(max) = N'';

			-- Musimy zastosować sztuczkę z konkatenacją wykorzystującą zmienną o typie nvarchar(max).
			-- Bez tego concat nie zwróci nam typu nvarchar(max), co przy tak długim zapytaniu po prostu by je ucięło w najmniej oczekiwanym miejscu.
			set @query = concat(@query, N'
				with [moduly_prod] as (	select 	[s].[name] as [schemat],
						   		[o].[name] as [modul_nazwa],
								[o].[type] as [modul_typ],
								[o].[type_desc] as [modul_typ_nazwa],
								[m].[definition] as [modul_definicja],
								case 	when [m].[execute_as_principal_id] = -2 then ''owner''
									when [p].[principal_id] is not null then [p].[name]
									else ''caller''
								end as [execute_as],
								[p].[type] as [execute_as_type],
								[p].[type_desc] as [execute_as_type_name]
							from [', @dbProd, N'].[sys].[sql_modules] as [m]
							inner join [', @dbProd, N'].[sys].[objects] as [o] on [o].[object_id] = [m].[object_id]
							inner join [', @dbProd, N'].[sys].[schemas] as [s] on [s].[schema_id] = [o].[schema_id]
							left join [', @dbProd, N'].[sys].[database_principals] as [p]
								on [p].[principal_id] = [m].[execute_as_principal_id]
					  		),
					 [moduly_dev]  as ( 	select 	[s].[name] as [schemat],
									[o].[name] as [modul_nazwa],
									[o].[type] as [modul_typ],
									[o].[type_desc] as [modul_typ_nazwa],
									[m].[definition] as [modul_definicja],
									case 	when [m].[execute_as_principal_id] = -2 then ''owner''
										when [p].[principal_id] is not null then [p].[name]
										else ''caller''
									end as [execute_as],
									[p].[type] as [execute_as_type],
									[p].[type_desc] as [execute_as_type_name]
								from [', @dbDev, N'].[sys].[sql_modules] as [m]
								inner join [', @dbDev, N'].[sys].[objects] as [o] on [o].[object_id] = [m].[object_id]
								inner join [', @dbDev, N'].[sys].[schemas] as [s] on [s].[schema_id] = [o].[schema_id]
								left join [', @dbDev, N'].[sys].[database_principals] as [p]
									on [p].[principal_id] = [m].[execute_as_principal_id]
							  ),
					 [cmp_prod]    as ( select * from [moduly_prod] except select * from [moduly_dev] ),
					 [cmp_dev]     as ( select * from [moduly_dev] except select * from [moduly_prod] )
				select	coalesce([p].[schemat], [d].[schemat]) as [schemat],
					coalesce([p].[modul_nazwa], [d].[modul_nazwa]) as [modul_nazwa],
					coalesce([p].[modul_typ], [d].[modul_typ]) as [modul_typ],
					coalesce([p].[modul_typ_nazwa], [d].[modul_typ_nazwa]) as [modul_typ_nazwa],
					iif(coalesce([p].[schemat], '''') != coalesce([d].[schemat], ''''), 1, 0) as [diffSchemat],
				   	iif(coalesce([p].[modul_nazwa], '''') != coalesce([d].[modul_nazwa], ''''), 1, 0) as [difModulNazwa],
				   	iif(coalesce([p].[modul_typ], '''') != coalesce([d].[modul_typ], ''''), 1, 0) as [difModulTyp],
				   	iif(coalesce([p].[modul_definicja], '''') != coalesce([d].[modul_definicja], ''''), 1, 0) as [diffDefinition],
					iif(coalesce([p].[execute_as], '''') != coalesce([d].[execute_as], ''''), 1, 0) as [diffExecuteAs],
				   	iif(coalesce([p].[execute_as_type], '''') != coalesce([d].[execute_as_type], ''''), 1, 0) as [diffExecuteAsType],
				   	[p].[modul_definicja] as [b1_definicja],
				   	[p].[execute_as] as [b1_execute_as],
				   	[p].[execute_as_type] as [b1_execute_as_type],
				   	[p].[execute_as_type_name] as [b1_execute_as_type_name],
				   	[d].[modul_definicja] as [b2_definicja],
				   	[d].[execute_as] as [b2_execute_as],
				   	[d].[execute_as_type] as [b2_execute_as_type],
				   	[d].[execute_as_type_name] as [b2_execute_as_type_name]
				from [cmp_prod] as [p]
				full outer join [cmp_dev] as [d]
					on [p].[schemat] = [d].[schemat] and [p].[modul_nazwa] = [d].[modul_nazwa] and [p].[modul_typ] = [d].[modul_typ]
			');

			exec [sp_sqlexec] @query;
		end
		else begin
			set @error = concat(N'Niepoprawna nazwa bazy danych [', @dbDev, N']');
			throw 51001, @error, 1;
		end
	end
	else begin
		set @error = concat(N'Niepoprawna nazwa bazy danych [', @dbProd, N']');
		throw 51000, @error, 1;
	end
end
go
-- Ponieważ uparwniony do wykonywania procedury jest tylko administrator dlatego nie musimy dodawać żadnych dodatkowych uprawnień
