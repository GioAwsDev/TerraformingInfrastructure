output "vpc_id" {
  description = "ID of project VPC"
  value       = aws_vpc.ProjectAVPC.id
}
