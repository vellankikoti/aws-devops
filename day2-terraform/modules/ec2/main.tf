# =============================================================================
# EC2 Module - Sock Shop Application Server
# =============================================================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    yum update -y

    # Install Docker
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Deploy Sock Shop
    mkdir -p /opt/sockshop
    cat > /opt/sockshop/docker-compose.yml << 'COMPOSE'
    version: '3'
    services:
      front-end:
        image: weaveworksdemos/front-end:0.3.12
        ports:
          - "8079:8079"
        environment:
          - SESSION_REDIS=true
        restart: always

      catalogue:
        image: weaveworksdemos/catalogue:0.3.5
        restart: always

      catalogue-db:
        image: weaveworksdemos/catalogue-db:0.3.0
        environment:
          - MYSQL_ROOT_PASSWORD=fake_password
          - MYSQL_DATABASE=socksdb
        restart: always

      carts:
        image: weaveworksdemos/carts:0.4.8
        environment:
          - JAVA_OPTS=-Xms64m -Xmx128m -XX:+UseG1GC
        restart: always

      carts-db:
        image: mongo:4.4
        restart: always

      orders:
        image: weaveworksdemos/orders:0.4.7
        environment:
          - JAVA_OPTS=-Xms64m -Xmx128m -XX:+UseG1GC
        restart: always

      orders-db:
        image: mongo:4.4
        restart: always

      shipping:
        image: weaveworksdemos/shipping:0.4.8
        environment:
          - JAVA_OPTS=-Xms64m -Xmx128m -XX:+UseG1GC
        restart: always

      queue-master:
        image: weaveworksdemos/queue-master:0.3.1
        restart: always

      rabbitmq:
        image: rabbitmq:3.8-management
        restart: always

      payment:
        image: weaveworksdemos/payment:0.4.3
        restart: always

      user:
        image: weaveworksdemos/user:0.4.7
        restart: always

      user-db:
        image: weaveworksdemos/user-db:0.3.0
        restart: always
    COMPOSE

    cd /opt/sockshop
    docker-compose up -d

    echo "Sock Shop deployment complete!" > /tmp/deploy-status.txt
  EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-app-server"
    Role = "application"
  }
}
