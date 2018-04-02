size = 1024
data = bytearray([i % 256 for i in range(0, size)])
f = open('data-%s.bin' % size, 'wb')
f.write(data)
f.close()
