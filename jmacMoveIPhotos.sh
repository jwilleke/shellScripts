#!/bin/bash
#
# SCRIPT: jmacMoveIPhotos.sh
# AUTHOR: jim@willeke.com
# DATE:   2022-09-10-13:13:21
T_VER=1.1A								# Script Version Number
# REV:    1.1.A (Valid are A, B, D, T, Q, and P)
#               (For Alpha, Beta, Dev, Test, QA, and Production)
#
# PLATFORM: (SPECIFY: AIX, HP-UX, Linux, OpenBSD, Solaris, other flavor, 
#                      or Not platform dependent)
#
# REQUIREMENTS: 
#   iPhotos
#
# PURPOSE: iphoto Hides photos so you can not use them for anyting but what Apple thinks you should.
#   copies them to a known location

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
#         DEFINE FILES AND VARIABLES HERE
##########################################################
EMAIL_NOTIFY="info@willeke.com"
EMAIL_FROM_ADDRESS="info@willeke.com"
EMAIL_FROM="$APPHOST"
THIS_SCRIPT=$(basename $0)
SINGLEBAR="______________________________________________________________________"
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
# Host name (or IP address) of application server e.g localhost
APPHOST=`hostname`
# Put the logs files here
LOGDIR=/Library/Logs/${THIS_SCRIPT%.*}
LOGFILENAME=${THIS_SCRIPT%.*}.log
LOGFILE="$LOGDIR/`date +%Y-%m-%d`-$LOGFILENAME"
# Following are specific to this script
# iphoto_source is where Apple puts iPhotos originals
iphoto_source=/Users/jim/Pictures/Photos\ Library.photoslibrary/originals/
# from_iphoto_dest - is where we copy them so it is easy to find
from_iphoto_dest=/Users/jim/Downloads/scans/images/from-iphoto
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
#               BEGINNING OF MAIN
##########################################################
f_write_and_log "$DOUBLEBAR"
f_write_and_log "$APPHOST  $THIS_SCRIPT - see - $LOGFILE"
f_write_and_log "$DOUBLEBAR"
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: $0 $APPNAME Script Name: $THIS_SCRIPT Script Version $T_VER Started by $USER"
f_write_and_log "$SINGLEBAR"
currentfolder="/var/log/www"
f_write_and_log "`date '+%Y-%m-%d %H:%M:%S'`: Removing file in $currentfolder that are older than $OLDERTHAN days"

# Displays photos readdy to copy
find -E "$iphoto_source" -iregex ".*\.(jpg|gif|png|jpeg)"
# Copy from iphoto_source location to from_iphoto_dest
find -E "$iphoto_source" -iregex ".*\.(jpg|gif|png|jpeg)" -exec cp '{}' "$from_iphoto_dest" \;
# delete them from iphoto_source
find -E "$iphoto_source" -iregex ".*\.(jpg|gif|png|jpeg)" -delete
# AFTER Uploding to Google Photos - Delete 
echo AFTER Uploding to a safe place. Press any keey to delete?
read varname
echo Deleteing from $from_iphoto_dest
find -E "$from_iphoto_dest" -iregex ".*\.(jpg|gif|png|jpeg)" -delete
echo Finished
##########################################################
#               CLEANUP
##########################################################
unset T_VER
# End of script