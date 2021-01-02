# certificate-monitor
Certificate expiration monitoring system

[sudo] docker build -f Dockerfile -t cert_check .

single domain 
[sudo] docker run  -it cert_check <domain> 

domain list (text file)
cd $HOME
[sudo] docker run -v $HOME/domains.txt:/tmp/domains.txt -it cert_check -f /tmp/domains.txt 

STILL WORK IN PROGRESS! 

Next release Daemon mode
