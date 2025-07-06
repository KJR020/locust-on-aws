/**
 * ネットワークモジュールの出力変数
 */

output "vpc_id" {
  description = "作成されたVPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "パブリックサブネットのID"
  value       = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  description = "プライベートサブネットのID"
  value       = aws_subnet.private.*.id
}
