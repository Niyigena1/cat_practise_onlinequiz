#!/bin/bash

# Phase 7: Operate - Monitoring, Logging & Alerting Setup Script
# This script deploys the complete observability stack for Quiz API

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="monitoring"
QUIZ_NAMESPACE="default"
QUIZ_DEPLOYMENT="quiz-api"
SLACK_WEBHOOK=""
PAGERDUTY_KEY=""

# Functions
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_success "kubectl found: $(kubectl version --client --short)"

    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"

    # Check for default namespace
    if ! kubectl get ns $QUIZ_NAMESPACE &> /dev/null; then
        print_warning "Namespace '$QUIZ_NAMESPACE' not found, will be created"
    else
        print_success "Namespace '$QUIZ_NAMESPACE' exists"
    fi
}

create_monitoring_namespace() {
    print_header "Creating Monitoring Namespace"

    if kubectl get ns $NAMESPACE &> /dev/null; then
        print_warning "Namespace '$NAMESPACE' already exists"
    else
        kubectl apply -f kubernetes/namespace.yaml
        print_success "Namespace '$NAMESPACE' created"
    fi
}

setup_prometheus() {
    print_header "Setting up Prometheus"

    print_warning "Note: Prometheus requires persistent storage"
    print_warning "Make sure your cluster supports PVC provisioning"

    # Create RBAC
    kubectl apply -f kubernetes/prometheus-rbac.yaml
    print_success "RBAC configured for Prometheus"

    # Create ConfigMap
    kubectl apply -f kubernetes/prometheus-configmap.yaml
    print_success "Prometheus ConfigMap created"

    # Deploy Prometheus
    kubectl apply -f kubernetes/prometheus-deployment.yaml
    print_success "Prometheus deployment created"

    # Wait for Prometheus to be ready
    print_warning "Waiting for Prometheus to be ready (this may take a minute)..."
    kubectl rollout status deployment/prometheus -n $NAMESPACE --timeout=5m || true
    print_success "Prometheus is deployed"
}

setup_alertmanager() {
    print_header "Setting up AlertManager"

    # Check for Slack webhook
    if [ -z "$SLACK_WEBHOOK" ]; then
        print_warning "No Slack webhook configured"
        print_warning "Update kubernetes/alertmanager-deployment.yaml with your webhook URL:"
        print_warning "  slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'"
    fi

    kubectl apply -f kubernetes/alertmanager-deployment.yaml
    print_success "AlertManager deployment created"

    # Wait for AlertManager to be ready
    print_warning "Waiting for AlertManager to be ready..."
    kubectl rollout status deployment/alertmanager -n $NAMESPACE --timeout=5m || true
    print_success "AlertManager is deployed"
}

setup_grafana() {
    print_header "Setting up Grafana"

    kubectl apply -f kubernetes/grafana-deployment.yaml
    print_success "Grafana deployment created"

    # Wait for Grafana to be ready
    print_warning "Waiting for Grafana to be ready..."
    kubectl rollout status deployment/grafana -n $NAMESPACE --timeout=5m || true
    print_success "Grafana is deployed"

    # Get Grafana access info
    GRAFANA_IP=$(kubectl get svc grafana-loadbalancer -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    GRAFANA_PORT=$(kubectl get svc grafana-loadbalancer -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "3000")

    print_warning "Grafana default credentials: admin/admin123"
    print_warning "CHANGE THE PASSWORD IN PRODUCTION!"
    if [ "$GRAFANA_IP" != "pending" ]; then
        print_warning "Access Grafana at: http://$GRAFANA_IP:$GRAFANA_PORT"
    else
        print_warning "LoadBalancer IP pending, use port-forward:"
        print_warning "kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000"
    fi
}

setup_elk_stack() {
    print_header "Setting up ELK Stack"

    print_warning "Note: ELK Stack requires significant disk space"
    print_warning "Elasticsearch: 100GB, Logstash: 10GB, Kibana: 5GB"

    # Elasticsearch
    kubectl apply -f kubernetes/elasticsearch-deployment.yaml
    print_success "Elasticsearch deployment created"
    print_warning "Waiting for Elasticsearch to be ready (this may take 2+ minutes)..."
    kubectl rollout status deployment/elasticsearch -n $NAMESPACE --timeout=5m || true
    print_success "Elasticsearch is deployed"

    # Logstash
    kubectl apply -f kubernetes/logstash-deployment.yaml
    print_success "Logstash deployment created"
    print_warning "Waiting for Logstash to be ready..."
    kubectl rollout status deployment/logstash -n $NAMESPACE --timeout=5m || true
    print_success "Logstash is deployed"

    # Kibana
    kubectl apply -f kubernetes/kibana-deployment.yaml
    print_success "Kibana deployment created"
    print_warning "Waiting for Kibana to be ready..."
    kubectl rollout status deployment/kibana -n $NAMESPACE --timeout=5m || true
    print_success "Kibana is deployed"

    # Get Kibana access info
    KIBANA_IP=$(kubectl get svc kibana-loadbalancer -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    KIBANA_PORT=$(kubectl get svc kibana-loadbalancer -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "5601")

    if [ "$KIBANA_IP" != "pending" ]; then
        print_warning "Access Kibana at: http://$KIBANA_IP:$KIBANA_PORT"
    else
        print_warning "LoadBalancer IP pending, use port-forward:"
        print_warning "kubectl port-forward -n $NAMESPACE svc/kibana 5601:5601"
    fi
}

setup_log_collection() {
    print_header "Setting up Log Collection (Fluent-bit)"

    kubectl apply -f kubernetes/fluent-bit-daemonset.yaml
    print_success "Fluent-bit DaemonSet created"

    # Wait for Fluent-bit to be ready
    print_warning "Waiting for Fluent-bit DaemonSet to be ready..."
    sleep 10
    READY=$(kubectl get daemonset fluent-bit -n $NAMESPACE -o jsonpath='{.status.numberReady}' 2>/dev/null || echo "0")
    print_success "Fluent-bit ready on $READY nodes"
}

annotate_quiz_api() {
    print_header "Annotating Quiz API for Prometheus Scraping"

    # Update deployment with Prometheus annotations
    kubectl patch deployment $QUIZ_DEPLOYMENT -n $QUIZ_NAMESPACE -p '{
      "spec": {
        "template": {
          "metadata": {
            "annotations": {
              "prometheus.io/scrape": "true",
              "prometheus.io/port": "3000",
              "prometheus.io/path": "/metrics"
            }
          }
        }
      }
    }' || print_warning "Failed to update $QUIZ_DEPLOYMENT annotations"

    print_success "Quiz API annotations applied"

    # Restart deployment to apply new configuration
    kubectl rollout restart deployment/$QUIZ_DEPLOYMENT -n $QUIZ_NAMESPACE
    print_warning "Restarting Quiz API deployment to apply annotations..."
    kubectl rollout status deployment/$QUIZ_DEPLOYMENT -n $QUIZ_NAMESPACE --timeout=5m || true
    print_success "Quiz API deployment restarted"
}

verify_deployment() {
    print_header "Verifying Deployment"

    # Check all pods
    print_warning "Monitoring Stack Status:"
    kubectl get pods -n $NAMESPACE

    # Check services
    print_warning "Services:"
    kubectl get svc -n $NAMESPACE

    # Check PVCs
    print_warning "Persistent Volumes:"
    kubectl get pvc -n $NAMESPACE

    # Verify Prometheus targets
    print_warning "Verifying Prometheus scrape targets..."
    PROM_READY=$(kubectl get pod -n $NAMESPACE -l app=prometheus -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
    if [ "$PROM_READY" = "True" ]; then
        print_success "Prometheus is ready, targets will appear at http://localhost:9090/targets"
    else
        print_warning "Prometheus is still starting, check again in a moment"
    fi
}

show_access_instructions() {
    print_header "Access Instructions"

    echo ""
    echo -e "${BLUE}Port Forward Commands:${NC}"
    echo "  # Prometheus"
    echo "  kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090 &"
    echo ""
    echo "  # Grafana"
    echo "  kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000 &"
    echo ""
    echo "  # AlertManager"
    echo "  kubectl port-forward -n $NAMESPACE svc/alertmanager 9093:9093 &"
    echo ""
    echo "  # Kibana"
    echo "  kubectl port-forward -n $NAMESPACE svc/kibana 5601:5601 &"
    echo ""

    echo -e "${BLUE}Web Addresses:${NC}"
    echo "  Prometheus:  http://localhost:9090"
    echo "  Grafana:     http://localhost:3000 (admin/admin123)"
    echo "  AlertManager: http://localhost:9093"
    echo "  Kibana:      http://localhost:5601"
    echo ""

    echo -e "${BLUE}Useful Commands:${NC}"
    echo "  # Watch all monitoring pods"
    echo "  watch -n 5 'kubectl get pods -n $NAMESPACE'"
    echo ""
    echo "  # Check logs"
    echo "  kubectl logs -f -n $NAMESPACE -l app=prometheus"
    echo "  kubectl logs -f -n $NAMESPACE -l app=grafana"
    echo "  kubectl logs -f -n $NAMESPACE -l app=alertmanager"
    echo ""
    echo "  # Check metrics are being collected"
    echo "  kubectl exec -it -n $NAMESPACE deployment/prometheus -- promtool query instant 'up'"
    echo ""

    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Change Grafana default password"
    echo "  2. Configure Slack webhook in AlertManager"
    echo "  3. Set Elasticsearch ILM policies"
    echo "  4. Create Kibana dashboards"
    echo "  5. Setup on-call rotations"
    echo ""
}

main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║     Phase 7: Operate - Monitoring, Logging & Alerting          ║"
    echo "║                   Automated Setup Script                        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    # Check prerequisites
    check_prerequisites

    # Ask for confirmation
    echo ""
    read -p "Continue with monitoring stack deployment? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled"
        exit 1
    fi

    # Deploy components
    create_monitoring_namespace
    setup_prometheus
    setup_alertmanager
    setup_grafana
    setup_elk_stack
    setup_log_collection
    annotate_quiz_api

    # Verify and show results
    verify_deployment
    show_access_instructions

    print_header "Deployment Complete!"
    print_success "Monitoring, logging, and alerting stack deployed successfully"
    print_warning "Please review .github/MONITORING_GUIDE.md for detailed documentation"
}

# Run main function
main
