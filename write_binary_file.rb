data = bytearray([1, 2, 3, 4, 5, 6, 7, 8])
f = open('data.bin', 'wb')
f.write(data)
f.close()
