#!/bin/bash

# Firebase Deployment Script for Todo App
# This script deploys Firestore and Storage rules to Firebase

echo "======================================"
echo "Firebase Rules Deployment Script"
echo "======================================"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "ERROR: Firebase CLI is not installed."
    echo "Please install it first:"
    echo "  npm install -g firebase-tools"
    exit 1
fi

echo "Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "ERROR: Not authenticated with Firebase."
    echo "Running 'firebase login'..."
    firebase login
fi

echo ""
echo ""
echo "Select deployment option:"
echo "1. Deploy Firestore rules only"
echo "2. Deploy Storage rules only"
echo "3. Deploy all rules (Firestore + Storage)"
echo "4. Deploy rules + indexes"
echo "5. List current rules"
echo ""

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo ""
        echo "Deploying Firestore rules..."
        firebase deploy --only firestore:rules
        echo "Firestore rules deployed successfully!"
        ;;
    2)
        echo ""
        echo "Deploying Storage rules..."
        firebase deploy --only storage
        echo "Storage rules deployed successfully!"
        ;;
    3)
        echo ""
        echo "Deploying all rules..."
        firebase deploy --only firestore:rules,storage
        echo "All rules deployed successfully!"
        ;;
    4)
        echo ""
        echo "Deploying rules and indexes..."
        firebase deploy --only firestore
        echo "Rules and indexes deployed successfully!"
        ;;
    5)
        echo ""
        echo "Current Firestore rules configuration:"
        firebase rules:list
        echo ""
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
