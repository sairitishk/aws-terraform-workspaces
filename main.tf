#This Terraform Code Deploys Basic VPC Infra.
provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      version = "<= 3.0.0" #Forcing which version of plugin needs to be used.
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "33tfstatebucket"
    key    = "devsecops33.tfstate"
    region = "us-east-1"
  }
}

resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name        = "${var.vpc_name}"
    Owner       = "Korrapati Naidu"
    environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "${var.IGW_name}"
  }
}

resource "aws_subnet" "subnet1-public" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet1_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.public_subnet1_name}"
  }
}

resource "aws_subnet" "subnet2-public" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet2_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "${var.public_subnet2_name}"
  }
}

resource "aws_subnet" "subnet3-public" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet3_cidr
  availability_zone = "us-east-1c"

  tags = {
    Name = "${var.public_subnet3_name}"
  }

}


resource "aws_route_table" "terraform-public" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "${var.Main_Routing_Table}"
  }
}

resource "aws_route_table_association" "terraform-public" {
  subnet_id      = aws_subnet.subnet1-public.id
  route_table_id = aws_route_table.terraform-public.id
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_instance" "web-1" {
  ami                         = "ami-0261755bbcb8c4a84"
  instance_type               = "t2.micro"
  key_name                    = "test"
  subnet_id                   = aws_subnet.subnet1-public.id
  vpc_security_group_ids      = ["${aws_security_group.allow_all.id}"]
  associate_public_ip_address = true
  tags = {
    Name       = "Server-1-${var.environment}"
    Env        = var.environment
    Owner      = "KSR"
    CostCenter = "ABCD"
  }

  user_data = <<-EOF
        #!/bin/bash
        sudo apt-get update
        sudo apt-get install -y nginx
        sudo systemctl start nginx
        sudo systemctl enable nginx
        sudo "<h1>${var.environment}</h1>" | sudo tee /var/www/html/index.html
    EOF    
}

##output "ami_id" {
#  value = "${data.aws_ami.my_ami.id}"
#}
#!/bin/bash
# echo "Listing the files in the repo."
# ls -al
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Packer Now...!!"
# packer build -var=aws_access_key=AAAAAAAAAAAAAAAAAA -var=aws_secret_key=BBBBBBBBBBBBB packer.json
#packer validate --var-file creds.json packer.json
#packer build --var-file creds.json packer.json
#packer.exe build --var-file creds.json -var=aws_access_key=AAAAAAAAAAAAAAAAAA -var=aws_secret_key=BBBBBBBBBBBBB packer.json
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Terraform Now...!!"
# terraform init
# terraform apply --var-file terraform.tfvars -var="aws_access_key=AAAAAAAAAAAAAAAAAA" -var="aws_secret_key=BBBBBBBBBBBBB" --auto-approve
#https://discuss.devopscube.com/t/how-to-get-the-ami-id-after-a-packer-build/36
