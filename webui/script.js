async function runPlaybook(playbook) {
    const response = await fetch('/api/run', {
        method: 'POST',
        headers: {
            'Authorization': 'Basic ' + btoa('admin:supersecret'),
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ playbook })
    });
    const result = await response.json();
    document.getElementById('output').textContent = JSON.stringify(result, null, 2);
}