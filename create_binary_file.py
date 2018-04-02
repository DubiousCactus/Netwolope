size = 256
data = bytearray(range(0, size))
f = open('data-%s.bin' % size, 'wb')
f.write(data)
f.close()
