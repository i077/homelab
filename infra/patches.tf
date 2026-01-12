locals {
  tailnet_patch = jsonencode({
    apiVersion = "v1alpha1"
    kind       = "ExtensionServiceConfig"
    name       = "tailscale"
    environment = [
      "TS_AUTHKEY=${tailscale_tailnet_key.tsauth.key}",
      "TS_ACCEPT_DNS=true",
      "TS_EXTRA_ARGS=--reset"
    ]
  })

  tailnet_worker_patch = jsonencode({
    apiVersion = "v1alpha1"
    kind       = "ExtensionServiceConfig"
    name       = "tailscale"
    environment = [
      "TS_AUTHKEY=${tailscale_tailnet_key.tsauth.key}",
      "TS_ACCEPT_DNS=true",
      "TS_USERSPACE=false",
      "TS_ROUTES=10.96.0.0/12,10.244.0.0/16",
      "TS_EXTRA_ARGS=--reset"
    ]
  })

  # Replace CNI & kube-proxy with Cilium
  cni_patch_controlplane = jsonencode({
    cluster = {
      inlineManifests = [
        { name = "01-gateway-api", contents = data.http.gateway_api.response_body },
        { name = "02-cilium", contents = data.helm_template.cilium.manifest }
      ]
    }
  })

  cni_patch = jsonencode({
    machine = {
      kubelet = {
        nodeIP = {
          # Only use IP from the LAN's subnet
          validSubnets = ["192.168.0.0/16"]
        }
      }

      features = {
        hostDNS = {
          enabled = true
          # Disable forwarding DNS to host, since this is incompatible with Cilium:
          # https://www.talos.dev/v1.9/kubernetes-guides/network/deploying-cilium/#known-issues
          forwardKubeDNSToHost = false
        }
      }
    }

    cluster = {
      proxy = { disabled = true }
      network = {
        cni = { name = "none" }
      }
    }
  })

  cluster_config_patch = jsonencode({
    machine = {
      certSANs = [local.cluster_endpoint]
    }
    cluster = {
      apiServer = {
        certSANs = [local.cluster_endpoint]
      }
    }
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

  cluster_domain_patch = jsonencode({
    cluster = {
      network = { dnsDomain = "home.arpa" }
    }
  })

  kubelet_ca_patch = jsonencode({
    machine = {
      kubelet = {
        extraArgs = {
          rotate-server-certificates = true
        }
      }
    }
  })
}
