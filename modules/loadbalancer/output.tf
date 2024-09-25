output "nlb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.nlb.arn
}

output "nlb_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.nlb.dns_name
}

output "nlb_listener_arn" {
  description = "ARN of the load balancer listener"
  value       = aws_lb_listener.nlb_listener.arn
}