let editingId = null;

document.getElementById('questionForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const quizId = document.getElementById('quizId').value;
  const question = document.getElementById('question').value;
  const options = [
    document.getElementById('option1').value,
    document.getElementById('option2').value,
    document.getElementById('option3').value
  ];
  const correctAnswer = parseInt(document.getElementById('correctAnswer').value);

  const url = editingId ? `/api/questions/${editingId}` : '/api/questions';
  const method = editingId ? 'PUT' : 'POST';

  const response = await fetch(url, {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ quizId, question, options, correctAnswer })
  });

  if (response.ok) {
    alert(editingId ? 'Question updated!' : 'Question added!');
    editingId = null;
    document.getElementById('questionForm').reset();
    loadQuestions();
  }
});

async function loadQuestions() {
  const response = await fetch('/api/questions');
  const questions = await response.json();
  
  let html = '';
  questions.forEach(q => {
    html += `
      <div class="question-item">
        <p><strong>${q.question}</strong></p>
        <p>Options: ${q.options.join(', ')}</p>
        <p>Correct: ${q.options[q.correctAnswer]}</p>
        <button onclick="editQuestion(${q.id}, '${q.question}', '${q.options.join('|')}', ${q.correctAnswer})" class="btn">Edit</button>
        <button onclick="deleteQuestion(${q.id})" class="btn btn-delete">Delete</button>
      </div>
    `;
  });
  document.getElementById('questionsList').innerHTML = html;
}

function editQuestion(id, question, options, correctAnswer) {
  const opts = options.split('|');
  document.getElementById('quizId').value = 1;
  document.getElementById('question').value = question;
  document.getElementById('option1').value = opts[0];
  document.getElementById('option2').value = opts[1];
  document.getElementById('option3').value = opts[2];
  document.getElementById('correctAnswer').value = correctAnswer;
  editingId = id;
}

async function deleteQuestion(id) {
  if (confirm('Delete this question?')) {
    await fetch(`/api/questions/${id}`, { method: 'DELETE' });
    loadQuestions();
  }
}

loadQuestions();
