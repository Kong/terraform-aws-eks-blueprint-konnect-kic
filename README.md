# Kong Konnect KIC - EKS Blueprint AddOn

<p align="center">
  <img src="https://konghq.com/wp-content/uploads/2018/08/kong-combination-mark-color-256px.png" /></div>
</p>

## Introduction

Kong Konnect’s integration with the Kong Ingress Controller simplifies the management of Kong Gateways across different deployment scenarios, be it as an Ingress or on various cloud and Kubernetes providers.

The Kong Ingress Controller’s integration with Kong Konnect will activate API Portal, API Analytics, and Service Registry (Service Hub) capabilities for all services managed across connected Kong Ingress Controllers. API product owners can now take advantage of Kong Konnect’s powerful API portal capabilities, enabling application registration and customized developer experiences for any Ingress-managed service at a click of a button.

## Helm Chart

### Instructions to use the Helm Chart

See the [Kong Helm Chart](https://github.com/Kong/charts)

## Examples

See [blueprint-kong-samples](https://github.com/aws-samples/terraform-eks-blueprints-kong-samples).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.9.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.72 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 1.14 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.10 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.9.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_add_ons"></a> [add\_ons](#module\_add\_ons) | aws-ia/eks-blueprints-addons/aws | 1.1.0 |
| <a name="module_external_secret_irsa"></a> [external\_secret\_irsa](#module\_external\_secret\_irsa) | aws-ia/eks-blueprints-addon/aws | 1.1.0 |
| <a name="module_kong_helm"></a> [kong\_helm](#module\_kong\_helm) | aws-ia/eks-blueprints-addon/aws | 1.1.0 |

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.secret](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.secretstore](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.kong](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_service_account_v1.external_secret_sa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1) | resource |
| [time_sleep.this](https://registry.terraform.io/providers/hashicorp/time/0.9.1/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kong_external_secret_secretstore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_alias.secret_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | Endpoint for your Kubernetes API server | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.24`) | `string` | n/a | yes |
| <a name="input_create_delay_dependencies"></a> [create\_delay\_dependencies](#input\_create\_delay\_dependencies) | Dependency attribute which must be resolved before starting the `create_delay_duration` | `list(string)` | `[]` | no |
| <a name="input_create_delay_duration"></a> [create\_delay\_duration](#input\_create\_delay\_duration) | The duration to wait before creating resources | `string` | `"30s"` | no |
| <a name="input_kong_config"></a> [kong\_config](#input\_kong\_config) | Kong addon configuration values | `any` | `{}` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | The ARN of the cluster OIDC Provider | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace in which kong is being created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
