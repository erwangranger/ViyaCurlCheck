#!/bin/bash

## any bad return code will be lethal:
set -e

# the version
viyacurlcheck_Version="Beta 0.003"


# Displays the Documentation
function usage() {
    printf "
####################################################################
## viyacurlcheck: Check if Viya Health Endpoints are responding   ##
####################################################################
## Version      : ${viyacurlcheck_Version}                        ##
####################################################################

  -h|--help|--doc
    ## display the documentation

  --version
     ## display the version of this script

  (---required---)

    -u|--url-list \"http://server/SASDrive https://server/SASLogon/\"
        ## one or more Viya urls to check
        ## use space as a separator and surround by quotes
        ## for info on how to get a complete list of URLs for Viya 3.X, consult
        ## <placeholder>

  (---optional---)

    -o|--output-type (none|csv)
        ## this option will determine what type of output the script creates
        ## default is none

    --retry-gap <10s>
        ## how many seconds to wait before re-trying

    --max-retries <0 = unlimited>
        ## how many times to retry

    --min-success-rate (percentage)
        ## The minimum desired success rate in percentage
        ## Setting this to 101 would make it run forever

    --timings yes|no
        ## capture curl timing as well (slower)

    -d|--debug
        ## enable debugging options

"
}



## display doc if no parameters are passed at all
if [ $# -eq 0 ]  ; then
    usage
    exit 0
fi

## Parameters
while [[ $# -gt 0 ]]; do
    key="$1"
    case ${key} in
        -h|--help|--doc)
            shift
            usage
            exit 0
            ;;
        -v|--version)
            shift
            echo -e "## viyacurlcheck version: ${viyacurlcheck_Version}  "
            exit 0
            ;;
        --max-retries)
            shift
            MAX_RETRIES="$1"
            shift
            ;;
        --min-success-rate )
            shift
            MIN_SUCCESS_RATE="$1"
            shift
            ;;
        --retry-gap )
            shift
            RETRY_GAP="$1"
            shift
            ;;
        -u|--url-list)
            shift
            URL_LIST="$1"
            shift
            ;;
        -o|--output-type)
            shift
            OUTPUT_TYPE="$1"
            shift
            ;;
        -d|--debug)
            shift
            DEBUG=1
            ;;
        --timings)
            shift
            TIMINGS="yes"
            ;;
        *)
            usage
            echo -e "\n\nOne or more arguments were not recognized: \n$@"
            echo
            exit 1
            shift
    ;;
    esac
done

## ask for a URL if none was provided
if [[ "${URL_LIST}" == "" ]] ; then
    echo -e "You did not provide a URL list"
    echo -e "Ctrl-C to Cancel and try again (with the -u parameter)."
    echo -e "Or enter the URL at the prompt below:"
    URL_LIST=${URL_LIST:-$(read -p "URL to check: " x && echo "$x")}
    echo -e "You entered: ${URL_LIST}"
    echo -e "continuing...."
fi

# display more things when debugging
function debug_out () {
    if [[ ${DEBUG} == 1 ]]; then
    echo -e "DEBUG: $1"
    fi
}

## assigning default values
OUTPUT_TYPE=${OUTPUT_TYPE:-none}     ## none or csv
RETRY_GAP=${RETRY_GAP:-10}               ## How many seconds to sleep between retries
MIN_SUCCESS_RATE=${MIN_SUCCESS_RATE:-95}
MAX_RETRIES=${MAX_RETRIES:-0}         ## set to 0 for unlimited
TIMINGS=${TIMINGS:-no}


debug_out 'the debugging has ben turned on'
debug_out "URL_LIST=${URL_LIST}"
debug_out "OUTPUT_TYPE=${OUTPUT_TYPE}"
debug_out "RETRY_GAP=${RETRY_GAP}"
debug_out "MIN_SUCCESS_RATE=${MIN_SUCCESS_RATE}"
debug_out "MAX_RETRIES=${MAX_RETRIES}"
debug_out "TIMINGS=${TIMINGS}"

# this is a curl with the timing turned on
function curltime(){
curl -k -w @- -o /dev/null -s "$@" <<'EOF'
%{time_namelookup},%{time_connect},%{time_appconnect},%{time_pretransfer},%{time_redirect},%{time_starttransfer},%{time_total}
EOF
}

check_urls () {

    if [[ "${URL_LIST}" == "" ]] ; then
        echo -e "No URL list provided. Exiting"
        exit 1
    fi

    echo -e "Using curl to check the following urls: (-u \"${URL_LIST}\")"

    local SUCC_RATE=0
    local RETRIES=0
    local HEALTH_SUFFIX="commons/health"
    ## CSV-friendly date format

    until [[ $SUCC_RATE -ge $MIN_SUCCESS_RATE ]];
    do
        local URL_HTTP_CODE=0
        local URL=0
        local URL_PASS_FAIL=""
        local COUNT_FAIL=0
        local COUNT_SUCC=0
        local URL_COUNTER=0

        RETRIES=$[$RETRIES +1]

        local date_csv=$(date '+%Y-%m-%d %H:%M:%S')

        ## print csv header
        if [[ "$OUTPUT_TYPE" == "csv" ]] && [[ $RETRIES -eq 1 ]] ; then
            printf "CSV,Retry Number,Date,Pass/Fail,HTTP Code,URL Checked"
            if [[ "$TIMINGS" == "yes" ]]; then
                printf ",time_namelookup,time_connect,time_appconnect,time_pretransfer,time_redirect,time_starttransfer,time_total"
            fi
            printf "\n"
        fi

        ## loop through URLs
        for url in ${URL_LIST[@]};
        do

            # remove trailing slash from url
            url=$( echo "$url" | sed  -e 's#/$##' )

            debug_out "each url: ${url}"

            # if the url does not contain the health suffix, add it in
            if ! [[ "$url" == *${HEALTH_SUFFIX} ]]
            then
                url="${url}/${HEALTH_SUFFIX}"
            fi

            debug_out "each url, with health suffix: ${url}"


            URL_COUNTER=$[$URL_COUNTER +1]
            URL=${url%$'\r'}
            URL_HTTP_CODE=$(curl -k -s -o /dev/null -w '%{http_code}' $URL  | tr -d '[:space:]' )

            if [[ "$URL_HTTP_CODE" =~ ^(200)$ ]]; then
                URL_PASS_FAIL="Success"
                COUNT_SUCC=$[$COUNT_SUCC +1]
            else
                URL_PASS_FAIL="Failure"
                COUNT_FAIL=$[$COUNT_FAIL +1]
            fi

            if [[ "$OUTPUT_TYPE" == "csv" ]]; then
                printf "CSV,${RETRIES},${date_csv},${URL_PASS_FAIL},${URL_HTTP_CODE},${url}"
                if [[ "$TIMINGS" == "yes" ]]; then
                    TIMING_INFO=$(curltime $URL)
                    printf ",${TIMING_INFO}"
                fi
                printf "\n"
            fi

        done

        #SUCC_RATE=$(echo "scale=2 ; $COUNT_SUCC / $URL_COUNTER * 100" | bc | awk '{print int($1+0.5)}' )
        SUCC_RATE=$(( (${COUNT_SUCC} * 100) / ${URL_COUNTER} ))


        echo -e "Number of URLs checked: $URL_COUNTER "
        echo -e "Number of URLs working: $COUNT_SUCC "
        echo -e "Number of URLs failing: $COUNT_FAIL"
        echo -e "Success rate (percent): $SUCC_RATE"

        if [ "$SUCC_RATE" -lt "$MIN_SUCCESS_RATE" ];    then
            echo -e "Success Rate ($SUCC_RATE %) is lower than the requested minimum (--min-success-rate $MIN_SUCCESS_RATE) % "
            if [[ $RETRIES -ge $MAX_RETRIES && $MAX_RETRIES -ne 0 ]]; then
                echo -e "Reached Maximum number of tries (--max-retries $MAX_RETRIES) before minimum success rate (--min-success-rate $MIN_SUCCESS_RATE )%. Exiting."
                exit $COUNT_FAIL
            fi
            echo -e "This was try # ${RETRIES}. Trying again in (--retry-gap $RETRY_GAP) seconds, up to (--max-retries $MAX_RETRIES) times.  "
            sleep $RETRY_GAP
        fi
    done

    if [ "$SUCC_RATE" -ge "$MIN_SUCCESS_RATE" ];    then
        echo -e "Success Rate ($SUCC_RATE %) is greater or equal than requested minimum (--min-success-rate $MIN_SUCCESS_RATE) % "
        exit 0
    fi

}

check_urls
