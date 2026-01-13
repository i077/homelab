# Generate a CA to use as Cilium's common CA
resource "tls_private_key" "cilium_common_ca" {
  algorithm = "ED25519"
}

resource "tls_self_signed_cert" "cilium_common_ca" {
  private_key_pem = tls_private_key.cilium_common_ca.private_key_pem

  subject {
    common_name = "Cilium CA"
  }

  validity_period_hours = 24 * 365 * 5 # 5 years
  early_renewal_hours   = 24 * 365 * 4 # 4 years

  allowed_uses      = ["digital_signature", "key_encipherment", "cert_signing", "server_auth", "client_auth"]
  is_ca_certificate = true
}

# Template the Cilium chart, to be passed to the Talos MachineConfigs
data "helm_template" "cilium" {
  repository   = "https://helm.cilium.io/"
  chart        = "cilium"
  version      = "1.18.2"
  kube_version = local.cluster_info.kubernetes_version

  name      = "cilium"
  namespace = "kube-system"

  # https://www.talos.dev/v1.9/kubernetes-guides/network/deploying-cilium/#method-1-helm-install
  values = [
    jsonencode({
      ipam                 = { mode = "kubernetes" }
      kubeProxyReplacement = true

      bpf = {
        enabled = true

        # Allow external access to ClusterIP services, to let the Tailscale extension act as a subnet
        # router.
        lbExternalClusterIP = true
      }

      l2announcements = {
        enabled = true
      }

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

      gatewayAPI = {
        enabled           = true
        enableAlpn        = true
        enableAppProtocol = true
        gatewayClass      = { create = "true" }
      }
    }),
    jsonencode({
      tls = {
        ca = {
          key  = base64encode(tls_private_key.cilium_common_ca.private_key_pem)
          cert = base64encode(tls_self_signed_cert.cilium_common_ca.cert_pem)
        }
      }

      # Generate Hubble key & renew cert w/ CronJob
      hubble = {
        tls = {
          auto = {
            enabled              = true
            method               = "cronJob"
            certValidityDuration = 365 * 3       # 3 years
            schedule             = "0 0 1 */4 *" # Every 4 weeks
          }
        }
      }
    }),
  ]
}

# Grab the Gateway API CRDs, a prereq. for Cilium's Gateway implementation
data "http" "gateway_api" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml"
}
