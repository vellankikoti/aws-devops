# Docker Cheat Sheet

## Containers
```bash
docker ps                    # List running
docker ps -a                 # List all
docker run -d -p 80:80 IMG   # Run detached
docker exec -it ID /bin/sh   # Shell into
docker logs ID [-f]          # View logs
docker stop/start/restart ID  # Lifecycle
docker rm ID                 # Remove
```

## Images
```bash
docker images               # List images
docker pull IMG:TAG          # Pull image
docker build -t NAME .      # Build image
docker rmi IMG               # Remove image
```

## Docker Compose
```bash
docker-compose up -d         # Start services
docker-compose down          # Stop and remove
docker-compose ps            # List services
docker-compose logs [-f]     # View logs
docker-compose pull          # Pull images
docker-compose restart       # Restart services
```

## Cleanup
```bash
docker system prune -a       # Remove everything unused
docker volume prune          # Remove unused volumes
```
