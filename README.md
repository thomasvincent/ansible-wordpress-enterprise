# Ansible Role: WordPress Enterprise

[![CI](https://github.com/thomasvincent/ansible-wordpress-enterprise/workflows/CI/badge.svg)](https://github.com/thomasvincent/ansible-wordpress-enterprise/actions)
[![Ansible Galaxy](https://img.shields.io/badge/ansible--galaxy-wordpress__enterprise-blue.svg)](https://galaxy.ansible.com/thomasvincent/wordpress_enterprise)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Enterprise-grade Ansible role for deploying and managing WordPress installations with support for multiple cloud providers, external databases, caching systems, and CDN integration.

## Features

### 🚀 Core Features
- ✅ **Multi-OS Support**: RHEL 8/9, Ubuntu 20.04/22.04/24.04
- ✅ **Web Servers**: Nginx or Apache with HTTP/2 and SSL/TLS
- ✅ **PHP Versions**: 7.4, 8.0, 8.1, 8.2, 8.3
- ✅ **Databases**: MySQL or MariaDB (local or external)
- ✅ **Idempotent Operations**: Safe to run multiple times
- ✅ **WP-CLI Integration**: Command-line WordPress management
- ✅ **Plugin & Theme Management**: Automated installation and updates
- ✅ **Security Hardening**: Fail2ban, firewall, SELinux support

### ☁️ Cloud Provider Support
- **Cloudflare**: DNS, CDN, DDoS protection
- **DigitalOcean**: Spaces (S3-compatible), Managed Databases, CDN
- **Google Cloud Platform**: Cloud SQL, Memorystore, Cloud Storage, CDN
- **Microsoft Azure**: Azure Database, Azure Cache for Redis, Blob Storage, CDN
- **Oracle Cloud**: Object Storage, Autonomous Database
- **AWS**: RDS/Aurora, ElastiCache, S3, CloudFront (compatible)

### 🗄️ External Services
- **Managed Databases**: RDS, Cloud SQL, Azure Database, DigitalOcean DB
- **Managed Cache**: ElastiCache, Memorystore, Azure Redis, DO Redis
- **Object Storage**: S3, Google Cloud Storage, Azure Blob, DO Spaces
- **Email Services**: SendGrid, Amazon SES, Mailgun, SMTP
- **CDN**: Cloudflare, CloudFront, BunnyCDN, Fastly

### ⚡ Performance Features
- Redis/Memcached object caching
- FastCGI caching
- Opcache optimization
- Image optimization (WebP/AVIF support)
- HTTP/2 with Server Push
- Gzip and Brotli compression
- Database query caching

### 🔒 Security Features
- SSL/TLS (Let's Encrypt or custom certificates)
- Fail2ban WordPress-specific rules
- Firewall configuration (firewalld/ufw)
- SELinux policies (RHEL)
- Security headers (HSTS, CSP, X-Frame-Options)
- Disable file editing in WordPress
- Automated security keys generation
- wp-config.php hardening

## Requirements

- Ansible 2.14 or higher
- Target OS: RHEL 8/9 or Ubuntu 20.04/22.04/24.04
- Sudo/root access on target hosts
- Python 3 on control and target nodes

### Ansible Collections Required

```bash
ansible-galaxy collection install community.general
ansible-galaxy collection install community.mysql
ansible-galaxy collection install ansible.posix
```

## Installation

### From Ansible Galaxy

```bash
ansible-galaxy install thomasvincent.wordpress_enterprise
```

### From Source

```bash
git clone https://github.com/thomasvincent/ansible-wordpress-enterprise.git
cd ansible-wordpress-enterprise
```

## Quick Start

### Basic Usage

```yaml
---
- hosts: wordpress_servers
  become: true
  roles:
    - role: thomasvincent.wordpress_enterprise
      vars:
        wordpress_site_url: "https://example.com"
        wordpress_site_title: "My WordPress Site"
        wordpress_admin_user: "admin"
        wordpress_admin_email: "admin@example.com"
```

### Production Configuration

```yaml
---
- hosts: wordpress_servers
  become: true
  roles:
    - role: thomasvincent.wordpress_enterprise
      vars:
        # WordPress Configuration
        wordpress_version: "6.4.2"
        wordpress_site_url: "https://{{ ansible_fqdn }}"
        wordpress_site_title: "Production WordPress"

        # Web Server
        wordpress_web_server: "nginx"
        wordpress_enable_ssl: true
        wordpress_use_letsencrypt: true

        # Database
        wordpress_db_engine: "mariadb"
        wordpress_db_name: "wordpress_prod"

        # PHP
        wordpress_php_version: "8.2"
        wordpress_php_memory_limit: "512M"

        # Caching
        wordpress_enable_redis: true
        wordpress_enable_object_cache: true

        # Security
        wordpress_enable_fail2ban: true
        wordpress_configure_firewall: true
```

## Cloud Provider Configurations

### Cloudflare

Full integration with Cloudflare services:

```yaml
---
wordpress_cloud_provider: "cloudflare"
wordpress_cloudflare_enabled: true
wordpress_cloudflare_api_token: "{{ vault_cloudflare_api_token }}"
wordpress_cloudflare_zone_id: "your-zone-id"
wordpress_cloudflare_email: "your-email@example.com"

# DNS Management
wordpress_cloudflare_dns_records:
  - name: "{{ wordpress_server_name }}"
    type: "A"
    value: "{{ ansible_default_ipv4.address }}"
    proxied: true

# CDN Configuration
wordpress_cloudflare_cdn_enabled: true
wordpress_cloudflare_cache_ttl: 14400
wordpress_cloudflare_purge_on_update: true
```

### DigitalOcean

DigitalOcean Spaces, Managed Database, and CDN:

```yaml
---
wordpress_cloud_provider: "digitalocean"
wordpress_digitalocean_enabled: true
wordpress_digitalocean_token: "{{ vault_do_token }}"

# Managed Database
wordpress_use_external_db: true
wordpress_external_db_host: "your-db-cluster.db.ondigitalocean.com"
wordpress_external_db_port: 25060
wordpress_external_db_ssl_enabled: true

# Spaces (Object Storage)
wordpress_digitalocean_spaces_enabled: true
wordpress_digitalocean_spaces_key: "{{ vault_do_spaces_key }}"
wordpress_digitalocean_spaces_secret: "{{ vault_do_spaces_secret }}"
wordpress_digitalocean_spaces_bucket: "wordpress-uploads"
wordpress_digitalocean_spaces_region: "nyc3"

# Managed Redis
wordpress_use_external_cache: true
wordpress_do_redis_enabled: true
wordpress_do_redis_host: "your-redis-cluster.db.ondigitalocean.com"
wordpress_do_redis_port: 25061
wordpress_do_redis_password: "{{ vault_do_redis_password }}"

# CDN
wordpress_digitalocean_cdn_enabled: true
```

### Google Cloud Platform

Cloud SQL, Memorystore, and Cloud Storage:

```yaml
---
wordpress_cloud_provider: "google"
wordpress_gcp_enabled: true
wordpress_gcp_project_id: "your-project-id"
wordpress_gcp_service_account_key: "{{ vault_gcp_sa_key }}"

# Cloud SQL
wordpress_use_external_db: true
wordpress_gcp_cloudsql_enabled: true
wordpress_gcp_cloudsql_instance: "your-instance-name"
wordpress_external_db_host: "10.0.0.3"  # Private IP
wordpress_gcp_cloudsql_proxy_enabled: true

# Memorystore (Redis)
wordpress_use_external_cache: true
wordpress_gcp_memorystore_enabled: true
wordpress_gcp_memorystore_host: "10.0.0.4"
wordpress_gcp_memorystore_port: 6379

# Cloud Storage
wordpress_gcp_storage_enabled: true
wordpress_gcp_storage_bucket: "wordpress-media"
wordpress_object_storage_enabled: true
wordpress_object_storage_provider: "gcs"

# CDN
wordpress_gcp_cdn_enabled: true
```

### Microsoft Azure

Azure Database, Azure Cache, and Blob Storage:

```yaml
---
wordpress_cloud_provider: "azure"
wordpress_azure_enabled: true
wordpress_azure_subscription_id: "{{ vault_azure_subscription_id }}"
wordpress_azure_resource_group: "wordpress-rg"

# Azure Database for MySQL
wordpress_use_external_db: true
wordpress_azure_db_enabled: true
wordpress_azure_db_server: "wordpress-mysql-server.mysql.database.azure.com"
wordpress_external_db_ssl_enabled: true

# Azure Cache for Redis
wordpress_use_external_cache: true
wordpress_azure_redis_enabled: true
wordpress_azure_redis_hostname: "wordpress-redis.redis.cache.windows.net"
wordpress_azure_redis_port: 6380
wordpress_azure_redis_password: "{{ vault_azure_redis_password }}"
wordpress_azure_redis_ssl_enabled: true

# Azure Blob Storage
wordpress_azure_storage_enabled: true
wordpress_azure_storage_account: "wordpressstorage"
wordpress_azure_storage_key: "{{ vault_azure_storage_key }}"
wordpress_azure_storage_container: "uploads"
wordpress_object_storage_enabled: true
wordpress_object_storage_provider: "azure_blob"

# Azure CDN
wordpress_azure_cdn_enabled: true
```

### Oracle Cloud Infrastructure

OCI Object Storage and Autonomous Database:

```yaml
---
wordpress_cloud_provider: "oracle"
wordpress_oci_enabled: true
wordpress_oci_tenancy: "{{ vault_oci_tenancy }}"
wordpress_oci_user: "{{ vault_oci_user }}"
wordpress_oci_fingerprint: "{{ vault_oci_fingerprint }}"
wordpress_oci_key_file: "/path/to/oci-api-key.pem"
wordpress_oci_region: "us-ashburn-1"

# Object Storage
wordpress_oci_object_storage_enabled: true
wordpress_oci_object_storage_bucket: "wordpress-uploads"
wordpress_oci_object_storage_namespace: "your-namespace"
wordpress_object_storage_enabled: true
wordpress_object_storage_provider: "oci_storage"

# Autonomous Database (use external DB config)
wordpress_use_external_db: true
wordpress_external_db_host: "your-db.oraclecloud.com"
wordpress_external_db_ssl_enabled: true
```

## Email Service Configuration

### SendGrid

```yaml
---
wordpress_smtp_enabled: true
wordpress_smtp_provider: "sendgrid"
wordpress_smtp_host: "smtp.sendgrid.net"
wordpress_smtp_port: 587
wordpress_smtp_user: "apikey"
wordpress_smtp_password: "{{ vault_sendgrid_api_key }}"
wordpress_smtp_from_email: "noreply@example.com"
wordpress_smtp_from_name: "{{ wordpress_site_title }}"
wordpress_smtp_encryption: "tls"
```

### Amazon SES

```yaml
---
wordpress_smtp_enabled: true
wordpress_smtp_provider: "ses"
wordpress_smtp_host: "email-smtp.us-east-1.amazonaws.com"
wordpress_smtp_port: 587
wordpress_smtp_user: "{{ vault_aws_smtp_user }}"
wordpress_smtp_password: "{{ vault_aws_smtp_password }}"
wordpress_smtp_encryption: "tls"
```

### Mailgun

```yaml
---
wordpress_smtp_enabled: true
wordpress_smtp_provider: "mailgun"
wordpress_smtp_host: "smtp.mailgun.org"
wordpress_smtp_port: 587
wordpress_smtp_user: "{{ vault_mailgun_smtp_user }}"
wordpress_smtp_password: "{{ vault_mailgun_smtp_password }}"
wordpress_smtp_encryption: "tls"
```

## High Availability Setup

```yaml
---
wordpress_ha_enabled: true
wordpress_ha_load_balancer: "nginx"

wordpress_ha_nodes:
  - host: "web1.example.com"
    ip: "10.0.1.10"
  - host: "web2.example.com"
    ip: "10.0.1.11"
  - host: "web3.example.com"
    ip: "10.0.1.12"

# External shared database
wordpress_use_external_db: true
wordpress_external_db_host: "db-cluster.example.com"

# Redis for session storage
wordpress_ha_session_storage: "redis"
wordpress_use_external_cache: true
wordpress_redis_host: "redis-cluster.example.com"

# Shared file storage (NFS/GlusterFS/Cloud Storage)
wordpress_object_storage_enabled: true
```

## Advanced Plugin Configuration

### Essential Plugins

```yaml
---
wordpress_plugins:
  # Security
  - name: "wordfence"
    version: "latest"
    state: "present"

  - name: "all-in-one-wp-security-and-firewall"
    version: "latest"
    state: "present"

  # Performance
  - name: "wp-rocket"  # Premium, needs license
    version: "latest"
    state: "present"

  - name: "redis-cache"
    version: "latest"
    state: "present"

  # SEO
  - name: "wordpress-seo"  # Yoast SEO
    version: "latest"
    state: "present"

  # Backups
  - name: "updraftplus"
    version: "latest"
    state: "present"

  # Cloud Integration
  - name: "amazon-s3-and-cloudfront"  # For AWS S3
    version: "latest"
    state: "present"

  - name: "wp-mail-smtp"  # For email providers
    version: "latest"
    state: "present"
```

### Custom Plugin Installation

```yaml
---
wordpress_custom_plugins:
  - name: "my-custom-plugin"
    version: "1.0.0"
    state: "present"
    source: "https://example.com/plugins/my-custom-plugin-1.0.0.zip"

  - name: "proprietary-plugin"
    version: "2.1.0"
    state: "present"
    source: "https://license.example.com/download/plugin.zip"
```

## Performance Tuning

```yaml
---
# PHP-FPM Optimization
wordpress_php_memory_limit: "512M"
wordpress_php_max_execution_time: "300"
wordpress_php_upload_max_filesize: "256M"
wordpress_php_max_input_vars: "5000"

# Opcache
wordpress_opcache_enable: true
wordpress_opcache_memory: "256"
wordpress_opcache_max_files: "10000"
wordpress_opcache_validate_timestamps: "0"

# Redis
wordpress_enable_redis: true
wordpress_redis_maxmemory: "256mb"
wordpress_redis_maxmemory_policy: "allkeys-lru"

# Image Optimization
wordpress_image_optimization_enabled: true
wordpress_webp_enabled: true
wordpress_avif_enabled: true
wordpress_lazy_load_enabled: true

# HTTP/2 and Compression
wordpress_http2_push_enabled: true
wordpress_http2_push_preload: true
```

## Security Hardening

```yaml
---
# WordPress Security
wordpress_disable_file_edit: true
wordpress_disable_file_mods: false
wordpress_force_ssl_admin: true
wordpress_disallow_unfiltered_html: true

# Fail2ban
wordpress_enable_fail2ban: true
wordpress_fail2ban_maxretry: 5
wordpress_fail2ban_findtime: "10m"
wordpress_fail2ban_bantime: "1h"

# Firewall
wordpress_configure_firewall: true
wordpress_allowed_ips:
  - "192.168.1.0/24"
  - "10.0.0.0/8"

# SSL/TLS
wordpress_enable_ssl: true
wordpress_ssl_protocols: "TLSv1.2 TLSv1.3"
wordpress_ssl_stapling: true
```

## Backup Configuration

```yaml
---
wordpress_enable_backups: true
wordpress_backup_dir: "/var/backups/wordpress"
wordpress_backup_retention_days: 30
wordpress_backup_schedule_hour: "2"
wordpress_backup_schedule_minute: "0"

# Backup to cloud storage
wordpress_backup_to_cloud: true
wordpress_backup_cloud_provider: "s3"  # s3, gcs, azure_blob
wordpress_backup_cloud_bucket: "wordpress-backups"
```

## Variables Reference

See [defaults/main.yml](defaults/main.yml) for complete variable documentation.

### Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `wordpress_version` | `latest` | WordPress version to install |
| `wordpress_web_server` | `nginx` | Web server (nginx/apache) |
| `wordpress_php_version` | `8.2` | PHP version (7.4-8.3) |
| `wordpress_db_engine` | `mariadb` | Database engine |
| `wordpress_enable_ssl` | `true` | Enable SSL/TLS |
| `wordpress_enable_redis` | `true` | Enable Redis caching |
| `wordpress_cloud_provider` | `none` | Cloud provider integration |

## Dependencies

None. This role is self-contained.

## Example Playbook

### Complete Production Setup

```yaml
---
- name: Deploy WordPress with Cloudflare and DigitalOcean
  hosts: wordpress_servers
  become: true

  vars:
    # Basic Configuration
    wordpress_version: "6.4.2"
    wordpress_site_url: "https://blog.example.com"
    wordpress_site_title: "Example Blog"

    # Cloud Provider
    wordpress_cloud_provider: "cloudflare"
    wordpress_cloudflare_enabled: true

    # Database (DigitalOcean Managed)
    wordpress_use_external_db: true
    wordpress_external_db_host: "{{ vault_do_db_host }}"
    wordpress_external_db_port: 25060
    wordpress_external_db_ssl_enabled: true

    # Cache (DigitalOcean Managed Redis)
    wordpress_use_external_cache: true
    wordpress_do_redis_enabled: true
    wordpress_do_redis_host: "{{ vault_do_redis_host }}"

    # Object Storage (DO Spaces)
    wordpress_digitalocean_spaces_enabled: true
    wordpress_object_storage_enabled: true

    # Email (SendGrid)
    wordpress_smtp_enabled: true
    wordpress_smtp_provider: "sendgrid"

    # Security
    wordpress_enable_fail2ban: true
    wordpress_configure_firewall: true

  roles:
    - thomasvincent.wordpress_enterprise
```

## Testing

### Molecule Tests

```bash
# Install molecule
pip install molecule molecule-plugins[docker]

# Run tests
molecule test

# Test specific scenario
molecule test -s ubuntu-nginx
molecule test -s rhel-apache
```

## Best Practices

1. **Always use Ansible Vault for sensitive data**
   ```bash
   ansible-vault encrypt_string 'secret-password' --name 'wordpress_db_password'
   ```

2. **Use external managed services in production**
   - Managed databases (RDS, Cloud SQL, Azure Database)
   - Managed cache (ElastiCache, Memorystore)
   - Object storage (S3, GCS, Azure Blob)

3. **Enable all security features**
   - SSL/TLS with valid certificates
   - Fail2ban
   - Firewall rules
   - Security headers

4. **Implement proper backups**
   - Automated daily backups
   - Off-site backup storage
   - Regular restore testing

5. **Use version pinning in production**
   ```yaml
   wordpress_version: "6.4.2"
   wordpress_php_version: "8.2"
   ```

6. **Monitor and log everything**
   - Application logs
   - Web server logs
   - PHP-FPM logs
   - Database slow query logs

## Troubleshooting

### Common Issues

**Issue**: WordPress white screen of death
```yaml
# Enable debugging
wordpress_debug: true
wordpress_debug_log: true
wordpress_debug_display: true
```

**Issue**: PHP memory errors
```yaml
# Increase PHP memory
wordpress_php_memory_limit: "512M"
```

**Issue**: Upload size limits
```yaml
# Increase upload limits
wordpress_php_upload_max_filesize: "256M"
wordpress_php_post_max_size: "256M"
```

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.

## Author

**Thomas Vincent**
- GitHub: [@thomasvincent](https://github.com/thomasvincent)
- Email: thomasvincent@users.noreply.github.com

## Acknowledgments

- WordPress community
- Ansible community
- Cloud provider documentation

## Support

- GitHub Issues: https://github.com/thomasvincent/ansible-wordpress-enterprise/issues
- Documentation: https://github.com/thomasvincent/ansible-wordpress-enterprise/wiki

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
