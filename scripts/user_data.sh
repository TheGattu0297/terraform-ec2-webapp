#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y \
  python3-pip \
  python3-venv \
  curl \
  wget \
  postgresql-client

# Create app directory
mkdir -p /opt/webapp
cd /opt/webapp

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Create requirements file
cat > requirements.txt << 'EOF'
Flask==2.3.0
psycopg2-binary==2.9.6
python-dotenv==1.0.0
EOF

# Install Python dependencies
pip install -r requirements.txt

# Create Flask application
cat > app.py << 'EOF'
from flask import Flask, render_template_string, jsonify
import psycopg2
import os
import socket
from datetime import datetime

app = Flask(__name__)

# Database configuration
def get_db():
    try:
        conn = psycopg2.connect(
            host=os.environ.get('DB_HOST', '${db_host}').split(':')[0],
            database=os.environ.get('DB_NAME', '${db_name}'),
            user=os.environ.get('DB_USERNAME', '${db_username}'),
            password=os.environ.get('DB_PASSWORD', '${db_password}'),
            port=5432
        )
        return conn
    except Exception as e:
        return None

@app.route('/')
def index():
    db_status = "✓ Connected"
    instance_id = socket.gethostname()
    current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    try:
        conn = get_db()
        if conn:
            conn.close()
        else:
            db_status = "✗ Failed to connect"
    except:
        db_status = "✗ Error connecting"
    
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>EC2 WebApp</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; }}
            .container {{ max-width: 600px; margin: 0 auto; }}
            .status {{ padding: 20px; background: #f0f0f0; border-radius: 5px; }}
            .ok {{ color: green; }}
            .error {{ color: red; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>EC2 Web Application</h1>
            <div class="status">
                <p><strong>Instance ID (Hostname):</strong> {instance_id}</p>
                <p><strong>Current Time:</strong> {current_time}</p>
                <p><strong>Database Status:</strong> <span class="{'ok' if 'Connected' in db_status else 'error'}">{db_status}</span></p>
                <p><strong>Application:</strong> Running on Python Flask</p>
            </div>
            <hr>
            <p>Request ID: {os.urandom(8).hex()}</p>
        </div>
    </body>
    </html>
    """
    return render_template_string(html)

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/status')
def status():
    return jsonify({
        "hostname": socket.gethostname(),
        "database": "connected" if get_db() else "disconnected",
        "time": datetime.now().isoformat()
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# Create systemd service file
cat > /etc/systemd/system/webapp.service << 'EOF'
[Unit]
Description=EC2 Web Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/webapp
Environment="PATH=/opt/webapp/venv/bin"
Environment="DB_HOST=${db_host}"
Environment="DB_NAME=${db_name}"
Environment="DB_USERNAME=${db_username}"
Environment="DB_PASSWORD=${db_password}"
ExecStart=/opt/webapp/venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable webapp.service
systemctl start webapp.service

echo "Application deployment completed successfully!"
