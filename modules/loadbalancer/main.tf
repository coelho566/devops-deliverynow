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

resource "aws_lb_target_group" "deliverynow_tg_1" {
  name        = "${var.api_name}-tg-ip-1"
  port        = "31001"
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

resource "aws_lb_target_group" "deliverynow_tg_2" {
  name        = "${var.api_name}-tg-ip-2"
  port        = "31002"
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

resource "aws_lb_listener" "nlb_listener_1" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 81
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deliverynow_tg_1.arn
  }
}

resource "aws_lb_listener" "nlb_listener_2" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 82
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deliverynow_tg_2.arn
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

resource "aws_lb_target_group_attachment" "tg_attachment_2" {
  target_group_arn = aws_lb_target_group.deliverynow_tg_1.arn
  target_id        = data.aws_instance.foo.id
  port             = 31001
}

resource "aws_lb_target_group_attachment" "tg_attachment_3" {
  target_group_arn = aws_lb_target_group.deliverynow_tg_2.arn
  target_id        = data.aws_instance.foo.id
  port             = 31002
}




