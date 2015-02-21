mysqlfragfinder
===============

finds your fragmented tables...and defragments them

```shell
me@host:~/src/mysqlfragfinder $ ./mysqlfragfinder.sh

MySQL fragmentation finder (and fixer) v1.0.2
Written by Phil Dufault (phil@dufault.info, http://www.dufault.info)
        This script only repairs MyISAM and InnoDB tables
        --help -h               this menu
        --user username         specify mysql username to use, the script will prompt for a password during runtime, unless you supply a password
        --password "yourpass"
        --host hostname         specify mysql hostname to use, be it local (default) or remote
        --mysql command         specify mysql command name, default is mysql
        --database              use specified database as target
                                if this option is not used, all databases are targeted
        --log                   set a custom log. Default value is $PWD/mysqlfragfinder.log"
        --check                 only shows fragmented tables, but do not optimize them
        --detail                additionally display fragmented tables

```
