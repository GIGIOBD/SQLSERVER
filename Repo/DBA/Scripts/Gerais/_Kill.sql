/* Mata todas as sess�es do banco */
kill_all 'i4sro_registradora_head',null

/* Mata todas as sess�es do usu�rio*/
kill_all null,'i4proinfo\ashinoda'


sp_helptext kill_all

alter login [i4proinfo\ashinoda] disable 

drop login [i4proinfo\ashinoda];