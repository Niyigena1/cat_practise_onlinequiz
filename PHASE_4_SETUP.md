# Phase 4: Test - Setup Guide

## ✅ What's Been Implemented

### 1. **Unit Tests** (`__tests__/unit.test.js`)
- ✅ Health check endpoint
- ✅ Static pages (/, /quiz, /admin)
- ✅ Questions API (GET, POST, PUT, DELETE)
- ✅ Error handling
- **27 tests total - ALL PASSING**

### 2. **Integration Tests** (`__tests__/integration.test.js`)
- ✅ Complete quiz workflow (add → retrieve → update → delete)
- ✅ Multiple questions scenario
- ✅ Data persistence validation
- ✅ Concurrent operations handling
- ✅ API response format validation

### 3. **CI Pipeline Enhancements**
- ✅ Test coverage reporting
- ✅ Test result artifacts upload
- ✅ Test report publishing (dorny/test-reporter)
- ✅ Coverage upload to Codecov
- ✅ Slack notifications on pipeline status

---

## ⚙️ WHAT YOU NEED TO CONFIGURE

### **1. Slack Webhook (REQUIRED for notifications)**

To enable Slack notifications on every pipeline run, you need to:

#### Step 1: Create Slack App
1. Go to https://api.slack.com/apps
2. Click "Create New App"
3. Choose "From scratch"
4. Name: `Class_Quiz_CI`
5. Select your Slack workspace

#### Step 2: Enable Incoming Webhooks
1. In your app settings, go to **Incoming Webhooks**
2. Click "Add New Webhook to Workspace"
3. Select the channel where you want notifications (e.g., `#deployments` or `#general`)
4. Click "Allow"
5. Copy the **Webhook URL** (looks like: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX`)

#### Step 3: Add Secret to GitHub
1. Go to your repo: https://github.com/TWAHIRWAFAB/Class_Quiz
2. Go to **Settings → Secrets and variables → Actions**
3. Click **New repository secret**
4. Name: `SLACK_WEBHOOK_URL`
5. Paste the webhook URL
6. Click **Add secret**

### **2. Codecov Token (Optional but recommended)**

For better test coverage tracking:

1. Go to https://codecov.io
2. Sign in with GitHub
3. Select your repo `Class_Quiz`
4. Copy the **Repository Token**
5. Add it to GitHub Secrets as `CODECOV_TOKEN` (same process as above)

### **3. Kubernetes Secrets (Required for deployment)**

The deployment job needs:
- `KUBECONFIG`: Your Kubernetes config file contents

Add this to GitHub Secrets as a base64-encoded secret.

### **4. Email Notifications (Alternative to Slack)**

If you prefer email notifications instead of Slack, you can use GitHub's built-in email notifications:
- Go to repo **Settings → Notifications**
- Enable "Email notifications for pushes"

---

## 📊 HOW TO TEST IT

### Local Testing
```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific test file
npm test __tests__/unit.test.js

# Run in watch mode
npm test -- --watch
```

### GitHub Actions Testing
1. Commit any change to `main` or `develop`
2. Go to https://github.com/TWAHIRWAFAB/Class_Quiz/actions
3. Watch the workflow run through:
   - ✅ Lint
   - ✅ Test
   - ✅ Build
   - ✅ Security
   - ✅ **Notify** (sends Slack message)
   - ✅ Deploy (if all above pass)

---

## 📝 Test Coverage

Current test coverage:
- **Unit Tests**: 17 tests (API endpoints, error handling)
- **Integration Tests**: 10 tests (workflows, persistence, concurrency)
- **Existing Tests**: Index tests
- **Total**: 27 passing tests

### Coverage Metrics (from jest.config.js)
```
Branches:  70%+
Functions: 70%+
Lines:     70%+
Statements: 70%+
```

---

## 🔔 Slack Notification Format

Once configured, you'll receive messages like:

```
CI/CD Pipeline Report ✅ SUCCESS
Repo: TWAHIRWAFAB/Class_Quiz
Branch: main
Commit: abc123def456...
Author: TWAHIRWAFAB

Lint:     ✅
Test:     ✅
Build:    ✅
Security: ✅

[View Workflow Button]
```

On failures:
```
CI/CD Pipeline Report ❌ FAILED
... (same format)

Lint:     ❌
Test:     ✅
Build:    ❌
Security: ✅
```

---

## ⚡ Quick Setup Checklist

- [ ] Create Slack App at https://api.slack.com/apps
- [ ] Enable Incoming Webhooks
- [ ] Copy Webhook URL
- [ ] Add `SLACK_WEBHOOK_URL` secret to GitHub
- [ ] (Optional) Add `CODECOV_TOKEN` for coverage tracking
- [ ] Push a change to trigger first workflow run
- [ ] Check Slack for notification
- [ ] Verify all tests pass on GitHub Actions

---

## 📝 Files Modified in Phase 4

1. `__tests__/unit.test.js` - New unit tests
2. `__tests__/integration.test.js` - New integration tests
3. `.github/workflows/ci-cd.yml` - Enhanced with test reporting + Slack notifications

**Commit**: `da77c65`
**Tests Status**: ✅ 27/27 passing

---

## 🚀 Next Steps After Setup

1. Create Slack webhook (5 min)
2. Add GitHub secret (2 min)
3. Push a test commit to trigger workflow
4. Verify notifications work in Slack
5. Done! Pipeline is fully functional

Need help with Slack setup? See: https://docs.slack.com/messaging/webhooks
