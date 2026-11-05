locals {
  tailnet_patch = jsonencode({
    apiVersion = "v1alpha1"
    kind       = "ExtensionServiceConfig"
    name       = "tailscale"
    environment = concat([
      "TS_AUTHKEY=${var.cluster_info.tailnet_auth_key}",
      "TS_ACCEPT_DNS=true",
      "TS_EXTRA_ARGS=--reset",
      "TS_USERSPACE=false",
      ], var.controlplane ? [] : [
      # Only advertise Service & Pod CIDRs from worker nodes
      "TS_ROUTES=10.96.0.0/12,10.244.0.0/16",
    ])
  })

  # Replace CNI & kube-proxy with Cilium
  cni_install_patch = jsonencode({
    cluster = {
      inlineManifests = [
        { name = "01-gateway-api", contents = var.bootstrap_manifests.gateway_api },
        { name = "02-cilium", contents = var.bootstrap_manifests.cilium_cni }
      ]
    }
  })

  cni_patch = jsonencode({
    apiVersion = "v1alpha1"
    kind       = "KubeNodeConfig"
    nodeIP = {
      # Only use IP from the LAN's subnet
      validSubnets = ["192.168.0.0/16"]
    }
    labels = var.openebs_nodeid != null ? {
      "openebs.io/nodeid" = var.openebs_nodeid
    } : {}
  })

  kubelet_ca_patch = jsonencode({
    apiVersion = "v1alpha1"
    kind       = "KubeletConfig"
    extraArgs = {
      "rotate-server-certificates" = true
    }
  })

  resolver_patch = jsonencode({
    apiVersion = "v1alpha1"
    kind       = "ResolverConfig"
    hostDNS = {
      enabled              = true
      forwardKubeDNSToHost = false
    }
  })

  kube_network_patch = jsonencode({
    apiVersion = "v1alpha1"
    kind       = "KubeNetworkConfig"
    dnsDomain  = "home.arpa"
  })

  cluster_config_patch = jsonencode({
    machine = {
      certSANs = [var.cluster_info.cluster_endpoint]
    }
  })

  kube_apiserver_patch = jsonencode({
    apiVersion    = "v1alpha1"
    kind          = "KubeAPIServerConfig"
    certExtraSANs = [var.cluster_info.cluster_endpoint]
  })

  kube_proxy_patch = jsonencode({
    apiVersion = "v1alpha1"
    kind       = "KubeProxyConfig"
    enabled    = false
  })

  flannel_delete_patch = jsonencode({
    apiVersion = "v1alpha1"
    kind       = "KubeFlannelCNIConfig"
    "$patch"   = "delete"
  })

  talos_api_access_patch = jsonencode({
    machine = {
      features = {
        kubernetesTalosAPIAccess = {
          enabled                     = true
          allowedRoles                = ["os:etcd:backup"]
          allowedKubernetesNamespaces = ["storage"]
        }
      }
    }
  })

}
