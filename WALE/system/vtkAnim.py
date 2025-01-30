#!/usr/bin/env python
import sys, os, re, string, shutil

# A reg exp that will only select OF's time directories
cregex=re.compile("^[-+]?[0-9]+[.]?[0-9]*([eE][-+]?[0-9]+)?$")

dirlist = []
count = 0

# Find out all time directories in the current directory
for dirs in os.listdir(os.curdir):
  if cregex.search(str(dirs)):
    dirlist.append(dirs)

# A function that will sort the string-typed directories as numbers
def alfa_num(x, y):
  if float(x) > float(y):
    return 1
  elif float(x) == float(y):
    return 0
  else:
    return -1

dirlist.sort(alfa_num)

if len(dirlist) == 0:
  print "No time-directories found!"
  sys.exit(1)

# In the first time directory, find out which .vtk files there are
files_in_timedirs =  os.listdir(os.path.join(os.curdir,dirlist[0]))
movie_objs = []
for obj in files_in_timedirs:
  if obj.endswith('.vtk'):
    fname, ext = os.path.splitext(obj)
    movie_objs.append(fname)

if len(movie_objs) == 0:
  print "No vtk-files found in first time-directory, " + str(os.path.join(os.curdir,dirlist[0]))
  sys.exit(1)

# Copy the .vtk files from the time directories to current dir and
# add a counter
for timedir in dirlist:
  count = count + 1
  for obj in movie_objs:
    old_filename = os.path.join(os.curdir,timedir,obj + '.vtk')
    if count >= 1000:
      new_filename = os.path.join(os.curdir,obj + "_" + str(count) + '.vtk')
    elif count >= 100:
      new_filename = os.path.join(os.curdir,obj + "_0" + str(count) + '.vtk')
    elif count >= 10:
      new_filename = os.path.join(os.curdir,obj + "_00" + str(count) + '.vtk')
    elif count >= 0:
      new_filename = os.path.join(os.curdir,obj + "_000" + str(count) + '.vtk')
    try:
      shutil.copy2(old_filename, new_filename)
    except:
      print "Cannot read file " + str(old_filename)
      sys.exit(1)
