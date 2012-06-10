#!/bin/sh

#-
# Copyright (c) 2009-2011 Phil Dufault <phil@dufault.info>
# Copyright (c) 2012 Daniel Gerzo <danger@FreeBSd.org>
# All rights reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted providing that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

VERSION="2.0"
_frag_flag="0"

# some defaults
mysqlOptimize=${mysqlOptimize:-"0"}
log=${log:-"/root/mysql_error_log.txt"}

usage() {
	cat <<EOF
MySQL fragmentation finder (and fixer) v$VERSION
This script only repairs MyISAM, InnoDB and Aria tables.

usage: `basename $0` [options]

Options:
	--help or -h	Print the usage message (i.e. this)
	--user username	Specify mysql username to use
			using this flag means the script will ask for a password during runtime, unless you supply...
	--password pwd	Specify the password for the given mysql username
			If not provided, the script will ask during its execution
	--host hostname	Specify mysql hostname to use, be it local (default) or remote
	--mysql cmd	Specify mysql command name, the default is mysql
	--database db	Use the specified database as target
			If this option is not used, all databases are targeted
	--log path	Store the logs in the specified file, the default is $log
	--optimize	Optimize the fragmented tables
EOF
}

# prevent overwriting the commandline args with the ones in .my.cnf, and check that .my.cnf exists
if [ -z "$mysqlUser" -a -f "$HOME/.my.cnf" ]; then
	mysqlUser=$(grep user= < "$HOME/.my.cnf" | awk -F\= '{print $2}');
	mysqlPass=$(grep -E 'pass(word)?=' < "$HOME/.my.cnf" | awk -F\= '{print $2}');
	mysqlHost=$(grep host= < "$HOME/.my.cnf" | awk -F\= '{print $2}');
fi

# parse arguments
while [ $# -gt 0 ]; do
	case "$1" in
		--help|-h) usage; exit 0;;
		--user|-u) mysqlUser="$2"; shift 2;;
		--password|-p) mysqlPass="$2"; shift 2;;
		--host|-h) mysqlHost="$2"; shift 2;;
		--mysql|-m) mysqlCmd="$2"; shift 2;;
		--database|-d) mysqlDb="$2"; shift 2;;
		--log|-l) log="$2"; shift 2;;
		--optimize|-o) mysqlOptimize="1"; shift;;
		--*|-*) shift; break;;
	esac
done

# set defaults
mysqlCmd=${mysqlCmd:-"mysql"}
mysqlUser=${mysqlUser:-"root"}
mysqlHost=${mysqlHost:-"localhost"}

if [ -z $mysqlPass ]; then
	echo -n "Enter your MySQL password: "
	read mysqlPass
fi

# Test connecting to the database:
"${mysqlCmd}" -u"$mysqlUser" -p"$mysqlPass" -h"$mysqlHost" --skip-column-names --batch -e "SHOW STATUS" > /dev/null 2> "$log"
if [ $? -gt 0 ]; then
	echo "An error occured, check $log for more information.";
	exit 1;
fi

# Retrieve the list of databases:
if [ ! $mysqlDb ]; then
	databases=$("${mysqlCmd}" -u"$mysqlUser" -p"$mysqlPass" -h"$mysqlHost" --skip-column-names --batch -e "SHOW DATABASES;" 2>"$log")
else
	databases=$mysqlDb;
fi
if [ $? -gt 0 ]; then
	echo "An error occured, check $log for more information."
	exit 1;
fi

count=$(echo $databases | wc -w | tr -d '[:space:]')
echo "Found ${count} databases";
for i in ${databases}; do
	# get a list of all of the tables, grep for MyISAM or InnoDB, and then sort out the fragmented tables with awk
	fragmented=$("${mysqlCmd}" -u"$mysqlUser" -p"$mysqlPass" -h"$mysqlHost" --skip-column-names --batch -e "SHOW TABLE STATUS FROM \`$i\`;" 2>"$log" | awk '$2 ~ /MyISAM|InnoDB|Aria/ {if ($10>0) print $1}')
	if [ $? -gt 0 ]; then
		echo "An error occured, check $log for more information."
		exit 1;
	fi
	echo "Checking $i ... ";
	if [ ! -z "${fragmented}" ]; then
		_frag_flag="1"
		echo "The following tables are fragmented:"
		for table in ${fragmented}; do
			echo -e "\t$table";
		done

		# only optimize tables if optimize option is enabled
		if [ $mysqlOptimize -eq "1" ]; then
			for table in ${fragmented}; do
				printf "\tOptimizing $table ... ";
				"${mysqlCmd}" -u"$mysqlUser" -p"$mysqlPass" -h"$mysqlHost" -D "$i" --skip-column-names --batch -e "OPTIMIZE TABLE \`$table\`" 2>"$log" >/dev/null
				if [ $? -gt 0 ]; then
					echo "An error occured, check $log for more information."
					exit 1;
				fi
				echo done
			done
		fi
	fi
done

# footer message
echo
if [ $_frag_flag -eq "1" -a $mysqlOptimize -eq "0" ]; then
	echo "Optimize option was disabled, so no optimization was done.";
elif [ $_frag_flag -eq "0" ]; then
	echo "No tables were fragmented, so no optimizing was done.";
else
	echo "Tables were successfully optimized.";
fi
