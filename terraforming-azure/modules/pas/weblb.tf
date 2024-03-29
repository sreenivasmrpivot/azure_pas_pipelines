resource "azurerm_public_ip" "web-lb-public-ip" {
  name                    = "web-lb-public-ip"
  location                = "${var.location}"
  resource_group_name     = "${var.resource_group_name}"
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 30
}

resource "azurerm_lb" "web" {
  name                = "${var.env_name}-web-lb"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "Standard"

  frontend_ip_configuration = {
    name                 = "frontendip"
    public_ip_address_id = "${azurerm_public_ip.web-lb-public-ip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "web-backend-pool" {
  name                = "web-backend-pool"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.web.id}"
}

resource "azurerm_lb_probe" "web-https-probe" {
  name                = "web-https-probe"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.web.id}"
  protocol            = "TCP"
  port                = 443
}

resource "azurerm_lb_rule" "web-https-rule" {
  name                = "web-https-rule"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.web.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = 443
  backend_port                   = 443
  idle_timeout_in_minutes        = 30

  backend_address_pool_id = "${azurerm_lb_backend_address_pool.web-backend-pool.id}"
  probe_id                = "${azurerm_lb_probe.web-https-probe.id}"
}

resource "azurerm_lb_probe" "web-http-probe" {
  name                = "web-http-probe"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.web.id}"
  protocol            = "TCP"
  port                = 80
}

resource "azurerm_lb_rule" "web-http-rule" {
  name                = "web-http-rule"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.web.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = 80
  backend_port                   = 80
  idle_timeout_in_minutes        = 30

  backend_address_pool_id = "${azurerm_lb_backend_address_pool.web-backend-pool.id}"
  probe_id                = "${azurerm_lb_probe.web-http-probe.id}"
}

resource "azurerm_lb_rule" "web-ntp" {
  name                = "web-ntp-rule"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.web.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "UDP"
  frontend_port                  = "123"
  backend_port                   = "123"

  backend_address_pool_id = "${azurerm_lb_backend_address_pool.web-backend-pool.id}"
}

resource "azurerm_public_ip" "pks-lb-ip" {
  name                = "${var.env_name}-pks-lb-ip"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "pks-lb" {
  name                = "${var.env_name}-pks-lb"
  location            = "${var.location}"
  sku                 = "Standard"
  resource_group_name = "${var.resource_group_name}"

  frontend_ip_configuration {
    name                 = "${azurerm_public_ip.pks-lb-ip.name}"
    public_ip_address_id = "${azurerm_public_ip.pks-lb-ip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "pks-lb-backend-pool" {
  name                = "${var.env_name}-pks-backend-pool"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.pks-lb.id}"
}

resource "azurerm_lb_probe" "pks-lb-uaa-health-probe" {
  name                = "${var.env_name}-pks-lb-uaa-health-probe"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.pks-lb.id}"
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
  port                = 8443
}

resource "azurerm_lb_rule" "pks-lb-uaa-rule" {
  name                           = "${var.env_name}-pks-lb-uaa-rule"
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.pks-lb.id}"
  protocol                       = "Tcp"
  frontend_port                  = 8443
  backend_port                   = 8443
  frontend_ip_configuration_name = "${azurerm_public_ip.pks-lb-ip.name}"
  probe_id                       = "${azurerm_lb_probe.pks-lb-uaa-health-probe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.pks-lb-backend-pool.id}"
}

resource "azurerm_lb_probe" "pks-lb-api-health-probe" {
  name                = "${var.env_name}-pks-lb-api-health-probe"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.pks-lb.id}"
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
  port                = 9021
}

resource "azurerm_lb_rule" "pks-lb-api-rule" {
  name                           = "${var.env_name}-pks-lb-api-rule"
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.pks-lb.id}"
  protocol                       = "Tcp"
  frontend_port                  = 9021
  backend_port                   = 9021
  frontend_ip_configuration_name = "${azurerm_public_ip.pks-lb-ip.name}"
  probe_id                       = "${azurerm_lb_probe.pks-lb-api-health-probe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.pks-lb-backend-pool.id}"
}

# MESH 

resource "azurerm_public_ip" "mesh-lb-public-ip" {
  name                    = "mesh-lb-public-ip"
  location                = "${var.location}"
  resource_group_name     = "${var.resource_group_name}"
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 30
}

resource "azurerm_lb" "mesh" {
  name                = "${var.env_name}-mesh-lb"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "Standard"

  frontend_ip_configuration = {
    name                 = "frontendip"
    public_ip_address_id = "${azurerm_public_ip.mesh-lb-public-ip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "mesh-backend-pool" {
  name                = "mesh-backend-pool"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.mesh.id}"
}


resource "azurerm_lb_probe" "mesh-healthcheck-probe" {
  name                = "mesh-healthcheck-probe"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.mesh.id}"
  protocol            = "HTTP"
  port                = 8002
  request_path        = "/healthcheck"
}

resource "azurerm_lb_rule" "mesh-https-rule" {
  name                = "mesh-https-rule"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.mesh.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = 443
  backend_port                   = 443
  idle_timeout_in_minutes        = 30

  backend_address_pool_id = "${azurerm_lb_backend_address_pool.mesh-backend-pool.id}"
  probe_id                = "${azurerm_lb_probe.mesh-healthcheck-probe.id}"
}

resource "azurerm_lb_rule" "mesh-http-rule" {
  name                = "mesh-http-rule"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.mesh.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = 80
  backend_port                   = 80
  idle_timeout_in_minutes        = 30

  backend_address_pool_id = "${azurerm_lb_backend_address_pool.mesh-backend-pool.id}"
  probe_id                = "${azurerm_lb_probe.mesh-healthcheck-probe.id}"
}

resource "azurerm_lb_rule" "mesh-http-8002-rule" {
  name                = "mesh-http-8002-rule"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.mesh.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = 8002
  backend_port                   = 8002
  idle_timeout_in_minutes        = 30

  backend_address_pool_id = "${azurerm_lb_backend_address_pool.mesh-backend-pool.id}"
  probe_id                = "${azurerm_lb_probe.mesh-healthcheck-probe.id}"
}

# isolation segment

resource "azurerm_public_ip" "iso-lb-public-ip" {
  name                    = "iso-lb-public-ip"
  location                = "${var.location}"
  resource_group_name     = "${var.resource_group_name}"
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 30
}

resource "azurerm_lb" "iso" {
  name                = "${var.env_name}-iso-lb"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "Standard"

  frontend_ip_configuration = {
    name                 = "frontendip"
    public_ip_address_id = "${azurerm_public_ip.iso-lb-public-ip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "iso-backend-pool" {
  name                = "iso-backend-pool"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.iso.id}"
}

resource "azurerm_lb_probe" "iso-https-probe" {
  name                = "iso-https-probe"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.iso.id}"
  protocol            = "TCP"
  port                = 443
}

resource "azurerm_lb_rule" "iso-https-rule" {
  name                = "iso-https-rule"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.iso.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = 443
  backend_port                   = 443
  idle_timeout_in_minutes        = 30

  backend_address_pool_id = "${azurerm_lb_backend_address_pool.iso-backend-pool.id}"
  probe_id                = "${azurerm_lb_probe.iso-https-probe.id}"
}

resource "azurerm_lb_probe" "iso-http-probe" {
  name                = "iso-http-probe"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.iso.id}"
  protocol            = "TCP"
  port                = 80
}

resource "azurerm_lb_rule" "iso-http-rule" {
  name                = "iso-http-rule"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.iso.id}"

  frontend_ip_configuration_name = "frontendip"
  protocol                       = "TCP"
  frontend_port                  = 80
  backend_port                   = 80
  idle_timeout_in_minutes        = 30

  backend_address_pool_id = "${azurerm_lb_backend_address_pool.iso-backend-pool.id}"
  probe_id                = "${azurerm_lb_probe.iso-http-probe.id}"
}