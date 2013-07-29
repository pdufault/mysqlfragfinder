mysqlfragfinder
===============

finds your fragmented tables...and defragments them

```
me@host:~/src/mysqlfragfinder $ ./mysqlfragfinder.sh
MySQL fragmentation finder (and fixer) v1.0.1
Written by Phil Dufault (phil@dufault.info, http://www.dufault.info)
Authentication information not found as arguments, nor in .my.cnf

        This script only repairs MyISAM and InnoDB tables
        --help or -h            this menu
        --user username specify mysql username to use
                        using this flag means the script will ask for a password during runtime, unless you supply...
        --password "yourpassword"
        --host hostname specify mysql hostname to use, be it local (default) or remote
        --mysql command specify mysql command name, default is mysql
        --database      use specified database as target
                        if this option is not used, all databases are targeted
        --check only shows fragmented tables, but do not optimize them
        --detail        additionally display fragmented tables
```
