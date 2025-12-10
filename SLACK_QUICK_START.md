# Quick Setup: Slack Webhook for GitHub Actions

## You Have Your Token ✅

Great! You have your Slack webhook token. Now let's add it to GitHub so your pipeline can send notifications.

---

## 3 Simple Steps

### Step 1: Open GitHub Secrets Page
```
Go to:
https://github.com/Niyigena1/cat_practise_onlinequiz/settings/secrets/actions
```

### Step 2: Add New Secret
1. Click **"New repository secret"** button
2. Fill in:
   - **Name:** `SLACK_WEBHOOK_URL`
   - **Value:** Paste your webhook token here
3. Click **"Add secret"**

### Step 3: Push Code to Trigger
```bash
cd /home/vboxuser/Documents/onlineQuiz-API

# Make a small change
echo "# Updated at $(date)" >> README.md

# Commit and push
git add README.md
git commit -m "test: Enable Slack notifications"
git push origin main
```

---

## What Happens Next

```
Your push → GitHub Actions starts → Runs tests & builds Docker image
   ↓
Pipeline completes → Sends Slack message to your channel
   ↓
You see: "✅ Pipeline SUCCESS - Docker image pushed!"
```

---

## Expected Slack Message

```
CI/CD Pipeline Report ✅ SUCCESS

Repo: Niyigena1/cat_practise_onlinequiz
Branch: main
Author: Niyigena1

Lint:     ✅
Test:     ✅
Build:    ✅  (Docker pushed!)
Security: ✅

[View Workflow]
```

---

## Verify It Worked

1. **GitHub:** https://github.com/Niyigena1/cat_practise_onlinequiz/actions
   - Should show green checkmarks for all jobs
   
2. **Docker Hub:** https://hub.docker.com/repository/docker/niyigena1/cat-practise-onlinequiz
   - Should show new image tags

3. **Slack:**
   - Should see notification in your channel

---

## All Secrets Checklist

```
✅ DOCKER_USERNAME = niyigena1
✅ DOCKER_PASSWORD = Your Docker Hub PAT
✅ SLACK_WEBHOOK_URL = Your webhook (ADD NOW!)
✅ EMAIL_USERNAME = Email address
✅ EMAIL_PASSWORD = Email password
✅ SLACK_WEBHOOK_URL = Slack webhook
```

---

## Done! 🎉

Your complete automation is now:
- ✅ Code quality (Lint)
- ✅ Testing (Jest - 27 tests)
- ✅ Docker build & push
- ✅ Security scanning
- ✅ Slack notifications
- ✅ Kubernetes deployment

Everything runs automatically when you push code!
