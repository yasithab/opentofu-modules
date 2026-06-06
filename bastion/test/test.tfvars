enabled       = true
name          = "test-bastion"
subnet_id     = "subnet-0123456789abcdef0"
instance_type = "t4g.nano"
public        = true

allowed_ssh_cidrs = ["203.0.113.0/24"]

tunnel_users = {
  dev_user = {
    ssh_public_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLxJMPJXtLZYz7IljYqIvjcUBbCGRHyhZGJ3UwF1DYM test@example.com"
    allowed_tunnels = ["db.internal:5432", "redis.internal:6379"]
  }
}

session_log_retention_days   = 7
session_idle_timeout_minutes = 20
