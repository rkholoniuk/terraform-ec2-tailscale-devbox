# terraform-ec2-tailscale-devbox

Connecting from a local workstation to AWS dev box.

Create a `config/dev.tfvars` to setup your stack:

```terraform
aws_region         = "us-east-1"
rds_instance_class = "db.t4g.micro"
rds_multi_az       = false
rds_username       = "admin"
rds_password       = "yourpass"
workload           = "dev"
allow_ssh          = ["0.0.0.0/0"]
```

Create a ssh key pair:

```sh
mkdir keys
ssh-keygen -f keys/temp_key
```

Apply the stack:

```sh
terraform init
terraform apply
```

Start TailScale
Check if everything is working by connecting via SSH:

```sh
ssh -i keys/temp_key ubuntu@54.163.110.231
```

Destroy the stack:

```sh
terraform destroy
```
