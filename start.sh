#!/bin/bash

set -euo pipefail

JAVA_AGENT=''

APP_OPTS=""
if [ "" != "${DEBUG_ADDRESS:-}" ]; then
    APP_OPTS="-agentlib:jdwp=transport=dt_socket,server=n,address=${DEBUG_ADDRESS},suspend=y"
fi

APP_OPTS="${APP_OPTS} -Dspring.profiles.active=${OPBEANS_JAVA_PROFILE:-}"
APP_OPTS="${APP_OPTS} -Dserver.port=${OPBEANS_SERVER_PORT:-}"
APP_OPTS="${APP_OPTS} -Dserver.address=${OPBEANS_SERVER_ADDRESS:-0.0.0.0}"
APP_OPTS="${APP_OPTS} -Dspring.datasource.url=${DATABASE_URL:-}"
APP_OPTS="${APP_OPTS} -Dspring.datasource.driverClassName=${DATABASE_DRIVER:-}"
APP_OPTS="${APP_OPTS} -Dspring.jpa.database=${DATABASE_DIALECT:-}"

case "${APM_AGENT_TYPE:-none}" in
    "opentelemetry")
        JAVA_AGENT="-javaagent:/app/opentelemetry-javaagent.jar"
        APP_OPTS="${APP_OPTS} -Dotel.instrumentation.runtime-metrics.enabled=true"
        ;;
    "elasticapm")
        JAVA_AGENT="-javaagent:/app/elastic-apm-agent.jar"
        ;;
    "none")
        JAVA_AGENT=""
        ;;
    *)
        echo "unknown agent type $APM_AGENT_TYPE"
        exit 1
        ;;
esac

export OTEL_EXPORTER_OTLP_ENDPOINT=https://a5f902e40963480292686d47af76ba4a.apm.us-west-2.aws.cloud.es.io:443
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer rWNpu0sXwsIlBXWavq"
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_RESOURCE_ATTRIBUTES=service.name=java,deployment.environment=production

java \
    ${JAVA_AGENT} \
    ${APP_OPTS} \
    -jar ./app.jar
