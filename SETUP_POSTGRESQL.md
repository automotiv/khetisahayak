# 🗄️ PostgreSQL Setup for Kheti Sahayak

## ✅ Quick PostgreSQL Setup

As per **Agents.md**, Kheti Sahayak uses **PostgreSQL 14+** as the primary database.

---

## 📥 **Install PostgreSQL (If Not Installed)**

### **Download:**
https://www.postgresql.org/download/windows/

**Recommended Version:** PostgreSQL 14 or higher

### **During Installation:**
- Remember the password you set for user `postgres`
- Default port: `5432`
- Leave other settings as default

---

## 🔧 **Create Database**

### **Option 1: Using pgAdmin (GUI)**
1. Open pgAdmin (installed with PostgreSQL)
2. Right-click on "Databases"
3. Create → Database
4. Name: `kheti_sahayak`
5. Click Save

### **Option 2: Using Command Line**
```cmd
# Open Command Prompt or PowerShell
# Connect to PostgreSQL
psql -U postgres

# Enter your postgres password when prompted

# Create database
CREATE DATABASE kheti_sahayak;

# Verify
\l

# Exit
\q
```

---

## ⚙️ **Configure Application**

### **Method 1: Set Environment Variables (Recommended)**

```powershell
# Set PostgreSQL password (replace 'your_password' with actual password)
[System.Environment]::SetEnvironmentVariable('DB_PASSWORD', 'your_password', [System.EnvironmentVariableTarget]::User)

# Verify
echo $env:DB_PASSWORD
```

### **Method 2: Create .env file**

Create `kheti_sahayak_spring_boot/.env`:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=kheti_sahayak
DB_USER=postgres
DB_PASSWORD=your_actual_password_here
```

---

## 🚀 **Start Application**

```powershell
cd kheti_sahayak_spring_boot

# Set JAVA_HOME
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot"

# Set DB Password (use your actual password)
$env:DB_PASSWORD = "your_password"

# Start backend (skip tests for now)
./mvnw.cmd spring-boot:run -DskipTests
```

---

## 🐛 **Troubleshooting**

### **Error: "password authentication failed"**

**Solution:** Update the password in application.yml or set environment variable:
```powershell
$env:DB_PASSWORD = "YOUR_ACTUAL_POSTGRES_PASSWORD"
```

### **Error: "database does not exist"**

**Solution:** Create the database:
```sql
psql -U postgres
CREATE DATABASE kheti_sahayak;
\q
```

### **Error: "could not connect to server"**

**Solution:** Start PostgreSQL service:
```powershell
# Check if PostgreSQL is running
Get-Service -Name postgresql*

# Start PostgreSQL
net start postgresql-x64-14
```

---

## ✅ **Quick Test**

```powershell
# Test PostgreSQL connection
psql -U postgres -d kheti_sahayak -c "SELECT 1;"

# Should return: 1
```

---

**After PostgreSQL is setup, run:**
```powershell
./start-application.ps1
```

