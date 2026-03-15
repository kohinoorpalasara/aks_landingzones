# AKS Platform

This repository provisions a shared AKS platform with Terraform and deploys environment workloads with Ansible.

## Architecture

- Single AKS cluster with `dev`, `tst`, `preprod`, and `prod` namespaces.
- Azure Application Gateway Ingress Controller for host-based routing.
- Azure Key Vault with External Secrets for environment-isolated secrets.
- Azure Monitor / Log Analytics for namespace-aware logging.
- ResourceQuota, LimitRange, NetworkPolicy, and RBAC-ready namespace separation.

## Terraform layout

- `modules/`: reusable Azure and Kubernetes building blocks.
- `environments/shared-cluster/`: shared-cluster composition and sample tfvars.
- `providers.tf`: provider requirements.

Run:

```bash
cd environments/shared-cluster
terraform init
terraform plan
terraform apply
```

## Ansible deployment

Deploy manifests and Helm for one environment:

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy-env.yml -e env=dev
```

Deploy only YAML assets:

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/deploy-yaml.yml -e env=prod
```

Install shared add-ons:

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy-platform.yml
```

This installs `external-secrets`, `reloader`, and the placeholder `twistlock` release.

Bootstrap Argo CD and let GitOps own the shared platform add-ons:

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/bootstrap-argocd.yml \
  -e gitops_repo_url=https://dev.azure.com/your-org/your-project/_git/openshift \
  -e gitops_revision=main
```

Configure Linux self-hosted Azure DevOps agents:

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy-devops-agent.yml \
  --limit devops_agents \
  -e azure_devops_org_url=https://dev.azure.com/your-org \
  -e azure_devops_pat=YOUR_PAT \
  -e target_agent_pool=aks-platform-linux
```

Pipeline definitions live in `pipelines/` for agent bootstrap and Argo CD bootstrap workflows.

## Logging

Use namespace filtering in Container Insights:

```kusto
ContainerLogV2
| where Namespace == "prod"
```

## Notes

- Replace the placeholder `tenant_id`, subscription ID, image repository, and hostnames before deployment.
- Replace the placeholder Azure DevOps repo URL in the Argo CD application YAMLs before syncing GitOps.
- The Helm chart directory expects a deployable chart at `helm/myapp`.
- If environments become highly regulated or very large, split `prod` and `preprod` into a dedicated production cluster.
