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

## UFW checks - This is handled by verification.sh script

UFW stores its default policies in `/etc/default/ufw`:

```bash
DEFAULT_INPUT_POLICY="DROP"
DEFAULT_OUTPUT_POLICY="ACCEPT"
DEFAULT_FORWARD_POLICY="DROP"
```

These normally correspond to this output from:

```bash
sudo ufw status verbose
```

```text
Default: deny (incoming), allow (outgoing), deny (routed)
```

Some systems may display:

```text
Default: deny (incoming), allow (outgoing), disabled (routed)
```

Routing or forwarding might also be disabled, which is appropriate for a normal desktop user. See more from verificaton.md .

To check the relevant settings in `/etc/default/ufw`, including IPv6 support, run:

```bash
sudo grep -nE \
'^[[:space:]]*(IPV6|DEFAULT_(INPUT|OUTPUT|FORWARD)_POLICY)[[:space:]]*=' \
/etc/default/ufw
```

Expected values are:

```bash
IPV6=yes
DEFAULT_INPUT_POLICY="DROP"
DEFAULT_OUTPUT_POLICY="ACCEPT"
DEFAULT_FORWARD_POLICY="DROP"
```
