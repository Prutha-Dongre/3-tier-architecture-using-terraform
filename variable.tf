variable "region" {
  default = "us-east-1"
}

variable "vpc-cidr" {
  default = "10.0.0.0/16"
}

variable "project-name" {
  default = "3-tier"
}

variable "az1" {
  default = "us-east-1a"
}

variable "az2" {
  default = "us-east-1b"
}

variable "az3" {
  default = "us-east-1c"
}

variable "cidr-pub-sub" {
  default = "10.0.0.0/20"
}

variable "cidr-pri-sub-1" {
  default = "10.0.16.0/20"
}

variable "cidr-pri-sub-2" {
  default = "10.0.32.0/20"
}

variable "igw-cidr" {
  default = "0.0.0.0/0"
}

variable "nat-cidr" {
  default = "0.0.0.0/0"
} 


variable "ami" {
  default = "ami-0fa3fe0fa7920f68e"
}

variable "instance-type" {
  default = "t3.micro"
}

variable "key" {
  default = "north-v-key"
}