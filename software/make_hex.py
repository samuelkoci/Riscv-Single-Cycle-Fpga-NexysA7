import struct

try:
    with open("coremark.bin", "rb") as f:
        bin_data = f.read()

    with open("memfile.dat", "w") as f:
        for i in range(0, len(bin_data), 4):
            chunk = bin_data[i:i+4]
            if len(chunk) < 4:
                chunk = chunk.ljust(4, b'\x00')
            # Lexojme 4 byte si Little Endian dhe i shkruajme si Hex
            val = struct.unpack("<I", chunk)[0]
            f.write(f"{val:08x}\n")
    print("Sukses! memfile.dat u gjenerua.")
except Exception as e:
    print(f"Gabim: {e}")