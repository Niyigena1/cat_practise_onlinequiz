const request = require('supertest');
const app = require('../src/app');

describe('Integration Tests - Quiz API Flow', () => {
  
  describe('Complete Quiz Workflow', () => {
    let questionId;

    it('Step 1: Admin adds a quiz question', async () => {
      const question = {
        quizId: 1,
        question: 'What is JavaScript?',
        options: ['Programming Language', 'Markup Language', 'Database'],
        correctAnswer: 0
      };

      const response = await request(app)
        .post('/api/questions')
        .send(question);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('id');
      questionId = response.body.id;
    });

    it('Step 2: User retrieves all questions', async () => {
      const response = await request(app)
        .get('/api/questions');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);
    });

    it('Step 3: Admin can retrieve specific question', async () => {
      if (!questionId) {
        // If no question was created, skip this test
        return;
      }

      const response = await request(app)
        .get(`/api/questions`);

      expect(response.status).toBe(200);
      const questionExists = response.body.some(q => q.id === questionId);
      expect(questionExists).toBe(true);
    });

    it('Step 4: Admin updates the question', async () => {
      if (!questionId) return;

      const updated = {
        question: 'What is Node.js?',
        options: ['JavaScript Runtime', 'Database', 'Framework'],
        correctAnswer: 0
      };

      const response = await request(app)
        .put(`/api/questions/${questionId}`)
        .send(updated);

      expect(response.status).toBe(200);
      expect(response.body.question).toBe(updated.question);
    });

    it('Step 5: Admin deletes the question', async () => {
      if (!questionId) return;

      const response = await request(app)
        .delete(`/api/questions/${questionId}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('Multiple Questions Scenario', () => {
    it('should handle adding multiple questions', async () => {
      const questions = [
        {
          quizId: 1,
          question: 'Q1?',
          options: ['A1', 'B1', 'C1'],
          correctAnswer: 0
        },
        {
          quizId: 1,
          question: 'Q2?',
          options: ['A2', 'B2', 'C2'],
          correctAnswer: 1
        },
        {
          quizId: 2,
          question: 'Q3?',
          options: ['A3', 'B3', 'C3'],
          correctAnswer: 2
        }
      ];

      for (const q of questions) {
        const response = await request(app)
          .post('/api/questions')
          .send(q);

        expect(response.status).toBe(200);
      }

      const allQuestions = await request(app).get('/api/questions');
      expect(allQuestions.body.length).toBeGreaterThanOrEqual(3);
    });
  });

  describe('Data Persistence', () => {
    it('added questions should persist across requests', async () => {
      const question = {
        quizId: 1,
        question: 'Persistence test?',
        options: ['Yes', 'No'],
        correctAnswer: 0
      };

      const createResponse = await request(app)
        .post('/api/questions')
        .send(question);

      const questionId = createResponse.body.id;

      // Retrieve immediately
      const retrieval1 = await request(app).get('/api/questions');
      expect(retrieval1.body.some(q => q.id === questionId)).toBe(true);

      // Simulate time passing and retrieve again
      await new Promise(resolve => setTimeout(resolve, 100));

      const retrieval2 = await request(app).get('/api/questions');
      expect(retrieval2.body.some(q => q.id === questionId)).toBe(true);
    });
  });

  describe('Concurrent Operations', () => {
    it('should handle concurrent POST requests', async () => {
      const promises = [];

      for (let i = 0; i < 3; i++) {
        promises.push(
          request(app)
            .post('/api/questions')
            .send({
              quizId: 1,
              question: `Concurrent Question ${i}?`,
              options: ['A', 'B', 'C'],
              correctAnswer: 0
            })
        );
      }

      const responses = await Promise.all(promises);
      responses.forEach(response => {
        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('id');
      });
    });
  });

  describe('API Response Format', () => {
    it('should return proper JSON format', async () => {
      const response = await request(app).get('/api/questions');

      expect(response.headers['content-type']).toContain('application/json');
      expect(Array.isArray(response.body)).toBe(true);
    });

    it('should include proper HTTP headers', async () => {
      const response = await request(app).get('/api/questions');

      expect(response.headers['content-type']).toBeDefined();
      expect(response.status).toBeGreaterThanOrEqual(200);
      expect(response.status).toBeLessThan(300);
    });
  });
});
