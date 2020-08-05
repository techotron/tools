function fix-pulse-audio() {
	rm -r ~/.config/pulse
	pulseaudio -k
}
