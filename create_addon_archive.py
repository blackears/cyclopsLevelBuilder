#!/usr/bin/env python

# MIT License
#
# Copyright (c) 2023 Mark McKay
# This file is for packaging Godot addons for various projects (https://github.com/blackears).
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os
import shutil
import sys
import getopt
import platform

projectName = 'cyclops_level_builder'
version="_1_0_3"
extensions = [".gd", ".tres", ".tscn", ".gdshader", ".gdshaderinc", ".glsl", ".cfg", ".txt", ".md", ".glb", ".gltf", ".jpg", ".jpeg", ".png", ".exr", ".svg", ".bin", ".ttf", ".otf"]


def copy_files_with_suffix(source_dir, dest_dir, suffixes):
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if any(file.endswith(suffix) for suffix in suffixes):
                source_path = os.path.join(root, file)
                dest_path = os.path.join(dest_dir, os.path.relpath(source_path, source_dir))
                os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                shutil.copy2(source_path, dest_path)

def make():
    
    #Delete any existing build directory
    if os.path.exists('build'):
        shutil.rmtree('build')

    copy_files_with_suffix("godot/addons/" + projectName + "/", "build/addons/" + projectName + "/", extensions);

    
    #Build addon zip file
    if not os.path.exists('export'):
        os.mkdir('export')

    shutil.make_archive("export/" + projectName + version, "zip", "build")



if __name__ == '__main__':

    make()

            

