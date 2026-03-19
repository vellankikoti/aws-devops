# Auto Scaling Group Configuration
resource "aws_launch_template" "app" {
  name_prefix   = "sockshop-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_pair_name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_version = var.app_version
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "sockshop-asg-instance"
      Project = "SockShop"
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "sockshop-asg"
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = 2
  min_size            = 1
  max_size            = 4

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [var.target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Project"
    value               = "SockShop"
    propagate_at_launch = true
  }
}
