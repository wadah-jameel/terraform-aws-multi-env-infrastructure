# ─── SECURITY GROUP ─────────────────────────────────────────
resource "aws_security_group" "this" {
  name        = "${var.environment}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id              # ← Passed from VPC module

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-ec2-sg"
  })
}

# ─── EC2 INSTANCES ──────────────────────────────────────────
resource "aws_instance" "this" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type

  # Distribute instances across subnets
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = [aws_security_group.this.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from ${var.environment} - Server ${count.index + 1}</h1>" \
    > /var/www/html/index.html
  EOF

  tags = merge(var.tags, {
    Name        = "${var.environment}-web-${count.index + 1}"
    Environment = var.environment
  })
}
