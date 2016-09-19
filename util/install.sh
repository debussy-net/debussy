#!/usr/bin/env bash

# Fail on error
set -e

# Fail on unset var usage
set -o nounset

SRC_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd -P )"
MN_VERSION="2.2.0"

DIST=Unknown
test -e /etc/debian_version && DIST="Debian"
grep Ubuntu /etc/lsb-release &> /dev/null && DIST="Ubuntu"
if [ "$DIST" = "Ubuntu" ] || [ "$DIST" = "Debian" ]; then
    install='sudo apt-get -y install'
    update='sudo apt-get update'
    remove='sudo apt-get -y remove'
    pkginst='sudo dpkg -i'
    addrepo='sudo apt-add-repository -y'
else
    echo "Only Ubuntu and Debian supported!"
    exit
fi

function all {
    printf 'installing all...\n' >&2
    echo "Install dir:" $SRC_DIR
    mininet
    postgres
    debussy
}

function mininet {
    echo "Installing mininet..."
    $update
    $install --quiet git

    cd "$SRC_DIR"
    git clone git://github.com/mininet/mininet
    cd mininet
    git checkout $MN_VERSION
    ./util/install.sh -kmnvp
    cd "$SRC_DIR"

}

function postgres {
    $install postgresql
}

function debussy {
    $install python2.7 python-pip python-dev build-essential
    sudo pip install sqlalchemy sqlparse tabulate sysv_ipc

    $addrepo ppa:georepublic/pgrouting
    $update
    $install postgresql-contrib postgresql-client \
	python-psycopg2 python-igraph postgis postgresql-plpython-9.3 \
	postgresql-9.3-pgrouting postgresql-9.3-plsh

    sudo -u postgres psql -c "CREATE DATABASE debussy;"
    sudo -u postgres psql -c "CREATE USER debussy WITH SUPERUSER;"
    sudo -u postgres psql -c "ALTER USER debussy WITH PASSWORD 'debussy';"
    sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS plpythonu;"
    sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS postgis;"
    sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS pgrouting;"

    printf -- '\n\n' >&2
    printf -- 'Debussy requires either "trust" or "md5" authentication for\n' >&2
    printf -- '"postgres" and "all" users in PostgreSQL.  Please modify\n' >&2
    printf -- 'the file /etc/postgresql/9.3/main/pg_hba.conf to:\n' >&2
    printf -- '     local    all    postgres    trust  #or md5\n' >&2
    printf -- '     local    all    all         trust  #or md5\n\n' >&2

    printf -- 'Or, choose yes below to automatically set to trust.\n' >&2
    read -p "Set authentication method to 'trust'? [y/N] " response
    response=${response,,}
    if [[ $response =~ ^(yes|y) ]]; then
	sudo sed -i -e '/^local/s/peer/trust/g' /etc/postgresql/9.3/main/pg_hba.conf
	sudo service postgresql restart
    fi
}

function usage {
    printf '\nUsage %s [-amprh]\n\n' $(basename $0) >&2

    printf 'Install and setup Debussy and its dependencies.\n\n' >&2

    printf 'options:\n' >&2
    printf -- ' -a: install (A)ll packages\n' >&2
    printf -- ' -m: install (Mininet) (with flags -kmnvp\n' >&2
    printf -- ' -p: install (P)ostgreSQL database\n' >&2
    printf -- ' -r: install (R)avel libraries and configure PostgreSQL\n' >&2
    printf -- ' -h: print this (H)elp message\n\n' >&2
}

if [ $# -eq 0 ]
then
    usage
else
    while getopts 'amprh' OPTION
    do
	case $OPTION in
	        a) all;;
	        m) mininet;;
	        p) postgres;;
	        r) debussy;;
	        h) usage;;
	    esac
    done
    shift $(($OPTIND - 1))
fi
