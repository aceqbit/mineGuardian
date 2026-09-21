# 🛡️ MineGuardian — Phase 1 Safety & Compliance Platform

MineGuardian is an offline-first, real-time mine safety and compliance platform designed for underground mining operations. It connects miners, shift supervisors, and safety officers to prevent incidents, enforce pre-shift safety verifications, and rapidly dispatch emergency alerts.

---

## 🚀 Key Phase 1 Deliverables

### 📱 Flutter Mobile Application (`mobile/`)
1. **Role-Based Authentication**:
   - Phone + 4-digit PIN authentication with secure JWT storage.
   - Quick one-tap role switcher for rapid demonstration (Miner vs Supervisor).
2. **Offline-First Daily Pre-Shift Checklist**:
   - Bilingual safety checklist (English & Hindi) covering PPE, Equipment, Gas Levels, and Physical Fitness.
   - GPS boundary tagging and shift window validation.
   - **Gamification**: +50 XP reward badge, streak progression tracking, and instant compliance modal.
   - Local SQLite queue ensures zero checklist drop-offs even deep underground without network coverage.
3. **Hazard Reporting with Multimodal Evidence**:
   - One-tap audio speech-to-text dictation for hands-free reporting.
   - Camera photo evidence capture.
   - Severity tags (*Critical, High, Medium, Low*) and zone tagging.
   - Immediate offline queue fallback with auto-sync when network reconnects.
4. **Offline 2D Evacuation Blueprint**:
   - Vector-rendered offline schematic with refuge chamber markers, air shafts, and active hazard warnings.
5. **Emergency SOS System**:
   - High-contrast visual pulse siren with emergency contact directory and instant broadcast telemetry.
6. **Supervisor Real-Time Portal**:
   - Live compliance KPI cards (Compliance Rate, Unverified Workers, Active Hazards, Roster Count).
   - Dynamic Shift Window management (Open & Close shift windows).
   - Worker compliance verification and flagging queue.
   - Real-time hazard review and corrective action resolution.

---

### ⚙️ Node.js + Express Backend (`backend/`)
1. **REST APIs & WebSocket Gateway**:
   - `/api/auth`: Phone/PIN login, token issuance, FCM token management.
   - `/api/checklist`: Question retrieval, shift checklist submissions, and history.
   - `/api/hazard` & `/api/hazards`: Real-time hazard submissions and status resolutions.
   - `/api/supervisor`: Dashboard aggregations, shift opening/closing, and worker verification.
   - `/api/sync`: Batch offline reconciliation.
2. **Real-Time WebSockets (`socket.io`)**:
   - Room-based zone subscriptions (`hazard:new`, `shift:update`, `checklist:submitted`).
3. **Automated Background Cron Service (`node-cron`)**:
   - Auto-flags unverified workers at shift close to maintain 100% compliance records while protecting worker scores.
4. **Twilio SMS Alert Integration**:
   - Automated SMS dispatches to supervisors on critical hazard reports.

---

## 📂 Project Architecture

```
mineGuardian/
├── backend/
│   ├── src/
│   │   ├── config/          # Database (MongoDB), Firebase, Twilio
│   │   ├── middleware/      # JWT auth and role-based access control
│   │   ├── models/          # User, Shift, Checklist, HazardReport, AuditLog
│   │   ├── routes/          # Express API route controllers
│   │   ├── services/        # Sockets, cron worker, Twilio alerts
│   │   └── index.js         # Express + Socket.io main server
│   ├── package.json
│   └── .env.example
├── mobile/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/   # App constants, URLs, XP configs
│   │   │   ├── database/    # SQLite offline helper
│   │   │   ├── network/     # ApiClient & SocketClient
│   │   │   └── theme/       # Industrial Dark Theme (Outfit font, Amber/Orange palette)
│   │   ├── features/
│   │   │   ├── auth/        # UserModel, AuthBloc, SplashScreen, LoginScreen
│   │   │   ├── miner/       # ChecklistBloc, HazardBloc, Home, Checklist, Hazard, SOS, Evacuation Map
│   │   │   ├── supervisor/  # SupervisorBloc, Dashboard, Shift Mgmt, Hazard Review
│   │   │   └── shared/      # LocationService, VoiceService, SyncService, Custom widgets
│   │   └── main.dart        # App root with MultiBlocProvider
│   └── pubspec.yaml
└── README.md
```

---

## 🛠️ Quick Start Instructions

### 1. Run the Backend API
```bash
cd backend
npm install
npm run dev
# Server will start on http://localhost:3000
```

### 2. Run the Flutter Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

---

## ⚡ Demo Credentials
- **Miner Role**: Phone: `+919876543210` | PIN: `1234`
- **Supervisor Role**: Phone: `+919876543211` | PIN: `1234`
*(Or simply tap the Quick Demo Access buttons on the Login Screen)*
