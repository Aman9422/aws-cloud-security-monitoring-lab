package terraform.security

import rego.v1

# Block public IPv4 SSH access
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_security_group"
    is_object(resource.change.after)

    some rule in object.get(resource.change.after, "ingress", [])
    rule.from_port <= 22
    rule.to_port >= 22

    some cidr in object.get(rule, "cidr_blocks", [])
    cidr == "0.0.0.0/0"

    msg := sprintf(
        "SECURITY VIOLATION: Security group '%s' exposes SSH (port 22) to public IPv4.",
        [resource.name]
    )
}

# Block public IPv6 SSH access
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_security_group"
    is_object(resource.change.after)

    some rule in object.get(resource.change.after, "ingress", [])
    rule.from_port <= 22
    rule.to_port >= 22

    some cidr in object.get(rule, "ipv6_cidr_blocks", [])
    cidr == "::/0"

    msg := sprintf(
        "SECURITY VIOLATION: Security group '%s' exposes SSH (port 22) to public IPv6.",
        [resource.name]
    )
}

# Block public IPv4 RDP access
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_security_group"
    is_object(resource.change.after)

    some rule in object.get(resource.change.after, "ingress", [])
    rule.from_port <= 3389
    rule.to_port >= 3389

    some cidr in object.get(rule, "cidr_blocks", [])
    cidr == "0.0.0.0/0"

    msg := sprintf(
        "SECURITY VIOLATION: Security group '%s' exposes RDP (port 3389) to public IPv4.",
        [resource.name]
    )
}

# Block public IPv6 RDP access
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_security_group"
    is_object(resource.change.after)

    some rule in object.get(resource.change.after, "ingress", [])
    rule.from_port <= 3389
    rule.to_port >= 3389

    some cidr in object.get(rule, "ipv6_cidr_blocks", [])
    cidr == "::/0"

    msg := sprintf(
        "SECURITY VIOLATION: Security group '%s' exposes RDP (port 3389) to public IPv6.",
        [resource.name]
    )
}

# Require encryption on the EC2 root EBS volume
instance_root_volume_encrypted(after) if {
    root_devices := object.get(after, "root_block_device", [])
    is_array(root_devices)
    some device in root_devices
    object.get(device, "encrypted", false) == true
}

deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_instance"
    is_object(resource.change.after)

    not instance_root_volume_encrypted(resource.change.after)

    msg := sprintf(
        "SECURITY VIOLATION: EC2 instance '%s' must use an encrypted root EBS volume.",
        [resource.name]
    )
}

# Require encryption on separately provisioned EBS volumes
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_ebs_volume"
    is_object(resource.change.after)

    object.get(resource.change.after, "encrypted", false) != true

    msg := sprintf(
        "SECURITY VIOLATION: EBS volume '%s' must have encryption enabled.",
        [resource.name]
    )
}

# Require IMDSv2 on EC2 instances
instance_uses_imdsv2(after) if {
    metadata_options := object.get(after, "metadata_options", [])
    is_array(metadata_options)

    some metadata in metadata_options
    is_object(metadata)

    object.get(metadata, "http_tokens", "") == "required"
}

deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_instance"
    is_object(resource.change.after)

    not instance_uses_imdsv2(resource.change.after)

    msg := sprintf(
        "SECURITY VIOLATION: EC2 instance '%s' must require IMDSv2.",
        [resource.name]
    )
}

# Convert a single action into an array for consistent checking
as_array(value) := [value] if {
    is_string(value)
}

as_array(value) := value if {
    is_array(value)
}

# Read IAM policy statements whether Statement is an object or array
policy_statements(policy_json) := statements if {
    document := json.unmarshal(policy_json)
    statements := object.get(document, "Statement", [])
    is_array(statements)
}

policy_statements(policy_json) := [statement] if {
    document := json.unmarshal(policy_json)
    statement := object.get(document, "Statement", {})
    is_object(statement)
}

# Identify wildcard actions
action_is_wildcard(action) if {
    action == "*"
}

action_is_wildcard(action) if {
    action == "*:*"
}

action_is_wildcard(action) if {
    endswith(action, ":*")
}

# Reject overly broad Allow statements in customer-defined IAM policies
deny contains msg if {
    some resource in input.resource_changes

    resource.type in {
        "aws_iam_policy",
        "aws_iam_role_policy",
        "aws_iam_user_policy",
        "aws_iam_group_policy"
    }

    after := object.get(resource.change, "after", null)
    is_object(after)

    policy_json := object.get(after, "policy", "")
    is_string(policy_json)

    some statement in policy_statements(policy_json)
    object.get(statement, "Effect", "") == "Allow"

    some action in as_array(object.get(statement, "Action", []))
    is_string(action)
    action_is_wildcard(action)

    msg := sprintf(
        "SECURITY VIOLATION: IAM policy '%s' grants an overly broad wildcard action '%s'.",
        [resource.name, action]
    )
}

# Prevent attaching highly privileged AWS-managed policies
deny contains msg if {
    some resource in input.resource_changes

    resource.type in {
        "aws_iam_role_policy_attachment",
        "aws_iam_user_policy_attachment",
        "aws_iam_group_policy_attachment"
    }

    after := object.get(resource.change, "after", null)
    is_object(after)

    policy_arn := object.get(after, "policy_arn", "")
    is_string(policy_arn)

    some policy_name in {
        "AdministratorAccess",
        "PowerUserAccess"
    }

    endswith(policy_arn, sprintf("/%s", [policy_name]))

    msg := sprintf(
        "SECURITY VIOLATION: IAM attachment '%s' uses prohibited managed policy '%s'.",
        [resource.name, policy_name]
    )
}

# Block public IPv4 SSH using a standalone ingress rule
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_vpc_security_group_ingress_rule"

    after := object.get(resource.change, "after", null)
    is_object(after)

    object.get(after, "from_port", 0) <= 22
    object.get(after, "to_port", 0) >= 22
    object.get(after, "cidr_ipv4", "") == "0.0.0.0/0"

    msg := sprintf(
        "SECURITY VIOLATION: Ingress rule '%s' exposes SSH to public IPv4.",
        [resource.name]
    )
}

# Block public IPv6 SSH using a standalone ingress rule
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_vpc_security_group_ingress_rule"

    after := object.get(resource.change, "after", null)
    is_object(after)

    object.get(after, "from_port", 0) <= 22
    object.get(after, "to_port", 0) >= 22
    object.get(after, "cidr_ipv6", "") == "::/0"

    msg := sprintf(
        "SECURITY VIOLATION: Ingress rule '%s' exposes SSH to public IPv6.",
        [resource.name]
    )
}

# Block public IPv4 RDP using a standalone ingress rule
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_vpc_security_group_ingress_rule"

    after := object.get(resource.change, "after", null)
    is_object(after)

    object.get(after, "from_port", 0) <= 3389
    object.get(after, "to_port", 0) >= 3389
    object.get(after, "cidr_ipv4", "") == "0.0.0.0/0"

    msg := sprintf(
        "SECURITY VIOLATION: Ingress rule '%s' exposes RDP to public IPv4.",
        [resource.name]
    )
}

# Block public IPv6 RDP using a standalone ingress rule
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_vpc_security_group_ingress_rule"

    after := object.get(resource.change, "after", null)
    is_object(after)

    object.get(after, "from_port", 0) <= 3389
    object.get(after, "to_port", 0) >= 3389
    object.get(after, "cidr_ipv6", "") == "::/0"

    msg := sprintf(
        "SECURITY VIOLATION: Ingress rule '%s' exposes RDP to public IPv6.",
        [resource.name]
    )
}

# Identify unrestricted outbound traffic
unrestricted_egress(rule) if {
    object.get(rule, "ip_protocol", "") == "-1"
}

unrestricted_egress(rule) if {
    object.get(rule, "ip_protocol", "") in {"tcp", "udp"}
    object.get(rule, "from_port", -1) == 0
    object.get(rule, "to_port", -1) == 65535
}

# Block unrestricted public IPv4 egress
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_vpc_security_group_egress_rule"

    after := object.get(resource.change, "after", null)
    is_object(after)

    object.get(after, "cidr_ipv4", "") == "0.0.0.0/0"
    unrestricted_egress(after)

    msg := sprintf(
        "SECURITY VIOLATION: Egress rule '%s' allows unrestricted outbound IPv4 traffic.",
        [resource.name]
    )
}

# Block unrestricted public IPv6 egress
deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_vpc_security_group_egress_rule"

    after := object.get(resource.change, "after", null)
    is_object(after)

    object.get(after, "cidr_ipv6", "") == "::/0"
    unrestricted_egress(after)

    msg := sprintf(
        "SECURITY VIOLATION: Egress rule '%s' allows unrestricted outbound IPv6 traffic.",
        [resource.name]
    )
}