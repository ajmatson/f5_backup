#!/bin/bash
#
# Off box backup script for HHSC F5 BigIPs. 
# Created by Alan Matson (alan.matson@hhsc.state.tx.us)
#
# Place in /admin/home/f5_backup.sh
# Run with a cronjob at 2300 daily: "* 23 * * * /home/admin/home/f5_backup.sh > /dev/null"
#
# Local UCS Files will be saved to /var/local/ucs/
# Local SCF Files will be saved to /var/local/scf/
#
# To do: Create a local log
#        Enable email support for failed notifications
#        Possibly make an automated installer.


# Set initial variables, change as needed to suite your deployment
scpEnabled=0  #To enable copy of files via SCP (Must use SSH keys and disabled by default). / 0=Disabled, 1=Enabled
deleteOld=1   #Enables or disables deleting old files to save local disk space (Recommended and on by default) / 0=Disabled, 1=Enabled
deleteDays=15 # Number of days to keep old files.

#Define SCP Paramaters:
scpUser='ajmatson'
scpKey='/root/.ssh/id_rsa'  #SSH Keys need to be generated and exchanged before this will work.
scpServer='192.168.1.125'
scpDirectory='/home/ajmatson/F5_Backups/'





##### DO NOT MODIFY BELOW THIS LINE OR THE SCRIPT MAY FAIL #####
dateTime="`date +%Y_%m_%d`"
hostName=`echo $HOSTNAME | awk -F. '{print $1}'`
 
saveFilename="${dateTime}_$hostName"
#echo $saveFilename
tmsh save sys ucs "${saveFilename}"
tmsh save sys config file "${saveFilename}.scf" no-passphrase
 
if [ $deleteOld=1 ]; then
    find /var/local/ucs/ -mtime +$deleteDays -delete
    find /var/local/ucs/ -mtime +$deleteDays -delete
fi

if [ scpEnabled=1 ]; then
    scp -c aes256-ctr -i $scpKey /var/local/ucs/$saveFilename.ucs /var/local/scf/$saveFilename.scf.tar $scpUser@$scpServer:$scpDirectory
    if [ $? > 1 ]; then failedSCP=1; fi
fi

if [ $failedSCP=1 ]; then
    echo "SCP Transfer Failed!!!"
fi
