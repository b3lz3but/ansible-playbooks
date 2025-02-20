#!/bin/bash
# Ansible Playbook Runner Module for Webmin
# Description: Displays an HTML form to select and run Ansible playbooks.
# Author: System Administrator
# Last Modified: 2024

# Output the HTTP header
echo "Content-type: text/html"
echo ""

# Begin HTML output
cat <<'EOF'
<html>
<head>
  <title>Ansible Playbook Runner</title>
  <style>
    body { font-family: Arial, sans-serif; }
    h1 { color: #2e6c80; }
    .error { color: red; }
    pre { background: #f4f4f4; padding: 10px; border: 1px solid #ccc; }
  </style>
</head>
<body>
  <h1>Ansible Playbook Runner</h1>
EOF

# Check for inventory file
if [ ! -f "/ansible/inventory.ini" ]; then
  echo "<p class='error'>Error: /ansible/inventory.ini not found. Please add an inventory file.</p>"
  echo "</body></html>"
  exit 1
fi

# List available playbooks (assumes *.yml files in /ansible/playbooks)
PLAYBOOKS=$(ls /ansible/playbooks/*.yml 2>/dev/null | xargs -n1 basename)
if [ -z "$PLAYBOOKS" ]; then
  echo "<p class='error'>No playbooks found in /ansible/playbooks.</p>"
  echo "</body></html>"
  exit 1
fi

# If QUERY_STRING is set, try to extract the 'playbook' parameter and run it
if [ -n "$QUERY_STRING" ]; then
  PLAYBOOK=$(echo "$QUERY_STRING" | sed -n 's/.*playbook=\([^&]*\).*/\1/p' | sed "s/%20/ /g")
  if [ -n "$PLAYBOOK" ]; then
    echo "<h2>Running playbook: $PLAYBOOK</h2>"
    echo "<pre>"
    ansible-playbook -i /ansible/inventory.ini "/ansible/playbooks/$PLAYBOOK" 2>&1
    echo "</pre>"
  fi
fi

# Display the form to select a playbook
echo "<form method='GET'>"
echo "  <label for='playbook'>Select a playbook:</label><br>"
echo "  <select name='playbook' id='playbook'>"
for pb in $PLAYBOOKS; do
  echo "    <option value='$pb'>$pb</option>"
done
echo "  </select><br><br>"
echo "  <input type='submit' value='Run Playbook'>"
echo "</form>"

# End HTML output
echo "</body></html>"
