# ================================= Subnets ====================================

resource "azurerm_subnet" "pas_subnet" {
  name = "${var.env_name}-pas-subnet"

  //  depends_on                = ["${var.resource_group_name}"]
  resource_group_name       = "${var.resource_group_name}"
  virtual_network_name      = "${var.network_name}"
  address_prefix            = "${var.pas_subnet_cidr}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

resource "azurerm_subnet_network_security_group_association" "pks_subnet" {
  subnet_id                 = "${azurerm_subnet.pks_subnet.id}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

resource "azurerm_subnet" "pks_subnet" {
  name = "${var.env_name}-pks-subnet"

  //  depends_on                = ["${var.resource_group_name}"]
  resource_group_name       = "${var.resource_group_name}"
  virtual_network_name      = "${var.network_name}"
  address_prefix            = "${var.pks_subnet_cidr}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

resource "azurerm_subnet_network_security_group_association" "pas_subnet" {
  subnet_id                 = "${azurerm_subnet.pas_subnet.id}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

resource "azurerm_subnet" "services_subnet" {
  name = "${var.env_name}-services-subnet"

  //  depends_on                = ["${var.resource_group_name}"]
  resource_group_name       = "${var.resource_group_name}"
  virtual_network_name      = "${var.network_name}"
  address_prefix            = "${var.services_subnet_cidr}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

resource "azurerm_subnet_network_security_group_association" "services_subnet" {
  subnet_id                 = "${azurerm_subnet.services_subnet.id}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}


resource "azurerm_subnet" "pks_services_subnet" {
  name = "${var.env_name}-pks-services-subnet"

  //  depends_on                = ["${var.resource_group_name}"]
  resource_group_name       = "${var.resource_group_name}"
  virtual_network_name      = "${var.network_name}"
  address_prefix            = "${var.pks_services_subnet_cidr}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

resource "azurerm_subnet_network_security_group_association" "pks_services_subnet" {
  subnet_id                 = "${azurerm_subnet.pks_services_subnet.id}"
  network_security_group_id = "${var.bosh_deployed_vms_security_group_id}"
}

// Security Group for PKS API Nodes

resource "azurerm_application_security_group" "pks-master" {
  name                = "${var.env_name}-pks-master-app-sec-group"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_application_security_group" "pks-api" {
  name                = "${var.env_name}-pks-api-app-sec-group"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

// Allow access from the internet to the masters
resource "azurerm_network_security_group" "pks-master" {
  name                = "${var.env_name}-pks-master-sg"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  security_rule {
    name                                       = "master"
    priority                                   = 100
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    destination_port_range                     = "8443"
    source_address_prefix                      = "*"
    destination_application_security_group_ids = ["${azurerm_application_security_group.pks-master.id}"]
  }
}

// Allow access from the internet to the PKS API VM
resource "azurerm_network_security_group" "pks-api" {
  name                = "${var.env_name}-pks-api-sg"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  security_rule {
    name                                       = "api"
    priority                                   = 100
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_port_range                          = "*"
    destination_port_ranges                    = ["9021", "8443"]
    source_address_prefix                      = "*"
    destination_application_security_group_ids = ["${azurerm_application_security_group.pks-api.id}"]
  }
}

// Allow access from the internal VMs to the internal VMs via TCP and UDP
resource "azurerm_network_security_group" "pks-internal" {
  name                = "${var.env_name}-pks-internal-sg"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  security_rule {
    name                       = "internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["${local.pks_cidr}", "${local.pks_services_cidr}"]
    destination_address_prefix = "*"
  }
}
