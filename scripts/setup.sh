#!/bin/bash
# COMPLETE SETUP CHECK - Verify entire setup

echo "🧪 COMPLETE SETUP VERIFICATION"
echo "=============================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TOTAL_TESTS=6

echo ""

# Test 1: AWS CLI
echo "1️⃣ Testing AWS CLI..."
if command -v aws &> /dev/null; then
    echo -e "${GREEN}✅ AWS CLI installed${NC}"
    aws --version
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ AWS CLI not found${NC}"
    echo "   Install with:"
    echo "   curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
    echo "   unzip awscliv2.zip && sudo ./aws/install"
fi

echo ""

# Test 2: Terraform
echo "2️⃣ Testing Terraform..."
if command -v terraform &> /dev/null; then
    echo -e "${GREEN}✅ Terraform installed${NC}"
    terraform version
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ Terraform not found${NC}"
    echo "   Install with:"
    echo "   wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip"
    echo "   unzip terraform_1.6.6_linux_amd64.zip && sudo mv terraform /usr/local/bin/"
fi

echo ""

# Test 3: AWS Credentials
echo "3️⃣ Testing AWS Credentials..."
if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✅ AWS credentials configured${NC}"
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    REGION=$(aws configure get region)
    
    echo "   🆔 Account ID: $ACCOUNT_ID"
    echo "   👤 User: $USER_ARN"
    echo "   🌍 Region: ${REGION:-'not configured'}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    echo "   Configure with: aws configure"
    echo ""
    read -p "🔧 Configure now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "⚙️ Configuring AWS CLI..."
        aws configure
        echo "🔄 Retesting credentials..."
        if aws sts get-caller-identity &> /dev/null; then
            echo -e "${GREEN}✅ Credentials configured successfully!${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}❌ Configuration failed${NC}"
        fi
    fi
fi

echo ""

# Test 4: AWS Region
echo "4️⃣ Testing AWS Region..."
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    echo -e "${YELLOW}⚠️ No region configured${NC}"
    echo "🔧 Setting eu-west-1..."
    aws configure set region eu-west-1
    REGION="eu-west-1"
    echo -e "${GREEN}✅ Region configured: $REGION${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${GREEN}✅ Region configured: $REGION${NC}"
    # Test region accessibility
    if aws ec2 describe-regions --region $REGION &> /dev/null 2>&1; then
        echo -e "${GREEN}✅ Region accessible${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Region access error${NC}"
    fi
fi

echo ""

# Test 5: AWS Permissions
echo "5️⃣ Testing AWS Permissions..."
PERMISSION_OK=true

# Test S3
echo "   📦 Testing S3..."
if aws s3 ls &> /dev/null; then
    echo -e "${GREEN}   ✅ S3 access OK${NC}"
else
    echo -e "${RED}   ❌ S3 access denied${NC}"
    PERMISSION_OK=false
fi

# Test IAM
echo "   👤 Testing IAM..."
if aws iam get-user &> /dev/null; then
    echo -e "${GREEN}   ✅ IAM access OK${NC}"
else
    echo -e "${YELLOW}   ⚠️ IAM access limited${NC}"
fi

# Test Glue
echo "   🔗 Testing Glue..."
if aws glue get-databases &> /dev/null; then
    echo -e "${GREEN}   ✅ Glue access OK${NC}"
else
    echo -e "${YELLOW}   ⚠️ Glue access limited (normal for new account)${NC}"
fi

if $PERMISSION_OK; then
    ((TESTS_PASSED++))
fi

echo ""

# Test 6: Directory Structure
echo "6️⃣ Testing Directory Structure..."
if [ -d "terraform/modules" ] && [ -d "terraform/environments" ]; then
    echo -e "${GREEN}✅ Directory structure OK${NC}"
    echo "   📁 terraform/modules/ ✓"
    echo "   📁 terraform/environments/ ✓"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ Directory structure incomplete${NC}"
    echo "   Make sure you're in multitenant-data-lakehouse/"
    echo "   And have created: terraform/modules/ and terraform/environments/"
fi

echo ""
echo "================================================="
echo "📊 FINAL RESULTS"
echo "================================================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}/$TOTAL_TESTS"

if [ $TESTS_PASSED -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 SETUP COMPLETE! Everything works perfectly!${NC}"
    echo ""
    echo "📋 FINAL CONFIGURATION:"
    echo "   🆔 Account: $(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo 'N/A')"
    echo "   👤 User: $(aws sts get-caller-identity --query Arn --output text 2>/dev/null || echo 'N/A')"
    echo "   🌍 Region: $(aws configure get region || echo 'N/A')"
    echo "   📁 Directory: $(pwd)"
    echo ""
    echo -e "${GREEN}✅ READY FOR STEP 3: Terraform Backend Setup!${NC}"
elif [ $TESTS_PASSED -ge 4 ]; then
    echo -e "${YELLOW}⚠️ Setup almost complete - fix remaining issues${NC}"
    echo ""
    echo "🔧 NEXT ACTIONS:"
    echo "   → Complete AWS configuration if needed"
    echo "   → Verify IAM permissions"
    echo "   → Once everything OK, proceed with Step 3"
else
    echo -e "${RED}❌ Setup incomplete - fix main issues${NC}"
    echo ""
    echo "🔧 PRIORITIES:"
    echo "   1. Install AWS CLI and Terraform"
    echo "   2. Configure AWS credentials"
    echo "   3. Verify permissions"
    echo "   4. Re-run this script"
fi

echo ""
echo "🔄 To re-run this check: bash setup-check.sh"