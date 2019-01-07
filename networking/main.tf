data "aws_availability_zones" "available" {}

resource "aws_subnet" "private_subnet" {
  count = 2
  vpc_id = "${var.vpc_id}"
  
  cidr_block = "${var.private_subnet_cidrs[count.index]}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  tags {
        Name = "private_subnet_${count.index + 1}"
    }
}

resource "aws_route_table" "private_subnet_route_table" {
  vpc_id = "${var.vpc_id}"
  
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${var.nat_gateway_id}"
  }

  tags {
        Name = "Private Subnet Route Table"
    }
}

resource "aws_route_table_association" "private_route_table_assoc" {
  count = "${aws_subnet.private_subnet.count}"
  subnet_id = "${aws_subnet.private_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.private_subnet_route_table.id}"
}
