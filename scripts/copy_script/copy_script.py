import sys
import os

if os.path.exists("copy_image.sh"):
  os.remove("copy_image.sh")
else:
  print("The file does not exist")


_folder_path = sys.argv[1]
_folder_path = _folder_path.rstrip('\n')
print("Folder path =>", _folder_path)
try:
    with open('copy_image.sh', 'a') as f:
        f.write('#!/bin/bash\n')
        _myfile = open("file_path.txt", "r")
        for line in _myfile:
            line = line.rstrip()
            line = line.rstrip(',')
            line = line.rstrip('\"')
            line = line.lstrip('\"')
            command = "cp " + line + ' ' + _folder_path + '/.' + '\n'
            print(command)
            f.write(command)
except FileNotFoundError:
    print("The directory does not exist")   
_myfile.close()   