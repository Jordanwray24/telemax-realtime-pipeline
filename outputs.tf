output "kinesis_stream_name" {
  value = aws_kinesis_stream.telemax_stream.name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.telemax_table.name
}

output "lambda_function_name" {
  value = aws_lambda_function.telemax_consumer.function_name
}

