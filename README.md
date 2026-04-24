# 🌩️ Scalable Cloud-Based Expense Management System
### *Using Google Cloud Platform (GCP)*

> **Lab Project** | Cloud Computing | Python Flask + MySQL + Bootstrap 5 + Chart.js

---
# Every time you want to run it:
cd D:\expense-tracker
.venv\Scripts\activate
python run.py

## 📁 Project Folder Structure

```
expense-tracker/
│
├── app/                          ← Flask application package
│   ├── __init__.py               ← App factory (create_app)
│   ├── models.py                 ← SQLAlchemy ORM models
│   │
│   ├── routes/                   ← Blueprint route handlers
│   │   ├── __init__.py
│   │   ├── auth.py               ← Register / Login / Logout
│   │   ├── main.py               ← Dashboard + chart data
│   │   ├── transactions.py       ← CRUD + receipt upload
│   │   └── budget.py             ← Budget limit management
│   │
│   ├── templates/                ← Jinja2 HTML templates
│   │   ├── base.html             ← Sidebar layout (all pages inherit)
│   │   ├── auth/
│   │   │   ├── login.html
│   │   │   └── register.html
│   │   ├── main/
│   │   │   └── dashboard.html    ← Chart.js charts + stat cards
│   │   ├── transactions/
│   │   │   ├── list.html         ← Filterable paginated table
│   │   │   ├── form.html         ← Add/Edit form with file upload
│   │   │   └── summary.html      ← Monthly report
│   │   └── budget/
│   │       ├── list.html         ← Progress bar cards
│   │       └── set.html          ← Budget form
│   │
│   └── static/
│       ├── css/style.css         ← Custom styles (sidebar, cards)
│       ├── js/app.js             ← Global JS helpers
│       └── uploads/              ← Local receipt storage
│
├── run.py                        ← App entry point
├── requirements.txt              ← Python dependencies
├── schema.sql                    ← MySQL table creation + test data
├── app.yaml                      ← Google App Engine config
├── Dockerfile                    ← Docker / Cloud Run / Kubernetes
├── k8s-deployment.yaml           ← GKE Kubernetes manifests
├── .env.example                  ← Environment variable template
├── .gitignore
└── README.md                     ← This file
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     USER (Browser)                                   │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ HTTPS
┌──────────────────────────▼──────────────────────────────────────────┐
│             Google App Engine (Python 3.11 + Gunicorn)               │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  Flask Application                                           │   │
│  │  ├── Blueprint: auth       (register, login, logout)         │   │
│  │  ├── Blueprint: main       (dashboard, charts)               │   │
│  │  ├── Blueprint: transactions (CRUD, receipt upload)          │   │
│  │  └── Blueprint: budget     (limits, alerts)                  │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────┬──────────────────────────────────┬───────────────────────┘
           │ Cloud SQL Connector              │ GCS Client Library
┌──────────▼──────────────┐      ┌───────────▼──────────────────────┐
│  Cloud SQL (MySQL 8)    │      │  Cloud Storage Bucket            │
│  Tables:                │      │  receipts/                       │
│  ├── users              │      │  ├── abc123.jpg                  │
│  ├── transactions       │      │  └── def456.pdf                  │
│  └── budgets            │      └──────────────────────────────────┘
└─────────────────────────┘
```

---

## ⚙️ Application Flow

```
1. User visits /  → redirected to /auth/login (Flask-Login)
2. Register  → password bcrypt-hashed → stored in users table
3. Login     → session created via Flask-Login
4. Dashboard → queries transactions for current month
              → aggregates income/expense totals
              → builds Chart.js data (last 6 months + categories)
              → checks budget limits → shows alerts if >80% spent
5. Add Txn   → validates form → optionally uploads receipt
              → if GCS_BUCKET set → uploads to Google Cloud Storage
              → else saves to static/uploads/
6. Budgets   → set per-category monthly limits
              → progress bars show actual vs budgeted spend
7. Summary   → category breakdown for selected month/year
```

---

## 🚀 Local Setup & Running

### Prerequisites
- Python 3.10+
- pip

### Step 1: Clone / create project
```bash
# If cloning:
git clone <repo-url>
cd expense-tracker

# OR navigate to project folder
cd expense-tracker
```

### Step 2: Create virtual environment
```bash
python -m venv venv

# Activate:
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate
```

### Step 3: Install dependencies
```bash
pip install -r requirements.txt
```

### Step 4: Set environment variables
```bash
cp .env.example .env
# Edit .env with your values (SECRET_KEY at minimum)
```

### Step 5: Run the app
```bash
python run.py
```

Visit: **http://localhost:5000**

> SQLite database is auto-created at `instance/expense_tracker.db`

---

## 🗄️ MySQL Setup (Local)

```bash
# Install MySQL if needed, then:
mysql -u root -p

CREATE DATABASE expense_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'expenseuser'@'localhost' IDENTIFIED BY 'strongpassword';
GRANT ALL PRIVILEGES ON expense_db.* TO 'expenseuser'@'localhost';
FLUSH PRIVILEGES;

# Run schema (creates tables + optional test data):
mysql -u expenseuser -p expense_db < schema.sql
```

Update `.env`:
```
DATABASE_URL=mysql+pymysql://expenseuser:strongpassword@localhost/expense_db
```

---

## ☁️ Google Cloud Platform Deployment

### Prerequisites
```bash
# Install Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

---

### Step 1: Create Cloud SQL (MySQL) Instance

```bash
# Create MySQL 8 instance (this takes ~5 minutes)
gcloud sql instances create expense-db-instance \
  --database-version=MYSQL_8_0 \
  --tier=db-f1-micro \
  --region=asia-south1 \
  --root-password=YourRootPassword123

# Create database
gcloud sql databases create expense_db \
  --instance=expense-db-instance

# Create database user
gcloud sql users create expenseuser \
  --instance=expense-db-instance \
  --password=YourDbPassword123

# Get connection name (format: project:region:instance)
gcloud sql instances describe expense-db-instance \
  --format="value(connectionName)"
# → e.g. my-project:asia-south1:expense-db-instance

# Connect and run schema
gcloud sql connect expense-db-instance --user=root
# (paste contents of schema.sql at the MySQL prompt)
```

---

### Step 2: Create Cloud Storage Bucket

```bash
# Create bucket (name must be globally unique)
gcloud storage buckets create gs://expense-tracker-receipts-YOURNAME \
  --location=asia-south1 \
  --uniform-bucket-level-access

# Allow public read (so receipt URLs are accessible)
gcloud storage buckets add-iam-policy-binding \
  gs://expense-tracker-receipts-YOURNAME \
  --member=allUsers \
  --role=roles/storage.objectViewer

# Allow App Engine service account to write
gcloud storage buckets add-iam-policy-binding \
  gs://expense-tracker-receipts-YOURNAME \
  --member=serviceAccount:YOUR_PROJECT_ID@appspot.gserviceaccount.com \
  --role=roles/storage.objectAdmin
```

---

### Step 3: Enable Required APIs

```bash
gcloud services enable \
  appengine.googleapis.com \
  sqladmin.googleapis.com \
  storage.googleapis.com \
  cloudresourcemanager.googleapis.com
```

---

### Step 4: Configure app.yaml

Edit `app.yaml` and replace ALL placeholders:
```yaml
env_variables:
  SECRET_KEY: "your-64-char-random-string"
  DATABASE_URL: "mysql+pymysql://expenseuser:YourDbPassword123@/expense_db?unix_socket=/cloudsql/my-project:asia-south1:expense-db-instance"
  GCS_BUCKET: "expense-tracker-receipts-YOURNAME"

beta_settings:
  cloud_sql_instances: "my-project:asia-south1:expense-db-instance"
```

---

### Step 5: Deploy to App Engine

```bash
# Initialize App Engine (first time only)
gcloud app create --region=asia-south1

# Deploy
gcloud app deploy

# Open in browser
gcloud app browse
```

---

## 🐳 Docker / Cloud Run / Kubernetes

### Build & Push Docker Image

```bash
# Build
docker build -t gcr.io/YOUR_PROJECT_ID/expense-tracker:latest .

# Push to Google Container Registry
gcloud auth configure-docker
docker push gcr.io/YOUR_PROJECT_ID/expense-tracker:latest
```

### Deploy to Cloud Run (serverless containers)

```bash
gcloud run deploy expense-tracker \
  --image gcr.io/YOUR_PROJECT_ID/expense-tracker:latest \
  --platform managed \
  --region asia-south1 \
  --allow-unauthenticated \
  --add-cloudsql-instances YOUR_PROJECT:REGION:INSTANCE \
  --set-env-vars "DATABASE_URL=...,SECRET_KEY=...,GCS_BUCKET=..."
```

### Deploy to GKE (Kubernetes)

```bash
# Create GKE cluster
gcloud container clusters create expense-cluster \
  --num-nodes=2 \
  --region=asia-south1

# Get credentials
gcloud container clusters get-credentials expense-cluster --region=asia-south1

# Edit k8s-deployment.yaml with your values, then:
kubectl apply -f k8s-deployment.yaml

# Check status
kubectl get pods
kubectl get services

# Get external IP
kubectl get service expense-tracker-service
```

---

## 🧪 Sample Test Data

Use these credentials to log in with the test account (after running schema.sql):
```
Email:    test@example.com
Password: password123
```

Or register a new account at `/auth/register`.

---

## 🔗 Cloud Lab Experiment Alignment

| Lab Experiment | How This Project Uses It |
|---|---|
| **Virtual Machines (Compute Engine)** | Could host Flask app on a GCE VM instead of App Engine |
| **Cloud SQL** | MySQL 8 on Cloud SQL; connected via Cloud SQL Python Connector |
| **Cloud Storage** | Receipt files (images/PDFs) stored in GCS bucket |
| **App Engine** | Serverless PaaS deployment via `app.yaml` |
| **Cloud Functions** | Could trigger budget alerts via Pub/Sub → Cloud Function → email |
| **Pub/Sub** | Could publish a message when a transaction exceeds budget limit |
| **Kubernetes (GKE)** | `k8s-deployment.yaml` with HPA for auto-scaling |
| **Cloud Monitoring** | App Engine auto-integrates; custom metrics via Cloud Monitoring API |
| **Cloud Build** | CI/CD pipeline: `cloudbuild.yaml` → test → build → deploy |
| **IAM** | Service account for GCS write, Cloud SQL access |

---

## 📝 Viva Questions & Answers

**Q1. What is the architecture of your application?**
> A three-tier cloud-native architecture: Presentation (Bootstrap 5 frontend), Application (Flask on App Engine), and Data (MySQL on Cloud SQL + files on Cloud Storage). The tiers are loosely coupled — the frontend uses Jinja2 templates, the backend uses SQLAlchemy ORM to abstract the database, and storage is switched by an environment variable.

**Q2. Why Flask instead of Django?**
> Flask is a micro-framework ideal for learning and cloud labs — minimal boilerplate, easy to understand each component. It uses Blueprints for modular routing, similar to Django's apps. Django would be overkill for this project scope.

**Q3. How is the database connected to Cloud SQL?**
> Via the `cloud-sql-python-connector` library. On App Engine, the connection uses a Unix socket (`/cloudsql/PROJECT:REGION:INSTANCE`) which is more secure than TCP because it doesn't require opening firewall rules. Locally, we connect via TCP with PyMySQL.

**Q4. How does receipt upload work?**
> The app checks `GCS_BUCKET` environment variable. If set, `google-cloud-storage` SDK uploads the file to the bucket and returns a public URL stored in the `receipt_url` column. If not set, the file is saved to `static/uploads/` locally. This makes local dev easy while being cloud-ready.

**Q5. How is authentication implemented?**
> Flask-Login manages sessions (stores user ID in signed cookie). Flask-Bcrypt hashes passwords using bcrypt (adaptive hashing — resists brute force). The `@login_required` decorator protects all authenticated routes. Passwords are never stored in plain text.

**Q6. What are SQLAlchemy ORM relationships?**
> `db.relationship('Transaction', backref='owner')` in the User model creates a virtual attribute — `user.transactions` returns all transactions. `backref='owner'` adds `transaction.owner` pointing back to User. `cascade='all, delete-orphan'` means deleting a user deletes their transactions automatically.

**Q7. What is the purpose of Blueprints?**
> Blueprints modularize the application. Each Blueprint is a self-contained set of routes, like `auth_bp` handles all `/auth/*` routes. This makes the code maintainable, testable, and scalable — you can add new features without touching existing code.

**Q8. How does the Chart.js integration work?**
> Flask calculates aggregated data server-side (monthly totals, category sums). These Python lists are passed to the template and rendered into JavaScript arrays by Jinja2's `tojson` filter: `const data = {{ income_data | tojson }}`. Chart.js then uses these to render bar and doughnut charts in the browser.

**Q9. What is Gunicorn and why use it?**
> Gunicorn is a production WSGI server. Flask's built-in server is single-threaded and not suitable for production. Gunicorn spawns multiple worker processes to handle concurrent requests. App Engine uses `gunicorn -b :$PORT run:app` as the entrypoint.

**Q10. How does Kubernetes auto-scaling work in your deployment?**
> The `HorizontalPodAutoscaler` in `k8s-deployment.yaml` monitors CPU usage. When average CPU exceeds 60%, it adds more pods (up to 10). When load drops, it scales down to the minimum (2). This ensures availability during traffic spikes while minimizing cost during idle periods.

**Q11. What security measures are implemented?**
> (1) Bcrypt password hashing — salted and adaptive. (2) CSRF protection via Flask's secret key-signed session cookies. (3) Authorization checks — every edit/delete verifies `txn.user_id == current_user.id`, returning 403 otherwise. (4) `secure_filename()` sanitizes uploaded filenames. (5) Environment variables keep credentials out of code. (6) Max upload size limits (5MB) prevent DoS via large files.

**Q12. What is the role of the `.env` file?**
> `.env` stores sensitive configuration (database credentials, secret key, bucket name) outside of source code. The `.gitignore` excludes it from version control. On App Engine, these are set as `env_variables` in `app.yaml`. This follows the Twelve-Factor App methodology: store config in the environment.

**Q13. Explain database indexing in your schema.**
> The MySQL schema adds composite indexes on frequently queried columns: `idx_user_date (user_id, date)` speeds up monthly queries like `WHERE user_id=1 AND MONTH(date)=6`. `idx_user_type` optimizes income/expense filter. Without indexes, each query would do a full table scan — O(n) instead of O(log n).

**Q14. What is the difference between App Engine Standard and Flexible?**
> Standard uses a sandboxed runtime (Python 3.11), scales to zero, and has free tier — ideal for this lab. Flexible runs Docker containers on Compute Engine VMs, supports any runtime, but costs more and has minimum 1 instance running. We use Standard since our Flask app fits the supported runtime.

**Q15. How would you add Pub/Sub for real-time budget alerts?**
> When a transaction is added that causes spending to exceed budget: (1) Publish a message to a Pub/Sub topic with `{user_id, category, amount, limit}`. (2) A Cloud Function subscribes to this topic. (3) The function sends an email via SendGrid or SMS via Twilio. This decouples the alert mechanism from the main app.

---

## ✅ Implementation Checklist

### Local Development
- [ ] Clone/create project with folder structure
- [ ] Create virtual environment: `python -m venv venv`
- [ ] Activate venv and install: `pip install -r requirements.txt`
- [ ] Copy `.env.example` to `.env` and set `SECRET_KEY`
- [ ] Run: `python run.py`
- [ ] Visit http://localhost:5000, register account
- [ ] Test: add income transaction, add expense, set budget
- [ ] Verify charts appear on dashboard
- [ ] Test receipt upload (local mode)

### MySQL Setup (Local)
- [ ] Install MySQL
- [ ] Create database: `expense_db`
- [ ] Run `schema.sql`
- [ ] Update `DATABASE_URL` in `.env`
- [ ] Restart app, verify it connects to MySQL

### GCP Deployment
- [ ] Create GCP project
- [ ] Enable APIs (App Engine, Cloud SQL, Storage)
- [ ] Create Cloud SQL MySQL instance
- [ ] Create database and user in Cloud SQL
- [ ] Run schema.sql via `gcloud sql connect`
- [ ] Create GCS bucket with public access
- [ ] Update `app.yaml` with all placeholders replaced
- [ ] Run `gcloud app deploy`
- [ ] Test all features on live URL
- [ ] Verify receipts upload to GCS bucket

### Kubernetes (Optional)
- [ ] Build Docker image
- [ ] Push to GCR
- [ ] Update `k8s-deployment.yaml` with project/image values
- [ ] Create GKE cluster
- [ ] Apply deployment: `kubectl apply -f k8s-deployment.yaml`
- [ ] Get external IP and test

---

## 📊 Key Commands Reference

```bash
# Local run
python run.py

# Install deps
pip install -r requirements.txt

# Generate secret key
python -c "import secrets; print(secrets.token_hex(32))"

# Create Cloud SQL instance
gcloud sql instances create expense-db-instance --database-version=MYSQL_8_0 --tier=db-f1-micro --region=asia-south1

# Create GCS bucket
gcloud storage buckets create gs://my-expense-receipts --location=asia-south1

# Deploy to App Engine
gcloud app deploy

# View App Engine logs
gcloud app logs tail -s default

# Build Docker image
docker build -t expense-tracker .

# Run Docker locally
docker run -p 8080:8080 --env-file .env expense-tracker

# Push to GCR
docker tag expense-tracker gcr.io/PROJECT_ID/expense-tracker
docker push gcr.io/PROJECT_ID/expense-tracker

# Deploy to GKE
kubectl apply -f k8s-deployment.yaml
kubectl get pods
kubectl get services
```
