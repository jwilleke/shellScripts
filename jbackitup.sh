#!/bin/bash
#
# SCRIPT: jbackup.sh
# AUTHOR: jim@willeke.com
# DATE:   2013-02-16
T_VER=2025-05-04							# Script Version Number
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
# Setting backup destination directory
BACKUP_DIR="/var/local/backup"
# Defining an array of source directories to back up
declare -a SOURCE_DIRS=("/path/to/folder1" "/path/to/folder2" "/path/to/folder3")
# Setting backup destination directory
BACKUP_DIR="/path/to/backup/destination"
# Creating timestamp for backup files
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
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
  l_target=$1

   if [ -f ${l_target}/lockfile ]
   then
      echo "Lockfile exists, backup stopped."
      f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Lockfile ${l_target}/lockfile exists, backup stopped." 
      exit 2
   else
      touch ${l_target}/lockfile
   fi
}
##########################################################
# create folders if neccessary
# $1 = folder name
##########################################################
f_create_folders()
{
  l_folder=$1

  if [ ! -e ${l_folder} ]
  then
      f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: mkdir ${l_folder}"
      mkdir ${l_folder}
  fi
  if [ ! -d ${l_folder}/weekly ]
  then
      f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: mkdir ${l_folder}/weekly" 
      mkdir ${l_folder}/weekly
   fi
   if [ ! -d ${l_folder}/daily ]
   then
      f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: mkdir ${l_folder}/daily" 
      mkdir ${l_folder}/daily
   fi
   if [ ! -d ${l_folder}/hourly ]
   then
      f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: mkdir ${l_folder}/hourly" 
      mkdir ${l_folder}/hourly
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
# Ensuring backup directory exists
f_create_folders "$BACKUP_DIR"
f_lock_file "$BACKUP_DIR"
# Looping through each source directory
for DIR in "${SOURCE_DIRS[@]}"; do
    # Getting the base name of the directory
    DIR_NAME=$(basename "$DIR")
    # Creating tar file name
    TAR_FILE="$BACKUP_DIR/${TIMESTAMP}_${DIR_NAME}.tar.gz"
    f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: $0 $APPNAME $THIS_SCRIPT SOURCE: $DIR_NAME is being backed up to $TAR_FILE"
    # Creating tar archive
    tar -czf "$TAR_FILE" -C "$(dirname "$DIR")" "$DIR_NAME"
    # Checking if tar command was successful
    if [ $? -eq 0 ]; then
        f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`:Backup of $DIR completed: $TAR_FILE"
    else
        f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: ERROR: Backup of $DIR failed"
    fi
done

f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: All Backup Complete!"
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Delete old backups"
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +13 -delete
# keep daily backup

#if [ `find ${TARGET}/daily -maxdepth 1 -type d -mtime -2 -name "20*" | wc -l` -eq 0 ] && [ `find ${TARGET}/hourly -maxdepth 1 -name "20*" | wc -l` -gt 1 ]
#then
#   oldest=`ls -1 -tr ${TARGET}/hourly/ | head -1`
#   f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Keep daily backups  mv ${TARGET}/hourly/$oldest ${TARGET}/daily/"   
#   mv ${TARGET}/hourly/$oldest ${TARGET}/daily/
#fi

# keep weekly backup
#if [ `find ${TARGET}/weekly -maxdepth 1 -type d -mtime -14 -name "20*" | wc -l` -eq 0 ] && [ `find ${TARGET}/daily -maxdepth 1 -name "20*" | wc -l` -gt 1 ]
#then
#   oldest=`ls -1 -tr ${TARGET}/daily/ | head -1`
#   f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Keep weekly backups  mv ${TARGET}/daily/$oldest ${TARGET}/weekly/"   
#   mv ${TARGET}/daily/$oldest ${TARGET}/weekly/
#fi

# delete old backups
#f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Delete old backups"
#find ${TARGET}/hourly -maxdepth 1 -type d -mtime +0 | xargs rm -rf
#find ${TARGET}/daily -maxdepth 1 -type d -mtime +7 | xargs rm -rf

# remove lockfile
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Remove:  ${BACKUP_DIR}/lockfile"
rm ${BACKUP_DIR}/lockfile
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: $0 $APPNAME Script Name: $THIS_SCRIPT Script Version $T_VER exited by $USER"

##########################################################
#               CLEANUP
##########################################################
unset T_VER
# End of script

