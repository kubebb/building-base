#!/usr/bin/env bash
#
# Copyright contributors to the kubebb project
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
# 	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# variants for options
UPGRADE_U4A=${UPGRADE_U4A:-"NO"}
INSTALL_U4A=${INSTALL_U4A:-"NO"}

TIMEOUT=${TIMEOUT:-"1200s"}

RUN_IN_TEST=${RUN_IN_TEST:-"NO"}
echo "checking option params..."

# Get install options
for i in "$@"; do
	echo $i
	if [ $i == "--all" ]; then
		echo "will install all parts by default"
		INSTALL_U4A="YES"
	elif [ $i == "--u4a" ]; then
		echo "will install u4a components"
		INSTALL_U4A="YES"
	elif [ $i == "--up-all" ]; then
		echo "will upgrade all components"
		UPGRADE_U4A="YES"
		# TODO: upgrade other components
	else
		echo "param error, no changes applied"
	fi
done

function debug() {
	if [[ ${RUN_IN_TEST} == "YES" ]]; then
		kubectl describe po -A
		kubectl get po -A
	fi
	exit 1
}
trap debug ERR

# step 1. create namespace
if [[ $INSTALL_U4A == "YES" ]]; then
	kubectl create ns u4a-system --dry-run=client -oyaml| kubectl apply -f -
fi

# step 2. get node name and node ip
ingressNode="kind-worker"
kubeProxyNode="kind-worker2"
ingressNodeIP=$(kubectl get node ${ingressNode} -owide | grep -v "NAME" | awk '{print $6}')
kubeProxyNodeIP=$(kubectl get node ${kubeProxyNode} -owide | grep -v "NAME" | awk '{print $6}')

echo "node info:"
kubectl get node -o wide
echo "ingressNodeIp is: ${ingressNodeIP}"
echo "kubeProxyNodeIP is: ${kubeProxyNodeIP}"
export ingressNodeIP=${ingressNodeIP}

# step 3. repalce ingress node name
cat u4a-component/charts/cluster-component/values.yaml | sed "s/<replaced-ingress-node-name>/${ingressNode}/g" \
	>u4a-component/charts/cluster-component/values1.yaml

# step 4. replace nginx and kube proxy node name
cat u4a-component/values.yaml | sed "s/<replaced-ingress-nginx-ip>/${ingressNodeIP}/g" |
	sed "s/<replaced-oidc-proxy-node-name>/${kubeProxyNode}/g" |
	sed "s/<replaced-oidc-proxy-node-ip>/${kubeProxyNodeIP}/g" \
		>u4a-component/values1.yaml

if [ $INSTALL_U4A == "YES" ]; then
	# step 5. install cluster-compoent
	echo "begin deploying cluster component..."
	helm --wait --timeout=$TIMEOUT -n u4a-system install cluster-component -f u4a-component/charts/cluster-component/values1.yaml u4a-component/charts/cluster-component
	echo "deploy cluster component succeffsully."

	# step 6. install u4a component
	echo "begin deploying u4a component..."
	helm --wait --timeout=$TIMEOUT -n u4a-system install u4a-component -f u4a-component/values1.yaml u4a-component
	echo "deploy u4a component successfully"

	echo "namespace info:"
	kubectl get po -n u4a-system -o wide
fi

# upgrade u4a
if [ ${UPGRADE_U4A} == "YES" ]; then
	helm upgrade -n u4a-system cluster-component -f u4a-component/charts/cluster-component/values1.yaml u4a-component/charts/cluster-component
fi
