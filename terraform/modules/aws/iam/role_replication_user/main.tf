/**
* ## Module: aws/iam/role_user
*
* This module creates a role with a trust relationship with IAM users from
* a trusted account. We need to specify the list of trusted users and
* policies to attach to the role.
*
* For instance, the following parameters allow the users 'user1' and 'user2'
* from the account ID 123456789000 to use the AWS Security Token Service
* AssumeRole API action to gain AdministratorAccess permissions on our account:
*
*```
* "role_name" = "myadmins"
*
* "role_policy_arns" = [
*   "arn:aws:iam::aws:policy/AdministratorAccess"
* ]
*
* "role_user_arns" = [
*   "arn:aws:iam::123456789000:user/user1",
*   "arn:aws:iam::123456789000:user/user2",
* ]
*```
*/
variable "role_name" {
  type        = "string"
  description = "The name of the Role"
}

variable "role_replication_user_arns" {
  type        = "list"
  description = "List of ARNs of external users that can assume the role"
}

variable "role_replication_policy_arns" {
  type        = "list"
  description = "List of ARNs of policies to attach to the role"
  default     = []
}

# Resources
#--------------------------------------------------------------

data "aws_iam_policy_document" "assume_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["${var.role_replication_user_arns}"]
    }

    condition {
      test = "IpAddress"
      variable = "aws:SourceIp"

      values = ["${var.office_ips}"]
  }
}

resource "aws_iam_role" "user_replication_role" {
  name               = "${var.role_name}"
  path               = "/"
  description        = "Role to Delegate Permissions to an IAM User: ${var.role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_policy_document.json}"
}

resource "aws_iam_role_policy_attachment" "user_replication_policy_attachment" {
  count      = "${length(var.role_policy_arns)}"
  role       = "${aws_iam_role.user_replication_role.name}"
  policy_arn = "${element(var.role_policy_arns, count.index)}"
}

# Outputs
#--------------------------------------------------------------

output "role_arn" {
  value       = "${aws_iam_role.user_replication_role.arn}"
  description = "The ARN specifying the role."
}

