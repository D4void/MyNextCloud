# MyNextCloud

Production-ready Nextcloud deployment with Docker Compose, featuring a custom image with SMB support and integration with Traefik reverse proxy.

## Features

- **Custom Nextcloud Image**: Extended official image with `smbclient` for external SMB/CIFS storage
- **Complete Stack**: Nextcloud, MariaDB 11.4, Redis cache, Collabora Online office suite
- **Traefik Integration**: Automatic HTTPS with Let's Encrypt certificates
- **Automated Backups**: Integrated Plakar backup system for data and database
- **Production Ready**: Resource limits, health checks, and proper volume management

## Prerequisites

- Docker and Docker Compose
- [MyTraefik](https://github.com/D4void/MyTraefik) project deployed (provides `MyTraefikNet` network)
- [MyDockerApps](https://github.com/D4void/MyDockerApps) - Unified Docker Compose orchestrator
- [Plakar](https://plakar.io/) - Plakar installed. Backup tool used for snapshots
- [plakarbackup](https://github.com/D4void/plakarbackup) - My Bash wrapper script for plakar
- DNS A record pointing to your server for `NEXTCLOUD_FQDN` and `COLLABORA_FQDN`

## Quick Start

### 1. Initial Configuration

```bash
# Copy environment template
cp env.example .env
chmod 600 .env

# Edit .env with your configuration
nano .env
```

Configure the following critical variables:
- `NEXTCLOUD_FQDN`: Your Nextcloud domain (e.g., `nextcloud.domain.fr`)
- `COLLABORA_FQDN`: Collabora Online domain (e.g., `office.domain.fr`)
- `COLLABORA_DOMAIN`: Escaped domain for regex (e.g., `nextcloud\\.domain\\.fr`)
- `TRAEFIK_IP`: Internal IP of Traefik container
- `NC_VOL`: Host path for volume data (e.g., `/opt/MyNextcloud`)
- Database credentials and service versions

### 2. Initialize Volumes

```bash
# Create volume directories with correct permissions
./init-voldir.sh
```

This creates all required directories with proper uid/gid and permissions:
- MariaDB data (999:999, chmod 700)
- Redis data (999:1000, chmod 700)
- Nextcloud data/config/apps (33:33, chmod 750)

### 3. Deploy Services

**Recommended**: Use [MyDockerApps](https://github.com/D4void/MyDockerApps) orchestrator to manage Traefik dependency:

```bash
cd ../MyDockerApps
docker compose up -d
```

This ensures Traefik starts first and creates the `MyTraefikNet` network before Nextcloud services attempt to connect.

**Alternative** (standalone, requires MyTraefik already running):

```bash
docker compose up -d
```

Access Nextcloud at `https://<NEXTCLOUD_FQDN>` and complete the web setup.


## Building Custom Image (Optionnal)

The custom image adds SMB client support to official Nextcloud.

If you want to build the image yourself, edit build.sh and run it:

```bash
./build.sh
```

This builds `d4void/nextcloud:${NEXTCLOUD_TAG}` and pushes to Docker Hub.
(Change to your dockerhub repository and modify docker compose file accordingly)

## Administration

### Nextcloud CLI (occ)

Use the `occ.sh` wrapper for all occ commands:

```bash
./occ.sh maintenance:mode --on
./occ.sh files:scan --all
./occ.sh user:list
./occ.sh app:enable files_external
```

### Maintenance Mode

```bash
# Enable maintenance mode
./occ.sh maintenance:mode --on

# Disable maintenance mode
./occ.sh maintenance:mode --off
```

## Backup & Restore

### Backup

The backup script creates a MariaDB dump and Plakar snapshot:

```bash
./nc-backup.sh
```

Process:
1. Enables maintenance mode
2. Dumps MariaDB with `--single-transaction`
3. Creates Plakar snapshot of dump + data/config/custom_apps
4. Disables maintenance mode
5. Cleans up temporary files

**Dependency**: Requires [plakarbackup.sh](https://github.com/D4void/plakarbackup) installed at the path specified in `PLAKAR` variable.

Currently at `/usr/local/bin/plakarbackup.sh`

### Restore

Two-step restoration process:

```bash
# Step 1: Extract Plakar snapshot
./plakar-restore.sh <repo_name> <restore_dir> <snapshot_id>

# Step 2: Restore database and data
./nc-restore.sh <dump_file> <data_directory>
```

**Warning**: Existing data/config/custom_apps are moved to `.old` directories before restore.

## Architecture

### Services

| Service | Image | Purpose | Port |
|---------|-------|---------|------|
| nc-nextcloud | d4void/nextcloud:31.0.7-apache | Main Nextcloud server | 80 |
| nc-cron | d4void/nextcloud:31.0.7-apache | Background jobs | - |
| nc-db | mariadb:11.4-noble | Database with binlog | 3306 |
| nc-redis | redis:8.0.2-alpine | Cache | 6379 |
| nc-collabora | collabora/code:25.04.4.1.1 | Office suite | 9980 |

### Networks

- **MyNCnet** (internal): Service-to-service communication
- **MyTraefikNet** (external): Traefik reverse proxy connection

### Volumes

All volumes use bind mounts to `${NC_VOL}`:

```
${NC_VOL}/
├── var-lib-mysql/     # MariaDB data
├── redis_data/        # Redis persistence
├── data/              # User files
├── config/            # Nextcloud config
├── custom_apps/       # Custom apps
├── app/               # Nextcloud core
└── backup/            # Local backups
```

### Key Design Decisions

- **extra_hosts**: Forces Nextcloud ↔ Collabora communication through Traefik's internal IP instead of external DNS
- **Bind mounts**: Explicit control over file permissions and ownership
- **Shared volumes**: nc-nextcloud and nc-cron share the same volumes for consistency
- **MariaDB binlog**: Transaction isolation with binary logging for replication support

## Configuration Details

### Resource Limits

Configured for standalone Docker Compose (convert to `deploy.resources` for Swarm):

- nc-nextcloud: 0.7 CPU, 3GB RAM
- nc-cron: 0.7 CPU, 3GB RAM  
- nc-db: 0.7 CPU, 3GB RAM
- nc-redis: 0.25 CPU, 512MB RAM
- nc-collabora: 0.5 CPU, 1GB RAM

Edit cpus and mem_limit in `docker-compose.yml`

### Network Configuration

#### Internal Network
- `MyNCnet`: Internal network for `nc-nextcloud`, `nc-cron`, `nc-collabora`, `nc-redis`, `nc-db` communication

#### External Network  
- `MyTraefikNet`: Connection to Traefik reverse proxy (must exist before deployment)

### Traefik Labels

The `nc-nextcloud` and `nc-collabora` services uses these Traefik labels:
- Routes HTTPS traffic via `Host()` rule
- TLS termination with `certresolver=mytlschallenge` (Let's Encrypt)
- Security middleware from `security@file` (HSTS, security headers)



## Troubleshooting

### Nextcloud can't connect to Collabora

Check `extra_hosts` configuration and verify `TRAEFIK_IP` matches Traefik container IP:

```bash
docker inspect <traefik_container> | grep IPAddress
```

### Permission errors

Verify volume directory ownership:

```bash
ls -la ${NC_VOL}/
```

Re-run `./init-voldir.sh` if needed.

### Database connection issues

Check MariaDB container logs:

```bash
docker logs nc-db
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Related Projects

- [Official Nextcloud Documentation](https://docs.nextcloud.com/)
- [Collabora Online Documentation](https://www.collaboraoffice.com/code/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [MyTraefik](https://github.com/D4void/MyTraefik) - Traefik reverse proxy configuration
- [MyDockerApps](https://github.com/D4void/MyDockerApps) - Unified Docker Compose orchestrator
- [Plakar](https://plakar.io/) - Backup tool used for snapshots
- [plakarbackup](https://github.com/D4void/plakarbackup) - Bash wrapper script for plakar


---

*This README was initially generated with AI assistance.*