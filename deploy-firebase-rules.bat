@echo off
REM Firebase Deployment Script for Todo App
REM This script deploys Firestore and Storage rules to Firebase

echo ======================================
echo Firebase Rules Deployment Script
echo ======================================
echo.

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Firebase CLI is not installed.
    echo Please install it first:
    echo   npm install -g firebase-tools
    pause
    exit /b 1
)

echo.
echo Checking Firebase authentication...
firebase projects:list >nul 2>&1
if errorlevel 1 (
    echo ERROR: Not authenticated with Firebase.
    echo Running 'firebase login'...
    firebase login
)

echo.
echo.
echo Select deployment option:
echo 1. Deploy Firestore rules only
echo 2. Deploy Storage rules only
echo 3. Deploy all rules (Firestore + Storage)
echo 4. Deploy rules + indexes
echo 5. List current rules
echo.

set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" (
    echo.
    echo Deploying Firestore rules...
    firebase deploy --only firestore:rules
    echo Firestore rules deployed successfully!
) else if "%choice%"=="2" (
    echo.
    echo Deploying Storage rules...
    firebase deploy --only storage
    echo Storage rules deployed successfully!
) else if "%choice%"=="3" (
    echo.
    echo Deploying all rules...
    firebase deploy --only firestore:rules,storage
    echo All rules deployed successfully!
) else if "%choice%"=="4" (
    echo.
    echo Deploying rules and indexes...
    firebase deploy --only firestore
    echo Rules and indexes deployed successfully!
) else if "%choice%"=="5" (
    echo.
    echo Current Firestore rules configuration:
    firebase rules:list
    echo.
) else (
    echo Invalid choice. Exiting.
    exit /b 1
)

echo.
echo ======================================
echo Deployment Complete!
echo ======================================
pause
