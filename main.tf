terraform {
  required_providers {
    dsm = {
      version = "0.5.28"
      source  = "fortanix/dsm"
    }
  }
}

variable "password" {}
variable "azure_secret_id" {}
provider "dsm" {
  endpoint = var.endpoint
  username = var.username
  password = "${var.password}"
  acct_id  = var.acct_id
}


/*
1. Create a normal group
2. Create an RSA key
3. Create an Azure group
4. Create an RSA inside azure group from the above RSA key(step 2) - copy key
5. Check the dashboard
*/

resource "dsm_group" "ado_ng" {
  name = "ado_ng"
}


resource "dsm_sobject" "ado_rsa" {
  name     = "ado_rsa"
  group_id = dsm_group.ado_ng.id
  key_size = 2048
  key_ops = [
    "ENCRYPT",
    "DECRYPT",
    "WRAPKEY",
    "UNWRAPKEY",
    "SIGN",
    "VERIFY",
    "EXPORT"
  ]
  obj_type = "RSA"
}

resource "dsm_azure_group" "ado_ag" {
  name            = "ado_ag"
  description     = "dsm_azure_group"
  url             = "https://ravigterraform.vault.azure.net/"
  client_id       = "51fb90ff-6b70-47ac-b76a-b67139aa3a63"
  key_vault_type  = "Standard"
  subscription_id = "de7becae-4883-43e8-82c7-7dbdbb988ae6"
  tenant_id       = "de7becae-4883-43e8-82c7-7dbdbb988ae6"
  secret_key      = "${var.azure_secret_id}"
}

resource "dsm_azure_sobject" "ado_rsa_ag" {

  name            = "ado_rsa_ag"
  group_id        = dsm_azure_group.ado_ag.id
  description     = "dsm_azure_sobject"
  enabled          = true
  key             = {
    kid =  dsm_sobject.ado_rsa.id
  }
  custom_metadata = {
    azure_key_state =  "Enabled"
    azure-key-name = "ado-rsa-pp"
  }
  key_ops         = ["SIGN", "VERIFY", "ENCRYPT", "DECRYPT", "WRAPKEY", "UNWRAPKEY", "EXPORT", "APPMANAGEABLE", "HIGHVOLUME"]
}
