#!/bin/bash

# ZaraLive Observability Stack Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if ports are available
check_ports() {
    local ports=(3000 9090 9093 9100)
    local unavailable_ports=()
    
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            unavailable_ports+=($port)
        fi
    done
    
    if [ ${#unavailable_ports[@]} -gt 0 ]; then
        print_warning "The following ports are already in use: ${unavailable_ports[*]}"
        print_warning "This may cause conflicts with the observability stack"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Port check failed. Please free up the required ports and try again."
            exit 1
        fi
    else
        print_success "All required ports are available"
    fi
}

# Function to check Docker Compose
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "docker-compose is not installed. Please install it and try again."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Function to start services
start_services() {
    print_status "Starting ZaraLive Observability Stack..."
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        print_success "Services started successfully"
    else
        print_error "Failed to start services"
        exit 1
    fi
}

# Function to stop services
stop_services() {
    print_status "Stopping ZaraLive Observability Stack..."
    docker-compose down
    
    if [ $? -eq 0 ]; then
        print_success "Services stopped successfully"
    else
        print_error "Failed to stop services"
        exit 1
    fi
}

# Function to restart services
restart_services() {
    print_status "Restarting ZaraLive Observability Stack..."
    docker-compose restart
    
    if [ $? -eq 0 ]; then
        print_success "Services restarted successfully"
    else
        print_error "Failed to restart services"
        exit 1
    fi
}

# Function to show service status
show_status() {
    print_status "Checking service status..."
    docker-compose ps
    
    echo
    print_status "Service URLs:"
    echo -e "  ${GREEN}Grafana:${NC}      http://localhost:3001 (admin/admin)"
    echo -e "  ${GREEN}Prometheus:${NC}   http://localhost:9090"
    echo -e "  ${GREEN}Alertmanager:${NC} http://localhost:9093"
    echo -e "  ${GREEN}Node Exporter:${NC} http://localhost:9100"
    echo -e "  ${GREEN}Your Backend:${NC} http://localhost:8080"
    echo -e "  ${GREEN}Your Frontend:${NC} http://localhost:3000 (when started)"
}

# Function to show logs
show_logs() {
    local service=${1:-""}
    
    if [ -z "$service" ]; then
        print_status "Showing logs for all services (Ctrl+C to exit)..."
        docker-compose logs -f
    else
        print_status "Showing logs for $service (Ctrl+C to exit)..."
        docker-compose logs -f "$service"
    fi
}

# Function to clean up
cleanup() {
    print_warning "This will remove all containers, volumes, and data. Are you sure? (y/N): "
    read -p "" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up ZaraLive Observability Stack..."
        docker-compose down -v --remove-orphans
        docker system prune -f
        
        print_success "Cleanup completed"
    else
        print_status "Cleanup cancelled"
    fi
}

# Function to check service health
check_health() {
    print_status "Checking service health..."
    
    local services=(
        "http://localhost:3001/api/health"  # Grafana (moved to 3001)
        "http://localhost:9090/-/healthy"   # Prometheus
        "http://localhost:9093/-/healthy"   # Alertmanager
        "http://localhost:9100/metrics"     # Node Exporter
    )
    
    local service_names=("Grafana" "Prometheus" "Alertmanager" "Node Exporter")
    local all_healthy=true
    
    for i in "${!services[@]}"; do
        if curl -s -f "${services[$i]}" > /dev/null 2>&1; then
            print_success "${service_names[$i]}: Healthy"
        else
            print_error "${service_names[$i]}: Unhealthy"
            all_healthy=false
        fi
    done
    
    if [ "$all_healthy" = true ]; then
        print_success "All services are healthy!"
    else
        print_warning "Some services are unhealthy. Check logs with: ./start.sh logs"
    fi
}

# Function to show help
show_help() {
    echo "ZaraLive Observability Stack Management Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start     Start all services"
    echo "  stop      Stop all services"
    echo "  restart   Restart all services"
    echo "  status    Show service status and URLs"
    echo "  logs      Show logs for all services"
    echo "  logs [SERVICE]  Show logs for specific service"
    echo "  health    Check service health"
    echo "  cleanup   Remove all containers and volumes"
    echo "  help      Show this help message"
    echo
    echo "Examples:"
    echo "  $0 start          # Start the stack"
    echo "  $0 logs grafana   # Show Grafana logs"
    echo "  $0 health         # Check all services"
}

# Main script logic
main() {
    case "${1:-start}" in
        start)
            check_docker
            check_docker_compose
            check_ports
            start_services
            show_status
            print_status "Waiting for services to be ready..."
            sleep 10
            check_health
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            show_status
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$2"
            ;;
        health)
            check_health
            ;;
        cleanup)
            cleanup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
