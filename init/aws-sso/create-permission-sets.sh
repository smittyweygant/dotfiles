#!/usr/bin/env bash
# One-time Identity Center setup for a new organization: creates the
# ClaudeDev, ClaudeElevated, Admin and ReadOnly permission sets and assigns
# Admin and ReadOnly to the human user and ClaudeDev to Claude's user. ClaudeElevated stays unassigned;
# aws-elevate grants it on demand. Both users must already exist (console:
# IAM Identity Center > Users). Not safe to re-run: the permission sets would
# already exist.
#
# Run from this directory, signed in as an administrator:
#   AWS_PROFILE=admin ./create-permission-sets.sh
# Values come from ~/.config/aws-sso/env (see aws-sso-setup).
set -euo pipefail

. "$HOME/.config/aws-sso/env"
I=$AWS_SSO_INSTANCE_ARN
A="aws"

user_id() {
  $A identitystore get-user-id --identity-store-id "$AWS_SSO_IDENTITY_STORE_ID" \
    --alternate-identifier "{\"UniqueAttribute\":{\"AttributePath\":\"UserName\",\"AttributeValue\":\"$1\"}}" \
    --query UserId --output text
}
HUMAN_ID=$(user_id "$AWS_SSO_HUMAN_USER")
CLAUDE_ID=$(user_id "$AWS_SSO_CLAUDE_USER")

make_permission_set() {  # name, duration, description -> ARN
  $A sso-admin create-permission-set --instance-arn "$I" --name "$1" \
    --session-duration "$2" --description "$3" \
    --query 'PermissionSet.PermissionSetArn' --output text
}
ClaudeDev=$(make_permission_set ClaudeDev PT8H "Read-only, for Claude Code sessions")
ClaudeElevated=$(make_permission_set ClaudeElevated PT1H "EC2, ECR, SSM, Route 53 write; finances bucket read/write; Parameter Store /finances/* denied, no interactive host shells")
Admin=$(make_permission_set Admin PT1H "Full administrator, human only")
ReadOnly=$(make_permission_set ReadOnly PT8H "Read-only including data, human only")

VIEW=arn:aws:iam::aws:policy/job-function/ViewOnlyAccess
for ps in "$ClaudeDev" "$ClaudeElevated"; do
  $A sso-admin attach-managed-policy-to-permission-set --instance-arn "$I" \
    --permission-set-arn "$ps" --managed-policy-arn "$VIEW"
done
$A sso-admin attach-managed-policy-to-permission-set --instance-arn "$I" \
  --permission-set-arn "$ReadOnly" --managed-policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
$A sso-admin put-inline-policy-to-permission-set --instance-arn "$I" \
  --permission-set-arn "$ClaudeElevated" --inline-policy file://ClaudeElevated-inline-policy.json
$A sso-admin attach-managed-policy-to-permission-set --instance-arn "$I" \
  --permission-set-arn "$Admin" --managed-policy-arn arn:aws:iam::aws:policy/AdministratorAccess

assign() {  # permission-set ARN, user ID
  $A sso-admin create-account-assignment --instance-arn "$I" --target-id "$AWS_SSO_ACCOUNT_ID" \
    --target-type AWS_ACCOUNT --permission-set-arn "$1" --principal-type USER --principal-id "$2"
}
assign "$Admin" "$HUMAN_ID"
assign "$ReadOnly" "$HUMAN_ID"
assign "$ClaudeDev" "$CLAUDE_ID"
echo "Done. Grant ClaudeElevated with: aws-elevate on"
