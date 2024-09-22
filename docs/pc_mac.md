This document installs a set of tools on a new Windows 11 laptop. 

For that we're exclusively using a **powershell Admin** terminal. No GUI. 

The goal is to load a postgreSQL dump file from github  into a fresh install of postgres and connect to the database via psql or pgAdmin.

The plan is to install

- postgreSQL 16
- pgAdmin 4
- git
- vscode
- vim

And 
- be able to start, stop, get the status of the postgreSQL server with ```pg_ctl```
- use ```pg_restore``` and ```pg_dump``` to respectively restore and dump a compressed sql backup file
- 

This will require to
- modify the Machine PATH
- create and add an ssh key to your github account
- 

Before we start by installing postgreSQL, the **powershell Admin** terminal is launched via: Win + X and selecting "Terminal Admin".



# Install postgreSQL on Windows 11

Downloading and installing postgres is strqihgtforzqrd. Go to postgresql.org and find the download page or go directly to 
https://www.enterprisedb.com/downloads/postgres-postgresql-downloads and click on the download arrow for Windows x86-64 and postgres 16

Then follow the instructions 

From now on we assume that postgresql@16 has been installed in the folder:

> C:\Program Files\PostgreSQL\16\

You can check that the folder exists with the ```Test-Path``` utility

```powershell
Test-Path 'C:\Program Files\PostgreSQL\16\'
```

Note: the quotes around the path, which make up for the presence of a space in 'Program Files'.

Anyway the above line should return a resounding **True**. 

If not, that means postgreSQL was installed elsewhere on your machine. Good luck.

## Manage postgres on the command line

On windows you start, stop, restart and monitor postgresql with ```pg_ctl```. 

We need to make sure that program exists, is in the right place, does the job  and finally we want to add it to the machine PATH. 

* ```pg_ctl.exe``` should be in the 'C:\Program Files\PostgreSQL\16\bin\' folder. Which also contains stuff like ```pg_restore```, ```pg_dump```, ```createdb```, ```createuser``` and ```psql``` and many other niceties.

To check if postgres is installed and if it can actually run try:

```powershell
& "C:\Program Files\PostgreSQL\16\bin\pg_ctl" start -D "C:\Program Files\PostgreSQL\16\data"
```

This should return 
```powershell
PS C:\Users\alexis> & "C:\Program Files\PostgreSQL\16\bin\pg_ctl" start -D "C:\Program Files\PostgreSQL\16\data"
waiting for server to start....2024-09-15 14:36:07.370 GMT [10044] LOG:  redirecting log output to logging collector process
2024-09-15 14:36:07.370 GMT [10044] HINT:  Future log output will appear in directory "log".
 done
server started
```

If that's the case, congratulation you have correctly installed postgres@16 on your windows box!

Now we don't want to have to remember all these path everytime we want to start or stop the postgresql server. So we need to first add the location of ```pg_ctl``` to the path.

On windows there are 2 different paths! The machine and the user one. Machine path makes thing available to the whole ... machine dhu! and user path only to the current user.

The PATH is an environment variable that list all the directories (and thier full path) where a given program can be found. 
Important because before windows (or any other OS for that matter) can execute / run a program it needs to know where to find it.

So, if you want to start postgreSQL server with a simple 

```powershell
pg_ctl start
```
(we'll deal with the rest of the command: ```-D "C:\Program Files\PostgreSQL\16\data"``` in a bit )

you must first add _"C:\Program Files\PostgreSQL\16\bin\"_ to the PATH.

Let's see what's in the Machine PATH:
```powershell
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
echo $currentPath
```
should return something like

```powershell
PS C:\Users\alexis> echo $currentPath
C:\windows\system32;C:\windows;C:\windows\System32\Wbem;C:\windows\System32\WindowsPowerShell\v1.0\;C:\windows\System32\OpenSSH\
```

By the way, notice how we've used a variable to store the value of the PATH. Powershell variables are very nice and will facilitate our lives a lot.

To add the folder to the PATH, you can concatenate the two 
```powershell
$postgresPath = "C:\Program Files\PostgreSQL\16\bin"
$newPath = $currentPath + ";" + $postgresPath
```
and then store that ```$newPath``` value as the Machine PATH with:

```powershell
[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
```

Then the PATH should now contain the right folder.

Before you shout victory, let's check if your change will be resilient enough.

To reload the PATH from scratch, open a new terminal Admin window 
and then

```powershell
echo [Environment]::GetEnvironmentVariable("Path", "Machine")
```
should return a string that includes the **PostgreSQL\16\bin folder**.

```powershell
C:\windows\system32;C:\windows;C:\windows\System32\Wbem;C:\windows\System32\WindowsPowerShell\v1.0\;C:\windows\System32\OpenSSH\;**C:\Program Files\PostgreSQL\16\bin**
```

ok now let's deal with the rest of the command: ```-D "C:\Program Files\PostgreSQL\16\data"```


### Troubleshooting

There are a lot (I mean way too many) restrictions and safeties
 

<!-- verify location of postgres -->

> ls 'C:\Program Files\PostgreSQL\16\data'

<!-- start stop postgres -->

> pg_ctl start -D "C:\Program Files\PostgreSQL\16\data"

<!-- this works -->

> & "C:\Program Files\PostgreSQL\16\bin\pg_ctl" start -D "C:\Program Files\PostgreSQL\16\data"

#  PATH

<!-- echo the PATH -->


## add to path
To add PostgreSQL to your PATH permanently, you can use the System Properties dialog:

* Press Win+X and select "System"
* Click on "Advanced system settings"
* Click on "Environment Variables"
* Under "System variables", find and edit "Path"
* Add a new entry: "C:\Program Files\PostgreSQL\16\bin"

or edit the PATH directly 

$postgresPath = "C:\Program Files\PostgreSQL\16\bin"
$newPath = $currentPath + ";" + $postgresPath
> $newPath = $currentPath + ";" + $postgresPath

adding vim 

get path to vim
PS C:\Users\Administrateur> Get-ChildItem "C:\Program Files\Vim" -Recurse -Filter "vim.exe"
C:\Program Files\Vim\vim91

$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$vimPath = "C:\Program Files\Vim\vim91"
$newPath = $currentPath + ";" + $vimPath
[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

* test the path is correct with
Test-Path "C:\Program Files\Vim\vim91\vim.exe"
True

## setup vim

# 1. Check vim version and features
vim --version

# 2. Enable paste mode in vim
# When in vim, type:
# :set paste
# Then press i to enter insert mode, and try pasting

# 3. If that doesn't work, try creating a .vimrc file
$vimrcPath = "$env:USERPROFILE\_vimrc"
if (-not (Test-Path $vimrcPath)) {
    @"
set paste
set mouse=
"@ | Out-File -FilePath $vimrcPath -Encoding ascii
    Write-Host "Created _vimrc file at $vimrcPath"
} else {
    Write-Host "_vimrc file already exists at $vimrcPath"
}

# 4. If issues persist, try using Notepad++ for editing
if (-not (Get-Command notepad++ -ErrorAction SilentlyContinue)) {
    Write-Host "Notepad++ not found. You may want to install it for easier editing."
} else {
    Write-Host "You can use Notepad++ to edit files:"
    Write-Host "notepad++ `"$env:APPDATA\postgresql\psqlrc.conf`""
}

# 5. Reminder about PowerShell's native text editing capabilities
Write-Host "Remember, you can also use PowerShell's native text editing capabilities:"
Write-Host "Invoke-Item `"$env:APPDATA\postgresql\psqlrc.conf`""

Invoke-Item $env:APPDATA\postgresql\psqlrc.conf

# Powershell profile 

To disable the warnings when pasting multiple lines in PowerShell on Windows 11, you can modify a PowerShell setting. 

view the current setting:

> $PSDefaultParameterValues['Out-Default:OutVariable']

## create your PowerShell profile:

check if you have a profile by running:

> Test-Path $PROFILE

If it returns False, create a profile by running:

> New-Item -Path $PROFILE -Type File -Force

## edit profile
Open the profile in a text editor:

> notepad $PROFILE

Add the following line to the profile:

> $PSDefaultParameterValues['Out-Default:OutVariable'] = '__'

Set-PSReadLineOption -PredictionSource History


Save & close

# Git

1. using HTTPS instead of SSH, doesn't require SSH keys 
>  git clone https://github.com/SkatAI/epitadb.git

## using SSH, to set up SSH keys 

* Generate a new SSH key

> ssh-keygen -t ed25519 -C "your_email@example.com"

key is saved in  C:\Users\Administrateur/.ssh/id_ed25519.pub

* Enable and Start the ssh-agent servive 

> Set-Service ssh-agent -StartupType Automatic
> Start-Service ssh-agent

* Add the SSH key to the ssh-agent:

> ssh-add $env:USERPROFILE\.ssh\id_ed25519

* Copy the public key:

> Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | clip

* Add this public key to your GitHub account:
    - Go to GitHub > Settings > SSH and GPG keys
    - Click "New SSH key"
    - Paste your key and save

* test your SSH connection to GitHub:
>   ssh -T git@github.com

* Make sure your Git configuration has the correct user information:
   ```
   git config --global user.name "Your Name"
   git config --global user.email "your_email@example.com"
   ```

# pg_restore 
I was able to restre the sql.backup file  with

```powershell
pg_restore -d "treesdb_v01" `
  -U postgres `
  --no-owner `
  --no-data-for-failed-tables `
  --no-privileges `
  --section=pre-data `
  --section=data `
  --section=post-data `
  --verbose `
  --exit-on-error `
  --single-transaction `
  "C:\Users\alexis\work\epitadb\data\treesdb_v01.08.sql.backup"

```

# setup pgpass to handle password in psql

1. Create the pgpass.conf file
(you may have to create the \postgres\ folder first))

> $pgpassPath = "$env:APPDATA\postgresql\pgpass.conf"

This forces the creation of the file
> New-Item -Path $pgpassPath -ItemType File -Force

This tests the existance of the file
> Test-Path $pgpassPath

# 2. Set the file permissions (only the current user should have access)
$acl = Get-Acl $pgpassPath
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
$acl.AddAccessRule($rule)
Set-Acl $pgpassPath $acl

# 3. Add connection details to pgpass.conf (example)
$connectionString = "localhost:5432:your_database:your_username:your_password"
Add-Content -Path $pgpassPath -Value $connectionString

or edit the file directly adding the line (this sets the password for postgres on all the database on locahost port 5432)
> localhost:5432:*:postgres:postgres 


# 4. Verify the content (optional)

> Get-Content $pgpassPath

or 

> cat $pgpassPath

# psqlrc

Run this script in an Administrator PowerShell

Define the path for psqlrc.conf
> $psqlrcPath = "$env:APPDATA\postgresql\psqlrc.conf"

# Create the directory if it doesn't exist
$directory = Split-Path -Path $psqlrcPath -Parent
if (-not (Test-Path -Path $directory)) {
    New-Item -ItemType Directory -Path $directory | Out-Null
    Write-Host "Created directory: $directory"
}

# Create the psqlrc.conf file if it doesn't exist
if (-not (Test-Path -Path $psqlrcPath)) {
    New-Item -ItemType File -Path $psqlrcPath | Out-Null
    Write-Host "Created file: $psqlrcPath"
} else {
    Write-Host "File already exists: $psqlrcPath"
}

# Add some common psqlrc configurations
$psqlrcContent = @"
-- Set the default prompt
\set PROMPT1 '%[%033[1;33;40m%]%n@%m:%>%[%033[0m%] %/ %# '

-- Set the default pager
\setenv PAGER less

-- Set the default editor
\setenv EDITOR notepad

-- Enable expanded table format by default
\x auto

-- Show execution time of queries
\timing

-- Set null display
\pset null '(null)'

-- Set border style
\pset border 2

-- Show table sizes in \d+
\set VERBOSITY verbose

-- Customize psql's behavior
\set COMP_KEYWORD_CASE upper
\set HISTCONTROL ignoredups
\set HISTSIZE 2000
\set ECHO_HIDDEN ON
"@

# Write the content to the file
Set-Content -Path $psqlrcPath -Value $psqlrcContent

Write-Host "psqlrc.conf has been created and populated with default settings."
Write-Host "You can edit this file at: $psqlrcPath"

# Set proper permissions (only the current user should have access)
$acl = Get-Acl $psqlrcPath
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
    "FullControl",
    "Allow"
)
$acl.AddAccessRule($rule)
Set-Acl $psqlrcPath $acl

Write-Host "File permissions have been set to restrict access to the current user only."

# Verify the content
Write-Host "`nContent of $psqlrcPath:"
Get-Content $psqlrcPath

Write-Host "`nTo edit this file, you can use: notepad `"$psqlrcPath`""
