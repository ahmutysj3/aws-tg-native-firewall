resource "aws_networkfirewall_firewall" "main" {
  name                = "main"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = aws_vpc.spokes["az1"].id
  subnet_mapping {
    subnet_id = aws_subnet.spokes_private["az1"].id
  }

  tags = {
    Name = "main_network_firewall"
  }
}

resource "aws_networkfirewall_firewall_policy" "main" {
  name = "main"

  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:drop"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.main.arn
    }
  }

  tags = {
    Name = "main_network_firewall_policy"
  }
}

resource "aws_networkfirewall_rule_group" "main" {
  capacity = 100
  name     = "main-rule-group"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      stateful_rule {
        action = "DROP"
        header {
          destination      = aws_vpc.security.cidr_block
          destination_port = 22
          direction        = "ANY"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }
    }
  }

  tags = {
    Name = "main_network_firewall_rule_group"
  }
}