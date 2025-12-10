# Complete Monitoring Stack Deployment Guide

## Overview
This guide provides step-by-step instructions to deploy the complete monitoring, logging, and alerting infrastructure for the Online Quiz API.

## Components
1. **Prometheus** - Metrics collection and time-series database
2. **Grafana** - Visualization dashboards
3. **AlertManager** - Alert routing and notification management
4. **Elasticsearch** - Log storage and indexing
5. **Logstash** - Log processing and aggregation
6. **Kibana** - Log visualization

## Prerequisites
- Kubernetes cluster running (minikube, EKS, AKS, GKE, etc.)
- `kubectl` configured to access your cluster
- Sufficient cluster resources (minimum 4 CPU, 4GB RAM for all components)
- Persistent volume provisioning available

## Step 1: Create Monitoring Namespace and Deploy Core Stack

```bash
# Apply monitoring stack (Prometheus, Grafana, AlertManager)
kubectl apply -f kubernetes/monitoring-stack.yaml

# Verify deployments
kubectl get deployments -n monitoring
kubectl get services -n monitoring
kubectl get configmaps -n monitoring
```

## Step 2: Configure AlertManager

Before deploying, update the AlertManager configuration with your credentials:

```bash
# Edit the alertmanager-config.yaml
kubectl edit configmap alertmanager-config -n monitoring
```

Update these placeholders:
- `YOUR_SLACK_WEBHOOK_URL` - Your Slack webhook URL
- `YOUR_GMAIL_ADDRESS` - Your Gmail address
- `YOUR_GMAIL_APP_PASSWORD` - Gmail app-specific password

For Gmail:
1. Enable 2FA on your Google account
2. Generate an app-specific password at https://myaccount.google.com/apppasswords
3. Use this password instead of your regular Gmail password

## Step 3: Deploy ELK Stack

```bash
# Apply ELK stack (Elasticsearch, Logstash, Kibana)
kubectl apply -f kubernetes/elk-stack.yaml

# Monitor Elasticsearch StatefulSet initialization
kubectl get statefulsets -n monitoring
kubectl logs -n monitoring -f statefulset/elasticsearch
```

## Step 4: Update Quiz API Deployment

Configure your Quiz API deployment to scrape metrics:

```bash
# Patch the deployment with Prometheus annotations
kubectl patch deployment quiz-api -p '{"spec":{"template":{"metadata":{"annotations":{"prometheus.io/scrape":"true","prometheus.io/port":"3000","prometheus.io/path":"/metrics"}}}}}'

# Or manually add to your deployment YAML:
# annotations:
#   prometheus.io/scrape: "true"
#   prometheus.io/port: "3000"
#   prometheus.io/path: "/metrics"
```

## Step 5: Access the UIs

### Prometheus
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Access at http://localhost:9090
```

### Grafana
```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Access at http://localhost:3000
# Default credentials: admin / admin
```

### AlertManager
```bash
kubectl port-forward -n monitoring svc/alertmanager 9093:9093
# Access at http://localhost:9093
```

### Kibana
```bash
kubectl port-forward -n monitoring svc/kibana 5601:5601
# Access at http://localhost:5601
```

## Step 6: Configure Prometheus Data Source in Grafana

1. Open Grafana at http://localhost:3000
2. Login with admin/admin
3. Go to Configuration → Data Sources
4. Click "Add data source"
5. Select Prometheus
6. Set URL: `http://prometheus:9090`
7. Click "Save & test"

## Step 7: Import Sample Dashboard

In Grafana:
1. Click "+" → Dashboard
2. Click "Import"
3. Search for Dashboard ID: **1860** (Node Exporter for Prometheus)
4. Select Prometheus data source
5. Import

For Quiz API specific dashboard, create custom dashboard with:
- HTTP Request Rate: `rate(http_requests_total[5m])`
- Error Rate: `rate(http_requests_total{status_code=~"5.."}[5m])`
- Response Time (p95): `histogram_quantile(0.95, http_request_duration_seconds)`
- Database Query Duration: `rate(db_query_duration_seconds_sum[5m])`

## Step 8: Send Test Alerts

```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# In another terminal, trigger a test alert by overloading the API
# This will cause high error rates that trigger the HighErrorRate alert
```

## Step 9: Verify Alert Routing

1. Access AlertManager at http://localhost:9093
2. Go to "Alerts" tab
3. Verify alerts are being received
4. Check Slack channel and email for notifications

## Step 10: Send Logs to Logstash (Optional - for applications that support it)

Forward application logs to Logstash:
```bash
# Forward to Logstash on port 5000 (TCP or UDP)
# Example with JSON logs:
echo '{"message":"test log","level":"info","service":"quiz-api"}' | nc localhost 5000
```

## Monitoring Best Practices

1. **Set Appropriate Alert Thresholds**
   - Review alert rules in `prometheus-alert-rules.yaml`
   - Adjust thresholds based on your baseline metrics

2. **Configure Alert Routing**
   - Critical alerts → Immediate notification (Slack + Email)
   - Warning alerts → Daily digest
   - Info alerts → Logging only

3. **Dashboard Organization**
   - Create dashboards per application component
   - Include business metrics alongside infrastructure metrics

4. **Log Retention**
   - Set appropriate retention in Elasticsearch (default: logs-YYYY.MM.dd indices)
   - Archive old indices to S3 or similar storage

5. **Regular Review**
   - Review alert firing patterns weekly
   - Adjust thresholds to reduce alert fatigue
   - Update dashboards based on team feedback

## Troubleshooting

### Prometheus not scraping metrics
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Navigate to Status → Targets in Prometheus UI
# Verify quiz-api pods are showing up with correct labels
```

### Alerts not firing
```bash
# Check Prometheus evaluation
kubectl logs -n monitoring -l app=prometheus | grep -i alert

# Verify alert rule syntax
kubectl get configmap prometheus-config -n monitoring -o yaml
```

### Elasticsearch memory issues
```bash
# Check Elasticsearch logs
kubectl logs -n monitoring -l app=elasticsearch

# Adjust JVM memory in elk-stack.yaml:
# ES_JAVA_OPTS: "-Xms1024m -Xmx1024m"
```

### AlertManager not sending notifications
```bash
# Check AlertManager logs
kubectl logs -n monitoring -l app=alertmanager

# Verify SMTP credentials
kubectl get configmap alertmanager-config -n monitoring -o yaml

# Test email with telnet
telnet smtp.gmail.com 587
```

## Cleanup

To remove all monitoring components:
```bash
kubectl delete namespace monitoring
```

## Next Steps

1. Integrate monitoring alerts into on-call schedules (PagerDuty, Opsgenie)
2. Setup log-based anomaly detection (ELK stack ML)
3. Create runbooks for common alerts
4. Implement SLOs and error budgets based on metrics
5. Setup cost monitoring for Kubernetes cluster

---
For detailed Prometheus query examples and Grafana dashboard templates, see the companion files.
