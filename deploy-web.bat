@echo off
echo Building VetClick for web...
flutter build web --release
echo Deploying to Firebase...
firebase deploy --only hosting
echo Done!
pause
