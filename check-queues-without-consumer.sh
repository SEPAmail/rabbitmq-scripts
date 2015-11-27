#!/bin/bash


set -e
#set -x

verbose=false
#ADMIN_USER=guest
ADMIN_USER=admin
ADMIN_PASSWORD=
RABBITMQ_REMOTE_HOST=localhost
RABBITMQ_API_PORT=15672
SSL_OPTION=""


while test $# -gt 0; do
    case "$1" in
       --host)
            shift
            RABBITMQ_REMOTE_HOST=$1
            shift
            ;;
       --port)
            shift
            RABBITMQ_API_PORT=$1
            shift
            ;;
       --password)
            shift
            ADMIN_PASSWORD=$1
            shift
            ;;
       --ssl)
            shift
            SSL_OPTION="--ssl"
            ;;
        *)
            echo "Unsupported option $1"
            break
            ;;
    esac
done


QUEUES_WITHOUT_CONSUMER=$(./rabbitmqadmin ${SSL_OPTION} -u ${ADMIN_USER} -p "${ADMIN_PASSWORD}" -H ${RABBITMQ_REMOTE_HOST} -P ${RABBITMQ_API_PORT} list queues -f kvp vhost name messages consumers idle_since | grep "consumers=\"0\"")

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

