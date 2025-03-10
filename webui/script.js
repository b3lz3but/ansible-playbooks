import { getCredentials } from './credentials.js';

async function runPlaybook(playbook) {
    try {
        const response = await fetch('/api/run', {
            method: 'POST',
            headers: {
                'Authorization': 'Basic ' + btoa(getCredentials()), // Consider moving credentials to a secure location
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ playbook })
        });

        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(`Network response was not ok: ${errorText}`);
        }

        const result = await response.json();
        document.getElementById('output').textContent = JSON.stringify(result, null, 2);
    } catch (error) {
        document.getElementById('output').textContent = 'Error: ' + error.message;
    }
}

function getCredentials() {
    // Fetch credentials from a secure location
    return 'admin:supersecret';
}