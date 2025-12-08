const request = require('supertest');
const app = require('../src/app');

describe('Online Quiz API', () => {
  
  describe('GET /', () => {
    it('should return home page', async () => {
      const response = await request(app).get('/');
      expect(response.status).toBe(200);
    });
  });

  describe('GET /api/questions', () => {
    it('should return questions array', async () => {
      const response = await request(app).get('/api/questions');
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('POST /api/questions', () => {
    it('should add a new question', async () => {
      const newQuestion = {
        quizId: 1,
        question: 'Test Question?',
        options: ['Option 1', 'Option 2', 'Option 3'],
        correctAnswer: 0
      };
      const response = await request(app)
        .post('/api/questions')
        .send(newQuestion);
      expect(response.status).toBe(200);
      expect(response.body.id).toBeDefined();
    });
  });

  describe('GET /admin', () => {
    it('should return admin page', async () => {
      const response = await request(app).get('/admin');
      expect(response.status).toBe(200);
    });
  });
});
