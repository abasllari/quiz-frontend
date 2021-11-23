terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.86.0"
    }
  }
}
resource "random_pet" "prefix" {}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "prodrg" {
  name     = "prodrg"
  location = "westeurope"

  tags = {
    environment = "Demo"
  }
}

resource "azurerm_kubernetes_cluster" "dpro" {
  name                = "dpro"
  location            = azurerm_resource_group.prodrg.location
  resource_group_name = azurerm_resource_group.prodrg.name
  dns_prefix          = "${random_pet.prefix.id}-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }
  }
  service_principal {
    client_id     = "27e530d1-1e3e-4878-9042-0dc659fe6a4e"
    client_secret = "NPsa0Xun9u3LDJaD.042origM~sNO_R~g9"
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = "Demo"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace" "final" {
  metadata {
    name = "${random_pet.prefix.id}-nm"
  }
}
#Backend Deployments

resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "${random_pet.prefix.id}-backend"
    namespace = "${random_pet.prefix.id}-nm"
  }
  spec {
    replicas = 2
      selector {
          match_labels = {
            app = "quiz-backend"
          }
        }
    template {
      metadata {
        labels = {
          app = "quiz-backend"
        }
      }
      spec {

        container {
          image   = "abasllari/quiz-backend"
          name    = "quiz-backend"
          image_pull_policy = "Always"
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backendservice" {
  metadata {
    name = "${random_pet.prefix.id}-bcksrv"
    namespace = "${random_pet.prefix.id}-nm"
  }
  spec {
    type = "ClusterIP"
    port {
      port        = 8080
      target_port = "8080"
    }
    selector = {
      app = "quiz-backend"
    }
  }
}
#Frontend deployments

resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend"
    namespace = "${random_pet.prefix.id}-nm"
  }
  spec {
    replicas = 2
      selector {
          match_labels = {
            app = "frontend"
          }
        }
    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }
      spec {

        container {
          image   = "abasllari/quiz-frontend"
          name    = "frontend"
          image_pull_policy = "Always"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name = "frontend"
    namespace = "${random_pet.prefix.id}-nm"
  }
  spec {
    type = "ClusterIP"
    port {
      port        = 80
      target_port = "80"
    }
    selector = {
      app = "frontend"
    }
  }
}

# Ingress

resource "helm_release" "ingress_nginx" {
  name       = "${random_pet.prefix.id}-aks"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "${random_pet.prefix.id}-nm"
  timeout    = 300

}


resource "kubernetes_ingress" "ingress-front-back" {
  metadata {
    labels                = {
      app = "ingress-nginx"
    }
    name = "${random_pet.prefix.id}-frt"
    namespace = "${random_pet.prefix.id}-nm"
    annotations = {
      "kubernetes.io/ingress.class": "nginx"
        "nginx.ingress.kubernetes.io/ssl-redirect": "false"
        "nginx.ingress.kubernetes.io/use-regex": "true"
        "nginx.ingress.kubernetes.io/rewrite-target": "/$1"
    }
  }

  spec {
    rule {
      http {
        path {
          backend {
            service_name = "${random_pet.prefix.id}-bcksrv"
            service_port = 8080
          }

          path = "/api/quiz/?(.*)"
        }

        path {
          backend {
            service_name = "frontend"
            service_port = 80
          }

          path = "/?(.*)"
        }
      }
    }
  }
}
