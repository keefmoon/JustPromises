
xcodebuild \
	-project JustPromises.xcodeproj \
	-scheme JustPromises \
	-configuration Release \
	-destination "platform=iOS Simulator,name=iPhone Retina (4-inch 64-bit),OS=latest" \
	test


xcodebuild \
	-project JustPromises.xcodeproj \
	-scheme JustPromises \
	-configuration Release \
	-destination "platform=iOS Simulator,name=iPad Retina (64-bit),OS=latest" \
	test

