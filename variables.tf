variable "create_iam_resources_per_cluster" {
  description = "Whether to generate IAM resources bound to single cluster that otherwise would be reused."
  type        = bool
  default     = true
}

variable "aws_cluster_name" {
  type        = string
  description = "Name of the cluster IAM resources will be created for."
}

variable "aws_cluster_region" {
  type        = string
  description = "Region of the cluster IAM resources will created for."
}

variable "aws_cluster_vpc_id" {
  type        = string
  description = "VPC of the cluster IAM resources will created for."
}

variable "aws_account_id" {
  type        = string
  description = "ID of AWS account the cluster is located in."
}

variable "castai_user_arn" {
  type        = string
  description = "ARN of CAST AI user for which AssumeRole trust access should be granted"
  default     = ""
}

variable "castai_cluster_id" {
  type        = string
  description = "ID of CAST AI cluster"
}
