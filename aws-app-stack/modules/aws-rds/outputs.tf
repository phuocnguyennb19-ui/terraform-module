output "db_instance_endpoint"       { value = module.rds.db_instance_endpoint }
output "db_instance_address"        { value = module.rds.db_instance_address }
output "db_instance_port"           { value = module.rds.db_instance_port }
output "db_instance_name"           { value = module.rds.db_instance_name }
output "db_instance_username"       { value = module.rds.db_instance_username }
output "db_master_user_secret_arn"  { value = module.rds.db_instance_master_user_secret_arn }
output "security_group_id"          { value = module.rds_sg.security_group_id }
