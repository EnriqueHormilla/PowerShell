get-wmiobject win32_logicaldisk | 
select Name,FileSystem,VolumeName,@{n="Total/GB";e={[math]::truncate($_.Size / 1GB)}},@{n="Free/GB";e={[math]::truncate($_.freespace / 1GB)}}