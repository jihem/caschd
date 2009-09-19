CaSchd.rb is a Network Monitoring Tool : TCP Ping, HTTP, DNS, Mail (send & receive),
Heartbeat, ... Send mails to a users list (with specific time periods,
events, ...)

Web sites :
- http://wdwave.dnsalias.com/caschd
- http://github.com/jihem/caschd

WARNING :
You can remove the '#' before the 'dbry' key in caschd.conf to use the red threads model.
The red threads model provides real time performance without having to worry about system calls.
(see http://ph7spot.com/articles/system_timer for more explanation about green threads limits)

Red threads mode increase CPU load (up to 41 simultaneous process).
It's recommanded to use green threads mode on slow or no dedicated computer.

Red threads mode use Kernel.fork to start the subprocesses.
Unfortunately Windows doesn’t support the fork command.
Windows users can only use green threads mode or must install cygwin (http://www.cygwin.com).
Which is really useful to (poor) users who are restricted to Windows.