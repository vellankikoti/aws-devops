# AWS Account Setup - Detailed Checklist

## Prerequisites Verification

Before starting, verify you have:
- [ ] Valid email address (you check regularly)
- [ ] Credit/debit card for AWS verification
- [ ] Phone for SMS/voice verification
- [ ] Password manager (recommended: Bitwarden, 1Password, LastPass)
- [ ] Authenticator app (Google Authenticator or Authy)

## Step 1: Create AWS Account

1. Navigate to: https://aws.amazon.com/free
2. Click **"Create a Free Account"**
3. Enter email address (use a real one - AWS sends important alerts here)
4. Choose **AWS account name**: `your-name-learning` or similar
5. Click **"Verify email address"**
6. Check email, copy verification code
7. Enter verification code
8. Create **root password**:
   - Minimum 8 characters
   - Use a strong, unique password
   - Store in password manager
   - Format example: `SockShop2025!AWS@Root`

## Step 2: Add Payment Information

AWS requires a payment method even for Free Tier. You won't be charged if you stay within limits.

1. Enter contact information:
   - Full name (as on card)
   - Phone number
   - Country
   - Address
2. Enter payment information:
   - Credit or debit card number
   - Expiration date
   - CVV
3. AWS will authorize $1 on your card (refunded immediately)
4. Click **"Verify and Continue"**

**Note**: You'll see a pending $1 charge. It disappears in 3-5 days.

## Step 3: Confirm Identity

AWS verifies you're a real person:

1. Choose verification method:
   - **Text message (SMS)** - recommended
   - Voice call
2. Enter phone number (must be able to receive calls/texts)
3. Enter security check characters
4. Click **"Send SMS"** or **"Call me now"**
5. Enter the 4-digit verification code
6. Click **"Verify Code"**

**Troubleshooting**:
- If SMS doesn't arrive in 2 minutes, try voice call
- If verification fails, try a different browser
- VoIP numbers (Google Voice) sometimes don't work

## Step 4: Select Support Plan

1. Choose **Basic support - Free**
2. Click **"Complete sign up"**

You'll see a confirmation page. Your AWS account is now active!

## Step 5: Initial Login as Root

1. Go to: https://console.aws.amazon.com/
2. Click **"Sign in to the Console"**
3. Choose **"Root user"**
4. Enter your root email address
5. Click **"Next"**
6. Enter your root password
7. Click **"Sign in"**

You're now in the AWS Management Console as the root user.

**IMPORTANT**: This is the last time you'll log in as root for daily work. We're about to secure this account and create a safer user.

## Step 6: Enable MFA on Root Account (CRITICAL)

### Why This Matters

Root account has unlimited power. If someone gets your password, they can:
- Launch thousands of expensive instances
- Delete all your data
- Rack up a massive bill

MFA adds a second factor (your phone) so a stolen password alone isn't enough.

### Enable MFA

1. In AWS Console, click your **account name** (top right)
2. Click **"Security credentials"**
3. Scroll to **"Multi-factor authentication (MFA)"**
4. Click **"Assign MFA device"**
5. Device name: `root-mfa-device`
6. MFA device type: **Authenticator app** (recommended)
7. Click **"Next"**

### Set Up Authenticator App

8. On your phone, open authenticator app:
   - **Google Authenticator** (iOS/Android)
   - **Authy** (iOS/Android)
   - **Microsoft Authenticator** (iOS/Android)

9. In the app, add a new account:
   - Scan the QR code shown in AWS Console
   - OR manually enter the secret key

10. The app will show a 6-digit code that changes every 30 seconds

11. In AWS Console:
    - Enter the current 6-digit code in "MFA code 1"
    - Wait 30 seconds for the code to change
    - Enter the new code in "MFA code 2"

12. Click **"Add MFA"**

You'll see: "You have successfully assigned virtual MFA"

### Test MFA

1. Sign out of AWS Console
2. Sign back in as root user
3. After entering password, you'll be prompted for MFA code
4. Open authenticator app
5. Enter the 6-digit code
6. You're in

**If this works, your root account is now protected by MFA.** ✅

### Save Recovery Information

**IMPORTANT**: Write these down and store safely:
- Root email: _________________
- Root password: (in password manager)
- MFA device: (your phone with authenticator app)
- Account ID (12 digits): _________________ (found in top right of console)

If you lose access to your MFA device, AWS account recovery is painful. Keep this info safe.

## Step 7: Create IAM Admin User (Your Daily Driver)

Now we create the user you'll actually use every day.

### Why Not Use Root?

- Root has unlimited power (dangerous)
- Root can't have permissions restrictions
- Security best practice: root only for account-level tasks
- IAM users can have restricted permissions

### Create the User

1. In AWS Console search bar, type **"IAM"**
2. Click **"IAM"** (Identity and Access Management)
3. In left sidebar, click **"Users"**
4. Click **"Create user"**

5. User details:
   - User name: `devops-admin` (or your name, e.g., `koti-admin`)
   - Check ✅ **"Provide user access to AWS Management Console"**
   - Click **"I want to create an IAM user"**

6. Console password:
   - Choose **"Custom password"**
   - Enter a strong password (different from root!)
   - Store in password manager
   - Uncheck **"Users must create a new password at next sign-in"**
   - Click **"Next"**

7. Permissions options:
   - Choose **"Attach policies directly"**
   - In the filter box, search: `AdministratorAccess`
   - Check ✅ **"AdministratorAccess"**
   - Click **"Next"**

8. Review and create:
   - Review the settings
   - Click **"Create user"**

### Save Sign-In Details

You'll see a success page with important information:

**SAVE THESE IMMEDIATELY:**
- Console sign-in URL: `https://123456789012.signin.aws.amazon.com/console`
  - (Your 12-digit account ID will be different)
- User name: `devops-admin`
- Console password: (the one you set)

**Action**: Bookmark the sign-in URL. This is YOUR login page.

### Download Credentials (Optional)

Click **"Download .csv file"** - this contains:
- User name
- Console sign-in URL
- Access key ID (if created)
- Secret access key (if created)

Store this file securely.

## Step 8: Test IAM User Login

**IMPORTANT**: Before continuing, test that you can log in as your IAM user.

1. Sign out of the AWS Console (you're currently logged in as root)
2. Go to the IAM user sign-in URL you saved:
   - `https://123456789012.signin.aws.amazon.com/console`
3. Account ID should be pre-filled (if not, enter your 12-digit account ID)
4. IAM user name: `devops-admin`
5. Password: (the password you set for this user)
6. Click **"Sign in"**

You should be in the AWS Console, but now as `devops-admin` instead of root.

**Verify**:
- Top right should show: `devops-admin @ your-account-name`
- You should be able to access services like EC2, VPC, RDS

## Step 9: Enable MFA on IAM User (Recommended)

Secure your daily-use account too:

1. In AWS Console (logged in as devops-admin), click your username (top right)
2. Click **"Security credentials"**
3. Scroll to **"Multi-factor authentication (MFA)"**
4. Click **"Assign MFA device"**
5. Device name: `devops-admin-mfa`
6. Choose **"Authenticator app"**
7. Click **"Next"**
8. Scan QR code with your authenticator app (same app as before)
9. Enter two consecutive MFA codes
10. Click **"Add MFA"**

Now your IAM user also requires MFA for login.

## Step 10: Create Access Keys for AWS CLI

We need programmatic access (API/CLI) for automation and terminal commands.

1. Still in **"Security credentials"** page
2. Scroll to **"Access keys"**
3. Click **"Create access key"**
4. Use case: **"Command Line Interface (CLI)"**
5. Check ✅ the confirmation box: "I understand the above recommendation..."
6. Click **"Next"**
7. Description tag: `devops-admin-cli-key`
8. Click **"Create access key"**

### Save Your Access Keys

You'll see:
- Access key ID: `AKIAIOSFODNN7EXAMPLE` (yours will be different)
- Secret access key: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` (yours will be different)

**CRITICAL**: This is the ONLY time you'll see the secret access key!

**Actions**:
1. Click **"Download .csv file"** and save it securely
2. Copy both keys to your password manager
3. **Never commit these keys to git**
4. **Never share these keys**
5. If leaked, delete and create new ones immediately

Click **"Done"**

## Step 11: Install and Configure AWS CLI

### Install AWS CLI

**macOS**:
```bash
# If you have Homebrew installed
brew install awscli

# Verify installation
aws --version
# Should show: aws-cli/2.x.x Python/3.x.x Darwin/...
```

**Linux (Ubuntu/Debian)**:
```bash
# Download the installer
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Install unzip if needed
sudo apt install unzip

# Unzip the installer
unzip awscliv2.zip

# Run the installer
sudo ./aws/install

# Verify installation
aws --version
# Should show: aws-cli/2.x.x Python/3.x.x Linux/...
```

**Linux (Amazon Linux/CentOS/RHEL)**:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo yum install unzip
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

**Windows (WSL - Windows Subsystem for Linux)**:
Same as Linux instructions above.

**Windows (Native)**:
1. Download the installer: https://awscli.amazonaws.com/AWSCLIV2.msi
2. Run the installer
3. Open Command Prompt or PowerShell
4. Verify: `aws --version`

### Configure AWS CLI

Now we connect the CLI to your AWS account:

```bash
aws configure
```

You'll be prompted for:

**AWS Access Key ID**:
```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
```
Paste your access key ID from Step 10.

**AWS Secret Access Key**:
```
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```
Paste your secret access key from Step 10.

**Default region name**:
```
Default region name [None]: us-east-1
```
Use `us-east-1` (Virginia) - it has the most services and best Free Tier coverage.

Alternatives:
- `us-west-2` (Oregon)
- `eu-west-1` (Ireland)
- `ap-south-1` (Mumbai)

Choose one close to you geographically for lower latency.

**Default output format**:
```
Default output format [None]: json
```
Options: `json`, `yaml`, `text`, `table`

Use `json` (most common and parseable).

### Verify AWS CLI Configuration

Test that everything works:

```bash
# Check your identity
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/devops-admin"
}
```

If you see your account number and user ARN, **you're successfully configured!** ✅

### Troubleshooting

**Error: "Unable to locate credentials"**
- Run `aws configure` again
- Make sure you copied the access keys correctly
- Check `~/.aws/credentials` file exists

**Error: "The security token included in the request is invalid"**
- Your access keys might be incorrect
- The keys might have been deleted in AWS Console
- Create new access keys

**Error: "Access Denied"**
- Your IAM user might not have the right permissions
- Verify AdministratorAccess policy is attached

## Step 12: Set Up Billing Alerts (CRITICAL)

This is non-negotiable. Set this up NOW before launching any resources.

### Enable Billing Alerts

1. In AWS Console, click your **account name** (top right)
2. Click **"Billing and Cost Management"**
3. In left sidebar, click **"Billing preferences"**
4. Under **"Alert preferences"**, check these boxes:
   - ✅ **Receive PDF Invoice By Email**
   - ✅ **Receive Free Tier Usage Alerts**
   - ✅ **Receive CloudWatch Billing Alerts**

5. Enter your email address in **"Email address for invoice delivery"**
6. Click **"Save preferences"**

### Create a Zero Spend Budget

This will alert you if you spend even $0.01.

1. In **Billing and Cost Management**, click **"Budgets"** in left sidebar
2. Click **"Create budget"**
3. Select **"Use a template (simplified)"**
4. Template: **"Zero spend budget"**
5. Budget name: `free-tier-zero-spend`
6. Email recipients: Enter your email
7. Click **"Create budget"**

**What this does**:
- Alerts you immediately if any charges occur
- Helps catch mistakes early (like leaving instances running)
- Free to set up and use

### Create a Monthly Cost Budget (Optional)

If you plan to spend a small amount (e.g., for ALB):

1. Create another budget
2. Choose **"Monthly cost budget"**
3. Budget name: `monthly-learning-budget`
4. Budgeted amount: `$10` (adjust as needed)
5. Email recipients: Your email
6. Alert threshold: `80%` (alert when you hit $8)
7. Click **"Create budget"**

### Enable Cost Explorer (Optional)

Free tool to visualize spending:

1. In **Billing and Cost Management**, click **"Cost Explorer"**
2. Click **"Enable Cost Explorer"**
3. Wait 24 hours for data to populate

After 24 hours, you can see daily costs broken down by service.

## Step 13: Enable AWS Free Tier Usage Alerts

Separate from billing alerts, AWS can warn you when you're approaching Free Tier limits.

1. **Billing and Cost Management** → **"Billing preferences"**
2. Verify ✅ **"Receive Free Tier Usage Alerts"** is checked
3. Email should be filled in
4. Click **"Save preferences"** if you made changes

### Check Free Tier Usage

1. **Billing and Cost Management** → **"Free Tier"**
2. You'll see a table of services with:
   - Service name (e.g., "Amazon EC2 t2.micro")
   - Usage limit (e.g., "750 Hours per month")
   - Current usage (e.g., "0 Hours")
   - Percentage used (e.g., "0%")
   - Forecast (predicted usage by month end)

Check this page daily for the first week of learning.

## Step 14: Set Up Cost Allocation Tags (Optional but Useful)

Tags help you track costs by project.

1. **Billing and Cost Management** → **"Cost allocation tags"**
2. Click **"Activate"** for these tags:
   - `Name`
   - `Project`
   - `Environment`
   - `Owner`

When you tag resources with these keys, you can filter costs by tag in Cost Explorer.

We'll tag all our resources with `Project: SockShop` today.

## Step 15: Security Checklist

Before proceeding, verify:

- [ ] Root account has MFA enabled
- [ ] Root password is stored securely (password manager)
- [ ] IAM admin user created
- [ ] IAM admin user has AdministratorAccess policy
- [ ] IAM admin user has MFA enabled (recommended)
- [ ] AWS CLI installed and configured
- [ ] `aws sts get-caller-identity` works
- [ ] Access keys are saved securely
- [ ] Access keys are NOT committed to any git repository
- [ ] Billing alerts enabled
- [ ] Zero spend budget created
- [ ] Free Tier usage alerts enabled
- [ ] You can log in as IAM user (not root)

If all boxes are checked, you're ready for the next step! ✅

## Common Issues and Solutions

### Issue: "Your account is being verified"

**Symptom**: Can't launch EC2 instances or other resources. Console shows "Your account is being verified."

**Solution**:
- AWS is verifying your identity (can take 2-24 hours)
- Check your email for verification requests
- If it takes longer than 24 hours, contact AWS Support

### Issue: MFA device lost or broken

**Symptom**: Can't log in because you don't have access to MFA codes.

**Solution**:
1. On login page, click "Troubleshoot MFA"
2. Follow account recovery process (requires email and phone verification)
3. Future prevention: Register multiple MFA devices or save backup codes

### Issue: Forgot IAM user password

**Symptom**: Can't log in as IAM user.

**Solution**:
1. Log in as root user
2. Go to IAM → Users → Select your user
3. Security credentials tab → Console password → Manage
4. Reset password

### Issue: Access keys not working

**Symptom**: `aws` commands fail with authentication errors.

**Solution**:
1. Check `~/.aws/credentials` file:
   ```bash
   cat ~/.aws/credentials
   ```
2. Verify the keys match what's in AWS Console
3. If in doubt, delete the keys and create new ones

### Issue: Hit Free Tier limits

**Symptom**: Getting charged despite using Free Tier services.

**Solution**:
- Check **Billing → Free Tier** to see what exceeded limits
- Common culprits:
  - Running instances for more than 750 hours/month
  - Using non-Free Tier instance types (e.g., t3.small instead of t2.micro)
  - Data transfer out exceeding 15GB/month
  - Multiple EBS snapshots
- Stop or delete unused resources

## Next Steps

Account setup is complete! You now have:
- ✅ Secure AWS account with MFA
- ✅ IAM admin user for daily work
- ✅ AWS CLI configured
- ✅ Billing alerts and cost monitoring
- ✅ Understanding of AWS Free Tier

**Next**: [02-vpc-setup.md](./02-vpc-setup.md) - Create your VPC and networking infrastructure

---

**Time spent**: ~45-60 minutes (including verification waits)
**Cost so far**: $0
**Concepts learned**: AWS account structure, IAM, security best practices, billing management
