CaSchd.rb is a Network Monitoring Tool : TCP Ping, HTTP, DNS, Mail (send & receive),
Heartbeat, ... Send mails to a users list (with specific time periods,
events, ...)

Web sites :
- http://wdwave.dnsalias.com/caschd
- http://github.com/jihem/caschd

WARNING :
You can remove the '#' before the 'dbry' key in caschd.conf to use the red threads model.
Red threads mode increase CPU load (up to 41 simultaneous process).
It's recommanded to use green threads mode on slow or no dedicated computer for better performance.