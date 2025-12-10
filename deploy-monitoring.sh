#!/bin/bash

#################################################################
# Complete Monitoring Stack Deployment Script
# Deploys Prometheus, Grafana, AlertManager, and ELK Stack
# Usage: ./deploy-monitoring.sh [--help] [--check] [--deploy] [--destroy]
#################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MONITORING_NAMESPACE="monitoring"
QUIZ_API_NAMESPACE="default"
MONITORING_TIMEOUT="300s"
HELM_REPO_PROMETHEUS="https://prometheus-community.github.io/helm-charts"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_success "kubectl installed"
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
    
    # Check cluster resources
    AVAILABLE_CPU=$(kubectl top nodes --no-headers 2>/dev/null | awk '{s+=$4} END {print s}' || echo "0")
    if [ "$AVAILABLE_CPU" -lt 2 ]; then
        print_warning "Low available CPU. Monitoring may not run optimally."
    else
        print_success "Sufficient cluster resources available"
    fi
    
    echo ""
}

check_existing_deployment() {
    print_header "Checking Existing Deployment"
    
    if kubectl get namespace $MONITORING_NAMESPACE &> /dev/null; then
        print_warning "Monitoring namespace already exists"
        read -p "Do you want to delete and recreate? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Destroying existing monitoring stack..."
            kubectl delete namespace $MONITORING_NAMESPACE --ignore-not-found=true
            sleep 5
            print_success "Destroyed existing monitoring stack"
        else
            print_info "Using existing monitoring namespace"
        fi
    else
        print_success "Clean monitoring namespace ready for deployment"
    fi
    
    echo ""
}

validate_manifests() {
    print_header "Validating Kubernetes Manifests"
    
    local manifest_files=(
        "kubernetes/monitoring-stack.yaml"
        "kubernetes/alertmanager-config.yaml"
        "kubernetes/elk-stack.yaml"
    )
    
    for manifest in "${manifest_files[@]}"; do
        if [ ! -f "$manifest" ]; then
            print_error "Missing manifest: $manifest"
            exit 1
        fi
        
        if kubectl apply -f "$manifest" --dry-run=client --validate=true &> /dev/null; then
            print_success "Valid: $manifest"
        else
            print_error "Invalid manifest: $manifest"
            exit 1
        fi
    done
    
    echo ""
}

deploy_monitoring_stack() {
    print_header "Deploying Monitoring Stack"
    
    # Create namespace
    print_info "Creating monitoring namespace..."
    kubectl create namespace $MONITORING_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace created"
    
    # Apply monitoring stack
    print_info "Deploying Prometheus, Grafana, and AlertManager..."
    kubectl apply -f kubernetes/monitoring-stack.yaml
    print_success "Monitoring stack deployed"
    
    # Wait for Prometheus to be ready
    print_info "Waiting for Prometheus to be ready (timeout: $MONITORING_TIMEOUT)..."
    kubectl rollout status deployment/prometheus -n $MONITORING_NAMESPACE --timeout=$MONITORING_TIMEOUT
    print_success "Prometheus ready"
    
    # Wait for Grafana to be ready
    print_info "Waiting for Grafana to be ready..."
    kubectl rollout status deployment/grafana -n $MONITORING_NAMESPACE --timeout=$MONITORING_TIMEOUT
    print_success "Grafana ready"
    
    echo ""
}

deploy_alertmanager() {
    print_header "Deploying AlertManager"
    
    print_info "Applying AlertManager configuration..."
    kubectl apply -f kubernetes/alertmanager-config.yaml
    print_success "AlertManager configured"
    
    # Wait for AlertManager to be ready
    print_info "Waiting for AlertManager to be ready..."
    kubectl rollout status deployment/alertmanager -n $MONITORING_NAMESPACE --timeout=$MONITORING_TIMEOUT
    print_success "AlertManager ready"
    
    print_warning "⚠ IMPORTANT: Configure AlertManager with your Slack and email credentials"
    print_info "Edit the configuration with:"
    echo "  kubectl edit configmap alertmanager-config -n $MONITORING_NAMESPACE"
    
    echo ""
}

deploy_elk_stack() {
    print_header "Deploying ELK Stack (Elasticsearch, Logstash, Kibana)"
    
    # Check node kernel parameters
    print_info "Setting up Elasticsearch prerequisites..."
    if ! sysctl vm.max_map_count &> /dev/null || [ "$(sysctl vm.max_map_count | awk -F'=' '{print $2}' | xargs)" -lt 262144 ]; then
        print_warning "vm.max_map_count needs adjustment for Elasticsearch"
        print_info "Run on nodes: sudo sysctl -w vm.max_map_count=262144"
    fi
    
    # Deploy ELK stack
    print_info "Deploying ELK stack..."
    kubectl apply -f kubernetes/elk-stack.yaml
    print_success "ELK stack deployed"
    
    # Wait for Elasticsearch to be ready
    print_info "Waiting for Elasticsearch to be ready (this may take several minutes)..."
    kubectl rollout status statefulset/elasticsearch -n $MONITORING_NAMESPACE --timeout=600s
    print_success "Elasticsearch ready"
    
    # Wait for Logstash to be ready
    print_info "Waiting for Logstash to be ready..."
    kubectl rollout status deployment/logstash -n $MONITORING_NAMESPACE --timeout=$MONITORING_TIMEOUT
    print_success "Logstash ready"
    
    # Wait for Kibana to be ready
    print_info "Waiting for Kibana to be ready..."
    kubectl rollout status deployment/kibana -n $MONITORING_NAMESPACE --timeout=$MONITORING_TIMEOUT
    print_success "Kibana ready"
    
    echo ""
}

configure_quiz_api() {
    print_header "Configuring Quiz API for Prometheus Metrics"
    
    # Check if quiz-api deployment exists
    if kubectl get deployment quiz-api &> /dev/null; then
        print_info "Found quiz-api deployment. Adding Prometheus annotations..."
        kubectl annotate deployment quiz-api \
            prometheus.io/scrape=true \
            prometheus.io/port=3000 \
            prometheus.io/path=/metrics \
            --overwrite 2>/dev/null || true
        print_success "Prometheus annotations added to quiz-api"
    else
        print_warning "quiz-api deployment not found in default namespace"
        print_info "Make sure quiz-api has these annotations:"
        echo "  prometheus.io/scrape: 'true'"
        echo "  prometheus.io/port: '3000'"
        echo "  prometheus.io/path: '/metrics'"
    fi
    
    echo ""
}

show_access_info() {
    print_header "Monitoring Stack Deployed Successfully!"
    
    echo ""
    print_info "Access the monitoring components:"
    echo ""
    echo "  ${BLUE}Prometheus:${NC}"
    echo "    kubectl port-forward -n $MONITORING_NAMESPACE svc/prometheus 9090:9090"
    echo "    http://localhost:9090"
    echo ""
    echo "  ${BLUE}Grafana:${NC}"
    echo "    kubectl port-forward -n $MONITORING_NAMESPACE svc/grafana 3000:3000"
    echo "    http://localhost:3000"
    echo "    Default credentials: admin / admin"
    echo ""
    echo "  ${BLUE}AlertManager:${NC}"
    echo "    kubectl port-forward -n $MONITORING_NAMESPACE svc/alertmanager 9093:9093"
    echo "    http://localhost:9093"
    echo ""
    echo "  ${BLUE}Kibana (Logs):${NC}"
    echo "    kubectl port-forward -n $MONITORING_NAMESPACE svc/kibana 5601:5601"
    echo "    http://localhost:5601"
    echo ""
    
    print_info "Next steps:"
    echo "  1. Configure AlertManager with your Slack and email credentials"
    echo "  2. Add Prometheus as a data source in Grafana"
    echo "  3. Import sample dashboards in Grafana"
    echo "  4. Set up log index patterns in Kibana"
    echo ""
}

show_status() {
    print_header "Monitoring Stack Status"
    
    echo ""
    print_info "Namespace: $MONITORING_NAMESPACE"
    echo ""
    
    echo -e "${BLUE}Deployments:${NC}"
    kubectl get deployments -n $MONITORING_NAMESPACE --no-headers
    echo ""
    
    echo -e "${BLUE}StatefulSets:${NC}"
    kubectl get statefulsets -n $MONITORING_NAMESPACE --no-headers
    echo ""
    
    echo -e "${BLUE}Services:${NC}"
    kubectl get services -n $MONITORING_NAMESPACE --no-headers
    echo ""
    
    echo -e "${BLUE}Pod Status:${NC}"
    kubectl get pods -n $MONITORING_NAMESPACE --no-headers
    echo ""
}

destroy_monitoring() {
    print_header "Destroying Monitoring Stack"
    
    read -p "Are you sure you want to delete the monitoring namespace? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deleting monitoring namespace..."
        kubectl delete namespace $MONITORING_NAMESPACE --ignore-not-found=true
        print_success "Monitoring stack destroyed"
    else
        print_info "Cancelled"
    fi
    echo ""
}

show_help() {
    cat << EOF
${BLUE}Usage: ./deploy-monitoring.sh [OPTION]${NC}

${BLUE}Options:${NC}
  --help      Show this help message
  --check     Validate prerequisites and manifests
  --deploy    Full deployment of monitoring stack
  --status    Show current deployment status
  --destroy   Destroy monitoring stack
  --configure Configure quiz-api for Prometheus metrics
  
${BLUE}Examples:${NC}
  # Check prerequisites before deployment
  ./deploy-monitoring.sh --check
  
  # Deploy complete monitoring stack
  ./deploy-monitoring.sh --deploy
  
  # Check current status
  ./deploy-monitoring.sh --status
  
  # Remove monitoring stack
  ./deploy-monitoring.sh --destroy

${BLUE}Default behavior (no arguments):${NC}
  Runs full deployment with prerequisites check

EOF
}

# Main script logic
main() {
    case "${1:-}" in
        --help)
            show_help
            ;;
        --check)
            check_prerequisites
            validate_manifests
            ;;
        --deploy)
            check_prerequisites
            check_existing_deployment
            validate_manifests
            deploy_monitoring_stack
            deploy_alertmanager
            deploy_elk_stack
            configure_quiz_api
            show_access_info
            show_status
            ;;
        --status)
            show_status
            ;;
        --destroy)
            destroy_monitoring
            ;;
        --configure)
            configure_quiz_api
            ;;
        *)
            print_info "Starting full monitoring stack deployment..."
            check_prerequisites
            check_existing_deployment
            validate_manifests
            deploy_monitoring_stack
            deploy_alertmanager
            deploy_elk_stack
            configure_quiz_api
            show_access_info
            show_status
            ;;
    esac
}

# Run main function
main "$@"
