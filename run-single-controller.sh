#! /bin/bash
source .env


mkdir -p $CONTROLLER_PERSISTENCE
chmod 777 $CONTROLLER_PERSISTENCE
#  -e JENKINS_OPTS="--accessLoggerClassName=winstone.accesslog.SimpleAccessLogger --simpleAccessLogger.format=combined --simpleAccessLogger.file=/var/jenkins_home/access.log" \
#  -v /var/run/docker.sock:/var/run/docker.sock \
#  -e JAVA_OPTS="-Dcore.casc.config.bundle=/var/jenkins_home/core-casc-bundle" \
docker run \
  -e JAVA_OPTS="$CONTROLLER_JAVA_OPTS" \
  -e JENKINS_OPTS="$CONTROLLER_JENKINS_OPTS" \
  -u root \
  --rm \
  -p 8080:8080 \
  -v $CONTROLLER_PERSISTENCE:/var/jenkins_home \
  -v $CONTROLLER_CASC_BUNDLE_PATH_LOCAL:$CONTROLLER_CASC_BUNDLE_PATH_CONTAINER \
  cloudbees/cloudbees-core-cm:$CB_VERSION
