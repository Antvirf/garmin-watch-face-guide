SDK = /home/antti/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-7.3.1-2024-09-23-df7b5816a/bin
PK = /home/antti/dev/developer_key_newstuff

run:
	$(SDK)/connectiq &
	java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
		-jar $(SDK)/monkeybrains.jar \
		--output bin/garminwatchfaceguide.prg \
		--jungles /home/antti/dev/garmin-watch-face-guide/monkey.jungle \
		--private-key $(PK) \
		--device enduro3_sim \
		--warn \
		--typecheck 0
	$(SDK)/monkeydo bin/garminwatchfaceguide.prg enduro3


build:
	java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
		-jar $(SDK)/monkeybrains.jar \
		-output /home/antti/dev/garmin-watch-face-guide/bin/garmin-watch-face-guide.iq \
		--jungles /home/antti/dev/garmin-watch-face-guide/monkey.jungle \
		--private-key /home/antti/dev/developer_key_newstuff \
		-e \
		-r \
		--warn \
		--typecheck 0
