locals {
  aws_region       = "us-east-1"
  environment_name = "staging"
  tags = {
    ops_env              = "${local.environment_name}"
    ops_managed_by       = "terraform",
    ops_source_repo      = "kubernetes-ops",
    ops_source_repo_path = "terraform-environments/aws/${local.environment_name}/25-eks-cluster-autoscaler",
    ops_owners           = "devops",
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.37.0"
    }
    random = {
      source = "hashicorp/random"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.3.0"
    }
  }

  backend "remote" {
    # Update to your Terraform Cloud organization
    organization = "managedkube"

    workspaces {
      name = "kubernetes-ops-staging-25-eks-cluster-autoscaler"
    }
  }
}

provider "aws" {
  region = local.aws_region
}

data "terraform_remote_state" "eks" {
  backend = "remote"
  config = {
    # Update to your Terraform Cloud organization
    organization = "managedkube"
    workspaces = {
      name = "kubernetes-ops-staging-20-eks"
    }
  }
}

#
# EKS authentication
# # https://registry.terraform.io/providers/hashicorp/helm/latest/docs#exec-plugins
provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", "${local.environment_name}"]
      command     = "aws"
    }
  }
}

#
# Helm - cluster-autoscaler
#
module "cluster-autoscaler" {
  source = "github.com/arikamir/kubernetes-ops-modules//terraform-modules/aws/cluster-autoscaler?ref=v1.0.30"

  aws_region                  = local.aws_region
  cluster_name                = local.environment_name
  eks_cluster_id              = data.terraform_remote_state.eks.outputs.cluster_id
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url

  depends_on = [
    data.terraform_remote_state.eks
  ]
}
