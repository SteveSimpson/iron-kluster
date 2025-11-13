output "k8s_contol_node_ids" {
  value = [for instance in aws_instance.ec2_k8s_nodes : instance.id if instance.tags["Function"] == "control"]
}
