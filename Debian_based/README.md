#### Run with:

		chmod 700 ufw_ipv6.sh

		sudo bash ufw_ipv6.sh
		
Check status: 

		sudo ufw status verbose

Check your ipv6 address from cli: 

		ip -6 address show scope global

Log file location example: 

		/var/log/ufw-desktop-report-20260711-211350.log

Old config file location example:

		/etc/default/ufw.backup-20260711-211350 

You might want to consider removing the log and backup files after they are no longer needed. Example command structure:

		sudo rm insert_file_name_here
