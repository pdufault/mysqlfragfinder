#!/usr/bin/env python
# python port of mysqlfragfinder.sh ?

import MySQLdb as mdb
import sys

try:
    con = mdb.connect('localhost', 'user', 'password', 'mysql');

    cur = con.cursor()
    cur.execute("SELECT VERSION()")

    ver = cur.fetchone()

    print "Database version : %s " % ver

except mdb.Error, e:
    print "Error %d: %s" % (e.args[0],e.args[1])
    sys.exit(1)

finally:

    if con:
        con.close()

#Logic flow
# parse command line input
# read ~/.my.cnf for authentication details
# test login
# get db version
# open logs
# get list of databases
#     check table status on each db
#     sort out all that are myisam or innodb
#     sort tables based on our criteria:
#     disk space regain
#     optimize all tables
#     optimize only the small tables
#     optimize only the big tables?
#     add each sorted table to an array
#     iterate over list. thread?
#     error checking / logging
#
# wrap up message
# close logs
