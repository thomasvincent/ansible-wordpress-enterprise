# CLAUDE.md

Ansible role for production-ready WordPress deployments at scale.

## Stack
- Ansible 2.15+
- Python 3.x
- Molecule for testing

## Lint & Test
```bash
ansible-lint
yamllint .
molecule test
./simple-test.sh
```

## Notes
- Multi-cloud support: AWS, GCP, Azure, DigitalOcean, Oracle Cloud
- Web servers: Nginx (FastCGI cache, HTTP/2) or Apache (mod_php/PHP-FPM)
- PHP 7.4-8.3 with OPcache optimization
- HA features: load balancing, database clustering, shared storage
- Security: ModSecurity WAF, Let's Encrypt, Fail2ban, SELinux/AppArmor
- Performance: Redis/Memcached, CDN integration, image optimization
