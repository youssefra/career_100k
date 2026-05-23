provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = "http://localhost:4567"
    organizations = "http://localhost:4567"
  }
}

# 1. Initialize the AWS Organization structure
resource "aws_organizations_organization" "vois_org" {
  feature_set = "ALL"
}

# 2. Create an Organizational Unit (OU) for Production workloads
resource "aws_organizations_organizational_unit" "production_ou" {
  name      = "Production-Workloads"
  parent_id = aws_organizations_organization.vois_org.roots[0].id
}

# 3. Define the Global Service Control Policy (SCP) Guardrail
# This SCP explicitly prevents any account under its umbrella from deleting CloudTrail logs
resource "aws_organizations_policy" "deny_cloudtrail_delete" {
  name        = "vOIS-Global-Audit-Guardrail"
  description = "Absolute restriction preventing deletion of security audit logs"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyCloudTrailModification"
        Effect   = "Deny"
        Action   = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
      }
    ]
  })
}

# 4. Attach the global SCP directly to our Production OU
resource "aws_organizations_policy_attachment" "apply_to_production" {
  policy_id = aws_organizations_policy.deny_cloudtrail_delete.id
  target_id = aws_organizations_organizational_unit.production_ou.id
}
