provider aws{
    region     = "us-east-1"
    access_key = "AKIAWQHBZW"
    secret_key = "Tw1bSFiP5e3xCmcjmL9QYQ"
}


resource "aws_vpc" "lwterra" {
  
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "task5_vpc"
  }
}

resource "aws_subnet" "subnet1" {
  depends_on= [aws_vpc.lwterra]
  vpc_id     = aws_vpc.lwterra.id
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "my_subnet"
  }
}


resource "aws_internet_gateway" "igw" {
  depends_on= [aws_vpc.lwterra]
  vpc_id = aws_vpc.lwterra.id

  tags = {
    Name = "web_igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.lwterra.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "web_route_table"
  }
}

resource "aws_route_table_association" "rt_subnet_asso" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "web_sg" {
  name        = "web_allow_all"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.lwterra.id

  ingress {
    description      = "Allow all Port"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_allow_all"
  }
}


resource "aws_instance" "OS5" {
    ami= "ami-0c2b8ca1dad447f8a" 
    availability_zone = "us-east-1a"
    instance_type= "t2.micro"
    key_name= "task5"
    vpc_security_group_ids= ["${aws_security_group.web_sg.id}"] 
    subnet_id= aws_subnet.subnet1.id 
    tags={
        Name= "webos"
    }
}

resource "aws_ebs_volume" "ebs1"{
    availability_zone= aws_instance.OS5.availability_zone
    size= 1
    tags={
        Name= "web_hd"
    }
}

resource "aws_volume_attachment" "ebs_attach"{
    device_name= "/dev/xvdc"
    volume_id= aws_ebs_volume.ebs1.id
    instance_id= aws_instance.OS5.id 
}

resource "null_resource" "webapp" {
           
    connection{
        type= "ssh"
        user= "ec2-user"
        private_key= file("C:/Users/YASH RAUT/Documents/Terraform/task5.pem")
        host= aws_instance.OS5.public_ip
    }

    provisioner "remote-exec" {
        inline= [
            "sudo yum install httpd -y",
            "sudo systemctl start httpd",
            "sudo yum install git -y",
            "sudo git clone https://github.com/Himni2424/Terraform_task5_vpc.git",
            "sudo mkfs.ext4  /dev/xvdc",
            "sudo mount /dev/xvdc /var/www/html",
            "sudo cp /home/ec2-user/Terraform_task5_vpc/index.html  /var/www/html"
        ]
    }
}

resource "null_resource" "chrome"  {


	provisioner "local-exec" {
	    command = "chrome  http://${aws_instance.OS5.public_ip}"
  	}

}







#ami-04db49c0fb2215364