data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "deploy" {
  key_name   = "jenkins-deploy"
  public_key = file(pathexpand("~/.ssh/backend-ev.pub"))
}

resource "aws_security_group" "app" {
  name = "backend-ev-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "server" {
  name = "backend-ev-server-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "server_s3" {
  name = "backup-s3-put"
  role = aws_iam_role.server.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:ListBucket"]
      Resource = [aws_s3_bucket.backup.arn, "${aws_s3_bucket.backup.arn}/*"]
    }]
  })
}

resource "aws_iam_instance_profile" "server" {
  name = "backend-ev-server-profile"
  role = aws_iam_role.server.name
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.deploy.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.server.name

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ubuntu
    systemctl enable --now docker
    mkdir -p /home/ubuntu/app
    chown ubuntu:ubuntu /home/ubuntu/app
    echo "0 */3 * * * cd /home/ubuntu/app && docker compose --profile backup run --rm backup >> /home/ubuntu/backup.log 2>&1" | crontab -u ubuntu -
  EOF

  tags = { Name = "backend-ev-server" }
}

output "server_ip" {
  value = aws_instance.app.public_ip
}