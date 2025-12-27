#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}==>${NC} $1"
}

print_error() {
    echo -e "${RED}==>${NC} $1"
}

print_info() {
    echo -e "${BLUE}==>${NC} $1"
}

show_usage() {
    echo "Usage: $0 [NODE_TYPE]"
    echo ""
    echo "NODE_TYPE:"
    echo "  manager     - Portainer manager + optional Watchtower"
    echo "  worker      - Portainer agent + Watchtower"
    echo "  standalone  - Portainer agent + Watchtower (default)"
    echo ""
    echo "Examples:"
    echo "  $0 manager"
    echo "  $0 worker"
    echo "  $0              # Defaults to standalone"
}

install_docker() {
    if command -v docker &> /dev/null; then
        print_warning "Docker already installed, skipping..."
        return
    fi

    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh

    print_status "Adding user to docker group..."
    sudo usermod -aG docker $USER

    print_status "Enabling and starting Docker..."
    sudo systemctl enable docker
    sudo systemctl start docker

    print_warning "You'll need to log out and back in for docker group to take effect"
}

install_docker_compose() {
    print_status "Checking Docker Compose..."
    
    if docker compose version &> /dev/null; then
        print_status "Docker Compose already available"
    else
        print_status "Installing Docker Compose plugin..."
        sudo apt install -y docker-compose-plugin
    fi
}

install_lazydocker() {
    print_status "Installing lazydocker..."
    if ! command -v lazydocker &> /dev/null; then
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
        print_status "Lazydocker installed to ~/.local/bin/lazydocker"
    else
        print_warning "Lazydocker already installed, skipping..."
    fi
}

deploy_portainer_manager() {
    print_status "Deploying Portainer Manager..."
    
    mkdir -p ~/docker/portainer
    cat > ~/docker/portainer/compose.yml <<'EOF'
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9000:9000"
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

volumes:
  portainer_data:
EOF

    cd ~/docker/portainer
    docker compose up -d
    
    echo ""
    print_status "Portainer Manager deployed!"
    print_info "Access at: https://$(hostname -I | awk '{print $1}'):9443"
    echo ""
}

deploy_portainer_agent() {
    print_status "Deploying Portainer Agent..."
    
    mkdir -p ~/docker/portainer-agent
    cat > ~/docker/portainer-agent/compose.yml <<'EOF'
services:
  portainer-agent:
    image: portainer/agent:latest
    container_name: portainer-agent
    restart: unless-stopped
    ports:
      - "9001:9001"
    environment:
      - AGENT_CLUSTER_ADDR=
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
EOF

    cd ~/docker/portainer-agent
    docker compose up -d
    
    echo ""
    print_status "Portainer Agent deployed!"
    print_info "Add to Portainer Manager:"
    print_info "  1. Go to Portainer UI → Environments → Add environment"
    print_info "  2. Choose 'Agent'"
    print_info "  3. Enter: $(hostname -I | awk '{print $1}'):9001"
    echo ""
}

deploy_watchtower() {
    print_status "Deploying Watchtower..."

    mkdir -p ~/docker/watchtower
    cat > ~/docker/watchtower/compose.yml <<'EOF'
services:
  watchtower:
    image: nickfedor/watchtower:latest
    container_name: watchtower
    restart: unless-stopped
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_RESTARTING=true
      - WATCHTOWER_SCHEDULE=0 0 4 * * *
      - TZ=America/Chicago
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
EOF

    cd ~/docker/watchtower
    docker compose up -d

    print_status "Watchtower deployed! (Updates containers daily at 4 AM)"
}

verify_setup() {
    echo ""
    print_status "Verifying setup..."
    echo ""
    
    print_info "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    print_status "Setup complete!"
}

# Parse node type
NODE_TYPE=${1:-standalone}

case $NODE_TYPE in
    manager)
        echo ""
        print_status "Setting up Docker Manager Node"
        echo ""
        ;;
    worker)
        echo ""
        print_status "Setting up Docker Worker Node"
        echo ""
        ;;
    standalone)
        echo ""
        print_status "Setting up Docker Standalone Node"
        echo ""
        ;;
    --help|-h)
        show_usage
        exit 0
        ;;
    *)
        print_error "Invalid node type: $NODE_TYPE"
        echo ""
        show_usage
        exit 1
        ;;
esac

# Install Docker and Docker Compose
install_docker
install_docker_compose
install_lazydocker

# Deploy based on node type
case $NODE_TYPE in
    manager)
        deploy_portainer_manager
        
        # Ask about Watchtower for manager
        echo ""
        read -p "Deploy Watchtower on manager? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            deploy_watchtower
            print_warning "Note: Watchtower should only manage standalone containers, not Swarm services"
        fi
        ;;
    worker|standalone)
        deploy_portainer_agent
        deploy_watchtower
        ;;
esac

verify_setup

# Remind about group membership
if ! groups | grep -q docker; then
    echo ""
    print_warning "Remember to log out and back in for docker group membership to take effect!"
    echo ""
fi
