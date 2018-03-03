# Screen-sharing-iOS
This project implements a screen sharing server in an iOS app extension using ReplayKit 2 framework. 

# Description
Apple introduced ReplayKit 2 framework in WWDC 2017 which is a powerful tool to get access to the frames from an iPhone/iPad screen in real time using an app extension. The challenge is to develop a light weight protocol for live streaming the frames captured from the screen. The current prototype uses hardware enabled JPEG encoding provided by VideoToolbox framework to encode and send the frames over UDP to multiple devices connected using iPhone hotspot.

# Pending work
H264 encoding and adaptive streaming based on the network conditions

