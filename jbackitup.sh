#!/bin/bash
#
# SCRIPT: jbackup.sh
# AUTHOR: jim@willeke.com
# DATE:   2013-02-16
T_VER=1.1A								# Script Version Number
# REV:    1.1.A (Valid are A, B, D, T, Q, and P)
#               (For Alpha, Beta, Dev, Test, QA, and Production)
#
# PLATFORM: (SPECIFY: bash
#
# REQUIREMENTS: If this script has requirements that need to be noted, this
#               is the place to spell those requirements in detail. 
#
#         EXAMPLE:  OpenSSH is required for this shell script to work.
#
# PURPOSE: Backs up filesGive a clear, and if necessary, long, description of the
#          purpose of the shell script. This will also help you stay
#          focused on the task at hand.
#
# REV LIST:
#        DATE: DATE_of_REVISION
#        BY:   AUTHOR_of_MODIFICATION
#        MODIFICATION: Describe what was modified, new features, etc--
#
#
# set -n   # Uncomment to check script syntax, without execution.
#          # NOTE: Do not forget to put the # comment back in or
#          #       the shell script will never execute!
# set -x   # Uncomment to debug this shell script
#
##########################################################
#         COMMON DEFINED VARIABLES HERE
##########################################################
THIS_SCRIPT=$(basename $0)
SUNGLEBAR="----------------------------------------------------------------------"
DOUBLEBAR="======================================================================"
# Our Standard Date format for files
DATE=`date +%Y-%m-%d`			# Datestamp e.g 2002-09-21
# Get DOW
DOW=`date +%A`						# Day of the week e.g. Monday
# Get DOM
DOM=`date +%d`						# Date of the Month e.g. 27
# Get Month Name
M=`date +%B`						# Month e.g January
# GET WEEK NUMBER
W=`date +%V`						# Week Number e.g 37
DATETIME=`date "+%Y-%m-%dT%H_%M_%S"` # filename safe timestamp!
# Host name (or IP address) of application server e.g localhost
APPHOST=`hostname`
APPNAME=jbackup
# Put the logs files here
LOGDIR=/var/log/backup
LOGFILENAME=${APPNAME}.log
LOGFILE="$LOGDIR/`date +%Y-%m-%d`-$LOGFILENAME"
##########################################################
#         DEFINE FILES AND VARIABLES HERE
##########################################################
EMAIL_NOTIFY="systems@willeke.com"
EMAIL_FROM_ADDRESS="systems@willeke.com"
EMAIL_FROM="$APPHOST"
SOURCE="/home"
TARGET="/var/local/backup"
##########################################################
#              DEFINE FUNCTIONS HERE
##########################################################
######################################################################
# Subroutine to Log to LOGFILE does not show to console
######################################################################
f_write_log ()
{
	if [ -n "$LOGFILE" -a -n "$*" ]
	then
		printf "$*\n" >> $LOGFILE
	fi
}

######################################################################
# Sends outpuit to console and to $LOGFILE
######################################################################
f_write_and_log ()
{
	if [ -n "$*" ]
	then
		f_write_log "$*"
		printf "$*\n"
	fi
}

######################################################################
# Subroutine to echo & run command
# Sends outpuit to console and to $LOGFILE
######################################################################
f_cmd ()
# arg_1 = Command to run
{
	f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'` $*"
	cmdOutput=`eval $*`; f_write_and_log "$cmdOutput"
}
###################################################################
# Will send an email message to desired recipients
# 	i_recipient="$1"
#		if i_recipient=help, we will dump out parameters
#	i_subject="$2"
#	i_msg="$3"
# if i_msg as a file exist, the message will be the contents
#	NOTE: i_msg will be erased
# If parameters are not passed, a testing message is sent.
###################################################################
f_messagesend()
{  
   TEMP_FILE=/tmp/$$.$RANDOM
	i_recipient="$1"
	i_subject="$2"
	i_msg="$3"
	i_recipient=${i_recipient:="$EMAIL_NOTIFY"}
	if [ "$i_recipient" = "help" ]
	then
		echo "recipient subject msg"
		return 1
	fi
	i_subject=${i_subject:="TESTING from $i_recipient  -`hostname`.$DOMAINNAME"}
	i_msg=${i_msg:="Message is: TESTING from $i_recipient  -`hostname`.$DOMAINNAME - `date` \n Sent form Script: $(basename $0)"}
	f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Preparing message to: $i_recipient with Subject: $i_subject  f_sendTestMessage()"
	if [ -f "$i_msg" ]
	then
		i_msgfile="$i_msg"
	else
		i_msgfile="$TEMP_FILE"
		date	                                        >  $i_msgfile
		printf "\n$i_msg\n"                             >> $i_msgfile
	fi
	$MAILER -s "$i_subject" "$i_recipient" -- -F "$EMAIL_FROM" -f "$EMAIL_FROM_ADDRESS" < $i_msgfile
	rm -f $i_msgfile
	f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: END f_sendTestMessage\n"
}
##########################################################
# check and create lockfile
##########################################################
f_lock_file()
{
   if [ -f ${TARGET}/lockfile ]
   then
      echo "Lockfile exists, backup stopped."
      f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Lockfile ${TARGET}/lockfile exists, backup stopped." 
      exit 2
   else
      touch ${TARGET}/lockfile
   fi
}
##########################################################
# create folders if neccessary
##########################################################
f_create_folders()
{
   if [ ! -e ${TARGET}/current ]
   then
      f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: mkdir ${TARGET}/current" 
      mkdir ${TARGET}/current
   fi
   if [ ! -d ${TARGET}/weekly ]
   then
      f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: mkdir ${TARGET}/weekly" 
      mkdir ${TARGET}/weekly
   fi
   if [ ! -d ${TARGET}/daily ]
   then
      f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: mkdir ${TARGET}/daily" 
      mkdir ${TARGET}/daily
   fi
   if [ ! -d ${TARGET}/hourly ]
   then
      f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: mkdir ${TARGET}/hourly" 
      mkdir ${TARGET}/hourly
   fi
}
##########################################################
#               BEGINNING OF MAIN
##########################################################
f_write_and_log "$DOUBLEBAR"
f_write_and_log "$LAGS " 
f_write_and_log "$APPHOST  $THIS_SCRIPT - see - $LOGFILE"
f_write_and_log "$DOUBLEBAR"
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: $0 $APPNAME Script Name: $THIS_SCRIPT Script Version $T_VER Started by $USER"
if [ "$1" != "" ]
then
   f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Source specified as $1"    
   SOURCE=$1
else
   f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: No Source specified using $SOURCE"
fi
f_lock_file
f_create_folders
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: $0 $APPNAME $THIS_SCRIPT SOURCE: $SOURCE is being backed up to $TARGET"
# rsync
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: rsync --archive --xattrs --verbose --human-readable --delete --exclude-from='/root/bin/rsync-exclude.txt' --link-dest=${TARGET}/current $SOURCE $TARGET/$DATETIME-incomplete"
f_cmd rsync --archive --xattrs --verbose --human-readable --delete --exclude-from='/root/bin/rsync-exclude.txt' --link-dest=${TARGET}/current $SOURCE $TARGET/$DATETIME-incomplete
# backup complete
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Backup Complete! "
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Move $TARGET/$DATETIME-incomplete to ${TARGET}/hourly/$DATETIME"
mv $TARGET/$DATETIME-incomplete ${TARGET}/hourly/$DATETIME
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Removing ${TARGET}/current" 
rm -r ${TARGET}/current
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Link into ln -s ${TARGET}/hourly/$DATETIME ${TARGET}/current" 
ln -s ${TARGET}/hourly/$DATETIME ${TARGET}/current
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Set Date ${TARGET}/hourly/$DATETIME"
touch ${TARGET}/hourly/$DATETIME

# keep daily backup
if [ `find ${TARGET}/daily -maxdepth 1 -type d -mtime -2 -name "20*" | wc -l` -eq 0 ] && [ `find ${TARGET}/hourly -maxdepth 1 -name "20*" | wc -l` -gt 1 ]
then
   oldest=`ls -1 -tr ${TARGET}/hourly/ | head -1`
   f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Keep daily backups  mv ${TARGET}/hourly/$oldest ${TARGET}/daily/"   
   mv ${TARGET}/hourly/$oldest ${TARGET}/daily/
fi

# keep weekly backup

if [ `find ${TARGET}/weekly -maxdepth 1 -type d -mtime -14 -name "20*" | wc -l` -eq 0 ] && [ `find ${TARGET}/daily -maxdepth 1 -name "20*" | wc -l` -gt 1 ]
then
   oldest=`ls -1 -tr ${TARGET}/daily/ | head -1`
   f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Keep weekly backups  mv ${TARGET}/daily/$oldest ${TARGET}/weekly/"   
   mv ${TARGET}/daily/$oldest ${TARGET}/weekly/
fi

# delete old backups
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Delete old backups"
find ${TARGET}/hourly -maxdepth 1 -type d -mtime +0 | xargs rm -rf
find ${TARGET}/daily -maxdepth 1 -type d -mtime +7 | xargs rm -rf

# remove lockfile
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Remove:  ${TARGET}/lockfile"
rm ${TARGET}/lockfile
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: $0 $APPNAME Script Name: $THIS_SCRIPT Script Version $T_VER exited by $USER"

##########################################################
#               CLEANUP
##########################################################
unset T_VER
# End of script

