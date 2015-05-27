provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_instance" "nginx" {
  ami = "ami-4ddffc4c"
  connection {
    user = "ubuntu"
    key_file = "${var.key_path}"
  }
  instance_type = "t1.micro"
  key_name = "${var.key_name}"

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo /etc/init.d/nginx restart"
    ]
  }

  security_groups = ["${aws_security_group.development.name}", "${aws_security_group.allow_ssh.name}"]
  depends_on = ["aws_security_group.development", "aws_security_group.allow_ssh"]
  count = 2
}

resource "aws_security_group" "development" {
  name = "development"
  description = "allow all traffic in development"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
    security_groups = ["${aws_security_group.allow_http.id}"]
  }
}

resource "aws_security_group" "allow_http" {
  name = "allow_http"
  description = "allow all inbound traffic"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "test-elb" {
  name = "test-elb"
  availability_zones = ["ap-northeast-1a", "ap-northeast-1c"]
  availability_zones = ["${var.region}"]
  listener {
    instance_protocol = "http"
    instance_port = 80
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 5
  }
  instances = ["${aws_instance.nginx.id}"]
  security_groups = ["${aws_security_group.allow_http.id}"]
  depends_on = ["aws_instance.nginx"]
}
