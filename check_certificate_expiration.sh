#!/bin/bash
# NMS - 10/07/2019 - 20/02/2020

# Required:
# domain_list.txt: containig all domains to check
#
# Sintaxis:
#
# check_certificate_expiration.sh [-v] { -u URL | -f FILE_WITH_URLS } [-m EMAIL_TO] [ -r REPORT_FILE ]
# If -s and -r are specified report is sent on HTML format otherwise if -s is only specified report is sent in text format.
#
# Must be defined:
#
# -v: VERBOSE
# -u: URL
# -f: FILE WITH URL
# -m SEND ADDRESS
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
TIMEPAUSE=0

# PARAMETERS LOAD

while getopts :vsu:f:m:r:t: option; do
  case $option in
    v) VERBOSE=1
      [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} VERBOSE mode ON ${reset}"
      ;;
    u) URL=$OPTARG
      [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} URL: specified $URL ${reset}"
      ;;
    f) FILE=$OPTARG
      [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} FILE specified $FILE ${reset}"
      ;;
    m) ADDRESS=$OPTARG
      [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} Destination ADDRESS specified $ADDRESS ${reset}"
      ;;
    r) REPORT=$OPTARG
      [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} REPORTS specified $REPORT ${reset}"
      ;;
    t) TIMEPAUSE=$OPTARG
      [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} PAUSE BETWEEN CHECKS SET TO $TIMEPAUSE SECONDS ${reset}"
      ;;
    s)  DAEMON=1
       REPORT=/tmp/report.html
      [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} DAEMON mode ON ${reset}"
      ;;
  esac
done

# // Function
generate_report_header() {
 [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG]${yellow} Generating report header on $REPORT  ${reset}"
   echo "<!doctype html>
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
}

check_fqdn(){
  echo "${cyan}Checking domain ${green} $1"
  getent hosts $1 > /dev/null
  case $? in
    0)  EXPDATE=$(timeout 5 openssl s_client -servername $1 -connect $1:443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d'=' -f2)
        [[ -z "$EXPDATE" ]] && echo "${red}[ERROR]${yellow} Timeout reached, Unable to retrieve certificate information on 5 seconds" && return -1
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


	[[ ! -z $VERBOSE ]] && echo "ISSUER: $(openssl s_client -servername $1 -connect $1:443 2> /dev/null | openssl x509 -noout -issuer 2> /dev/null)"
}

# // Main

if [ -z $URL ] && [ -z $FILE ]; then
  echo "${red}[ERROR]${yellow} you're not in the right path, have you read the manual ? Either you tell me an URL or you give me a file path, you want me to make it up ?" 
  echo "${red}[ERROR]${yellow} No vamos bien, tu te has mirado el manual ? o me dices una URL o me dices un fichero con URLs pero quieres que me las invente?"
  echo "${green}Sintaxis:"
  echo "${reset}check_certificate_expiration [-v] ${yellow} [-u URL | -f FILE_WITH_URLS]  ${reset} [-s EMAIL_TO] [ -r REPORT_FILE ] [ -t SECONDS_PAUSE_BETWEEN_DOMAINS]"
  exit 1
fi

if [ $REPORT ] || [ $DAEMON ]; then
  OUTPUT="/tmp/tempfile"
  echo "" > $OUTPUT
  generate_report_header
fi

if [ -r "$FILE" ]; then
  [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG]${yellow} Checking URLs on file $FILE ${reset}"
  for i in `cat $FILE` ; do
    check_fqdn $i
    sleep $TIMEPAUSE
  done
  [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG]${yellow} All domains checked ${reset}"
  else
    check_fqdn $URL 
fi

if [ ! -z $REPORT ]; then   # HTML Report formatting
   [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG]${yellow} formatting $REPORT file ${reset}"
   awk -f $AWKCONFIG $OUTPUT >> $REPORT
   echo "</html>" >> $REPORT
   [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG]${yellow} $REPORT created ${reset}"
fi

if [ $DAEMON ]; then 
  [[ ! -z $VERBOSE ]] && echo "${cyan}[DEBUG] ${green} Starting daemon ${reset}"
  echo "HTTP/1.1 200 OK

        " > /tmp/tempfile
  cat $REPORT >> /tmp/tempfile
  mv /tmp/tempfile $REPORT

  while [ 1 ]; do
    nc -l -p 8080 < $REPORT   
  done
fi
