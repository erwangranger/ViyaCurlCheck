# `viyacurlcheck`

`viyacurlcheck` is a script that helps assess the status of Viya based on its health endpoint return codes

## What it does

* Checks all the health endpoints of a Viya Deployment to ensure they are all "healthy"
* If the number of healthy endpoints is below a specified threshold, the program exits with an error code
* Optionally outputs CSV statistics

## QuickStart

### Install

Choose one:

* Globally:

    ```bash
    # Ensure you have curl installed
    sudo yum install curl -y

    ## where it's coming from
    RAW_URL=https://raw.githubusercontent.com/erwangranger/ViyaCurlCheck/master/viyacurlcheck.sh

    ## where it's going to
    DEST_PATH=/usr/local/bin/viyacurlcheck

    ## Install
    sudo curl -fsSL ${RAW_URL} -o ${DEST_PATH}

    ## Make executable
    sudo chmod a+x ${DEST_PATH}

    ## confirm version
    viyacurlcheck --version

    ```

* Locally (no sudo):

    ```bash
    ## where it's coming from
    RAW_URL=https://raw.githubusercontent.com/erwangranger/ViyaCurlCheck/master/viyacurlcheck.sh

    ## where it's going to
    DEST_PATH=~/viyacurlcheck

    ## Install
    curl -fsSL ${RAW_URL} -o ${DEST_PATH}

    ## Make executable
    chmod a+x ${DEST_PATH}

    ## define an alias:
    alias viyacurlcheck="${DEST_PATH}"

    ## confirm version
    viyacurlcheck --version

    ```

### Execution examples

* Display the help for the program:

    ```bash
    viyacurlcheck -h
    ```

* Check that SASDrive is up,

    ```bash
    viyacurlcheck  -u 'https://${my_viyaserver_dot_com}/SASDrive https://${my_viyaserver_dot_com}/SASLogon'
    ```

* Check that SASLogon is up, and if not, try 10 times, 30 seconds apart:

    ```bash
    viyacurlcheck  -u 'https://${my_viyaserver_dot_com}/SASLogon' \
        --max-retries 10 \
        --retry-gap 30 \
    ```

* Check 10 different URLs until 80% of them are up:

    ```bash
    h=https://${my_viyaserver_dot_com}
    viyacurlcheck  -u "${h}/SASDrive \
                        ${h}/SASLogon \
                        ${h}/SASReportViewer \
                        ${h}/SASStudio \
                        ${h}/SASThemeDesigner \
                        ${h}/SASVisualAnalytics \
                        ${h}/SASWorkflowManager \
                        ${h}/SASDataExplorer \
                        ${h}/SASDecisionManager \
                        ${h}/SASEnvironmentManager " \
                    --min-success-rate 80
    ```

## How do I know what URLs to pass?

### Viya 3.X

1. If you are using Viya 3.X, place yourself in the playbook folder and execute this command:

    ```bash

    ## capture the list of URLs
    MY_URLS=$(ansible httpproxy -m shell -a 'grep ProxyPass /etc/httpd/conf.d/proxy.conf  \
                          | grep -Ev "cas-shared-default-http|jobDefinitions|dagentsrv-shared" \
                          | awk  "{print \"https://$(hostname -f)\" \$2 }" \
                          | sort -u \
                          | tr "\n\r" " " ' \
                          | grep -v CHANGED)

    ## make sure those URLs are as expected:
    echo $MY_URLS

    ```

1. And now, run:

    ```bash
    viyacurlcheck -u "$MY_URLS"

    ```

### From a static file

1. If you are using Viya 3.X, place yourself in the playbook folder and execute this command:

    ```bash
    ## capture the list of in a file, one per line
    ansible httpproxy -m shell -a 'grep ProxyPass /etc/httpd/conf.d/proxy.conf  \
                          | grep -Ev "cas-shared-default-http|jobDefinitions|dagentsrv-shared" \
                          | awk  "{print \"https://$(hostname -f)\" \$2 }" ' \
                          | sort -u \
                          | grep -v CHANGED \
                          > /tmp/urls.txt
    ```

1. This creates the list of URLs in a file (`/tmp/urls.txt`).
1. Edit the file to keep the URLs you are interested in.
1. And now, run (keep the double quotes!):

    ```bash
    viyacurlcheck -u "$(cat  /tmp/urls.txt)"

    ```
