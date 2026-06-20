#!/bin/sh
set -e

# Gather variables injected via container environment (with safe fallbacks)
WEBDAV_USER="${WEBDAV_USER:-admin}"
WEBDAV_PASS="${WEBDAV_PASS:-password123}"
WEBDAV_REALM="${WEBDAV_REALM:-WebDAV}"

echo "Bootstrapping WebDAV image..."
echo "Realm destination set to: ${WEBDAV_REALM}"
echo "User configuration set to: ${WEBDAV_USER}"

# 1. Hot-swap the placeholder inside the Apache config with your custom Realm
sed -i "s/DYNAMIC_REALM_PLACEHOLDER/${WEBDAV_REALM}/g" /etc/apache2/sites-available/000-default.conf

# 2. Programmatically generate the cryptographic digest password file
# FIXED: Using printf to reliably send the password twice with a clean newline
printf "%s\n%s\n" "${WEBDAV_PASS}" "${WEBDAV_PASS}" | htdigest -c /etc/apache2/users.passwd "${WEBDAV_REALM}" "${WEBDAV_USER}"

# 3. Secure file permissions before launching server
chown www-data:www-data /etc/apache2/users.passwd
chmod 600 /etc/apache2/users.passwd

# Handoff to Apache foreground process
exec "$@"
