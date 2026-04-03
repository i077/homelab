# Reconcile all Flux resources
reconcile:
    flux reconcile source git flux-system
    flux reconcile kustomization flux-system
    flux reconcile kustomization crds
    flux reconcile kustomization addons
    flux reconcile kustomization apps

# Upgrade a Talos node
upgrade node:
    talosctl upgrade -n {{node}} --image $(op run -- tofu -chdir=infra output -json | jq -r .installer_urls.value.{{node}})

# Update talosconfig from OpenTofu state
[working-directory: 'infra']
talosconfig:
    op run -- tofu output -raw talos_config > ~/.talos/config

# Apply OpenTofu configuration
[working-directory: 'infra']
apply:
    op run -- tofu apply
