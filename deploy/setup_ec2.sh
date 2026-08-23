#!/bin/bash
# ============================================
# MediQR V3 - AWS EC2 Setup Script (Ubuntu)
# Run this on your EC2 instance
# ============================================

set -e

echo "=========================================="
echo " MediQR V3 - EC2 Setup Script"
echo "=========================================="

# 1. Update system
echo "[1/8] Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# 2. Install Node.js 20.x
echo "[2/8] Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Install MySQL client (for connecting to RDS)
echo "[3/8] Installing MySQL client..."
sudo apt-get install -y mysql-client

# 4. Install PM2 (process manager)
echo "[4/8] Installing PM2..."
sudo npm install -g pm2

# 5. Install Nginx (reverse proxy)
echo "[5/8] Installing Nginx..."
sudo apt-get install -y nginx

# 6. Clone the repository
echo "[6/8] Cloning MediQR repository..."
cd /home/ubuntu
if [ ! -d "mediqr" ]; then
  git clone https://github.com/Ajmal-alt/MediQR.git mediqr
fi
cd mediqr/backend

# 7. Install backend dependencies
echo "[7/8] Installing backend dependencies..."
npm install --production

# 8. Create .env file (EDIT THESE VALUES!)
echo "[8/8] Creating .env file..."
cat > .env << 'EOF'
PORT=3000
DB_HOST=YOUR_RDS_ENDPOINT
DB_USER=YOUR_DB_USER
DB_PASSWORD=YOUR_DB_PASSWORD
DB_NAME=mediqr3
DB_PORT=3306
JWT_SECRET=CHANGE_THIS_TO_A_RANDOM_SECRET
PUBLIC_URL=http://YOUR_EC2_PUBLIC_IP
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY
S3_BUCKET_NAME=mediqr-media
EOF

echo ""
echo "=========================================="
echo " Setup complete!"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo "1. Edit the .env file with your RDS details:"
echo "   nano /home/ubuntu/mediqr/backend/.env"
echo ""
echo "2. Import the database schema:"
echo "   mysql -h YOUR_RDS_ENDPOINT -u YOUR_DB_USER -p mediqr3 < /home/ubuntu/mediqr/database/schema.sql"
echo ""
echo "3. Start the backend with PM2:"
echo "   cd /home/ubuntu/mediqr/backend && pm2 start server.js --name mediqr-backend"
echo "   pm2 save && pm2 startup"
echo ""
echo "4. Configure Nginx (see nginx config file):"
echo "   sudo cp /home/ubuntu/mediqr/deploy/mediqr-nginx.conf /etc/nginx/sites-available/"
echo "   sudo ln -s /etc/nginx/sites-available/mediqr-nginx.conf /etc/nginx/sites-enabled/"
echo "   sudo nginx -t && sudo systemctl reload nginx"
echo ""
echo "5. Open port 80 in your EC2 Security Group!"
echo ""