# Homelab

This is my private Kubernetes cluster running on [Talos Linux](https://www.siderolabs.com/talos-linux)
and continuously reconciled using [Flux](https://fluxcd.io/).

My goal for this homelab was to have a simple-enough-to-manage and API-driven system
where I don't have to worry too much about what application runs where,
day-to-day operations (e.g. updating software) are relatively simple,
and the system would for the most part take care of itself.
Its architecture isn't too sophisticated right now:
the cluster consists of one control plane node, a Raspberry Pi 4B, and
a single mini PC serving as a worker node.

## Structure

There are two main components:

- Talos Linux, an entirely API-driven OS, is configured via an [OpenTofu module](./infra).
  [Cilium](https://cilium.io/) and the Gateway API are also deployed here
  as part of the control plane configuration to serve as the cluster's
  Container Networking Interface.
- [Kubernetes manifests](./k8s) are continuously reconciled using Flux,
  and are organized into layers:
  - [`00-entry`](./k8s/00-entry) contains the Flux bootstrap manifests as well as
    sources used by subsequent layers.
  - [`01-crds`](./k8s/01-crds) contains custom resource definitions (CRDs) used by
    addons in the next layer.
    These are managed separately from the addons themselves to avoid accidentally
    deleting custom resources when their addons are removed for any reason.
  - [`02-addons`](./k8s/02-addons) contains addons that provide cluster functionality
    (storage, secrets management, etc.)
    and any configuration needed to get them working.
  - [`03-apps`](./k8s/03-apps) contains user-facing applications.
