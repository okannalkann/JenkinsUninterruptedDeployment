net use S: SERVER_NAME /user:USERNAME PASSWORD

net use T: "JENKINSNAME\workspace"

set sFolderName="serverFolderName"
set tFolderName="JenkinsFolderName"
set projectName="Project Name"
::PM2 is the module of Nodejs
set pm2Name="pm2NAME" 
set skipBuild=0

if %skipBuild% == 1 goto :skipBuild
call t:
call cd T:%tFolderName%
call del latest.7z
call del latest.7z.tmp
call rd /s /q node_modules
call C:"Program Files"\7-Zip\7z.exe a -r latest.7z T:%tFolderName%*

call s:
call rd /s /q %sFolderName%-new
call mkdir %sFolderName%-new

call t:
call xcopy /Y /E latest.7z S:%sFolderName%-new\
if %errorlevel% neq 0 exit /b %errorlevel%

call s:
call cd %sFolderName%-new
if %errorlevel% neq 0 exit /b %errorlevel%
call C:"Program Files"\7-Zip\7z.exe x latest.7z -aoa
if %errorlevel% neq 0 exit /b %errorlevel%

call npm install
if %errorlevel% neq 0 exit /b %errorlevel%

call cd ..
:skipBuild
call s:
call cd %sFolderName%
call del latest.7z
call del latest.7z.tmp
::pm2 stop
call wmic /NODE:SERVER_NAME /user:USERNAME /password:PASSWORD process call create 'cmd.exe /c  "(d:) & (pm2 delete %projectName%)"'
call waitfor SomethingThatIsNeverHappening /t 2 2>NUL
call cd ..
:changeFolderName
call waitfor SomethingThatIsNeverHappening /t 5 2>NUL
call ren %sFolderName% OLD-%sFolderName%
IF exist OLD-%sFolderName%\ ( echo "Foldername changed") else ( echo "Foldername not changed" )

call ren %sFolderName%-new %sFolderName%
call cd %sFolderName%
call echo DB_HOST=%DB_HOST%  >> .env
call echo DB_USER=%DB_USER%  >> .env
call echo DB_PASSWORD=%DB_PASSWORD%  >> .env
call echo DB_NAME=%DB_NAME%  >> .env
call echo DB_PORT=%DB_PORT%  >> .env
call echo DB_CONLIMIT=%DB_CONLIMIT%  >> .env
call echo SEQ_URL=%SEQ_URL%  >> .env
call echo SEQ_APIKEY=%SEQ_APIKEY%  >> .env

::pm2 start
call wmic /NODE:SERVER_NAME /user:USERNAME /password:PASSWORD process call create 'cmd.exe /c   "(d:) & (pm2 start --env %pm2Name%)"'

call cd ..
call cd OLD-%sFolderName%
call rd /s /q nodemodules
call cd ..
call del %tFolderName%*.7z
::Last build backup
call C:"Program Files"\7-Zip\7z.exe a -r %tFolderName%%time:~0,2%%time:~3,2%%time:~6,2%%date:~-10,2%%date:~-7,2%%date:~-4,4%.7z S:\OLD-%sFolderName%*
call waitfor SomethingThatIsNeverHappening /t 2 2>NUL
call rd /s /q OLD-%sFolderName%
call exit 0
