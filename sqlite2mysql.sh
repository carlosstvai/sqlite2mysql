#!/bin/bash

usage() { echo "Usage: $0 [ -s sqlite_source_file.db ] [ -h mysql_host -u mysql_user ] [ -p mysql_password ] [ -d new_database_name ] " 1>&2; exit 1; }

while getopts ":s:h:u:p:d:" opt ; do
	case $opt in
		s)
			DBFILENAME=$OPTARG
			;;
		h)
			MYSQLHOST=$OPTARG
			;;
		u)
			MYSQLUSER=$OPTARG
			;;
		p)
			MYSQLPWD=$OPTARG
			;;
		d)
			MYSQLNEWDBNAME=$OPTARG
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
		*)
			usage
			;;
	esac
done

if [ -z $DBFILENAME ] || [ -z $MYSQLHOST ] || [ -z $MYSQLUSER ] || [ -z $MYSQLPWD ] || [ -z $MYSQLNEWDBNAME ]; then 
	usage
	exit 1;
fi

if [ ! -s "$DBFILENAME" ]; then
	echo -e "File \"$DBFILENAME\" not found or is not a valid SQLite source file"
	exit;
fi

DUMPFILENAME=$DBFILENAME.dump.sql

#sqlite3 ZKTimeNet.db .dump > ZK_sqlite3_dump.sql
sqlite3 $DBFILENAME .dump > $DUMPFILENAME

if [ $? -ne 0 ]; then
	echo -e "Error...\n";
	exit 1;
fi
# HACER ANTES UN BACKUP DEL ARCHIVO A MODIFICAR
NEWFILENAME=$DUMPFILENAME
cp $NEWFILENAME $NEWFILENAME.origbak
sed -i '/PRAGMA/d' $NEWFILENAME
sed -i '/BEGIN TRANSACTION/d' $NEWFILENAME
sed -i '/COMMIT/d' $NEWFILENAME
sed -i 's/AUTOINCREMENT/auto_increment/g' $NEWFILENAME
sed -i 's/nvarchar/varchar/g' $NEWFILENAME
sed -i 's/\[//g' $NEWFILENAME
sed -i 's/\]//g' $NEWFILENAME
sed -i 's/\"//g' $NEWFILENAME
sed -i 's/COLLATE NOCASE//g' $NEWFILENAME
sed -i 's/varchar(1024)/varchar(255)/g' $NEWFILENAME
sed -i 's/varchar[^\(]/text /g' $NEWFILENAME
if [ -s $NEWFILENAME ]; then
	sed -i '1i set foreign_key_checks = 0;' $NEWFILENAME
else
	echo "Invalid SQLite source file"
	exit 1;
fi

# # # # # # # # #
# mysql -u$MYSQLUSER -p$MYSQLPWD -e "drop database $MYSQLNEWDBNAME"
# # # # # # # # #

#MYSQLNEWDBNAME=$(echo $DBFILENAME | sed 's/\./_/g')_$(date +%Y%m%d%H%M)
mysql -h$MYSQLHOST -u$MYSQLUSER -p$MYSQLPWD -e "create database $MYSQLNEWDBNAME"
mysql -h$MYSQLHOST -u$MYSQLUSER -p$MYSQLPWD $MYSQLNEWDBNAME < $NEWFILENAME

# # # # # # # # # 
# MARCHA ATRÁS  #
# # # # # # # # # 
# mysql -u$MYSQLUSER -p$MYSQLPWD -e "drop database $MYSQLNEWDBNAME"
# # # # # # # # #
# cp $NEWFILENAME.origbak $NEWFILENAME 
