#
# Regular cron jobs for the onetime package
#
0 4	* * *	root	[ -x /usr/bin/onetime_maintenance ] && /usr/bin/onetime_maintenance
