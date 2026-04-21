module "app" {
  # For local testing, use relative path. 
  # In CI/CD, developers will use the Git URL of the modules repo.
  source = "../modules/ecs-service" 
}
