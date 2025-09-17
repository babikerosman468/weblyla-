// participate.js

document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('participateForm');

  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const data = {
      name: form.name.value,
      email: form.email.value,
      skills: form.skills.value
    };

    try {
      const res = await fetch('/api/participate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });

      const result = await res.json();

      if (result.success) {
        alert('Participation submitted! Thank you.');
        form.reset();
      } else {
        alert('Something went wrong. Please try again.');
      }
    } catch (err) {
      console.error(err);
      alert('Error submitting form. Please check your connection.');
    }
  });
});

