# Android Deployment Guide

To enable automated builds on GitHub, you need to generate a digital signature (Keystore), encode it, and save it as Secrets in your GitHub repository.

## 1. Generate Upload Keystore
Run the following command in your terminal (if you have Java installed) or use Android Studio.

**Terminal Command:**
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*   Set a password when prompted (e.g., `MyStrongPassword123`).
*   Remember the **Alias** (`upload`) and **Password**.
*   This creates a file named `upload-keystore.jks`.

## 2. Encode Keystore to Base64
GitHub Secrets cannot store files directly, so we convert the file to a text string.

**Mac/Linux:**
```bash
base64 -i upload-keystore.jks -o keystore_base64.txt
```
Copy the contents of `keystore_base64.txt`.

## 3. Configure GitHub Secrets
Go to your GitHub Repository -> **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret**.

Add the following 4 secrets:

| Name | Value |
|------|-------|
| `ANDROID_KEYSTORE_BASE64` | The long text string you copied in Step 2. |
| `KEY_STORE_PASSWORD` | The password you set in Step 1. |
| `KEY_PASSWORD` | The password you set in Step 1 (usually same as store password). |
| `KEY_ALIAS` | `upload` (or whatever alias you used). |

## 4. Trigger Build
1.  Push your code to `main`.
2.  Go to the **Actions** tab on your GitHub repository.
3.  You will see "Android Release Build" running.
4.  Once completed, click on the run and download the `app-release-bundle` artifact.
5.  Upload this `.aab` file to the [Google Play Console](https://play.google.com/console).

## 5. Automated Publishing Setup (Opt-in)
To have GitHub automatically upload the `.aab` to the Play Store Internal Track:

### A. Create Service Account
1.  Go to **Google Cloud Console** > **IAM & Admin** > **Service Accounts**.
2.  Click **Create Service Account**.
3.  Name it (e.g., `github-actions-deploy`).
4.  Grant Role: **Service Account User**.
5.  Click **Done**.
6.  Click on the newly created email > **Keys** > **Add Key** > **Create new key** > **JSON**.
7.  Save the `.json` file to your computer.

### B. Grant Play Console Access
1.  Go to **Google Play Console** > **Users and permissions** > **Invite new users**.
2.  Enter the service account email (from step A).
3.  Grant permissions: **Admin (all permissions)** or specifically **Releases > Release to production, exclude devices, and use Play App Signing**.
4.  Click **Invite User**.

### C. Add Secret to GitHub
1.  Open the `.json` key file you downloaded in a text editor.
2.  Copy the entire content.
3.  Go to GitHub Secrets.
4.  Create new secret: `PLAY_SERVICE_ACCOUNT_JSON` with the content.

