output "subscription_id" {
  description = "Subscription the templates deployed into"
  value       = data.azurerm_client_config.current.subscription_id
}
