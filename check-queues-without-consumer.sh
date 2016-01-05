#!/bin/bash


set -e
#set -x

verbose=false

CONFIG_FILE=~/rabbitmq-client-config.yml

while test $# -gt 0; do
    case "$1" in
       --config)
            shift
            CONFIG_FILE=$1
            shift
            ;;
        *)
            echo "Unsupported option $1"
            break
            ;;
    esac
done

if test ! -f "$CONFIG_FILE"
then
    echo "Config file not found : $CONFIG_FILE"
    exit 32
fi

ADMIN_USER=$(cat $CONFIG_FILE | shyaml get-value auth.username)
ADMIN_PASSWORD=$(cat $CONFIG_FILE | shyaml get-value auth.password)

RABBITMQ_REMOTE_HOST=$(cat $CONFIG_FILE | shyaml get-value server.host)
RABBITMQ_API_PORT=$(cat $CONFIG_FILE | shyaml get-value server.port)

USE_SSL=$(cat $CONFIG_FILE | shyaml get-value transport.ssl)
if test "$USE_SSL" == "True"
then
    SSL_OPTION="--ssl"
fi

echo "Querying RabbitMQ Server for queues info ..."

QUEUES_DATA=$(./rabbitmqadmin ${SSL_OPTION} -u ${ADMIN_USER} -p "${ADMIN_PASSWORD}" -H ${RABBITMQ_REMOTE_HOST} -P ${RABBITMQ_API_PORT} list queues -f kvp vhost name messages consumers idle_since)

echo "Found" $(echo "$QUEUES_DATA" | grep "vhost" | wc -l) "existing queues"

QUEUES_WITHOUT_CONSUMER=$(echo "$QUEUES_DATA" | grep "consumers=\"0\"")

EMPTY_QUEUES_WITHOUT_CONSUMER=$(echo "$QUEUES_WITHOUT_CONSUMER" | grep "messages=\"0\"" || true)
NON_EMPTY_QUEUES_WITHOUT_CONSUMER=$(echo "$QUEUES_WITHOUT_CONSUMER" | grep -v "messages=\"0\"" || true)

# filter trailing empty line using : sed '/^\s*$/d'
EMPTY_QUEUES_WITHOUT_CONSUMER_COUNT=$(echo "$EMPTY_QUEUES_WITHOUT_CONSUMER" | sed '/^\s*$/d' | wc -l)
NON_EMPTY_QUEUES_WITHOUT_CONSUMER_COUNT=$(echo "$NON_EMPTY_QUEUES_WITHOUT_CONSUMER" | sed '/^\s*$/d' | wc -l)

echo ""
echo "Empty queues without any consumers : (WARNING level = LOW) : $EMPTY_QUEUES_WITHOUT_CONSUMER_COUNT"
echo "$EMPTY_QUEUES_WITHOUT_CONSUMER"

echo ""
echo "Non-empty queues without any consumers :  (WARNING level = HIGH): $NON_EMPTY_QUEUES_WITHOUT_CONSUMER_COUNT"
echo "$NON_EMPTY_QUEUES_WITHOUT_CONSUMER"

echo ""

EXIT_STATUS=0
#if test $EMPTY_QUEUES_WITHOUT_CONSUMER_COUNT -gt 0
#then
#	EXIT_STATUS=$((EXIT_STATUS + 1))
#fi
if test $NON_EMPTY_QUEUES_WITHOUT_CONSUMER_COUNT -gt 0
then
	EXIT_STATUS=$((EXIT_STATUS + 2))
fi

echo "EXIT_STATUS = $EXIT_STATUS"
exit $EXIT_STATUS

