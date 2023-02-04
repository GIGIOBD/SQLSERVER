SELECT 
    [name],
    [value],
    [description]
FROM 
    sys.configurations
WHERE 
    [name] IN ( 'max degree of parallelism', 'cost threshold for parallelism', 'min server memory (MB)',
                'max server memory (MB)', 'clr enabled', 'xp_cmdshell', 'Ole Automation Procedures',
                'user connections', 'fill factor (%)', 'cross db ownership chaining', 'remote access',
                'default trace enabled', 'external scripts enabled', 'Database Mail XPs', 'Ad Hoc Distributed Queries',
                'SMO and DMO XPs', 'clr strict security', 'remote admin connections'
              )
ORDER BY 
    [name]