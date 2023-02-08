#!/bin/bash

# Copyright 2020 Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Update the Envoy SHA in istio/proxy WORKSPACE with the first argument (aka ENVOY_SHA) and
# the second argument (aka ENVOY_SHA commit date)

# Exit immediately for non zero status
set -e
# Check unset variables
set -u
# Print commands
set -x

# Update to main as envoyproxy/proxy has updated.
UPDATE_BRANCH=${UPDATE_BRANCH:-"main"}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WORKSPACE=${ROOT}/WORKSPACE
GITLAB_BAZEL=${ROOT}/bazel/gitlab.bzl

# ENVOY_ORG="$(grep -Pom1 "^ENVOY_ORG = \"\K[a-zA-Z-]+" "${WORKSPACE}")"
# ENVOY_REPO="$(grep -Pom1 "^ENVOY_REPO = \"\K[a-zA-Z-]+" "${WORKSPACE}")"

GITLAB_TOKEN=${GITLAB_TOKEN:-"your-gitlab-access-token"}
GITLAB_URL=${GITLAB_URL:-"your-gitlab-url"}
GITLAB_PROJECT_ID=${GITLAB_PROJECT_ID:-"your-gitlab-project-id"}

# get latest commit for specified org/repo
LATEST_SHA=$(curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/branches/${UPDATE_BRANCH}" | jq -r '.commit.id')
DATE=$(curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/commits/${LATEST_SHA}" | jq -r '.committed_date')

DATE=$(echo "${DATE/\"/}" | cut -d'T' -f1)

# Update ENVOY_SHA commit date
sed -i "s/Commit date: .*/Commit date: ${DATE}/" "${WORKSPACE}"

# Update the dependency in istio/proxy WORKSPACE
sed -i 's/ENVOY_SHA = .*/ENVOY_SHA = "'"$LATEST_SHA"'"/' "${WORKSPACE}"

# Update .bazelversion and envoy.bazelrc
curl -sSL --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/files/.bazelversion/raw?ref=${LATEST_SHA}" > .bazelversion
curl -sSL --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "https://${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/files/.bazelrc/raw?ref=${LATEST_SHA}" > envoy.bazelrc

# Generate gitlab bazel
echo "GITLAB_TOKEN = \"${GITLAB_TOKEN}\"" > "${GITLAB_BAZEL}"
echo "GITLAB_URL = \"${GITLAB_URL}\"" >> "${GITLAB_BAZEL}"
echo "GITLAB_PROJECT_ID = \"${GITLAB_PROJECT_ID}\"" >> "${GITLAB_BAZEL}"