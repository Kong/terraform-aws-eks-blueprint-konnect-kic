###########Namespace###########

resource "kubernetes_namespace_v1" "kong" {
  count = var.enable_kong_konnect && local.create_namespace && local.namespace != "kube-system" ? 1 : 0

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

###########Service Account###########

resource "kubernetes_service_account_v1" "kong" {
  count = var.enable_kong_konnect && local.create_kubernetes_service_account ? 1 : 0
  metadata {
    name        = local.service_account

    namespace   = try(kubernetes_namespace_v1.kong[0].metadata[0].name, local.namespace)
    annotations = { "eks.amazonaws.com/role-arn" : module.kong_irsa[0].iam_role_arn }
  }

  automount_service_account_token = true
}

###########Kong Helm Module##########

module "kong_helm" {
  source           = "aws-ia/eks-blueprints-addon/aws"
  version          = "1.1.0"

  create           = var.enable_kong_konnect
  chart            = local.name
  chart_version    = local.chart_version
  repository       = local.repository
  description      = "Kong konnect"
  namespace        = local.namespace
  create_namespace = false

  set              = local.set_values
  values           = local.values

  set_irsa_names = ["deployment.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  # # Equivalent to the following but the ARN is only known internally to the module
  # set = [{
  #   name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
  #   value = iam_role_arn.this[0].arn
  # }]

  tags = var.tags
  depends_on = [kubectl_manifest.secret]
}

###########IRSA###########

module "kong_irsa" {
  count   = var.enable_kong_konnect ? 1 : 0
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.0"

  create_release = false
  # IAM role for service account (IRSA)
  create_role                   = true
  role_name                     = local.role_name
  role_name_use_prefix          = try(var.kong_config.role_name_use_prefix, true)
  role_path                     = try(var.kong_config.role_path, "/")
  role_permissions_boundary_arn = lookup(var.kong_config, "role_permissions_boundary_arn", null)
  role_description              = try(var.kong_config.role_description, "IRSA for kong")
  role_policies                 = lookup(var.kong_config, "role_policies", {})
  source_policy_documents = compact(concat(
    data.aws_iam_policy_document.kong_secretstore[*].json,
    lookup(var.kong_config, "source_policy_documents", [])
  ))
  override_policy_documents = lookup(var.kong_config, "override_policy_documents", [])
  policy_statements         = lookup(var.kong_config, "policy_statements", [])
  policy_name               = try(var.kong_config.policy_name, "kong")
  policy_name_use_prefix    = try(var.kong_config.policy_name_use_prefix, true)
  policy_path               = try(var.kong_config.policy_path, null)
  policy_description        = try(var.kong_config.policy_description, "IAM Policy for Kong")

  oidc_providers = {
    this = {
      provider_arn = var.oidc_provider_arn
      # namespace is inherited from chart
      namespace       = local.namespace
      service_account = local.service_account
    }
  }
}

###########Secret Store###########

resource "kubectl_manifest" "secretstore" {
  count = var.enable_kong_konnect ? 1 : 0
  yaml_body  = <<YAML
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
            name: ${local.service_account}
YAML
  depends_on = [
    module.kong_irsa,
    kubernetes_service_account_v1.kong
  ]
}

###########External Secret###########

resource "kubectl_manifest" "secret" {
  count = var.enable_kong_konnect ? 1 : 0
  yaml_body  = <<YAML
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
  - secretKey: kong_cert
    remoteRef:
      key: ${local.cert_secret_name}
  - secretKey: kong_key
    remoteRef:
      key: ${local.key_secret_name}
YAML
  depends_on = [kubectl_manifest.secretstore]
}