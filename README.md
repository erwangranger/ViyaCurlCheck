# `viyacurlcheck`

`viyacurlcheck` is a script that helps assess the status of Viya based on its health endpoint HTTP return codes

* [What `viyacurlcheck` does](#what-viyacurlcheck-does)
* [QuickStart](#quickstart)
  * [Install `viyacurlcheck`](#install-viyacurlcheck)
    * [Globally (using sudo):](#globally-using-sudo)
    * [Locally (without sudo):](#locally-without-sudo)
  * [Usage examples](#usage-examples)
* [How do I know what URLs to pass?](#how-do-i-know-what-urls-to-pass)
  * [Viya 3.X](#viya-3x)
  * [From a static file](#from-a-static-file)
* [Integrating with third-party tools](#integrating-with-third-party-tools)
  * [In general](#in-general)
  * [Jenkins](#jenkins)
  * [Other](#other)

## What `viyacurlcheck` does

* Checks one or more of the health endpoints of a Viya Deployment to ensure they are all responding
* If the number of healthy endpoints is below a specified threshold, the program either:
  * exits with an error code
  * waits and retry until success
* Optionally outputs CSV statistics

## QuickStart

### Install `viyacurlcheck`

Choose one:

#### Globally (using sudo):

* If you want to install it on a Linux server to be used easily by all users:

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

#### Locally (without sudo):

* If you prefer to install it in a specific location, to be available to a specific user:

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

### Usage examples

* Display the help for the program:

    ```bash
    viyacurlcheck -h

    ```

* Check that SASDrive and SASLogon are both up,

    ```bash
    viyacurlcheck  -u "https://${my_viyaserver_dot_com}/SASDrive https://${my_viyaserver_dot_com}/SASLogon"

    ```

* Check that SASLogon is up, and if not, try up to 10 times, 30 seconds apart:

    ```bash
    viyacurlcheck  -u "https://${my_viyaserver_dot_com}/SASLogon" \
        --max-retries 10 \
        --retry-gap 30

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

* Check the status for SASLogon, every minute, forever, and output details CSV information:

    ```bash
    viyacurlcheck  -u "https://${my_viyaserver_dot_com}/SASLogon" \
        --max-retries 0 \
        --retry-gap 60 \
        -o csv

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

1. This creates the list of URLs in a file ( execute `cat /tmp/urls.txt` to display its content).
1. Edit the file to keep the URLs you are interested in.
1. And now, run (keep the double quotes!):

    ```bash
    viyacurlcheck -u "$(cat /tmp/urls.txt)"

    ```

## Integrating with third-party tools

### In general

The `viyacurlcheck` script can be leveraged easily from many different third-party tools.

As a simple option, you could for example use `cron` to schedule it on a Linux server, and have it notify you when a relevant event happens.

### Jenkins

If you have a [Jenkins](https://www.jenkins.io/) Server available, this can be a very easy way to quickly make the `viyacurlcheck` script a lot more powerful.

While it's not Jenkins' "raison d'être", it is very good not only at scheduling things, but also very good at notifying you when something important happens!

### Other

TBD...
