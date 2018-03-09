f = open('data.bin', 'rb')
data = bytearray(f.read())
f.close()
for i in data:
  print(i)
