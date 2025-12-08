const request = require('supertest');
const app = require('../index');

describe('Health Check', () => {
  test('GET /health should return 200 with UP status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('UP');
  });
});

describe('Quiz API', () => {
  test('GET /api/quizzes should return 200', async () => {
    const response = await request(app).get('/api/quizzes');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('data');
  });

  test('POST /api/quizzes should create quiz', async () => {
    const response = await request(app)
      .post('/api/quizzes')
      .send({ title: 'Test Quiz' });
    expect(response.status).toBe(201);
  });
});

describe('Metrics', () => {
  test('GET /metrics should return prometheus metrics', async () => {
    const response = await request(app).get('/metrics');
    expect(response.status).toBe(200);
  });
});
