
### This is what you should see after running verification.sh: 

		sudo bash verification.sh

=== Persistent UFW settings ===
IPV6=yes
DEFAULT_INPUT_POLICY="DROP"
DEFAULT_OUTPUT_POLICY="ACCEPT"
DEFAULT_FORWARD_POLICY="DROP"

=== Active UFW policy ===
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), deny or disabled (routed)
New profiles: skip


net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0


Explanation: 0 means false / off here.
