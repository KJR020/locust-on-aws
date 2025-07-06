/**
 * ネットワークモジュール
 * VPC、サブネット、ルートテーブル、インターネットゲートウェイなどを作成します
 */

/**
 * VPCの作成
 */
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.general_name}-vpc"
  }
}

/**
 * インターネットゲートウェイの作成
 */
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.general_name}-igw"
  }
}

/**
 * パブリックサブネットの作成
 */
resource "aws_subnet" "public" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.general_name}-public-subnet-${count.index + 1}"
  }
}

/**
 * プライベートサブネットの作成
 */
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, var.az_count + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.general_name}-private-subnet-${count.index + 1}"
  }
}

/**
 * パブリックルートテーブルの作成
 */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.general_name}-public-rt"
  }
}

/**
 * パブリックルートテーブルの関連付け
 */
resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

/**
 * NATゲートウェイ用のEIPの作成
 */
resource "aws_eip" "nat" {
  count = var.az_count
  domain = "vpc"

  tags = {
    Name = "${var.general_name}-nat-eip-${count.index + 1}"
  }
}

/**
 * NATゲートウェイの作成
 */
resource "aws_nat_gateway" "main" {
  count         = var.az_count
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = {
    Name = "${var.general_name}-nat-gw-${count.index + 1}"
  }
}

/**
 * プライベートルートテーブルの作成
 */
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.main.*.id, count.index)
  }

  tags = {
    Name = "${var.general_name}-private-rt-${count.index + 1}"
  }
}

/**
 * プライベートルートテーブルの関連付け
 */
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

/**
 * 利用可能なアベイラビリティゾーンの取得
 */
data "aws_availability_zones" "available" {}
