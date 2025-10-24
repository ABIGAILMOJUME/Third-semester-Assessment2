###Create a new IAM user for our development team.
##This user must have read-only access to the resources within the EKS cluster. The goal is to allow developers to view logs, describe pods, and check service status without being able to make changes.
##Provide the necessary credentials and configuration instructions for this user.

resource "aws_iam_user" "dev_user" {
  name = "dev-user"
}

resource "aws_iam_user_policy" "dev_user_readonly" {
  name   = "dev-user-readonly"
  user   = aws_iam_user.dev_user.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "eks:Describe*",
          "eks:List*",
          "logs:Describe*",
          "logs:List*",
          "logs:Get*",
          "ec2:Describe*",
          "ec2:List*"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "dev_user_access_key" {
  user = aws_iam_user.dev_user.name
}

### attachment policy for user to access EKS cluster and read-only access to the resources within the EKS cluster
resource "aws_iam_user_policy_attachment" "dev_user_eks_readonly" {
  user       = aws_iam_user.dev_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSReadOnlyAccess"
}

