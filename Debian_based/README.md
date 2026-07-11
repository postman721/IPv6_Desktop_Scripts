#### Run with:

		chmod 700 ufw_ipv6.sh

		sudo bash ufw_ipv6.sh
		
Check status: 

		sudo ufw status verbose

Check your ipv6 address from cli: 

		ip -6 address show scope global

Old config location example. This only gets created when IPV6 is no or missing.

		/etc/default/ufw.backup-20260711-225725

You might want to consider removing the backup file after it is no longer needed. Example command structure:

		sudo rm insert_file_name_here
