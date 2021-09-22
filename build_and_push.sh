#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
set -eu
DOCKERHUB_USER=${DOCKERHUB_USER:="apache"}
DOCKERHUB_REPO=${DOCKERHUB_REPO:="airflow"}
PGBOUNCER_EXPORTER_VERSION="0.12.0"
AIRFLOW_PGBOUNCER_EXPORTER_VERSION="2021.09.22"
EXPECTED_GO_VERSION="1.17"
COMMIT_SHA=$(git rev-parse HEAD)

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

CURRENT_GO_VERSION=$("go${EXPECTED_GO_VERSION}" version 2>/dev/null | awk '{ print $3 }' 2>/dev/null || true)

if [[ ${CURRENT_GO_VERSION} == "" ]]; then
  CURRENT_GO_VERSION=$(go version 2>/dev/null | awk '{ print $3 }' 2>/dev/null)
  GO_BIN=$(command -v go 2>/dev/null || true)
else
  GO_BIN=$(command -v go${EXPECTED_GO_VERSION} 2>/dev/null)
fi

if [[ ${CURRENT_GO_VERSION} == "" ]]; then
  echo "ERROR! You have no go installed"
  echo
  echo "Please install go${EXPECTED_GO_VERSION} to build the package"
  echo
  echo "You need to have golang installed. Follow https://golang.org/doc/install"
  echo
fi

if [[ ${CURRENT_GO_VERSION} != "go${EXPECTED_GO_VERSION}" ]]; then
  echo "ERROR! You have unexpected version of go in the path ${CURRENT_GO_VERSION}"
  echo
  echo "Make sure you have go${EXPECTED_GO_VERSION} installed:"
  echo
  echo "   go get golang.org/dl/go${EXPECTED_GO_VERSION}"
  echo
  echo "   go${EXPECTED_GO_VERSION} download"
  echo
  echo "You might need to add ${HOME}/go/bin to your PATH"
  echo
  exit 1
fi


# Needs to be set for alpine images to run net package of GO
export CGO_ENABLED=0
rm -f pgbouncer_exporter 2>/dev/null

"${GO_BIN}" get ./...
"${GO_BIN}" build

TAG="${DOCKERHUB_USER}/${DOCKERHUB_REPO}:airflow-pgbouncer-exporter-${AIRFLOW_PGBOUNCER_EXPORTER_VERSION}-${PGBOUNCER_EXPORTER_VERSION}"

docker build . \
    --pull \
    --build-arg "PGBOUNCER_EXPORTER_VERSION=${PGBOUNCER_EXPORTER_VERSION}" \
    --build-arg "AIRFLOW_PGBOUNCER_EXPORTER_VERSION=${AIRFLOW_PGBOUNCER_EXPORTER_VERSION}"\
    --build-arg "COMMIT_SHA=${COMMIT_SHA}" \
    --build-arg "GO_VERSION=${CURRENT_GO_VERSION}" \
    --tag "${TAG}"

docker push "${TAG}"
