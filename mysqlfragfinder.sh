#!/usr/bin/env bash
# Phil Dufault (2009)
# bumped to v1 (2011)
# phil@dufault.info

VERSION="1.0.1"
log="$PWD/mysql_error_log.txt"
mysqlCmd="mysql"

echo "MySQL fragmentation finder (and fixer) v$VERSION"
echo "Written by Phil Dufault (phil@dufault.info, http://www.dufault.info)"

showHelp() {
	echo -e "\tThis script only repairs MyISAM and InnoDB tables"
	echo -e "\t--help or -h\t\tthis menu"
	echo -e "\t--user username\tspecify mysql username to use\n\t\t\tusing this flag means the script will ask for a password during runtime, unless you supply..."
	echo -e "\t--password \"yourpassword\""
	echo -e "\t--host hostname\tspecify mysql hostname to use, be it local (default) or remote"
	echo -e "\t--mysql command\tspecify mysql command name, default is mysql"
	echo -e "\t--database\tuse specified database as target\n\t\t\tif this option is not used, all databases are targeted"
	echo -e "\t--check\tonly shows fragmented tables, but do not optimize them"
	echo -e "\t--detail\tadditionally display fragmented tables"
}

#s parse arguments
while [[ $1 == -* ]]; do
	case "$1" in
		--help|-h) showHelp; exit 0;;
		--user) mysqlUser="$2"; shift 2;;
		--password) mysqlPass="$2"; shift 2;;
		--host) mysqlHost="$2"; shift 2;;
		--mysql) mysqlCmd="$2"; shift 2;;
		--database) mysqlDb="$2"; shift 2;;
		--check) mysqlCheck="1"; shift;;
		--detail) mysqlDetail="1"; shift;;
		--*) shift; break;;
	esac
done

# prevent overwriting the commandline args with the ones in .my.cnf, and check that .my.cnf exists
if [[ ! $mysqlUser  && -f "$HOME/.my.cnf" ]]; then
	if grep "user=" "$HOME/.my.cnf" >/dev/null 2>&1; then
		if grep "password=" "$HOME/.my.cnf" >/dev/null 2>&1; then
			mysqlUser=$(grep user= < "$HOME/.my.cnf" | awk -F\" '{print $2}');
			mysqlPass=$(grep password= < "$HOME/.my.cnf" | awk -F\" '{print $2}');
			if grep "host=" "$HOME/.my.cnf" >/dev/null 2>&1; then
				mysqlHost=$(grep host= < "$HOME/.my.cnf" | awk -F\" '{print $2}');
			fi
		else
			echo "Found no pass line in your .my.cnf,, fix this or specify with --password"
		fi
	else
		echo "Found no user line in your .my.cnf, fix this or specify with --user"
		exit 1;
	fi
fi

# set localhost if no host is set anywhere else
if [[ ! $mysqlHost ]]; then
	mysqlHost="127.0.0.1"
fi

# error out
if [[ ! $mysqlUser ]]; then
	echo "Authentication information not found as arguments, nor in $HOME/.my.cnf"
	echo
	showHelp
	exit 1
fi

if [[ ! $mysqlPass ]]; then
	echo -n "Enter your MySQL password: "
	read -s mysqlPass
fi

# Test connecting to the database:
"${mysqlCmd}" -u"$mysqlUser" -p"$mysqlPass" -h"$mysqlHost" --skip-column-names --batch -e "show status" >/dev/null 2>"$log"
if [[ $? -gt 0 ]]; then
	echo "An error occured, check $log for more information.";
	exit 1;
fi

# Retrieve the listing of databases:
if [[ ! $mysqlDb ]]; then
	databases=( $("${mysqlCmd}" -u"$mysqlUser" -p"$mysqlPass" -h"$mysqlHost" --skip-column-names --batch -e "show databases;" 2>"$log") );
else
	databases=( $mysqlDb );
fi
if [[ $? -gt 0 ]]; then
	echo "An error occured, check $log for more information."
	exit 1;
fi

echo -e "Found ${#databases[@]} databases";
for i in ${databases[@]}; do
	# get a list of all of the tables, grep for MyISAM or InnoDB, and then sort out the fragmented tables with awk
	fragmented=( $("${mysqlCmd}" -u"$mysqlUser" -p"$mysqlPass" -h"$mysqlHost" --skip-column-names --batch -e "SHOW TABLE STATUS FROM \`$i\`;" 2>"$log" | awk '{print $1,$2,$10}' | egrep "MyISAM|InnoDB|Aria" | awk '$3 > 0' | awk '{print $1}') );
	if [[ $? -gt 0 ]]; then
		echo "An error occured, check $log for more information."
		exit 1;
	fi
	tput sc
	echo -n "Checking $i ... ";
	if [[ ${#fragmented[@]} -gt 0 ]]; then
		if [[ ${#fragmented[@]} -gt 0 ]]; then
			if [[ ${#fragmented[@]} -gt 1 ]]; then
				echo "found ${#fragmented[@]} fragmented tables."
			else
				echo "found ${#fragmented[@]} fragmented table."
			fi
			if [[ $mysqlDetail ]]; then
				for table in ${fragmented[@]}; do
					echo -ne "\t$table\n";
				done
			fi
		fi
		# only optimize tables if check option is disabled
		if [[ ! $mysqlCheck ]]; then
			for table in ${fragmented[@]}; do
				let fraggedTables=$fraggedTables+1;
				echo -ne "\tOptimizing $table ... ";
				"${mysqlCmd}" -u"$mysqlUser" -p"$mysqlPass" -h"$mysqlHost" -D "$i" --skip-column-names --batch -e "optimize table \`$table\`" 2>"$log" >/dev/null
				if [[ $? -gt 0 ]]; then
					echo "An error occured, check $log for more information."
					exit 1;
				fi
				echo done
			done
		fi
	else
		tput rc
		tput el
	fi
	unset fragmented
done

# footer message
if [[ $mysqlCheck ]]; then
	echo "Check option was enabled, so no optimizing was done.";
elif [[ ! $fraggedTables -gt 0 ]]; then
	echo "No tables were fragmented, so no optimizing was done.";
else
	if [[ $fraggedTables -gt 1 ]]; then
		echo "$fraggedTables tables were fragmented, and were optimized.";
	else
		echo "$fraggedTables table was fragmented, and was optimized.";
	fi
fi

if [[ ! -s $log ]]; then
	rm -f "$log"
fi

unset fraggedTables
