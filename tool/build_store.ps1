# Builds the Google Play bundle with real ad units. Without PROD_ADS the
# release build shows Google's "Test Ad" creatives.
flutter build appbundle --release --dart-define=PROD_ADS=true
