const request = require('supertest');
const app = require('../src/app');

describe('Unit Tests - API Endpoints', () => {
  
  describe('Health Check Endpoint', () => {
    it('should return healthy status', async () => {
      const response = await request(app).get('/health');
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
    });
  });

  describe('Home Endpoint', () => {
    it('should return 200 status for root path', async () => {
      const response = await request(app).get('/');
      expect(response.status).toBe(200);
    });

    it('should return HTML content', async () => {
      const response = await request(app).get('/');
      expect(response.headers['content-type']).toContain('text/html');
    });
  });

  describe('Quiz Endpoint', () => {
    it('should return quiz page with 200 status', async () => {
      const response = await request(app).get('/quiz');
      expect(response.status).toBe(200);
      expect(response.headers['content-type']).toContain('text/html');
    });
  });

  describe('Admin Endpoint', () => {
    it('should return admin page with 200 status', async () => {
      const response = await request(app).get('/admin');
      expect(response.status).toBe(200);
      expect(response.headers['content-type']).toContain('text/html');
    });
  });

  describe('Questions API - GET', () => {
    it('should return questions array', async () => {
      const response = await request(app).get('/api/questions');
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });

    it('should have correct question structure', async () => {
      const response = await request(app).get('/api/questions');
      if (response.body.length > 0) {
        const question = response.body[0];
        expect(question).toHaveProperty('id');
        expect(question).toHaveProperty('question');
        expect(question).toHaveProperty('options');
        expect(question).toHaveProperty('correctAnswer');
      }
    });
  });

  describe('Questions API - POST', () => {
    it('should create a new question', async () => {
      const newQuestion = {
        quizId: 1,
        question: 'What is 2 + 2?',
        options: ['3', '4', '5'],
        correctAnswer: 1
      };

      const response = await request(app)
        .post('/api/questions')
        .send(newQuestion);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('id');
      expect(response.body.question).toBe(newQuestion.question);
    });

    it('should accept partial question data', async () => {
      const question = {
        quizId: 1,
        question: 'Incomplete question',
        options: ['A', 'B'],
        correctAnswer: 0
      };

      const response = await request(app)
        .post('/api/questions')
        .send(question);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('id');
    });
  });

  describe('Questions API - PUT', () => {
    it('should update an existing question', async () => {
      // First create a question
      const newQuestion = {
        quizId: 1,
        question: 'Original question?',
        options: ['A', 'B', 'C'],
        correctAnswer: 0
      };

      const createResponse = await request(app)
        .post('/api/questions')
        .send(newQuestion);

      const questionId = createResponse.body.id;

      // Update it
      const updatedQuestion = {
        question: 'Updated question?',
        options: ['X', 'Y', 'Z'],
        correctAnswer: 1
      };

      const updateResponse = await request(app)
        .put(`/api/questions/${questionId}`)
        .send(updatedQuestion);

      expect(updateResponse.status).toBe(200);
      expect(updateResponse.body.question).toBe(updatedQuestion.question);
    });
  });

  describe('Questions API - DELETE', () => {
    it('should delete a question', async () => {
      // Create a question
      const newQuestion = {
        quizId: 1,
        question: 'Question to delete?',
        options: ['A', 'B', 'C'],
        correctAnswer: 0
      };

      const createResponse = await request(app)
        .post('/api/questions')
        .send(newQuestion);

      const questionId = createResponse.body.id;

      // Delete it
      const deleteResponse = await request(app)
        .delete(`/api/questions/${questionId}`);

      expect(deleteResponse.status).toBe(200);
      expect(deleteResponse.body.success).toBe(true);
    });
  });

  describe('Error Handling', () => {
    it('should handle invalid routes', async () => {
      const response = await request(app).get('/api/invalid-endpoint');
      expect(response.status).toBe(404);
    });

    it('should return error for malformed JSON', async () => {
      const response = await request(app)
        .post('/api/questions')
        .set('Content-Type', 'application/json')
        .send('invalid json');

      expect(response.status).toBe(400);
    });
  });
});
