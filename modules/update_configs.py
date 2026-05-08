import os
import re

modules_dir = "/Users/dylansmartbit.one/Dylan/project/terraform-module/modules"

standard_variables = """variable "global_config" {
  type = object({
    environment = string
    region      = string
    project     = string
    managed_by  = optional(string, "DylanDevOps")
    tags        = optional(map(string), {})
  })

  validation {
    condition     = contains(["dev", "test", "staging", "preprod", "prod"], var.global_config.environment)
    error_message = "Biến environment phải là một trong các giá trị: dev, test, staging, preprod, prod."
  }
}

variable "config_file" {
  type    = string
  default = "config.yml"
}

variable "manual_config" {
  type    = any 
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
"""

def update_variables_tf(filepath):
    if not os.path.exists(filepath):
        return
    with open(filepath, 'r') as f:
        content = f.read()

    # Remove the 4 standard variable blocks using precise regex
    blocks = ["global_config", "config_file", "manual_config", "tags"]
    for b in blocks:
        # Match variable "b" { ... } properly
        # We assume they don't have nested {} or complex structures in the old 'any' blocks
        pattern = r'variable\s+"' + b + r'"\s+\{[\s\S]*?\n\}\n*'
        content = re.sub(pattern, '', content)

    # Append standard variables
    new_content = content.strip() + "\n\n" + standard_variables
    
    with open(filepath, 'w') as f:
        f.write(new_content)

def update_locals_tf(filepath):
    if not os.path.exists(filepath):
        return
    with open(filepath, 'r') as f:
        content = f.read()

    # 1. Update Context Variables
    # Regex to find: env = lookup(var.global_config, "environment", null) or similar
    content = re.sub(r'env\s*=\s*lookup\(var\.global_config,\s*"environment",\s*[^)]+\)', 'env          = lookup(var.global_config, "environment", "dev")', content)
    content = re.sub(r'region\s*=\s*lookup\(var\.global_config,\s*"region",\s*[^)]+\)', 'region       = lookup(var.global_config, "region", "ap-southeast-1")', content)
    content = re.sub(r'project\s*=\s*lookup\(var\.global_config,\s*"project",\s*[^)]+\)', 'project      = lookup(var.global_config, "project", "core")', content)

    # 2. Update name_prefix
    content = re.sub(r'name_prefix\s*=\s*local\.app_name == "base".*?\n', 'name_prefix  = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))\n', content)

    with open(filepath, 'w') as f:
        f.write(content)

for mod in os.listdir(modules_dir):
    mod_path = os.path.join(modules_dir, mod)
    if os.path.isdir(mod_path) and mod not in ["vpc", "acm", "alb"]: # acm and alb were updated manually
        update_variables_tf(os.path.join(mod_path, "variables.tf"))
        update_locals_tf(os.path.join(mod_path, "locals.tf"))
        print(f"Updated {mod}")
