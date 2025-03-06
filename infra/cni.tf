# Template the Cilium chart, to be passed to the Talos MachineConfigs
data "helm_template" "cilium" {
  repository   = "https://helm.cilium.io/"
  chart        = "cilium"
  version      = "1.17.1"
  kube_version = local.k8s_version

  name      = "cilium"
  namespace = "kube-system"

  # https://www.talos.dev/v1.9/kubernetes-guides/network/deploying-cilium/#method-1-helm-install
  values = [jsonencode({
    ipam                 = { mode = "kubernetes" }
    kubeProxyReplacement = true

    securityContext = {
      capabilities = {
        ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
        cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
      }
    }

    cgroup = {
      automount = { enabled = false }
      hostRoot  = "/sys/fs/cgroup"
    }

    k8sServiceHost = "localhost"
    k8sServicePort = 7445

    gatewayApi = {
      enabled           = true
      enableAlpn        = true
      enableAppProtocol = true
    }
  })]
}
