# Copyright 2022 Replicated Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# 	http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
package kurl.installer

# reports an error in case the kubernetes distribution is k3s and the user has
# selected also a container runtime. for k3s no container runtime can be selected.
lint[output] {
	input.spec.k3s.version
	count(container_runtimes) > 0
	output :=  {
		"type": "incompatibility",
		"message": "container runtime is incompatible with k3s",
		"field": "spec.k3s"
	}
}

# reports an error in case the kubernetes distribution is rke2 and the user has
# also chosen a container runtime. for rke2 no container runtime can be selected.
lint[output] {
	input.spec.rke2.version
	count(container_runtimes) > 0
	output :=  {
		"type": "incompatibility",
		"message": "container runtime is incompatible with rke2",
		"field": "spec.rke2"
	}
}

# reports an error if user has selected the kubernetes distribution but has not
# selected a container runtime. a container runtime is necessary to run the kube
# distribution.
lint[output] {
	input.spec.kubernetes.version
	count(container_runtimes) == 0
	output :=  {
		"type": "misconfiguration",
		"message": "no container runtime selected",
		"field": "spec"
	}
}

# reports an error if user has selected multiple container runtimes at the same
# time. only one can be selected (or docker or containerd).
lint[output] {
	count(container_runtimes) > 1
	output := {
		"type": "misconfiguration",
		"message": "multiple container runtimes selected",
		"field": "spec"
	}
}

# checks if there is at least one selected kubernetes distro (kubernetes, k3s, or rke2).
lint[output] {
	count(kube_distributions) == 0
	output := {
		"type": "misconfiguration",
		"message": "no kubernetes distribution selected",
		"field": "spec"
	}
}

# returns an error if more than one kubernetes distro has been selected.
lint[output] {
	count(kube_distributions) > 1
	output := {
		"type": "misconfiguration",
		"message": "multiple kubernetes distributions selected",
		"field": "spec"
	}
}

# verifies if the selected kubernetes version is compatible with the selected container
# runtime. the only thing verified here is that we are not trying to run kubernetes 1.24+
# with the "docker" container runtime as they are incompatible.
lint[output] {
	not valid_runtime_for_kubernetes
	output := {
		"type": "incompatibility",
		"message": "kubernetes >= v1.24 does not work with docker",
		"field": "spec.docker"
	}
}

# verifies if the kubernetes service cidr override provided by the user is valid.
lint[output] {
	not valid_kubernetes_service_cidr_range_override
	output := {
		"type": "misconfiguration",
		"message": "service cidr range is invalid",
		"field": "spec.kubernetes.serviceCidrRange"
	}
}

# verifies if the weave pod cidr range override provided by the user is valid.
lint[output] {
	not valid_pod_cidr_range_override("weave")
	output := {
		"type": "misconfiguration",
		"message": "weave pod cidr range is invalid",
		"field": "spec.weave.podCidrRange"
	}
}

# verifies if the antrea pod cidr override provided by the user is valid.
lint[output] {
	not valid_pod_cidr_range_override("antrea")
	output := {
		"type": "misconfiguration",
		"message": "antrea pod cidr range is invalid",
		"field": "spec.antrea.podCidrRange"
	}
}

# returns an error if the config has weave and antrea selected at the same time.
lint[output] {
	input.spec.weave.version
	input.spec.antrea.version
	output := {
		"type": "misconfiguration",
		"message": "multiple cni plugins selected",
		"field": "spec"
	}
}

# returns an error if selected kubernetes is >= 1.20 and rook is less than 1.1.0.
lint[output] {
	is_addon_version_greater_than_or_equal("kubernetes", "1.20.0")
	is_addon_version_lower_than("rook", "1.1.0")
	output := {
		"type": "incompatibility",
		"message": "rook <= 1.1.0 is not compatible with kubernetes 1.20+",
		"field": "spec.rook.version"
	}
}

# returns an error if longhorn <= 1.4.0 is selected with kubernetes >= 1.25.0, this
# pair is incompatible.
lint[output] {
	is_addon_version_greater_than_or_equal("kubernetes", "1.25.0")
	is_addon_version_lower_than("longhorn", "1.4.0")
	output := {
		"type": "incompatibility",
		"message": "longhorn <= 1.4.0 are not compatible with kubernetes 1.25+",
		"field": "spec.longhorn.version"
	}
}

# this returns an error if an invalid or unknown version for an add-on has been selected.
lint[output] {
	some name 
	ignored := known_versions[name]
	not valid_add_on_version(name)
	output := {
		"type": "unknown-addon",
		"message": sprintf("unknown %v version %v", [name, input.spec[name].version]),
		"field": sprintf("spec.%v.version", [name])
	}
}

# returns an error if weave has been selected with containerd in versions between 1.6.0 and
# 1.6.4 as this pair is incompatible.
lint[output] {
	is_addon_version_greater_than_or_equal("containerd", "1.6.0")
	is_addon_version_lower_than_or_equal("containerd", "1.6.4")
	output := {
		"type": "incompatibility",
		"message": "weave is not compatible with containerd versions 1.6.0 - 1.6.4",
		"field": "spec.containerd.version"
	}
}

# reports incompatiblity error for the openebs <= 2.12.9 and kubernetes >= 1.22.0 duo.
lint[output] {
	is_addon_version_greater_than_or_equal("kubernetes", "1.22.0")
	is_addon_version_lower_than_or_equal("openebs", "2.12.9")
	output := {
		"type": "incompatibility",
		"message": "openebs version <= 2.12.9  not compatible with kubernetes 1.22+",
		"field": "spec.openebs.version"
	}
}

# if due to a network error we could not load the list of known versions we report an error
# as well.
lint[output] {
	remote_versions.error.message
	output :=  {
		"type": "preprocess",
		"message": remote_versions.error.message
	}
}

# reports an error if openebs >= 2.12.9 and cstor is enabled. this configuration is not
# supported by kurl.
lint[output] {
	input.spec.openebs.isCstorEnabled
	is_addon_version_greater_than_or_equal("openebs", "2.12.9")
	version := input.spec.openebs.version
	message := sprintf("openebs version %v does not support cstor in kurl", [version])
	output := {
		"type": "misconfiguration",
		"message": message,
		"field": "spec.openebs.isCstorEnabled"
	}
}

# reports an error if rook is <= 1.9.10 and kubernetes >= 1.25 as this pair is incompatible.
lint[output] {
	is_addon_version_greater_than_or_equal("kubernetes", "1.25.0")
	is_addon_version_lower_than_or_equal("rook", "1.9.10")
	output := {
		"type": "incompatibility",
		"message": "rook versions <= 1.9.10 are not compatible with kubernetes 1.25+",
		"field": "spec.rook.version"
	}
}

# prometheus versions <= 0.49.0-17.1.3 are incompatible with Kubernetes 1.22+.
lint[output] {
	is_addon_version_greater_than_or_equal("kubernetes", "1.22.0")
	is_addon_version_lower_than_or_equal("prometheus", "0.49.0")
	output := {
		"type": "incompatibility",
		"message": "prometheus <= 0.49.0-17.1.3 is not compatible with kubernetes 1.22+",
		"field": "spec.prometheus.version"
	}
}

# prometheus versions less than or equal to 0.59.0 are not compatible with kubernetes 1.25+.
lint[output] {
	is_addon_version_greater_than_or_equal("kubernetes", "1.25.0")
	is_addon_version_lower_than_or_equal("prometheus", "0.59.0")
	output := {
		"type": "incompatibility",
		"message": "prometheus <= 0.59.0 is not compatible with kubernetes 1.25+",
		"field": "spec.prometheus.version"
	}
}

# reports an error if prometheus service port is of invalid type.
lint[output] {
	svc_type := input.spec.prometheus.serviceType
	svc_type != "NodePort"
	svc_type != "ClusterIP"
	msg := sprintf("prometheus service types are NodePort and ClusterIP, not %v", [svc_type])
	output := {
		"type": "misconfiguration",
		"message": msg,
		"field": "spec.prometheus.serviceType"
	}
}

# prometheus service type is only supported for versions >= 0.48.1
lint[output] {
	input.spec.prometheus.serviceType
	is_addon_version_lower_than("prometheus", "0.48.1")
	output := {
		"type": "misconfiguration",
		"message": "prometheus service types supported for v0.48.1-16.10.0 and later",
		"field": "spec.prometheus.serviceType"
	}
}

# this next rule evaluates if all selected add-ons are supported by k3s.
lint[output] {
	input.spec.k3s
	input.spec[addon]
	not add_on_compatible_with_k3s(addon)
	output := {
		"type": "incompatibility",
		"message": sprintf("k3s is not compatible with %v", [addon]),
		"field": sprintf("spec.%v", [addon])
	}
}

# this next rule evaluates if all selected add-ons are supported by rke2.
lint[output] {
	input.spec.rke2
	input.spec[addon]
	not add_on_compatible_with_rke2(addon)
	output := {
		"type": "incompatibility",
		"message": sprintf("rke2 is not compatible with %v", [addon]),
		"field": sprintf("spec.%v", [addon])
	}
}

lint[output] {
	input.spec.k3s.version
	input.spec.kotsadm.uiBindPort
	port_out_of_range(input.spec.kotsadm.uiBindPort, 30000, 32767)
	output := {
		"type": "misconfiguration",
		"message": "nodeports for k3s distro must use a NodePort between 30000-32767",
		"field": "spec.kotsadm.uiBindPort"
	}
}

lint[output] {
	input.spec.rke2.version
	input.spec.kotsadm.uiBindPort
	port_out_of_range(input.spec.kotsadm.uiBindPort, 30000, 32767)
	output := {
		"type": "misconfiguration",
		"message": "nodeports for rke2 distro must use a NodePort between 30000-32767",
		"field": "spec.kotsadm.uiBindPort"
	}
}
