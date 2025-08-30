# pip install pyusb

import usb.core
import usb.util

def toU32(x):
	return bytes([x % 256, (x >> 8) % 256, (x >> 16) % 256, (x >> 24) % 256])

def chopMessage(str):
	data = toU32(len(str)) + str.encode()
	strLen = len(data)
	
	result = []
	i = 0
	while i < strLen:
		end_pos = min(strLen, i + 64)
		result.append(data[i:end_pos])
		i = end_pos
	return result

# find our device
dev = usb.core.find(idVendor=0x0000, idProduct=0x0001)

# was it found?
if dev is None:
	raise ValueError('Device not found')

# get an endpoint instance
cfg = dev.get_active_configuration()
intf = cfg[(0, 0)]

outep = usb.util.find_descriptor(
	intf,
	# match the first OUT endpoint
	custom_match= \
		lambda e: \
			usb.util.endpoint_direction(e.bEndpointAddress) == \
			usb.util.ENDPOINT_OUT)

inep = usb.util.find_descriptor(
	intf,
	# match the first IN endpoint
	custom_match= \
		lambda e: \
			usb.util.endpoint_direction(e.bEndpointAddress) == \
		    usb.util.ENDPOINT_IN)

assert inep is not None
assert outep is not None

# message = "Hello, World! This message exceeds the buffer............................................."
message = "j(R1wzR*y[^GxWJ5B>L{-HLETRD"
# message = "Hello, World!"
message = ''.join([message for i in range(100)])
# print("send len: ", len(message))
print(message)

blocks = chopMessage(message)
for i in range(len(blocks)):
	block = blocks[i]
	print("sending: '", block, end="' ...", sep="")
	outep.write(block)
	print(" sent.")
	
	response = inep.read(64)
	response_str = ''.join([chr(x) for x in response])
	if (i + 1) == len(blocks):
		# last block sent, expect to receive hash
		if len(response) == 0:
			raise Exception("Device expected more data that was announced in the hashshake!")
		if len(response) != 32:
			raise Exception("Device reported an error: " + response_str)
		else:
			print("hash: " + response_str)
	else:
		# middle (or first) block, expect to receive 0 byte ack
		if len(response) != 0:
			raise Exception("Device reported an error: " + response_str)
