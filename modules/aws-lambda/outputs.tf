output "function_name"    { value = module.lambda.lambda_function_name }
output "function_arn"     { value = module.lambda.lambda_function_arn }
output "invoke_arn"       { value = module.lambda.lambda_function_invoke_arn }
output "function_url"     { value = try(module.lambda.lambda_function_url, "") }
output "role_arn"         { value = module.lambda.lambda_role_arn }
output "role_name"        { value = module.lambda.lambda_role_name }
output "version"          { value = module.lambda.lambda_function_version }
