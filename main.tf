###########Namespace###########

resource "kubernetes_namespace_v1" "kong" {
  count = local.create_namespace && local.namespace != "kube-system" ? 1 : 0

  metadata {
    name = local.namespace

  }

  timeouts {
    delete = "15m"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }
}

###########AddOns for Cluster. Note the module name has addon"s"###########

module "add_ons" {
  count = local.enable_external_secrets ? 1 : 0

  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.1.0"

  cluster_name      = var.cluster_name
  cluster_endpoint  = var.cluster_endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = var.oidc_provider_arn

  # EKS Add-on
  # eks_addons = {
  #   coredns    = {}
  #   vpc-cni    = {}
  #   kube-proxy = {}
  # }

  enable_external_secrets = true
  # Following to ensure that the IRSA with which the External Secret Pod is running does not have any access. 
  # Ideally, this should not use IRSA at all as its the property of `SecretStore` CRD
  external_secrets_secrets_manager_arns = []
  external_secrets_ssm_parameter_arns   = []

  external_secrets = {
    wait = true
    set = [
      {
        name  = "webhook.port"
        value = "9443"
      }
    ]
  }
}

##########Service Account for External Secret###########

resource "kubernetes_service_account_v1" "external_secret_sa" {
  metadata {
    name        = local.external_secret_service_account_name
    namespace   = try(kubernetes_namespace_v1.kong[0].metadata[0].name, local.namespace)
    annotations = { "eks.amazonaws.com/role-arn" : module.external_secret_irsa.iam_role_arn }
  }

  automount_service_account_token = true
}

## IRSA FOR EXTERNAL SECRET STORE OBJECT ##
# Note, this source module does not has "s" in eks-blueprints-addon

module "external_secret_irsa" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.0"

  create_release = false
  # IAM role for service account (IRSA)
  create_role                   = true
  role_name                     = local.external_secrets_irsa_role_name
  role_name_use_prefix          = local.external_secrets_irsa_role_name_use_prefix
  role_path                     = local.external_secrets_irsa_role_path
  role_permissions_boundary_arn = local.external_secrets_irsa_role_permissions_boundary_arn
  role_description              = local.external_secrets_irsa_role_description
  role_policies                 = local.external_secrets_irsa_role_policies
  source_policy_documents = compact(concat(
    data.aws_iam_policy_document.kong_external_secret_secretstore[*].json,
    lookup(var.kong_config, "source_policy_documents", [])
  ))
  override_policy_documents = lookup(var.kong_config, "override_policy_documents", [])
  policy_statements         = lookup(var.kong_config, "policy_statements", [])
  policy_name               = try(var.kong_config.policy_name, "external-secrets-irsa-policy")
  policy_name_use_prefix    = try(var.kong_config.policy_name_use_prefix, true)
  policy_path               = try(var.kong_config.policy_path, null)
  policy_description        = try(var.kong_config.policy_description, "IAM Policy for Kong")

  oidc_providers = {
    this = {
      provider_arn = var.oidc_provider_arn
      # namespace is inherited from chart 
      namespace       = local.namespace
      service_account = local.external_secret_service_account_name
    }
  }
}

###########Secret Store###########

resource "kubectl_manifest" "secretstore" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: kong-secretstore
  namespace: ${local.namespace}
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${data.aws_region.current.name}
      auth:
        jwt:
          serviceAccountRef:
            name: ${local.external_secret_service_account_name}
YAML
  wait      = true

  depends_on = [
    module.external_secret_irsa,
    kubernetes_service_account_v1.external_secret_sa,
    module.add_ons # Dont remove this dependency
  ]
}

###########External Secret###########

resource "kubectl_manifest" "secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ${local.kong_external_secrets}
  namespace: ${local.namespace}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: kong-secretstore
    kind: SecretStore
  target:
    name: ${local.kong_external_secrets}
    creationPolicy: Owner
    template:
      type: kubernetes.io/tls
  data:
  - secretKey: tls.crt
    remoteRef:
      key: ${local.cert_secret_name}
  - secretKey: tls.key
    remoteRef:
      key: ${local.key_secret_name}
YAML
  wait      = true

  depends_on = [kubectl_manifest.secretstore]
}

###########Kong Helm Module##########

module "kong_helm" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.0"

  create           = true
  chart            = local.chart
  name             = local.name
  chart_version    = local.chart_version
  repository       = local.repository
  description      = "Kong Konnect - KIC"
  namespace        = local.namespace
  create_namespace = false

  set    = local.set_values
  values = local.values

  tags = var.tags
  depends_on = [
    module.add_ons,
    kubectl_manifest.secret
  ]

}

## Not required, but commenting, so that in future, if we need to retrieve the ARN of the secret, thats doable by data.aws_secretsmanager_secret.cert_secret_name.arn
# data "aws_secretsmanager_secret" "cert_secret_name" {
#   name = local.cert_secret_name
# }

# data "aws_secretsmanager_secret" "key_secret_name" {
#   name = local.key_secret_name
# }
