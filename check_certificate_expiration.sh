#!/bin/bash
# NMS - 10/07/2019 - 20/02/2020

# Required:
# domain_list.txt: containig all domains to check
#
# Sintaxis:
#
# check_certificate_expiration.sh [-v] { -u URL | -f FILE_WITH_URLS } [-s EMAIL_TO] [ -r REPORT_FILE ]
# If -s and -r are specified report is sent on HTML format otherwise if -s is only specified report is sent in text format.
#
# Must be defined:
#
# -v: VERBOSE
# -u: URL
# -f: FILE WITH URL
# -s SEND ADDRESS
# -r GENERATE REPORT (HTML FORMAT)
# -

# Variables
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenda=`tput setaf 5`
cyan=`tput setaf 6`
reset=`tput sgr0`
AWKCONFIG="./html.awk"

# PARAMETERS LOAD

while getopts :vu:f:s:r:d: option; do
  case $option in
    v) VERBOSE=1
      ;;
    u) URL=$OPTARG
	[[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} URL: specified $URL ${reset}"
      ;;
    f) FILE=$OPTARG
	[[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} FILE specified $FILE ${reset}"
      ;;
    s) ADDRESS=$OPTARG
	[[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} Destination ADDRESS specified $ADDRESS ${reset}"
      ;;
    r) REPORT=$OPTARG
	[[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} REPORTS specified $REPORT ${reset}"
      ;;
    d) DAEMON=$OPTARG
  [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} Daemon mode specified $DAEMON ${reset}"
      ;;
  esac
done

# // Function
check_fqdn(){
  echo "${cyan}Checking domain ${green} $1"
  getent hosts $1 > /dev/null
  case $? in
    0)  EXPDATE=$(echo | openssl s_client -servername $1 -connect $1:443 2>/dev/null | openssl x509 -noout -enddate)
  	EXPDATE=$(echo $EXPDATE | cut -d'=' -f2)
  	ENDDATE=$(date -d "$EXPDATE" +%s)
  	TODAY=$(date +%s)

  	if [ "$TODAY" -ge "$ENDDATE" ]; then
   	  echo "${yellow}EXPIRED!!!!";
   	  echo "${reset}CERTIFICATE IS EXPIRED! ${red} Expiration date: $EXPDATE"
   	[[ $REPORT ]] && echo "$1 -> <font color="red">EXPIRED!!!</font> $EXPDATE" >> $OUTPUT
  	else
   	  echo "${reset} Expiration date: $EXPDATE"
   	  [[ $REPORT ]] && echo "$1 -> <font color="black"> $EXPDATE </font>" >> $OUTPUT
  	fi
	;;
    2)  echo "${yellow}UNKNOWN DOMAIN $1!!!!"
	[[ $REPORT ]] && echo "$1 -> <font color="red">UNKOWN DOMAIN!!!</font>" >> $OUTPUT
        ;;
    *)  echo "${yellow}UNKNOWN DNS ERROR $1!!!!"
        [[ $REPORT ]] && echo "$1 -> <font color="red">UNKNOWN DNS ERROR!!!</font>" >> $OUTPUT
        ;;
  esac
  [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} Resolved domains: $(getent hosts $1)"
  echo ${reset}
}

start_server() {
  while true; do
    cat /tmp/index.http | nc -lp 8000; 
    sleep 1
  done
}

# // Main

if [ -z $URL ] && [ -z $FILE ]; then
  echo "${red}[ERROR]${yellow} No vamos bien, tu te has mirado el manual ? o me dices una URL o me dices un fichero con URLs pero quieres que me las invente?"
  echo "${green}Sintaxis:"
  echo "${reset}check_certificate_expiration [-v] ${yellow} [-u URL | -f FILE_WITH_URLS]  ${reset} [-s EMAIL_TO] [ -r REPORT_FILE ]"
  exit 1
fi

OUTPUT="/tmp/index.http"
echo "" > $OUTPUT 

if [ $REPORT ]; then
  [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG]${yellow} Generating report header on $REPORT  ${reset}"
  echo  > $REPORT
  echo "HTTP/1.1 200 OK
        Content-Type: text/html; charset=UTF-8
        Server: netcat!

        <!doctype html>
        <html>
        <head>
         <style>
             TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
             TR:Hover TD {Background-Color: #C1D5F8;}
             TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
             TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
             .odd  { background-color:#ffffff; }
             .even { background-color:#dddddd; }
         </style>
        <title>
           Domain certificate status
        </title>
        </head>" > $REPORT
fi

if [ -r "$FILE" ]; then
 [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG]${yellow} Checking file ${reset}"
 for i in `cat $FILE` ; do
  check_fqdn $i
 done
 else
  check_fqdn $URL
fi

if [ ! -z $REPORT ]; then
   awk -f $AWKCONFIG $OUTPUT >> $REPORT
   echo "</html>" >> $REPORT
fi

#if [ $DAEMON ]; then 
  start_server 
#fi
