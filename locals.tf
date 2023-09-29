locals {

  # Threads the sleep resource into the module to make the dependency
  cluster_endpoint  = time_sleep.this.triggers["cluster_endpoint"]
  cluster_name      = time_sleep.this.triggers["cluster_name"]
  oidc_provider_arn = time_sleep.this.triggers["oidc_provider_arn"]

  # https://github.com/Kong/charts/tree/main/charts
  name             = try(var.kong_config.name, "kong")
  namespace        = try(var.kong_config.namespace, "kong")
  create_namespace = try(var.kong_config.create_namespace, true)
  chart            = "ingress"
  chart_version    = try(var.kong_config.chart_version, null)
  repository       = try(var.kong_config.repository, "https://charts.konghq.com")
  values           = try(var.kong_config.values, [])

  runtimeGroupID        = try(var.kong_config.runtimeGroupID, null)
  apiHostname           = try(var.kong_config.apiHostname, null)
  telemetry_dns         = try(var.kong_config.telemetry_dns, null)
  cert_secret_name      = try(var.kong_config.cert_secret_name, null)
  key_secret_name       = try(var.kong_config.key_secret_name, null)
  kong_external_secrets = try(var.kong_config.kong_external_secrets, "konnect-client-tls")
  secret_volume_length  = try(length(yamldecode(var.kong_config.values[0])["secretVolumes"]), 0)

  enable_external_secrets = try(var.kong_config.add_ons.enable_external_secrets, true)

  external_secret_service_account_name                = "external-secret-irsa"
  external_secrets_irsa_role_name                     = "external-secret-irsa"
  external_secrets_irsa_role_name_use_prefix          = true
  external_secrets_irsa_role_path                     = "/"
  external_secrets_irsa_role_permissions_boundary_arn = null
  external_secrets_irsa_role_description              = "IRSA for external-secrets operator"
  external_secrets_irsa_role_policies                 = {}


  set_values = [
    {
      name  = "controller.ingressController.image.repository"
      value = "kong/kubernetes-ingress-controller"
    },
    {
      name  = "controller.ingressController.konnect.license.enabled"
      value = true
    },
    {
      name  = "controller.ingressController.konnect.enabled"
      value = true
    },
    {
      name  = "controller.ingressController.konnect.runtimeGroupID"
      value = local.runtimeGroupID
    },
    {
      name  = "controller.ingressController.apiHostname"
      value = local.apiHostname
    },
    {
      name  = "controller.ingressController.tlsClientSecretName"
      value = local.kong_external_secrets
    },
    {
      name  = "gateway.image.repository"
      value = "kong/kong-gateway"
    },
    {
      name  = "gateway.env.konnect_mode"
      value = "on"
    },
    {
      name  = "gateway.env.vitals"
      value = "off"
    },
    {
      name  = "gateway.env.cluster_mtls"
      value = "pki"
    },
    {
      name  = "gateway.env.cluster_telemetry_endpoint"
      value = "${local.telemetry_dns}:443"
    },
    {
      name  = "gateway.env.cluster_telemetry_server_name"
      value = local.telemetry_dns
    },
    {
      name  = "gateway.env.cluster_cert"
      value = "/etc/secrets/${local.kong_external_secrets}/tls.crt"
    },
    {
      name  = "gateway.env.cluster_cert_key"
      value = "/etc/secrets/${local.kong_external_secrets}/tls.key"
    },
    {
      name  = "gateway.env.lua_ssl_trusted_certificate"
      value = "system"
    },
    {
      name  = "gateway.secretVolumes[${local.secret_volume_length}]"
      value = local.kong_external_secrets
    }
  ]
}
