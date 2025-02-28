locals {
  resource_name_postfix = var.aws_cluster_name

  iam_role_name              = "castai-eks-${substr(local.resource_name_postfix, 0, 53)}"
  iam_policy_name            = var.create_iam_resources_per_cluster ? "CastEKSPolicy-${local.resource_name_postfix}" : "CastEKSPolicy-tf"
  iam_role_policy_name       = "castai-user-policy-${substr(local.resource_name_postfix, 0, 45)}"
  instance_profile_role_name = "cast-${substr(local.resource_name_postfix, 0, 40)}-eks-${substr(var.castai_cluster_id, 0, 8)}"
  iam_policy_prefix          = "arn:${data.aws_partition.current.partition}:iam::aws:policy"
}

data "aws_partition" "current" {}

# castai eks settings (provides required iam policies)

data "castai_eks_settings" "eks" {
  account_id = var.aws_account_id
  vpc        = var.aws_cluster_vpc_id
  region     = var.aws_cluster_region
  cluster    = var.aws_cluster_name
}

resource "aws_iam_role_policy_attachment" "castai_iam_policy_attachment" {
  role       = aws_iam_role.cast_role.name
  policy_arn = aws_iam_policy.castai_iam_policy.arn
}

resource "aws_iam_role" "cast_role" {
  name               = local.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.cast_assume_role_policy.json
}

moved {
  from = aws_iam_role.test_role
  to   = aws_iam_role.cast_role
}

resource "aws_iam_policy" "castai_iam_policy" {
  name   = local.iam_policy_name
  policy = data.castai_eks_settings.eks.iam_policy_json
}

resource "aws_iam_role_policy_attachment" "castai_iam_readonly_policy_attachment" {
  for_each = toset([
    "${local.iam_policy_prefix}/AmazonEC2ReadOnlyAccess",
    "${local.iam_policy_prefix}/IAMReadOnlyAccess",
  ])
  role       = aws_iam_role.cast_role.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "castai_role_iam_policy" {
  name   = local.iam_role_policy_name
  role   = aws_iam_role.cast_role.name
  policy = data.castai_eks_settings.eks.iam_user_policy_json
}
# iam - instance profile role

resource "aws_iam_role" "instance_profile_role" {
  name               = local.instance_profile_role_name
  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        Sid       = ""
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = ["sts:AssumeRole"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = local.instance_profile_role_name
  role = aws_iam_role.instance_profile_role.name
}

resource "aws_iam_role_policy_attachment" "castai_instance_profile_policy" {
  for_each = toset([
    "${local.iam_policy_prefix}/AmazonEKSWorkerNodePolicy",
    "${local.iam_policy_prefix}/AmazonEC2ContainerRegistryReadOnly",
    "${local.iam_policy_prefix}/AmazonEKS_CNI_Policy"
  ])

  role       = aws_iam_instance_profile.instance_profile.role
  policy_arn = each.value
}

data "aws_iam_policy_document" "cast_assume_role_policy" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = [var.castai_user_arn]
    }
  }
}

