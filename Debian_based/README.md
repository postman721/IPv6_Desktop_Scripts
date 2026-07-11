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

## UFW checks

/etc/default/ufw:

		DEFAULT_INPUT_POLICY="DROP"
		DEFAULT_OUTPUT_POLICY="ACCEPT"
		DEFAULT_FORWARD_POLICY="DROP"

Should look like this on ufw status verbose:
		
		Default: deny (incoming), allow (outgoing), deny or disabled (routed)

If ufw status verbose is correct but the file still lacks those entries, show the output of:

		sudo grep -nE 'DEFAULT_(INPUT|OUTPUT|FORWARD)_POLICY|IPV6' /etc/default/ufw
