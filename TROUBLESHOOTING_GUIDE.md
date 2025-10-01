# 🔧 Kheti Sahayak - Troubleshooting Guide

## ✅ **CURRENT STATUS**

**Frontend:** ✅ RUNNING on http://localhost:3001  
**Backend:** ⏳ Starting (may take 30-60 seconds)

---

## 🎯 **QUICK FIX - Application is Already Running!**

### **✅ Frontend is Available NOW:**

Open your browser and go to:
👉 **http://localhost:3001**

The Kheti Sahayak application interface should load immediately!

### **⏳ Backend is Starting:**

The Spring Boot backend takes 30-60 seconds to start. It will automatically connect when ready.

---

## 🚀 **EASIEST WAY TO START THE APP (Next Time)**

### **Option 1: Use the Startup Script (Recommended)**

```powershell
# Run this command (it sets JAVA_HOME and starts everything)
./start-application.ps1
```

This script:
- ✅ Automatically sets JAVA_HOME
- ✅ Starts backend in new window
- ✅ Starts frontend in new window
- ✅ Opens browser
- ✅ Checks status

### **Option 2: Manual Start (If you prefer)**

**Terminal 1 - Backend:**
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot"
cd kheti_sahayak_spring_boot
./mvnw spring-boot:run
```

**Terminal 2 - Frontend:**
```powershell
cd frontend
npm run dev
```

---

## 🐛 **COMMON ISSUES & SOLUTIONS**

### **Issue: "JAVA_HOME not found"**

**Solution:**
```powershell
# Set JAVA_HOME (this session only)
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot"

# Set permanently
[System.Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot', [System.EnvironmentVariableTarget]::User)

# Verify
echo $env:JAVA_HOME
java -version
```

### **Issue: "Port already in use"**

**Backend (Port 8080):**
```powershell
# Find what's using port 8080
netstat -ano | findstr :8080

# Kill the process
taskkill /PID <PID_NUMBER> /F
```

**Frontend (Port 3000/3001):**
```powershell
# Find what's using the port
netstat -ano | findstr :3001

# Kill the process
taskkill /PID <PID_NUMBER> /F
```

### **Issue: "Database connection failed"**

**Option 1: Install PostgreSQL** (Recommended for production)
```powershell
# Download from: https://www.postgresql.org/download/windows/
# Or use Chocolatey:
choco install postgresql

# Create database
createdb kheti_sahayak
```

**Option 2: Use H2 In-Memory Database** (Quick testing)

The application will automatically use H2 if PostgreSQL is not available.

### **Issue: "Redis connection failed"**

**Option 1: Install Redis** (Recommended)
```powershell
# Download from: https://github.com/microsoftarchive/redis/releases
# Or use Chocolatey:
choco install redis-64

# Start Redis
redis-server
```

**Option 2: Disable Redis**

The application will work without Redis (OTP will be stored in memory).

---

## 🔍 **CHECK APPLICATION STATUS**

### **Quick Status Check:**
```powershell
./check-app-status.ps1
```

This will show:
- ✅ Frontend status
- ✅ Backend status
- ✅ Quick access links

### **Manual Status Check:**

```powershell
# Check frontend
curl http://localhost:3001

# Check backend
curl http://localhost:8080/api/health

# Check Swagger
curl http://localhost:8080/api-docs
```

---

## 🌐 **ACCESS URLS (CURRENT)**

```
┌─────────────────────────────────────────────┐
│                                             │
│   🌾 KHETI SAHAYAK - ACCESS LINKS          │
│                                             │
│   ✅ Frontend:  http://localhost:3001      │
│      (Main application interface)          │
│                                             │
│   ⏳ Backend:   http://localhost:8080      │
│      (REST API - starting)                 │
│                                             │
│   ⏳ API Docs:  http://localhost:8080/api-docs│
│      (Swagger UI - will be ready soon)     │
│                                             │
└─────────────────────────────────────────────┘
```

**Frontend is READY RIGHT NOW!**  
**Backend will be ready in 30-60 seconds**

---

## ⚡ **QUICK TROUBLESHOOTING STEPS**

### **Step 1: Is Java Installed?**
```powershell
java -version
# Should show: openjdk version "17.0.16"
```

If not installed:
- Download from: https://adoptium.net/
- Or use: `choco install openjdk17`

### **Step 2: Is JAVA_HOME Set?**
```powershell
echo $env:JAVA_HOME
# Should show: C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot
```

If not set, run:
```powershell
./start-application.ps1
```

### **Step 3: Are Dependencies Installed?**

**Backend:**
```powershell
cd kheti_sahayak_spring_boot
./mvnw clean install
```

**Frontend:**
```powershell
cd frontend
npm install
```

### **Step 4: Check Ports Available?**
```powershell
# Check if ports are free
netstat -ano | findstr :8080
netstat -ano | findstr :3001
```

---

## 📝 **BACKEND STARTUP LOGS**

The backend window will show:
```
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v3.3.3)

...
Started KhetiSahayakApplication in X.XXX seconds
```

When you see "Started KhetiSahayakApplication", the backend is ready!

---

## 🎯 **WHAT TO DO NOW**

### **✅ Frontend is Ready:**
1. Open http://localhost:3001 (should already be open)
2. You'll see the Kheti Sahayak interface
3. You can browse the UI
4. Some features need backend to be connected

### **⏳ Waiting for Backend:**
1. Wait 30-60 seconds
2. Backend will show "Started KhetiSahayakApplication"
3. Then refresh your browser
4. All features will work!

### **🧪 Test Everything:**
1. Go to http://localhost:8080/api-docs (when backend is ready)
2. Test all 74+ API endpoints
3. Try authentication
4. Test new features

---

## 🔧 **ALTERNATIVE: DOCKER STARTUP (Easiest)**

If you have Docker installed:

```bash
# Start everything with Docker
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Access
# Frontend: http://localhost:3000
# Backend: http://localhost:8080
```

---

## 📞 **STILL HAVING ISSUES?**

### **Check These:**

1. **Java is installed:** `java -version`
2. **JAVA_HOME is set:** `echo $env:JAVA_HOME`
3. **Ports are free:** No other apps on 8080, 3001
4. **Dependencies installed:** `npm install` in frontend
5. **Maven works:** `./mvnw --version` in backend folder

### **Get Help:**

1. **Check backend logs:** Look at the Spring Boot startup window
2. **Check frontend logs:** Look at the Vite dev server window
3. **Run status check:** `./check-app-status.ps1`
4. **View documentation:** See `QUICKSTART_GUIDE.md`

---

## 🎉 **SUCCESS INDICATORS**

### **You'll know it's working when:**

✅ Frontend shows Kheti Sahayak dashboard  
✅ No connection errors in browser console  
✅ Backend health check returns OK  
✅ Swagger UI loads  
✅ API calls return data  

---

## 💡 **PRO TIP**

**Use the startup script for hassle-free launch:**
```powershell
./start-application.ps1
```

This handles everything automatically!

---

**🌾 Your application is starting! Frontend is ready now at http://localhost:3001! 🌾**

