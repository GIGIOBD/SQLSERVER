------------------------------------------------------------------
-- Gerador de Senhas ou Texto aleatório
declare 
	@contador int = 0

	declare @letras varchar(max) = ' abcdefghijklmnopqrstuwvxzABCDEFGHIJKLMNOPQRSTUWVXZ1234567890!@#$%¨&*()-+_=´[]~;/\.,<>|"'''
	declare @tamanho int = 15
	;with cte as (
	    select
	        1 as contador,
	        substring(@letras, 1 + (abs(checksum(newid())) % len(@letras)), 1) as letra
	    union all
	    select
	        contador + 1,
	        substring(@letras, 1 + (abs(checksum(newid())) % len(@letras)), 1)
	    from cte where contador < @tamanho)
	--select * from cte option (maxrecursion 0)
	
	select (
	    select '' + letra from cte
	    for xml path(''), type, root('txt')
	    ).value ('/txt[1]', 'varchar(max)')
	option (maxrecursion 0)
