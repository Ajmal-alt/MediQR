# MediQR V3 — AWS EC2 + VPC Deployment Guide

இந்த guide-ஐ பின்பற்றி உங்கள் MediQR app-ஐ AWS cloud-ல் deploy செய்யலாம்.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                 AWS Cloud                       │
│                                                 │
│  ┌──────────────┐      ┌────────────────────┐   │
│  │    VPC       │      │   Security Groups  │   │
│  │              │      │                    │   │
│  │ ┌──────────┐ │      │  EC2: 80, 3000     │   │
│  │ │  EC2     │ │      │  RDS: 3306         │   │
│  │ │ (Node.js)│ │      │                    │   │
│  │ └──────────┘ │      └────────────────────┘   │
│  │              │                               │
│  │ ┌──────────┐ │                               │
│  │ │   RDS    │ │                               │
│  │ │ (MySQL)  │ │                               │
│  │ └──────────┘ │                               │
│  └──────────────┘                               │
│                                                 │
│  Flutter App ──── HTTP ──── EC2 Public IP       │
└─────────────────────────────────────────────────┘
```

---

## Step 1 — Create VPC

1. AWS Console → **VPC** → **Create VPC**
2. Select **VPC and more**
3. Name: `mediqr-vpc`
4. IPv4 CIDR: `10.0.0.0/16`
5. Number of AZs: **2**
6. Number of public subnets: **2**
7. Number of private subnets: **2**
8. NAT gateways: **None** (free tier)
9. Click **Create VPC**

> இது public subnet-ல் EC2, private subnet-ல் RDS வைக்க உதவும்.

---

## Step 2 — Create RDS MySQL Database

1. AWS Console → **RDS** → **Create database**
2. Engine: **MySQL**
3. Version: **MySQL 8.0**
4. Template: **Free tier**
5. DB instance identifier: `mediqr-db`
6. Master username: `mediqr_admin`
7. Master password: (strong password எடுங்கள்)
8. **Connectivity:**
   - VPC: `mediqr-vpc`
   - DB subnet group: private subnets
   - Public access: **No**
9. Create database

> RDS endpoint-ஐ குறித்து வையுங்கள் (e.g., `mediqr-db.xxxxx.us-east-1.rds.amazonaws.com`)

---

## Step 3 — Create EC2 Instance

1. AWS Console → **EC2** → **Launch instance**
2. Name: `mediqr-server`
3. AMI: **Ubuntu 22.04 LTS**
4. Instance type: **t2.micro** (free tier)
5. Key pair: Create new `mediqr-key.pem`
6. Network settings:
   - VPC: `mediqr-vpc`
   - Subnet: public subnet
   - Auto-assign public IP: **Enable**
7. **Security Group** (create new):
   - SSH: port 22 (your IP only)
   - HTTP: port 80 (0.0.0.0/0)
   - HTTPS: port 443 (0.0.0.0/0) — optional
8. Launch instance

---

## Step 4 — Connect RDS to EC2 (Security Group)

1. RDS → `mediqr-db` → Connectivity → VPC security group
2. Edit inbound rules:
   - **MySQL/Aurora**: port 3306
   - Source: EC2 security group ID (not IP!)
3. Save

> இது EC2 மட்டும் RDS-ஐ அணுக முடியும். வெளியில் இருந்து யாரும் அணுக முடியாது.

---

## Step 5 — Connect to EC2 & Setup

```bash
# Windows PowerShell / CMD
ssh -i "C:\path\to\mediqr-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

### Upload deployment files (from your PC):

```bash
# From your project folder (mediqr2)
scp -i "C:\path\to\mediqr-key.pem" -r deploy ubuntu@YOUR_EC2_PUBLIC_IP:/home/ubuntu/
```

### Run setup script:

```bash
chmod +x /home/ubuntu/deploy/setup_ec2.sh
sudo /home/ubuntu/deploy/setup_ec2.sh
```

---

## Step 6 — Configure .env

```bash
cd /home/ubuntu/mediqr/backend
nano .env
```

Update these values:

```env
PORT=3000
DB_HOST=mediqr-db.xxxxx.us-east-1.rds.amazonaws.com
DB_USER=mediqr_admin
DB_PASSWORD=YOUR_DB_PASSWORD
DB_NAME=mediqr3
DB_PORT=3306
JWT_SECRET=use-a-long-random-string-here
PUBLIC_URL=http://YOUR_EC2_PUBLIC_IP
```

---

## Step 7 — Import Database Schema

```bash
mysql -h mediqr-db.xxxxx.us-east-1.rds.amazonaws.com -u mediqr_admin -p mediqr3 < /home/ubuntu/mediqr/database/schema.sql
```

> `mediqr3` database-ஐ முதலில் create செய்யுங்கள்:
> ```sql
> CREATE DATABASE mediqr3;
> ```

---

## Step 8 — Start Backend with PM2

```bash
cd /home/ubuntu/mediqr/backend
pm2 start server.js --name mediqr-backend
pm2 save
pm2 startup
```

Check status:
```bash
pm2 status
curl http://localhost:3000/api/health
```

---

## Step 9 — Configure Nginx

```bash
sudo cp /home/ubuntu/mediqr/deploy/mediqr-nginx.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/mediqr-nginx.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

Test:
```bash
curl http://YOUR_EC2_PUBLIC_IP/api/health
```

---

## Step 10 — Create S3 Bucket (for Videos & Images)

1. AWS Console → **S3** → **Create bucket**
2. Bucket name: `mediqr-media` (unique name)
3. Region: உங்கள் EC2 region-க்கு அருகில்
4. **Block Public Access**: Uncheck (public-read videos வேண்டும்)
5. **ACLs enabled**: Check
6. Create bucket

### Create IAM User for S3 Access

1. AWS Console → **IAM** → **Users** → **Create user**
2. Name: `mediqr-s3-user`
3. Permissions: **Attach policies directly**
4. Add policy: `AmazonS3FullAccess`
5. Create user → **Create access key** → Save Access Key ID & Secret

### Update .env with S3 credentials

```bash
cd /home/ubuntu/mediqr/backend
nano .env
```

```env
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY
S3_BUCKET_NAME=mediqr-media
```

Restart backend:
```bash
pm2 restart mediqr-backend
```

---

## Step 11 — Update Flutter App

Open `lib/utils/app_config.dart`:

```dart
static const String baseUrl = 'http://YOUR_EC2_PUBLIC_IP';
```

Build APK:
```bash
flutter pub get
flutter build apk --release
```

---

## Step 12 — Upload Videos to S3

### Option A: Via API (recommended)

Login மூலம் token எடுத்து, upload செய்யுங்கள்:

```bash
# Get token
TOKEN=$(curl -s -X POST http://YOUR_EC2_PUBLIC_IP/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"your@email.com","password":"yourpass"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

# Upload video
curl -X POST http://YOUR_EC2_PUBLIC_IP/api/upload/video \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@paracetamol_ta.mp4" \
  -F "medicine_id=1" \
  -F "language_code=ta"
```

Response-ல் வரும் `video_url`-ஐ database-ல் சேர்க்கவும்:

```sql
USE mediqr3;
INSERT INTO videos (medicine_id, language_code, video_url, file_name) VALUES
(1, 'ta', 'https://mediqr-media.s3.us-east-1.amazonaws.com/videos/1_ta.mp4', 'paracetamol_ta.mp4');
```

### Option B: AWS CLI (direct upload)

```bash
# Install AWS CLI on your PC
aws s3 cp paracetamol_ta.mp4 s3://mediqr-media/videos/1_ta.mp4 --acl public-read
```

Then update DB:
```sql
USE mediqr3;
INSERT INTO videos (medicine_id, language_code, video_url, file_name) VALUES
(1, 'ta', 'https://mediqr-media.s3.us-east-1.amazonaws.com/videos/1_ta.mp4', 'paracetamol_ta.mp4');
```

---

## Docker Deployment (Optional but Recommended)

Docker-ஐ பயன்படுத்தி backend-ஐ containerize செய்து Docker Hub-க்கு push செய்யலாம்.

### Step A — Build & Push to Docker Hub (உங்கள் PC-ல்)

```bash
# 1. Docker install செய்யுங்கள் (https://www.docker.com/products/docker-desktop/)
# 2. Docker Hub account create செய்யுங்கள் (https://hub.docker.com)

# 3. Docker login
docker login

# 4. Build & push (உங்கள் Docker Hub username-ஐ போடுங்கள்)
bash deploy/docker_push.sh YOUR_DOCKER_USERNAME
```

இது `backend/Dockerfile`-ஐ பயன்படுத்தி image build செய்து push செய்யும்.

### Step B — EC2-ல் Docker Install

```bash
# EC2-ல்
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
# Re-login: exit, then ssh again
```

### Step C — Docker Compose மூலம் Run (Local Test)

உங்கள் PC-ல் local test செய்ய:

```bash
# Project root-ல் (mediqr2)
docker-compose up -d
```

இது backend + MySQL இரண்டையும் start செய்யும். Schema auto-import ஆகும்.

### Step D — EC2-ல் Docker Image Run

```bash
# EC2-ல்
mkdir -p /home/ubuntu/mediqr
cd /home/ubuntu/mediqr

# docker-compose.yml + .env upload செய்யுங்கள்
scp -i "C:\path\to\mediqr-key.pem" docker-compose.yml ubuntu@YOUR_EC2_PUBLIC_IP:/home/ubuntu/mediqr/

# .env file create (S3 credentials)
cat > .env << 'EOF'
AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY
S3_BUCKET_NAME=mediqr-media
EOF

# docker-compose.yml-ல் image name-ஐ update செய்யுங்கள்:
#   build: ./backend  →  image: YOUR_DOCKER_USERNAME/mediqr-backend:v3.0.0

# Run
docker-compose up -d
```

### Docker Files Summary

| File | Purpose |
|---|---|
| `backend/Dockerfile` | Backend image build |
| `backend/.dockerignore` | node_modules, .env exclude |
| `docker-compose.yml` | Backend + MySQL together |
| `deploy/docker_push.sh` | Build & push to Docker Hub |

---

## Security Checklist

- [ ] EC2 Security Group: port 22 only your IP
- [ ] RDS Security Group: port 3306 only EC2 SG
- [ ] JWT_SECRET strong random string
- [ ] DB password strong
- [ ] (Optional) Add HTTPS with Let's Encrypt:
  ```bash
  sudo apt install certbot python3-certbot-nginx
  sudo certbot --nginx -d yourdomain.com
  ```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `ECONNREFUSED` DB | Check RDS endpoint, security group, .env |
| `Access denied` DB | Check username/password in .env |
| Port 3000 not reachable | Use Nginx on port 80, don't expose 3000 |
| App can't connect | Check `app_config.dart` baseUrl |
| Videos not loading | Check video URLs in DB, files in `backend/videos/` |

---

## Cost (Free Tier)

| Service | Free Tier |
|---|---|
| EC2 t2.micro | 750 hrs/month |
| RDS db.t3.micro | 750 hrs/month |
| VPC | Free |

> Free tier முடிந்த பிறகு ~$15-20/month ஆகும்.