# Phase 7: Operating - Monitoring, Logging & Alerting Quick Start

## 🚀 Quick Start (5 minutes)

### 1. Deploy Monitoring Stack
```bash
./deploy-monitoring.sh --deploy
```

This automatically:
- Creates monitoring namespace
- Deploys Prometheus (metrics collection)
- Deploys Grafana (visualization)
- Deploys AlertManager (alert routing)
- Deploys ELK stack (logs: Elasticsearch, Logstash, Kibana)
- Configures quiz-api for metrics collection

### 2. Access the Dashboards

**Prometheus** (Metrics Database):
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Open http://localhost:9090
```

**Grafana** (Visualizations):
```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Open http://localhost:3000
# Login: admin / admin
```

**AlertManager** (Alert Router):
```bash
kubectl port-forward -n monitoring svc/alertmanager 9093:9093
# Open http://localhost:9093
```

**Kibana** (Log Viewer):
```bash
kubectl port-forward -n monitoring svc/kibana 5601:5601
# Open http://localhost:5601
```

### 3. Configure Notifications

Edit AlertManager configuration:
```bash
kubectl edit configmap alertmanager-config -n monitoring
```

Update:
- `YOUR_SLACK_WEBHOOK_URL` - Get from Slack: Apps → Create New App
- `YOUR_GMAIL_ADDRESS` - Your Gmail address
- `YOUR_GMAIL_APP_PASSWORD` - Generate from Google Account settings

### 4. Add Prometheus Data Source in Grafana

1. Open Grafana (http://localhost:3000)
2. Configuration → Data Sources → Add data source
3. Select Prometheus
4. URL: `http://prometheus:9090`
5. Click "Save & test"

### 5. Import Sample Dashboard

1. In Grafana: `+` → Dashboard → Import
2. Paste JSON from `kubernetes/grafana-dashboard.json`
3. Select Prometheus data source
4. Import

---

## 📊 What Gets Monitored

### Application Metrics (from Express.js)
- **HTTP Requests**: Rate, status codes, duration percentiles
- **API Errors**: Error rate, error types, affected endpoints
- **Database Queries**: Query duration, slow queries
- **Custom Metrics**: Business metrics for quizzes

### Infrastructure Metrics
- **Pod Health**: CPU, memory, restarts
- **Nodes**: CPU, memory, disk, network
- **Deployment Status**: Replicas, update progress
- **Kubernetes Events**: Pod creation, termination, errors

### Logs (via ELK Stack)
- **Application Logs**: Captured via stdout
- **Error Logs**: Indexed by severity
- **Structured Logs**: JSON log aggregation via Logstash

---

## ⚠️ Alert Rules Configured

### Critical Alerts (Immediate Action)
- `HighErrorRate`: 5xx errors > 5% for 5 minutes
- `DeploymentUpdateFailure`: Update stuck for 10 minutes
- `InsufficientReplicas`: Less than 2 replicas available

### Warning Alerts (Investigation)
- `HighCPUUsage`: > 50% for 10 minutes
- `HighMemoryUsage`: > 80% of limit for 5 minutes
- `PodRestartingTooOften`: > 0.1 restarts per 15 minutes
- `SlowResponseTime`: p95 latency > 1 second for 5 minutes

### Info Alerts (Trending)
- `HighRequestRate`: Unusual traffic patterns
- `SlowDatabaseQuery`: Database performance degradation

---

## 🔧 Customization

### Change Alert Thresholds

Edit alert rules:
```bash
kubectl edit configmap prometheus-config -n monitoring
```

Modify the `alert-rules.yml` section. Examples:

```yaml
# Change CPU threshold from 50% to 70%
expr: sum(rate(container_cpu_usage_seconds_total...)) > 0.7

# Change error rate threshold from 5% to 10%
expr: ... > 0.10
```

### Add Custom Metrics to Application

In `src/app.js`, add custom counters:
```javascript
const customCounter = new prometheus.Counter({
  name: 'quiz_completions_total',
  help: 'Total number of quiz completions',
  labelNames: ['quiz_id', 'result']
});

// Use it
customCounter.labels('quiz-1', 'pass').inc();
```

### Adjust Scrape Intervals

Edit `kubernetes/monitoring-stack.yaml`:
```yaml
global:
  scrape_interval: 15s  # Change from 15s to 30s for less load
  evaluation_interval: 15s
```

---

## 📈 Common Queries

### Prometheus Query Examples

**Request Rate (requests per second)**
```
rate(http_requests_total[5m])
```

**Error Rate (percentage)**
```
(sum(rate(http_requests_total{status_code=~"5.."}[5m])) / 
 sum(rate(http_requests_total[5m]))) * 100
```

**P95 Response Time**
```
histogram_quantile(0.95, http_request_duration_seconds_bucket)
```

**Pod Memory Usage**
```
container_memory_usage_bytes{pod=~"quiz-api.*"}
```

**Database Query Duration**
```
rate(db_query_duration_seconds_sum[5m])
```

---

## 🐛 Troubleshooting

### Prometheus not scraping metrics
```bash
# Check targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Open http://localhost:9090/targets
# Look for quiz-api job - should show "UP"
```

### Alerts not firing
```bash
# Check alert rules
kubectl logs -n monitoring -l app=prometheus | grep -i alert

# Verify Prometheus evaluation
# Check http://localhost:9090/rules
```

### Grafana dashboards not showing data
1. Verify Prometheus data source is configured (Configuration → Data Sources)
2. Run test query in data source: `up`
3. Check if pods are exposing metrics: `kubectl port-forward quiz-api-pod 3000:3000` → http://localhost:3000/metrics

### AlertManager not sending notifications
```bash
# Check AlertManager logs
kubectl logs -n monitoring -l app=alertmanager

# Verify configuration loaded
kubectl get configmap alertmanager-config -n monitoring -o yaml

# Check connectivity to Slack/SMTP
# Test SMTP: telnet smtp.gmail.com 587
```

### Elasticsearch not starting
```bash
# Check logs
kubectl logs -n monitoring -l app=elasticsearch

# Verify resources available
kubectl top nodes

# Check kernel parameters (if on Linux nodes)
sysctl vm.max_map_count  # Should be >= 262144
```

---

## 🧹 Maintenance

### Backup Prometheus Data
```bash
# Prometheus uses emptyDir, so data is not persisted
# To add persistence, update monitoring-stack.yaml:
# volumes:
#   - name: storage
#     persistentVolumeClaim:
#       claimName: prometheus-pvc
```

### Cleanup Old Logs
Elasticsearch automatically rotates logs via index names (logs-YYYY.MM.dd)

To delete old indices:
```bash
curl -X DELETE "localhost:9200/logs-2024.01.*"
```

### Monitor Disk Usage
```bash
# Check Elasticsearch volume
kubectl get pvc -n monitoring
kubectl exec -n monitoring elasticsearch-0 -- du -sh /usr/share/elasticsearch/data
```

---

## 📚 Next Steps

1. **Setup On-Call Rotation**: Integrate AlertManager with PagerDuty or Opsgenie
2. **Create Runbooks**: Document responses to common alerts
3. **Implement SLOs**: Define error budgets based on metrics
4. **Setup Log Analysis**: Use Kibana to create saved searches for common issues
5. **Optimize Costs**: Right-size resource requests based on actual usage

---

## 📞 Support

For issues or questions:
1. Check logs: `kubectl logs -n monitoring [pod-name]`
2. Check metrics: http://localhost:9090 (Prometheus UI)
3. Check alerts: http://localhost:9093 (AlertManager UI)
4. Review logs: http://localhost:5601 (Kibana)

---

**Version**: 1.0 | **Last Updated**: 2024 | **For**: Online Quiz API
