
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


#### Reducing listening services
At the end of verification.sh you might get a large list of services listening. These are usually local ones.
One good example is: Exim. It is on many Debian based systems so local programs can send system mail. If you want to get rid of it:

		sudo apt purge exim4 exim4-base exim4-config exim4-daemon-light
		sudo systemctl disable --now exim4

Another common one is avahi daemon which is used mainly for:

		Network printers
		Scanners
		AirPlay-compatible speakers/TVs / Chromecast discovery
		SSH service discovery (ssh.local)
		File sharing discovery (SMB/AFP on some systems) etc.

Rather than removing it, the best option is to disable the daemon:
		
		sudo systemctl disable --now avahi-daemon

If things start to go wrong, then you will just enable it again:

		sudo systemctl enable --now avahi-daemon

