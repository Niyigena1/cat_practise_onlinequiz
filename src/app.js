const express = require('express');
const path = require('path');
const db = require('./database');
const promClient = require('prom-client');

const app = express();

// Prometheus metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const dbQueryDuration = new promClient.Histogram({
  name: 'db_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['operation'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1]
});

const apiErrorsTotal = new promClient.Counter({
  name: 'api_errors_total',
  help: 'Total number of API errors',
  labelNames: ['error_type', 'status_code']
});

// Register metrics
promClient.register.registerMetric(httpRequestDuration);
promClient.register.registerMetric(httpRequestTotal);
promClient.register.registerMetric(dbQueryDuration);
promClient.register.registerMetric(apiErrorsTotal);

app.use(express.static(path.join(__dirname, '../public')));
app.use(express.json());

// Prometheus metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route?.path || req.path;
    
    httpRequestDuration.observe(
      { method: req.method, route, status_code: res.statusCode },
      duration
    );
    
    httpRequestTotal.inc({
      method: req.method,
      route,
      status_code: res.statusCode
    });
    
    if (res.statusCode >= 400) {
      apiErrorsTotal.inc({
        error_type: res.statusCode >= 500 ? 'server_error' : 'client_error',
        status_code: res.statusCode
      });
    }
  });
  
  next();
});

// Metrics endpoint
app.get('/metrics', (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(promClient.register.metrics());
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

app.get('/quiz', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/quiz.html'));
});

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/admin.html'));
});

// Get all questions
app.get('/api/questions', (req, res) => {
  db.all('SELECT * FROM questions', (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows.map(row => ({ ...row, options: JSON.parse(row.options) })));
  });
});

// Add question
app.post('/api/questions', (req, res) => {
  const { quizId, question, options, correctAnswer } = req.body;
  db.run(
    'INSERT INTO questions (quizId, question, options, correctAnswer) VALUES (?, ?, ?, ?)',
    [quizId, question, JSON.stringify(options), correctAnswer],
    function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: this.lastID, quizId, question, options, correctAnswer });
    }
  );
});

// Edit question
app.put('/api/questions/:id', (req, res) => {
  const { question, options, correctAnswer } = req.body;
  db.run(
    'UPDATE questions SET question = ?, options = ?, correctAnswer = ? WHERE id = ?',
    [question, JSON.stringify(options), correctAnswer, req.params.id],
    function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: req.params.id, question, options, correctAnswer });
    }
  );
});

// Delete question
app.delete('/api/questions/:id', (req, res) => {
  db.run('DELETE FROM questions WHERE id = ?', [req.params.id], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

module.exports = app;


