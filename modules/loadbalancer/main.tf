# Criação do Network Load Balancer
resource "aws_lb" "nlb" {
  name               = "${var.api_name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.vpc_link_subnets # Subnets onde o NLB estará disponível
  
  enable_deletion_protection = false
}

# Grupo de Alvos (Target Group) com IPs Privados
resource "aws_lb_target_group" "deliverynow_tg" {
  name        = "${var.api_name}-tg-ip"
  port        = "31000"
  protocol    = "TCP"
  vpc_id      = var.vpc_id

  health_check {
    protocol            = "TCP"  # TCP health check
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

}

# Listeners para o NLB
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deliverynow_tg.arn
  }
}

data "aws_instance" "foo" {
    filter {
    name   = "tag:eks:cluster-name"
    values = ["deliverynow-eks"]
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment_1" {
  target_group_arn = aws_lb_target_group.deliverynow_tg.arn
  target_id        = data.aws_instance.foo.id
  port             = 31000
}




