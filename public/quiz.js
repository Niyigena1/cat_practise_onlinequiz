// eslint-disable-next-line no-unused-vars
const quizzes = {
  1: {
    title: 'JavaScript Basics',
    questions: [
      { q: 'What is the correct way to declare a variable?', a: ['var x = 5;', 'variable x = 5;', 'v x = 5;'] },
      { q: 'What is the output of 2 + "2"?', a: ['4', '"4"', '22'] }
    ]
  },
  2: {
    title: 'React Fundamentals',
    questions: [
      { q: 'What is JSX?', a: ['JavaScript XML', 'Java Syntax Extension', 'JSON Extension'] },
      { q: 'What is a component?', a: ['Reusable piece of UI', 'Database table', 'API endpoint'] }
    ]
  }
};

// eslint-disable-next-line no-unused-vars
let currentQuiz, currentQuestion = 0, questions = [];

window.onload = async () => {
  const params = new URLSearchParams(window.location.search);
  const quizId = params.get('id');
  
  const response = await fetch('/api/questions');
  const allQuestions = await response.json();
  questions = allQuestions.filter(q => q.quizId == quizId);
  
  if (questions.length === 0) {
    document.getElementById('question-container').innerHTML = '<p>No questions found</p>';
    return;
  }
  
  document.getElementById('quiz-title').textContent = `Quiz ${quizId}`;
  displayQuestion();
};

function displayQuestion() {
  const q = questions[currentQuestion];
  let html = `<h3>${currentQuestion + 1}. ${q.question}</h3>`;
  q.options.forEach((ans, index) => {
    html += `<label><input type="radio" name="answer" value="${index}"> ${ans}</label><br>`;
  });
  document.getElementById('question-container').innerHTML = html;
  document.getElementById('feedback').innerHTML = '';
  document.getElementById('nextBtn').style.display = 'none';
  
  document.querySelectorAll('input[name="answer"]').forEach(input => {
    input.addEventListener('change', () => checkAnswer(q, input.value));
  });
}

function checkAnswer(q, selectedIndex) {
  const isCorrect = parseInt(selectedIndex) === q.correctAnswer;
  const feedbackDiv = document.getElementById('feedback');
  
  feedbackDiv.innerHTML = `
    <div class="feedback ${isCorrect ? 'correct' : 'incorrect'}">
      <p>${isCorrect ? '✅ Correct!' : '❌ Incorrect!'}</p>
      <p>Correct answer: <strong>${q.options[q.correctAnswer]}</strong></p>
      <p>Your answer: <strong>${q.options[selectedIndex]}</strong></p>
    </div>
  `;
  
  document.getElementById('nextBtn').style.display = 'inline-block';
  document.querySelectorAll('input[name="answer"]').forEach(input => {
    input.disabled = true;
  });
}

// eslint-disable-next-line no-unused-vars
function nextQuestion() {
  currentQuestion++;
  if (currentQuestion < questions.length) {
    displayQuestion();
  } else {
    document.getElementById('question-container').innerHTML = '';
    document.getElementById('feedback').innerHTML = '<h2>✅ Quiz Complete!</h2>';
    document.getElementById('nextBtn').style.display = 'none';
  }
}
