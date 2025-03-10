export function getCredentials() {
    // Fetch credentials from environment variables
    const username = process.env.ANSIBLE_USERNAME;
    const password = process.env.ANSIBLE_PASSWORD;

    if (!username || !password) {
        throw new Error('Missing credentials');
    }

    return `${username}:${password}`;
}