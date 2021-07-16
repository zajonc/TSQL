use [master];
go
-- Sprawdzam czy procedura istnieje - jeśli tak to ją usuwam.
-- Dzięki takiemu podejściu nie muszę się przejmować czy wykonywać skrypt tworzenia procedury czy jej zmiany.
-- Ponad to jeśli chcę nadać procedurze jakieś specyficzne uprawnienia, wtedy nie muszę się przejmować usuwaniem poprzednich.
-- Przy takim podejściu mogę ten skrypt wykonywać bezpiecznie wielokrotnie i niczego przez przypadek nie zepsuję :)
if exists(select *
		  from [sysobjects]
		  where [id] = object_id(N'[dbo].[migracje_sprawdzRole]')
			and objectproperty([id], N'IsProcedure') = 1) begin
	drop procedure [dbo].[migracje_sprawdzRole]
end
go
create procedure [dbo].[migracje_sprawdzRole]
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
				with [role_prod] as ( select [dp].[name] as [role_name],
											 [dp].[type_desc] as [role_type],
											 [ob].[name] as [object_name],
											 [ob].[type_desc] as [object_type],
											 [dpe].[permission_name] as [permission_type],
											 [dpe].[state_desc] as [permission_state]
									  from [', @dbProd, N'].[sys].[database_principals] as [dp]
									  left join [', @dbProd, N'].[sys].[database_permissions] as [dpe] on [dpe].[grantee_principal_id] = [dp].[principal_id]
									  left join [', @dbProd, N'].[sys].[objects] as [ob] on [ob].[object_id] = [dpe].[major_id]
									  where [dp].[is_fixed_role] = 0
										and [dp].[type] != ''s''
										and [dp].[name] != ''public''
									),
					 [role_dev]  as ( select [dp].[name] as [role_name],
											 [dp].[type_desc] as [role_type],
											 [ob].[name] as [object_name],
											 [ob].[type_desc] as [object_type],
											 [dpe].[permission_name] as [permission_type],
											 [dpe].[state_desc] as [permission_state]
									  from [', @dbDev, N'].[sys].[database_principals] as [dp]
									  left join [', @dbDev, N'].[sys].[database_permissions] as [dpe] on [dpe].[grantee_principal_id] = [dp].[principal_id]
									  left join [', @dbDev, N'].[sys].[objects] as [ob] on [ob].[object_id] = [dpe].[major_id]
									  where [dp].[is_fixed_role] = 0
										and [dp].[type] != ''s''
										and [dp].[name] != ''public''
									),
					 [cmp_prod]  as ( select * from [role_prod] except select * from [role_dev] ),
					 [cmp_dev]   as ( select * from [role_dev] except select * from [role_prod] )
				select coalesce([p].[role_name], [d].[role_name]) as [role_name],
					   [p].[role_type] as [b1_role_type],
					   [p].[object_name] as [b1_object_name],
					   [p].[object_type] as [b1_object_type],
					   [p].[permission_type] as [b1_permission_type],
					   [p].[permission_state] as [b1_permission_state],
					   [d].[role_type] as [b2_role_type],
					   [d].[object_name] as [b2_object_name],
					   [d].[object_type] as [b2_object_type],
					   [d].[permission_type] as [b2_permission_type],
					   [d].[permission_state] as [b2_permission_state]
				from [cmp_prod] as [p]
				full outer join [cmp_dev] as [d] on [p].[role_name] = [d].[role_name] and [p].[role_type] = [d].[role_type] and
													coalesce([p].[object_name], '''') = coalesce([d].[object_name], '''') and
													coalesce([p].[object_type], '''') = coalesce([d].[object_type], '''') and
													coalesce([p].[permission_type], '''') = coalesce([d].[permission_type], '''')
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
-- Ponieważ uparwniony do wykonywania procedury jest tylko administrator dlatego nie musimy dodawać żadnych dodatkowych uprawnieńdatkowych uprawnień

